(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Resource;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes

  , Skuchain.Client.CustomResource
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
  TSkuchainClientResource = class(TSkuchainClientCustomResource)
  private
  protected
  public
  published
    property Accept;
    property Application;
    property AuthToken;
    property Client;
    property ContentType;
    property SpecificAccept;
    property SpecificClient;
    property SpecificContentType;
    property Resource;
    property Path;
    property PathParamsValues;
    property QueryParams;
    property Token;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientResource]);
end;

end.
