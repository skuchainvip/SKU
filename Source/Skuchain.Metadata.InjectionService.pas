(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Metadata.InjectionService;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti, Generics.Collections
  , Skuchain.Core.Injection
  , Skuchain.Core.Injection.Interfaces
  , Skuchain.Core.Injection.Types
  , Skuchain.Core.Activation.Interfaces
;

type
  TSkuchainMetadataInjectionService = class(TInterfacedObject, ISkuchainInjectionService)
  protected
  public
    procedure GetValue(const ADestination: TRttiObject; const AActivation: ISkuchainActivation;
      out AValue: TInjectionValue);
  end;

implementation

uses
    Skuchain.Rtti.Utils, Skuchain.Core.Attributes
  , Skuchain.Core.Engine, Skuchain.Core.Application
  , Skuchain.Metadata
  , Skuchain.Metadata.Reader
;

{ TSkuchainMetadataInjectionService }

procedure TSkuchainMetadataInjectionService.GetValue(const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation; out AValue: TInjectionValue);
var
  LReader: TSkuchainMetadataReader;
  LValue: TInjectionValue;
begin
  LReader := TSkuchainMetadataReader.Create(AActivation.Engine);
  try
    AActivation.AddToContext(LReader);
  except
    LReader.Free;
    raise;
  end;


  LValue.Clear;
  if ADestination.GetRttiType.IsObjectOfType(TSkuchainEngineMetadata) then
    LValue := TInjectionValue.Create(LReader.Metadata, True)
  else if ADestination.GetRttiType.IsObjectOfType(TSkuchainApplicationMetadata) then
  begin
    LReader.Metadata.ForEachApplication(
      procedure (AMetaApp: TSkuchainApplicationMetadata)
      begin
        if AMetaApp.Name = AActivation.Application.Name then
          LValue := TInjectionValue.Create(AMetaApp, True)
      end
    );
  end;

  AValue := LValue;
end;


procedure RegisterServices;
begin
  TSkuchainInjectionServiceRegistry.Instance.RegisterService(
    function :ISkuchainInjectionService
    begin
      Result := TSkuchainMetadataInjectionService.Create;
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
          LType.IsObjectOfType(TSkuchainEngineMetadata)
          or LType.IsObjectOfType(TSkuchainApplicationMetadata)
        ;
      end;
    end
  );
end;

initialization
  RegisterServices;

end.
