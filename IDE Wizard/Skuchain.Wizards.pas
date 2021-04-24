unit Skuchain.Wizards;

interface

uses
  ToolsAPI;

resourcestring
  SName = 'Skuchain-Curiosity Server Application Wizard';
  SComment = 'Creates a new Skuchain-Curiosity Server Application';
  SAuthor = 'Skuchain-Curiosity Development Team';
  SGalleryCategory = 'Skuchain-Curiosity Library';
  SIDString = 'Skuchain-Curiosity.Wizards';

type
  TSkuchainServerProjectWizard = class(TNotifierObject, IOTAWizard, IOTARepositoryWizard, IOTARepositoryWizard60,
    IOTARepositoryWizard80, IOTAProjectWizard, IOTAProjectWizard100)
  public
    constructor Create;

    // IOTAWizard
    procedure Execute;
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;

    // IOTARepositoryWizard
    function GetAuthor: string;
    function GetComment: string;
    function GetGlyph: Cardinal;
    function GetPage: string;

    // IOTARepositoryWizard60
    function GetDesigner: string;

    // IOTARepositoryWizard80
    function GetGalleryCategory: IOTAGalleryCategory;
    function GetPersonality: string;

    // IOTAProjectWizard100
    function IsVisible(Project: IOTAProject): Boolean;
  end;

procedure Register;

implementation

uses
  Skuchain.Wizards.ProjectCreator;

{ TSkuchainServerProjectWizard }

constructor TSkuchainServerProjectWizard.Create;
var
  LCategoryServices: IOTAGalleryCategoryManager;
begin
  inherited Create;
  LCategoryServices := BorlandIDEServices as IOTAGalleryCategoryManager;
  LCategoryServices.AddCategory(LCategoryServices.FindCategory(sCategoryRoot), SIDString, SGalleryCategory);
end;

{$REGION 'IOTAWizard'}

procedure TSkuchainServerProjectWizard.Execute;
begin
  (BorlandIDEServices as IOTAModuleServices).CreateModule(TSkuchainServerProjectCreator.Create);
end;

function TSkuchainServerProjectWizard.GetIDString: string;
begin
  Result := SIDString + '.Server';
end;

function TSkuchainServerProjectWizard.GetName: string;
begin
  Result := SName;
end;

function TSkuchainServerProjectWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TSkuchainServerProjectWizard.AfterSave;
begin
end;

procedure TSkuchainServerProjectWizard.BeforeSave;
begin
end;

procedure TSkuchainServerProjectWizard.Destroyed;
begin
end;

procedure TSkuchainServerProjectWizard.Modified;
begin
end;

{$ENDREGION}
{$REGION 'IOTARepositoryWizard'}

function TSkuchainServerProjectWizard.GetAuthor: string;
begin
  Result := SAuthor;
end;

function TSkuchainServerProjectWizard.GetComment: string;
begin
  Result := SComment;
end;

function TSkuchainServerProjectWizard.GetGlyph: Cardinal;
begin
{ TODO : function TSkuchainServerProjectWizard.GetGlyph: Cardinal; }
  Result := 0;
end;

function TSkuchainServerProjectWizard.GetPage: string;
begin
  Result := SGalleryCategory;
end;

{$ENDREGION}
{$REGION 'IOTARepositoryWizard60'}

function TSkuchainServerProjectWizard.GetDesigner: string;
begin
  Result := dAny;
end;

{$ENDREGION}
{$REGION 'IOTARepositoryWizard80'}

function TSkuchainServerProjectWizard.GetGalleryCategory: IOTAGalleryCategory;
begin
  Result := (BorlandIDEServices as IOTAGalleryCategoryManager).FindCategory(SIDString);
end;

function TSkuchainServerProjectWizard.GetPersonality: string;
begin
  Result := sDelphiPersonality;
end;

{$ENDREGION}
{$REGION 'IOTAProjectWizard100'}

function TSkuchainServerProjectWizard.IsVisible(Project: IOTAProject): Boolean;
begin
  Result := True;
end;

{$ENDREGION}

procedure Register;
begin
  RegisterPackageWizard(TSkuchainServerProjectWizard.Create);
end;


end.
