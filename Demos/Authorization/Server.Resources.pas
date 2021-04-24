(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Server.Resources;

interface

uses
  Classes, SysUtils

  , Skuchain.Core.JSON
  , Rtti

  , Skuchain.Core.Registry
  , Skuchain.Core.Attributes
  , Skuchain.Core.MediaType
  , Skuchain.Core.URL
  , Skuchain.Core.MessageBodyWriters

  , Skuchain.Core.Token
  , Skuchain.Core.Token.Resource

  , Skuchain.Core.Application
  ;

type
  [Path('first')]
  TFirstResource = class
  private
  protected
    [Context] Token: TSkuchainToken;
  public
    [GET, PermitAll]
    [Produces(TMediaType.TEXT_PLAIN)]
    function PublicInfo: string;


    [GET, Path('/details'), RolesAllowed('admin')]
    [Produces(TMediaType.TEXT_PLAIN)]
    function DetailsInfo: string;
  end;

  {
    This 'second' resource will be allowed only to users with 'admin' role.
    Note that the resource is decorated with RolesAllowed attribute and their
    methods (Default, One, Two, Three) are not.
    A fallback mechanism (from method to class) is used to determine authorization settings.
  }
  [Path('second'), RolesAllowed('admin')]
  TSecondResource = class
  private
  protected
  public
    [GET]
    function Default: string;

    [GET, Path('/one')]
    function One: string;
    [GET, Path('/two')]
    function Two: string;
    [GET, Path('/three')]
    function Three: string;
  end;

  [Path('token')]
  TTokenResource = class(TSkuchainTokenResource)
  private
    [Context] App: TSkuchainApplication;
    function GetLocalFile(const AName: string): string;
  protected

  public
    [GET, Path('html'), Produces(TMediaType.TEXT_HTML)]
    function GetTokenPage: TStream;
  end;

implementation

uses
  StrUtils, IOUtils
;

{ TFirstResource }

function TFirstResource.DetailsInfo: string;
begin
  Result := 'Admin-level access informations here! Welcome, ' + IfThen(Token.IsVerified, Token.Username, '[anonymous]');
end;

function TFirstResource.PublicInfo: string;
begin
  Result := 'Public informations here! Hi, ' + IfThen(Token.IsVerified, Token.Username, '[anonymous]');
end;

{ TSecondResource }

function TSecondResource.Default: string;
begin
  Result := 'Default';
end;

function TSecondResource.One: string;
begin
  Result := 'One';
end;

function TSecondResource.Three: string;
begin
  Result := 'Three';
end;

function TSecondResource.Two: string;
begin
  Result := 'Two';
end;

{ TTokenResource }

function TTokenResource.GetLocalFile(const AName: string): string;
begin
  Result := TPath.Combine(
     App.Parameters.ByName('LocalFileFolder'
       , TPath.Combine(ExtractFilePath(ParamStr(0)), 'html')
     ).AsString
   , AName
  );
end;

function TTokenResource.GetTokenPage: TStream;
begin
  Result := TFileStream.Create(
    GetLocalFile('tokenPage.html'), fmOpenRead or fmShareDenyNone
  );
end;

initialization
  TSkuchainResourceRegistry.Instance.RegisterResource<TFirstResource>;
  TSkuchainResourceRegistry.Instance.RegisterResource<TSecondResource>;
  TSkuchainResourceRegistry.Instance.RegisterResource<TTokenResource>;

end.
