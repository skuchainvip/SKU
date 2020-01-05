(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.FireDAC;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti
  , Skuchain.Core.JSON
  {$ifdef DelphiXE7_UP}, System.JSON {$endif}

  , FireDAC.Comp.Client

  , Skuchain.Client.Resource
  , Skuchain.Client.Client
  , Skuchain.Data.FireDAC.Utils
  ;

type
  TSkuchainFDResourceDatasetsItem = class(TCollectionItem)
  private
    FDataSet: TFDMemTable;
    FDataSetName: string;
    FSendDelta: Boolean;
    FSynchronize: Boolean;
    procedure SetDataSet(const Value: TFDMemTable);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
  published
    property DataSetName: string read FDataSetName write FDataSetName;
    property DataSet: TFDMemTable read FDataSet write SetDataSet;
    property SendDelta: Boolean read FSendDelta write FSendDelta;
    property Synchronize: Boolean read FSynchronize write FSynchronize;
  end;

  TSkuchainFDResourceDatasets = class(TCollection)
  private
    function GetItem(Index: Integer): TSkuchainFDResourceDatasetsItem;
  public
    function Add: TSkuchainFDResourceDatasetsItem;
    function FindItemByDataSetName(AName: string): TSkuchainFDResourceDatasetsItem;
    procedure ForEach(const ADoSomething: TProc<TSkuchainFDResourceDatasetsItem>);
    property Item[Index: Integer]: TSkuchainFDResourceDatasetsItem read GetItem;
  end;

  TOnApplyUpdatesErrorEvent = procedure (const ASender: TObject;
      const AItem: TSkuchainFDResourceDatasetsItem; const AErrorCount: Integer;
      const AErrors: TArray<string>; var AHandled: Boolean) of object;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX32 or pidiOSSimulator or pidiOSDevice or pidAndroid)]
  TSkuchainFDResource = class(TSkuchainClientResource)
  private
    FResourceDataSets: TSkuchainFDResourceDatasets;
    FPOSTResponse: TJSONValue;
    FOnApplyUpdatesError: TOnApplyUpdatesErrorEvent;
    FApplyUpdatesResults: TArray<TSkuchainFDApplyUpdatesRes>;
  protected
    procedure AfterGET(const AContent: TStream); override;
    procedure BeforePOST(const AContent: TMemoryStream); override;
    procedure AfterPOST(const AContent: TStream); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
    procedure AssignTo(Dest: TPersistent); override;

    function ApplyUpdatesHadErrors(const ADataSetName: string; var AErrorCount: Integer;
      var AErrorText: TArray<string>): Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property POSTResponse: TJSONValue read FPOSTResponse write FPOSTResponse;
    property ResourceDataSets: TSkuchainFDResourceDatasets read FResourceDataSets write FResourceDataSets;
    property OnApplyUpdatesError: TOnApplyUpdatesErrorEvent read FOnApplyUpdatesError write FOnApplyUpdatesError;
    property ApplyUpdatesResults: TArray<TSkuchainFDApplyUpdatesRes> read FApplyUpdatesResults;
  end;

procedure Register;

implementation

uses
    FireDAC.Comp.DataSet
  , FireDAC.Stan.StorageBin, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageXML
  , Skuchain.Core.Utils, Skuchain.Client.Utils, Skuchain.Rtti.Utils
  , Skuchain.Core.Exceptions, Skuchain.Core.MediaType
  ;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainFDResource]);
end;

{ TSkuchainFDResource }

procedure TSkuchainFDResource.AfterGET(const AContent: TStream);
var
  LDataSet: TFDMemTable;
  LDataSets: TArray<TFDMemTable>;
  LName: string;
  LItem: TSkuchainFDResourceDatasetsItem;
  LCopyDataSetProc: TThreadProcedure;
  LIndex: Integer;
  LFound: Boolean;
begin
  inherited;

  LDataSets := TFDDataSets.FromJSON(AContent);
  try
    LCopyDataSetProc :=
      procedure
      begin
        LItem.DataSet.DisableControls;
        try
          LItem.DataSet.Close;
          LItem.DataSet.Data := LDataset;
          LItem.DataSet.ApplyUpdates;
        finally
          LItem.DataSet.EnableControls;
        end;
      end;

    //purge dataset on client no more present on the server
    LIndex := 0;
    while LIndex < FResourceDataSets.Count do
    begin
      LName := FResourceDataSets.Item[LIndex].DataSetName;

      LFound := False;
      for LDataSet in LDataSets do
      begin
        if SameText(LDataSet.Name, LName) then
        begin
          LFound := True;
          Break;
        end;
      end;

      if not LFound then
        FResourceDataSets.Delete(LIndex)
      else
        Inc(LIndex);
    end;


    for LDataSet in LDataSets do
    begin
      LName := LDataSet.Name;

      LItem := FResourceDataSets.FindItemByDataSetName(LName);
      if Assigned(LItem) then
      begin
        if Assigned(LItem.DataSet) then
        begin
          if LItem.Synchronize then
            TThread.Synchronize(nil, LCopyDataSetProc)
          else
            LCopyDataSetProc();
        end;
      end
      else
      begin
        LItem := FResourceDataSets.Add;
        LItem.DataSetName := LName;
      end;
    end;
  finally
    TFDDataSets.FreeAll(LDataSets);
  end;
end;

procedure TSkuchainFDResource.AfterPOST(const AContent: TStream);
begin
  inherited;
  if Client.LastCmdSuccess then
  begin
    if Assigned(FPOSTResponse) then
      FPOSTResponse.Free;
    FPOSTResponse := StreamToJSONValue(AContent);

    FApplyUpdatesResults := [];
    if FPOSTResponse is TJSONArray then
      FApplyUpdatesResults := TJSONArray(FPOSTResponse).ToArrayOfRecord<TSkuchainFDApplyUpdatesRes>;

    FResourceDataSets.ForEach(
      procedure (AItem: TSkuchainFDResourceDatasetsItem)
      var
        LErrorCount: Integer;
        LErrorText: TArray<string>;
        LHandled: Boolean;
      begin
        if AItem.SendDelta and Assigned(AItem.DataSet) and (AItem.DataSet.Active) then
        begin
          if ApplyUpdatesHadErrors(AItem.DataSetName, LErrorCount, LErrorText) then
          begin
            LHandled := False;
            if Assigned(OnApplyUpdatesError) then
              OnApplyUpdatesError(Self, AItem, LErrorCount, LErrorText, LHandled);

            if not LHandled then
              raise ESkuchainException.CreateFmt('Error applying updates to dataset %s. Error: %s. Error count: %d'
                , [AItem.DataSetName, StringArrayToString(LErrorText, sLineBreak), LErrorCount]);
          end;
          AItem.DataSet.ApplyUpdates;
        end;
      end
    );
  end;
end;

function TSkuchainFDResource.ApplyUpdatesHadErrors(const ADataSetName: string;
  var AErrorCount: Integer; var AErrorText: TArray<string>): Boolean;
var
  LRes: TSkuchainFDApplyUpdatesRes;
begin
  Result := False;

  for LRes in ApplyUpdatesResults do
  begin
    if SameText(LRes.dataset, ADataSetName) then
    begin
      AErrorCount := LRes.errorCount;
      AErrorText := LRes.errors;
      Result := AErrorCount > 0;
      Break;
    end;
  end;
end;

procedure TSkuchainFDResource.AssignTo(Dest: TPersistent);
var
  LDest: TSkuchainFDResource;
begin
  inherited AssignTo(Dest);
  LDest := Dest as TSkuchainFDResource;

  LDest.ResourceDataSets.Assign(ResourceDataSets);
end;

procedure TSkuchainFDResource.BeforePOST(const AContent: TMemoryStream);
var
  LDeltas: TArray<TFDDataSet>;
  LDelta: TFDDataSet;
begin
  inherited;

  FApplyUpdatesResults := [];
  LDeltas := [];
  try
    FResourceDataSets.ForEach(
      procedure(AItem: TSkuchainFDResourceDatasetsItem)
      begin
        if AItem.SendDelta and Assigned(AItem.DataSet) and (AItem.DataSet.Active) then
        begin
          LDelta := TFDMemTable.Create(nil);
          try
            LDelta.Name := AItem.DataSetName;
            LDelta.Data := AItem.DataSet.Delta;
            LDeltas := LDeltas + [LDelta];
          except
            FreeAndNil(LDelta);
            raise;
          end;
        end;
      end
    );

    TFDDataSets.ToJSON(LDeltas, AContent);
  finally
    TFDDataSets.FreeAll(LDeltas);
  end;
end;

constructor TSkuchainFDResource.Create(AOwner: TComponent);
begin
  inherited;
  FResourceDataSets := TSkuchainFDResourceDatasets.Create(TSkuchainFDResourceDatasetsItem);
  SpecificAccept := TMediaType.APPLICATION_JSON_FireDAC + ',' + TMediaType.APPLICATION_JSON;
  SpecificContentType := TMediaType.APPLICATION_JSON_FireDAC;
end;

destructor TSkuchainFDResource.Destroy;
begin
  FPOSTResponse.Free;
  FResourceDataSets.Free;
  inherited;
end;

procedure TSkuchainFDResource.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = TOperation.opRemove then
  begin
    FResourceDataSets.ForEach(
      procedure (AItem: TSkuchainFDResourceDatasetsItem)
      begin
        if AItem.DataSet = AComponent then
          AItem.DataSet := nil;
      end
    );
  end;

end;

{ TSkuchainFDResourceDatasets }

function TSkuchainFDResourceDatasets.Add: TSkuchainFDResourceDatasetsItem;
begin
  Result := inherited Add as TSkuchainFDResourceDatasetsItem;
end;

function TSkuchainFDResourceDatasets.FindItemByDataSetName(
  AName: string): TSkuchainFDResourceDatasetsItem;
var
  LIndex: Integer;
  LItem: TSkuchainFDResourceDatasetsItem;
begin
  Result := nil;
  for LIndex := 0 to Count-1 do
  begin
    LItem := GetItem(LIndex);
    if SameText(LItem.DataSetName, AName) then
    begin
      Result := LItem;
      Break;
    end;
  end;
end;

procedure TSkuchainFDResourceDatasets.ForEach(
  const ADoSomething: TProc<TSkuchainFDResourceDatasetsItem>);
var
  LIndex: Integer;
begin
  if Assigned(ADoSomething) then
  begin
    for LIndex := 0 to Count-1 do
      ADoSomething(GetItem(LIndex));
  end;
end;

function TSkuchainFDResourceDatasets.GetItem(
  Index: Integer): TSkuchainFDResourceDatasetsItem;
begin
  Result := inherited GetItem(Index) as TSkuchainFDResourceDatasetsItem;
end;

{ TSkuchainFDResourceDatasetsItem }

procedure TSkuchainFDResourceDatasetsItem.AssignTo(Dest: TPersistent);
var
  LDest: TSkuchainFDResourceDatasetsItem;
begin
//   inherited;
  LDest := Dest as TSkuchainFDResourceDatasetsItem;

  LDest.DataSetName := DataSetName;
  LDest.DataSet := DataSet;
  LDest.SendDelta := SendDelta;
  LDest.Synchronize := Synchronize;
end;

constructor TSkuchainFDResourceDatasetsItem.Create(Collection: TCollection);
begin
  inherited;
  FSendDelta := True;
  FSynchronize := True;
end;

function TSkuchainFDResourceDatasetsItem.GetDisplayName: string;
begin
  Result := DataSetName;
  if Assigned(DataSet) then
    Result := Result + ' -> ' + DataSet.Name;
end;

procedure TSkuchainFDResourceDatasetsItem.SetDataSet(const Value: TFDMemTable);
begin
  if FDataSet <> Value then
  begin
    FDataSet := Value;
    if Assigned(FDataSet) then
    begin
      if SendDelta then
        FDataSet.CachedUpdates := True;
      FDataSet.ActiveStoredUsage := [];
    end;
  end;
end;

end.
