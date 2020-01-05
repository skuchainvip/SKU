(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Data.FireDAC.ReadersAndWriters;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti

  , DB

  , Skuchain.Core.Attributes
  , Skuchain.Core.Activation.Interfaces
  , Skuchain.Core.Declarations
  , Skuchain.Core.MediaType
  , Skuchain.Core.Classes
  , Skuchain.Core.MessageBodyWriter
  , Skuchain.Core.MessageBodyReader
  , Skuchain.Core.Utils
  , Skuchain.Data.Utils;

type
  // --- READERS ---
  [ Consumes(TMediaType.APPLICATION_JSON_FIREDAC) ]
  TArrayFDMemTableReader = class(TInterfacedObject, IMessageBodyReader)
  public
    function ReadFrom(
    {$ifdef Delphi10Berlin_UP}const AInputData: TBytes;{$else}const AInputData: AnsiString;{$endif}
      const ADestination: TRttiObject; const AMediaType: TMediaType;
      const AActivation: ISkuchainActivation
    ): TValue; virtual;
  end;

  // --- WRITERS ---
  [ Produces(TMediaType.APPLICATION_XML)
  , Produces(TMediaType.APPLICATION_JSON_FIREDAC)
  , Produces(TMediaType.APPLICATION_OCTET_STREAM)
  ]
  TFDDataSetWriter = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;

  [ Produces(TMediaType.APPLICATION_JSON_FIREDAC) ]
  TArrayFDDataSetWriter = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
    class procedure WriteDataSets(const ADataSets: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;


implementation

uses
    Generics.Collections
  , FireDAC.Comp.Client, FireDAC.Comp.DataSet
  , FireDAC.Stan.Intf

  , FireDAC.Stan.StorageBIN
  , FireDAC.Stan.StorageJSON
  , FireDAC.Stan.StorageXML

  , Skuchain.Core.JSON
  , Skuchain.Core.MessageBodyWriters, Skuchain.Core.MessageBodyReaders
  {$ifdef DelphiXE7_UP}, System.JSON {$endif}
  , Skuchain.Core.Exceptions
  , Skuchain.Rtti.Utils, Skuchain.Data.FireDAC.Utils
;

{ TArrayFDDataSetWriter }

class procedure TArrayFDDataSetWriter.WriteDataSets(const ADataSets: TValue;
  const AMediaType: TMediaType; AOutputStream: TStream;
  const AActivation: ISkuchainActivation);
var
  LWriter: TArrayFDDataSetWriter;
begin
  LWriter := TArrayFDDataSetWriter.Create;
  try
    LWriter.WriteTo(ADataSets, AMediaType, AOutputStream, AActivation);
  finally
    LWriter.Free;
  end;
end;

procedure TArrayFDDataSetWriter.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LResult: TJSONObject;
begin
  LResult := TFDDataSets.ToJSON(AValue);
  try
    TJSONValueWriter.WriteJSONValue(LResult, AMediaType, AOutputStream, AActivation);
  finally
    LResult.Free;
  end;
end;

{ TFDDataSetWriter }

procedure TFDDataSetWriter.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LDataset: TFDDataSet;
begin
  LDataset := AValue.AsType<TFDDataSet>;

  if AMediaType.Matches(TMediaType.APPLICATION_XML) then
    LDataSet.SaveToStream(AOutputStream, sfXML)
  else if AMediaType.Matches(TMediaType.APPLICATION_JSON_FireDAC) then
    TArrayFDDataSetWriter.WriteDataSets(TValue.From<TArray<TFDDataSet>>([LDataSet]),
      AMediaType, AOutputStream, AActivation)
  else if AMediaType.Matches(TMediaType.APPLICATION_OCTET_STREAM) then
    LDataSet.SaveToStream(AOutputStream, sfBinary)
  else
    raise ESkuchainException.CreateFmt('Unsupported media type: %s', [AMediaType.ToString]);
end;

{ TArrayFDMemTableReader }

function TArrayFDMemTableReader.ReadFrom(
{$ifdef Delphi10Berlin_UP}const AInputData: TBytes;{$else}const AInputData: AnsiString;{$endif}
  const ADestination: TRttiObject; const AMediaType: TMediaType;
  const AActivation: ISkuchainActivation
): TValue;
var
  LJSON: TJSONObject;
begin
  Result := TValue.Empty;

  LJSON := TJSONValueReader.ReadJSONValue(AInputData, ADestination, AMediaType, AActivation).AsType<TJSONObject>;
  if not Assigned(LJSON) then
    Exit;
  try
    Result := TValue.From<TArray<TFDMemTable>>(TFDDataSets.FromJSON(LJSON));
  finally
    LJSON.Free;
  end;
end;

procedure RegisterReadersAndWriters;
begin
  TSkuchainMessageBodyRegistry.Instance.RegisterWriter<TFDDataSet>(TFDDataSetWriter);

  TSkuchainMessageBodyRegistry.Instance.RegisterWriter(
    TArrayFDDataSetWriter
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Boolean
    begin
      Result := Assigned(AType) and AType.IsDynamicArrayOf<TFDDataSet>;
    end
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Integer
    begin
      Result := TSkuchainMessageBodyRegistry.AFFINITY_MEDIUM;
    end
  );

  TSkuchainMessageBodyReaderRegistry.Instance.RegisterReader(
    TArrayFDMemTableReader
  , function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Boolean
    begin
      Result := Assigned(AType) and AType.IsDynamicArrayOf<TFDMemTable>;
    end
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Integer
    begin
      Result := TSkuchainMessageBodyRegistry.AFFINITY_MEDIUM
    end
  );
end;

initialization
  RegisterReadersAndWriters;

end.
