(*
  Copyright 2016, Skuchain-Curiosity - REST Library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Utils.ReqRespLogger.CodeSite;

interface

uses
  Classes, SysUtils, Diagnostics, Rtti
  , Skuchain.Core.Classes
  , Skuchain.Core.Activation
  , Skuchain.Core.Activation.Interfaces, Skuchain.Utils.ReqRespLogger.Interfaces
  , Web.HttpApp
;

type
  TSkuchainReqRespLoggerCodeSite=class(TInterfacedObject, ISkuchainReqRespLogger)
  private
    class var _Instance: TSkuchainReqRespLoggerCodeSite;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    // ISkuchainReqRespLogger
    procedure Clear;
    function GetLogBuffer: TValue;
    procedure Log(const AMessage: string);

    class function Instance: TSkuchainReqRespLoggerCodeSite;
    class constructor ClassCreate;
    class destructor ClassDestroy;
  end;

  TWebRequestHelper = class helper for TWebRequest
  public
    function ToLogString: string;
  end;

  TWebResponseHelper = class helper for TWebResponse
  public
    function ToLogString: string;
  end;

implementation

uses
  CodeSiteLogging
;

const
  LOGFIELD_SEPARATOR = ' | ';

{ TSkuchainReqRespLoggerCodeSite }

class constructor TSkuchainReqRespLoggerCodeSite.ClassCreate;
begin
  TSkuchainActivation.RegisterBeforeInvoke(
    procedure (const AR: ISkuchainActivation; out AIsAllowed: Boolean)
    begin
      TSkuchainReqRespLoggerCodeSite.Instance.Log(
        string.Join(LOGFIELD_SEPARATOR
        , [
           'Incoming'
          , AR.Request.ToLogString
          , 'Engine: ' + AR.Engine.Name
          , 'Application: ' + AR.Application.Name
          ]
        )
      );
    end
  );

  TSkuchainActivation.RegisterAfterInvoke(
    procedure (const AR: ISkuchainActivation)
    begin
      TSkuchainReqRespLoggerCodeSite.Instance.Log(
        string.Join(LOGFIELD_SEPARATOR
        , [
            'Outgoing'
          , AR.Response.ToLogString
          , 'Time: ' + AR.InvocationTime.ElapsedMilliseconds.ToString + ' ms'
          , 'Engine: ' + AR.Engine.Name
          , 'Application: ' + AR.Application.Name
          ]
        )
      );
    end
  );
end;

class destructor TSkuchainReqRespLoggerCodeSite.ClassDestroy;
begin
  if Assigned(_Instance) then
    FreeAndNil(_Instance);
end;

procedure TSkuchainReqRespLoggerCodeSite.Clear;
begin
  CodeSite.Clear;
end;

constructor TSkuchainReqRespLoggerCodeSite.Create;
begin
  inherited Create;
  CodeSite.SendMsg('Logger started');
end;

destructor TSkuchainReqRespLoggerCodeSite.Destroy;
begin
  CodeSite.SendMsg('Logger stopped');
  inherited;
end;

function TSkuchainReqRespLoggerCodeSite.GetLogBuffer: TValue;
begin
  Result := TValue.Empty;
end;

class function TSkuchainReqRespLoggerCodeSite.Instance: TSkuchainReqRespLoggerCodeSite;
begin
  if not Assigned(_Instance) then
    _Instance := TSkuchainReqRespLoggerCodeSite.Create;
  Result := _Instance;
end;

procedure TSkuchainReqRespLoggerCodeSite.Log(const AMessage: string);
begin
  CodeSite.SendMsg(AMessage);
end;

{ TWebRequestHelper }

function TWebRequestHelper.ToLogString: string;
begin
  Result := string.Join(LOGFIELD_SEPARATOR
  , [
        Method
      , PathInfo
      , 'Content: [' + Content + ']'
      , 'Cookie: ['  + CookieFields.Text  + ']'
      , 'Query: ['   + QueryFields.Text   + ']'
      , 'Length: '  + Length(Content).ToString
      , 'RemoteIP: ' + RemoteIP
      , 'RemoteAddress: ' + RemoteAddr
      , 'RemoteHost: ' + RemoteHost
    ]
  );
end;

{ TWebResponseHelper }

function TWebResponseHelper.ToLogString: string;
var
  LContentSize: Int64;
begin
  if Assigned(ContentStream) then
    LContentSize := ContentStream.Size
  else
    LContentSize := 0;


  Result := string.Join(LOGFIELD_SEPARATOR
    , [
        HTTPRequest.Method
      , HTTPRequest.PathInfo
      , 'StatusCode: ' + StatusCode.ToString
      , 'ReasonString: ' + ReasonString
      , 'ContentType: ' + ContentType
      , 'Content.Size: ' + LContentSize.ToString
      , 'Content: [' + Content + ']'
      , 'Cookies.Count: '  + Cookies.Count.ToString
    ]
  );
end;

end.
