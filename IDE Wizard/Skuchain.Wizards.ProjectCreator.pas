unit Skuchain.Wizards.ProjectCreator;
{$WARN SYMBOL_DEPRECATED OFF}

interface

uses
  ToolsAPI;

resourcestring
  SSkuchainServerProject = 'SkuchainServerProject';

type
  TSkuchainServerProjectCreator = class(TInterfacedObject, IOTACreator, IOTAProjectCreator50, IOTAProjectCreator80,
  IOTAProjectCreator160, IOTAProjectCreator)
  public
    // IOTACreator
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;

    // IOTAProjectCreator
    function GetFileName: string;
    function GetOptionFileName: string; deprecated;
    function GetShowSource: Boolean;
    procedure NewDefaultModule; deprecated;
    function NewOptionSource(const ProjectName: string): IOTAFile; deprecated;
    procedure NewProjectResource(const Project: IOTAProject);
    function NewProjectSource(const ProjectName: string): IOTAFile;

    // IOTAProjectCreator50
    procedure NewDefaultProjectModule(const Project: IOTAProject);

    // IOTAProjectCreator80
    function GetProjectPersonality: string;

    // IOTAProjectCreator160
    function GetFrameworkType: string;
    function GetPlatforms: TArray<string>;
    function GetPreferredPlatform: string;
    procedure SetInitialOptions(const NewProject: IOTAProject);
  end;

implementation

uses
  Skuchain.Wizards.Utils,
  Skuchain.Wizards.Modules.MainForm,
  Skuchain.Wizards.Modules.Resources,
  PlatformAPI,
  System.SysUtils,
  System.Types,
  System.Classes;

{$REGION 'IOTACreator'}

function TSkuchainServerProjectCreator.GetCreatorType: string;
begin
  Result := '';
end;

function TSkuchainServerProjectCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TSkuchainServerProjectCreator.GetFileSystem: string;
begin
  Result := '';
end;

function TSkuchainServerProjectCreator.GetOwner: IOTAModule;
begin
  Result := ActiveProjectGroup;
end;

function TSkuchainServerProjectCreator.GetUnnamed: Boolean;
begin
  Result := True;
end;

{$ENDREGION}
{$REGION 'IOTAProjectCreator'}

function TSkuchainServerProjectCreator.GetFileName: string;
begin
  Result := GetCurrentDir + '\' + 'SkuchainServerProject.dpr';
end;

function TSkuchainServerProjectCreator.GetOptionFileName: string; deprecated;
begin
  Result := '';
end;

function TSkuchainServerProjectCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TSkuchainServerProjectCreator.NewProjectSource(const ProjectName: string): IOTAFile;
begin
  Result := TSkuchainSourceFile.Create(SSkuchainServerProject);
end;

function TSkuchainServerProjectCreator.NewOptionSource(const ProjectName: string): IOTAFile; deprecated;
begin
  Result := nil;
end;

procedure TSkuchainServerProjectCreator.NewDefaultModule; deprecated;
begin
end;

procedure TSkuchainServerProjectCreator.NewProjectResource(const Project: IOTAProject);
begin
end;

{$ENDREGION}
{$REGION 'IOTAProjectCreator50'}

procedure TSkuchainServerProjectCreator.NewDefaultProjectModule(const Project: IOTAProject);
var
  ms: IOTAModuleServices;
begin
  ms := BorlandIDEServices as IOTAModuleServices;
  ms.CreateModule(TSkuchainServerMainFormCreator.Create);
  ms.CreateModule(TSkuchainServerResourcesCreator.Create);
end;

{$ENDREGION}
{$REGION 'IOTAProjectCreator80'}

function TSkuchainServerProjectCreator.GetProjectPersonality: string;
begin
  Result := sDelphiPersonality;
end;

{$ENDREGION}
{$REGION 'IOTAProjectCreator160'}

function TSkuchainServerProjectCreator.GetFrameworkType: string;
begin
  Result := sFrameworkTypeVCL;
end;

function TSkuchainServerProjectCreator.GetPlatforms: TArray<string>;
begin
  SetLength(Result, 2);
  Result[0] := cWin32Platform;
  Result[1] := cWin64Platform;
end;

function TSkuchainServerProjectCreator.GetPreferredPlatform: string;
begin
  Result := cWin32Platform;
end;

procedure TSkuchainServerProjectCreator.SetInitialOptions(const NewProject: IOTAProject);
begin
end;

{$ENDREGION}

end.
