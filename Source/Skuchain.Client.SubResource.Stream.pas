(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.SubResource.Stream;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes

  , Skuchain.Client.SubResource
  , Skuchain.Client.Client
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
  TSkuchainClientSubResourceStream = class(TSkuchainClientSubResource)
  private
    FResponse: TStream;
  protected
    procedure AfterGET(const AContent: TStream); override;
    procedure AfterPOST(const AContent: TStream); override;
    function GetResponseSize: Int64; virtual;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    property Response: TStream read FResponse;
    property ResponseSize: Int64 read GetResponseSize;
  end;

procedure Register;

implementation

uses
  Skuchain.Core.Utils,
  Skuchain.Core.MediaType;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientSubResourceStream]);
end;

{ TSkuchainClientResourceJSON }

procedure TSkuchainClientSubResourceStream.AfterGET(const AContent: TStream);
begin
  inherited;
  CopyStream(AContent, FResponse);
end;

procedure TSkuchainClientSubResourceStream.AfterPOST(const AContent: TStream);
begin
  inherited;
  CopyStream(AContent, FResponse);
end;

constructor TSkuchainClientSubResourceStream.Create(AOwner: TComponent);
begin
  inherited;
  FResponse := TMemoryStream.Create;
  SpecificAccept := TMediaType.WILDCARD;
  SpecificContentType := TMediaType.APPLICATION_OCTET_STREAM;
end;

destructor TSkuchainClientSubResourceStream.Destroy;
begin
  FResponse.Free;
  inherited;
end;


function TSkuchainClientSubResourceStream.GetResponseSize: Int64;
begin
  Result := FResponse.Size;
end;

end.
