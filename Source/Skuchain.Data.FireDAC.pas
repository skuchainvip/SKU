(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Data.FireDAC;

{$I Skuchain.inc}

interface

uses
    System.Classes, System.SysUtils, Generics.Collections, Rtti

  , Data.DB
// *** BEWARE ***
// if your Delphi edition/license does not include FireDAC,
// remove the Skuchain_FIREDAC definition in the Skuchain.inc file!
// This is likely to be the case if you are compiling your first project and
// got a "FireDAC.DApt not found" error at the following line
  , FireDAC.DApt, FireDAC.DApt.Intf, FireDAC.DatS
  , FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Stan.Def
  , FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Stan.StorageXML, FireDAC.Stan.Param
  , FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageBin
  , FireDAC.UI.Intf
  , FireDAC.Phys.Intf, FireDAC.Phys
  , FireDAC.Comp.Client, FireDAC.Comp.UI, FireDAC.Comp.DataSet

  , Skuchain.Core.Application
  , Skuchain.Core.Attributes
  , Skuchain.Core.Classes
  , Skuchain.Core.Declarations
  , Skuchain.Core.JSON
  , Skuchain.Core.MediaType
  , Skuchain.Core.Registry
  , Skuchain.Core.Token
  , Skuchain.Core.URL
  , Skuchain.Utils.Parameters
  , Skuchain.Core.Activation.Interfaces
  , Skuchain.Data.FireDAC.Utils
;

type
  ESkuchainFireDACException = class(ESkuchainApplicationException);

  ConnectionAttribute = class(TCustomAttribute)
  private
    FConnectionDefName: string;
  public
    constructor Create(AConnectionDefName: string);
    property ConnectionDefName: string read FConnectionDefName;
  end;

  SQLStatementAttribute = class(TCustomAttribute)
  private
    FName: string;
    FSQLStatement: string;
  public
    constructor Create(AName, ASQLStatement: string);
    property Name: string read FName;
    property SQLStatement: string read FSQLStatement;
  end;

  TContextValueProviderProc = reference to procedure (const AActivation: ISkuchainActivation;
    const AName: string; const ADesiredType: TFieldType; out AValue: TValue);


  TSkuchainFDMemTable = class(TFDMemTable)
  private
    FApplyUpdatesRes: TSkuchainFDApplyUpdatesRes;
  protected
    function DoApplyUpdates(ATable: TFDDatSTable; AMaxErrors: Integer): Integer; override;
    procedure DoBeforeApplyUpdate; override;
    procedure DoUpdateErrorHandler(ARow: TFDDatSRow; AException: Exception;
      ARequest: TFDUpdateRequest; var AAction: TFDErrorAction); override;
  public
    property ApplyUpdatesRes: TSkuchainFDApplyUpdatesRes read FApplyUpdatesRes;
  end;

  TSkuchainFireDAC = class
  private
    FConnectionDefName: string;
    FConnection: TFDConnection;
    FActivation: ISkuchainActivation;
  protected
    procedure DoUpdateError(ASender: TDataSet; AException: EFDException;
      ARow: TFDDatSRow; ARequest: TFDUpdateRequest; var AAction: TFDErrorAction);
    procedure SetConnectionDefName(const Value: string); virtual;
    function GetConnection: TFDConnection; virtual;
    function GetContextValue(const AName: string; const ADesiredType: TFieldType = ftUnknown): TValue; virtual;
    class var FContextValueProviders: TArray<TContextValueProviderProc>;
  public
    const PARAM_AND_MACRO_DELIMITER = '_';

    procedure InjectParamValues(const ACommand: TFDCustomCommand); virtual;
    procedure InjectMacroValues(const ACommand: TFDCustomCommand); virtual;

    constructor Create(const AConnectionDefName: string;
      const AActivation: ISkuchainActivation = nil); virtual;
    destructor Destroy; override;

    function ApplyUpdates(const ADelta: TFDMemTable; const ATableAdapter: TFDTableAdapter;
      const AMaxErrors: Integer = -1): TSkuchainFDApplyUpdatesRes; overload; virtual;

    function ApplyUpdates(ADataSets: TArray<TFDDataSet>; ADeltas: TArray<TFDMemTable>;
//      AOnApplyUpdates: TProc<TFDCustomQuery, Integer, IFDJSONDeltasApplyUpdates> = nil;
      AOnBeforeApplyUpdates: TProc<TFDDataSet, TFDMemTable> = nil
      ): TArray<TSkuchainFDApplyUpdatesRes>; overload; virtual;

    function CreateCommand(const ASQL: string = ''; const ATransaction: TFDTransaction = nil;
      const AContextOwned: Boolean = True): TFDCommand; virtual;
    function CreateQuery(const ASQL: string = ''; const ATransaction: TFDTransaction = nil;
      const AContextOwned: Boolean = True; const AName: string = 'DataSet'): TFDQuery; virtual;
    function CreateTransaction(const AContextOwned: Boolean = True): TFDTransaction; virtual;

    procedure ExecuteSQL(const ASQL: string; const ATransaction: TFDTransaction = nil;
      const ABeforeExecute: TProc<TFDCommand> = nil;
      const AAfterExecute: TProc<TFDCommand> = nil); virtual;

    function Query(const ASQL: string): TFDQuery; overload; virtual;

    function Query(const ASQL: string;
      const ATransaction: TFDTransaction): TFDQuery; overload; virtual;

    function Query(const ASQL: string; const ATransaction: TFDTransaction;
      const AContextOwned: Boolean): TFDQuery; overload; virtual;

    function Query(const ASQL: string; const ATransaction: TFDTransaction;
      const AContextOwned: Boolean;
      const AOnBeforeOpen: TProc<TFDQuery>): TFDQuery; overload; virtual;

    procedure Query(const ASQL: string; const ATransaction: TFDTransaction;
      const AOnBeforeOpen: TProc<TFDQuery>;
      const AOnDataSetReady: TProc<TFDQuery>); overload; virtual;

    procedure InTransaction(const ADoSomething: TProc<TFDTransaction>);

    property Connection: TFDConnection read GetConnection;
    property ConnectionDefName: string read FConnectionDefName write SetConnectionDefName;
    property Activation: ISkuchainActivation read FActivation;

    class function LoadConnectionDefs(const AParameters: TSkuchainParameters;
      const ASliceName: string = ''): TArray<string>;
    class procedure CloseConnectionDefs(const AConnectionDefNames: TArray<string>);
    class function CreateConnectionByDefName(const AConnectionDefName: string): TFDConnection;

    class constructor CreateClass;
    class procedure AddContextValueProvider(const AContextValueProviderProc: TContextValueProviderProc);
  end;

  function MacroDataTypeToFieldType(const AMacroDataType: TFDMacroDataType): TFieldType;

implementation

uses
  StrUtils, Variants
  , Skuchain.Core.Utils
  , Skuchain.Core.Exceptions
  , Skuchain.Data.Utils
  , Skuchain.Rtti.Utils
  , Skuchain.Data.FireDAC.InjectionService
  , Skuchain.Data.FireDAC.ReadersAndWriters
;


function MacroDataTypeToFieldType(const AMacroDataType: TFDMacroDataType): TFieldType;
begin
  case AMacroDataType of
    mdUnknown: Result := ftUnknown;
    mdString: Result := ftString;
    mdIdentifier: Result := ftString; // !!!
    mdInteger: Result := ftInteger;
    mdBoolean: Result := ftBoolean;
    mdFloat: Result := ftFloat;
    mdDate: Result := ftDate;
    mdTime: Result := ftTime;
    mdDateTime: Result := ftDateTime;
    mdRaw: Result := ftUnknown;   // ???
    else
      Result := ftUnknown;
  end;
end;


function GetAsTStrings(const AParameters: TSkuchainParameters): TStrings;
var
  LParam: TPair<string, TValue>;
begin
  Result := TStringList.Create;
  try
    for LParam in AParameters do
      Result.Values[LParam.Key] := LParam.Value.ToString;
  except
    Result.Free;
    raise;
  end;
end;

class function TSkuchainFireDAC.LoadConnectionDefs(const AParameters: TSkuchainParameters;
  const ASliceName: string = ''): TArray<string>;
var
  LData, LConnectionParams: TSkuchainParameters;
  LConnectionDefNames: TArray<string>;
  LConnectionDefName: string;
  LParams: TStrings;
begin
  Result := [];
  LData := TSkuchainParameters.Create('');
  try
    LData.CopyFrom(AParameters, ASliceName);
    LConnectionDefNames := LData.SliceNames;

    for LConnectionDefName in LConnectionDefNames do
    begin
      LConnectionParams := TSkuchainParameters.Create(LConnectionDefName);
      try
        LConnectionParams.CopyFrom(LData, LConnectionDefName);
        LParams := GetAsTStrings(LConnectionParams);
        try
          FDManager.AddConnectionDef(LConnectionDefName, LParams.Values['DriverID'], LParams);
          Result := Result + [LConnectionDefName];
        finally
          LParams.Free;
        end;
      finally
        LConnectionParams.Free;
      end;
    end;
  finally
    LData.Free;
  end;
end;

function TSkuchainFireDAC.Query(const ASQL: string;
  const ATransaction: TFDTransaction): TFDQuery;
begin
  Result := Query(ASQL, ATransaction, True);
end;

function TSkuchainFireDAC.Query(const ASQL: string;
  const ATransaction: TFDTransaction; const AContextOwned: Boolean;
  const AOnBeforeOpen: TProc<TFDQuery>): TFDQuery;
begin
  Result := CreateQuery(ASQL, ATransaction, AContextOwned);
  try
    if Assigned(AOnBeforeOpen) then
      AOnBeforeOpen(Result);
    Result.Open;
  except
    if not AContextOwned then
      Result.Free;
    raise;
  end;
end;

function TSkuchainFireDAC.Query(const ASQL: string): TFDQuery;
begin
  Result := Query(ASQL, nil, True);
end;

procedure TSkuchainFireDAC.Query(const ASQL: string; const ATransaction: TFDTransaction;
  const AOnBeforeOpen, AOnDataSetReady: TProc<TFDQuery>);
var
  LQuery: TFDQuery;
begin
  LQuery := Query(ASQL, ATransaction, False, AOnBeforeOpen);
  try
    if Assigned(AOnDataSetReady) then
      AOnDataSetReady(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TSkuchainFireDAC.Query(const ASQL: string;
  const ATransaction: TFDTransaction; const AContextOwned: Boolean): TFDQuery;
begin
  Result := CreateQuery(ASQL, ATransaction, AContextOwned);
  Result.Open;
end;

class function TSkuchainFireDAC.CreateConnectionByDefName(const AConnectionDefName: string): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.ConnectionDefName := AConnectionDefName;
  except
    Result.Free;
    raise;
  end;
end;

{ ConnectionAttribute }

constructor ConnectionAttribute.Create(AConnectionDefName: string);
begin
  inherited Create;
  FConnectionDefName := AConnectionDefName;
end;

{ SQLStatementAttribute }

constructor SQLStatementAttribute.Create(AName, ASQLStatement: string);
begin
  inherited Create;
  FName := AName;
  FSQLStatement := ASQLStatement;
end;

{ TSkuchainFireDAC }

class procedure TSkuchainFireDAC.AddContextValueProvider(
  const AContextValueProviderProc: TContextValueProviderProc);
begin
  FContextValueProviders := FContextValueProviders + [TContextValueProviderProc(AContextValueProviderProc)];
end;

function DataSetByName(const ADataSets: TArray<TFDDataSet>; const AName: string): TFDDataSet;
var
  LCurrent: TFDDataSet;
begin
  Result := nil;
  for LCurrent in ADataSets do
    if SameText(LCurrent.Name, AName) then
    begin
      Result := LCurrent;
      Break;
    end;
  if Result = nil then
    raise ESkuchainFireDACException.CreateFmt('DataSet %s not found', [AName]);
end;

function TSkuchainFireDAC.ApplyUpdates(const ADelta: TFDMemTable;
  const ATableAdapter: TFDTableAdapter;
  const AMaxErrors: Integer): TSkuchainFDApplyUpdatesRes;
var
  LFDMemTable: TSkuchainFDMemTable;
  LFDAdapter: TFDTableAdapter;
begin
  Assert(ATableAdapter <> nil);

  Result.Clear;

  LFDMemTable := TSkuchainFDMemTable.Create(nil);
  try
    LFDMemTable.Name := ATableAdapter.Name;
    LFDAdapter := TFDTableAdapter.Create(nil);
    try
      if Assigned(ATableAdapter.SelectCommand) then
        LFDAdapter.SelectCommand := ATableAdapter.SelectCommand;
      if Assigned(ATableAdapter.InsertCommand) then
        LFDAdapter.InsertCommand := ATableAdapter.InsertCommand;
      if Assigned(ATableAdapter.UpdateCommand) then
        LFDAdapter.UpdateCommand := ATableAdapter.UpdateCommand;
      if Assigned(ATableAdapter.DeleteCommand) then
        LFDAdapter.DeleteCommand := ATableAdapter.DeleteCommand;

      LFDAdapter.UpdateTableName := ATableAdapter.UpdateTableName;
      if LFDAdapter.UpdateTableName = '' then
        LFDAdapter.UpdateTableName := LFDAdapter.SelectCommand.UpdateOptions.UpdateTableName;

      LFDMemTable.ResourceOptions.StoreItems := [siMeta, siDelta];
      LFDMemTable.CachedUpdates := True;
      LFDMemTable.Adapter := LFDAdapter;
      LFDMemTable.Data := ADelta.Data;
      LFDMemTable.ApplyUpdates(AMaxErrors);
      Result := LFDMemTable.ApplyUpdatesRes;
    finally
      LFDAdapter.Free;
    end;
  finally
    LFDMemTable.Free;
  end;
end;

function TSkuchainFireDAC.ApplyUpdates(ADataSets: TArray<TFDDataSet>;
  ADeltas: TArray<TFDMemTable>;
  AOnBeforeApplyUpdates: TProc<TFDDataSet, TFDMemTable>): TArray<TSkuchainFDApplyUpdatesRes>;
var
  LDelta: TFDMemTable;
  LDataSet: TFDAdaptedDataSet;
  LFDAdapter: TFDTableAdapter;

begin
  Result := [];
  for LDelta in ADeltas do
  begin
    LDataSet := DataSetByName(ADataSets, LDelta.Name) as TFDAdaptedDataSet;
    Assert(LDataSet <> nil);
    Assert(LDataSet.Command <> nil);

    InjectMacroValues(LDataSet.Command);
    InjectParamValues(LDataSet.Command);

    if Assigned(AOnBeforeApplyUpdates) then
      AOnBeforeApplyUpdates(LDataSet, LDelta);

    LFDAdapter := TFDTableAdapter.Create(nil);
    try
      LFDAdapter.Name := LDataSet.Name;
      LFDAdapter.SelectCommand := LDataSet.Command;
      Result := Result + [ApplyUpdates(LDelta, LFDAdapter, -1)];
    finally
      LFDAdapter.Free;
    end;
  end;
end;

class procedure TSkuchainFireDAC.CloseConnectionDefs(
  const AConnectionDefNames: TArray<string>);
var
  LConnectionDefName: string;
begin
  for LConnectionDefName in AConnectionDefNames do
    FDManager.CloseConnectionDef(LConnectionDefName);
end;

constructor TSkuchainFireDAC.Create(const AConnectionDefName: string;
  const AActivation: ISkuchainActivation);
begin
  inherited Create();
  ConnectionDefName := AConnectionDefName;
  FActivation := AActivation;
end;

class constructor TSkuchainFireDAC.CreateClass;
begin
  FContextValueProviders := [];
end;

function TSkuchainFireDAC.CreateCommand(const ASQL: string;
  const ATransaction: TFDTransaction; const AContextOwned: Boolean): TFDCommand;
begin
  Result := TFDCommand.Create(nil);
  try
    Result.Connection := Connection;
    Result.Transaction := ATransaction;
    Result.CommandText.Text := ASQL;
    InjectMacroValues(Result);
    InjectParamValues(Result);
    if AContextOwned then
      Activation.AddToContext(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TSkuchainFireDAC.CreateQuery(const ASQL: string; const ATransaction: TFDTransaction;
  const AContextOwned: Boolean; const AName: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Name := AName;
    Result.Connection := Connection;
    Result.Transaction := ATransaction;
    Result.SQL.Text := ASQL;
    InjectMacroValues(Result.Command);
    InjectParamValues(Result.Command);
    if AContextOwned then
      Activation.AddToContext(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TSkuchainFireDAC.CreateTransaction(const AContextOwned: Boolean): TFDTransaction;
begin
  Result := TFDTransaction.Create(nil);
  try
    Result.Connection := Connection;
    if AContextOwned then
      Activation.AddToContext(Result);
  except
    Result.Free;
    raise;
  end;
end;

destructor TSkuchainFireDAC.Destroy;
begin
  FreeAndNil(FConnection);
  inherited;
end;

procedure TSkuchainFireDAC.DoUpdateError(ASender: TDataSet;
  AException: EFDException; ARow: TFDDatSRow; ARequest: TFDUpdateRequest;
  var AAction: TFDErrorAction);
begin

end;

procedure TSkuchainFireDAC.ExecuteSQL(const ASQL: string; const ATransaction: TFDTransaction;
  const ABeforeExecute, AAfterExecute: TProc<TFDCommand>);
var
  LCommand: TFDCommand;
begin
  LCommand := CreateCommand(ASQL, ATransaction, False);
  try
    if Assigned(ABeforeExecute) then
      ABeforeExecute(LCommand);
    LCommand.Execute();
    if Assigned(AAfterExecute) then
      AAfterExecute(LCommand);
  finally
    LCommand.Free;
  end;
end;

function TSkuchainFireDAC.GetConnection: TFDConnection;
begin
  if not Assigned(FConnection) then
    FConnection := CreateConnectionByDefName(ConnectionDefName);
  Result := FConnection;
end;

function TSkuchainFireDAC.GetContextValue(const AName: string; const ADesiredType: TFieldType): TValue;
var
  LFirstToken, LSecondToken: string;
  LHasThirdToken: Boolean;
  LSecondTokenAndAll, LThirdTokenAndAll: string;
  LNameTokens: TArray<string>;
  LFirstDelim, LSecondDelim: Integer;

  LIndex: Integer;
  LCustomProvider: TContextValueProviderProc;
begin
  Result := TValue.Empty;
  LNameTokens := AName.Split([PARAM_AND_MACRO_DELIMITER]);
  if Length(LNameTokens) < 2 then
    Exit;

  LFirstToken := LNameTokens[0];
  LSecondToken := LNameTokens[1];
  LFirstDelim := AName.IndexOf(PARAM_AND_MACRO_DELIMITER);
  LSecondTokenAndAll := AName.Substring(LFirstDelim + 1);
  LHasThirdToken := Length(LNameTokens) > 2;
  if LHasThirdToken then
  begin
    LSecondDelim := AName.IndexOf(PARAM_AND_MACRO_DELIMITER, LFirstDelim + Length(PARAM_AND_MACRO_DELIMITER));
    LThirdTokenAndAll := AName.Substring(LSecondDelim + 1);
  end;

  if SameText(LFirstToken, 'Token') then
  begin
    Result := ReadPropertyValue(Activation.Token, LSecondToken);

    if SameText(LSecondToken, 'HasRole') and LHasThirdToken then
      Result := Activation.Token.HasRole(LThirdTokenAndAll)
    else if SameText(LSecondToken, 'Claim') and LHasThirdToken then
      Result := Activation.Token.Claims.ByNameText(LThirdTokenAndAll);
  end
  else if SameText(LFirstToken, 'PathParam') then
  begin
    LIndex := Activation.URLPrototype.GetPathParamIndex(LSecondTokenAndAll);
    if (LIndex > -1) and (LIndex < Length(Activation.URL.PathTokens)) then
      Result := Activation.URL.PathTokens[LIndex] { TODO -oAndrea : Try to convert according to ADesiredType }
    else
      raise ESkuchainFireDACException.CreateFmt('PathParam not found: %s', [LSecondTokenAndAll]);
  end
  else if SameText(LFirstToken, 'QueryParam') then
    Result := Activation.URL.QueryTokenByName(LSecondTokenAndAll)
  else if SameText(LFirstToken, 'FormParam') then
    Result := Activation.Request.ContentFields.Values[LSecondTokenAndAll]
  else if SameText(LFirstToken, 'Request') then
    Result := ReadPropertyValue(Activation.Request, LSecondTokenAndAll)
//  else if SameText(LFirstToken, 'Response') then
//    Result := ReadPropertyValue(Activation.Response, LSecondToken)
  else if SameText(LFirstToken, 'URL') then
    Result := ReadPropertyValue(Activation.URL, LSecondTokenAndAll)
  else if SameText(LFirstToken, 'URLPrototype') then
    Result := ReadPropertyValue(Activation.URLPrototype, LSecondTokenAndAll)
  else // last chance, custom injection
    for LCustomProvider in FContextValueProviders do
      LCustomProvider(Activation, AName, ADesiredType, Result);
end;

procedure TSkuchainFireDAC.InjectMacroValues(const ACommand: TFDCustomCommand);
var
  LIndex: Integer;
  LMacro: TFDMacro;
begin
  for LIndex := 0 to ACommand.Macros.Count-1 do
  begin
    LMacro := ACommand.Macros[LIndex];
    LMacro.Value := GetContextValue(LMacro.Name, MacroDataTypeToFieldType(LMacro.DataType)).AsVariant;
  end;
end;

procedure TSkuchainFireDAC.InjectParamValues(const ACommand: TFDCustomCommand);
var
  LIndex: Integer;
  LParam: TFDParam;
begin
  for LIndex := 0 to ACommand.Params.Count-1 do
  begin
    LParam := ACommand.Params[LIndex];
    LParam.Value := GetContextValue(LParam.Name, LParam.DataType).AsVariant;
  end;
end;


procedure TSkuchainFireDAC.InTransaction(const ADoSomething: TProc<TFDTransaction>);
var
  LTransaction: TFDTransaction;
begin
  if Assigned(ADoSomething) then
  begin
    LTransaction := CreateTransaction(False);
    try
      LTransaction.StartTransaction;
      try
        ADoSomething(LTransaction);
        LTransaction.Commit;
      except
        LTransaction.Rollback;
        raise;
      end;
    finally
      LTransaction.Free;
    end;
  end;
end;

procedure TSkuchainFireDAC.SetConnectionDefName(const Value: string);
begin
  if FConnectionDefName <> Value then
  begin
    FreeAndNil(FConnection);
    FConnectionDefName := Value;
  end;
end;


{ TSkuchainFDMemTable }

function TSkuchainFDMemTable.DoApplyUpdates(ATable: TFDDatSTable;
  AMaxErrors: Integer): Integer;
begin
  Result := inherited DoApplyUpdates(ATable, AMaxErrors);
  FApplyUpdatesRes.result := Result;
end;

procedure TSkuchainFDMemTable.DoBeforeApplyUpdate;
begin
  inherited;
  FApplyUpdatesRes := TSkuchainFDApplyUpdatesRes.Create(Self.Name);
end;

procedure TSkuchainFDMemTable.DoUpdateErrorHandler(ARow: TFDDatSRow;
  AException: Exception; ARequest: TFDUpdateRequest;
  var AAction: TFDErrorAction);
begin
  inherited;
  FApplyUpdatesRes.AddError(ARow, AException, ARequest);
end;

end.
