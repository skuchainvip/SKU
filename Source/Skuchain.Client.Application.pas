(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Application;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Client.Client
  , Skuchain.Client.Utils
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
  TSkuchainClientApplication = class(TComponent)
  private
    FAppName: string;
    FDefaultMediaType: string;
    FDefaultContentType: string;
    FClient: TSkuchainCustomClient;
    FOnError: TSkuchainClientErrorEvent;
  protected
    function GetPath: string; virtual;
    procedure AssignTo(Dest: TPersistent); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DoError(const AResource: TObject; const AException: Exception; const AVerb: TSkuchainHttpVerb; const AAfterExecute: TSkuchainClientResponseProc); virtual;

    const DEFAULT_APPNAME = 'default';
  published
    property DefaultMediaType: string read FDefaultMediaType write FDefaultMediaType;
    property DefaultContentType: string read FDefaultContentType write FDefaultContentType;
    [Default(DEFAULT_APPNAME)]
    property AppName: string read FAppName write FAppName;
    property Client: TSkuchainCustomClient read FClient write FClient;
    property Path: string read GetPath;
    property OnError: TSkuchainClientErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

uses
  Skuchain.Core.URL, Skuchain.Core.MediaType
  ;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientApplication]);
end;

{ TSkuchainClientApplication }

procedure TSkuchainClientApplication.AssignTo(Dest: TPersistent);
var
  LDestApp: TSkuchainClientApplication;
begin
//  inherited;
  LDestApp := Dest as TSkuchainClientApplication;

  LDestApp.DefaultMediaType := DefaultMediaType;
  LDestApp.DefaultContentType := DefaultContentType;
  LDestApp.AppName := AppName;
  LDestApp.Client := Client;
  LDestApp.OnError := OnError;
end;

constructor TSkuchainClientApplication.Create(AOwner: TComponent);
begin
  inherited;
  FDefaultMediaType := TMediaType.APPLICATION_JSON;
  FDefaultContentType := TMediaType.APPLICATION_JSON;
  FAppName := DEFAULT_APPNAME;
  if TSkuchainComponentHelper.IsDesigning(Self) and not Assigned(FClient) then
    FClient := TSkuchainComponentHelper.FindDefault<TSkuchainCustomClient>(Self);
end;

procedure TSkuchainClientApplication.DoError(const AResource: TObject;
  const AException: Exception; const AVerb: TSkuchainHttpVerb;
  const AAfterExecute: TSkuchainClientResponseProc);
var
  LHandled: Boolean;
begin
  LHandled := False;
  if Assigned(FOnError) then
    FOnError(AResource, AException, AVerb, AAfterExecute, LHandled);

  if not LHandled then
  begin
    if Assigned(Client) then
      Client.DoError(AResource, AException, AVerb, AAfterExecute)
    else
      raise ESkuchainClientException.Create(AException.Message);
  end;
end;

function TSkuchainClientApplication.GetPath: string;
var
  LEngine: string;
begin
  LEngine := '';
  if Assigned(FClient) then
    LEngine := FClient.SkuchainEngineURL;

  Result := TSkuchainURL.CombinePath([LEngine, AppName])
end;

procedure TSkuchainClientApplication.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (Client = AComponent) then
    Client := nil;
  if not Assigned(Client) and (Operation = opInsert) and TSkuchainComponentHelper.IsDesigning(Self) then
    Client := TSkuchainComponentHelper.FindDefault<TSkuchainCustomClient>(Self);
end;

end.
