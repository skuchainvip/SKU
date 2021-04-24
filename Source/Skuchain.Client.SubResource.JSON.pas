(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.SubResource.JSON;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Core.JSON

  , Skuchain.Client.SubResource, Skuchain.Client.Client
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
  TSkuchainClientSubResourceJSON = class(TSkuchainClientSubResource)
  private
    FResponse: TJSONValue;
  protected
    procedure AfterGET(const AContent: TStream); override;
    procedure AfterPOST(const AContent: TStream); override;
    function GetResponseAsString: string; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function ResponseAs<T: record>: T;
    function ResponseAsArray<T: record>: TArray<T>;
  published
    property Response: TJSONValue read FResponse write FResponse;
    property ResponseAsString: string read GetResponseAsString;
  end;

procedure Register;

implementation

uses
  Skuchain.Core.Utils, Skuchain.Core.MediaType
;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientSubResourceJSON]);
end;

{ TSkuchainClientResourceJSON }

procedure TSkuchainClientSubResourceJSON.AfterGET(const AContent: TStream);
begin
  inherited;
  if Assigned(FResponse) then
    FResponse.Free;
  FResponse := StreamToJSONValue(AContent);
end;

procedure TSkuchainClientSubResourceJSON.AfterPOST(const AContent: TStream);
begin
  inherited;
  if Assigned(FResponse) then
    FResponse.Free;
  FResponse := StreamToJSONValue(AContent);
end;

constructor TSkuchainClientSubResourceJSON.Create(AOwner: TComponent);
begin
  inherited;
  FResponse := TJSONObject.Create;
  SpecificAccept := TMediaType.APPLICATION_JSON;
  SpecificContentType := TMediaType.APPLICATION_JSON;
end;

destructor TSkuchainClientSubResourceJSON.Destroy;
begin
  FResponse.Free;
  inherited;
end;

function TSkuchainClientSubResourceJSON.GetResponseAsString: string;
begin
  Result := '';
  if Assigned(FResponse) then
    Result := FResponse.ToJSON;
end;

function TSkuchainClientSubResourceJSON.ResponseAs<T>: T;
begin
  Result := (Response as TJSONObject).ToRecord<T>;
end;

function TSkuchainClientSubResourceJSON.ResponseAsArray<T>: TArray<T>;
begin
  Result := (Response as TJSONArray).ToArrayOfRecord<T>;
end;

end.
