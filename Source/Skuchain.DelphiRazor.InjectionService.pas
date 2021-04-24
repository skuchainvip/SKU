(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.DelphiRazor.InjectionService;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti
  , Skuchain.Core.Injection
  , Skuchain.Core.Injection.Interfaces
  , Skuchain.Core.Injection.Types
  , Skuchain.Core.Activation.Interfaces
  , Skuchain.DelphiRazor
  , RlxRazor
;

type
  TSkuchainDelphiRazorInjectionService = class(TInterfacedObject, ISkuchainInjectionService)
  protected
    function GetName(const ADestination: TRttiObject;
      const AActivation: ISkuchainActivation): string;
  public
    procedure GetValue(const ADestination: TRttiObject; const AActivation: ISkuchainActivation;
      out AValue: TInjectionValue);

    const DelphiRazor_Name_PARAM = 'DelphiRazor.Name';
    const DelphiRazor_Name_PARAM_DEFAULT = 'Engine';
  end;

implementation

uses
    Skuchain.Rtti.Utils, Skuchain.Core.Attributes
  , Skuchain.Core.Token, Skuchain.Core.URL, Skuchain.Core.Engine, Skuchain.Core.Application
;

{ TSkuchainDelphiRazorInjectionService }

function TSkuchainDelphiRazorInjectionService.GetName(
  const ADestination: TRttiObject; const AActivation: ISkuchainActivation): string;
var
  LName: string;
begin
  LName := '';

  // field, property or method param annotation
  ADestination.HasAttribute<RazorEngineAttribute>(
    procedure (AAttrib: RazorEngineAttribute)
    begin
      LName := AAttrib.Name;
    end
  );

  // second chance: method annotation
  if (LName = '') then
    AActivation.Method.HasAttribute<RazorEngineAttribute>(
      procedure (AAttrib: RazorEngineAttribute)
      begin
        LName := AAttrib.Name;
      end
    );

  // third chance: resource annotation
  if (LName = '') then
    AActivation.Resource.HasAttribute<RazorEngineAttribute>(
      procedure (AAttrib: RazorEngineAttribute)
      begin
        LName := AAttrib.Name;
      end
    );

  // last chance: application parameters
  if (LName = '') then
    LName := AActivation.Application.Parameters.ByName(
      DelphiRazor_Name_PARAM, DelphiRazor_Name_PARAM_DEFAULT
    ).AsString;

  Result := LName;
end;

procedure TSkuchainDelphiRazorInjectionService.GetValue(const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation; out AValue: TInjectionValue);
begin

  if ADestination.GetRttiType.IsObjectOfType(TRlxRazorEngine) then
    AValue := TInjectionValue.Create(
      TRlxRazorEngine.Create(nil)
    )
  else if ADestination.GetRttiType.IsObjectOfType(TRlxRazorProcessor) then
    AValue := TInjectionValue.Create(
      TRlxRazorProcessor.Create(nil)
    )
  else if ADestination.GetRttiType.IsObjectOfType(TSkuchainDelphiRazor) then
    AValue := TInjectionValue.Create(
      TSkuchainDelphiRazor.Create(GetName(ADestination, AActivation), AActivation)
    );
end;


procedure RegisterServices;
begin
  TSkuchainInjectionServiceRegistry.Instance.RegisterService(
    function :ISkuchainInjectionService
    begin
      Result := TSkuchainDelphiRazorInjectionService.Create;
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
          LType.IsObjectOfType(TSkuchainDelphiRazor)
          or LType.IsObjectOfType(TRlxRazorEngine)
          or LType.IsObjectOfType(TRlxRazorProcessor)
        ;
      end;
    end
  );
end;

initialization
  RegisterServices;

end.
