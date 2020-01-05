(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Messaging.Resource;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Core.JSON

{$ifdef DelphiXE7_UP}
  , System.Threading
  , System.JSON
{$endif}

  , Skuchain.Client.Resource.JSON
  , Skuchain.Client.SubResource.JSON
  ;

type
  TSkuchainMessageEvent = procedure (Sender: TObject; AMessage: TJSONObject) of object;

  TSkuchainClientMessagingResource = class(TSkuchainClientResourceJSON)
  private
{$ifdef DelphiXE7_UP}
    FWorkerTask: ITask;
{$endif}
    FListenSubRes: TSkuchainClientSubResourceJSON;
    FMyQueueSubRes: TSkuchainClientSubResourceJSON;
    FPollingInterval: Integer;
    FActive: Boolean;
    FOnMessage: TSkuchainMessageEvent;
    FSynchronizeEvents: Boolean;
    procedure SetPollingInterval(const Value: Integer);
    procedure SetActive(const Value: Boolean);
  protected
    procedure HandleMessage(AMessage: TJSONObject);
    procedure StartPolling;
    procedure StopPolling;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Active: Boolean read FActive write SetActive;
    property PollingInterval: Integer read FPollingInterval write SetPollingInterval;
    property SynchronizeEvents: Boolean read FSynchronizeEvents write FSynchronizeEvents;
    property OnMessage: TSkuchainMessageEvent read FOnMessage write FOnMessage;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientMessagingResource]);
end;

{ TSkuchainClientMessagingResource }

constructor TSkuchainClientMessagingResource.Create(AOwner: TComponent);
begin
  inherited;
  FListenSubRes := TSkuchainClientSubResourceJSON.Create(nil);
  FListenSubRes.ParentResource := Self;
  FListenSubRes.Resource := 'listen';

  FMyQueueSubRes := TSkuchainClientSubResourceJSON.Create(nil);
  FMyQueueSubRes.ParentResource := Self;
  FMyQueueSubRes.Resource := 'myqueue';

  FPollingInterval := 500;
  FActive := False;
end;

destructor TSkuchainClientMessagingResource.Destroy;
begin
  StopPolling;
  FListenSubRes.Free;
  FMyQueueSubRes.Free;
  inherited;
end;

procedure TSkuchainClientMessagingResource.HandleMessage(AMessage: TJSONObject);
begin
  if Assigned(FOnMessage) then
  begin
    if SynchronizeEvents then
      TThread.Queue(nil,
        procedure
        begin
          FOnMessage(Self, AMessage);
        end
      )
    else
      FOnMessage(Self, AMessage);
  end;
end;

procedure TSkuchainClientMessagingResource.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    if FActive then
      StartPolling
    else
      StopPolling;
  end;
end;

procedure TSkuchainClientMessagingResource.SetPollingInterval(const Value: Integer);
begin
  if FPollingInterval <> Value then
  begin
    FPollingInterval := Value;
    if Active then
    begin
      StopPolling;
      StartPolling;
    end;
  end;
end;

procedure TSkuchainClientMessagingResource.StartPolling;
begin
  if not ([csLoading, csReading] * ComponentState = []) then
    Exit;

{$ifdef DelphiXE7_UP}
  FWorkerTask := TTask.Create(
    procedure
    var
      LArray: TJSONArray;
      LElement: TJSONValue;
      LMessage: TJSONObject;
      LResponse: TJSONObject;
    begin
      FListenSubRes.GET;

      while TTask.CurrentTask.Status = TTaskStatus.Running do
      begin
        try
          FMyQueueSubRes.GET;

          LResponse := FMyQueueSubRes.Response as TJSONObject;
          LArray := LResponse.Get('Messages').JsonValue as TJSONArray;
          for LElement in LArray do
          begin
            LMessage := (LElement as TJSONObject);
            HandleMessage(LMessage);
          end;
        except on E: Exception do
          // handle errors? ignore errors?
        end;

        Sleep(FPollingInterval);
      end; // while
    end // task
  ).Start;
{$endif}
end;

procedure TSkuchainClientMessagingResource.StopPolling;
begin
{$ifdef DelphiXE7_UP}
  if Assigned(FWorkerTask) and (FWorkerTask.Status < TTaskStatus.Completed) then
    FWorkerTask.Cancel;
{$endif}
end;

end.
