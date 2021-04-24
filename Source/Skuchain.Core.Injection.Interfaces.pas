(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Injection.Interfaces;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Rtti, TypInfo
, Skuchain.Core.Declarations
, Skuchain.Core.Activation.Interfaces
, Skuchain.Core.Injection.Types
;

type
  ISkuchainInjectionService = interface ['{C2EB93E0-5D0B-4F29-AEAF-CAB74DC72C3C}']
    procedure GetValue(const ADestination: TRttiObject; const AActivation: ISkuchainActivation;
      out AValue: TInjectionValue);
  end;



implementation

end.
