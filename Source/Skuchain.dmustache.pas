(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.dmustache;

{$I Skuchain.inc}

interface

uses
    System.Classes, System.SysUtils, Rtti

  , Skuchain.Core.Application
  , Skuchain.Core.Attributes
  , Skuchain.Core.Classes
  , Skuchain.Core.Declarations
  , Skuchain.Core.JSON
  , Skuchain.Core.MediaType
  , Skuchain.Core.Registry
  , Skuchain.Core.Token
  , Skuchain.Core.URL
  , Skuchain.Utils.Parameters
  , Skuchain.Core.Activation.Interfaces

  , SynMustache, SynCommons
;

type
  EdmustacheError = class(ESkuchainApplicationException);

  dmustacheAttribute = class(SkuchainAttribute)
  private
    FName: string;
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TSkuchaindmustache = class
  private
    FActivation: ISkuchainActivation;
    FName: string;
    FApplication: TSkuchainApplication;
    FParameters: TSkuchainParameters;
    FURL: TSkuchainURL;
    FToken: TSkuchainToken;
  protected
    function GetTemplatesFolder: string; virtual;
    function GetTemplateFileName(const AFileName: string): string; virtual;
  public
    constructor Create(const AName: string; const AActivation: ISkuchainActivation = nil); virtual;
    destructor Destroy; override;

    function RenderTemplateWithJSON(const ATemplateFileName: string; const AJSON: string): string; overload;
    function RenderTemplateWithJSON(const ATemplateFileName: string; const AJSON: TJSONValue;
      const AThenFreeJSON: Boolean = False): string; overload;
    function Render(const ATemplate: string; const AValue: variant): string;

    property Activation: ISkuchainActivation read FActivation;
    property Application: TSkuchainApplication read FApplication;
    property URL: TSkuchainURL read FURL;
    property Token: TSkuchainToken read FToken;
    property Parameters: TSkuchainParameters read FParameters;
    property Name: string read FName;
    property TemplatesFolder: string read GetTemplatesFolder;  // MF 170805
  end;

implementation

uses
  IOUTils
  , Skuchain.Core.Utils
  , Skuchain.Core.Exceptions
  , Skuchain.Rtti.Utils
  , Skuchain.dmustache.InjectionService
;

  { TSkuchaindmustache }

constructor TSkuchaindmustache.Create(const AName: string; const AActivation: ISkuchainActivation);
var
  LdmustacheSlice: TSkuchainParameters;
begin
  inherited Create;
  FName := AName;
  FActivation := AActivation;

  // shortcuts
  FApplication := FActivation.Application;
  FURL := FActivation.URL;
  FToken := FActivation.Token;

  // dmustache parameters
  FParameters := TSkuchainParameters.Create(AName);
  try
    if FApplication.Parameters.ContainsSlice('dmustache') then
    begin
      LdmustacheSlice := TSkuchainParameters.Create('dmustache');
      try
        LdmustacheSlice.CopyFrom(FApplication.Parameters, 'dmustache');
        FParameters.CopyFrom(LdmustacheSlice, FName);
      finally
        LdmustacheSlice.Free;
      end;
    end;
  except
    FParameters.Free;
    raise;
  end;
end;

destructor TSkuchaindmustache.Destroy;
begin
  FreeAndNil(FParameters);
  inherited;
end;


function TSkuchaindmustache.GetTemplateFileName(const AFileName: string): string;
begin
  if IsRelativePath(AFileName) then
    Result := TPath.Combine(GetTemplatesFolder, AFileName)
  else
    Result := AFileName;
end;

function TSkuchaindmustache.GetTemplatesFolder: string;
begin
  Result := Parameters.ByName('TemplatesFolder'
      , IncludeTrailingPathDelimiter(TPath.Combine(ExtractFilePath(ParamStr(0)), 'templates'))
      ).AsString;
end;

function TSkuchaindmustache.Render(const ATemplate: string;
  const AValue: variant): string;
var
  LMustache: TSynMustache;
begin
  LMustache := TSynMustache.Parse(StringToUTF8(ATemplate));
  Result := UTF8ToString(LMustache.Render(AValue));
end;

function TSkuchaindmustache.RenderTemplateWithJSON(const ATemplateFileName,
  AJSON: string): string;
var
  LTemplate: TStringList;
  LOutput: RawUTF8;
begin
  LTemplate := TStringList.Create;
  try
    LTemplate.LoadFromFile(GetTemplateFileName(ATemplateFileName));
    if TSynMustache.TryRenderJson(StringToUTF8(LTemplate.Text), StringToUTF8(AJSON), LOutput) then
      Result := UTF8ToString(LOutput)
    else
     raise EdmustacheError.Create('Error rendering JSON');
  finally
    LTemplate.Free;
  end;
end;

function TSkuchaindmustache.RenderTemplateWithJSON(const ATemplateFileName: string;
  const AJSON: TJSONValue; const AThenFreeJSON: Boolean): string;
begin
  try
    Result := RenderTemplateWithJSON(ATemplateFileName, AJSON.ToJSON);
  finally
    if AThenFreeJSON then
      AJSON.Free;
  end;
end;

{ dmustacheAttribute }

constructor dmustacheAttribute.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;

end.
