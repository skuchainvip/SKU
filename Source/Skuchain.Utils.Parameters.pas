(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Utils.Parameters;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils, Generics.Collections, Rtti;

type
  TSkuchainParametersSlice = class
  private
    FItems: TDictionary<string, TValue>;
    FName: string;
  protected
    const SLICE_SEPARATOR = '.';

    procedure Assign(const ASource: TSkuchainParametersSlice);
    function GetCount: Integer; inline;
    function GetIsEmpty: Boolean; inline;
    function GetParamNames: TArray<string>; inline;
    function GetSliceNames: TArray<string>;
    function GetValue(AName: string): TValue;
    procedure SetValue(AName: string; const Value: TValue);
  public
    constructor Create(const AName: string); virtual;
    destructor Destroy; override;

    function GetQualifiedParamName(const AParamName: string): string;
    function ByNameText(const AName: string): TValue; overload;
    function ByNameText(const AName: string; const ADefault: TValue): TValue; overload;
    function ByName(const AName: string): TValue; overload;
    function ByName(const AName: string; const ADefault: TValue): TValue; overload;
    procedure Clear;
    function ContainsSlice(const ASliceName: string): Boolean;
    function ContainsParam(const AParamName: string): Boolean;
    function CopyFrom(const ASource: TSkuchainParametersSlice;
      const ASliceName: string = ''): Integer;
    function ToString: string; override;

    property Count: Integer read GetCount;
    property IsEmpty: Boolean read GetIsEmpty;
    property Name: string read FName;
    property ParamNames: TArray<string> read GetParamNames;
    property Values[AName: string]: TValue read GetValue write SetValue; default;
    property SliceNames: TArray<string> read GetSliceNames;

    class function CombineSliceAndParamName(const ASlice, AParam: string): string;
    class procedure GetSliceAndParamName(const AName: string; out ASliceName, AParamName: string);
  public
    type TEnumerator = TEnumerator<TPair<string, TValue>>;
    function GetEnumerator: TEnumerator;
  end;

  TSkuchainParameters = class(TSkuchainParametersSlice)
  private
  protected
  public
  end;

implementation

{$ifdef DelphiXE2_UP}
{$else}
uses
  StrUtils;
{$endif}

{ TSkuchainParametersSlice }

function TSkuchainParametersSlice.ByName(const AName: string): TValue;
begin
  Result := ByName(AName, TValue.Empty);
end;

procedure TSkuchainParametersSlice.Assign(const ASource: TSkuchainParametersSlice);
var
  LItem: TPair<string, TValue>;
begin
  FItems.Clear;
  for LItem in ASource do
    Fitems.Add(LItem.Key, LItem.Value);
end;

function TSkuchainParametersSlice.ByName(const AName: string;
  const ADefault: TValue): TValue;
var
  LValue: TValue;
begin
  if FItems.TryGetValue(AName, LValue) then
    Result := LValue
  else
    Result := ADefault;
end;

function TSkuchainParametersSlice.ByNameText(const AName: string): TValue;
begin
  Result := ByNameText(AName, TValue.Empty);
end;

function TSkuchainParametersSlice.ByNameText(const AName: string;
  const ADefault: TValue): TValue;
var
  LName: string;
  LParamName: string;
begin
  LName := AName;
  for LParamName in ParamNames do
  begin
    if SameText(LParamName, LName) then
    begin
      LName := LParamName;
      Break;
    end;
  end;

  Result := ByName(LName, ADefault);
end;

procedure TSkuchainParametersSlice.Clear;
begin
  FItems.Clear;
end;

class function TSkuchainParametersSlice.CombineSliceAndParamName(const ASlice,
  AParam: string): string;
begin
  Result := AParam;
  if ASlice <> '' then
    Result := ASlice + SLICE_SEPARATOR + AParam;
end;

function TSkuchainParametersSlice.ContainsParam(const AParamName: string): Boolean;
begin
  Result := FItems.ContainsKey(AParamName);
end;

function TSkuchainParametersSlice.ContainsSlice(const ASliceName: string): Boolean;
var
  LIndex: Integer;
begin
  Result := TArray.BinarySearch<string>(GetSliceNames, ASliceName, LIndex);
end;

function TSkuchainParametersSlice.CopyFrom(const ASource: TSkuchainParametersSlice;
  const ASliceName: string): Integer;
var
  LItem: TPair<string, TValue>;
  LSourceSliceName: string;
  LSourceParamName: string;
begin
  Result := 0;
  Clear;
  if Assigned(ASource) then
  begin
    if ASliceName = '' then
      Self.Assign(ASource)
    else
    begin
      for LItem in ASource do
      begin
        GetSliceAndParamName(LItem.Key, LSourceSliceName, LSourceParamName);

        if SameText(LSourceSliceName, ASliceName) then
        begin
          Self.Values[LSourceParamName] := LItem.Value;
          Inc(Result);
        end;
      end;
    end;
  end;
end;

class procedure TSkuchainParametersSlice.GetSliceAndParamName(const AName: string;
  out ASliceName, AParamName: string);
var
  LTokens: TArray<string>;
begin
  ASliceName := '';
  AParamName := AName;

  {$ifdef DelphiXE2_UP}
  LTokens := AName.Split([SLICE_SEPARATOR]);
  {$else}
  LTokens := TArray<string>(SplitString(AName, SLICE_SEPARATOR));
  {$endif}
  if Length(LTokens) > 1 then
  begin
    ASliceName := LTokens[0];
    AParamName := Copy(AName, Length(ASliceName) + 1 + Length(SLICE_SEPARATOR), MAXINT);
  end;
end;

function UniqueArray(const AArray: TArray<string>): TArray<string>;
var
  LSortedArray: TArray<string>;
  LIndex: Integer;
  LCurrValue: string;
  LPrevValue: string;
begin
  LSortedArray := AArray;
  TArray.Sort<string>(LSortedArray);

  SetLength(Result, 0);
  LPrevValue := '';
  for LIndex := Low(LSortedArray) to High(LSortedArray) do
  begin
    LCurrValue := LSortedArray[LIndex];
    if LCurrValue <> LPrevValue then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result)-1] := LCurrValue;
      LPrevValue := LCurrValue;
    end;
  end;
end;


function TSkuchainParametersSlice.GetSliceNames: TArray<string>;
var
  LKey: string;
  LSlice, LParamName: string;
begin
  SetLength(Result, 0);
  for LKey in FItems.Keys.ToArray do
  begin
    GetSliceAndParamName(LKey, LSlice, LParamName);
    if LSlice <> '' then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result)-1] := LSlice;
    end;
  end;
  Result := UniqueArray(Result);
end;

constructor TSkuchainParametersSlice.Create(const AName: string);
begin
  inherited Create;
  FItems := TDictionary<string, TValue>.Create;
  FName := AName;
end;

destructor TSkuchainParametersSlice.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function TSkuchainParametersSlice.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TSkuchainParametersSlice.GetEnumerator: TEnumerator;
begin
  Result := FItems.GetEnumerator;
end;

function TSkuchainParametersSlice.GetIsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TSkuchainParametersSlice.GetParamNames: TArray<string>;
begin
  Result := FItems.Keys.ToArray;
end;

function TSkuchainParametersSlice.GetQualifiedParamName(
  const AParamName: string): string;
begin
  Result := CombineSliceAndParamName(Name, AParamName);
end;

function TSkuchainParametersSlice.GetValue(AName: string): TValue;
begin
  Result := ByName(AName, TValue.Empty);
end;

procedure TSkuchainParametersSlice.SetValue(AName: string; const Value: TValue);
begin
  FItems.AddOrSetValue(AName, Value);
end;

function TSkuchainParametersSlice.ToString: string;
var
  LItem: TPair<string, TValue>;
begin
  Result := '';
  for LItem in FItems do
  begin
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result + LItem.Key +': ' + LItem.Value.ToString;
  end;
end;

end.
