(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
program FireDACBasicServer;

uses
  Vcl.Forms,
  Server.Forms.Main in 'Server.Forms.Main.pas' {MainForm},
  Server.MainData in 'Server.MainData.pas' {MainDataResource: TDataModule},
  Skuchain.Data.FireDAC.DataModule in '..\..\Source\Skuchain.Data.FireDAC.DataModule.pas' {SkuchainFDDataModuleResource: TDataModule},
  Server.Resources in 'Server.Resources.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
