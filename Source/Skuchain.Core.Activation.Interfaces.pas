(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Activation.Interfaces;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes, Generics.Collections, Rtti, Diagnostics
  , HTTPApp

  , Skuchain.Core.URL
  , Skuchain.Core.Application
  , Skuchain.Core.Engine
  , Skuchain.Core.Token
  , Skuchain.Core.Registry
  , Skuchain.Core.MediaType
  , Skuchain.Core.Injection.Types
  ;

type

  ISkuchainActivation = interface
    procedure AddToContext(AValue: TValue);
    function HasToken: Boolean;

    procedure Invoke;

    function GetApplication: TSkuchainApplication;
    function GetEngine: TSkuchainEngine;
    function GetInvocationTime: TStopwatch;
    function GetMethod: TRttiMethod;
    function GetMethodArguments: TArray<TValue>;
    function GetMethodResult: TValue;
    function GetRequest: TWebRequest;
    function GetResource: TRttiType;
    function GetResourceInstance: TObject;
    function GetResponse: TWebResponse;
    function GetURL: TSkuchainURL;
    function GetURLPrototype: TSkuchainURL;
    function GetToken: TSkuchainToken;

    property Application: TSkuchainApplication read GetApplication;
    property Engine: TSkuchainEngine read GetEngine;
    property InvocationTime: TStopwatch read GetInvocationTime;
    property Method: TRttiMethod read GetMethod;
    property MethodArguments: TArray<TValue> read GetMethodArguments;
    property MethodResult: TValue read GetMethodResult;
    property Request: TWebRequest read GetRequest;
    property Resource: TRttiType read GetResource;
    property ResourceInstance: TObject read GetResourceInstance;
    property Response: TWebResponse read GetResponse;
    property URL: TSkuchainURL read GetURL;
    property URLPrototype: TSkuchainURL read GetURLPrototype;
    property Token: TSkuchainToken read GetToken;
  end;


implementation

end.
