(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Metadata.JSON;

interface

uses
    System.Rtti
  , Skuchain.Metadata
  , Skuchain.Core.JSON
;

type
  TSkuchainMetadataJSON=class helper for TSkuchainMetadata
  protected
    procedure ReadItem(const AItem: TJSONObject; const AMetadataClass: TSkuchainMetadataClass);
    procedure ReadField(const AField: TRttiField; const AJSONObject: TJSONObject); virtual;
    procedure ReadFieldList(const AField: TRttiField; const AJSONArray: TJSONArray); virtual;
    procedure ReadProperty(const AProperty: TRttiProperty; const AJSONObject: TJSONObject); virtual;
    procedure ReadPropertyList(const AProperty: TRttiProperty; const AJSONArray: TJSONArray); virtual;
  public
    function ToJSON: TJSONObject; virtual;
    procedure FromJSON(const AJSONObject: TJSONObject); virtual;
  end;


implementation

uses
    System.TypInfo, Generics.Collections, System.JSON
  , Skuchain.Rtti.Utils
;

{ TSkuchainMetadataJSON }

procedure TSkuchainMetadataJSON.ReadField(const AField: TRttiField;
  const AJSONObject: TJSONObject);
begin

end;

procedure TSkuchainMetadataJSON.ReadFieldList(const AField: TRttiField;
  const AJSONArray: TJSONArray);
begin

end;

procedure TSkuchainMetadataJSON.ReadItem(const AItem: TJSONObject; const AMetadataClass: TSkuchainMetadataClass);
var
  LMetadata: TSkuchainMetadata;
begin
  LMetadata := AMetadataClass.Create(Self);
  try
    LMetadata.FromJSON(AItem);
  except
    LMetadata.Free;
    raise;
  end;
end;

procedure TSkuchainMetadataJSON.ReadProperty(const AProperty: TRttiProperty;
  const AJSONObject: TJSONObject);
begin

end;

procedure TSkuchainMetadataJSON.ReadPropertyList(const AProperty: TRttiProperty;
  const AJSONArray: TJSONArray);
var
  LItem: TJSONValue;
begin
  inherited;
  //AM TODO: ugly (make more general)!
  for LItem in AJSONArray do
  begin
    if AProperty.Name = 'Applications' then
      ReadItem(LItem as TJSONObject, TSkuchainApplicationMetadata)
    else if AProperty.Name = 'Resources' then
      ReadItem(LItem as TJSONObject, TSkuchainResourceMetadata)
    else if AProperty.Name = 'Methods' then
      ReadItem(LItem as TJSONObject, TSkuchainMethodMetadata)
    else if AProperty.Name = 'Parameters' then
      ReadItem(LItem as TJSONObject, TSkuchainRequestParamMetadata);
  end;
end;

function TSkuchainMetadataJSON.ToJSON: TJSONObject;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LField: TRttiField;
  LFields: TArray<TRttiField>;
  LProperties: TArray<TRttiProperty>;
  LProperty: TRttiProperty;
  LItem: TSkuchainMetadata;
  LList: TSkuchainMetadataList;
  LJSONArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  LType := LContext.GetType(Self.ClassType);

  // fields
  LFields := LType.GetFields;
  for LField in LFields do
  begin
    if LField.Visibility >= TMemberVisibility.mvPublic then
    begin
      if LField.FieldType.IsObjectOfType<TSkuchainMetadata> then
        Result.AddPair(LField.Name, LField.GetValue(Self).AsType<TSkuchainMetadata>.ToJSON)
      else if LField.FieldType is TRttiInstanceType then
      begin
        LList := LField.GetValue(Self).AsType<TSkuchainMetadataList>;
        if Assigned(LList) then
        begin
          LJSONArray := TJSONArray.Create;
          try
            for LItem in LList do
              LJSONArray.Add(LItem.ToJSON);

            Result.AddPair(LField.Name, LJSONArray);
          except
            LJSONArray.Free;
            raise;
          end;
        end;
      end
      else
        Result.WriteTValue(LField.Name, LField.GetValue(Self));
    end;
  end;

  // properties
  LProperties := LType.GetProperties;
  for LProperty in LProperties do
  begin
    if LProperty.Visibility >= TMemberVisibility.mvPublic then
    begin
      if LProperty.PropertyType.IsObjectOfType<TSkuchainMetadata> then
        Result.AddPair(LProperty.Name, LProperty.GetValue(Self).AsType<TSkuchainMetadata>.ToJSON)
      else if LProperty.PropertyType is TRttiInstanceType then
      begin
        LList := LProperty.GetValue(Self).AsType<TSkuchainMetadataList>;
        if Assigned(LList) then
        begin
          LJSONArray := TJSONArray.Create;
          try
            for LItem in LList do
              LJSONArray.Add(LItem.ToJSON);

            Result.AddPair(LProperty.Name, LJSONArray);
          except
            LJSONArray.Free;
            raise;
          end;
        end;
      end
      else
        Result.WriteTValue(LProperty.Name, LProperty.GetValue(Self));
    end;
  end;
end;

procedure TSkuchainMetadataJSON.FromJSON(const AJSONObject: TJSONObject);
var
  LContext: TRttiContext;
  LType: TRttiType;
  LField: TRttiField;
  LFields: TArray<TRttiField>;
  LProperties: TArray<TRttiProperty>;
  LProperty: TRttiProperty;
  LFieldObject: TJSONObject;
  LFieldArray: TJSONArray;
begin
  LType := LContext.GetType(Self.ClassType);

  // fields
  LFields := LType.GetFields;
  for LField in LFields do
  begin
    if LField.Visibility >= TMemberVisibility.mvPublic then
    begin
      if LField.FieldType.IsObjectOfType<TSkuchainMetadata> then
      begin
        if AJSONObject.TryGetValue<TJSONObject>(LField.Name, LFieldObject) then
          ReadField(LField, LFieldObject);
      end
      else if LField.FieldType is TRttiInstanceType then
      begin
        if AJSONObject.TryGetValue<TJSONArray>(LField.Name, LFieldArray) then
          ReadFieldList(LField, LFieldArray);
      end
      else
        LField.SetValue(Self, AJSONObject.ReadValue(LField.Name, TValue.Empty, LField.FieldType));
    end;
  end;

  // properties
  LProperties := LType.GetProperties;
  for LProperty in LProperties do
  begin
    if (LProperty.Visibility >= TMemberVisibility.mvPublic) then
    begin
      if LProperty.PropertyType.IsObjectOfType<TSkuchainMetadata> then
      begin
        if AJSONObject.TryGetValue<TJSONObject>(LProperty.Name, LFieldObject) then
          ReadProperty(LProperty, LFieldObject);
      end
      else if LProperty.PropertyType is TRttiInstanceType then
      begin
        if AJSONObject.TryGetValue<TJSONArray>(LProperty.Name, LFieldArray) then
          ReadPropertyList(LProperty, LFieldArray);
      end
      else if (LProperty.IsWritable) then
        LProperty.SetValue(Self, AJSONObject.ReadValue(LProperty.Name, TValue.Empty, LProperty.PropertyType));
    end;
  end;
end;

end.
