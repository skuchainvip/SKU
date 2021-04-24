(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.dmustache.InjectionService;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti
  , Skuchain.Core.Injection
  , Skuchain.Core.Injection.Interfaces
  , Skuchain.Core.Injection.Types
  , Skuchain.Core.Activation.Interfaces
  , Skuchain.dmustache
  , SynMustache, SynCommons
;

type
  TSkuchaindmustacheInjectionService = class(TInterfacedObject, ISkuchainInjectionService)
  protected
    function GetName(const ADestination: TRttiObject;
      const AActivation: ISkuchainActivation): string;
  public
    procedure GetValue(const ADestination: TRttiObject; const AActivation: ISkuchainActivation;
      out AValue: TInjectionValue);

    const dmustache_Name_PARAM = 'dmustache.Name';
    const dmustache_Name_PARAM_DEFAULT = 'Engine';
  end;

implementation

uses
    Skuchain.Rtti.Utils, Skuchain.Core.Attributes
  , Skuchain.Core.Token, Skuchain.Core.URL, Skuchain.Core.Engine, Skuchain.Core.Application
;

{ TSkuchaindmustacheInjectionService }

function TSkuchaindmustacheInjectionService.GetName(
  const ADestination: TRttiObject; const AActivation: ISkuchainActivation): string;
var
  LName: string;
begin
  LName := '';

  // field, property or method param annotation
  ADestination.HasAttribute<dmustacheAttribute>(
    procedure (AAttrib: dmustacheAttribute)
    begin
      LName := AAttrib.Name;
    end
  );

  // second chance: method annotation
  if (LName = '') then
    AActivation.Method.HasAttribute<dmustacheAttribute>(
      procedure (AAttrib: dmustacheAttribute)
      begin
        LName := AAttrib.Name;
      end
    );

  // third chance: resource annotation
  if (LName = '') then
    AActivation.Resource.HasAttribute<dmustacheAttribute>(
      procedure (AAttrib: dmustacheAttribute)
      begin
        LName := AAttrib.Name;
      end
    );

  // last chance: application parameters
  if (LName = '') then
    LName := AActivation.Application.Parameters.ByName(
      dmustache_Name_PARAM, dmustache_Name_PARAM_DEFAULT
    ).AsString;

  Result := LName;
end;

procedure TSkuchaindmustacheInjectionService.GetValue(const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation; out AValue: TInjectionValue);
begin
  if ADestination.GetRttiType.IsObjectOfType(TSkuchaindmustache) then
    AValue := TInjectionValue.Create(
      TSkuchaindmustache.Create(GetName(ADestination, AActivation), AActivation)
    );
end;


procedure RegisterServices;
begin
  TSkuchainInjectionServiceRegistry.Instance.RegisterService(
    function :ISkuchainInjectionService
    begin
      Result := TSkuchaindmustacheInjectionService.Create;
    end
  , function (const ADestination: TRttiObject): Boolean
    var
      LType: TRttiType;
    begin
      Result := ((ADestination is TRttiParameter) or (ADestination is TRttiField) or (ADestination is TRttiProperty));
      if Result then
      begin
        LType := ADestination.GetRttiType;
        Result := LType.IsObjectOfType(TSkuchaindmustache);
      end;
    end
  );
end;

initialization
  RegisterServices;

end.
