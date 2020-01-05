(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Data.FireDAC.InjectionService;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti, Types
  , Skuchain.Core.Injection
  , Skuchain.Core.Injection.Interfaces
  , Skuchain.Core.Injection.Types
  , Skuchain.Core.Activation.Interfaces
;

type
  TSkuchainFireDACInjectionService = class(TInterfacedObject, ISkuchainInjectionService)
  protected
    function GetConnectionDefName(const ADestination: TRttiObject;
      const AActivation: ISkuchainActivation): string;
  public
    procedure GetValue(const ADestination: TRttiObject;
      const AActivation: ISkuchainActivation; out AValue: TInjectionValue);

    const FireDAC_ConnectionDefName_PARAM = 'FireDAC.ConnectionDefName';
    const FireDAC_ConnectionDefName_PARAM_DEFAULT = 'MAIN_DB';
  end;

implementation

uses
  Skuchain.Rtti.Utils
, Skuchain.Core.Token, Skuchain.Core.URL, Skuchain.Core.Engine, Skuchain.Core.Application
, Data.DB, FireDAC.Comp.Client
, Skuchain.Data.FireDAC
;


{ TSkuchainFireDACInjectionService }

function TSkuchainFireDACInjectionService.GetConnectionDefName(
  const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation): string;
var
  LConnectionDefName: string;
begin
  LConnectionDefName := '';

  // field, property or method param annotation
  ADestination.HasAttribute<ConnectionAttribute>(
    procedure (AAttrib: ConnectionAttribute)
    begin
      LConnectionDefName := AAttrib.ConnectionDefName;
    end
  );

  // second chance: method annotation
  if (LConnectionDefName = '') then
    AActivation.Method.HasAttribute<ConnectionAttribute>(
      procedure (AAttrib: ConnectionAttribute)
      begin
        LConnectionDefName := AAttrib.ConnectionDefName;
      end
    );

  // third chance: resource annotation
  if (LConnectionDefName = '') then
    AActivation.Resource.HasAttribute<ConnectionAttribute>(
      procedure (AAttrib: ConnectionAttribute)
      begin
        LConnectionDefName := AAttrib.ConnectionDefName;
      end
    );

  // last chance: application parameters
  if (LConnectionDefName = '') then
    LConnectionDefName := AActivation.Application.Parameters.ByName(
      FireDAC_ConnectionDefName_PARAM, FireDAC_ConnectionDefName_PARAM_DEFAULT
    ).AsString;

  Result := LConnectionDefName;
end;

procedure TSkuchainFireDACInjectionService.GetValue(const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation; out AValue: TInjectionValue);
begin
  if ADestination.GetRttiType.IsObjectOfType(TFDConnection) then
    AValue := TInjectionValue.Create(
      TSkuchainFireDAC.CreateConnectionByDefName(GetConnectionDefName(ADestination, AActivation))
    )
  else if ADestination.GetRttiType.IsObjectOfType(TSkuchainFireDAC) then
    AValue := TInjectionValue.Create(
      TSkuchainFireDAC.Create(GetConnectionDefName(ADestination, AActivation), AActivation)
    );
end;

procedure RegisterServices;
begin
  TSkuchainInjectionServiceRegistry.Instance.RegisterService(
    function :ISkuchainInjectionService
    begin
      Result := TSkuchainFireDACInjectionService.Create;
    end
  , function (const ADestination: TRttiObject): Boolean
    var
      LType: TRttiType;
    begin
      Result := ((ADestination is TRttiParameter) or (ADestination is TRttiField) or (ADestination is TRttiProperty));
      if Result then
      begin
        LType := ADestination.GetRttiType;
        Result := LType.IsObjectOfType(TFDConnection)
          or LType.IsObjectOfType(TSkuchainFireDAC);
      end;
    end
  );
end;

initialization
  RegisterServices;

end.