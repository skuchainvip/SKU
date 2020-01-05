(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Registry;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes, Rtti, TypInfo, Generics.Collections
;

type
  TSkuchainConstructorInfo = class
  private
    FConstructorFunc: TFunc<TObject>;
    FTypeTClass: TClass;
  protected
    function FindConstructor(AClass: TClass): TRttiMethod;
  public
    constructor Create(AClass: TClass; const AConstructorFunc: TFunc<TObject>);

    property TypeTClass: TClass read FTypeTClass;
    property ConstructorFunc: TFunc<TObject> read FConstructorFunc write FConstructorFunc;
    function Clone: TSkuchainConstructorInfo;
  end;

  TSkuchainResourceRegistry = class(TObjectDictionary<string, TSkuchainConstructorInfo>)
  private
  protected
    class var _Instance: TSkuchainResourceRegistry;

    class function GetInstance: TSkuchainResourceRegistry; static;
  public
    constructor Create; virtual;
    function RegisterResource<T: class>: TSkuchainConstructorInfo; overload;
    function RegisterResource<T: class>(const AConstructorFunc: TFunc<TObject>): TSkuchainConstructorInfo; overload;

    function GetResourceClass(const AResource: string; out Value: TClass): Boolean;
    function GetResourceInstance<T: class>: T;

    class property Instance: TSkuchainResourceRegistry read GetInstance;
    class destructor ClassDestroy;
  end;

{$ifdef DelphiXE}
type
  TObjectHelper = class helper for TObject
    class function QualifiedClassName: string;
  end;
{$endif}

implementation

type TDataModuleClass = class of TDataModule;

{$ifdef DelphiXE}
class function TObjectHelper.QualifiedClassName: string;
var
  LScope: string;
begin
  LScope := UnitName;
  if LScope = '' then
    Result := ClassName
  else
    Result := LScope + '.' + ClassName;
end;
{$endif}

{ TSkuchainResourceRegistry }

function TSkuchainResourceRegistry.GetResourceInstance<T>: T;
var
  LInfo: TSkuchainConstructorInfo;
begin
  if Self.TryGetValue(T.ClassName, LInfo) then
  begin
    if LInfo.ConstructorFunc <> nil then
      Result := LInfo.ConstructorFunc() as T;
  end;
end;

function TSkuchainResourceRegistry.RegisterResource<T>: TSkuchainConstructorInfo;
begin
  Result := RegisterResource<T>(nil);
end;

function TSkuchainResourceRegistry.RegisterResource<T>(
  const AConstructorFunc: TFunc<TObject>): TSkuchainConstructorInfo;
begin
  Result := TSkuchainConstructorInfo.Create(TClass(T), AConstructorFunc);
  Self.Add(T.QualifiedClassName.ToLower, Result);
end;

class destructor TSkuchainResourceRegistry.ClassDestroy;
begin
  if Assigned(_Instance) then
    FreeAndNil(_Instance);
end;

constructor TSkuchainResourceRegistry.Create;
begin
  inherited Create([doOwnsValues]);
end;

class function TSkuchainResourceRegistry.GetInstance: TSkuchainResourceRegistry;
begin
  if not Assigned(_Instance) then
    _Instance := TSkuchainResourceRegistry.Create;
  Result := _Instance;
end;

function TSkuchainResourceRegistry.GetResourceClass(const AResource: string;
  out Value: TClass): Boolean;
var
  LInfo: TSkuchainConstructorInfo;
begin
  Value := nil;
  Result := Self.TryGetValue(AResource, LInfo);
  if Result then
    Value := LInfo.TypeTClass;
end;

{ TSkuchainConstructorInfo }

function TSkuchainConstructorInfo.Clone: TSkuchainConstructorInfo;
begin
  Result := TSkuchainConstructorInfo.Create(FTypeTClass, FConstructorFunc);
end;

constructor TSkuchainConstructorInfo.Create(AClass: TClass;
  const AConstructorFunc: TFunc<TObject>);
begin
  inherited Create;
  FConstructorFunc := AConstructorFunc;
  FTypeTClass := AClass;

  // provide a default constructor function
  if not Assigned(FConstructorFunc) then
    FConstructorFunc :=
      function: TObject
      begin
        if FTypeTClass.InheritsFrom(TDataModule) then
          Result := TDataModuleClass(FTypeTClass).Create(nil)
        else
          Result := FindConstructor(FTypeTClass).Invoke(FTypeTClass, []).AsObject;
      end;
end;

function TSkuchainConstructorInfo.FindConstructor(AClass: TClass): TRttiMethod;
var
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  Result := nil;
  LType := TRttiContext.Create.GetType(AClass);

  for LMethod in LType.GetMethods do
  begin
    if LMethod.IsConstructor and (Length(LMethod.GetParameters) = 0) then
    begin
      Result := LMethod;
      Break;
    end;
  end;
end;

end.
