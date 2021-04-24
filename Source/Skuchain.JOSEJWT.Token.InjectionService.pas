(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.JOSEJWT.Token.InjectionService;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti
, Skuchain.Core.Injection, Skuchain.Core.Injection.Interfaces, Skuchain.Core.Injection.Types
, Skuchain.Core.Activation.Interfaces
;

type
  TSkuchainTokenInjectionService = class(TInterfacedObject, ISkuchainInjectionService)
  public
    procedure GetValue(const ADestination: TRttiObject; const AActivation: ISkuchainActivation;
      out AValue: TInjectionValue);
  end;

implementation

uses
  Skuchain.Rtti.Utils
, Skuchain.Core.Token, Skuchain.Core.URL, Skuchain.Core.Engine, Skuchain.Core.Application
, Skuchain.JOSEJWT.Token
;

{ TSkuchainTokenInjectionService }

procedure TSkuchainTokenInjectionService.GetValue(const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation; out AValue: TInjectionValue);
var
  LType: TRttiType;
  LToken: TSkuchainToken;
begin
  LType := ADestination.GetRttiType;

  if (LType.IsObjectOfType(TSkuchainToken)) then
  begin
    if AActivation.HasToken then
      AValue := TInjectionValue.Create(AActivation.Token, True)
    else begin
      LToken := TSkuchainJOSEJWTToken.Create(AActivation.Request
        , AActivation.Response
        , AActivation.Application.Parameters
        , AActivation.URL
      );

      AValue := TInjectionValue.Create(LToken);
    end;
  end;
end;


procedure RegisterServices;
begin
  TSkuchainInjectionServiceRegistry.Instance.RegisterService(
    function :ISkuchainInjectionService
    begin
      Result := TSkuchainTokenInjectionService.Create;
    end
  , function (const ADestination: TRttiObject): Boolean
    var
      LType: TRttiType;
    begin
      Result := ((ADestination is TRttiParameter) or (ADestination is TRttiField) or (ADestination is TRttiProperty));
      if Result then
      begin
        LType := ADestination.GetRttiType;
        Result := LType.IsObjectOfType(TSkuchainToken);
      end;
    end
  );
end;

initialization
  RegisterServices;

end.
