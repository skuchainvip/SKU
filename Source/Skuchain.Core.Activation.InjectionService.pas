(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Activation.InjectionService;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti
  , Skuchain.Core.Injection
  , Skuchain.Core.Injection.Interfaces
  , Skuchain.Core.Injection.Types
  , Skuchain.Core.Activation.Interfaces
;

type
  TSkuchainActivationInjectionService = class(TInterfacedObject, ISkuchainInjectionService)
  public
    procedure GetValue(const ADestination: TRttiObject; const AActivation: ISkuchainActivation;
      out AValue: TInjectionValue);
  end;

implementation

uses
    Skuchain.Rtti.Utils
  , Skuchain.Core.Token, Skuchain.Core.URL, Skuchain.Core.Engine, Skuchain.Core.Application, Skuchain.Core.Attributes
{$ifdef DelphiXE6_UP}
  , Web.HttpApp
{$else}
  , HttpApp
{$endif}
;

{ TSkuchainActivationInjectionService }

procedure TSkuchainActivationInjectionService.GetValue(const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation; out AValue: TInjectionValue);
var
  LType: TRttiType;
  LValue: TInjectionValue;
begin
  LType := ADestination.GetRttiType;

  LValue.Clear;
  if ADestination.HasAttribute<RequestParamAttribute>(
    procedure (AParam: RequestParamAttribute)
    begin
      LValue := TInjectionValue.Create(
        AParam.GetValue(ADestination, AActivation), ADestination.HasAttribute<IsReference>
      );
    end
  ) then
    AValue := LValue
  else if ADestination.HasAttribute<ConfigParamAttribute>(
    procedure (AConfigParam: ConfigParamAttribute)
    begin
      LValue := TInjectionValue.Create(AConfigParam.GetValue(ADestination, AActivation), False);
    end
  ) then
    AValue := LValue
  else if (LType.IsObjectOfType(TWebRequest)) then
    AValue := TInjectionValue.Create(AActivation.Request, True)
  else if (LType.IsObjectOfType(TWebResponse)) then
    AValue := TInjectionValue.Create(AActivation.Response, True)
  else if (LType.IsObjectOfType(TSkuchainURL)) then
    AValue := TInjectionValue.Create(AActivation.URL, True)
  else if (LType.IsObjectOfType(TSkuchainEngine)) then
    AValue := TInjectionValue.Create(AActivation.Engine, True)
  else if (LType.IsObjectOfType(TSkuchainApplication)) then
    AValue := TInjectionValue.Create(AActivation.Application, True)
  else if (LType is TRttiInterfaceType) and (LType.Handle = TypeInfo(ISkuchainActivation)) then
    AValue := TInjectionValue.Create(TValue.From<ISkuchainActivation>(AActivation), True);
end;


procedure RegisterServices;
begin
  TSkuchainInjectionServiceRegistry.Instance.RegisterService(
    function :ISkuchainInjectionService
    begin
      Result := TSkuchainActivationInjectionService.Create;
    end
  , function (const ADestination: TRttiObject): Boolean
    var
      LType: TRttiType;
    begin
      Result := ((ADestination is TRttiParameter) or (ADestination is TRttiField) or (ADestination is TRttiProperty));
      if Result then
      begin
        LType := ADestination.GetRttiType;
        Result :=
          ADestination.HasAttribute<RequestParamAttribute>
          or ADestination.HasAttribute<ConfigParamAttribute>
          or LType.IsObjectOfType(TWebRequest)
          or LType.IsObjectOfType(TWebResponse)
          or LType.IsObjectOfType(TSkuchainURL)
          or LType.IsObjectOfType(TSkuchainEngine)
          or LType.IsObjectOfType(TSkuchainApplication)
          or (LType.Handle = TypeInfo(ISkuchainActivation));
      end;
    end
  );
end;

initialization
  RegisterServices;

end.
