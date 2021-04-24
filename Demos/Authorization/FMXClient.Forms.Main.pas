unit FMXClient.Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Layouts,
  Skuchain.Client.SubResource, System.JSON, Skuchain.Client.CustomResource,
  Skuchain.Client.Resource, Skuchain.Client.Token, Skuchain.Client.Application,
  Skuchain.Client.Client, FMX.StdCtrls, FMX.Edit, Skuchain.Utils.Parameters,
  Skuchain.Client.Client.Indy
  ;

type
  TMainForm = class(TForm)
    DefaultClient: TSkuchainClient;
    DefaultApplication: TSkuchainClientApplication;
    Token: TSkuchainClientToken;
    FirstResource: TSkuchainClientResource;
    DetailsSubResource: TSkuchainClientSubResource;
    Layout1: TLayout;
    Layout3: TLayout;
    Memo1: TMemo;
    EchoStringLayout: TLayout;
    UsernameEdit: TEdit;
    Label1: TLabel;
    LoginButton: TButton;
    PasswordEdit: TEdit;
    Label2: TLabel;
    FirstButton: TButton;
    FirstDetailsButton: TButton;
    procedure LoginButtonClick(Sender: TObject);
    procedure FirstButtonClick(Sender: TObject);
    procedure FirstDetailsButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.FirstButtonClick(Sender: TObject);
begin
  Memo1.Lines.Clear;
  Memo1.Lines.Add('Request URL: ' + FirstResource.URL);
  Memo1.Lines.Add('Token: ' + FirstResource.AuthToken);
  Memo1.Lines.Add('Token.IsVerified: ' + Token.IsVerified.ToString(TUseBoolStrs.True));
  Memo1.Lines.Add('Response (GET):');
  Memo1.Lines.Add(FirstResource.GETAsString());
end;

procedure TMainForm.FirstDetailsButtonClick(Sender: TObject);
begin
  Memo1.Lines.Clear;
  Memo1.Lines.Add('Request URL: ' + DetailsSubResource.URL);
  Memo1.Lines.Add('Token: ' + DetailsSubResource.AuthToken);
  Memo1.Lines.Add('Token.IsVerified: ' + Token.IsVerified.ToString(TUseBoolStrs.True));
  Memo1.Lines.Add('Response (GET):');
  Memo1.Lines.Add(DetailsSubResource.GETAsString());
end;

procedure TMainForm.LoginButtonClick(Sender: TObject);
begin
  Token.UserName := UsernameEdit.Text;
  Token.Password := PasswordEdit.Text;
  Token.POST(
    nil
  , procedure (AStream: TStream)
    begin
      if Token.IsVerified then
        ShowMessage('OK, success!' + sLineBreak
          + 'Data:' + sLineBreak
          + Token.Data.ToString
        )
      else
        ShowMessage('Username or password invalid');
    end
  , procedure (AError: Exception)
    begin
      ShowMessage('Authentication error. Token expired? Try again.');
      Token.Clear;
    end
  );
end;

end.
