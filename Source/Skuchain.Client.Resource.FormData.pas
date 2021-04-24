(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Resource.FormData;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes, Generics.Collections

  , Skuchain.Client.Resource, Skuchain.Client.Client
  , Skuchain.Client.Utils, Skuchain.Core.Utils
;

type
  {$ifdef DelphiXE2_UP}
    [ComponentPlatformsAttribute(
        pidWin32 or pidWin64
     or pidOSX32
     or pidiOSSimulator
     or pidiOSDevice
    {$ifdef DelphiXE8_UP}
     or pidiOSDevice32 or pidiOSDevice64
    {$endif}
     or pidAndroid)]
  {$endif}
  TSkuchainClientResourceFormData = class(TSkuchainClientResource)
  private
    FFormData: TArray<TFormParam>;
    FResponse: TMemoryStream;
  protected
    procedure AfterPOST(const AContent: TStream); override;
    procedure AfterPUT(const AContent: TStream); override;
    function GetResponseAsString: string; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure POST(const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload; override;
    procedure POST(const AFormData: TArray<TFormParam>;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload; virtual;

    procedure PUT(const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload; override;
    procedure PUT(const AFormData: TArray<TFormParam>;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload; virtual;


  published
    property FormData: TArray<TFormParam> read FFormData write FFormData;
    property Response: TMemoryStream read FResponse;
    property ResponseAsString: string read GetResponseAsString;
  end;

procedure Register;

implementation

uses
  Skuchain.Core.MediaType
;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientResourceFormData]);
end;

{ TSkuchainClientResourceFormData }

procedure TSkuchainClientResourceFormData.AfterPOST(const AContent: TStream);
begin
  inherited;
  AContent.Position := 0;
  FResponse.Size := 0; // clear
  FResponse.CopyFrom(AContent, 0);
end;

procedure TSkuchainClientResourceFormData.AfterPUT(const AContent: TStream);
begin
  inherited;
  AContent.Position := 0;
  FResponse.Size := 0; // clear
  FResponse.CopyFrom(AContent, 0);
end;

constructor TSkuchainClientResourceFormData.Create(AOwner: TComponent);
begin
  inherited;
  FFormData := [];
  FResponse := TMemoryStream.Create;
  SpecificContentType := TMediaType.MULTIPART_FORM_DATA;
end;

destructor TSkuchainClientResourceFormData.Destroy;
begin
  FResponse.Free;
  FFormData := [];
  inherited;
end;

function TSkuchainClientResourceFormData.GetResponseAsString: string;
begin
  Result := StreamToString(FResponse);
end;

procedure TSkuchainClientResourceFormData.POST(const AFormData: TArray<TFormParam>;
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
begin
  FFormData := AFormData;
  POST(ABeforeExecute, AAfterExecute, AOnException);
end;

procedure TSkuchainClientResourceFormData.PUT(const AFormData: TArray<TFormParam>;
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
begin
  FFormData := AFormData;
  PUT(ABeforeExecute, AAfterExecute, AOnException);
end;

procedure TSkuchainClientResourceFormData.PUT(
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
var
  LResponseStream: TMemoryStream;
begin
  // inherited (!)

  try
    BeforePUT(nil);

    if Assigned(ABeforeExecute) then
      ABeforeExecute(nil);

    LResponseStream := TMemoryStream.Create;
    try
      Client.Put(URL, FFormData, LResponseStream, AuthToken, Accept, ContentType);

      AfterPUT(LResponseStream);

      if Assigned(AAfterExecute) then
        AAfterExecute(LResponseStream);
    finally
      LResponseStream.Free;
    end;
  except
    on E:Exception do
    begin
      if Assigned(AOnException) then
        AOnException(E)
      else
        DoError(E, TSkuchainHttpVerb.Put, AAfterExecute);
    end;
  end;
end;

procedure TSkuchainClientResourceFormData.POST(
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
var
  LResponseStream: TMemoryStream;
begin
  // inherited (!)

  try
    BeforePOST(nil);

    if Assigned(ABeforeExecute) then
      ABeforeExecute(nil);

    LResponseStream := TMemoryStream.Create;
    try
      Client.Post(URL, FFormData, LResponseStream, AuthToken, Accept, ContentType);

      AfterPOST(LResponseStream);

      if Assigned(AAfterExecute) then
        AAfterExecute(LResponseStream);
    finally
      LResponseStream.Free;
    end;
  except
    on E:Exception do
    begin
      if Assigned(AOnException) then
        AOnException(E)
      else
        DoError(E, TSkuchainHttpVerb.Post, AAfterExecute);
    end;
  end;
end;

end.
