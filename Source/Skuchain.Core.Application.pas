(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Application;

{$I Skuchain.inc}

interface

uses
    SysUtils, Classes, Rtti, Generics.Collections
  , Skuchain.Core.Classes
  , Skuchain.Core.URL
  , Skuchain.Core.Registry
  , Skuchain.Core.Exceptions
  , Skuchain.Utils.Parameters
  ;

type
  ESkuchainApplicationException = class(ESkuchainHttpException);
  ESkuchainAuthenticationException = class(ESkuchainApplicationException);
  ESkuchainAuthorizationException = class(ESkuchainApplicationException);

  TSkuchainApplication = class
  private
    FRttiContext: TRttiContext;
    FResourceRegistry: TObjectDictionary<string, TSkuchainConstructorInfo>;
    FBasePath: string;
    FName: string;
    FSystem: Boolean;
    FParameters: TSkuchainParameters;
  protected
  public
    constructor Create(const AName: string); virtual;
    destructor Destroy; override;

    function AddResource(AResource: string): Boolean;
    procedure EnumerateResources(const ADoSomething: TProc<string, TSkuchainConstructorInfo>);

    property Name: string read FName;
    property BasePath: string read FBasePath write FBasePath;
    property System: Boolean read FSystem write FSystem;
    property Resources: TObjectDictionary<string, TSkuchainConstructorInfo> read FResourceRegistry;
    property Parameters: TSkuchainParameters read FParameters;
  end;

  TSkuchainApplicationDictionary = class(TObjectDictionary<string, TSkuchainApplication>)
  end;

implementation

uses
    StrUtils
  , Skuchain.Core.Utils, Skuchain.Rtti.Utils
  , Skuchain.Core.Attributes
;

{ TSkuchainApplication }

function TSkuchainApplication.AddResource(AResource: string): Boolean;

  function AddResourceToApplicationRegistry(const AInfo: TSkuchainConstructorInfo): Boolean;
  var
    LClass: TClass;
    LResult: Boolean;
  begin
    LResult := False;
    LClass := AInfo.TypeTClass;
    FRttiContext.GetType(LClass).HasAttribute<PathAttribute>(
      procedure (AAttribute: PathAttribute)
      var
        LURL: TSkuchainURL;
        LResourceName: string;
      begin
        LURL := TSkuchainURL.CreateDummy(AAttribute.Value);
        try
          LResourceName := '';
          if LURL.HasPathTokens then
            LResourceName := LURL.PathTokens[0].ToLower;

          if not FResourceRegistry.ContainsKey(LResourceName) then
          begin
            FResourceRegistry.Add(LResourceName, AInfo.Clone);
            LResult := True;
          end;

        finally
          LURL.Free;
        end;
      end
    );
    Result := LResult;
  end;

var
  LRegistry: TSkuchainResourceRegistry;
  LInfo: TSkuchainConstructorInfo;
  LKey, LKeyToLower: string;
  LResourceToLower: string;
begin
  Result := False;
  LRegistry := TSkuchainResourceRegistry.Instance;
  LResourceToLower := AResource.ToLower;

  if IsMask(AResource) then // has wildcards and so on...
  begin
    for LKey in LRegistry.Keys.ToArray do
    begin
      LKeyToLower := LKey.ToLower;
      if MatchesMask(LKeyToLower, LResourceToLower) then
      begin
        if LRegistry.TryGetValue(LKeyToLower, LInfo) and AddResourceToApplicationRegistry(LInfo) then
          Result := True;
      end;
    end;
  end
  else // exact match
    if LRegistry.TryGetValue(LResourceToLower, LInfo) then
      Result := AddResourceToApplicationRegistry(LInfo);
end;

constructor TSkuchainApplication.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FRttiContext := TRttiContext.Create;
  FResourceRegistry := TObjectDictionary<string, TSkuchainConstructorInfo>.Create([doOwnsValues]);
  FParameters := TSkuchainParameters.Create(AName);
end;

destructor TSkuchainApplication.Destroy;
begin
  FParameters.Free;
  FResourceRegistry.Free;
  inherited;
end;

procedure TSkuchainApplication.EnumerateResources(
  const ADoSomething: TProc<string, TSkuchainConstructorInfo>);
var
  LPair: TPair<string, TSkuchainConstructorInfo>;
begin
  if Assigned(ADoSomething) then
    for LPair in FResourceRegistry do
      ADoSomething(LPair.Key, LPair.Value);
end;

end.
