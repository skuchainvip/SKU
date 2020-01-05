(*
  Copyright 2016, Skuchain-Curiosity - REST Library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Utils.ReqRespLogger.Memory;

interface

uses
  Classes, SysUtils, Diagnostics
  , Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.Comp.DataSet
//  , Skuchain.Core.Engine, Skuchain.Core.Application
  , Skuchain.Utils.ReqRespLogger.Interfaces
  , Web.HttpApp, SyncObjs, Rtti
  , Skuchain.Core.Activation
  , Skuchain.Core.Activation.Interfaces
;

type
  TSkuchainReqRespLoggerMemory=class(TInterfacedObject, ISkuchainReqRespLogger)
  private
    FMemory: TFDMemTable;
    FCriticalSection: TCriticalSection;
    class var _Instance: TSkuchainReqRespLoggerMemory;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    // ISkuchainReqRespLogger
    procedure Clear;
    function GetLogBuffer: TValue;
    procedure LogIncoming(const AR: ISkuchainActivation);
    procedure LogOutgoing(const AR: ISkuchainActivation);

    // protected access to FMemory from outside
    procedure ReadMemory(const AProc: TProc<TDataset>);
    function GetMemorySnapshot: TDataset;

    class function Instance: TSkuchainReqRespLoggerMemory;
    class constructor ClassCreate;
    class destructor ClassDestroy;
  end;

  TWebRequestHelper = class helper for TWebRequest
  public
    procedure ToDataSet(const ADataSet: TDataSet);
  end;

  TWebResponseHelper = class helper for TWebResponse
  public
    procedure ToDataSet(const ADataSet: TDataSet);
  end;


implementation

{ TSkuchainReqRespLoggerMemory }

class constructor TSkuchainReqRespLoggerMemory.ClassCreate;
begin
  TSkuchainActivation.RegisterBeforeInvoke(
    procedure (const AR: ISkuchainActivation; out AIsAllowed: Boolean)
    begin
      TSkuchainReqRespLoggerMemory.Instance.LogIncoming(AR);
    end
  );

  TSkuchainActivation.RegisterAfterInvoke(
    procedure (const AR: ISkuchainActivation)
    begin
      TSkuchainReqRespLoggerMemory.Instance.LogOutgoing(AR);
    end
  );
end;

class destructor TSkuchainReqRespLoggerMemory.ClassDestroy;
begin
  _Instance := nil;
end;

procedure TSkuchainReqRespLoggerMemory.Clear;
begin
  FCriticalSection.Enter;
  try
    FMemory.EmptyDataSet;
  finally
    FCriticalSection.Leave;
  end;
end;

constructor TSkuchainReqRespLoggerMemory.Create;
begin
  inherited Create;
  FCriticalSection := TCriticalSection.Create;

  FCriticalSection.Enter;
  try
    FMemory := TFDMemTable.Create(nil);
    try
      FMemory.FieldDefs.Add('TimeStamp', ftTimeStamp);
      FMemory.FieldDefs.Add('Engine', ftString, 255);
      FMemory.FieldDefs.Add('Application', ftString, 255);
      FMemory.FieldDefs.Add('Kind', ftString, 100);
      FMemory.FieldDefs.Add('Verb', ftString, 100);
      FMemory.FieldDefs.Add('Path', ftString, 2048); // 2K
      FMemory.FieldDefs.Add('StatusCode', ftInteger);
      FMemory.FieldDefs.Add('StatusText', ftString, 200);
      FMemory.FieldDefs.Add('ContentType', ftString, 200);
      FMemory.FieldDefs.Add('ContentSize', ftInteger);
      FMemory.FieldDefs.Add('CookieCount', ftInteger);
      FMemory.FieldDefs.Add('Cookie', ftMemo);
      FMemory.FieldDefs.Add('Content', ftMemo);
      FMemory.FieldDefs.Add('Query', ftMemo);
      FMemory.FieldDefs.Add('RemoteIP', ftString, 100);
      FMemory.FieldDefs.Add('RemoteAddr', ftString, 255);
      FMemory.FieldDefs.Add('RemoteHost', ftString, 255);
      FMemory.FieldDefs.Add('ExecutionTime', ftInteger);
      FMemory.CreateDataSet;
    except
      FMemory.Free;
      raise;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

destructor TSkuchainReqRespLoggerMemory.Destroy;
begin
  FCriticalSection.Enter;
  try
    FMemory.Free;
  finally
    FCriticalSection.Leave;
  end;
  FCriticalSection.Free;
  inherited;
end;

function TSkuchainReqRespLoggerMemory.GetLogBuffer: TValue;
begin
  Result := TValue.From<TDataSet>(GetMemorySnapshot);
end;

function TSkuchainReqRespLoggerMemory.GetMemorySnapshot: TDataset;
var
  LSnapshot: TFDMemTable;
begin
  LSnapshot := TFDMemTable.Create(nil);
  try
    ReadMemory(
      procedure (AMemory: TDataSet)
      begin
        LSnapShot.Data := (AMemory as TFDMemTable).Data;
      end
    );
    Result := LSnapshot;
  except
    LSnapshot.Free;
    raise;
  end;
end;

class function TSkuchainReqRespLoggerMemory.Instance: TSkuchainReqRespLoggerMemory;
begin
  if not Assigned(_Instance) then
    _Instance := TSkuchainReqRespLoggerMemory.Create;
  Result := _Instance;
end;

procedure TSkuchainReqRespLoggerMemory.LogIncoming(const AR: ISkuchainActivation);
begin
  FCriticalSection.Enter;
  try
    FMemory.Append;
    try
      FMemory.FieldByName('TimeStamp').AsDateTime := Now;
      FMemory.FieldByName('Engine').AsString := AR.Engine.Name;
      FMemory.FieldByName('Application').AsString := AR.Application.Name;
      FMemory.FieldByName('Kind').AsString := 'Incoming';
      AR.Request.ToDataSet(FMemory);
      FMemory.Post;
    except
      FMemory.Cancel;
      raise;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSkuchainReqRespLoggerMemory.LogOutgoing(const AR: ISkuchainActivation);
begin
  FCriticalSection.Enter;
  try
    FMemory.Append;
    try
      FMemory.FieldByName('TimeStamp').AsDateTime := Now;
      FMemory.FieldByName('Engine').AsString := AR.Engine.Name;
      FMemory.FieldByName('Application').AsString := AR.Application.Name;
      FMemory.FieldByName('Kind').AsString := 'Outgoing';
      FMemory.FieldByName('ExecutionTime').AsInteger := AR.InvocationTime.ElapsedMilliseconds;

      AR.Response.ToDataSet(FMemory);
      FMemory.Post;
    except
      FMemory.Cancel;
      raise;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TSkuchainReqRespLoggerMemory.ReadMemory(const AProc: TProc<TDataset>);
begin
  FCriticalSection.Enter;
  try
    if Assigned(AProc) then
      AProc(FMemory);
  finally
    FCriticalSection.Leave;
  end;
end;

{ TWebRequestHelper }

procedure TWebRequestHelper.ToDataSet(const ADataSet: TDataSet);
begin
  ADataSet.FieldByName('Verb').AsString := Method;
  ADataSet.FieldByName('Path').AsString := PathInfo;
  ADataSet.FieldByName('Query').AsString := QueryFields.Text;
  ADataSet.FieldByName('RemoteIP').AsString := RemoteIP;
  ADataSet.FieldByName('RemoteAddr').AsString := RemoteAddr;
  ADataSet.FieldByName('RemoteHost').AsString := RemoteHost;

  ADataSet.FieldByName('StatusCode').Clear;
  ADataSet.FieldByName('StatusText').Clear;

  try
    ADataSet.FieldByName('Content').AsString := Content;
  except on E: EEncodingError do
    ADataSet.FieldByName('Content').AsString := E.ToString;
  end;

  ADataSet.FieldByName('ContentType').AsString := ContentType;
  ADataSet.FieldByName('ContentSize').AsInteger := ContentLength;
  ADataSet.FieldByName('CookieCount').AsInteger := CookieFields.Count;
  ADataSet.FieldByName('Cookie').AsString := CookieFields.Text;
end;

{ TWebResponseHelper }

procedure TWebResponseHelper.ToDataSet(const ADataSet: TDataSet);
var
  LCookie: TCookie;
  LCookies: string;
  LCookieIndex: Integer;
  LContentString: string;
  LReader: TStreamReader;
begin
  HTTPRequest.ToDataSet(ADataSet);

  LContentString := '';
  if Assigned(ContentStream) then
  begin
    ADataSet.FieldByName('ContentSize').AsInteger := ContentStream.Size;

    ContentStream.Position := 0;
    LReader := TStreamReader.Create(ContentStream);
    try
      try
        LContentString := LReader.ReadToEnd;
      except on E:EEncodingError do
        LContentString := E.ToString;
      end;
      ContentStream.Position := 0;
    finally
      LReader.Free;
    end;
    ADataSet.FieldByName('Content').AsString := LContentString;
  end;

  ADataSet.FieldByName('StatusCode').AsInteger := StatusCode;
  ADataSet.FieldByName('StatusText').AsString := ReasonString;
  ADataSet.FieldByName('ContentType').AsString := ContentType;

  ADataSet.FieldByName('CookieCount').AsInteger := Cookies.Count;

  LCookies := '';
  for LCookieIndex := 0 to Cookies.Count-1 do
  begin
    LCookie := Cookies.Items[LCookieIndex];
    LCookies := LCookie.Name + '=' + LCookie.Value + sLineBreak;
  end;
  ADataSet.FieldByName('Cookie').AsString := LCookies;
end;

end.
