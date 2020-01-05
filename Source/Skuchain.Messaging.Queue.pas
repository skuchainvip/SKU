(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Messaging.Queue;

interface

uses
    Classes, SysUtils

  , Generics.Collections

  , Skuchain.Messaging.Dispatcher
  , Skuchain.Messaging.Subscriber
  , Skuchain.Messaging.Message

  , Skuchain.Stateful.Dictionary

  , Skuchain.Core.Token
  ;

type
  TSkuchainMessagingQueueForToken = class
  private
  protected
    class function GetQueueName<T: TSkuchainCustomMessage>(const AQueueName: string = ''): string;
  public
    class procedure Create<T: TSkuchainCustomMessage, constructor>(AToken: TSkuchainToken; const AQueueName: string = '');
    class procedure Use<T: TSkuchainCustomMessage>(AToken: TSkuchainToken; const ADoSomething: TProc<TQueue<T>>; const AQueueName: string = '');
  end;

implementation

{ TSkuchainMessagingQueue }

class procedure TSkuchainMessagingQueueForToken.Create<T>(AToken: TSkuchainToken;
  const AQueueName: string);
var
  LSubscriber: ISkuchainMessageSubscriber;
  LDictionary: TSkuchainStatefulDictionary;
  LQueueName: string;
begin
  LQueueName := GetQueueName<T>(AQueueName);

  LDictionary := TSkuchainStatefulDictionaryRegistry.Instance.GetDictionaryForToken(AToken);
  LDictionary.Add(LQueueName, TQueue<T>.Create());

  LSubscriber := TSkuchainAnonymousSubscriber<T>.Create(
    procedure(AMessage: T)
    begin
      LDictionary.Use<TQueue<T>>(LQueueName,
        procedure (AQueue: TQueue<T>)
        begin
          AQueue.Enqueue(T.Clone<T>(AMessage));
        end
      );
    end
  );

  TSkuchainMessageDispatcher.Instance.RegisterSubscriber(LSubscriber);
end;

class function TSkuchainMessagingQueueForToken.GetQueueName<T>(
  const AQueueName: string): string;
begin
  Result := AQueueName;
  if Result = '' then
    Result := 'MessageQueue.' + T.ClassName;
end;

class procedure TSkuchainMessagingQueueForToken.Use<T>(AToken: TSkuchainToken;
  const ADoSomething: TProc<TQueue<T>>; const AQueueName: string);
var
  LDictionary: TSkuchainStatefulDictionary;
begin
  LDictionary := TSkuchainStatefulDictionaryRegistry.Instance.GetDictionaryForToken(AToken);

  LDictionary.Use<TQueue<T>>(GetQueueName<T>(AQueueName), ADoSomething);
end;

end.
