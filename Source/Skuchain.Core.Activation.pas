(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Activation;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes, Generics.Collections, Rtti, Diagnostics
  , HTTPApp

  , Skuchain.Core.Classes
  , Skuchain.Core.URL
  , Skuchain.Core.Application
  , Skuchain.Core.Engine
  , Skuchain.Core.Token
  , Skuchain.Core.Registry
  , Skuchain.Core.MessageBodyWriter
  , Skuchain.Core.MediaType
  , Skuchain.Core.Injection.Types
  , Skuchain.Core.Activation.Interfaces
  ;

type
  TSkuchainActivation = class;

  TSkuchainActivationFactoryFunc = reference to function (const AEngine: TSkuchainEngine;
    const AApplication: TSkuchainApplication;
    const ARequest: TWebRequest; const AResponse: TWebResponse;
    const AURL: TSkuchainURL
  ): ISkuchainActivation;

  TSkuchainBeforeInvokeProc = reference to procedure(const AActivation: ISkuchainActivation; out AIsAllowed: Boolean);
  TSkuchainAfterInvokeProc = reference to procedure(const AActivation: ISkuchainActivation);

  TSkuchainAuthorizationInfo = record
  public
    DenyAll, PermitAll: Boolean;
    AllowedRoles: TArray<string>;
    function NeedsAuthentication: Boolean;
    function NeedsAuthorization: Boolean;
    constructor Create(const ADenyAll, APermitAll: Boolean; const AAllowedRoles: TArray<string>);
  end;

  TSkuchainActivation = class(TInterfacedObject, ISkuchainActivation)
  private
    FRequest: TWebRequest;
    FResponse: TWebResponse;
    class var FBeforeInvokeProcs: TArray<TSkuchainBeforeInvokeProc>;
    class var FAfterInvokeProcs: TArray<TSkuchainAfterInvokeProc>;
  protected
    FRttiContext: TRttiContext;
    FConstructorInfo: TSkuchainConstructorInfo;
    FApplication: TSkuchainApplication;
    FEngine: TSkuchainEngine;
    FURL: TSkuchainURL;
    FURLPrototype: TSkuchainURL;
    FToken: TSkuchainToken;
    FContext: TList<TValue>;
    FMethod: TRttiMethod;
    FResource: TRttiType;
    FResourceInstance: TObject;
    FMethodArguments: TArray<TValue>;
    FMethodResult: TValue;
    FWriter: IMessageBodyWriter;
    FWriterMediaType: TMediaType;
    FInvocationTime: TStopWatch;
    FAuthorizationInfo: TSkuchainAuthorizationInfo;

    procedure FreeContext; virtual;
    procedure CleanupGarbage(const AValue: TValue); virtual;
    procedure ContextInjection; virtual;
    function GetContextValue(const ADestination: TRttiObject): TInjectionValue; virtual;
    function GetMethodArgument(const AParam: TRttiParameter): TValue; virtual;
    function GetProducesValue: string; virtual;
    procedure FillResourceMethodParameters; virtual;
    procedure FindMethodToInvoke; virtual;
    procedure InvokeResourceMethod; virtual;
    procedure SetCustomHeaders; virtual;

    function DoBeforeInvoke: Boolean;
    procedure DoAfterInvoke;

    procedure CheckResource; virtual;
    procedure CheckMethod; virtual;
    procedure ReadAuthorizationInfo; virtual;
    procedure CheckAuthentication; virtual;
    procedure CheckAuthorization; virtual;
  public
    constructor Create(const AEngine: TSkuchainEngine; const AApplication: TSkuchainApplication;
      const ARequest: TWebRequest; const AResponse: TWebResponse; const AURL: TSkuchainURL); virtual;
    destructor Destroy; override;

    procedure Prepare; virtual;

    // --- ISkuchainActivation implementation --------------
    procedure AddToContext(AValue: TValue); virtual;
    function HasToken: Boolean; virtual;
    procedure Invoke; virtual;

    function GetApplication: TSkuchainApplication;
    function GetEngine: TSkuchainEngine;
    function GetInvocationTime: TStopwatch;
    function GetMethod: TRttiMethod;
    function GetMethodArguments: TArray<TValue>;
    function GetMethodResult: TValue;
    function GetRequest: TWebRequest;
    function GetResource: TRttiType;
    function GetResourceInstance: TObject;
    function GetResponse: TWebResponse;
    function GetURL: TSkuchainURL;
    function GetURLPrototype: TSkuchainURL;
    function GetToken: TSkuchainToken;
    // ---

    property Application: TSkuchainApplication read FApplication;
    property Engine: TSkuchainEngine read FEngine;
    property InvocationTime: TStopwatch read FInvocationTime;
    property Method: TRttiMethod read FMethod;
    property MethodArguments: TArray<TValue> read FMethodArguments;
    property Request: TWebRequest read FRequest;
    property Resource: TRttiType read FResource;
    property ResourceInstance: TObject read FResourceInstance;
    property Response: TWebResponse read FResponse;
    property URL: TSkuchainURL read FURL;
    property URLPrototype: TSkuchainURL read FURLPrototype;
    property Token: TSkuchainToken read GetToken;

    class procedure RegisterBeforeInvoke(const ABeforeInvoke: TSkuchainBeforeInvokeProc);
//    class procedure UnregisterBeforeInvoke(const ABeforeInvoke: TSkuchainBeforeInvokeProc);
    class procedure RegisterAfterInvoke(const AAfterInvoke: TSkuchainAfterInvokeProc);
//    class procedure UnregisterAfterInvoke(const AAfterInvoke: TSkuchainAfterInvokeProc);

    class var CreateActivationFunc: TSkuchainActivationFactoryFunc;
    class function CreateActivation(const AEngine: TSkuchainEngine;
      const AApplication: TSkuchainApplication;
      const ARequest: TWebRequest; const AResponse: TWebResponse;
      const AURL: TSkuchainURL): ISkuchainActivation;
  end;

implementation

uses
    Skuchain.Core.Attributes
  , Skuchain.Core.Response
  , Skuchain.Core.MessageBodyReader
  , Skuchain.Core.Exceptions
  , Skuchain.Core.Utils
  , Skuchain.Utils.Parameters
  , Skuchain.Rtti.Utils
  , Skuchain.Core.Injection
  , Skuchain.Core.Activation.InjectionService
  , TypInfo
;

{ TSkuchainActivation }

function TSkuchainActivation.GetMethod: TRttiMethod;
begin
  Result := FMethod;
end;

function TSkuchainActivation.GetMethodArgument(const AParam: TRttiParameter): TValue;
var
  LParamValue: TValue;
begin
  TValue.Make(nil, AParam.ParamType.Handle, LParamValue);

  AParam.HasAttribute<ContextAttribute>(
    procedure (AContextAttr: ContextAttribute)
    begin
      LParamValue := GetContextValue(AParam).Value;
    end
  );

  Result := LParamValue;
end;

function TSkuchainActivation.GetMethodArguments: TArray<TValue>;
begin
  Result := FMethodArguments;
end;

function TSkuchainActivation.GetMethodResult: TValue;
begin
  Result := FMethodResult;
end;

function TSkuchainActivation.GetProducesValue: string;
var
  LProduces: string;
begin
  LProduces := '';

  Method.HasAttribute<ProducesAttribute>(
    procedure(AAttr: ProducesAttribute)
    begin
      LProduces := AAttr.Value;
    end
  );
  if LProduces = '' then
    Resource.HasAttribute<ProducesAttribute>(
      procedure(AAttr: ProducesAttribute)
      begin
        LProduces := AAttr.Value;
      end
    );
  { TODO -oAndrea : Fallback to Application default? }

  Result := LProduces;
end;

function TSkuchainActivation.GetRequest: TWebRequest;
begin
  Result := FRequest;
end;

function TSkuchainActivation.GetResource: TRttiType;
begin
  Result := FResource;
end;

function TSkuchainActivation.GetResourceInstance: TObject;
begin
  Result := FResourceInstance;
end;

function TSkuchainActivation.GetResponse: TWebResponse;
begin
  Result := FResponse;
end;

function TSkuchainActivation.GetToken: TSkuchainToken;
begin
  if not Assigned(FToken) then
    FToken := GetContextValue(FRttiContext.GetType(Self.ClassType).GetField('FToken')).Value.AsType<TSkuchainToken>;
  Result := FToken;

  if not Assigned(Result) then
    raise Exception.Create('Token injection failed in SkuchainActivation');
end;

function TSkuchainActivation.GetURL: TSkuchainURL;
begin
  Result := FURL;
end;

function TSkuchainActivation.GetURLPrototype: TSkuchainURL;
begin
  Result := FURLPrototype;
end;

function TSkuchainActivation.HasToken: Boolean;
begin
  Result := Assigned(FToken);
end;

procedure TSkuchainActivation.FillResourceMethodParameters;
var
  LParameters: TArray<TRttiParameter>;
  LIndex: Integer;
  LParameter: TRttiParameter;
begin
  Assert(Assigned(FMethod));
  try
    LParameters := FMethod.GetParameters;
    SetLength(FMethodArguments, Length(LParameters));
    for LIndex := Low(LParameters) to High(LParameters) do
    begin
      LParameter := LParameters[LIndex];
      FMethodArguments[LIndex] := GetMethodArgument(LParameter);
    end;
  except
    on E: Exception do
      raise ESkuchainApplicationException.Create('Bad parameter values for resource method ' + FMethod.Name);
  end;
end;

procedure TSkuchainActivation.FindMethodToInvoke;
var
  LMethod: TRttiMethod;
  LResourcePath: string;
  LAttribute: TCustomAttribute;
  LPathMatches: Boolean;
  LHttpMethodMatches: Boolean;
  LMethodPath: string;
begin
  FResource := FRttiContext.GetType(FConstructorInfo.TypeTClass);
  FMethod := nil;
  FreeAndNil(FURLPrototype);

  LResourcePath := '';
  FResource.HasAttribute<PathAttribute>(
    procedure (APathAttribute: PathAttribute)
    begin
      LResourcePath := APathAttribute.Value;
    end
  );

  for LMethod in FResource.GetMethods do
  begin
    if (LMethod.Visibility < TMemberVisibility.mvPublic)
      or LMethod.IsConstructor or LMethod.IsDestructor
    then
      Continue;

    LMethodPath := '';
    LHttpMethodMatches := False;

    for LAttribute in LMethod.GetAttributes do
    begin
      if LAttribute is PathAttribute then
        LMethodPath := PathAttribute(LAttribute).Value;

      if LAttribute is HttpMethodAttribute then
        LHttpMethodMatches := HttpMethodAttribute(LAttribute).Matches(Request);

      { TODO -oAndrea : Check MediaType (you might have multiple methods matching, so let's discriminate using Request.Accept and Resource+Method's Produces attribute) }
    end;

    if LHttpMethodMatches then
    begin
      FURLPrototype := TSkuchainURL.CreateDummy([Engine.BasePath, Application.BasePath, LResourcePath, LMethodPath]);
      try
        LPathMatches := FURLPrototype.MatchPath(URL);
        if LPathMatches and LHttpMethodMatches then
        begin
          FMethod := LMethod;
          Break;
        end;
      finally
        if not Assigned(FMethod) then
          FreeAndNil(FURLPrototype);
      end;
    end;
  end;
end;

procedure TSkuchainActivation.CleanupGarbage(const AValue: TValue);
var
  LIndex: Integer;
  LValue: TValue;
begin
  case AValue.Kind of
    tkClass: AValue.AsObject.Free;
    tkArray,
    tkDynArray:
    begin
      for LIndex := 0 to AValue.GetArrayLength -1 do
      begin
        LValue := AValue.GetArrayElement(LIndex);
        case LValue.Kind of
          tkClass: LValue.AsObject.Free;
          tkArray, tkDynArray: CleanupGarbage(LValue); //recursion
        end;
      end;
    end;
  end;
end;

procedure TSkuchainActivation.FreeContext;
var
  LDestroyed: TList<TObject>;
  LValue: TValue;
begin
  if FContext.Count = 0 then
    Exit;

  LDestroyed := TList<TObject>.Create;
  try
    while FContext.Count > 0 do
    begin
      LValue := FContext[0];
      if LValue.IsObject then
      begin
        if not LDestroyed.Contains(LValue.AsObject) then
        begin
          LDestroyed.Add(LValue.AsObject);
          CleanupGarbage(LValue);
        end;
      end
      else
        CleanupGarbage(LValue);
      FContext.Delete(0);
    end;
  finally
    LDestroyed.Free;
  end;
end;

procedure TSkuchainActivation.InvokeResourceMethod();
var
  LStream: TBytesStream;
  LContentType: string;
begin
  Assert(Assigned(FMethod));

  // cache initial ContentType value to check later if it has been changed
  LContentType := string(Response.ContentType);

  try
    FMethodResult := FMethod.Invoke(FResourceInstance, FMethodArguments);

    // handle response
    SetCustomHeaders;

    // 1 - TSkuchainResponse (override)
    if (not FMethodResult.IsEmpty) // workaround for IsInstanceOf returning True on empty value (https://quality.embarcadero.com/browse/RSP-15301)
       and FMethodResult.IsInstanceOf(TSkuchainResponse)
    then
      TSkuchainResponse(FMethodResult.AsObject).CopyTo(Response)
    // 2 - MessageBodyWriter mechanism (standard)
    else begin
      TSkuchainMessageBodyRegistry.Instance.FindWriter(Self, FWriter, FWriterMediaType);
      try
        if Assigned(FWriter) then
        begin
          if string(Response.ContentType) = LContentType then
            Response.ContentType := FWriterMediaType.ToString;

          LStream := TBytesStream.Create();
          try
            FWriter.WriteTo(FMethodResult, FWriterMediaType, LStream, Self);
            LStream.Position := 0;
            Response.ContentStream := LStream;
          except
            LStream.Free;
            raise;
          end;
        end
        // 3 - fallback (raw)
        else
        begin
          Response.ContentType := GetProducesValue;
          if Response.ContentType = '' then
            Response.ContentType := TMediaType.WILDCARD;
          if Assigned(FMethod.ReturnType) then
          begin
            if (FMethodResult.Kind in [tkString, tkUString, tkChar, {$ifdef DelphiXE7_UP}tkWideChar,{$endif} tkLString, tkWString])  then
              Response.Content := FMethodResult.AsString
            else if (FMethodResult.IsType<Boolean>) then
              Response.Content := BoolToStr(FMethodResult.AsType<Boolean>, True)
            else if FMethodResult.TypeInfo = TypeInfo(TDateTime) then
              Response.Content := DateToJSON(FMethodResult.AsType<TDateTime>)
            else if FMethodResult.TypeInfo = TypeInfo(TDate) then
              Response.Content := DateToJSON(FMethodResult.AsType<TDate>)
            else if FMethodResult.TypeInfo = TypeInfo(TTime) then
              Response.Content := DateToJSON(FMethodResult.AsType<TTime>)

            else if (FMethodResult.Kind in [tkInt64]) then
              Response.Content := IntToStr(FMethodResult.AsType<Int64>)
            else if (FMethodResult.Kind in [tkInteger]) then
              Response.Content := IntToStr(FMethodResult.AsType<Integer>)

            else if (FMethodResult.Kind in [tkFloat]) then
              Response.Content := FormatFloat('0.00000000', FMethodResult.AsType<Double>)
            else
              Response.Content := FMethodResult.ToString;
          end;

          Response.StatusCode := 200;
        end;
      finally
        FWriter := nil;
        FreeAndNil(FWriterMediaType);
      end;
    end;
  finally
    if not FMethod.HasAttribute<IsReference>(nil) then
      AddToContext(FMethodResult);
  end;
end;

procedure TSkuchainActivation.Prepare;
begin
  Request.ReadTotalContent; // workaround for https://quality.embarcadero.com/browse/RSP-14674

  CheckResource;
  CheckMethod;
  ReadAuthorizationInfo;
  CheckAuthentication;
  CheckAuthorization;
  FillResourceMethodParameters;
end;

procedure TSkuchainActivation.ReadAuthorizationInfo;
var
  LProcessAuthorizationAttribute: TProc<AuthorizationAttribute>;
  LAllowedRoles: TStringList;
begin
{$ifdef DelphiXE7_UP}
  FAuthorizationInfo := TSkuchainAuthorizationInfo.Create(False, False, []);
{$else}
  FAuthorizationInfo := TSkuchainAuthorizationInfo.Create(False, False, nil);
{$endif}

  LAllowedRoles := TStringList.Create;
  try
    LAllowedRoles.Sorted := True;
    LAllowedRoles.Duplicates := TDuplicates.dupIgnore;

    LProcessAuthorizationAttribute :=
      procedure (AAttribute: AuthorizationAttribute)
      begin
        if AAttribute is DenyAllAttribute then
          FAuthorizationInfo.DenyAll := True
        else if AAttribute is PermitAllAttribute then
          FAuthorizationInfo.PermitAll := True
        else if AAttribute is RolesAllowedAttribute then
          LAllowedRoles.AddStrings(RolesAllowedAttribute(AAttribute).Roles);
      end;

    FMethod.ForEachAttribute<AuthorizationAttribute>(LProcessAuthorizationAttribute);
    FResource.ForEachAttribute<AuthorizationAttribute>(LProcessAuthorizationAttribute);

    FAuthorizationInfo.AllowedRoles := LAllowedRoles.ToStringArray;
  finally
    LAllowedRoles.Free;
  end;
end;

class procedure TSkuchainActivation.RegisterAfterInvoke(
  const AAfterInvoke: TSkuchainAfterInvokeProc);
begin
  SetLength(FAfterInvokeProcs, Length(FAfterInvokeProcs) + 1);
  FAfterInvokeProcs[Length(FAfterInvokeProcs)-1] := TSkuchainAfterInvokeProc(AAfterInvoke);
end;

class procedure TSkuchainActivation.RegisterBeforeInvoke(
  const ABeforeInvoke: TSkuchainBeforeInvokeProc);
begin
  SetLength(FBeforeInvokeProcs, Length(FBeforeInvokeProcs) + 1);
  FBeforeInvokeProcs[Length(FBeforeInvokeProcs)-1] := TSkuchainBeforeInvokeProc(ABeforeInvoke);
end;

procedure TSkuchainActivation.SetCustomHeaders;
var
  LCustomAtributeProcessor: TProc<CustomHeaderAttribute>;

begin
  LCustomAtributeProcessor :=
    procedure (ACustomHeader: CustomHeaderAttribute)
    begin
      Response.CustomHeaders.Values[ACustomHeader.HeaderName] := ACustomHeader.Value;
    end;
  FResource.ForEachAttribute<CustomHeaderAttribute>(LCustomAtributeProcessor);
  FMethod.ForEachAttribute<CustomHeaderAttribute>(LCustomAtributeProcessor);
end;

//class procedure TSkuchainActivation.UnregisterAfterInvoke(
//  const AAfterInvoke: TSkuchainAfterInvokeProc);
//begin
//  FAfterInvokeProcs := FAfterInvokeProcs - [TSkuchainAfterInvokeProc(AAfterInvoke)];
//end;
//
//class procedure TSkuchainActivation.UnregisterBeforeInvoke(
//  const ABeforeInvoke: TSkuchainBeforeInvokeProc);
//begin
//  FBeforeInvokeProcs := FBeforeInvokeProcs - [TSkuchainBeforeInvokeProc(ABeforeInvoke)];
//end;

procedure TSkuchainActivation.Invoke;
begin
  Assert(Assigned(FConstructorInfo));
  Assert(Assigned(FMethod));

  try
    if DoBeforeInvoke then
    begin
      FInvocationTime := TStopwatch.StartNew;
      FResourceInstance := FConstructorInfo.ConstructorFunc();
      try
        ContextInjection;
        InvokeResourceMethod;
        FInvocationTime.Stop;
        DoAfterInvoke;
      finally
        FResourceInstance.Free;
      end;
    end;
  finally
    FreeContext;
  end;
end;

procedure TSkuchainActivation.CheckAuthentication;
begin
  if (Token.Token <> '') and Token.IsExpired then
    Token.Clear;

  if FAuthorizationInfo.NeedsAuthentication then
    if ((Token.Token = '') or not Token.IsVerified) then
    begin
      Token.Clear;
      raise ESkuchainAuthenticationException.Create('Token missing, not valid or expired', 403);
    end;
end;

procedure TSkuchainActivation.CheckAuthorization;
begin
  if FAuthorizationInfo.NeedsAuthorization then
    if FAuthorizationInfo.DenyAll // DenyAll (stronger than PermitAll and Roles-based authorization)
       or (
         not FAuthorizationInfo.PermitAll  // PermitAll (stronger than Role-based authorization)
         and ((Length(FAuthorizationInfo.AllowedRoles) > 0) and (not Token.HasRole(FAuthorizationInfo.AllowedRoles)))
       ) then
      raise ESkuchainAuthorizationException.Create('Forbidden', 403);
end;

procedure TSkuchainActivation.CheckMethod;
begin
  FindMethodToInvoke;

  if not Assigned(FMethod) then
    raise ESkuchainApplicationException.Create(
      Format('[%s] No implementation found for http method %s'
      , [URL.Resource
{$ifndef Delphi10Seattle_UP}
         , GetEnumName(TypeInfo(TMethodType), Integer(Request.MethodType))
{$else}
         , TRttiEnumerationType.GetName<TMethodType>(Request.MethodType)
{$endif}
      ]), 404);
end;

procedure TSkuchainActivation.CheckResource;
begin
  if not Application.Resources.TryGetValue(URL.Resource.ToLower, FConstructorInfo) then
    raise ESkuchainApplicationException.Create(Format('Resource [%s] not found', [URL.Resource]), 404);
end;

procedure TSkuchainActivation.AddToContext(AValue: TValue);
begin
  if not AValue.IsEmpty then
    FContext.Add(AValue);
end;

procedure TSkuchainActivation.ContextInjection();
var
  LType: TRttiType;
begin
  LType := FRttiContext.GetType(FResourceInstance.ClassType);

  // fields
  LType.ForEachFieldWithAttribute<ContextAttribute>(
    function (AField: TRttiField; AAttrib: ContextAttribute): Boolean
    begin
      Result := True; // enumerate all
      AField.SetValue(FResourceInstance, GetContextValue(AField).Value);
    end
  );

  // properties
  LType.ForEachPropertyWithAttribute<ContextAttribute>(
    function (AProperty: TRttiProperty; AAttrib: ContextAttribute): Boolean
    begin
      Result := True; // enumerate all
      AProperty.SetValue(FResourceInstance, GetContextValue(AProperty).Value);
    end
  );
end;

function TSkuchainActivation.GetApplication: TSkuchainApplication;
begin
  Result := FApplication;
end;

function TSkuchainActivation.GetContextValue(const ADestination: TRttiObject): TInjectionValue;
begin
  Result := TSkuchainInjectionServiceRegistry.Instance.GetValue(ADestination, Self);
  if not Result.IsReference then
    AddToContext(Result.Value);
end;


function TSkuchainActivation.GetEngine: TSkuchainEngine;
begin
  Result := FEngine;
end;

function TSkuchainActivation.GetInvocationTime: TStopwatch;
begin
  Result := FInvocationTime;
end;

constructor TSkuchainActivation.Create(const AEngine: TSkuchainEngine;
  const AApplication: TSkuchainApplication;
  const ARequest: TWebRequest; const AResponse: TWebResponse;
  const AURL: TSkuchainURL);
begin
  inherited Create;
  FEngine := AEngine;
  FApplication := AApplication;
  FRequest := ARequest;
  FResponse := AResponse;
  FURL := AURL;
  FURLPrototype := nil;
  FToken := nil;
  FRttiContext := TRttiContext.Create;
  FContext := TList<TValue>.Create;
  FMethod := nil;
  FMethodArguments := [];
  FMethodResult := TValue.Empty;
  FResourceInstance := nil;
  FInvocationTime.Reset;
  Prepare;
end;

class function TSkuchainActivation.CreateActivation(const AEngine: TSkuchainEngine;
  const AApplication: TSkuchainApplication; const ARequest: TWebRequest;
  const AResponse: TWebResponse; const AURL: TSkuchainURL): ISkuchainActivation;
begin
  if Assigned(CreateActivationFunc) then
    Result := CreateActivationFunc(AEngine, AApplication, ARequest, AResponse, AURL)
  else
    Result := TSkuchainActivation.Create(AEngine, AApplication, ARequest, AResponse, AURL);
end;

destructor TSkuchainActivation.Destroy;
begin
  FreeContext;
  FContext.Free;
  FreeAndNil(FURLPrototype);
  inherited;
end;

procedure TSkuchainActivation.DoAfterInvoke;
var
  LSubscriber: TSkuchainAfterInvokeProc;
begin
  for LSubscriber in FAfterInvokeProcs do
    LSubscriber(Self);
end;

function TSkuchainActivation.DoBeforeInvoke: Boolean;
var
  LSubscriber: TSkuchainBeforeInvokeProc;
begin
  Result := True;
  for LSubscriber in FBeforeInvokeProcs do
    LSubscriber(Self, Result);
end;

{ TSkuchainAuthorizationInfo }

constructor TSkuchainAuthorizationInfo.Create(const ADenyAll, APermitAll: Boolean; const AAllowedRoles: TArray<string>);
begin
  DenyAll := ADenyAll;
  PermitAll := APermitAll;
  AllowedRoles := AAllowedRoles;
end;

function TSkuchainAuthorizationInfo.NeedsAuthentication: Boolean;
begin
  Result := Length(AllowedRoles) > 0;
end;

function TSkuchainAuthorizationInfo.NeedsAuthorization: Boolean;
begin
  Result := (Length(AllowedRoles) > 0) or DenyAll;
end;

end.
