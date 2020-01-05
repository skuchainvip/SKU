(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Client.Net;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Core.JSON, Skuchain.Client.Utils, Skuchain.Core.Utils, Skuchain.Client.Client

  // Net
  , System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent
  , System.Net.Mime
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
  TSkuchainNetClient = class(TSkuchainCustomClient)
  private
    FHttpClient: TNetHTTPClient;
    FLastResponse: IHTTPResponse;
  protected
    procedure AssignTo(Dest: TPersistent); override;
//    function GetProtocolVersion: TIdHTTPProtocolVersion;
//    procedure SetProtocolVersion(const Value: TIdHTTPProtocolVersion);

    procedure CloneCookies(const ADestination, ASource: TNetHTTPClient);

    function GetConnectTimeout: Integer; override;
    function GetReadTimeout: Integer; override;
    procedure SetConnectTimeout(const Value: Integer); override;
    procedure SetReadTimeout(const Value: Integer); override;

    function CreateMultipartFormData(AFormData: TArray<TFormParam>): TMultipartFormData;

    procedure EndorseAuthorization(const AAuthToken: string); override;
    procedure CheckLastCmdSuccess; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Delete(const AURL: string; AContent, AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); override;
    procedure Get(const AURL: string; AResponseContent: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); override;

    procedure Post(const AURL: string; AContent, AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); override;
    procedure Post(const AURL: string; const AFormData: TArray<TFormParam>;
      const AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); override;

    procedure Put(const AURL: string; AContent, AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); override;
    procedure Put(const AURL: string; const AFormData: System.TArray<TFormParam>;
      const AResponse: TStream; const AAuthToken: string;
      const AAccept: string; const AContentType: string); override;

    function LastCmdSuccess: Boolean; override;
    function ResponseStatusCode: Integer; override;
    function ResponseText: string; override;
  published
//    property ProtocolVersion: TIdHTTPProtocolVersion read GetProtocolVersion write SetProtocolVersion;
    property HttpClient: TNetHTTPClient read FHttpClient;
  end;

procedure Register;

implementation

uses
    Rtti, TypInfo
  , Skuchain.Client.CustomResource
  , Skuchain.Client.Resource
  , Skuchain.Client.Resource.JSON
  , Skuchain.Client.Resource.Stream
  , Skuchain.Client.Application
;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainNetClient]);
end;

{ TSkuchainNetClient }

procedure TSkuchainNetClient.AssignTo(Dest: TPersistent);
var
  LDestClient: TSkuchainNetClient;
begin
  inherited;
  if Dest is TSkuchainNetClient then
  begin
    LDestClient := Dest as TSkuchainNetClient;
//    LDestClient.ProtocolVersion := ProtocolVersion;
    LDestClient.AuthEndorsement := AuthEndorsement;
//    LDestClient.HttpClient.IOHandler := HttpClient.IOHandler;
    LDestClient.HttpClient.AllowCookies := HttpClient.AllowCookies;
    CloneCookies(LDestClient.HttpClient, HttpClient);
//    LDestClient.HttpClient.ProxyParams.BasicAuthentication := HttpClient.ProxyParams.BasicAuthentication;
//    LDestClient.HttpClient.ProxyParams.ProxyPort := HttpClient.ProxyParams.ProxyPort;
//    LDestClient.HttpClient.ProxyParams.ProxyServer := HttpClient.ProxyParams.ProxyServer;
//    LDestClient.HttpClient.Request.BasicAuthentication := HttpClient.Request.BasicAuthentication;
//    LDestClient.HttpClient.Request.Host := HttpClient.Request.Host;
//    LDestClient.HttpClient.Request.Password := HttpClient.Request.Password;
//    LDestClient.HttpClient.Request.Username := HttpClient.Request.Username;
  end;
end;

procedure TSkuchainNetClient.CheckLastCmdSuccess;
begin
  if not Assigned(FLastResponse) then
    Exit;

  if not LastCmdSuccess then
    raise ESkuchainClientHttpException.Create(FLastResponse.StatusText, FLastResponse.StatusCode);
end;

procedure TSkuchainNetClient.CloneCookies(const ADestination,
  ASource: TNetHTTPClient);
var
  LIndex: Integer;
  LCookie: TCookie;
  LURI: TURI;
begin
  for LIndex := 0 to Length(ASource.CookieManager.Cookies)-1 do
  begin
    LCookie := ASource.CookieManager.Cookies[LIndex];
    LURI := Default(TURI);
    LURI.Host := LCookie.Domain;
    LURI.Path := LCookie.Path;
    ADestination.CookieManager.AddServerCookie(LCookie, LURI);
  end;
end;

constructor TSkuchainNetClient.Create(AOwner: TComponent);
begin
  inherited;

  FHttpClient := TNetHTTPClient.Create(Self);
  try
    FHttpClient.SetSubComponent(True);
    FHttpClient.Name := 'HttpClient';
  except
    FHttpClient.Free;
    raise;
  end;
end;


procedure TSkuchainNetClient.Delete(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  inherited;
  FHttpClient.Accept := AAccept;
  FHttpClient.ContentType := AContentType;
  FLastResponse := FHttpClient.Delete(AURL, AResponse);
  CheckLastCmdSuccess;
end;

destructor TSkuchainNetClient.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

procedure TSkuchainNetClient.EndorseAuthorization(const AAuthToken: string);
begin
  if AuthEndorsement = AuthorizationBearer then
  begin
    if not (AAuthToken = '') then
      FHttpClient.CustomHeaders['Authorization'] := 'Bearer ' + AAuthToken
    else
      FHttpClient.CustomHeaders['Authorization'] := '';
  end;
end;

function TSkuchainNetClient.CreateMultipartFormData(
  AFormData: TArray<TFormParam>): TMultipartFormData;
var
  LFormParam: TFormParam;
begin
  Result := TMultipartFormData.Create();
  try
    for LFormParam in AFormData do
    begin
      if not LFormParam.IsFile then
        Result.AddField(LFormParam.FieldName, LFormParam.Value.ToString)
      else
      begin
        //TODO AM: save bytes to file and use TempFileName
        Result.AddFile(LFormParam.AsFile.FieldName, LFormParam.AsFile.FileName);
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TSkuchainNetClient.Get(const AURL: string; AResponseContent: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  FHttpClient.Accept := AAccept;
  FHttpClient.ContentType := AContentType;
  inherited;
  FLastResponse := FHttpClient.Get(AURL, AResponseContent);
  CheckLastCmdSuccess;
end;

function TSkuchainNetClient.GetConnectTimeout: Integer;
begin
  {$ifdef Delphi10Berlin_UP}
    Result := FHttpClient.ConnectionTimeout;
  {$else}
    Result := -1;
  {$endif}
end;

function TSkuchainNetClient.GetReadTimeout: Integer;
begin
  {$ifdef Delphi10Berlin_UP}
    Result := FHttpClient.ResponseTimeout;
  {$else}
    Result := -1;
  {$endif}
end;

function TSkuchainNetClient.LastCmdSuccess: Boolean;
begin
  Result := (FLastResponse.StatusCode >= 200) and (FLastResponse.StatusCode < 300)
end;

procedure TSkuchainNetClient.Post(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  inherited;
  FHttpClient.Accept := AAccept;
  FHttpClient.ContentType := AContentType;
  AContent.Position := 0;
  FLastResponse := FHttpClient.Post(AURL, AContent, AResponse);
  CheckLastCmdSuccess;
end;

procedure TSkuchainNetClient.Put(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  inherited;
  FHttpClient.Accept := AAccept;
  FHttpClient.ContentType := AContentType;
  AContent.Position := 0;
  FLastResponse := FHttpClient.Put(AURL, AContent, AResponse);
  CheckLastCmdSuccess;
end;

function TSkuchainNetClient.ResponseStatusCode: Integer;
begin
  Result := FLastResponse.StatusCode;
end;

function TSkuchainNetClient.ResponseText: string;
begin
  Result := FLastResponse.StatusText;
end;

procedure TSkuchainNetClient.SetConnectTimeout(const Value: Integer);
begin
  {$ifdef Delphi10Berlin_UP}
    FHttpClient.ConnectionTimeout := Value;
  {$else}
    // not available!
  {$endif}
end;

//procedure TSkuchainNetClient.SetProtocolVersion(const Value: TIdHTTPProtocolVersion);
//begin
//  FHttpClient.ProtocolVersion := Value;
//end;

procedure TSkuchainNetClient.SetReadTimeout(const Value: Integer);
begin
  {$ifdef Delphi10Berlin_UP}
    FHttpClient.ResponseTimeout := Value;
  {$else}
    // not available!
  {$endif}
end;

//function TSkuchainNetClient.GetProtocolVersion: TIdHTTPProtocolVersion;
//begin
//  Result := FHttpClient.ProtocolVersion;
//end;

procedure TSkuchainNetClient.Post(const AURL: string;
  const AFormData: TArray<TFormParam>; const AResponse: TStream;
  const AAuthToken, AAccept: string; const AContentType: string);
var
  LFormData: TMultipartFormData;
begin
  inherited;

  FHttpClient.Accept := AAccept;
  FHttpClient.ContentType := AContentType;
  LFormData := CreateMultipartFormData(AFormData);
  try
    FLastResponse := FHttpClient.Post(AURL, LFormData, AResponse);
    CheckLastCmdSuccess;
  finally
    LFormData.Free;
  end;
end;

procedure TSkuchainNetClient.Put(const AURL: string;
  const AFormData: System.TArray<TFormParam>; const AResponse: TStream;
  const AAuthToken, AAccept: string; const AContentType: string);
var
  LFormData: TMultipartFormData;
begin
  inherited;

  FHttpClient.Accept := AAccept;
  FHttpClient.ContentType := AContentType;
  LFormData := CreateMultipartFormData(AFormData);
  try
    //TODO AM: verify if calling PUT with LFormData.Stream is safe enough and actually working
    // (TNetHttpClient does not provide an overload of put for TMultipartFormData (10.2.2 Tokyo)
    LFormData.Stream.Position := 0;
    FHttpClient.ContentType := LFormData.MimeTypeHeader;
    FLastResponse := FHttpClient.Put(AURL, LFormData.Stream, AResponse);
    CheckLastCmdSuccess;
  finally
    LFormData.Free;
  end;
end;


end.
