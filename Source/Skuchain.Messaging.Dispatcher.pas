(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Messaging.Dispatcher;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils
  , Rtti
  , Generics.Collections
{$ifdef DelphiXE7_UP}
  , Threading
{$endif}
  , SyncObjs

  , Skuchain.Core.Utils
  , Skuchain.Messaging.Message
  , Skuchain.Messaging.Subscriber
  ;

type
  TSkuchainMessageDispatcher = class
  private
    FSubscribers: TList<ISkuchainMessageSubscriber>;
    FQueue: TThreadedQueue<TSkuchainMessage>;
    FCriticalSection: TCriticalSection;
{$ifdef DelphiXE7_UP}
    FWorkerTask: ITask;
{$endif}
  protected
    class var _Instance: TSkuchainMessageDispatcher;
    class function GetInstance: TSkuchainMessageDispatcher; static;

    procedure DoRegisterSubscriber(const ASubscriber: ISkuchainMessageSubscriber); virtual;
    procedure DoUnRegisterSubscriber(const ASubscriber: ISkuchainMessageSubscriber); virtual;

    property Subscribers: TList<ISkuchainMessageSubscriber> read FSubscribers;
  public
    const MESSAGE_QUEUE_DEPTH = 100;
    constructor Create; virtual;
    destructor Destroy; override;

    function Enqueue(AMessage: TSkuchainMessage): Integer;
    procedure RegisterSubscriber(const ASubscriber: ISkuchainMessageSubscriber);
    procedure UnRegisterSubscriber(const ASubscriber: ISkuchainMessageSubscriber);

    class property Instance: TSkuchainMessageDispatcher read GetInstance;
    class destructor ClassDestructor;
  end;


implementation

{ TSkuchainMessageDispatcher }

class destructor TSkuchainMessageDispatcher.ClassDestructor;
begin
  if Assigned(_Instance) then
    FreeAndNil(_Instance);
end;

constructor TSkuchainMessageDispatcher.Create;
begin
  inherited Create();

  FSubscribers := TList<ISkuchainMessageSubscriber>.Create;
  FQueue := TThreadedQueue<TSkuchainMessage>.Create(MESSAGE_QUEUE_DEPTH);
  FCriticalSection := TCriticalSection.Create;

{$ifdef DelphiXE7_UP}
  FWorkerTask := TTask.Create(
    procedure
    var
      LMessage: TSkuchainMessage;
      LSubscriber: ISkuchainMessageSubscriber;
    begin
      while TTask.CurrentTask.Status = TTaskStatus.Running do
      begin
        // pop
        LMessage := FQueue.PopItem;

        if Assigned(LMessage) then // this can be async
        try
          // dispatch
          for LSubscriber in Subscribers do
          begin
            try
              LSubscriber.OnMessage(LMessage);
            except
              // handle errors? ignore errors?
            end;
          end;
        finally
          LMessage.Free;
        end;

      end;
    end
  );

  FWorkerTask.Start;
{$endif}
end;

destructor TSkuchainMessageDispatcher.Destroy;
begin
{$ifdef DelphiXE7_UP}
  if Assigned(FWorkerTask) and (FWorkerTask.Status < TTaskStatus.Canceled) then
    FWorkerTask.Cancel;
{$endif}

  FCriticalSection.Free;
  FSubscribers.Free;
  FQueue.Free;

  inherited;
end;

procedure TSkuchainMessageDispatcher.DoRegisterSubscriber(
  const ASubscriber: ISkuchainMessageSubscriber);
begin
  FSubscribers.Add(ASubscriber);
end;

procedure TSkuchainMessageDispatcher.DoUnRegisterSubscriber(
  const ASubscriber: ISkuchainMessageSubscriber);
begin
  FSubscribers.Remove(ASubscriber);
end;

function TSkuchainMessageDispatcher.Enqueue(AMessage: TSkuchainMessage): Integer;
begin
  FQueue.PushItem(AMessage, Result);
end;

class function TSkuchainMessageDispatcher.GetInstance: TSkuchainMessageDispatcher;
begin
  if not Assigned(_Instance) then
    _Instance := TSkuchainMessageDispatcher.Create;
  Result := _Instance;
end;

procedure TSkuchainMessageDispatcher.RegisterSubscriber(
  const ASubscriber: ISkuchainMessageSubscriber);
begin
  DoRegisterSubscriber(ASubscriber);
end;

procedure TSkuchainMessageDispatcher.UnRegisterSubscriber(
  const ASubscriber: ISkuchainMessageSubscriber);
begin
  DoUnRegisterSubscriber(ASubscriber);
end;

end.
