(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Injection.Types;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti
;

type
  TInjectionValue = record
    IsReference: Boolean;
    Value: TValue;
    constructor Create(const AValue: TValue; const AIsReference: Boolean = False);
    procedure Clear;
  end;


implementation

{ TInjectionValue }

procedure TInjectionValue.Clear;
begin
  IsReference := False;
  Value := TValue.Empty;
end;


constructor TInjectionValue.Create(const AValue: TValue;
  const AIsReference: Boolean);
begin
  Value := AValue;
  IsReference := AIsReference;
end;

end.
