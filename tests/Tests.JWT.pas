unit Tests.JWT;

interface

uses
  Classes, SysUtils, Rtti, Types
, DUnitX.TestFramework
, Skuchain.Core.Token
, Skuchain.mORMotJWT.Token, Skuchain.JOSEJWT.Token
;

type
  TSkuchainJWT<T: TSkuchainToken> = class(TObject)
  private
  protected
    procedure Duration(const ASeconds: Int64);
    function GetTokenForVerifyOne: string; virtual;
  public
    const DUMMY_SECRET = 'dummy_secret';

    [Test] procedure BuildOne;
    [Test] procedure VerifyOne;
    [Test] procedure Duration1min;
    [Test] procedure Duration30secs;
    [Test] procedure Duration5secs;
    [Test] procedure Duration1sec;
  end;

  [TestFixture('JWT.mORMotJWT')]
  TSkuchainmORMotJWT = class(TSkuchainJWT<TSkuchainmORMotJWTToken>)
  protected
    function GetTokenForVerifyOne: string; override;
  end;

  [TestFixture('JWT.JOSEJWT')]
  TSkuchainJOSEJWT = class(TSkuchainJWT<TSkuchainJOSEJWTToken>);

implementation

uses
  Math
, Skuchain.Utils.Parameters, Skuchain.Utils.JWT
;

{ TSkuchainJWTmORMotTest }

procedure TSkuchainJWT<T>.BuildOne;
const
  DUMMY_DURATION = 1;
var
  LParams: TSkuchainParameters;
  LToken: TSkuchainToken;
begin
  LParams := TSkuchainParameters.Create('');
  try
    LParams.Values[JWT_SECRET_PARAM] := DUMMY_SECRET;
    LParams.Values[JWT_ISSUER_PARAM] := 'Skuchain-Curiosity';
    LParams.Values[JWT_DURATION_PARAM] := DUMMY_DURATION;

    LToken := T.Create('', LParams);
    try
      LToken.UserName := 'Andrea1';
      LToken.Roles := ['standard'];
      LToken.Claims.Values['LANGUAGE_ID'] := 1;
      LToken.Claims.Values['Claim1'] := 'Primo';
      LToken.Claims.Values['Claim2'] := 123;
      LToken.Build(DUMMY_SECRET);
      Assert.IsNotEmpty(LToken.Token);

      LToken.Load(LToken.Token, DUMMY_SECRET);
      Assert.AreEqual('Skuchain-Curiosity', LToken.Issuer);
      Assert.IsFalse(LToken.IsExpired, 'Token expired');

      if LToken.IssuedAt > 0 then
        Assert.IsTrue(SameValue(LToken.IssuedAt + LToken.Duration, LToken.Expiration), 'IssuedAt [' + DateTimeToStr(LToken.IssuedAt)
          + '] + Duration [' + IntToStr(Round(LToken.Duration * 24 * 60 * 60))+ ' seconds] = Expiration [' + DateTimeToStr(LToken.Expiration)+ ']');
      Assert.IsTrue(1 = LToken.Claims.Values['LANGUAGE_ID'].AsInteger, 'Custom claims 1');

      Assert.AreEqual('Andrea1', LToken.UserName);
      Assert.AreEqual(1, Length(LToken.Roles));
      Assert.AreEqual('standard', LToken.Roles[0]);

    finally
      LToken.Free;
    end;
  finally
    LParams.Free;
  end;
end;

procedure TSkuchainJWT<T>.Duration(const ASeconds: Int64);
var
  LParams: TSkuchainParameters;
  LToken: TSkuchainToken;
  LDuration: TDateTime;
begin
  LParams := TSkuchainParameters.Create('');
  try
    LParams.Values[JWT_SECRET_PARAM] := DUMMY_SECRET;
    LParams.Values[JWT_ISSUER_PARAM] := 'Skuchain-Curiosity';
    LDuration := ASeconds / SecsPerDay;
    LParams.Values[JWT_DURATION_PARAM] := LDuration;

    LToken := T.Create('', LParams);
    try
      LToken.Build(DUMMY_SECRET);
      Assert.IsNotEmpty(LToken.Token);

      LToken.Load(LToken.Token, DUMMY_SECRET);
      Assert.IsFalse(LToken.IsExpired, 'Token expired');
      Assert.IsTrue(SameValue(LToken.Expiration, LToken.IssuedAt + LDuration, (0.5 / SecsPerDay)) // half second as epsilon
      , 'Expiration = IssuedAt + Duration |'
      +' [' + DateTimeToStr(LToken.Expiration) + '] = '
      +' [' + DateTimeToStr(LToken.IssuedAt) + '] + '
      +' [' + DateTimeToStr(LToken.Duration) + ' = ' + IntToStr(LToken.DurationSecs) + ' s ]'
      );
    finally
      LToken.Free;
    end;
  finally
    LParams.Free;
  end;
end;

procedure TSkuchainJWT<T>.Duration1min;
begin
  Duration(60);
end;

procedure TSkuchainJWT<T>.Duration1sec;
begin
  Duration(1);
end;

procedure TSkuchainJWT<T>.Duration30secs;
begin
  Duration(30);
end;

procedure TSkuchainJWT<T>.Duration5secs;
begin
  Duration(5);
end;

function TSkuchainJWT<T>.GetTokenForVerifyOne: string;
begin
  // beware: will expire one million days after Nov 15th, 2017 that is somewhere around Thu, 13 Oct 4755 :-D
  Result := 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9'
    +'.eyJkdXJhdGlvbiI6MTAwMDAwMCwiUm9sZXMiOiJzdGFuZGFyZCIsImlhdCI6MTUxMDczOTg0OCwiZXhwIjo4NzkxMDczNjI0OCwiQ2xhaW0yIjoxMjMsIlVzZXJOYW1lIjoiQW5kcmVhMSIsIkxBTkdVQUdFX0lEIjoxLCJpc3MiOiJNQVJTLUN1cmlvc2l0eSIsIkNsYWltMSI6IlByaW1vIn0='
    +'.OacKD-duGSLeQA21eEzPYlRaIKX7fCWs54GyVpbHC0E=';
end;

procedure TSkuchainJWT<T>.VerifyOne;
var
  LParams: TSkuchainParameters;
  LToken: TSkuchainToken;
begin
  LParams := TSkuchainParameters.Create('');
  try
    LParams.Values[JWT_SECRET_PARAM] := DUMMY_SECRET;

    LToken := T.Create(GetTokenForVerifyOne, LParams);
    try
      Assert.IsTrue(LToken.Token <> '', 'Token is not empty');
      Assert.IsTrue(LToken.IsVerified, 'Token verified');
      Assert.IsFalse(LToken.IsExpired, 'Token expired');
      Assert.AreEqual('Skuchain-Curiosity', LToken.Issuer, 'Issuer');

      Assert.IsTrue('Primo' = LToken.Claims.Values['Claim1'].AsString, 'Custom claims 1');
      Assert.IsTrue(123 = LToken.Claims.Values['Claim2'].AsInteger, 'Custom claims 2');
    finally
      LToken.Free;
    end;
  finally
    LParams.Free;
  end;
end;

{ TSkuchainmORMotJWT }

function TSkuchainmORMotJWT.GetTokenForVerifyOne: string;
begin
  Result := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    +'.eyJkdXJhdGlvbiI6MTAwMDAwMCwiUm9sZXMiOiJzdGFuZGFyZCIsImlhdCI6MTUxMDc0MTM3MSwiZXhwIjoyMDExMzk1NDUxLCJDbGFpbTIiOjEyMywiVXNlck5hbWUiOiJBbmRyZWExIiwiTEFOR1VBR0VfSUQiOjEsImlzcyI6Ik1BUlMtQ3VyaW9zaXR5IiwiQ2xhaW0xIjoiUHJpbW8ifQ'
    +'.k-p3NEEBWXYlf4ilaZn8fE3ufxN29ezMPg8k_HTQg9c';
end;

initialization
  TDUnitX.RegisterTestFixture(TSkuchainmORMotJWT);
  TDUnitX.RegisterTestFixture(TSkuchainJOSEJWT);

end.
