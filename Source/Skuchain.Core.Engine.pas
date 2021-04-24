(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Engine;

{$I Skuchain.inc}

interface

uses
  SysUtils, HTTPApp, Classes, Generics.Collections
  , SyncObjs

  , Skuchain.Core.Classes
  , Skuchain.Core.Registry
  , Skuchain.Core.Application
  , Skuchain.Core.URL
  , Skuchain.Core.Exceptions
  , Skuchain.Utils.Parameters
;

{$M+}

const
  DEFAULT_ENGINE_NAME = 'DefaultEngine';

type
  ESkuchainEngineException = class(ESkuchainHttpException);
  TSkuchainEngine = class;

  TSkuchainEngineBeforeHandleRequestEvent = reference to function(AEngine: TSkuchainEngine;
    AURL: TSkuchainURL; ARequest: TWebRequest; AResponse: TWebResponse; var Handled: Boolean): Boolean;

  TSkuchainEngine = class
  private
    FApplications: TSkuchainApplicationDictionary;
    FCriticalSection: TCriticalSection;
    FParameters: TSkuchainParameters;
    FName: string;
    FOnBeforeHandleRequest: TSkuchainEngineBeforeHandleRequestEvent;
  protected
    function GetBasePath: string; virtual;
    function GetPort: Integer; virtual;
    function GetThreadPoolSize: Integer; virtual;
    procedure SetBasePath(const Value: string); virtual;
    procedure SetPort(const Value: Integer); virtual;
    procedure SetThreadPoolSize(const Value: Integer); virtual;
    procedure PatchCORS(const ARequest: TWebRequest; const AResponse: TWebResponse); virtual;
  public
    constructor Create(const AName: string = DEFAULT_ENGINE_NAME); virtual;
    destructor Destroy; override;

    function HandleRequest(ARequest: TWebRequest; AResponse: TWebResponse): Boolean; virtual;

    function AddApplication(const AName, ABasePath: string;
      const AResources: array of string; const AParametersSliceName: string = ''): TSkuchainApplication; virtual;

    procedure EnumerateApplications(const ADoSomething: TProc<string, TSkuchainApplication>); virtual;

    property Applications: TSkuchainApplicationDictionary read FApplications;
    property Parameters: TSkuchainParameters read FParameters;

    property BasePath: string read GetBasePath write SetBasePath;
    property Name: string read FName;
    property Port: Integer read GetPort write SetPort;
    property ThreadPoolSize: Integer read GetThreadPoolSize write SetThreadPoolSize;

    property OnBeforeHandleRequest: TSkuchainEngineBeforeHandleRequestEvent read FOnBeforeHandleRequest write FOnBeforeHandleRequest;
  end;

  TSkuchainEngineRegistry=class
  private
    FItems: TDictionary<string, TSkuchainEngine>;
    FCriticalSection: TCriticalSection;
  protected
    class var _Instance: TSkuchainEngineRegistry;
    class function GetInstance: TSkuchainEngineRegistry; static;
    function GetCount: Integer; virtual;
    function GetEngine(const AName: string): TSkuchainEngine; virtual;
    class function GetDefaultEngine: TSkuchainEngine; static;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure RegisterEngine(const AEngine: TSkuchainEngine); virtual;
    procedure UnregisterEngine(const AEngine: TSkuchainEngine); overload; virtual;
    procedure UnregisterEngine(const AEngineName: string); overload; virtual;

    procedure EnumerateEngines(const ADoSomething: TProc<string, TSkuchainEngine>); virtual;

    property Engine[const AName: string]: TSkuchainEngine read GetEngine; default;

    property Count: Integer read GetCount;

    class property Instance: TSkuchainEngineRegistry read GetInstance;
    class property DefaultEngine: TSkuchainEngine read GetDefaultEngine;
    class destructor ClassDestructor;
  end;

implementation

uses
    Skuchain.Core.Utils
  , Skuchain.Core.Activation, Skuchain.Core.Activation.Interfaces
  , Skuchain.Core.MediaType
  ;

function TSkuchainEngine.AddApplication(const AName, ABasePath: string;
  const AResources: array of string; const AParametersSliceName: string): TSkuchainApplication;
var
  LResource: string;
  LParametersSliceName: string;
begin
  Result := TSkuchainApplication.Create(AName);
  try
    Result.BasePath := ABasePath;
    for LResource in AResources do
      Result.AddResource(LResource);

    LParametersSliceName := AParametersSliceName;
    if LParametersSliceName = '' then
      LParametersSliceName := AName;
    Result.Parameters.CopyFrom(Parameters, LParametersSliceName);

    FCriticalSection.Enter;
    try
      Applications.Add(
        TSkuchainURL.CombinePath([BasePath, ABasePath]).ToLower
        , Result
      );
    finally
      FCriticalSection.Leave;
    end;
  except
    Result.Free;
    raise
  end;
end;

constructor TSkuchainEngine.Create(const AName: string);
begin
  inherited Create;

  FName := AName;

  FApplications := TSkuchainApplicationDictionary.Create([doOwnsValues]);
  FCriticalSection := TCriticalSection.Create;
  FParameters := TSkuchainParameters.Create(FName);

  // default parameters
  Parameters.Values['Port'] := 8080;
  Parameters.Values['ThreadPoolSize'] := 75;
  Parameters.Values['BasePath'] := '/rest';

  TSkuchainEngineRegistry.Instance.RegisterEngine(Self);
end;

destructor TSkuchainEngine.Destroy;
begin
  TSkuchainEngineRegistry.Instance.UnregisterEngine(Self);

  FParameters.Free;
  FCriticalSection.Free;
  FApplications.Free;
  inherited;
end;

procedure TSkuchainEngine.EnumerateApplications(
  const ADoSomething: TProc<string, TSkuchainApplication>);
var
  LPair: TPair<string, TSkuchainApplication>;
begin
  if Assigned(ADoSomething) then
  begin
    FCriticalSection.Enter;
    try
      for LPair in FApplications do
        ADoSomething(LPair.Key, LPair.Value);
    finally
      FCriticalSection.Leave;
    end;
  end;
end;

function TSkuchainEngine.HandleRequest(ARequest: TWebRequest; AResponse: TWebResponse): Boolean;
var
  LApplication: TSkuchainApplication;
  LURL: TSkuchainURL;
  LApplicationPath: string;
  LActivation: ISkuchainActivation;
begin
  Result := False;

  PatchCORS(ARequest, AResponse);

  LURL := TSkuchainURL.Create(ARequest);
  try
    if Assigned(FOnBeforeHandleRequest) then
      if not FOnBeforeHandleRequest(Self, LURL, ARequest, AResponse, Result) then
        Exit;

    LApplicationPath := '';
    if LURL.HasPathTokens then
      LApplicationPath := TSkuchainURL.CombinePath([LURL.PathTokens[0]]);

    if (BasePath <> '') and (BasePath <> TSkuchainURL.URL_PATH_SEPARATOR) then
    begin
      if not LURL.MatchPath(BasePath) then
        raise ESkuchainEngineException.Create(
            Format('Bad request [%s] does not match engine URL [%s]', [LURL.URL, BasePath])
            , 404
          );
      if LURL.HasPathTokens(2) then
        LApplicationPath := TSkuchainURL.CombinePath([LURL.PathTokens[0], LURL.PathTokens[1]]);
    end;

    if not FApplications.TryGetValue(LApplicationPath.ToLower, LApplication) then
      raise ESkuchainEngineException.Create(Format('Bad request [%s]: unknown application [%s]', [LURL.URL, LApplicationPath]), 404);

    LURL.BasePath := LApplicationPath;
    try
      LActivation := TSkuchainActivation.CreateActivation(Self, LApplication, ARequest, AResponse, LURL);
      try
        LActivation.Invoke;
      finally
        LActivation := nil;
      end;
    except on E: Exception do
      if E is ESkuchainHttpException then
      begin
        AResponse.StatusCode := ESkuchainHttpException(E).Status;
        AResponse.Content := E.Message;
        AResponse.ContentType := TMediaType.TEXT_HTML;
      end
      else begin
        AResponse.StatusCode := 500;
        AResponse.Content := 'Internal server error'
        {$IFDEF DEBUG}
          + ': ' + E.Message
        {$ENDIF}
        ;
        AResponse.ContentType := TMediaType.TEXT_PLAIN;
    //    raise;
      end;
    end;
    Result := True;
  finally
    LURL.Free;
  end;
end;

procedure TSkuchainEngine.PatchCORS(const ARequest: TWebRequest;
  const AResponse: TWebResponse);

  procedure SetHeaderFromParameter(const AHeader, AParamName, ADefault: string);
  begin
    AResponse.CustomHeaders.Values[AHeader] :=
      Parameters.ByName(AParamName, ADefault).AsString;
  end;

begin
  if Parameters.ByName('CORS.Enabled').AsBoolean then
  begin
    SetHeaderFromParameter('Access-Control-Allow-Origin', 'CORS.Origin', '*');
    SetHeaderFromParameter('Access-Control-Allow-Methods', 'CORS.Methods', 'HEAD,GET,PUT,POST,DELETE,OPTIONS');
    SetHeaderFromParameter('Access-Control-Allow-Headers', 'CORS.Headers', 'X-Requested-With, Content-Type');
  end;
end;

function TSkuchainEngine.GetBasePath: string;
begin
  Result := Parameters['BasePath'].AsString;
end;

procedure TSkuchainEngine.SetBasePath(const Value: string);
begin
  Parameters['BasePath'] := Value;
end;

procedure TSkuchainEngine.SetPort(const Value: Integer);
begin
  Parameters['Port'] := Value;
end;

procedure TSkuchainEngine.SetThreadPoolSize(const Value: Integer);
begin
  Parameters['ThreadPoolSize'] := Value;
end;

function TSkuchainEngine.GetPort: Integer;
begin
  Result := Parameters['Port'].AsInteger;
end;

function TSkuchainEngine.GetThreadPoolSize: Integer;
begin
  Result := Parameters['ThreadPoolSize'].AsInteger;
end;

{ TSkuchainEngineRegistry }

class destructor TSkuchainEngineRegistry.ClassDestructor;
begin
  if Assigned(_Instance) then
    FreeAndNil(_Instance);
end;

constructor TSkuchainEngineRegistry.Create;
begin
  inherited Create;
  FItems := TDictionary<string, TSkuchainEngine>.Create;
  FCriticalSection := TCriticalSection.Create;
end;

destructor TSkuchainEngineRegistry.Destroy;
begin
  FCriticalSection.Free;
  FItems.Free;
  inherited;
end;

procedure TSkuchainEngineRegistry.EnumerateEngines(
  const ADoSomething: TProc<string, TSkuchainEngine>);
var
  LPair: TPair<string, TSkuchainEngine>;
begin
  if Assigned(ADoSomething) then
  begin
    FCriticalSection.Enter;
    try
      for LPair in FItems do
        ADoSomething(LPair.Key, LPair.Value);
    finally
      FCriticalSection.Leave;
    end;
  end;
end;

function TSkuchainEngineRegistry.GetCount: Integer;
begin
  Result := FItems.Count;
end;

class function TSkuchainEngineRegistry.GetDefaultEngine: TSkuchainEngine;
begin
  Result := Instance.Engine[DEFAULT_ENGINE_NAME];
end;

function TSkuchainEngineRegistry.GetEngine(const AName: string): TSkuchainEngine;
begin
  if not FItems.TryGetValue(AName, Result) then
    Result := nil;
end;

class function TSkuchainEngineRegistry.GetInstance: TSkuchainEngineRegistry;
begin
  if not Assigned(_Instance) then
    _Instance := TSkuchainEngineRegistry.Create;
  Result := _Instance;
end;

procedure TSkuchainEngineRegistry.RegisterEngine(const AEngine: TSkuchainEngine);
begin
  Assert(Assigned(AEngine));

  FCriticalSection.Enter;
  try
    FItems.AddOrSetValue(AEngine.Name, AEngine);
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSkuchainEngineRegistry.UnregisterEngine(const AEngine: TSkuchainEngine);
begin
  Assert(Assigned(AEngine));

  UnregisterEngine(AEngine.Name);
end;

procedure TSkuchainEngineRegistry.UnregisterEngine(const AEngineName: string);
begin
  FCriticalSection.Enter;
  try
    FItems.Remove(AEngineName);
  finally
    FCriticalSection.Leave;
  end;
end;

end.
