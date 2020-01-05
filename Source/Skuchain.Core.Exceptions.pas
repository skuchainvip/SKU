(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Exceptions;

interface

uses
  SysUtils;

type
  ESkuchainException = class(Exception);

  ESkuchainHttpException = class(ESkuchainException)
  private
    FStatus: Integer;
  public
    constructor Create(const AMessage: string; AStatus: Integer = 500); reintroduce; virtual;
    constructor CreateFmt(const AMessage: string; const Args: array of const; AStatus: Integer = 500); reintroduce; virtual;

    property Status: Integer read FStatus write FStatus;
  end;

implementation

{ ESkuchainHttpException }

constructor ESkuchainHttpException.Create(const AMessage: string; AStatus: Integer);
begin
  inherited Create(AMessage);
  FStatus := AStatus;
end;

constructor ESkuchainHttpException.CreateFmt(const AMessage: string;
  const Args: array of const; AStatus: Integer);
begin
  inherited CreateFmt(AMessage, Args);
  FStatus := AStatus;
end;

end.
