(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Metadata.Attributes;

interface

uses
  Classes, SysUtils
  , Skuchain.Core.Attributes
;

type
  MetadataAttribute = class(SkuchainAttribute)

  end;

  MetaDescriptionAttribute = class(MetadataAttribute)
  private
    FText: string;
  public
    constructor Create(AText: string);
    property Text: string read FText;
  end;

  MetaVisibleAttribute = class(MetadataAttribute)
  private
    FValue: Boolean;
  public
    constructor Create(AValue: Boolean);
    property Value: Boolean read FValue;
  end;

implementation

uses
    Skuchain.Core.URL
;


{ MetaDescriptionAttribute }

constructor MetaDescriptionAttribute.Create(AText: string);
begin
  inherited Create;
  FText := AText;
end;

{ MetaVisibleAttribute }

constructor MetaVisibleAttribute.Create(AValue: Boolean);
begin
  inherited Create;
  FValue := AValue;
end;

end.
