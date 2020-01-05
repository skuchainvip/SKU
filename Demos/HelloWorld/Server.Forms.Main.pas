(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Server.Forms.Main;

{$I Skuchain.inc}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls
  , ActnList

  , Diagnostics

  , Skuchain.Core.Engine
  , Skuchain.http.Server.Indy
  {$IFDEF MSWINDOWS}
  , Skuchain.mORMotJWT.Token
  {$ELSE}
  , Skuchain.JOSEJWT.Token
  {$ENDIF}
  , Skuchain.Core.Application, System.Actions

;

type
  TMainForm = class(TForm)
    TopPanel: TPanel;
    StartButton: TButton;
    StopButton: TButton;
    MainActionList: TActionList;
    StartServerAction: TAction;
    StopServerAction: TAction;
    PortNumberEdit: TEdit;
    Label1: TLabel;
    procedure StartServerActionExecute(Sender: TObject);
    procedure StartServerActionUpdate(Sender: TObject);
    procedure StopServerActionExecute(Sender: TObject);
    procedure StopServerActionUpdate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PortNumberEditChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FServer: TSkuchainhttpServerIndy;
    FEngine: TSkuchainEngine;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
    Skuchain.Core.MessageBodyWriter, Skuchain.Core.MessageBodyWriters
  , Skuchain.Core.URL
  , Skuchain.Utils.Parameters.IniFile
  ;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopServerAction.Execute;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Skuchain-Curiosity Engine
  FEngine := TSkuchainEngine.Create;
  try
    FEngine.Parameters.LoadFromIniFile;
    FEngine.AddApplication('DefaultApp', '/default', ['Server.Resources.*']);
    PortNumberEdit.Text := IntToStr(FEngine.Port);

    StartServerAction.Execute;
  except
    FreeAndNil(FEngine);
    raise;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FEngine);
end;

procedure TMainForm.PortNumberEditChange(Sender: TObject);
begin
  FEngine.Port := StrToInt(PortNumberEdit.Text);
end;

procedure TMainForm.StartServerActionExecute(Sender: TObject);
begin
  // http server implementation
  FServer := TSkuchainhttpServerIndy.Create(FEngine);
  try
    FServer.DefaultPort := FEngine.Port;
    FServer.Active := True;
  except
    FServer.Free;
    raise;
  end;
end;

procedure TMainForm.StartServerActionUpdate(Sender: TObject);
begin
  StartServerAction.Enabled := (FServer = nil) or (FServer.Active = False);
end;

procedure TMainForm.StopServerActionExecute(Sender: TObject);
begin
  FServer.Active := False;
  FreeAndNil(FServer);
end;

procedure TMainForm.StopServerActionUpdate(Sender: TObject);
begin
  StopServerAction.Enabled := Assigned(FServer) and (FServer.Active = True);
end;

end.
