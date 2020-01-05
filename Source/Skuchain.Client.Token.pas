(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Token;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Core.JSON
  , Skuchain.Utils.Parameters
  , Skuchain.Utils.Parameters.JSON

   , Skuchain.Client.Resource
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
  TSkuchainClientToken = class(TSkuchainClientResource)
  private
    FData: TJSONObject;
    FIsVerified: Boolean;
    FToken: string;
    FPassword: string;
    FUserName: string;
    FUserRoles: TStrings;
    FClaims: TSkuchainParameters;
    FExpiration: TDateTime;
    FIssuedAt: TDateTime;
    function GetIsExpired: Boolean;
  protected
    procedure AfterGET(const AContent: TStream); override;
    procedure BeforePOST(const AContent: TMemoryStream); override;
    procedure AfterPOST(const AContent: TStream); override;
    procedure AfterDELETE(const AContent: TStream); override;
    procedure ParseData; virtual;
    function GetAuthToken: string; override;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear; virtual;
    procedure SaveToStream(const AStream: TStream); virtual;
    procedure LoadFromStream(const AStream: TStream); virtual;
    procedure SaveToFile(const AFilename: string); virtual;
    procedure LoadFromFile(const AFilename: string); virtual;
  published
    property Data: TJSONObject read FData;

    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword;
    property Token: string read FToken;
    property Authenticated: Boolean read FIsVerified;
    property IsVerified: Boolean read FIsVerified;
    property UserRoles: TStrings read FUserRoles;
    property IssuedAt: TDateTime read FIssuedAt;
    property Expiration: TDateTime read FExpiration;
    property Claims: TSkuchainParameters read FClaims;
    property IsExpired: Boolean read GetIsExpired;
  end;

procedure Register;

implementation

uses
  DateUtils
, Skuchain.Core.Utils, Skuchain.Rtti.Utils
, Skuchain.Core.MediaType
;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientToken]);
end;

{ TSkuchainClientToken }

procedure TSkuchainClientToken.AfterDELETE(const AContent: TStream);
begin
  inherited;
  if Assigned(FData) then
    FData.Free;
  FData := StreamToJSONValue(AContent) as TJSONObject;
  ParseData;
end;

procedure TSkuchainClientToken.AfterGET(const AContent: TStream);
begin
  inherited;
  if Assigned(FData) then
    FData.Free;
  FData := StreamToJSONValue(AContent) as TJSONObject;
  ParseData;
end;

procedure TSkuchainClientToken.AfterPOST(const AContent: TStream);
begin
  inherited;

  if Assigned(FData) then
    FData.Free;
  FData := StreamToJSONValue(AContent) as TJSONObject;
  ParseData;
end;

procedure TSkuchainClientToken.AssignTo(Dest: TPersistent);
var
  LDest: TSkuchainClientToken;
begin
  inherited AssignTo(Dest);
  LDest := Dest as TSkuchainClientToken;

  LDest.UserName := UserName;
  LDest.Password := Password;
end;

procedure TSkuchainClientToken.BeforePOST(const AContent: TMemoryStream);
var
  LStreamWriter: TStreamWriter;
begin
  inherited;
  LStreamWriter := TStreamWriter.Create(AContent);
  try
    LStreamWriter.Write('username=' + FUserName + '&password=' + FPassword);
  finally
    LStreamWriter.Free;
  end;
end;

procedure TSkuchainClientToken.Clear;
begin
  if Assigned(FData) then
    FreeAndNil(FData);
  FData := TJSONObject.Create;
  ParseData;
end;

constructor TSkuchainClientToken.Create(AOwner: TComponent);
begin
  inherited;
  Resource := 'token';
  FData := TJSONObject.Create;
  FUserRoles := TStringList.Create;
  FClaims := TSkuchainParameters.Create('');
  SpecificAccept := TMediaType.APPLICATION_JSON;
  SpecificContentType := TMediaType.APPLICATION_JSON;
end;

destructor TSkuchainClientToken.Destroy;
begin
  FClaims.Free;
  FUserRoles.Free;
  FData.Free;

  inherited;
end;

function TSkuchainClientToken.GetAuthToken: string;
begin
  Result := FToken;
end;

function TSkuchainClientToken.GetIsExpired: Boolean;
begin
  Result := Expiration < Now;
end;

procedure TSkuchainClientToken.LoadFromFile(const AFilename: string);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(LFileStream);
  finally
    LFileStream.Free;
  end;
end;

procedure TSkuchainClientToken.LoadFromStream(const AStream: TStream);
begin
  if Assigned(FData) then
    FData.Free;
  FData := StreamToJSONValue(AStream) as TJSONObject;
  ParseData;
end;

procedure TSkuchainClientToken.ParseData;
var
  LClaims: TJSONObject;
begin
  FToken := FData.ReadStringValue('Token');
  FIsVerified := FData.ReadBoolValue('IsVerified');

  FClaims.Clear;
{$IFNDEF DelphiXE8_UP}
  if FData.TryGetValue<TJSONObject>('Claims', LClaims) then
{$ELSE}
  if FData.TryGetValue('Claims', LClaims) then
{$endif}
  begin
    FClaims.LoadFromJSON(LClaims);

    FIssuedAt := UnixToDateTime(FClaims['iat'].AsInt64{$IFDEF DelphiXE7_UP}, False {$ENDIF});
    FExpiration := UnixToDateTime(FClaims['exp'].AsInt64{$IFDEF DelphiXE7_UP}, False {$ENDIF});
    FUserName := FClaims['UserName'].AsString;
    FUserRoles.CommaText := FClaims['Roles'].AsString;
  end
  else
  begin
    FIssuedAt := 0.0;
    FExpiration := 0.0;
    FUserRoles.Clear;
  end;
end;

procedure TSkuchainClientToken.SaveToFile(const AFilename: string);
var
  LFileStream: TFileStream;
begin
  LFileStream := TFileStream.Create(AFilename, fmCreate or fmOpenReadWrite);
  try
    SaveToStream(LFileStream);
  finally
    LFileStream.Free;
  end;
end;

procedure TSkuchainClientToken.SaveToStream(const AStream: TStream);
begin
  JSONValueToStream(FData, AStream);
end;

end.
