(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
program FMXClientProject;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMXClient.Forms.Main in 'FMXClient.Forms.Main.pas' {MainForm},
  FMXClient.DataModules.Main in 'FMXClient.DataModules.Main.pas' {MainDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainDataModule, MainDataModule);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
