(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Resource.Stream;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes

  , Skuchain.Client.Resource
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
  TSkuchainClientResourceStream = class(TSkuchainClientResource)
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
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientResourceStream]);
end;

{ TSkuchainClientResourceStream }

procedure TSkuchainClientResourceStream.AfterGET(const AContent: TStream);
begin
  inherited;
  CopyStream(AContent, FResponse);
end;

procedure TSkuchainClientResourceStream.AfterPOST(const AContent: TStream);
begin
  inherited;
  CopyStream(AContent, FResponse);
end;

constructor TSkuchainClientResourceStream.Create(AOwner: TComponent);
begin
  inherited;
  SpecificAccept := TMediaType.WILDCARD;
  SpecificContentType := TMediaType.APPLICATION_OCTET_STREAM;
  FResponse := TMemoryStream.Create;
end;

destructor TSkuchainClientResourceStream.Destroy;
begin
  FResponse.Free;
  inherited;
end;

function TSkuchainClientResourceStream.GetResponseSize: Int64;
begin
  Result := FResponse.Size;
end;

end.
