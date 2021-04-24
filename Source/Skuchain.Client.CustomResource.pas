(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.CustomResource;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes

  , Skuchain.Client.Application
  , Skuchain.Client.Client
  , Skuchain.Client.Utils
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
  TSkuchainClientCustomResource = class(TComponent)
  private
    FResource: string;
    FApplication: TSkuchainClientApplication;
    FSpecificClient: TSkuchainCustomClient;
    FSpecificToken: string;
    FPathParamsValues: TStrings;
    FQueryParams: TStrings;
    FSpecificAccept: string;
    FSpecificContentType: string;
    FToken: TSkuchainClientCustomResource;
    procedure SetPathParamsValues(const Value: TStrings);
    procedure SetQueryParams(const Value: TStrings);
  protected
    function GetClient: TSkuchainCustomClient; virtual;
    function GetPath: string; virtual;
    function GetURL: string; virtual;
    function GetApplication: TSkuchainClientApplication; virtual;
    function GetAccept: string; virtual;
    function GetContentType: string; virtual;
    function GetAuthToken: string; virtual;

    procedure BeforeGET; virtual;
    procedure AfterGET(const AContent: TStream); virtual;

    procedure BeforePOST(const AContent: TMemoryStream); virtual;
    procedure AfterPOST(const AContent: TStream); virtual;

    procedure BeforePUT(const AContent: TMemoryStream); virtual;
    procedure AfterPUT(const AContent: TStream); virtual;

    procedure BeforeDELETE(const AContent: TMemoryStream); virtual;
    procedure AfterDELETE(const AContent: TStream); virtual;

    procedure DoError(const AException: Exception; const AVerb: TSkuchainHttpVerb; const AAfterExecute: TSkuchainClientResponseProc); virtual;
    procedure AssignTo(Dest: TPersistent); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // http verbs
    procedure GET(const ABeforeExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;
    {$ifndef DelphiXE2_UP}
    function GETAsString: string; overload;
    {$endif}
    function GETAsString(AEncoding: TEncoding {$ifdef DelphiXE2_UP} = nil{$endif};
      const ABeforeExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}): string; {$ifndef DelphiXE2_UP}overload;{$endif} virtual;
    procedure POST(const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload; virtual;
    procedure PUT(const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload; virtual;
    procedure DELETE(const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload; virtual;
//    procedure PATCH(const ABeforeExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
//      const AAfterExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
//      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;
//    procedure HEAD(const ABeforeExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
//      const AAfterExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
//      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;
//    procedure OPTIONS(const ABeforeExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
//      const AAfterExecute: TSkuchainClientProc{$ifdef DelphiXE2_UP} = nil{$endif};
//      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;

{$ifdef DelphiXE7_UP}
    procedure GETAsync(const ACompletionHandler: TProc<TSkuchainClientCustomResource>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const ASynchronize: Boolean = True); overload;
    procedure POSTAsync(
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const ACompletionHandler: TProc<TSkuchainClientCustomResource>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const ASynchronize: Boolean = True); overload;
    procedure PUTAsync(
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const ACompletionHandler: TProc<TSkuchainClientCustomResource>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const ASynchronize: Boolean = True); overload;
{$endif}

    property Accept: string read GetAccept;
    property ContentType: string read GetContentType;
    property Application: TSkuchainClientApplication read GetApplication write FApplication;
    property AuthToken: string read GetAuthToken;
    property Client: TSkuchainCustomClient read GetClient;
    property SpecificAccept: string read FSpecificAccept write FSpecificAccept;
    property SpecificClient: TSkuchainCustomClient read FSpecificClient write FSpecificClient;
    property SpecificContentType: string read FSpecificContentType write FSpecificContentType;
    property SpecificToken: string read FSpecificToken write FSpecificToken;
    property Resource: string read FResource write FResource;
    property Path: string read GetPath;
    property PathParamsValues: TStrings read FPathParamsValues write SetPathParamsValues;
    property QueryParams: TStrings read FQueryParams write SetQueryParams;
    property Token: TSkuchainClientCustomResource read FToken write FToken;
    property URL: string read GetURL;
  published
  end;

  TSkuchainClientCustomResourceClass = class of TSkuchainClientCustomResource;


implementation

uses
  {$ifdef DelphiXE7_UP}System.Threading,{$endif}
   Skuchain.Core.URL, Skuchain.Core.Utils, Skuchain.Client.Token
 , Skuchain.Client.Resource, Skuchain.Client.SubResource
 , Skuchain.Core.MediaType
;

{ TSkuchainClientCustomResource }

procedure TSkuchainClientCustomResource.AfterDELETE;
begin

end;

procedure TSkuchainClientCustomResource.AfterGET(const AContent: TStream);
begin

end;

procedure TSkuchainClientCustomResource.AfterPOST(const AContent: TStream);
begin

end;

procedure TSkuchainClientCustomResource.AfterPUT(const AContent: TStream);
begin

end;

procedure TSkuchainClientCustomResource.AssignTo(Dest: TPersistent);
var
  LDestResource: TSkuchainClientCustomResource;
begin
//  inherited;
  LDestResource := Dest as TSkuchainClientCustomResource;
  LDestResource.Application := Application;

  LDestResource.SpecificAccept := SpecificAccept;
  LDestResource.SpecificContentType := SpecificContentType;
  LDestResource.SpecificClient := SpecificClient;
  LDestResource.SpecificToken := SpecificToken;
  LDestResource.Resource := Resource;
  LDestResource.PathParamsValues.Assign(PathParamsValues);
  LDestResource.QueryParams.Assign(QueryParams);
  LDestResource.Token := Token;
end;

procedure TSkuchainClientCustomResource.BeforeDELETE(const AContent: TMemoryStream);
begin

end;

procedure TSkuchainClientCustomResource.BeforeGET;
begin

end;

procedure TSkuchainClientCustomResource.BeforePOST(const AContent: TMemoryStream);
begin

end;

procedure TSkuchainClientCustomResource.BeforePUT(const AContent: TMemoryStream);
begin

end;

constructor TSkuchainClientCustomResource.Create(AOwner: TComponent);
begin
  inherited;
  FResource := 'main';
  if TSkuchainComponentHelper.IsDesigning(Self) then
  begin
    FApplication := TSkuchainComponentHelper.FindDefault<TSkuchainClientApplication>(Self);
    FToken := TSkuchainComponentHelper.FindDefault<TSkuchainClientToken>(Self);
  end;
  FPathParamsValues := TStringList.Create;
  FQueryParams := TStringList.Create;
  FSpecificAccept := TMediaType.WILDCARD;
  FSpecificContentType := '';
end;

function TSkuchainClientCustomResource.GetAuthToken: string;
begin
  Result := SpecificToken;
  if (Result = '') and Assigned(Token) then
    Result := (Token as TSkuchainClientToken).Token;
end;

function TSkuchainClientCustomResource.GetClient: TSkuchainCustomClient;
begin
  Result := nil;
  if Assigned(FSpecificClient) then
    Result := FSpecificClient
  else
  begin
    if Assigned(FApplication) then
      Result := FApplication.Client;
  end;
end;

function TSkuchainClientCustomResource.GetContentType: string;
begin
  Result := FSpecificContentType;
  if (Result = '') and Assigned(Application) then
    Result := Application.DefaultContentType;
end;

function TSkuchainClientCustomResource.GetPath: string;
var
  LEngine: string;
  LApplication: string;
begin
  LEngine := '';
  if Assigned(Client) then
    LEngine := Client.SkuchainEngineURL;

  LApplication := '';
  if Assigned(Application) then
    LApplication := Application.AppName;


  Result := TSkuchainURL.CombinePath([LEngine, LApplication, Resource]);
end;


function TSkuchainClientCustomResource.GetURL: string;
begin
  Result := TSkuchainURL.CombinePath([
    Path
    , TSkuchainURL.CombinePath(TSkuchainURL.URLEncode(FPathParamsValues.ToStringArray))
  ]);

  if FQueryParams.Count > 0 then
    Result := Result + '?' + SmartConcat(TSkuchainURL.URLEncode(FQueryParams.ToStringArray), '&');
end;

procedure TSkuchainClientCustomResource.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) then
  begin
    if SpecificClient = AComponent then
      SpecificClient := nil;
    if Token = AComponent then
      Token := nil;
    if Application = AComponent then
      Application := nil;
  end;

end;

procedure TSkuchainClientCustomResource.DELETE(const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc; const AOnException: TSkuchainClientExecptionProc);
var
  LResponseStream: TMemoryStream;
  LContent: TMemoryStream;
begin
  try
    LContent := TMemoryStream.Create;
    try
      BeforeDELETE(LContent);

      if Assigned(ABeforeExecute) then
        ABeforeExecute(LContent);

      LResponseStream := TMemoryStream.Create;
      try
        Client.Delete(URL, LContent, LResponseStream, AuthToken, Accept, ContentType);

        AfterDELETE(LResponseStream);

        if Assigned(AAfterExecute) then
          AAfterExecute(LResponseStream);
      finally
        LResponseStream.Free;
      end;
    finally
      LContent.Free;
    end;
  except
    on E:Exception do
    begin
      if Assigned(AOnException) then
        AOnException(E)
      else
        DoError(E, TSkuchainHttpVerb.Delete
          , procedure (AStream: TStream)
            begin
              if Assigned(AAfterExecute) then
                AAfterExecute(AStream);
            end);
    end;
  end;
end;

destructor TSkuchainClientCustomResource.Destroy;
begin
  FQueryParams.Free;
  FPathParamsValues.Free;
  inherited;
end;

procedure TSkuchainClientCustomResource.DoError(const AException: Exception;
  const AVerb: TSkuchainHttpVerb; const AAfterExecute: TSkuchainClientResponseProc);
begin
  if Assigned(Application) then
    Application.DoError(Self, AException, AVerb, AAfterExecute)
  else if Assigned(Client) then
    Client.DoError(Self, AException, AVerb, AAfterExecute)
  else
    raise ESkuchainClientException.Create(AException.Message);
end;

procedure TSkuchainClientCustomResource.GET(const ABeforeExecute: TSkuchainCLientProc;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
var
  LResponseStream: TMemoryStream;
begin
  try
    BeforeGET();

    if Assigned(ABeforeExecute) then
      ABeforeExecute();

    LResponseStream := TMemoryStream.Create;
    try
      Client.Get(URL, LResponseStream, AuthToken, Accept, ContentType);

      AfterGET(LResponseStream);

      if Assigned(AAfterExecute) then
        AAfterExecute(LResponseStream);
    finally
      LResponseStream.Free;
    end;
  except
    on E:Exception do
    begin
      if Assigned(AOnException) then
        AOnException(E)
      else
        DoError(E, TSkuchainHttpVerb.Get, AAfterExecute);
    end;
  end;
end;

{$ifndef DelphiXE2_UP}
function TSkuchainClientCustomResource.GETAsString: string;
begin
  Result := GetAsString(nil, nil, nil);
end;
{$endif}

function TSkuchainClientCustomResource.GETAsString(AEncoding: TEncoding;
  const ABeforeExecute: TSkuchainClientProc;
  const AOnException: TSkuchainClientExecptionProc): string;
var
  LResult: string;
  LEncoding: TEncoding;
begin
  LResult := '';
  LEncoding := AEncoding;
  if not Assigned(LEncoding) then
    LEncoding := TEncoding.Default;

  GET(ABeforeExecute
    , procedure (AResponse: TStream)
      var
        LStreamReader: TStreamReader;
      begin
        AResponse.Position := 0;
        LStreamReader := TStreamReader.Create(AResponse, LEncoding);
        try
          LResult := LStreamReader.ReadToEnd;
        finally
          LStreamReader.Free;
        end;
      end
    , AOnException
  );
  Result := LResult;
end;

function TSkuchainClientCustomResource.GetAccept: string;
begin
  Result := FSpecificAccept;
  if (Result = '') and Assigned(Application) then
    Result := Application.DefaultMediaType;
end;

function TSkuchainClientCustomResource.GetApplication: TSkuchainClientApplication;
begin
  Result := FApplication;
end;

{$ifdef DelphiXE7_UP}
procedure TSkuchainClientCustomResource.GETAsync(
  const ACompletionHandler: TProc<TSkuchainClientCustomResource>;
  const AOnException: TSkuchainClientExecptionProc;
  const ASynchronize: Boolean);
var
  LClient: TSkuchainCustomClient;
  LApplication: TSkuchainClientApplication;
  LResource, LParentResource: TSkuchainClientCustomResource;
begin
  LClient := TSkuchainCustomClientClass(Client.ClassType).Create(nil);
  try
    LClient.Assign(Client);
    LApplication := TSkuchainClientApplication.Create(nil);
    try
      LApplication.Assign(Application);
      LApplication.Client := LClient;
      LResource := TSkuchainClientCustomResourceClass(ClassType).Create(nil);
      try
        LResource.Assign(Self);
        LResource.SpecificClient := nil;
        LResource.Application := LApplication;

        LParentResource := nil;
        if Self is TSkuchainClientSubResource then
        begin
          LParentResource := TSkuchainClientCustomResourceClass(TSkuchainClientSubResource(Self).ParentResource.ClassType).Create(nil);
          try
            LParentResource.Assign(TSkuchainClientSubResource(Self).ParentResource);
            LParentResource.SpecificClient := nil;
            LParentResource.Application := LApplication;
            (LResource as TSkuchainClientSubResource).ParentResource := LParentResource as TSkuchainClientResource;
          except
            LParentResource.Free;
            raise;
          end;
        end;

        TTask.Run(
          procedure
          var
            LOnException: TProc<Exception>;
          begin
            try
              if Assigned(AOnException) then
              begin
                LOnException :=
                  procedure (AException: Exception)
                  begin
                    if ASynchronize then
                      TThread.Synchronize(nil
                        , procedure
                          begin
                            AOnException(AException);
                          end
                      )
                    else
                      AOnException(AException);
                  end;
              end
              else
                LOnException := nil;

              LResource.GET(nil
                , procedure (AStream: TStream)
                  begin
                    if Assigned(ACompletionHandler) then
                    begin
                      if ASynchronize then
                        TThread.Synchronize(nil
                          , procedure
                            begin
                              ACompletionHandler(LResource);
                            end
                        )
                      else
                        ACompletionHandler(LResource);
                    end;
                  end
                , LOnException
                );
              finally
                LResource.Free;
                if Assigned(LParentResource) then
                  LParentResource.Free;
                LApplication.Free;
                LClient.Free;
              end;
          end
        );
      except
        LResource.Free;
        raise;
      end;
    except
      LApplication.Free;
      raise;
    end;
  except
    LClient.Free;
    raise;
  end;
end;
{$endif}

procedure TSkuchainClientCustomResource.POST(
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
var
  LResponseStream: TMemoryStream;
  LContent: TMemoryStream;
begin
  try
    LContent := TMemoryStream.Create;
    try
      BeforePOST(LContent);

      if Assigned(ABeforeExecute) then
        ABeforeExecute(LContent);

      LResponseStream := TMemoryStream.Create;
      try
        Client.Post(URL, LContent, LResponseStream, AuthToken, Accept, ContentType);

        AfterPOST(LResponseStream);

        if Assigned(AAfterExecute) then
          AAfterExecute(LResponseStream);
      finally
        LResponseStream.Free;
      end;
    finally
      LContent.Free;
    end;
  except
    on E:Exception do
    begin
      if Assigned(AOnException) then
        AOnException(E)
      else
        DoError(E, TSkuchainHttpVerb.Post, AAfterExecute);
    end;
  end;
end;

{$ifdef DelphiXE7_UP}
procedure TSkuchainClientCustomResource.POSTAsync(
  const ABeforeExecute: TProc<TMemoryStream>;
  const ACompletionHandler: TProc<TSkuchainClientCustomResource>;
  const AOnException: TSkuchainClientExecptionProc;
  const ASynchronize: Boolean);
var
  LClient: TSkuchainCustomClient;
  LApplication: TSkuchainClientApplication;
  LResource, LParentResource: TSkuchainClientCustomResource;
begin
  LClient := TSkuchainCustomClientClass(Client.ClassType).Create(nil);
  try
    LClient.Assign(Client);
    LApplication := TSkuchainClientApplication.Create(nil);
    try
      LApplication.Assign(Application);
      LApplication.Client := LClient;
      LResource := TSkuchainClientCustomResourceClass(ClassType).Create(nil);
      try
        LResource.Assign(Self);
        LResource.SpecificClient := nil;
        LResource.Application := LApplication;

        LParentResource := nil;
        if Self is TSkuchainClientSubResource then
        begin
          LParentResource := TSkuchainClientCustomResourceClass(TSkuchainClientSubResource(Self).ParentResource.ClassType).Create(nil);
          try
            LParentResource.Assign(TSkuchainClientSubResource(Self).ParentResource);
            LParentResource.SpecificClient := nil;
            LParentResource.Application := LApplication;
            (LResource as TSkuchainClientSubResource).ParentResource := LParentResource as TSkuchainClientResource;
          except
            LParentResource.Free;
            raise;
          end;
        end;

        TTask.Run(
          procedure
          var
            LOnException: TProc<Exception>;
          begin
            try
              if Assigned(AOnException) then
              begin
                LOnException :=
                  procedure (AException: Exception)
                  begin
                    if ASynchronize then
                      TThread.Synchronize(nil
                        , procedure
                          begin
                            AOnException(AException);
                          end
                      )
                    else
                      AOnException(AException);
                  end;
              end
              else
                LOnException := nil;

              LResource.POST(
                ABeforeExecute
              , procedure (AStream: TStream)
                begin
                  if Assigned(ACompletionHandler) then
                  begin
                    if ASynchronize then
                      TThread.Synchronize(nil
                        , procedure
                          begin
                            ACompletionHandler(LResource);
                          end
                      )
                    else
                      ACompletionHandler(LResource);
                  end;
                end
              , LOnException
              );
            finally
              LResource.Free;
              if Assigned(LParentResource) then
                LParentResource.Free;
              LApplication.Free;
              LClient.Free;
            end;
          end
        );
      except
        LResource.Free;
        raise;
      end;
    except
      LApplication.Free;
      raise;
    end;
  except
    LClient.Free;
    raise;
  end;
end;
{$endif}

procedure TSkuchainClientCustomResource.PUT(const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
  const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
  const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}
);
var
  LResponseStream: TMemoryStream;
  LContent: TMemoryStream;
begin
  try
    LContent := TMemoryStream.Create;
    try
      BeforePUT(LContent);

      if Assigned(ABeforeExecute) then
        ABeforeExecute(LContent);

      LResponseStream := TMemoryStream.Create;
      try
        Client.Put(URL, LContent, LResponseStream, AuthToken, Accept, ContentType);

        AfterPUT(LResponseStream);

        if Assigned(AAfterExecute) then
          AAfterExecute(LResponseStream);
      finally
        LResponseStream.Free;
      end;
    finally
      LContent.Free;
    end;
  except
    on E:Exception do
    begin
      if Assigned(AOnException) then
        AOnException(E)
      else
        DoError(E, TSkuchainHttpVerb.Put, AAfterExecute);
    end;
  end;
end;

{$ifdef DelphiXE7_UP}
procedure TSkuchainClientCustomResource.PUTAsync(
  const ABeforeExecute: TProc<TMemoryStream>;
  const ACompletionHandler: TProc<TSkuchainClientCustomResource>;
  const AOnException: TSkuchainClientExecptionProc;
  const ASynchronize: Boolean);
var
  LClient: TSkuchainCustomClient;
  LApplication: TSkuchainClientApplication;
  LResource, LParentResource: TSkuchainClientCustomResource;
begin
  LClient := TSkuchainCustomClientClass(Client.ClassType).Create(nil);
  try
    LClient.Assign(Client);
    LApplication := TSkuchainClientApplication.Create(nil);
    try
      LApplication.Assign(Application);
      LApplication.Client := LClient;
      LResource := TSkuchainClientCustomResourceClass(ClassType).Create(nil);
      try
        LResource.Assign(Self);
        LResource.SpecificClient := nil;
        LResource.Application := LApplication;

        LParentResource := nil;
        if Self is TSkuchainClientSubResource then
        begin
          LParentResource := TSkuchainClientCustomResourceClass(TSkuchainClientSubResource(Self).ParentResource.ClassType).Create(nil);
          try
            LParentResource.Assign(TSkuchainClientSubResource(Self).ParentResource);
            LParentResource.SpecificClient := nil;
            LParentResource.Application := LApplication;
            (LResource as TSkuchainClientSubResource).ParentResource := LParentResource as TSkuchainClientResource;
          except
            LParentResource.Free;
            raise;
          end;
        end;

        TTask.Run(
          procedure
          var
            LOnException: TProc<Exception>;
          begin
            try
              if Assigned(AOnException) then
              begin
                LOnException :=
                  procedure (AException: Exception)
                  begin
                    if ASynchronize then
                      TThread.Synchronize(nil
                        , procedure
                          begin
                            AOnException(AException);
                          end
                      )
                    else
                      AOnException(AException);
                  end;
              end
              else
                LOnException := nil;

              LResource.PUT(
                ABeforeExecute
              , procedure (AStream: TStream)
                begin
                  if Assigned(ACompletionHandler) then
                  begin
                    if ASynchronize then
                      TThread.Synchronize(nil
                        , procedure
                          begin
                            ACompletionHandler(LResource);
                          end
                      )
                    else
                      ACompletionHandler(LResource);
                  end;
                end
              , LOnException
              );
            finally
              LResource.Free;
              if Assigned(LParentResource) then
                LParentResource.Free;
              LApplication.Free;
              LClient.Free;
            end;
          end
        );
      except
        LResource.Free;
        raise;
      end;
    except
      LApplication.Free;
      raise;
    end;
  except
    LClient.Free;
    raise;
  end;
end;
{$endif}

procedure TSkuchainClientCustomResource.SetPathParamsValues(const Value: TStrings);
begin
  FPathParamsValues.Assign(Value);
end;

procedure TSkuchainClientCustomResource.SetQueryParams(const Value: TStrings);
begin
  FQueryParams.Assign(Value);
end;

end.
