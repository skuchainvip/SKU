(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Server.Resources;

interface

uses
  SysUtils, Classes, Diagnostics

  , Skuchain.Core.Attributes
  , Skuchain.Core.MediaType
  , Skuchain.Core.Response

  , Skuchain.WebServer.Resources
  , Skuchain.Core.URL

  , Skuchain.Core.Classes
  , Skuchain.Core.Engine
  , Skuchain.Core.Application

  , RlxRazor
;

type
  [Path('razor'), Produces(TMediaType.TEXT_HTML)]
  TRazorResource = class
  private
    FRazorEngine: TRlxRazorEngine;
    FRazorProcessor: TRlxRazorProcessor;
    function GetCurrentSecond: Integer;
    function GetCurrentSecondEven: Boolean;
  protected
    [Context] URL: TSkuchainURL;
    function GetTemplatesFolder: string;
    function GetFilesFolder: string;
    function GetHelloText: string;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    [GET, Path('/{*}')]
    function HelloWorld():string;

    property HelloText: string read GetHelloText;
    property CurrentSecond: Integer read GetCurrentSecond;
    property CurrentSecondEven: Boolean read GetCurrentSecondEven;
  end;

implementation

uses
    IOUtils, DateUtils
  , Skuchain.Core.Registry
  , Skuchain.Core.Exceptions
  ;

{ TRazorResource }

constructor TRazorResource.Create;
begin
  inherited Create;
  FRazorEngine := TRlxRazorEngine.Create(nil);
  FRazorProcessor := TRlxRazorProcessor.Create(nil);
  try
    FRazorProcessor.RazorEngine := FRazorEngine;
    FRazorEngine.TemplatesFolder := GetTemplatesFolder;
    FRazorEngine.FilesFolder := GetFilesFolder;

    FRazorEngine.AddToDictionary('resource', Self, False);
  except
    FRazorProcessor.Free;
    raise;
  end;
end;

destructor TRazorResource.Destroy;
begin
  FRazorProcessor.Free;
  inherited;
end;

function TRazorResource.GetCurrentSecond: Integer;
begin
  Result := SecondOfTheDay(Now);
end;

function TRazorResource.GetCurrentSecondEven: Boolean;
begin
  Result := (GetCurrentSecond mod 2) = 0;
end;

function TRazorResource.GetFilesFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(
    TPath.Combine(ExtractFilePath(ParamStr(0)), 'files')
  );
end;

function TRazorResource.GetTemplatesFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(
    TPath.Combine(ExtractFilePath(ParamStr(0)), 'templates')
  );
end;

function TRazorResource.GetHelloText: string;
begin
  Result := 'Hello, current time is: ' + TimeToStr(Now);
end;

function TRazorResource.HelloWorld(): string;
var
  LReader: TStreamReader;
  LFileName: string;
begin
  LFileName := TPath.Combine(GetFilesFolder, URL.PathTokens[Length(URL.PathTokens)-1]);
  if not FileExists(LFileName) then
    raise ESkuchainHttpException.Create(Format('File [%s] not found', [LFileName]), 404);

  LReader := TStreamReader.Create(LFileName);
  try
    Result := FRazorProcessor.DoBlock(LReader.ReadToEnd);
  finally
    LReader.Free;
  end;
end;

initialization
  TSkuchainResourceRegistry.Instance.RegisterResource<TRazorResource>(
    function: TObject
    begin
      Result := TRazorResource.Create;
    end
  );

end.
