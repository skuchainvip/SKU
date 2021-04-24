(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Token.Resource;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils

  , Skuchain.Core.Registry
  , Skuchain.Core.Classes
  , Skuchain.Core.Application
  , Skuchain.Core.Attributes
  , Skuchain.Core.MediaType
  , Skuchain.Core.Token.ReadersAndWriters
  , Skuchain.Core.Token
  , Skuchain.Core.URL
;

type
  [Produces(TMediaType.APPLICATION_JSON)]
  TSkuchainTokenResource = class
  private
  protected
    [Context] Token: TSkuchainToken;
    [Context] App: TSkuchainApplication;
    [Context] URL: TSkuchainURL;
    function Authenticate(const AUserName, APassword: string): Boolean; virtual;
    procedure BeforeLogin(const AUserName, APassword: string); virtual;
    procedure AfterLogin(const AUserName, APassword: string); virtual;

    procedure BeforeLogout(); virtual;
    procedure AfterLogout(); virtual;
  public
    [GET, IsReference]
    function GetCurrent: TSkuchainToken;

    [POST, IsReference]
    function DoLogin(
      [FormParam('username')] const AUsername: string;
      [FormParam('password')] const APassword: string): TSkuchainToken;

    [DELETE, IsReference]
    function Logout: TSkuchainToken;
  end;


implementation

uses
  DateUtils
, Skuchain.Utils.JWT
;

{ TSkuchainTokenResource }

procedure TSkuchainTokenResource.AfterLogin(const AUserName, APassword: string);
begin

end;

procedure TSkuchainTokenResource.AfterLogout;
begin

end;

function TSkuchainTokenResource.Authenticate(const AUserName, APassword: string): Boolean;
begin
  Result := SameText(APassword, IntToStr(HourOf(Now)));

  if Result then
  begin
    Token.UserName := AUserName;
    if SameText(AUserName, 'admin') then
      Token.Roles := TArray<string>.Create('standard', 'admin')
    else
      Token.Roles := TArray<string>.Create('standard');
  end;
end;

procedure TSkuchainTokenResource.BeforeLogin(const AUserName, APassword: string);
begin

end;

procedure TSkuchainTokenResource.BeforeLogout;
begin

end;

function TSkuchainTokenResource.DoLogin(const AUsername, APassword: string): TSkuchainToken;
begin
  BeforeLogin(AUserName, APassword);
  try
    if Authenticate(AUserName, APassword) then
    begin
      Token.Build(
        App.Parameters.ByName(JWT_SECRET_PARAM, JWT_SECRET_PARAM_DEFAULT).AsString
      );
      Result := Token;
    end
    else
    begin
      Token.Clear;
      Result := Token;
    end;
  finally
    AfterLogin(AUserName, APassword);
  end;
end;

function TSkuchainTokenResource.GetCurrent: TSkuchainToken;
begin
  Result := Token;
end;

function TSkuchainTokenResource.Logout: TSkuchainToken;
begin
  BeforeLogout();
  try
    Token.Clear;
    Result := Token;
  finally
    AfterLogout();
  end;
end;

end.
