(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Messaging.Subscriber;

interface

uses
  Classes, SysUtils

  , Skuchain.Messaging.Message
  , Skuchain.Core.Classes

  ;

type
  ISkuchainMessageSubscriber = interface
    procedure OnMessage(AMessage: TSkuchainMessage);
  end;

  TSkuchainAnonymousSubscriber<T: TSkuchainCustomMessage> = class(TNonInterfacedObject, ISkuchainMessageSubscriber)
  private
    FProc: TProc<T>;
  protected
  public
    constructor Create(const AProc: TProc<T>); virtual;

    procedure OnMessage(AMessage: TSkuchainMessage);
  end;


implementation

{ TSkuchainAnonymousSubscriber }

constructor TSkuchainAnonymousSubscriber<T>.Create(const AProc: TProc<T>);
begin
  inherited Create;
  FProc := AProc;
end;

procedure TSkuchainAnonymousSubscriber<T>.OnMessage(AMessage: TSkuchainMessage);
begin
  if Assigned(FProc) and (AMessage is T) then
  begin
    FProc(AMessage as T);
  end;
end;

end.
