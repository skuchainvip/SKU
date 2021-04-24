(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Client;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Core.JSON
  , Skuchain.Client.Utils, Skuchain.Core.Utils
  ;

type
  TSkuchainAuthEndorsement = (Cookie, AuthorizationBearer);
  TSkuchainHttpVerb = (Get, Put, Post, Head, Delete, Patch);
  TSkuchainClientErrorEvent = procedure (
    AResource: TObject; AException: Exception; AVerb: TSkuchainHttpVerb;
    const AAfterExecute: TSkuchainClientResponseProc; var AHandled: Boolean) of object;

  TSkuchainCustomClient = class; // fwd
  TSkuchainCustomClientClass = class of TSkuchainCustomClient;

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
  TSkuchainCustomClient = class(TComponent)
  private
    FSkuchainEngineURL: string;
    FOnError: TSkuchainClientErrorEvent;
    FAuthEndorsement: TSkuchainAuthEndorsement;
  protected
    procedure AssignTo(Dest: TPersistent); override;

    function GetConnectTimeout: Integer; virtual;
    function GetReadTimeout: Integer; virtual;
    procedure SetConnectTimeout(const Value: Integer); virtual;
    procedure SetReadTimeout(const Value: Integer); virtual;
    procedure SetAuthEndorsement(const Value: TSkuchainAuthEndorsement);

    procedure EndorseAuthorization(const AAuthToken: string); virtual;
    procedure AuthEndorsementChanged; virtual;
  public
    constructor Create(AOwner: TComponent); override;

    procedure DoError(const AResource: TObject; const AException: Exception;
      const AVerb: TSkuchainHttpVerb; const AAfterExecute: TSkuchainClientResponseProc); virtual;

    procedure Delete(const AURL: string; AContent, AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); virtual;
    procedure Get(const AURL: string; AResponseContent: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); virtual;
    procedure Post(const AURL: string; AContent, AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); overload; virtual;
    procedure Post(const AURL: string; const AFormData: TArray<TFormParam>;
      const AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); overload; virtual;
    procedure Put(const AURL: string; AContent, AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); overload; virtual;
    procedure Put(const AURL: string; const AFormData: TArray<TFormParam>;
      const AResponse: TStream;
      const AAuthToken: string; const AAccept: string; const AContentType: string); overload; virtual;

    function LastCmdSuccess: Boolean; virtual;
    function ResponseStatusCode: Integer; virtual;
    function ResponseText: string; virtual;

    // shortcuts
    class function GetJSON<T: TJSONValue>(const AEngineURL, AAppName, AResourceName: string;
      const AToken: string = ''): T; overload;

    class function GetJSON<T: TJSONValue>(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AToken: string = '';
      const AIgnoreResult: Boolean = False): T; overload;

{$ifdef DelphiXE7_UP}
    class procedure GetJSONAsync<T: TJSONValue>(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const ACompletionHandler: TProc<T>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AToken: string = '';
      const ASynchronize: Boolean = True); overload;
{$endif}

    class function GetAsString(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AToken: string = ''): string; overload;

    class function PostJSON(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AContent: TJSONValue;
      const ACompletionHandler: TProc<TJSONValue>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AToken: string = ''
    ): Boolean;

{$ifdef DelphiXE7_UP}
    class procedure PostJSONAsync(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AContent: TJSONValue;
      const ACompletionHandler: TProc<TJSONValue>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AToken: string = '';
      const ASynchronize: Boolean = True);
{$endif}

    class function GetStream(const AEngineURL, AAppName, AResourceName: string;
      const AToken: string = ''): TStream; overload;

    class function GetStream(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AToken: string = ''): TStream; overload;

    class function PostStream(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AContent: TStream; const AToken: string = ''): Boolean;
  published
    property SkuchainEngineURL: string read FSkuchainEngineURL write FSkuchainEngineURL;
    property ConnectTimeout: Integer read GetConnectTimeout write SetConnectTimeout;
    property ReadTimeout: Integer read GetReadTimeout write SetReadTimeout;
    property OnError: TSkuchainClientErrorEvent read FOnError write FOnError;
    property AuthEndorsement: TSkuchainAuthEndorsement read FAuthEndorsement write SetAuthEndorsement default TSkuchainAuthEndorsement.Cookie;
  end;

function TSkuchainHttpVerbToString(const AVerb: TSkuchainHttpVerb): string;

implementation

uses
    Rtti, TypInfo
  , Skuchain.Client.CustomResource
  , Skuchain.Client.Resource
  , Skuchain.Client.Resource.JSON
  , Skuchain.Client.Resource.Stream
  , Skuchain.Client.Application
;

function TSkuchainHttpVerbToString(const AVerb: TSkuchainHttpVerb): string;
begin
{$ifdef DelphiXE7_UP}
  Result := TRttiEnumerationType.GetName<TSkuchainHttpVerb>(AVerb);
{$else}
  Result := GetEnumName(TypeInfo(TSkuchainHttpVerb), Integer(AVerb));
{$endif}
end;

{ TSkuchainCustomClient }

procedure TSkuchainCustomClient.AssignTo(Dest: TPersistent);
var
  LDestClient: TSkuchainCustomClient;
begin
//  inherited;
  LDestClient := Dest as TSkuchainCustomClient;

  if Assigned(LDestClient) then
  begin
    LDestClient.AuthEndorsement := AuthEndorsement;
    LDestClient.SkuchainEngineURL := SkuchainEngineURL;
    LDestClient.ConnectTimeout := ConnectTimeout;
    LDestClient.ReadTimeout := ReadTimeout;
    LDestClient.OnError := OnError;
  end;
end;

procedure TSkuchainCustomClient.AuthEndorsementChanged;
begin

end;

constructor TSkuchainCustomClient.Create(AOwner: TComponent);
begin
  inherited;
  FAuthEndorsement := Cookie;
  FSkuchainEngineURL := 'http://localhost:8080/rest';
end;


procedure TSkuchainCustomClient.Delete(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  EndorseAuthorization(AAuthToken);
end;

procedure TSkuchainCustomClient.DoError(const AResource: TObject;
  const AException: Exception; const AVerb: TSkuchainHttpVerb;
  const AAfterExecute: TSkuchainClientResponseProc);
var
  LHandled: Boolean;
begin
  LHandled := False;

  if Assigned(FOnError) then
    FOnError(AResource, AException, AVerb, AAfterExecute, LHandled);

  if not LHandled then
    raise ESkuchainClientException.Create(AException.Message)
end;

procedure TSkuchainCustomClient.EndorseAuthorization(const AAuthToken: string);
begin

end;

procedure TSkuchainCustomClient.Get(const AURL: string; AResponseContent: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  EndorseAuthorization(AAuthToken);
end;

function TSkuchainCustomClient.GetConnectTimeout: Integer;
begin
  Result := -1;
end;

function TSkuchainCustomClient.GetReadTimeout: Integer;
begin
  Result := -1;
end;

//function TSkuchainCustomClient.GetRequest: TIdHTTPRequest;
//begin
//  Result := FHttpClient.Request;
//end;

//function TSkuchainCustomClient.GetResponse: TIdHTTPResponse;
//begin
//  Result := FHttpClient.Response;
//end;

function TSkuchainCustomClient.LastCmdSuccess: Boolean;
begin
  Result := False;
end;

procedure TSkuchainCustomClient.Post(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  EndorseAuthorization(AAuthToken);
end;

procedure TSkuchainCustomClient.Put(const AURL: string; AContent, AResponse: TStream;
  const AAuthToken: string; const AAccept: string; const AContentType: string);
begin
  EndorseAuthorization(AAuthToken);
end;

function TSkuchainCustomClient.ResponseStatusCode: Integer;
begin
  Result := -1;
end;

function TSkuchainCustomClient.ResponseText: string;
begin
  Result := '';
end;

procedure TSkuchainCustomClient.SetAuthEndorsement(
  const Value: TSkuchainAuthEndorsement);
begin
  if FAuthEndorsement <> Value then
  begin
    FAuthEndorsement := Value;
    AuthEndorsementChanged;
  end;
end;

procedure TSkuchainCustomClient.SetConnectTimeout(const Value: Integer);
begin

end;

procedure TSkuchainCustomClient.SetReadTimeout(const Value: Integer);
begin

end;

class function TSkuchainCustomClient.GetAsString(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AToken: string): string;
var
  LClient: TSkuchainCustomClient;
  LResource: TSkuchainClientResource;
  LApp: TSkuchainClientApplication;
  LIndex: Integer;
  LFinalURL: string;
begin
  LClient := Create(nil);
  try
    LClient.AuthEndorsement := AuthorizationBearer;
    LClient.SkuchainEngineURL := AEngineURL;
    LApp := TSkuchainClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TSkuchainClientResource.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LFinalURL := LResource.URL;
        LResource.SpecificToken := AToken;
        Result := LResource.GETAsString();
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;

class function TSkuchainCustomClient.GetJSON<T>(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AToken: string; const AIgnoreResult: Boolean): T;
var
  LClient: TSkuchainCustomClient;
  LResource: TSkuchainClientResourceJSON;
  LApp: TSkuchainClientApplication;
  LIndex: Integer;
  LFinalURL: string;
begin
  Result := nil;
  LClient := Create(nil);
  try
    LClient.AuthEndorsement := AuthorizationBearer;
    LClient.SkuchainEngineURL := AEngineURL;
    LApp := TSkuchainClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TSkuchainClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LFinalURL := LResource.URL;
        LResource.SpecificToken := AToken;
        LResource.GET(nil, nil, nil);

        Result := nil;
        if not AIgnoreResult then
          Result := LResource.Response.Clone as T;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;

{$ifdef DelphiXE7_UP}
class procedure TSkuchainCustomClient.GetJSONAsync<T>(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const ACompletionHandler: TProc<T>;
  const AOnException: TSkuchainClientExecptionProc; const AToken: string;
  const ASynchronize: Boolean);
var
  LClient: TSkuchainCustomClient;
  LResource: TSkuchainClientResourceJSON;
  LApp: TSkuchainClientApplication;
  LIndex: Integer;
  LFinalURL: string;
begin
  LClient := Create(nil);
  try
    LClient.AuthEndorsement := AuthorizationBearer;
    LClient.SkuchainEngineURL := AEngineURL;
    LApp := TSkuchainClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TSkuchainClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LFinalURL := LResource.URL;
        LResource.SpecificToken := AToken;
        LResource.GETAsync(
          procedure (AResource: TSkuchainClientCustomResource)
          begin
            try
              if Assigned(ACompletionHandler) then
                ACompletionHandler((AResource as TSkuchainClientResourceJSON).Response as T);
            finally
              LResource.Free;
              LApp.Free;
              LClient.Free;
            end;
          end
        , AOnException
        , ASynchronize
        );
        except
          LResource.Free;
          raise;
        end;
      except
        LApp.Free;
        raise;
      end;
    except
      LClient.Free;
      raise;
    end;
end;
{$endif}

class function TSkuchainCustomClient.GetStream(const AEngineURL, AAppName,
  AResourceName: string; const AToken: string): TStream;
begin
  Result := GetStream(AEngineURL, AAppName, AResourceName, nil, nil, AToken);
end;

class function TSkuchainCustomClient.GetJSON<T>(const AEngineURL, AAppName,
  AResourceName: string; const AToken: string): T;
begin
  Result := GetJSON<T>(AEngineURL, AAppName, AResourceName, nil, nil, AToken);
end;

class function TSkuchainCustomClient.GetStream(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AToken: string): TStream;
var
  LClient: TSkuchainCustomClient;
  LResource: TSkuchainClientResourceStream;
  LApp: TSkuchainClientApplication;
  LIndex: Integer;
begin
  LClient := Create(nil);
  try
    LClient.AuthEndorsement := AuthorizationBearer;
    LClient.SkuchainEngineURL := AEngineURL;
    LApp := TSkuchainClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TSkuchainClientResourceStream.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.GET(nil, nil, nil);

        Result := TMemoryStream.Create;
        try
          Result.CopyFrom(LResource.Response, LResource.Response.Size);
        except
          Result.Free;
          raise;
        end;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;

procedure TSkuchainCustomClient.Post(const AURL: string;
  const AFormData: TArray<TFormParam>; const AResponse: TStream;
  const AAuthToken, AAccept: string; const AContentType: string);
begin
  EndorseAuthorization(AAuthToken);
end;

class function TSkuchainCustomClient.PostJSON(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>; const AQueryParams: TStrings;
  const AContent: TJSONValue; const ACompletionHandler: TProc<TJSONValue>; const AToken: string
): Boolean;
var
  LClient: TSkuchainCustomClient;
  LResource: TSkuchainClientResourceJSON;
  LApp: TSkuchainClientApplication;
  LIndex: Integer;
begin
  LClient := Create(nil);
  try
    LClient.AuthEndorsement := AuthorizationBearer;
    LClient.SkuchainEngineURL := AEngineURL;
    LApp := TSkuchainClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TSkuchainClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.POST(
          procedure (AStream: TMemoryStream)
          var
            LWriter: TStreamWriter;
          begin
            if Assigned(AContent) then
            begin
              LWriter := TStreamWriter.Create(AStream);
              try
                LWriter.Write(AContent.ToJSON);
              finally
                LWriter.Free;
              end;
            end;
          end
        , procedure (AStream: TStream)
          begin
            if Assigned(ACompletionHandler) then
              ACompletionHandler(LResource.Response);
          end
        , nil
        );
        Result := LClient.LastCmdSuccess;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;


{$ifdef DelphiXE7_UP}
class procedure TSkuchainCustomClient.PostJSONAsync(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AContent: TJSONValue;
  const ACompletionHandler: TProc<TJSONValue>;
  const AOnException: TSkuchainClientExecptionProc;
  const AToken: string;
  const ASynchronize: Boolean);
var
  LClient: TSkuchainCustomClient;
  LResource: TSkuchainClientResourceJSON;
  LApp: TSkuchainClientApplication;
  LIndex: Integer;
begin
  LClient := Create(nil);
  try
    LClient.AuthEndorsement := AuthorizationBearer;
    LClient.SkuchainEngineURL := AEngineURL;
    LApp := TSkuchainClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TSkuchainClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.POSTAsync(
          procedure (AStream: TMemoryStream)
          var
            LWriter: TStreamWriter;
          begin
            if Assigned(AContent) then
            begin
              LWriter := TStreamWriter.Create(AStream);
              try
                LWriter.Write(AContent.ToJSON);
              finally
                LWriter.Free;
              end;
            end;
          end
        , procedure (AResource: TSkuchainClientCustomResource)
          begin
            try
              if Assigned(ACompletionHandler) then
                ACompletionHandler((AResource as TSkuchainClientResourceJSON).Response);
            finally
              LResource.Free;
              LApp.Free;
              LClient.Free;
            end;
          end
        , AOnException
        , ASynchronize
        );
      except
        LResource.Free;
        raise;
      end;
    except
      LApp.Free;
      raise;
    end;
  except
    LClient.Free;
    raise;
  end;
end;
{$endif}

class function TSkuchainCustomClient.PostStream(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AContent: TStream; const AToken: string
): Boolean;
var
  LClient: TSkuchainCustomClient;
  LResource: TSkuchainClientResourceStream;
  LApp: TSkuchainClientApplication;
  LIndex: Integer;
begin
  LClient := Create(nil);
  try
    LClient.AuthEndorsement := AuthorizationBearer;
    LClient.SkuchainEngineURL := AEngineURL;
    LApp := TSkuchainClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TSkuchainClientResourceStream.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.POST(
          procedure (AStream: TMemoryStream)
          begin
            if Assigned(AContent) then
            begin
              AStream.Size := 0; // reset
              AContent.Position := 0;
              AStream.CopyFrom(AContent, AContent.Size);
            end;
          end
        , nil, nil
        );
        Result := LClient.LastCmdSuccess;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;


procedure TSkuchainCustomClient.Put(const AURL: string;
  const AFormData: TArray<TFormParam>; const AResponse: TStream;
  const AAuthToken, AAccept: string; const AContentType: string);
begin
  EndorseAuthorization(AAuthToken);
end;

end.
