(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Messaging.Resource;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes

  , Skuchain.Core.JSON
  , Skuchain.Core.Attributes
  , Skuchain.Core.Token
  , Skuchain.Core.MediaType

  , Skuchain.Messaging.Message
  , Skuchain.Messaging.Queue

  ;

type
  TSkuchainMessagingResourceForToken<T: TSkuchainCustomMessage, constructor> = class
  private
  protected
  [Context] Token: TSkuchainToken;
  public
    [Path('listen'), GET]
    [Produces(TMediaType.APPLICATION_JSON)]
    procedure Subscribe;

    [Path('myqueue'), GET]
    [Produces(TMediaType.APPLICATION_JSON)]
    function Consume: TJSONObject;
  end;


implementation

uses
  Generics.Collections;

{ TSkuchainMessagingResourceForToken<T> }

function TSkuchainMessagingResourceForToken<T>.Consume: TJSONObject;
var
  LCount: Integer;
  LArrayMessaggi: TJSONArray;
begin
  LCount := -1;

  LArrayMessaggi := TJSONArray.Create;
  try

    TSkuchainMessagingQueueForToken.Use<T>(Token,
      procedure (AQueue: TQueue<T>)
      var
        LMessage: T;
      begin
        LCount := AQueue.Count;
        while AQueue.Count > 0 do
        begin
          LMessage := AQueue.Dequeue;
          try
            LArrayMessaggi.Add(LMessage.ToJSON);
          finally
            LMessage.Free;
          end;
        end;
      end
    );

    Result := TJSONObject.Create;
    try
      Result.AddPair('Count', TJSONNumber.Create(LCount));
      Result.AddPair('Messages', LArrayMessaggi);
    except
      Result.Free;
      raise;
    end;
  except
    LArrayMessaggi.Free;
    raise;
  end;

end;

procedure TSkuchainMessagingResourceForToken<T>.Subscribe;
begin
  TSkuchainMessagingQueueForToken.Create<T>(Token);
end;

end.
