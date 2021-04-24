(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.SubResource;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes

  , Skuchain.Client.Resource
  , Skuchain.Client.Client
  , Skuchain.Client.Application

  ;

type
  {$ifdef DelphiXE2_UP}
    [ComponentPlatformsAttribute(
        pidWin32 or pidWin64
     or pidOSX32
     or pidiOSSimulator
     or pidiOSDevice
    {$ifdef DelphiXE8_UP}
     or pidiOSDevice32 or pidiOSDevice64
    {$endif}
     or pidAndroid)]
  {$endif}
  TSkuchainClientSubResource = class(TSkuchainClientResource)
  private
    FParentResource: TSkuchainClientResource;
  protected
    function GetPath: string; override;
    function GetClient: TSkuchainCustomClient; override;
    function GetApplication: TSkuchainClientApplication; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;

  public
    constructor Create(AOwner: TComponent); override;

  published
    property ParentResource: TSkuchainClientResource read FParentResource write FParentResource;
  end;

procedure Register;

implementation

uses
    Skuchain.Client.Utils
  , Skuchain.Core.URL;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientSubResource]);
end;

{ TSkuchainClientSubResource }

constructor TSkuchainClientSubResource.Create(AOwner: TComponent);
begin
  inherited;

  if TSkuchainComponentHelper.IsDesigning(Self) then
    FParentResource := TSkuchainComponentHelper.FindDefault<TSkuchainClientResource>(Self);
end;

function TSkuchainClientSubResource.GetApplication: TSkuchainClientApplication;
begin
  if Assigned(FParentResource) then
    Result := FParentResource.Application
  else
    Result := inherited GetApplication;
end;

function TSkuchainClientSubResource.GetClient: TSkuchainCustomClient;
begin
  if Assigned(SpecificClient) then
    Result := SpecificClient
  else if Assigned(FParentResource) then
    Result := FParentResource.Client
  else
    Result := inherited GetClient;
end;

function TSkuchainClientSubResource.GetPath: string;
begin
  if Assigned(FParentResource) then
    Result := TSkuchainURL.CombinePath([FParentResource.Path, Resource])
  else
    Result := inherited GetPath;
end;

procedure TSkuchainClientSubResource.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (ParentResource = AComponent) then
    ParentResource := nil;
end;

end.
