(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit FMXClient.DataModules.Main;

interface

uses
  System.SysUtils, System.Classes, Skuchain.Client.CustomResource,
  Skuchain.Client.Resource, Skuchain.Client.Resource.JSON, Skuchain.Client.Application,
  Skuchain.Client.Client, Skuchain.Client.SubResource, Skuchain.Client.SubResource.JSON,
  Skuchain.Client.Messaging.Resource, System.JSON, Skuchain.Client.Client.Indy
;

type
  TMainDataModule = class(TDataModule)
    SkuchainClient1: TSkuchainClient;
    SkuchainClientApplication1: TSkuchainClientApplication;
    HelloWorldResource: TSkuchainClientResource;
    EchoStringResource: TSkuchainClientSubResource;
    ReverseStringResource: TSkuchainClientSubResource;
    SumSubResource: TSkuchainClientSubResource;
  private
    { Private declarations }
  public
    function ExecuteHelloWorld: string;
    function EchoString(AString: string): string;
    function ReverseString(AString: string): string;
    function Sum(AFirst, ASecond: Integer) : Integer;
  end;

var
  MainDataModule: TMainDataModule;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TMainDataModule }

function TMainDataModule.EchoString(AString: string): string;
begin
  EchoStringResource.PathParamsValues.Text := AString;
  Result := EchoStringResource.GETAsString();
end;

function TMainDataModule.ExecuteHelloWorld: string;
begin
  Result := HelloWorldResource.GETAsString();
end;

function TMainDataModule.ReverseString(AString: string): string;
begin
  ReverseStringResource.PathParamsValues.Text := AString;
  Result := ReverseStringResource.GETAsString();
end;

function TMainDataModule.Sum(AFirst, ASecond: Integer): Integer;
begin
  SumSubResource.PathParamsValues.Clear;
  SumSubResource.PathParamsValues.Add(AFirst.ToString);
  SumSubResource.PathParamsValues.Add(ASecond.ToString);
  Result := SumSubResource.GETAsString().ToInteger;
end;

end.
