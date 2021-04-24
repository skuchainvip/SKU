(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Utils;

interface

uses
  Classes, SysUtils
  ;

type
  ESkuchainClientException = class(Exception);
  ESkuchainClientHttpException = class(ESkuchainClientException)
  private
    FStatusText: string;
    FStatusCode: Integer;
  public
    constructor Create(const AStatusText: string; const AStatusCode: Integer = 500); virtual;

    property StatusText: string read FStatusText;
    property StatusCode: Integer read FStatusCode;
  end;

  TSkuchainClientProc = TProc;
  TSkuchainClientResponseProc = TProc<TStream>;
  TSkuchainClientExecptionProc = TProc<Exception>;

  TSkuchainComponentHelper = class
  public
    class function IsDesigning(AComponent: TComponent): Boolean;
    class function FindDefault<T: class>(AComponent: TComponent): T;
  end;


implementation

class function TSkuchainComponentHelper.IsDesigning(AComponent: TComponent): Boolean;
begin
  Result :=
    ([csDesigning, csLoading] * AComponent.ComponentState = [csDesigning]) and
    ((AComponent.Owner = nil) or
     ([csDesigning, csLoading] * AComponent.Owner.ComponentState = [csDesigning]));
end;

class function TSkuchainComponentHelper.FindDefault<T>(AComponent: TComponent): T;
var
  LRoot: TComponent;
  LIndex: Integer;
begin
  Result := nil;
  LRoot := AComponent;
  while (LRoot.Owner <> nil) and (Result = nil) do begin
    LRoot := LRoot.Owner;
    for LIndex := 0 to LRoot.ComponentCount - 1 do
      if LRoot.Components[LIndex] is T then begin
        Result := T(LRoot.Components[LIndex]);
        Break;
      end;
  end;
end;


{ ESkuchainClientHttpException }

constructor ESkuchainClientHttpException.Create(const AStatusText: string;
  const AStatusCode: Integer);
begin
  inherited Create(AStatusCode.ToString + ': ' + AStatusText);
  FStatusCode := AStatusCode;
  FStatusText := AStatusText;
end;

end.
