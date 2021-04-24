(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Server.MainData;

interface

uses
  System.SysUtils, System.Classes,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, Data.DB, FireDAC.Comp.Client, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.VCLUI.Wait, FireDAC.Comp.UI
  , Skuchain.Data.FireDAC.DataModule
  , Skuchain.Core.Attributes
  , Skuchain.Core.URL
  , Skuchain.Core.Token
  ;

type
  [Path('/maindata')]
  TMainDataResource = class(TSkuchainFDDataModuleResource)
    FDConnection1: TFDConnection;
    employee: TFDQuery;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
  private
  public
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  Skuchain.Core.Registry;

{ TMainDataResource }

initialization
  TSkuchainResourceRegistry.Instance.RegisterResource<TMainDataResource>;

end.
