(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.Client.Resource.JSON;

{$I Skuchain.inc}

interface

uses
  SysUtils, Classes
  , Skuchain.Core.JSON, Skuchain.Client.Utils
  , Skuchain.Client.Resource, Skuchain.Client.CustomResource
  , Skuchain.Client.Client
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
  TSkuchainClientResourceJSON = class(TSkuchainClientResource)
  private
    FResponse: TJSONValue;
  protected
    procedure AfterGET(const AContent: TStream); override;
    procedure AfterPOST(const AContent: TStream); override;
    function GetResponseAsString: string; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure POST(const AJSONValue: TJSONValue;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;

    procedure POST<R: record>(const ARecord: R;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;

    procedure POST<R: record>(const AArrayOfRecord: TArray<R>;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;

    procedure POSTAsync(const AJSONValue: TJSONValue;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const ACompletionHandler: TProc<TSkuchainClientCustomResource>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const ASynchronize: Boolean = True); overload;

    procedure PUT(const AJSONValue: TJSONValue;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;

    procedure PUT<R: record>(const ARecord: R;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;

    procedure PUT<R: record>(const AArrayOfRecord: TArray<R>;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif}); overload;

    procedure PUTAsync(const AJSONValue: TJSONValue;
      const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
      const ACompletionHandler: TProc<TSkuchainClientCustomResource>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const ASynchronize: Boolean = True); overload;

    function ResponseAs<T: record>: T;
    function ResponseAsArray<T: record>: TArray<T>;
  published
    property Response: TJSONValue read FResponse write FResponse;
    property ResponseAsString: string read GetResponseAsString;
  end;

procedure Register;

implementation

uses
  Skuchain.Core.Utils, Skuchain.Core.MediaType
;

procedure Register;
begin
  RegisterComponents('Skuchain-Curiosity Client', [TSkuchainClientResourceJSON]);
end;

{ TSkuchainClientResourceJSON }

procedure TSkuchainClientResourceJSON.AfterGET(const AContent: TStream);
begin
  inherited;
  if Assigned(FResponse) then
    FResponse.Free;
  FResponse := StreamToJSONValue(AContent);
end;

procedure TSkuchainClientResourceJSON.AfterPOST(const AContent: TStream);
begin
  inherited;
  if Assigned(FResponse) then
    FResponse.Free;
  FResponse := StreamToJSONValue(AContent);
end;

constructor TSkuchainClientResourceJSON.Create(AOwner: TComponent);
begin
  inherited;
  FResponse := TJSONObject.Create;
  SpecificAccept := TMediaType.APPLICATION_JSON;
  SpecificContentType := TMediaType.APPLICATION_JSON;
end;

destructor TSkuchainClientResourceJSON.Destroy;
begin
  FResponse.Free;
  inherited;
end;

function TSkuchainClientResourceJSON.GetResponseAsString: string;
begin
  Result := '';
  if Assigned(FResponse) then
    Result := FResponse.ToJSON;
end;

procedure TSkuchainClientResourceJSON.POST(const AJSONValue: TJSONValue;
  const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
  const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
  const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif});
begin
  POST(
    procedure (AContent: TMemoryStream)
    begin
      JSONValueToStream(AJSONValue, AContent);
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , AAfterExecute
  , AOnException
  );
end;

procedure TSkuchainClientResourceJSON.POST<R>(const ARecord: R;
  const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
  const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
  const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif});
begin
  POST(
    procedure (AContent: TMemoryStream)
    var
      LJSONValue: TJSONValue;
    begin
      LJSONValue := TJSONObject.RecordToJSON<R>(ARecord);
      try
        JSONValueToStream(LJSONValue, AContent);
      finally
        LJSONValue.Free;
      end;
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , AAfterExecute
  , AOnException
  );
end;

procedure TSkuchainClientResourceJSON.POST<R>(const AArrayOfRecord: TArray<R>;
  const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
  const AAfterExecute: TSkuchainClientResponseProc{$ifdef DelphiXE2_UP} = nil{$endif};
  const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif});
begin
  POST(
    procedure (AContent: TMemoryStream)
    var
      LJSONValue: TJSONValue;
    begin
      LJSONValue := TJSONArray.ArrayOfRecordToJSON<R>(AArrayOfRecord);
      try
        JSONValueToStream(LJSONValue, AContent);
      finally
        LJSONValue.Free;
      end;
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , AAfterExecute
  , AOnException
  );
end;


procedure TSkuchainClientResourceJSON.POSTAsync(const AJSONValue: TJSONValue;
  const ABeforeExecute: TProc<TMemoryStream>{$ifdef DelphiXE2_UP} = nil{$endif};
  const ACompletionHandler: TProc<TSkuchainClientCustomResource>{$ifdef DelphiXE2_UP} = nil{$endif};
  const AOnException: TSkuchainClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
  const ASynchronize: Boolean = True);
begin
  POSTAsync(
    procedure (AContent: TMemoryStream)
    begin
      JSONValueToStream(AJSONValue, AContent);
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , ACompletionHandler
  , AOnException
  , ASynchronize
  );
end;

procedure TSkuchainClientResourceJSON.PUT(const AJSONValue: TJSONValue;
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
begin
  PUT(
    procedure (AContent: TMemoryStream)
    begin
      JSONValueToStream(AJSONValue, AContent);
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , AAfterExecute
  , AOnException
  );
end;

procedure TSkuchainClientResourceJSON.PUT<R>(const ARecord: R;
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
begin
  PUT(
    procedure (AContent: TMemoryStream)
    var
      LJSONValue: TJSONValue;
    begin
      LJSONValue := TJSONObject.RecordToJSON<R>(ARecord);
      try
        JSONValueToStream(LJSONValue, AContent);
      finally
        LJSONValue.Free;
      end;
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , AAfterExecute
  , AOnException
  );
end;

procedure TSkuchainClientResourceJSON.PUT<R>(const AArrayOfRecord: TArray<R>;
  const ABeforeExecute: TProc<TMemoryStream>;
  const AAfterExecute: TSkuchainClientResponseProc;
  const AOnException: TSkuchainClientExecptionProc);
begin
  PUT(
    procedure (AContent: TMemoryStream)
    var
      LJSONValue: TJSONValue;
    begin
      LJSONValue := TJSONArray.ArrayOfRecordToJSON<R>(AArrayOfRecord);
      try
        JSONValueToStream(LJSONValue, AContent);
      finally
        LJSONValue.Free;
      end;
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , AAfterExecute
  , AOnException
  );
end;

procedure TSkuchainClientResourceJSON.PUTAsync(const AJSONValue: TJSONValue;
  const ABeforeExecute: TProc<TMemoryStream>;
  const ACompletionHandler: TProc<TSkuchainClientCustomResource>;
  const AOnException: TSkuchainClientExecptionProc; const ASynchronize: Boolean);
begin
  PUTAsync(
    procedure (AContent: TMemoryStream)
    begin
      JSONValueToStream(AJSONValue, AContent);
      AContent.Position := 0;
      if Assigned(ABeforeExecute) then
        ABeforeExecute(AContent);
    end
  , ACompletionHandler
  , AOnException
  , ASynchronize
  );
end;

function TSkuchainClientResourceJSON.ResponseAs<T>: T;
begin
  Result := (Response as TJSONObject).ToRecord<T>;
end;

function TSkuchainClientResourceJSON.ResponseAsArray<T>: TArray<T>;
begin
  Result := (Response as TJSONArray).ToArrayOfRecord<T>;
end;

end.
