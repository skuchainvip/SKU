(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Messaging.Message;

{$I Skuchain.inc}

interface

uses
  Classes, SysUtils
  , Rtti
  , Skuchain.Core.JSON
  ;

type
  TSkuchainMessage = class
  private
    FCreationDateTime: TDateTime;
  public
    constructor Create(); virtual;
    procedure Assign(ASource: TSkuchainMessage); virtual;
    function ToJSON: TJSONObject; virtual;

    property CreationDateTime: TDateTime read FCreationDateTime;
  end;

  TSkuchainCustomMessage = class(TSkuchainMessage)
  private
  public
    class function Clone<T: TSkuchainMessage, constructor>(ASource: T): T;
  end;

  TSkuchainStringMessage = class(TSkuchainCustomMessage)
  private
    FValue: string;
  public
    constructor Create(const AValue: string); reintroduce;
    procedure Assign(ASource: TSkuchainMessage); override;
    function ToJSON: TJSONObject; override;

    property Value: string read FValue write FValue;
  end;

  TSkuchainJSONObjectMessage = class(TSkuchainCustomMessage)
  private
    FValue: TJSONObject;
    procedure SetValue(const AValue: TJSONObject);
  public
    constructor Create(AValue: TJSONObject); reintroduce;
    destructor Destroy; override;

    procedure Assign(ASource: TSkuchainMessage); override;
    function ToJSON: TJSONObject; override;

    property Value: TJSONObject read FValue write SetValue;
  end;


implementation

uses
  DateUtils
  , Skuchain.Core.Utils
  ;

{ TSkuchainMessage }

procedure TSkuchainMessage.Assign(ASource: TSkuchainMessage);
begin
  FCreationDateTime := ASource.FCreationDateTime;
end;

constructor TSkuchainMessage.Create();
begin
  inherited Create;
  FCreationDateTime := Now;
end;

function TSkuchainMessage.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('MessageType', ClassName);
  Result.AddPair('CreationDateTime', DateToISO8601(CreationDateTime));
end;

{ TSkuchainCustomMessage }

class function TSkuchainCustomMessage.Clone<T>(ASource: T): T;
begin
  Result := T.Create;
  Result.Assign(ASource);
end;


{ TSkuchainStringMessage }

procedure TSkuchainStringMessage.Assign(ASource: TSkuchainMessage);
begin
  inherited;
  if ASource is TSkuchainStringMessage then
    Self.FValue := TSkuchainStringMessage(ASource).FValue;
end;

constructor TSkuchainStringMessage.Create(const AValue: string);
begin
  inherited Create;
  FValue := AValue;
end;

function TSkuchainStringMessage.ToJSON: TJSONObject;
begin
  Result := inherited ToJSON;
  Result.AddPair('Value', Value);
end;

{ TSkuchainJSONObjectMessage }

procedure TSkuchainJSONObjectMessage.Assign(ASource: TSkuchainMessage);
begin
  inherited;
  if ASource is TSkuchainJSONObjectMessage then
  begin
    Value := TSkuchainJSONObjectMessage(ASource).Value;
  end;
end;

constructor TSkuchainJSONObjectMessage.Create(AValue: TJSONObject);
begin
  inherited Create;
  Value := AValue;
end;

destructor TSkuchainJSONObjectMessage.Destroy;
begin
  FValue.Free;
  inherited;
end;

procedure TSkuchainJSONObjectMessage.SetValue(const AValue: TJSONObject);
begin
  if FValue <> AValue then
    FValue := AValue.Clone as TJSONObject;
end;

function TSkuchainJSONObjectMessage.ToJSON: TJSONObject;
begin
  Result := inherited ToJSON;
  Result.AddPair('Value', Value);
end;

end.
