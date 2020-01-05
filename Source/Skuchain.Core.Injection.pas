(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Injection;

{$I Skuchain.inc}

interface

uses
    Classes, SysUtils, Generics.Collections, Rtti, TypInfo
  , Skuchain.Core.Declarations
  , Skuchain.Core.Injection.Interfaces
  , Skuchain.Core.Injection.Types
  , Skuchain.Core.Activation.Interfaces
;

type
  TCanProvideValueFunction = reference to function (const ADestination: TRttiObject): Boolean;

  TEntryInfo = record
    CreateInstance: TFunc<ISkuchainInjectionService>;
    CanProvideValue: TCanProvideValueFunction;
  end;

  TSkuchainInjectionServiceRegistry = class
  private
  private
    FRegistry: TList<TEntryInfo>;
    FRttiContext: TRttiContext;
    class var _Instance: TSkuchainInjectionServiceRegistry;
    class function GetInstance: TSkuchainInjectionServiceRegistry; static;
  protected
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterService(
      const ACreationFunc: TFunc<ISkuchainInjectionService>;
      const ACanProvideValueFunc: TCanProvideValueFunction
    ); overload;

    procedure RegisterService(
      const AClass: TClass;
      const ACanProvideValueFunc: TCanProvideValueFunction
    ); overload;


    function GetValue(const ADestination: TRttiObject;
      const AActivation: ISkuchainActivation): TInjectionValue;

    procedure Enumerate(const AProc: TProc<TEntryInfo>);

    class property Instance: TSkuchainInjectionServiceRegistry read GetInstance;
    class destructor ClassDestructor;
  end;

implementation

uses
  Skuchain.Rtti.Utils
;

{ TSkuchainInjectionServiceRegistry }

class destructor TSkuchainInjectionServiceRegistry.ClassDestructor;
begin
  if Assigned(_Instance) then
    FreeAndNil(_Instance);
end;

constructor TSkuchainInjectionServiceRegistry.Create;
begin
  inherited Create;

  FRegistry := TList<TEntryInfo>.Create;
  FRttiContext := TRttiContext.Create;
end;

destructor TSkuchainInjectionServiceRegistry.Destroy;
begin
  FRegistry.Free;
  inherited;
end;

procedure TSkuchainInjectionServiceRegistry.Enumerate(const AProc: TProc<TEntryInfo>);
var
  LEntry: TEntryInfo;
begin
  for LEntry in FRegistry do
    AProc(LEntry);
end;

class function TSkuchainInjectionServiceRegistry.GetInstance: TSkuchainInjectionServiceRegistry;
begin
  if not Assigned(_Instance) then
    _Instance := TSkuchainInjectionServiceRegistry.Create;
  Result := _Instance;
end;

function TSkuchainInjectionServiceRegistry.GetValue(const ADestination: TRttiObject;
  const AActivation: ISkuchainActivation): TInjectionValue;
var
  LEntry: TEntryInfo;
  LService: ISkuchainInjectionService;
begin
  Result.Clear;
  for LEntry in FRegistry do
  begin
    if LEntry.CanProvideValue(ADestination) then
    begin
      LService := LEntry.CreateInstance();
      LService.GetValue(ADestination, AActivation, Result);

      // first match wins
      if not Result.Value.IsEmpty then
        Break;
    end;
  end;
end;

procedure TSkuchainInjectionServiceRegistry.RegisterService(const AClass: TClass;
  const ACanProvideValueFunc: TCanProvideValueFunction);
begin
  RegisterService(
    function: ISkuchainInjectionService
    var
      LIntf: ISkuchainInjectionService;
      LInstance: TObject;
    begin
      Result := nil;
      LInstance := AClass.Create;
      try
        if Supports(LInstance, ISkuchainInjectionService, LIntf) then
          Result := LIntf
        else
          LInstance.Free;
      except
        LInstance.Free;
      end;
    end
   , ACanProvideValueFunc
  );
end;

procedure TSkuchainInjectionServiceRegistry.RegisterService(
  const ACreationFunc: TFunc<ISkuchainInjectionService>;
  const ACanProvideValueFunc: TCanProvideValueFunction);
var
  LEntryInfo: TEntryInfo;
begin
  LEntryInfo.CreateInstance := ACreationFunc;
  LEntryInfo.CanProvideValue := ACanProvideValueFunc;

  FRegistry.Add(LEntryInfo)
end;

end.
