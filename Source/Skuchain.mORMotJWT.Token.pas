(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Skuchain.mORMotJWT.Token;

interface

uses
  Classes, SysUtils
, Skuchain.Utils.Parameters, Skuchain.Utils.Parameters.JSON
, Skuchain.Core.Token

, SynCommons, SynCrypto, SynEcc, SynLZ
;

type
  TSkuchainmORMotJWTToken = class(TSkuchainToken)
  protected
    function BuildJWTToken(const ASecret: string; const AClaims: TSkuchainParameters): string; override;
    function LoadJWTToken(const AToken: string; const ASecret: string; var AClaims: TSkuchainParameters): Boolean; override;
  end;

implementation

uses
  DateUtils, Generics.Collections, Rtti
, Skuchain.Core.Utils, Skuchain.Utils.JWT
, Skuchain.mORMotJWT.Token.InjectionService
;

{ TSkuchainmORMotJWTToken }

function TSkuchainmORMotJWTToken.BuildJWTToken(const ASecret: string;
  const AClaims: TSkuchainParameters): string;
var
  LJWT: TJWTAbstract;
  LToken: RawUTF8;
  LClaimsValues: TDocVariantData;
  LArray: TTVarRecDynArray;
  LClaim: TPair<string, TValue>;
begin
  LJWT := TJWTHS256.Create(StringToUTF8(ASecret), 0, [jrcIssuer], []);
  try
    LClaimsValues.Init([], dvArray);
    for LClaim in AClaims do
    begin
      LClaimsValues.AddItem(LClaim.Key);
      LClaimsValues.AddItem(LClaim.Value.AsVariant);
    end;
    LClaimsValues.ToArrayOfConst(LArray);

    LToken := LJWT.Compute(
      LArray
    , StringToUTF8( AClaims.ByName(JWT_ISSUER_CLAIM).AsString )
    , StringToUTF8( AClaims.ByName(JWT_SUBJECT_CLAIM).AsString )
    , StringToUTF8( AClaims.ByName(JWT_AUDIENCE_CLAIM).AsString )
    , AClaims.ByName(JWT_NOT_BEFORE_CLAIM, 0).AsType<TDateTime>
    );

    Result := UTF8ToString(LToken);
  finally
    LJWT.Free;
  end;
end;

function TSkuchainmORMotJWTToken.LoadJWTToken(const AToken, ASecret: string;
  var AClaims: TSkuchainParameters): Boolean;
var
  LJWT: TJWTAbstract;
  LContent: TJWTContent;
  LName: RawUTF8;
  LValue: RawUTF8;
begin
  LJWT := TJWTHS256.Create(StringToUTF8(ASecret), 0, [jrcIssuer], []);
  try
    LJWT.Options := [joHeaderParse, joAllowUnexpectedClaims];
    LJWT.Verify(StringToUTF8(AToken), LContent);
    Result := LContent.result = jwtValid;

    if jrcAudience in LContent.claims then
      AClaims.Values[JWT_AUDIENCE_CLAIM] := string(LContent.reg[TJWTClaim.jrcAudience]);
    if jrcExpirationTime in LContent.claims then
      AClaims.Values[JWT_EXPIRATION_CLAIM] := StrToInt64Def(string(LContent.reg[TJWTClaim.jrcExpirationTime]), 0);
    if jrcIssuedAt in LContent.claims then
      AClaims.Values[JWT_ISSUED_AT_CLAIM] := StrToIntDef(string(LContent.reg[TJWTClaim.jrcIssuedAt]), 0);
    if jrcIssuer in LContent.claims then
      AClaims.Values[JWT_ISSUER_CLAIM] := string(LContent.reg[TJWTClaim.jrcIssuer]);
    if jrcJwtID in LContent.claims then
      AClaims.Values[JWT_JWT_ID_CLAIM] := string(LContent.reg[TJWTClaim.jrcJwtID]);
    if jrcNotBefore in LContent.claims then
      AClaims.Values[JWT_NOT_BEFORE_CLAIM] := StrToInt64Def(string(LContent.reg[TJWTClaim.jrcNotBefore]), 0);
    if jrcSubject in LContent.claims then
      AClaims.Values[JWT_SUBJECT_CLAIM] := string(LContent.reg[TJWTClaim.jrcSubject]);

    for LName in LContent.data.Names do
    begin
      LValue := '';
      LContent.data.GetAsRawUTF8(LName, LValue);
      AClaims.Values[string(LName)] := GuessTValueFromString( string(LValue) );
    end;
  finally
    LJWT.Free;
  end;
end;

end.

