(*
  Copyright 2016, Skuchain-Curiosity - REST Library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Utils.ReqRespLogger.Interfaces;

interface

uses
    Rtti
  , Skuchain.Core.Engine
;

type
  ISkuchainReqRespLogger = interface['{E59B8A55-5BFA-4DF4-853D-49D5CFF0E680}']

    function GetLogBuffer: TValue;
    procedure Clear;
  end;

implementation

end.
