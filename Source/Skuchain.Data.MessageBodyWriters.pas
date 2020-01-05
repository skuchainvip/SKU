(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Data.MessageBodyWriters;

interface

uses
  Classes, SysUtils, Rtti

  , Skuchain.Core.Attributes
  , Skuchain.Core.Declarations
  , Skuchain.Core.MediaType
  , Skuchain.Core.MessageBodyWriter
  , Skuchain.Core.Activation.Interfaces
  ;

type
  [Produces(TMediaType.APPLICATION_JSON)]
  TDataSetWriterJSON = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;

  [Produces(TMediaType.APPLICATION_JSON)]
  TArrayDataSetWriter = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;

  [Produces(TMediaType.APPLICATION_XML)]
  TDataSetWriterXML = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;

implementation

uses
  DB, DBClient
  , Skuchain.Core.JSON
  , Skuchain.Core.MessageBodyWriters
  , Skuchain.Data.Utils
  , Skuchain.Rtti.Utils
  ;

{ TDataSetWriterJSON }

procedure TDataSetWriterJSON.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LResult: TJSONArray;
begin
  LResult := DataSetToJSONArray(AValue.AsObject as TDataSet);
  try
    TJSONValueWriter.WriteJSONValue(LResult, AMediaType, AOutputStream, AActivation);
  finally
    LResult.Free;
  end;
end;

{ TDataSetWriterXML }

procedure TDataSetWriterXML.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LStreamWriter: TStreamWriter;
begin
  LStreamWriter := TStreamWriter.Create(AOutputStream);
  try
    if AValue.AsObject is TClientDataSet then // CDS
      LStreamWriter.Write(TClientDataSet(AValue.AsObject).XMLData)
    else // default
      LStreamWriter.Write(DataSetToXML(Avalue.AsObject as TDataSet));
  finally
    LStreamWriter.Free;
  end;
end;

{ TArrayDataSetWriter }

procedure TArrayDataSetWriter.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LResult: TJSONObject;
  LDataSet: TDataSet;
  LIndex: Integer;
begin
  LResult := TJSONObject.Create;
  try
    for LIndex := 0 to AValue.GetArrayLength - 1 do
    begin
      LDataSet := AValue.GetArrayElement(LIndex).AsObject as TDataSet;
      LResult.AddPair(LDataSet.Name, DataSetToJSONArray(LDataSet));
    end;

    TJSONValueWriter.WriteJSONValue(LResult, AMediaType, AOutputStream, AActivation);
  finally
    LResult.Free;
  end;
end;

procedure RegisterWriters;
begin
  TSkuchainMessageBodyRegistry.Instance.RegisterWriter<TDataSet>(TDataSetWriterJSON
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Integer
    begin
      Result := TSkuchainMessageBodyRegistry.AFFINITY_LOW;
    end
  );

  TSkuchainMessageBodyRegistry.Instance.RegisterWriter(TArrayDataSetWriter
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Boolean
    begin
      Result := Assigned(AType) and AType.IsDynamicArrayOf<TDataSet>;
    end
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Integer
    begin
      Result := TSkuchainMessageBodyRegistry.AFFINITY_LOW
    end
  );

  TSkuchainMessageBodyRegistry.Instance.RegisterWriter(TDataSetWriterXML
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Boolean
    begin
      Result := Assigned(AType) and AType.IsObjectOfType<TDataSet>;
    end
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Integer
    begin
      Result := TSkuchainMessageBodyRegistry.AFFINITY_LOW;
    end
  );
end;

initialization
  RegisterWriters;

end.
