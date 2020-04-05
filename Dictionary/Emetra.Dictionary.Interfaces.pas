unit Emetra.Dictionary.Interfaces;

interface

uses
  System.Variants;

type
  IVariantDictionary = interface
    ['{E6224B74-3AA6-45FF-8F4D-E0CCB137BE2D}']
    function TryGetValue( const AVarName: string; var AValue: Variant ): boolean;
  end;

  IStringDictionary = interface
    ['{9D7A83E8-F796-45E1-A2E1-B9F5C50DAE9A}']
    function TryGetString( const AVarName: string; var AValue: string ): boolean;
    function GetString( const AVarName: string ): string;
  end;

  INumericDictionary = interface
    ['{B2854A94-5F75-40D6-9711-EB318BFA7DD5}']
    function TryGetNumber( const AVarName: string; var Value: Extended ): boolean;
  end;

  IDefaultProperty = interface
    ['{2A0DC3BB-C982-46B2-92C1-B920793E123C}']
    function DefaultProperty: Variant;
  end;

  IPeriodDictionary = interface
    ['{9ABCF5FD-688A-4D7A-9BB5-2833BC722474}']
    function TryGetPeriod( const AContext, ACaption: string; out AStartDate, AStopDate: TDateTime ): boolean;
  end;

implementation

end.
