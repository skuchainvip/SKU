(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Token;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes, Generics.Collections, SyncObjs, Rtti
, HTTPApp, IdGlobal

, Skuchain.Core.URL
, Skuchain.Utils.Parameters


//{$IFDEF mORMot-JWT}
//, Skuchain.Utils.JWT.mORMot
//{$ENDIF}
//
//{$IFDEF JOSE-JWT}
//, Skuchain.Utils.JWT.JOSE
//{$ENDIF}

;

type
  TSkuchainToken = class
  public
  private
    FToken: string;
    FIsVerified: Boolean;
    FClaims: TSkuchainParameters;
    FCookieEnabled: Boolean;
    FCookieName: string;
    FCookieDomain: string;
    FCookiePath: string;
    FCookieSecure: Boolean;
    FRequest: TWebRequest;
    FResponse: TWebResponse;
    FDuration: TDateTime;
    FIssuer: string;
    function GetUserName: string;
    procedure SetUserName(const AValue: string);
    function GetExpiration: TDateTime;
    function GetIssuedAt: TDateTime;
    function GetRoles: TArray<string>;
    procedure SetRoles(const AValue: TArray<string>);
    function GetDurationMins: Int64;
    function GetDurationSecs: Int64;
  protected
    function GetTokenFromBearer(const ARequest: TWebRequest): string; virtual;
    function GetTokenFromCookie(const ARequest: TWebRequest): string; virtual;
    function GetToken(const ARequest: TWebRequest): string; virtual;
    function GetIsExpired: Boolean; virtual;

    function BuildJWTToken(const ASecret: string; const AClaims: TSkuchainParameters): string; virtual;
    function LoadJWTToken(const AToken: string; const ASecret: string; var AClaims: TSkuchainParameters): Boolean; virtual;

    property Request: TWebRequest read FRequest;
    property Response: TWebResponse read FResponse;
  public
    constructor Create(); reintroduce; overload; virtual;
    constructor Create(const AToken: string; const AParameters: TSkuchainParameters); overload; virtual;
    constructor Create(const AToken: string; const ASecret: string;
      const AIssuer: string; const ADuration: TDateTime); overload; virtual;
    constructor Create(const ARequest: TWebRequest; const AResponse: TWebResponse;
      const AParameters: TSkuchainParameters; const AURL: TSkuchainURL); overload; virtual;
    destructor Destroy; override;

    procedure Build(const ASecret: string);
    procedure Load(const AToken, ASecret: string);
    procedure Clear;
    function Clone(const AIgnoreRequestResponse: Boolean = True): TSkuchainToken; virtual;

    function HasRole(const ARole: string): Boolean; overload; virtual;
    function HasRole(const ARoles: TArray<string>): Boolean; overload; virtual;
    function HasRole(const ARoles: TStrings): Boolean; overload; virtual;
    procedure SetUserNameAndRoles(const AUserName: string; const ARoles: TArray<string>); virtual;
    procedure UpdateCookie; virtual;

    property Token: string read FToken;
    property UserName: string read GetUserName write SetUserName;
    property Roles: TArray<string> read GetRoles write SetRoles;
    property IsVerified: Boolean read FIsVerified;
    property IsExpired: Boolean read GetIsExpired;
    property Claims: TSkuchainParameters read FClaims;
    property Expiration: TDateTime read GetExpiration;
    property Issuer: string read FIssuer;
    property IssuedAt: TDateTime read GetIssuedAt;
    property Duration: TDateTime read FDuration;
    property DurationMins: Int64 read GetDurationMins;
    property DurationSecs: Int64 read GetDurationSecs;
    property CookieEnabled: Boolean read FCookieEnabled;
    property CookieName: string read FCookieName;
    property CookieDomain: string read FCookieDomain;
    property CookiePath: string read FCookiePath;
    property CookieSecure: Boolean read FCookieSecure;
  end;

implementation

uses
  DateUtils

  {$ifndef DelphiXE7_UP}
  , IdCoderMIME, IdUri
  {$else}
  , System.NetEncoding
  {$endif}
  , Skuchain.Core.Utils
  , Skuchain.Utils.Parameters.JSON
  , Skuchain.Utils.JWT
  ;

{ TSkuchainToken }

constructor TSkuchainToken.Create(const AToken: string; const AParameters: TSkuchainParameters);
begin
  Create(
    AToken
  , AParameters.ByName(JWT_SECRET_PARAM, JWT_SECRET_PARAM_DEFAULT).AsString
  , AParameters.ByName(JWT_ISSUER_PARAM, JWT_ISSUER_PARAM_DEFAULT).AsString
  , AParameters.ByName(JWT_DURATION_PARAM, JWT_DURATION_PARAM_DEFAULT).AsExtended
  );
end;

function TSkuchainToken.BuildJWTToken(const ASecret: string;
  const AClaims: TSkuchainParameters): string;
begin
  Result := '';
end;

procedure TSkuchainToken.Clear;
begin
  FToken := '';
  FIsVerified := False;
  FClaims.Clear;
  UpdateCookie;
end;

function TSkuchainToken.Clone(const AIgnoreRequestResponse: Boolean): TSkuchainToken;
begin
  Result := TSkuchainToken.Create();
  try
    if not AIgnoreRequestResponse then
    begin
      Result.FRequest := Request;
      Result.FResponse := Response;
    end;
    Result.FCookieEnabled := CookieEnabled;
    Result.FCookieName := CookieName;
    Result.FCookieDomain := CookieDomain;
    Result.FCookiePath := CookiePath;
    Result.FCookieSecure := CookieSecure;
    Result.FIssuer := Issuer;
    Result.FDuration := Duration;
    Result.FToken := Token;
    Result.FIsVerified := IsVerified;
    Result.FClaims.CopyFrom(Claims);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

constructor TSkuchainToken.Create(const AToken, ASecret, AIssuer: string;
  const ADuration: TDateTime);
begin
  Create;
  FIssuer := AIssuer;
  FDuration := ADuration;
  Load(AToken, ASecret);
end;

constructor TSkuchainToken.Create(const ARequest: TWebRequest; const AResponse: TWebResponse;
  const AParameters: TSkuchainParameters; const AURL: TSkuchainURL);
begin
  FRequest := ARequest;
  FResponse := AResponse;

  FCookieEnabled := AParameters.ByName(JWT_COOKIEENABLED_PARAM, JWT_COOKIEENABLED_PARAM_DEFAULT).AsBoolean;
  FCookieName := AParameters.ByName(JWT_COOKIENAME_PARAM, JWT_COOKIENAME_PARAM_DEFAULT).AsString;
  FCookieDomain := AParameters.ByName(JWT_COOKIEDOMAIN_PARAM, AURL.Hostname).AsString;
  FCookiePath := AParameters.ByName(JWT_COOKIEPATH_PARAM, AURL.BasePath).AsString;
  FCookieSecure := AParameters.ByName(JWT_COOKIESECURE_PARAM, JWT_COOKIESECURE_PARAM_DEFAULT).AsBoolean;
  Create(GetToken(ARequest), AParameters);
end;

constructor TSkuchainToken.Create;
begin
  inherited Create;
  FClaims := TSkuchainParameters.Create('');
end;

destructor TSkuchainToken.Destroy;
begin
  FClaims.Free;
  inherited;
end;

function TSkuchainToken.GetDurationMins: Int64;
begin
  Result := Trunc(Duration * MinsPerDay);
end;

function TSkuchainToken.GetDurationSecs: Int64;
begin
  Result := Trunc(Duration * MinsPerDay * 60);
end;

function TSkuchainToken.GetExpiration: TDateTime;
var
  LUnixValue: Int64;
begin
  LUnixValue := FClaims.ByName(JWT_EXPIRATION_CLAIM, 0).AsInt64;
  if LUnixValue > 0 then
    Result := UnixToDateTime(LUnixValue {$ifdef DelphiXE7_UP}, False {$endif})
  else
    Result := 0.0;
end;

function TSkuchainToken.GetIssuedAt: TDateTime;
var
  LUnixValue: Int64;
begin
  LUnixValue := FClaims.ByName(JWT_ISSUED_AT_CLAIM, 0).AsInt64;
  if LUnixValue > 0 then
    Result := UnixToDateTime(LUnixValue {$ifdef DelphiXE7_UP}, False {$endif})
  else
    Result := 0.0;
end;

function TSkuchainToken.GetRoles: TArray<string>;
{$ifdef DelphiXE7_UP}
begin
  Result := FClaims[JWT_ROLES].AsString.Split([',']); // do not localize
{$else}
var
  LTokens: TStringList;
begin
  LTokens := TStringList.Create;
  try
    LTokens.Delimiter := ',';
    LTokens.StrictDelimiter := True;
    LTokens.DelimitedText := FClaims[JWT_ROLES].AsString;
    Result := LTokens.ToStringArray;
  finally
    LTokens.Free;
  end;
{$endif}
end;

function TSkuchainToken.GetToken(const ARequest: TWebRequest): string;
begin
  // Beware: First match wins!

  // 1 - check if the authentication bearer schema is used
  Result := GetTokenFromBearer(ARequest);
  // 2 - check if a cookie is used
  if Result = '' then
    Result := GetTokenFromCookie(ARequest);
end;

function TSkuchainToken.GetTokenFromBearer(const ARequest: TWebRequest): string;
var
  LAuth: string;
  LAuthTokens: TArray<string>;
{$ifndef DelphiXE7_UP}
  LTokens: TStringList;
{$endif}
begin
  Result := '';
  LAuth := ARequest.Authorization;
{$ifdef DelphiXE7_UP}
  LAuthTokens := LAuth.Split([' ']);
{$else}
  LTokens := TStringList.Create;
  try
    LTokens.Delimiter := ' ';
    LTokens.StrictDelimiter := True;
    LTokens.DelimitedText := LAuth;
    LAuthTokens := LTokens.ToStringArray;
  finally
    LTokens.Free;
  end;
{$endif}
  if (Length(LAuthTokens) >= 2) then
    if SameText(LAuthTokens[0], 'Bearer') then
      Result := LAuthTokens[1];
end;

function TSkuchainToken.GetTokenFromCookie(const ARequest: TWebRequest): string;
begin
  Result := '';
  if CookieEnabled and (CookieName <> '') then
{$ifdef DelphiXE7_UP}
    Result := TNetEncoding.URL.Decode(ARequest.CookieFields.Values[CookieName]);
{$else}
    Result := TIdURI.URLDecode(ARequest.CookieFields.Values[CookieName]);
{$endif}
end;

function TSkuchainToken.GetUserName: string;
begin
  Result := FClaims[JWT_USERNAME].AsString;
end;

function TSkuchainToken.HasRole(const ARoles: TStrings): Boolean;
begin
  Result := HasRole(ARoles.ToStringArray);
end;

function TSkuchainToken.GetIsExpired: Boolean;
begin
  Result := Expiration < Now;
end;

function TSkuchainToken.HasRole(const ARoles: TArray<string>): Boolean;
var
  LRole: string;
begin
  Result := False;
  for LRole in ARoles do
  begin
    Result := HasRole(LRole);
    if Result then
      Break;
  end;
end;

procedure TSkuchainToken.Build(const ASecret: string);
var
  LIssuedAt: TDateTime;
begin
  LIssuedAt := Now;

  FClaims[JWT_ISSUED_AT_CLAIM] := DateTimeToUnix(LIssuedAt {$ifdef DelphiXE7_UP}, False{$endif});
  FClaims[JWT_EXPIRATION_CLAIM] := DateTimeToUnix(LIssuedAt + Duration {$ifdef DelphiXE7_UP}, False{$endif});
  FClaims[JWT_ISSUER_CLAIM] := FIssuer;
  FClaims[JWT_DURATION_CLAIM] := FDuration;

  FToken := BuildJWTToken(ASecret, FClaims);
  FIsVerified := True;
  UpdateCookie;
end;

procedure TSkuchainToken.Load(const AToken, ASecret: string);
begin
  FIsVerified := False;
  FToken := AToken;

  if AToken <> '' then
    FIsVerified := LoadJWTToken(AToken, ASecret, FClaims);
end;

function TSkuchainToken.LoadJWTToken(const AToken, ASecret: string;
  var AClaims: TSkuchainParameters): Boolean;
begin
  Result := False;
end;

procedure TSkuchainToken.SetRoles(const AValue: TArray<string>);
begin
  FClaims[JWT_ROLES] := SmartConcat(AValue);
end;

procedure TSkuchainToken.SetUserName(const AValue: string);
begin
  FClaims[JWT_USERNAME] := AValue;
end;

procedure TSkuchainToken.SetUserNameAndRoles(const AUserName: string;
  const ARoles: TArray<string>);
begin
  UserName := AUserName;
  Roles := ARoles;
end;

procedure TSkuchainToken.UpdateCookie;
var
  LContent: TStringList;
begin
  if CookieEnabled then
  begin
    Assert(Assigned(Response));

    LContent := TStringList.Create;
    try
      if IsVerified and not IsExpired then
      begin
        LContent.Values[CookieName] := Token;

        Response.SetCookieField(
          LContent, CookieDomain, CookiePath, Expiration, CookieSecure);
      end
      else begin
        if Request.CookieFields.Values[CookieName] <> '' then
        begin
          LContent.Values[CookieName] := 'dummy';
          Response.SetCookieField(
            LContent, CookieDomain, CookiePath, Now-1, CookieSecure);
        end;
      end;
    finally
      LContent.Free;
    end;
  end;
end;

function TSkuchainToken.HasRole(const ARole: string): Boolean;
var
  LRole: string;
begin
  Result := False;
  for LRole in GetRoles do
  begin
    if SameText(LRole, ARole) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

end.
