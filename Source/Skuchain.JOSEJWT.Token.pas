(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.JOSEJWT.Token;

interface

uses
  Classes, SysUtils
, Skuchain.Utils.Parameters, Skuchain.Utils.Parameters.JSON
, Skuchain.Core.Token
, JOSE.Types.Bytes, JOSE.Core.Builder
, JOSE.Core.JWT, JOSE.Core.JWS, JOSE.Core.JWK, JOSE.Core.JWA
;

type
  TSkuchainJOSEJWTToken = class(TSkuchainToken)
  protected
    function BuildJWTToken(const ASecret: string; const AClaims: TSkuchainParameters): string; override;
    function LoadJWTToken(const AToken: string; const ASecret: string; var AClaims: TSkuchainParameters): Boolean; override;
  end;

implementation

uses
  Skuchain.Utils.JWT
, Skuchain.JOSEJWT.Token.InjectionService
;

{ TSkuchainJOSEJWTToken }

function TSkuchainJOSEJWTToken.BuildJWTToken(const ASecret: string;
  const AClaims: TSkuchainParameters): string;
var
  LJWT: TJWT;
  LSigner: TJWS;
  LKey: TJWK;
begin
  LJWT := TJWT.Create(TJWTClaims);
  try
    AClaims.SaveToJSON(LJWT.Claims.JSON);

    LSigner := TJWS.Create(LJWT);
    try
      LKey := TJWK.Create(ASecret);
      try
        LSigner.Sign(LKey, HS256);

        Result := LSigner.CompactToken;
      finally
        LKey.Free;
      end;
    finally
      LSigner.Free;
    end;
  finally
    LJWT.Free;
  end;
end;

function TSkuchainJOSEJWTToken.LoadJWTToken(const AToken, ASecret: string;
  var AClaims: TSkuchainParameters): Boolean;
var
  LKey: TJWK;
  LJWT: TJWT;
begin
  Result := False;
  LKey := TJWK.Create(ASecret);
  try
    LJWT := TJOSE.Verify(LKey, AToken);
    if Assigned(LJWT) then
    begin
      try
        Result := LJWT.Verified;
        if Result then
          AClaims.LoadFromJSON(LJWT.Claims.JSON);
      finally
        LJWT.Free;
      end;
    end;
  finally
    LKey.Free;
  end;
end;

end.
