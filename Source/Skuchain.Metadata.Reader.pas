(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Metadata.Reader;

interface

uses
    Classes, SysUtils, Rtti, TypInfo
  , Skuchain.Metadata
  , Skuchain.Core.Engine
  , Skuchain.Core.Application
  , Skuchain.Core.Registry
;

type
  TSkuchainMetadataReader=class
  private
    FEngine: TSkuchainEngine;
    FMetadata: TSkuchainEngineMetadata;
  protected
    procedure ReadApplication(const AApplication: TSkuchainApplication); virtual;
    procedure ReadResource(const AApplication: TSkuchainApplication;
      const AApplicationMetadata: TSkuchainApplicationMetadata;
      const AResourcePath: string; AResourceInfo: TSkuchainConstructorInfo); virtual;
    procedure ReadMethod(const AResourceMetadata: TSkuchainResourceMetadata;
      const AMethod: TRttiMethod); virtual;
    procedure ReadParameter(const AResourceMetadata: TSkuchainResourceMetadata;
      const AMethodMetadata: TSkuchainMethodMetadata;
      const AParameter: TRttiParameter; const AMethod: TRttiMethod); virtual;
  public
    constructor Create(const AEngine: TSkuchainEngine; const AReadImmediately: Boolean = True); virtual;
    destructor Destroy; override;

    procedure Read; virtual;

    property Engine: TSkuchainEngine read FEngine;
    property Metadata: TSkuchainEngineMetadata read FMetadata;
  end;

implementation

uses
    Skuchain.Core.Utils
  , Skuchain.Rtti.Utils
  , Skuchain.Core.Attributes
  , Skuchain.Core.Exceptions
  , Skuchain.Metadata.Attributes
;


{ TSkuchainMetadataReader }

constructor TSkuchainMetadataReader.Create(const AEngine: TSkuchainEngine; const AReadImmediately: Boolean);
begin
  inherited Create;
  FEngine := AEngine;
  FMetadata := TSkuchainEngineMetadata.Create(nil);

  if AReadImmediately then
    Read;
end;

destructor TSkuchainMetadataReader.Destroy;
begin
  FMetadata.Free;
  inherited;
end;

procedure TSkuchainMetadataReader.Read;
begin
  Metadata.Name := Engine.Name;
  Metadata.Path := Engine.BasePath;

  Engine.EnumerateApplications(
    procedure (APath: string; AApplication: TSkuchainApplication)
    begin
      ReadApplication(AApplication);
    end
  );

end;

procedure TSkuchainMetadataReader.ReadApplication(
  const AApplication: TSkuchainApplication);
var
  LApplicationMetadata: TSkuchainApplicationMetadata;
begin
  LApplicationMetadata := TSkuchainApplicationMetadata.Create(FMetadata);
  try
    LApplicationMetadata.Name := AApplication.Name;
    LApplicationMetadata.Path := AApplication.BasePath;

    AApplication.EnumerateResources(
      procedure (APath: string; AConstructorInfo: TSkuchainConstructorInfo)
      begin
        ReadResource(AApplication, LApplicationMetadata, APath, AConstructorInfo);
      end
    );
  except
    LApplicationMetadata.Free;
    raise;
  end;
end;

procedure TSkuchainMetadataReader.ReadMethod(
  const AResourceMetadata: TSkuchainResourceMetadata; const AMethod: TRttiMethod);
var
  LMethodMetadata: TSkuchainMethodMetadata;
  LParameters: TArray<TRttiParameter>;
  LParameter: TRttiParameter;
begin
  LMethodMetadata := TSkuchainMethodMetadata.Create(AResourceMetadata);
  try
    LMethodMetadata.Name := AMethod.Name;
    AMethod.HasAttribute<PathAttribute>(
      procedure (Attribute: PathAttribute)
      begin
        LMethodMetadata.Path := Attribute.Value;
      end
    );

    LMethodMetadata.Description := '';
    AMethod.HasAttribute<MetaDescriptionAttribute>(
      procedure (Attribute: MetaDescriptionAttribute)
      begin
        LMethodMetadata.Description := Attribute.Text;
      end
    );

    LMethodMetadata.Visible := True;
    AMethod.HasAttribute<MetaVisibleAttribute>(
      procedure (Attribute: MetaVisibleAttribute)
      begin
        LMethodMetadata.Visible := Attribute.Value;
      end
    );

    LMethodMetadata.DataType := '';
    if (AMethod.MethodKind in [mkFunction, mkClassFunction]) then
      LMethodMetadata.DataType := AMethod.ReturnType.QualifiedName;

    AMethod.ForEachAttribute<HttpMethodAttribute>(
      procedure (Attribute: HttpMethodAttribute)
      begin
        LMethodMetadata.HttpMethod := SmartConcat([LMethodMetadata.HttpMethod, Attribute.HttpMethodName]);
      end
    );

    AMethod.ForEachAttribute<ProducesAttribute>(
      procedure (Attribute: ProducesAttribute)
      begin
        LMethodMetadata.Produces := SmartConcat([LMethodMetadata.Produces, Attribute.Value]);
      end
    );
    if LMethodMetadata.Produces.IsEmpty then
      LMethodMetadata.Produces := AResourceMetadata.Produces;


    AMethod.ForEachAttribute<ConsumesAttribute>(
      procedure (Attribute: ConsumesAttribute)
      begin
        LMethodMetadata.Consumes := SmartConcat([LMethodMetadata.Consumes, Attribute.Value]);
      end
    );
    if LMethodMetadata.Consumes.IsEmpty then
      LMethodMetadata.Consumes := AResourceMetadata.Consumes;

     AMethod.ForEachAttribute<AuthorizationAttribute>(
      procedure (Attribute: AuthorizationAttribute)
      begin
        LMethodMetadata.Authorization :=  SmartConcat([LMethodMetadata.Authorization, Attribute.ToString]);
      end
    );
    if LMethodMetadata.Authorization.IsEmpty then
      LMethodMetadata.Authorization := AResourceMetadata.Authorization;

    LParameters := AMethod.GetParameters;
    for LParameter in LParameters do
      ReadParameter(AResourceMetadata, LMethodMetadata, LParameter, AMethod);
  except
    LMethodMetadata.Free;
    raise;
  end;
end;

procedure TSkuchainMetadataReader.ReadParameter(
  const AResourceMetadata: TSkuchainResourceMetadata;
  const AMethodMetadata: TSkuchainMethodMetadata;
  const AParameter: TRttiParameter; const AMethod: TRttiMethod);
begin
  AParameter.HasAttribute<RequestParamAttribute>(
    procedure (AAttribute: RequestParamAttribute)
    var
      LRequestParamMetadata: TSkuchainRequestParamMetadata;
    begin
      LRequestParamMetadata := TSkuchainRequestParamMetadata.Create(AMethodMetadata);
      try
        LRequestParamMetadata.Description := '';
        AParameter.HasAttribute<MetaDescriptionAttribute>(
          procedure (Attribute: MetaDescriptionAttribute)
          begin
            LRequestParamMetadata.Description := Attribute.Text;
          end
        );

        LRequestParamMetadata.Kind := AAttribute.Kind;
        if AAttribute is NamedRequestParamAttribute then
          LRequestParamMetadata.Name := NamedRequestParamAttribute(AAttribute).Name;
        if LRequestParamMetadata.Name.IsEmpty then
          LRequestParamMetadata.Name := AParameter.Name;
        LRequestParamMetadata.DataType := AParameter.ParamType.QualifiedName;
      except
        LRequestParamMetadata.Free;
        raise;
      end;
    end
  );
end;

procedure TSkuchainMetadataReader.ReadResource(const AApplication: TSkuchainApplication;
  const AApplicationMetadata: TSkuchainApplicationMetadata;
  const AResourcePath: string; AResourceInfo: TSkuchainConstructorInfo);
var
  LRttiContext: TRttiContext;
  LResourceType: TRttiType;
  LResourceMetadata: TSkuchainResourceMetadata;
begin
  LResourceType := LRttiContext.GetType(AResourceInfo.TypeTClass);

  LResourceMetadata := TSkuchainResourceMetadata.Create(AApplicationMetadata);
  try
    LResourceMetadata.Path := AResourcePath;
    LResourceMetadata.Name := LResourceType.Name;

    LResourceMetadata.Description := '';
    LResourceType.HasAttribute<MetaDescriptionAttribute>(
      procedure (Attribute: MetaDescriptionAttribute)
      begin
        LResourceMetadata.Description := Attribute.Text;
      end
    );

    LResourceMetadata.Visible := True;
    LResourceType.HasAttribute<MetaVisibleAttribute>(
      procedure (Attribute: MetaVisibleAttribute)
      begin
        LResourceMetadata.Visible := Attribute.Value;
      end
    );

    LResourceType.ForEachAttribute<ProducesAttribute>(
      procedure (Attribute: ProducesAttribute)
      begin
        LResourceMetadata.Produces := SmartConcat([LResourceMetadata.Produces, Attribute.Value]);
      end
    );

    LResourceType.ForEachAttribute<ConsumesAttribute>(
      procedure (Attribute: ConsumesAttribute)
      begin
        LResourceMetadata.Consumes := SmartConcat([LResourceMetadata.Consumes, Attribute.Value]);
      end
    );

    LResourceType.ForEachAttribute<AuthorizationAttribute>(
      procedure (Attribute: AuthorizationAttribute)
      begin
        LResourceMetadata.Authorization := SmartConcat([LResourceMetadata.Authorization, Attribute.ToString]);
      end
    );

    LResourceType.ForEachMethodWithAttribute<HttpMethodAttribute>(
      function (AMethod: TRttiMethod; AHttpMethodAttribute: HttpMethodAttribute): Boolean
      begin
        Result := True;

        ReadMethod(LResourceMetadata, AMethod);
      end
    );
  except
    LResourceMetadata.Free;
    raise;
  end;
end;

end.
