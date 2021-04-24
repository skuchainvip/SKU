(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Client.Indy;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Core.JSON, Skuchain.Client.Utils, Skuchain.Core.Utils, Skuchain.Client.Client

  // Indy
  , IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, IdMultipartFormData
  , IdCookie, IdCookieManager
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
  TSkuchainIndyClient = class(TSkuchainCustomClient)
  private
    FHttpClient: TIdHTTP;
  protected
    procedure AssignTo(Dest: TPersistent); override;
//    function GetRequest: TIdHTTPRequest;
//    function GetResponse: TIdHTTPResponse;

    procedure CloneCookies(const ADestination, ASource: TIdHTTP);

    function GetProtocolVersion: TIdHTTPProtocolVersion;
    procedure SetProtocolVersion(const Value: TIdHTTPProtocolVersion);

    function GetConnectTimeout: Integer; override;
    function GetReadTimeout: Integer; override;

    procedure SetConnectTimeout(const Value: Integer); override;
    procedure SetReadTimeout(const Value: Integer); override;

    function CreateMultipartFormData(AFormData: TArray<TFormParam>): TIdMultiPartFormDataStream;

    procedure EndorseAuthorization(const AAuthToken: string); override;
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
    procedure Put(const AURL: string; const AFormData: TArray<TFormParam>;
      const AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); override;

    function LastCmdSuccess: Boolean; override;
    function ResponseStatusCode: Integer; override;
    function ResponseText: string; override;

  //  property Request: TIdHTTPRequest read GetRequest;
  //  property Response: TIdHTTPResponse read GetResponse;

  published
    property ProtocolVersion: TIdHTTPProtocolVersion read GetProtocolVersion write SetProtocolVersion;
    property HttpClient: TIdHTTP read FHttpClient;
  end;

  TSkuchainClient = class(TSkuchainIndyClient); // compatibility

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
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClient]);
end;

{ TSkuchainIndyClient }

procedure TSkuchainIndyClient.AssignTo(Dest: TPersistent);
var
  LDestClient: TSkuchainIndyClient;
begin
  inherited;
  if Dest is TSkuchainIndyClient then
  begin
    LDestClient := Dest as TSkuchainIndyClient;
    LDestClient.ProtocolVersion := ProtocolVersion;
    LDestClient.AuthEndorsement := AuthEndorsement;
    LDestClient.HttpClient.IOHandler := HttpClient.IOHandler;
    LDestClient.HttpClient.AllowCookies := HttpClient.AllowCookies;
    CloneCookies(LDestClient.HttpClient, HttpClient);
    LDestClient.HttpClient.ProxyParams.BasicAuthentication := HttpClient.ProxyParams.BasicAuthentication;
    LDestClient.HttpClient.ProxyParams.ProxyPort := HttpClient.ProxyParams.ProxyPort;
    LDestClient.HttpClient.ProxyParams.ProxyServer := HttpClient.ProxyParams.ProxyServer;
    LDestClient.HttpClient.Request.BasicAuthentication := HttpClient.Request.BasicAuthentication;
    LDestClient.HttpClient.Request.Host := HttpClient.Request.Host;
    LDestClient.HttpClient.Request.Password := HttpClient.Request.Password;
    LDestClient.HttpClient.Request.Username := HttpClient.Request.Username;
  end;
end;

procedure TSkuchainIndyClient.CloneCookies(const ADestination, ASource: TIdHTTP);
var
  LCookieManager: TIdCookieManager;
begin
  if ASource.AllowCookies and Assigned(ASource.CookieManager) then
  begin
    LCookieManager := TIdCookieManager.Create(ADestination);
    try
      LCookieManager.CookieCollection.AddCookies(
        ASource.CookieManager.CookieCollection
      );
      ADestination.CookieManager := LCookieManager;
    except
      LCookieManager.Free;
      raise;
    end;
  end;
end;

constructor TSkuchainIndyClient.Create(AOwner: TComponent);
begin
  inherited;

  FHttpClient := TIdHTTP.Create(Self);
  try
    FHttpClient.SetSubComponent(True);
    FHttpClient.Name := 'HttpClient';
  except
    FHttpClient.Free;
    raise;
  end;

end;


function TSkuchainIndyClient.CreateMultipartFormData(
  AFormData: TArray<TFormParam>): TIdMultiPartFormDataStream;
var
  LFormParam: TFormParam;
begin
  Result := TIdMultiPartFormDataStream.Create;
  try
    for LFormParam in AFormData do
    begin
      if not LFormParam.IsFile then
        Result.AddFormField(LFormParam.FieldName, LFormParam.Value.ToString)
      else
        Result.AddFile(LFormParam.FieldName, LFormParam.AsFile.FileName, LFormParam.AsFile.ContentType);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TSkuchainIndyClient.Delete(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  inherited;
  FHttpClient.Request.Accept := AAccept;
  FHttpClient.Request.ContentType := AContentType;
{$ifdef DelphiXE7_UP}
  FHttpClient.Delete(AURL, AResponse);
{$else}
  FHttpClient.Delete(AURL{, AResponse});
{$endif}
end;

destructor TSkuchainIndyClient.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

procedure TSkuchainIndyClient.EndorseAuthorization(const AAuthToken: string);
begin
  if AuthEndorsement = AuthorizationBearer then
  begin
    if not (AAuthToken = '') then
    begin
      FHttpClient.Request.CustomHeaders.FoldLines := False;
      FHttpClient.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AAuthToken;
    end
    else
      FHttpClient.Request.CustomHeaders.Values['Authorization'] := '';
  end;
end;

procedure TSkuchainIndyClient.Get(const AURL: string; AResponseContent: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  FHttpClient.Request.Accept := AAccept;
  FHttpClient.Request.ContentType := AContentType;
  inherited;
  FHttpClient.Get(AURL, AResponseContent);
end;

function TSkuchainIndyClient.GetConnectTimeout: Integer;
begin
  Result := FHttpClient.ConnectTimeout;
end;

function TSkuchainIndyClient.GetReadTimeout: Integer;
begin
  Result := FHttpClient.ReadTimeout;
end;

//function TSkuchainIndyClient.GetRequest: TIdHTTPRequest;
//begin
//  Result := FHttpClient.Request;
//end;

//function TSkuchainIndyClient.GetResponse: TIdHTTPResponse;
//begin
//  Result := FHttpClient.Response;
//end;

function TSkuchainIndyClient.LastCmdSuccess: Boolean;
begin
  Result := (FHttpClient.ResponseCode >= 200) and (FHttpClient.ResponseCode < 300);
end;

procedure TSkuchainIndyClient.Post(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  inherited;
  FHttpClient.Request.Accept := AAccept;
  FHttpClient.Request.ContentType := AContentType;
  FHttpClient.Post(AURL, AContent, AResponse);
end;

procedure TSkuchainIndyClient.Put(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  inherited;
  FHttpClient.Request.Accept := AAccept;
  FHttpClient.Request.ContentType := AContentType;
  FHttpClient.Put(AURL, AContent, AResponse);
end;

function TSkuchainIndyClient.ResponseStatusCode: Integer;
begin
  Result := FHttpClient.ResponseCode;
end;

function TSkuchainIndyClient.ResponseText: string;
begin
  Result := FHttpClient.ResponseText;
end;

procedure TSkuchainIndyClient.SetConnectTimeout(const Value: Integer);
begin
  FHttpClient.ConnectTimeout := Value;
end;

procedure TSkuchainIndyClient.SetProtocolVersion(const Value: TIdHTTPProtocolVersion);
begin
  FHttpClient.ProtocolVersion := Value;
end;

procedure TSkuchainIndyClient.SetReadTimeout(const Value: Integer);
begin
  FHttpClient.ReadTimeout := Value;
end;

function TSkuchainIndyClient.GetProtocolVersion: TIdHTTPProtocolVersion;
begin
  Result := FHttpClient.ProtocolVersion;
end;

procedure TSkuchainIndyClient.Post(const AURL: string;
  const AFormData: TArray<TFormParam>; const AResponse: TStream;
  const AAuthToken, AAccept: string; const AContentType: string);
var
  LFormDataStream: TIdMultiPartFormDataStream;
begin
  inherited;

  FHttpClient.Request.Accept := AAccept;

  LFormDataStream := CreateMultipartFormData(AFormData);
  try

    FHttpClient.Request.ContentType :=  'multipart/form-data, ' + LFormDataStream.RequestContentType;
    FHttpClient.Post(AURL, LFormDataStream, AResponse);
  finally
    LFormDataStream.Free;
  end;
end;

procedure TSkuchainIndyClient.Put(const AURL: string;
  const AFormData: TArray<TFormParam>; const AResponse: TStream;
  const AAuthToken, AAccept: string; const AContentType: string);
var
  LFormDataStream: TIdMultiPartFormDataStream;
begin
  inherited;

  FHttpClient.Request.Accept := AAccept;
  LFormDataStream := CreateMultipartFormData(AFormData);
  try
    FHttpClient.Request.ContentType := LFormDataStream.RequestContentType;
    FHttpClient.Put(AURL, LFormDataStream, AResponse);
  finally
    LFormDataStream.Free;
  end;
end;

end.
