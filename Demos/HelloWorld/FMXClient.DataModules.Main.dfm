object MainDataModule: TMainDataModule
  OldCreateOrder = False
  Height = 394
  Width = 605
  object SkuchainClient1: TSkuchainClient
    SkuchainEngineURL = 'http://localhost:8080/rest'
    ConnectTimeout = 0
    ReadTimeout = -1
    ProtocolVersion = pv1_1
    HttpClient.AllowCookies = True
    HttpClient.ProxyParams.BasicAuthentication = False
    HttpClient.ProxyParams.ProxyPort = 0
    HttpClient.Request.ContentLength = -1
    HttpClient.Request.ContentRangeEnd = -1
    HttpClient.Request.ContentRangeStart = -1
    HttpClient.Request.ContentRangeInstanceLength = -1
    HttpClient.Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    HttpClient.Request.BasicAuthentication = False
    HttpClient.Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HttpClient.Request.Ranges.Units = 'bytes'
    HttpClient.Request.Ranges = <>
    HttpClient.HTTPOptions = [hoForceEncodeParams]
    Left = 280
    Top = 16
  end
  object SkuchainClientApplication1: TSkuchainClientApplication
    DefaultMediaType = 'application/json'
    AppName = 'default'
    Client = SkuchainClient1
    Left = 280
    Top = 72
  end
  object HelloWorldResource: TSkuchainClientResource
    Application = SkuchainClientApplication1
    Resource = 'helloworld'
    Left = 280
    Top = 128
  end
  object EchoStringResource: TSkuchainClientSubResource
    Application = SkuchainClientApplication1
    Resource = 'echostring'
    ParentResource = HelloWorldResource
    Left = 136
    Top = 192
  end
  object ReverseStringResource: TSkuchainClientSubResource
    Application = SkuchainClientApplication1
    Resource = 'reversestring'
    ParentResource = HelloWorldResource
    Left = 280
    Top = 192
  end
  object SumSubResource: TSkuchainClientSubResource
    Application = SkuchainClientApplication1
    Resource = 'sum'
    ParentResource = HelloWorldResource
    Left = 424
    Top = 192
  end
end
