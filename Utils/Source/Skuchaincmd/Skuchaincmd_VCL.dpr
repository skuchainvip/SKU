program Skuchaincmd_VCL;

uses
  Vcl.Forms,
  Forms.Main in 'Forms.Main.pas' {MainForm},
  Skuchain.Cmd in 'Skuchain.Cmd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
