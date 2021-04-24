(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Metadata.ReadersAndWriters;

interface

uses
  Classes, SysUtils, Rtti

  , Skuchain.Core.Attributes
  , Skuchain.Core.Declarations
  , Skuchain.Core.MediaType
  , Skuchain.Core.MessageBodyWriter
  , Skuchain.Core.Engine
  , Skuchain.Core.JSON
  , Skuchain.Core.Activation.Interfaces
;

type
  [Produces(TMediaType.APPLICATION_JSON)]
  TSkuchainMetadataJSONWriter = class(TInterfacedObject, IMessageBodyWriter)
  private
  protected
  public
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;

implementation

uses
    Skuchain.Core.Utils
  , Skuchain.Core.MessageBodyWriters
  , Skuchain.Metadata
  , Skuchain.Metadata.JSON
  , Skuchain.Metadata.Reader
  ;

{ TSkuchainMetadataJSONWriter }

procedure TSkuchainMetadataJSONWriter.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LJSON: TJSONObject;
  LMetadata: TSkuchainMetadata;
begin
  LMetadata := AValue.AsType<TSkuchainMetadata>;
  if not Assigned(LMetadata) then
    Exit;

  LJSON := LMetadata.ToJSON;
  try
    TJSONValueWriter.WriteJSONValue(LJSON, AMediaType, AOutputStream, AActivation);
  finally
    LJSON.Free;
  end;
end;

initialization
  TSkuchainMessageBodyRegistry.Instance.RegisterWriter<TSkuchainMetadata>(TSkuchainMetadataJSONWriter);

end.
