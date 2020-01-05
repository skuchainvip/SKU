(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Metadata;

interface

uses
  Classes, SysUtils, Generics.Collections
;

type
  TSkuchainEngineMetadata=class; //fwd
  TSkuchainApplicationMetadata=class; //fwd
  TSkuchainResourceMetadata=class; // fwd
  TSkuchainMethodMetadata=class; // fwd

  TSkuchainMetadata=class
  protected
    FParent: TSkuchainMetadata;
    property Parent: TSkuchainMetadata read FParent;
  public
    Description: string;
    Visible: Boolean;
    constructor Create(const AParent: TSkuchainMetadata); virtual;
  end;
  TSkuchainMetadataClass = class of TSkuchainMetadata;
  TSkuchainMetadataList=class(TObjectList<TSkuchainMetadata>)
  public
    function ForEach<T: TSkuchainMetadata>(const ADoSomething: TProc<T>): Integer;
  end;

  TSkuchainPathItemMetadata=class(TSkuchainMetadata)
  protected
    function GetFullPath: string; virtual;
  public
    Name: string;
    Path: string;

    Produces: string;
    Consumes: string;

    Authorization: string;

    property FullPath: string read GetFullPath;
  end;

  TSkuchainRequestParamMetadata = class(TSkuchainMetadata)
  private
  protected
    function GetMethod: TSkuchainMethodMetadata;
    property Method: TSkuchainMethodMetadata read GetMethod;
  public
    Name: string;
    Kind: string;
    DataType: string;

    constructor Create(const AParent: TSkuchainMetadata); override;
  end;

  TSkuchainMethodMetadata=class(TSkuchainPathItemMetadata)
  private
    FParameters: TSkuchainMetadataList;
    function GetQualifiedName: string;
  protected
    function GetResource: TSkuchainResourceMetadata;
    property Resource: TSkuchainResourceMetadata read GetResource;
  public
    HttpMethod: string;
    DataType: string;

    constructor Create(const AParent: TSkuchainMetadata); override;
    destructor Destroy; override;

    property Parameters: TSkuchainMetadataList read FParameters;
    property QualifiedName: string read GetQualifiedName;
    function ForEachParameter(const ADoSomething: TProc<TSkuchainRequestParamMetadata>): Integer;
  end;

  TSkuchainResourceMetadata=class(TSkuchainPathItemMetadata)
  private
    FMethods: TSkuchainMetadataList;
  protected
    function GetApplication: TSkuchainApplicationMetadata;
    property Application: TSkuchainApplicationMetadata read GetApplication;
  public
    constructor Create(const AParent: TSkuchainMetadata); override;
    destructor Destroy; override;

    property Methods: TSkuchainMetadataList read FMethods;
    function ForEachMethod(const ADoSomething: TProc<TSkuchainMethodMetadata>): Integer;
  end;

  TSkuchainApplicationMetadata=class(TSkuchainPathItemMetadata)
  private
    FResources: TSkuchainMetadataList;
  protected
    function GetEngine: TSkuchainEngineMetadata;
    property Engine: TSkuchainEngineMetadata read GetEngine;
  public
    constructor Create(const AParent: TSkuchainMetadata); override;
    destructor Destroy; override;

    property Resources: TSkuchainMetadataList read FResources;
    function ForEachResource(const ADoSomething: TProc<TSkuchainResourceMetadata>): Integer;
    function ForEachMethod(const ADoSomething: TProc<TSkuchainResourceMetadata, TSkuchainMethodMetadata>): Integer;
    function FindResource(const AName: string): TSkuchainResourceMetadata;
  end;

  TSkuchainEngineMetadata=class(TSkuchainPathItemMetadata)
  private
    FApplications: TSkuchainMetadataList;
  public
    constructor Create(const AParent: TSkuchainMetadata); override;
    destructor Destroy; override;

    property Applications: TSkuchainMetadataList read FApplications;
    function ForEachApplication(const ADoSomething: TProc<TSkuchainApplicationMetadata>): Integer;
  end;

implementation

uses
    Skuchain.Core.URL
  , Skuchain.Metadata.InjectionService
;

{ TSkuchainApplicationMetadata }

constructor TSkuchainApplicationMetadata.Create(const AParent: TSkuchainMetadata);
begin
  inherited Create(AParent);
  if Assigned(Engine) then
    Engine.Applications.Add(Self);
  FResources := TSkuchainMetadataList.Create;
end;

destructor TSkuchainApplicationMetadata.Destroy;
begin
  FResources.Free;
  inherited;
end;

function TSkuchainApplicationMetadata.FindResource(
  const AName: string): TSkuchainResourceMetadata;
var
  LResult: TSkuchainResourceMetadata;
begin
  LResult := nil;
  ForEachResource(
    procedure (ARes: TSkuchainResourceMetadata)
    begin
      if SameText(ARes.Name, AName) then
        LResult := ARes;
    end
  );
  Result := LResult;
end;

function TSkuchainApplicationMetadata.ForEachMethod(
  const ADoSomething: TProc<TSkuchainResourceMetadata, TSkuchainMethodMetadata>): Integer;
begin
  Result := ForEachResource(
    procedure (AResource: TSkuchainResourceMetadata)
    begin
      AResource.ForEachMethod(
        procedure (AMethod: TSkuchainMethodMetadata)
        begin
          ADoSomething(AResource, AMethod);
        end
      );
    end
  );
end;

function TSkuchainApplicationMetadata.ForEachResource(
  const ADoSomething: TProc<TSkuchainResourceMetadata>): Integer;
begin
  Result := Resources.ForEach<TSkuchainResourceMetadata>(ADoSomething);
end;

function TSkuchainApplicationMetadata.GetEngine: TSkuchainEngineMetadata;
begin
  Result := Parent as TSkuchainEngineMetadata;
end;

{ TSkuchainResourceMetadata }

constructor TSkuchainResourceMetadata.Create(const AParent: TSkuchainMetadata);
begin
  inherited Create(AParent);
  if Assigned(Application) then
    Application.Resources.Add(Self);
  FMethods := TSkuchainMetadataList.Create;
end;

destructor TSkuchainResourceMetadata.Destroy;
begin
  FMethods.Free;
  inherited;
end;

function TSkuchainResourceMetadata.ForEachMethod(
  const ADoSomething: TProc<TSkuchainMethodMetadata>): Integer;
begin
  Result := Methods.ForEach<TSkuchainMethodMetadata>(ADoSomething);
end;

function TSkuchainResourceMetadata.GetApplication: TSkuchainApplicationMetadata;
begin
  Result := Parent as TSkuchainApplicationMetadata;
end;

{ TSkuchainMethodMetadata }

constructor TSkuchainMethodMetadata.Create(const AParent: TSkuchainMetadata);
begin
  inherited Create(AParent);
  if Assigned(Resource) then
    Resource.Methods.Add(Self);

  FParameters := TSkuchainMetadataList.Create;
end;

destructor TSkuchainMethodMetadata.Destroy;
begin
  FParameters.Free;
  inherited;
end;

function TSkuchainMethodMetadata.ForEachParameter(
  const ADoSomething: TProc<TSkuchainRequestParamMetadata>): Integer;
begin
  Result := Parameters.ForEach<TSkuchainRequestParamMetadata>(ADoSomething);
end;

function TSkuchainMethodMetadata.GetQualifiedName: string;
begin
  Result := Name;
  if Assigned(Resource) then
    Result := Resource.Name + '.' + Name;
end;

function TSkuchainMethodMetadata.GetResource: TSkuchainResourceMetadata;
begin
  Result := Parent as TSkuchainResourceMetadata;
end;

{ TSkuchainEngineMetadata }

constructor TSkuchainEngineMetadata.Create(const AParent: TSkuchainMetadata);
begin
  inherited Create(AParent);
  FApplications := TSkuchainMetadataList.Create;
end;

destructor TSkuchainEngineMetadata.Destroy;
begin
  FApplications.Free;
  inherited;
end;

function TSkuchainEngineMetadata.ForEachApplication(
  const ADoSomething: TProc<TSkuchainApplicationMetadata>): Integer;
begin
  Result := Applications.ForEach<TSkuchainApplicationMetadata>(ADoSomething);
end;

{ TSkuchainPathItemMetadata }

function TSkuchainPathItemMetadata.GetFullPath: string;
begin
  Result := Path;
  if Assigned(Parent) and (Parent is TSkuchainPathItemMetadata) then
    Result := TSkuchainURL.CombinePath([TSkuchainPathItemMetadata(Parent).FullPath, Result]);
end;

{ TSkuchainMetadata }

constructor TSkuchainMetadata.Create(const AParent: TSkuchainMetadata);
begin
  inherited Create;
  FParent := AParent;
  Description := '';
  Visible := True;
end;

{ TSkuchainRequestParamMetadata }

constructor TSkuchainRequestParamMetadata.Create(const AParent: TSkuchainMetadata);
begin
  inherited Create(AParent);
  if Assigned(Method) then
    Method.Parameters.Add(Self);
end;

function TSkuchainRequestParamMetadata.GetMethod: TSkuchainMethodMetadata;
begin
  Result := Parent as TSkuchainMethodMetadata;
end;

{ TSkuchainMetadataList }

function TSkuchainMetadataList.ForEach<T>(const ADoSomething: TProc<T>): Integer;
var
  LItem: TSkuchainMetadata;
begin
  Result := 0;
  if not Assigned(ADoSomething) then
    exit;

  for LItem in Self do
  begin
    if LItem is T then
    begin
      ADoSomething(LItem as T);
      Inc(Result);
    end;
  end;
end;

end.
