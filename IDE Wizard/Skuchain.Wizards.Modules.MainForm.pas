unit Skuchain.Wizards.Modules.MainForm;

interface

uses
  Skuchain.Wizards.Utils,
  ToolsAPI;

resourcestring
  SSkuchainServerMainFormSRC = 'SkuchainServerMainFormSRC';
  SSkuchainServerMainFormDFM = 'SkuchainServerMainFormDFM';
  SMainFormFileName = 'ServerMainForm';

type
  TSkuchainServerMainFormCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  public
    // IOTACreator
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;

    // IOTAModuleCreator
    function GetAncestorName: string;
    function GetImplFileName: string;
    function GetIntfFileName: string;
    function GetFormName: string;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
    function NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    procedure FormCreated(const FormEditor: IOTAFormEditor);
  end;

implementation

uses
  System.SysUtils;

{$REGION 'IOTACreator'}

function TSkuchainServerMainFormCreator.GetCreatorType: string;
begin
  Result := sForm;
end;

function TSkuchainServerMainFormCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TSkuchainServerMainFormCreator.GetFileSystem: string;
begin
  Result := '';
end;

function TSkuchainServerMainFormCreator.GetOwner: IOTAModule;
begin
  Result := ActiveProject;
end;

function TSkuchainServerMainFormCreator.GetUnnamed: Boolean;
begin
  Result := True;
end;

{$ENDREGION}
{$REGION 'IOTAModuleCreator'}

function TSkuchainServerMainFormCreator.GetAncestorName: string;
begin
  Result := 'TForm';
end;

function TSkuchainServerMainFormCreator.GetImplFileName: string;
begin
  Result := GetCurrentDir + '\' + SMainFormFileName + '.pas';
end;

function TSkuchainServerMainFormCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TSkuchainServerMainFormCreator.GetFormName: string;
begin
  Result := 'MainForm';
end;

function TSkuchainServerMainFormCreator.GetMainForm: Boolean;
begin
  Result := True;
end;

function TSkuchainServerMainFormCreator.GetShowForm: Boolean;
begin
  Result := True;
end;

function TSkuchainServerMainFormCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TSkuchainServerMainFormCreator.NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := TSkuchainSourceFile.Create(SSkuchainServerMainFormDFM);
end;

function TSkuchainServerMainFormCreator.NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := TSkuchainSourceFile.Create(SSkuchainServerMainFormSRC);
end;

function TSkuchainServerMainFormCreator.NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

procedure TSkuchainServerMainFormCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
end;

{$ENDREGION}

end.
