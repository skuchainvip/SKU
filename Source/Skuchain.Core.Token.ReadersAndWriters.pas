(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Token.ReadersAndWriters;

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
  TSkuchainTokenWriterJSON = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: ISkuchainActivation);
  end;

//  [Consumes(TMediaType.APPLICATION_JSON)]
//  TSkuchainTokenReaderJSON = class(TInterfacedObject, IMessageBodyReader)
//  public
//    function ReadFrom(const AInputData: TBytes;
//      const AAttributes: TAttributeArray;
//      AMediaType: TMediaType; ARequestHeaders: TStrings): TValue; virtual;
//  end;


implementation

uses
    Generics.Collections
  , Skuchain.Core.Utils
  , Skuchain.Rtti.Utils
  , Skuchain.Core.Token
  , Skuchain.Core.JSON
  , Skuchain.Core.MessageBodyWriters
  , Skuchain.Utils.Parameters, Skuchain.Utils.Parameters.JSON
  ;


{ TSkuchainTokenWriterJSON }

procedure TSkuchainTokenWriterJSON.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: ISkuchainActivation);
var
  LToken: TSkuchainToken;
  LJSONObj: TJSONObject;
begin
  LToken := AValue.AsObject as TSkuchainToken;
  if Assigned(LToken) then
  begin
    LJSONObj := TJSONObject.Create;
    try
      LJSONObj.WriteStringValue('Token', LToken.Token);
      LJSONObj.WriteBoolValue('IsVerified', LToken.IsVerified);
      LJSONObj.WriteStringValue('UserName', LToken.UserName);
      LJSONObj.WriteStringValue('Roles', StringArrayToString(LToken.Roles));
      if LToken.Expiration > 0 then
        LJSONObj.WriteDateTimeValue('Expiration', LToken.Expiration);
      if LToken.IssuedAt > 0 then
        LJSONObj.WriteDateTimeValue('IssuedAt', LToken.IssuedAt);
      if LToken.IsVerified and not LToken.Claims.IsEmpty  then
        LJSONObj.AddPair('Claims', LToken.Claims.SaveToJSON);

      TJSONValueWriter.WriteJSONValue(LJSONObj, AMediaType, AOutputStream, AActivation);
    finally
      LJSONObj.Free;
    end;
  end;
end;

procedure RegisterReadersAndWriters;
begin
//  TSkuchainMessageBodyReaderRegistry.Instance.RegisterReader<TSkuchainToken>(TSkuchainTokenReaderJSON);

  TSkuchainMessageBodyRegistry.Instance.RegisterWriter<TSkuchainToken>(TSkuchainTokenWriterJSON);
end;


initialization
  RegisterReadersAndWriters;

end.
