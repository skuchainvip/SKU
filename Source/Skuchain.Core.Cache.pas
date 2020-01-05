(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Core.Cache;

interface

uses
  Classes, SysUtils, Generics.Collections, Rtti,
  SyncObjs;

type
  TSkuchainCacheItem = class
  private
    FCriticalSection: TCriticalSection;
    FLastReadAccess: TDateTime;
    FLastWriteAccess: TDateTime;
    FDuration: TDateTime;
    FValue: TValue;
    function GetExpiration: TDateTime;
    function GetIsExpired: Boolean;
    function GetValue: TValue;
    procedure SetValue(const Value: TValue);
  protected
  public
    constructor Create;
    destructor Destroy; override;

    property LastReadAccess: TDateTime read FLastReadAccess;
    property LastWriteAccess: TDateTime read FLastWriteAccess;
    property Duration: TDateTime read FDuration write FDuration;
    property Expiration: TDateTime read GetExpiration;
    property IsExpired: Boolean read GetIsExpired;
    property Value: TValue read GetValue write SetValue;
    property CriticalSection: TCriticalSection read FCriticalSection;
  end;

  TSkuchainCache = class
  private
    FStorage: TDictionary<string, TSkuchainCacheItem>;
    FCriticalSection: TCriticalSection;
  protected
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure SetValue(const AName: string; const AValue: TValue);
    function Contains(const AName: string): Boolean;
    function GetValue(const AName: string): TValue;

    function Use(const AName: string; const ADoSomething: TProc<TValue>): Boolean;
  end;

   TCriticalSectionHelper = class helper for TCriticalSection
     procedure AcquireAndDo(const ADoSomething: TProc);
   end;

   TCacheManager = class
   private
   protected
     class var _Instance: TSkuchainCache;
     class function GetInstance: TSkuchainCache; static;
   public
     class property Instance: TSkuchainCache read GetInstance;
     class destructor ClassDestructor;
   end;

implementation

uses
  DateUtils, Math;

{ TCache }

procedure TSkuchainCache.SetValue(const AName: string; const AValue: TValue);
var
  LValue: TValue;
begin
  LValue := AValue;

  FCriticalSection.AcquireAndDo(
    procedure
    var
      LItem: TSkuchainCacheItem;
    begin
      if FStorage.TryGetValue(AName, LItem) then
      begin
        LItem.CriticalSection.AcquireAndDo(
          procedure
          begin
            LItem.Value := LValue;
          end
        );
      end
      else
      begin
        LItem := TSkuchainCacheItem.Create;
        try
          LItem.Value := LValue;
          FStorage.Add(AName, LItem);
        except
          LItem.Free;
          raise;
        end;
      end;
    end);
end;

function TSkuchainCache.Use(const AName: string;
  const ADoSomething: TProc<TValue>): Boolean;
var
  LItem: TSkuchainCacheItem;
  LFound: Boolean;
begin
  Result := False;

  FCriticalSection.Enter;
  try
    LFound := FStorage.TryGetValue(AName, LItem);
  finally
    FCriticalSection.Leave;
  end;

  if LFound then
  begin
    Result := True;

    LItem.CriticalSection.AcquireAndDo(
      procedure
      begin
        ADoSomething(LItem.Value);
      end);
  end;
end;

function TSkuchainCache.Contains(const AName: string): Boolean;
var
  LResult: Boolean;
begin
  FCriticalSection.AcquireAndDo(
    procedure
    begin
      LResult := FStorage.ContainsKey(AName);
    end);
  Result := LResult;
end;

constructor TSkuchainCache.Create;
begin
  inherited Create;
  FStorage := TDictionary<string, TSkuchainCacheItem>.Create;
  FCriticalSection := TCriticalSection.Create;
end;

destructor TSkuchainCache.Destroy;
begin
  FCriticalSection.Free;
  FStorage.Free;
  inherited;
end;

function TSkuchainCache.GetValue(const AName: string): TValue;
var
  LItem: TSkuchainCacheItem;
  LResult: TValue;
begin
  Result := TValue.Empty;

  FCriticalSection.AcquireAndDo(
    procedure
    begin
      if FStorage.TryGetValue(AName, LItem) then
      begin
        LItem.CriticalSection.AcquireAndDo(
          procedure
          begin
            LResult := LItem.Value;
          end
        );
      end;
    end);
  Result := LResult;
end;

{ TCacheItem }

constructor TSkuchainCacheItem.Create;
begin
  inherited Create;
  FCriticalSection := TCriticalSection.Create;
  FLastReadAccess := Now;
  FLastWriteAccess := Now;
  FDuration := 1 / HoursPerDay;
  FValue := TValue.Empty;
end;

destructor TSkuchainCacheItem.Destroy;
begin
  FCriticalSection.Free;
  inherited;
end;

function TSkuchainCacheItem.GetExpiration: TDateTime;
begin
  Result := Max(LastReadAccess, LastWriteAccess) + Duration;
end;

function TSkuchainCacheItem.GetIsExpired: Boolean;
begin
  Result := Now > Expiration;
end;

function TSkuchainCacheItem.GetValue: TValue;
begin
  Result := FValue;
  FLastReadAccess := Now;
end;

procedure TSkuchainCacheItem.SetValue(const Value: TValue);
begin
  FValue := Value;
  FLastWriteAccess := Now;
end;

{ TCriticalSectionHelper }

procedure TCriticalSectionHelper.AcquireAndDo(const ADoSomething: TProc);
begin
  Self.Enter;
  try
    ADoSomething();
  finally
    Self.Leave;
  end;
end;

{ TCacheManager }

class destructor TCacheManager.ClassDestructor;
begin
  if Assigned(_Instance) then
    FreeAndNil(_Instance);
end;

class function TCacheManager.GetInstance: TSkuchainCache;
begin
  if not Assigned(_Instance) then
    _Instance := TSkuchainCache.Create;
  Result := _Instance;
end;

end.
