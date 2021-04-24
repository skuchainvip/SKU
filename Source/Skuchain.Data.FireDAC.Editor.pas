(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Data.FireDAC.Editor;

interface

uses
  System.Classes, System.SysUtils
  ,  DesignEditors
  , Skuchain.Client.CustomResource.Editor
  , Skuchain.Client.FireDAC;

type
  TSkuchainFDResourceEditor = class(TSkuchainClientCustomResourceEditor)
  private
    function CurrentObj: TSkuchainFDResource;
  protected
    procedure SetDesignTimePosition(AComponent: TComponent; AIndex: Integer = 0);
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

procedure Register;

implementation

uses
  Windows
  , VCL.Dialogs
  , DesignIntf

  , FireDAC.Comp.Client
;

procedure Register;
begin
  RegisterComponentEditor(TSkuchainFDResource, TSkuchainFDResourceEditor);
end;

{ TSkuchainFDResourceEditor }

function TSkuchainFDResourceEditor.CurrentObj: TSkuchainFDResource;
begin
  Result := Component as TSkuchainFDResource;
end;

procedure TSkuchainFDResourceEditor.ExecuteVerb(Index: Integer);
var
  LIndex: Integer;
  LMemTable: TFDMemTable;
  LOwner: TComponent;
  LCreated: Integer;
begin
  inherited;
  LIndex := GetVerbCount - 1;
  if Index = LIndex then
  begin
    LCreated := 0;
    LOwner := CurrentObj.Owner;
    CurrentObj.GET;

    CurrentObj.ResourceDataSets.ForEach(
      procedure(AItem: TSkuchainFDResourceDatasetsItem)
      begin
        if (not Assigned(AItem.DataSet)) and (AItem.DataSetName <> '') then
        begin
          LMemTable := TFDMemTable.Create(LOwner);
          try
            LMemTable.Name := Designer.UniqueName(AItem.DataSetName);
            AItem.DataSet := LMemTable;

            SetDesignTimePosition(LMemTable, LCreated);
            Inc(LCreated);
          except
            LMemTable.Free;
            raise;
          end;
        end;
      end
    );

    CurrentObj.GET();
  end;

  Designer.Modified;
end;

function TSkuchainFDResourceEditor.GetVerb(Index: Integer): string;
var
  LIndex: Integer;
begin
  Result := inherited GetVerb(Index);

  LIndex := GetVerbCount - 1;
  if Index = LIndex then
  begin
    Result := 'Create datasets';
  end;
end;

function TSkuchainFDResourceEditor.GetVerbCount: Integer;
begin
  Result := inherited GetVerbCount + 1;
end;

procedure TSkuchainFDResourceEditor.SetDesignTimePosition(AComponent: TComponent; AIndex: Integer);
var
  LRec: LongRec;
begin
  LRec := LongRec(CurrentObj.DesignInfo);

  LRec.Hi := LRec.Hi + 48; // top
  LRec.Lo := LRec.Lo + (AIndex * 48); // left
  AComponent.DesignInfo := Integer(LRec);
  Designer.Modified;
end;

end.


