/// <summary>
///   Dictionaries should be kept case-insensitive by default. It may not be
///   immediately obvious to the user that SomeWord is fundamentally different
///   from someWord or someword, or even Someword.
/// </summary>
/// <remarks>
///   Note that most of these methods use <b>var</b> parameters for the values,
///   indicating that the <b>AValue</b> parameter should not be touched if it
///   already contains something, and the dictionary failed to find a
///   replacement for it. This can be useful for reporting, where you may have
///   some default values already.
/// </remarks>
unit Emetra.Dictionary.Interfaces;

interface

uses
  System.Variants;

type
  /// <summary>
  ///   This type is here to make sure that both the client and the
  ///   implementation understand that dictionary keys should be case
  ///   insensitive, and are implemented as such.
  /// </summary>
  TCaseInsensitiveString = string;

  IVariantDictionary = interface
    ['{E6224B74-3AA6-45FF-8F4D-E0CCB137BE2D}']
    /// <summary>
    ///   Returns a value from the dictionary if it exists, but should not
    ///   touch the value already in AValue if the dictionary doesn't contain
    ///   this key.
    /// </summary>
    /// <param name="AKey">
    ///   Case insensitive retrieval key.
    /// </param>
    /// <param name="AValue">
    ///   The value, unchanged if the function returned False.
    /// </param>
    function TryGetValue( const AKey: TCaseInsensitiveString; var AValue: Variant ): boolean;
  end;

  IStringDictionary = interface
    ['{9D7A83E8-F796-45E1-A2E1-B9F5C50DAE9A}']
    function TryGetString( const AKey: TCaseInsensitiveString; var AValue: string ): boolean;
    /// <summary>
    ///   This is like TryGetString, except that it just returns an empty
    ///   string if there is nothing in the dictionary.
    /// </summary>
    function GetString( const AKey: TCaseInsensitiveString ): string;
  end;

  INumericDictionary = interface
    ['{B2854A94-5F75-40D6-9711-EB318BFA7DD5}']
    function TryGetNumber( const AKey: TCaseInsensitiveString; var AValue: Extended ): boolean;
  end;

  IDefaultProperty = interface
    ['{2A0DC3BB-C982-46B2-92C1-B920793E123C}']
    function DefaultProperty: Variant;
  end;

  IDataDictionary = interface
    ['{6EA87537-D992-45D2-AE3A-34F6E3897F53}']
    function TryGetData( const AVariableNumber: integer; out AData: Variant): boolean;
  end;

  IPeriodDictionary = interface
    ['{9ABCF5FD-688A-4D7A-9BB5-2833BC722474}']
    function TryGetPeriod( const AContext, ACaption: string; out AStartDate, AStopDate: TDateTime ): boolean;
  end;

implementation

end.
