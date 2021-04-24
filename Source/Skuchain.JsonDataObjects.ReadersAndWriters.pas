(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.JsonDataObjects.ReadersAndWriters;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti

  , Skuchain.Core.Attributes
  , Skuchain.Core.Declarations
  , Skuchain.Core.MediaType
  , Skuchain.Core.MessageBodyWriter
  , Skuchain.Core.MessageBodyReader
  , Skuchain.Core.Activation.Interfaces
  ;

type
  [Produces(TMediaType.APPLICATION_JSON)]
  TJsonDataObjectsWriter = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;

  [Consumes(TMediaType.APPLICATION_JSON)]
  TJsonDataObjectsReader = class(TInterfacedObject, IMessageBodyReader)
  public
    function ReadFrom(
    {$ifdef Delphi10Berlin_UP}const AInputData: TBytes;{$else}const AInputData: AnsiString;{$endif}
      const ADestination: TRttiObject; const AMediaType: TMediaType;
      const AActivation: ISkuchainActivation
    ): TValue;
  end;


implementation

uses
    JsonDataObjects
  , Skuchain.Core.Utils
  , Skuchain.Rtti.Utils
  ;

{ TJsonDataObjectsWriter }

procedure TJsonDataObjectsWriter.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LStreamWriter: TStreamWriter;
  LJsonBO: TJsonBaseObject;
begin
  LStreamWriter := TStreamWriter.Create(AOutputStream);
  try
    LJsonBO := AValue.AsObject as TJsonBaseObject;
    if Assigned(LJsonBO) then
      LStreamWriter.Write(LJsonBO.ToJSON);
  finally
    LStreamWriter.Free;
  end;
end;

{ TJsonDataObjectsReader }

function TJsonDataObjectsReader.ReadFrom(
  {$ifdef Delphi10Berlin_UP}const AInputData: TBytes;{$else}const AInputData: AnsiString;{$endif}
    const ADestination: TRttiObject; const AMediaType: TMediaType;
    const AActivation: ISkuchainActivation
  ): TValue;
var
  LJson: TJsonBaseObject;
begin
  Result := TValue.Empty;

  LJson := TJsonBaseObject.Parse(AInputData);
  if Assigned(LJson) then
    Result := LJson;
end;

procedure RegisterReadersAndWriters;
begin
  TSkuchainMessageBodyReaderRegistry.Instance.RegisterReader<TJsonBaseObject>(TJsonDataObjectsReader);

  TSkuchainMessageBodyRegistry.Instance.RegisterWriter<TJsonBaseObject>(TJsonDataObjectsWriter);
end;


initialization
  RegisterReadersAndWriters;

end.
