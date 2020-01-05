(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Data.FireDAC.Resources;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Generics.Collections
  , FireDAC.Comp.Client, FireDAC.Comp.DataSet
  , Skuchain.Core.MediaType, Skuchain.Core.Attributes, Skuchain.Data.FireDAC, Skuchain.Data.FireDAC.Utils
;

type

  [
    Produces(TMediaType.APPLICATION_JSON), Produces(TMediaType.APPLICATION_JSON_FireDAC)
  , Consumes(TMediaType.APPLICATION_JSON), Consumes(TMediaType.APPLICATION_JSON_FireDAC)
  ]
  TSkuchainFDDatasetResource = class
  private
    FStatements: TDictionary<string, string>;
  protected
    [Context] FConnection: TFDConnection;
    [Context] FD: TSkuchainFireDAC;
    procedure SetupStatements; virtual;

    procedure AfterOpenDataSet(ADataSet: TFDCustomQuery); virtual;
    procedure BeforeOpenDataSet(ADataSet: TFDCustomQuery); virtual;
    function ReadDataSet(const ADataSetName, ASQLStatement: string; const AAutoOpen: Boolean = True): TFDCustomQuery; virtual;

    property Connection: TFDConnection read FConnection write FConnection;
    property Statements: TDictionary<string, string> read FStatements;
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;

    [GET]
    function Retrieve: TArray<TFDDataSet>; virtual;

    [POST]
    function Update([BodyParam] const ADeltas: TArray<TFDMemTable>): TArray<TSkuchainFDApplyUpdatesRes>; virtual;
  end;


implementation

uses
    Skuchain.Core.JSON
  , Skuchain.Core.Exceptions
  , Skuchain.Rtti.Utils
;

{ TSkuchainFDDatasetResource }

procedure TSkuchainFDDatasetResource.AfterConstruction;
begin
  inherited;
  FStatements := TDictionary<string, string>.Create;
end;

procedure TSkuchainFDDatasetResource.AfterOpenDataSet(ADataSet: TFDCustomQuery);
begin

end;

procedure TSkuchainFDDatasetResource.BeforeOpenDataSet(ADataSet: TFDCustomQuery);
begin

end;

destructor TSkuchainFDDatasetResource.Destroy;
begin
  FStatements.Free;
  inherited;
end;

function TSkuchainFDDatasetResource.ReadDataSet(const ADataSetName, ASQLStatement: string; const AAutoOpen: Boolean = True): TFDCustomQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := Connection;
    Result.SQL.Text := ASQLStatement;
    Result.Name := ADataSetName;
    BeforeOpenDataSet(Result);
    if AAutoOpen then
    begin
      Result.Open;
      AfterOpenDataSet(Result);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TSkuchainFDDatasetResource.Retrieve: TArray<TFDDataSet>;
var
  LStatement: TPair<string, string>;
  LData: TArray<TFDDataSet>;
  LCurrent: TFDDataSet;
begin
  LData := [];
  try
    // load dataset(s)
    SetupStatements;
    for LStatement in Statements do
      LData := LData + [ReadDataSet(LStatement.Key, LStatement.Value)];

    Result := LData;
  except
    // clean up
    for LCurrent in LData do
      LCurrent.Free;
    LData := [];
    raise;
  end;
end;

procedure TSkuchainFDDatasetResource.SetupStatements;
begin
  TRTTIHelper.ForEachAttribute<SQLStatementAttribute>(
    Self,
    procedure (AAttrib: SQLStatementAttribute)
    begin
      Statements.Add(AAttrib.Name, AAttrib.SQLStatement);
    end);
end;

function TSkuchainFDDatasetResource.Update([BodyParam] const ADeltas: TArray<TFDMemTable>): TArray<TSkuchainFDApplyUpdatesRes>;
begin
  // setup
  SetupStatements;

  // apply updates
  Result := FD.ApplyUpdates(Retrieve, ADeltas);
end;


end.
