(*
  Copyright 2016, Skuchain-Curiosity library

  Home: https://github.com/andrea-magni/Skuchain
*)
unit Server.Resources;

interface

uses
  Classes, SysUtils

  , System.Rtti

  , Skuchain.Core.JSON
  , Skuchain.Core.Registry
  , Skuchain.Core.Attributes
  , Skuchain.Core.MediaType

  , Skuchain.Core.Token
  , Skuchain.Core.Token.Resource

  , Skuchain.Data.MessageBodyWriters

  , Skuchain.Data.FireDAC, Skuchain.Data.FireDAC.Resources
  , FireDAC.Phys.FB, FireDAC.Comp.Client, FireDAC.Comp.DataSet

  , Data.DB
  ;

type
  [  Connection('MAIN_DB'), Path('fdresource')
   , SQLStatement('employee', 'select * from EMPLOYEE order by EMP_NO')
  ]
  THelloWorldResource = class(TSkuchainFDDatasetResource)
  end;

  [Path('fdsimple')]
  TSimpleResource = class
  protected
    [Context]
    FD: TSkuchainFireDAC;
  public
    [GET]
    function GetData: TArray<TFDDataSet>;

    [POST, Consumes(TMediaType.APPLICATION_JSON_FIREDAC)]
    function PostData([BodyParam] AData: TArray<TFDMemTable>): string;
  end;


  [Path('token')]
  TTokenResource = class(TSkuchainTokenResource);

implementation


{ TSimpleResource }

function TSimpleResource.GetData: TArray<TFDDataSet>;
begin
  Result := [
      FD.CreateQuery('select * from EMPLOYEE', nil, False, 'Employee')
    , FD.CreateQuery('select * from COUNTRY', nil, False, 'Country')
  ];
end;

function TSimpleResource.PostData(AData: TArray<TFDMemTable>): string;
begin
  Result := 'DataSets: ' + Length(AData).ToString + sLineBreak
   + AData[0].Name + sLineBreak
   + AData[0].Fields[1].AsString;
end;

initialization
  TSkuchainResourceRegistry.Instance.RegisterResource<TSimpleResource>;
  TSkuchainResourceRegistry.Instance.RegisterResource<THelloWorldResource>;
  TSkuchainResourceRegistry.Instance.RegisterResource<TTokenResource>;

end.
