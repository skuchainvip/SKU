(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, System.Rtti, FMX.Grid.Style,
  Data.Bind.Controls, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Skuchain.Client.CustomResource, Skuchain.Client.Resource, Skuchain.Client.FireDAC,
  Skuchain.Client.Application, Skuchain.Client.Client, FMX.StdCtrls, Fmx.Bind.Navigator,
  FMX.Layouts, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Grid,
  Data.Bind.EngExt, Fmx.Bind.DBEngExt, Fmx.Bind.Grid, System.Bindings.Outputs,
  Fmx.Bind.Editors, Data.Bind.Components, Data.Bind.Grid, Data.Bind.DBScope,
  Fmx.Dialogs, Skuchain.Client.Client.Indy
  ;

type
  TForm1 = class(TForm)
    SkuchainClient1: TSkuchainClient;
    SkuchainClientApplication1: TSkuchainClientApplication;
    StringGrid1: TStringGrid;
    ButtonPOST: TButton;
    BindNavigator1: TBindNavigator;
    Layout1: TLayout;
    ButtonGET: TButton;
    SkuchainFDResource1: TSkuchainFDResource;
    employee1: TFDMemTable;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBindSourceDB1: TLinkGridToDataSource;
    procedure FormCreate(Sender: TObject);
    procedure ButtonPOSTClick(Sender: TObject);
    procedure ButtonGETClick(Sender: TObject);
    procedure SkuchainFDResource1ApplyUpdatesError(const ASender: TObject;
      const AItem: TSkuchainFDResourceDatasetsItem; const AErrorCount: Integer;
      const AErrors: TArray<System.string>; var AHandled: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.ButtonGETClick(Sender: TObject);
begin
  SkuchainFDResource1.GET();
end;

procedure TForm1.ButtonPOSTClick(Sender: TObject);
begin
  SkuchainFDResource1.POST();
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ButtonGETClick(ButtonGET);
end;

procedure TForm1.SkuchainFDResource1ApplyUpdatesError(const ASender: TObject;
  const AItem: TSkuchainFDResourceDatasetsItem; const AErrorCount: Integer;
  const AErrors: TArray<System.string>; var AHandled: Boolean);
begin
  if AErrorCount > 0 then
    ShowMessage( string.Join(sLineBreak, AErrors) );
end;

end.
