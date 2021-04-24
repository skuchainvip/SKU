unit Skuchain.Wizards.Modules.Resources;

interface

uses
  Skuchain.Wizards.Utils,
  ToolsAPI;

resourcestring
  SSkuchainServerResources = 'SkuchainServerResources';
  SServerResourcesFileName = 'ServerResources';

type
  TSkuchainServerResourcesCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
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

function TSkuchainServerResourcesCreator.GetCreatorType: string;
begin
  Result := sUnit;
end;

function TSkuchainServerResourcesCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TSkuchainServerResourcesCreator.GetFileSystem: string;
begin
  Result := '';
end;

function TSkuchainServerResourcesCreator.GetOwner: IOTAModule;
begin
  Result := ActiveProject;
end;

function TSkuchainServerResourcesCreator.GetUnnamed: Boolean;
begin
  Result := True;
end;

{$ENDREGION}
{$REGION 'IOTAModuleCreator'}

function TSkuchainServerResourcesCreator.GetAncestorName: string;
begin
  Result := '';
end;

function TSkuchainServerResourcesCreator.GetImplFileName: string;
begin
  Result := GetCurrentDir + '\' + SServerResourcesFileName + '.pas';
end;

function TSkuchainServerResourcesCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TSkuchainServerResourcesCreator.GetFormName: string;
begin
  Result := '';
end;

function TSkuchainServerResourcesCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TSkuchainServerResourcesCreator.GetShowForm: Boolean;
begin
  Result := False;
end;

function TSkuchainServerResourcesCreator.GetShowSource: Boolean;
begin
  Result := False;
end;

function TSkuchainServerResourcesCreator.NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TSkuchainServerResourcesCreator.NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := TSkuchainSourceFile.Create(SSkuchainServerResources);
end;

function TSkuchainServerResourcesCreator.NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

procedure TSkuchainServerResourcesCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
end;

{$ENDREGION}

end.
