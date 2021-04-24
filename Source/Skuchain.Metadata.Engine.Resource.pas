(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Metadata.Engine.Resource;

interface

uses
    Skuchain.Core.Registry
  , Skuchain.Core.Attributes
  , Skuchain.Core.MediaType
  , Skuchain.Core.JSON
  , Skuchain.Metadata
  , Skuchain.Core.Application
;

type

  [Path('/metadata')]
  TMetadataResource = class
  private
  protected
    [Context] Metadata: TSkuchainEngineMetadata;
  public
    [GET, IsReference]
    function Get(): TSkuchainEngineMetadata;
    [GET, Path('{AppName}'), IsReference]
    function GetApplication([PathParam] AppName: string): TSkuchainApplicationMetadata;
  end;


implementation

uses
    Classes, SysUtils, System.Rtti
  , Skuchain.Rtti.Utils
;

{ TMetadataResource }

function TMetadataResource.Get(): TSkuchainEngineMetadata;
begin
  Result := Metadata;
end;

function TMetadataResource.GetApplication(AppName: string): TSkuchainApplicationMetadata;
var
  LResult: TSkuchainApplicationMetadata;
begin
  LResult := nil;
  Metadata.ForEachApplication(
    procedure (AAppMeta: TSkuchainApplicationMetadata)
    begin
      if SameText(AAppMeta.Name, AppName) then
        LResult := AAppMeta;
    end
  );
  Result := LResult;
  if not Assigned(Result) then
    raise ESkuchainApplicationException.CreateFmt('Application [%s] not found', [AppName], 404);

end;

initialization
  TSkuchainResourceRegistry.Instance.RegisterResource<TMetadataResource>;

end.
