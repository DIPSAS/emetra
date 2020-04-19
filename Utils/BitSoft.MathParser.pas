{$WARNINGS OFF}
unit BitSoft.MathParser;

{ =========================================================================
  Expression Evaluator v1.4 for Delphi                                    *
  (16 & 32 bits)                                                          *
  *
  Copyright © 1997 by BitSoft Development, L.L.C.                         *
  All rights reserved                                                     *
  *
  Web:     http://www.bitsoft.com                                         *
  E-mail:  info@bitsoft.com                                               *
  Support: tech-support@bitsoft.com                                       *
  -------------------------------------------------------------------------*
  Portions Copyright © 1992 by Borland International, Inc.                *
  All rights reserved                                                     *
  -------------------------------------------------------------------------*
  This file is distributed as freeware and without warranties of any kind.*
  You can use it in your own applications at your own risk.               *
  See the License Agreement for more information.                         *

  Changes By magne Rekdal:

  History:
  October 2, 2006:
  * Added some synonyms
  November 31, 2004:
  * Added Owner property
  October 31, 2004:
  * Removed D32 resource and Register function.
  October 10, 2001:
  * Added SIGN function
  2002
  * Added IS0 function
  October 4, 2004
  * Added IS_ZERO and IS_NULL function alias
  * Added HAS_DATA function with alias IS_POSITIVE

  ========================================================================= }

interface

uses
  BitSoft.MathParser.StdFunctions,
{$IFDEF Win32}
  Windows,
{$ELSE}
  WinProcs, Wintypes,
{$ENDIF}
  System.SysUtils, System.DateUtils, System.Math;

const
  ParserStackSize = 24;
  MaxFuncNameLen  = 16;
  ExpLimit        = 11356;
  SqrLimit        = 1E2466;
  MaxExpLen       = 4;

  ErrParserStack  = 1;
  ErrBadRange     = 2;
  ErrExpression   = 3;
  ErrOperator     = 4;
  ErrOpenParen    = 5;
  ErrOpCloseParen = 6;
  ErrInvalidNum   = 7;
  TotalErrors     = 7;

type
  TErrorRange = 0 .. TotalErrors;

  TokenTypes = ( Plus, Minus, Times, Divide, Expo, OParen, CParen, Num, Func, EOL, Bad, ERR, Modu );

  TokenRec = record
    State: Byte;
    case Byte of
      0:
        ( Value: Extended );
      2:
        ( FuncName: String[ MaxFuncNameLen ] );
  end; { TokenRec }

  TMathParser = class;
  TGetVarEvent = procedure( Sender: TObject; VarName: string; var Value: Extended; var Found: Boolean ) of object;

  TOnFunctionEvent = function( const AFunctionName: string; const Value: Extended ): Extended of object;

  TParseErrorEvent = procedure( Sender: TMathParser; const ParseError: Integer ) of object;

  TMathParser = class( TStdFunctions )
  private
    { Private declarations }
    fInput: string;
    fLogText: string;
    FOnGetVar: TGetVarEvent;
    FOnParseError: TParseErrorEvent;
    FParseValue: Extended;
    FParseError: Boolean;
    FTokenError: TErrorRange;
    fCurrToken: TokenRec;
    fMathError: Boolean;
    fStack: array [ 1 .. ParserStackSize ] of TokenRec;
    fStackTop: 0 .. ParserStackSize;
    fTokenLen: Word;
    fTokenType: TokenTypes;
    fPosition: Word;
  protected
    { Protected declarations }
    function GotoState( Production: Word ): Word;
    function IsCustomFunc: Boolean;
    function IsStandardFunc( const s: String ): Boolean;
    function IsVar( var Value: Extended ): Boolean;
    function NextToken: TokenTypes;
    procedure Push( Token: TokenRec );
    procedure Pop( var Token: TokenRec );
    procedure Reduce( Reduction: Word );
    procedure Shift( State: Word );
    procedure SetInput( const AValue: string );
  public
    { Public declarations }
    procedure AfterConstruction; override;
    function Parse: Extended;
    property OnGetVar: TGetVarEvent read FOnGetVar write FOnGetVar;
    property OnParseError: TParseErrorEvent read FOnParseError write FOnParseError;
    property ParseString: string read fInput write SetInput;
    property ParseError: Boolean read FParseError;
    property ParseValue: Extended read FParseValue;
    property TokenError: TErrorRange read FTokenError;
    property LogText: string read fLogText;
  end;

implementation

procedure TMathParser.AfterConstruction;
begin
  inherited;
  fInput := '';
end;

function TMathParser.GotoState( Production: Word ): Word;
{ Finds the new state based on the just-completed production and the
  top state. }
var
  State: Word;
begin
  GotoState := 0;
  State := fStack[ fStackTop ].State;
  if ( Production <= 3 ) then
  begin
    case State of
      0:
        GotoState := 1;
      9:
        GotoState := 19;
      20:
        GotoState := 28;
    end; { case }
  end
  else if Production <= 6 then
  begin
    case State of
      0, 9, 20:
        GotoState := 2;
      12:
        GotoState := 21;
      13:
        GotoState := 22;
    end; { case }
  end
  else if ( Production <= 8 ) or ( Production = 100 ) then
  begin
    case State of
      0, 9, 12, 13, 20:
        GotoState := 3;
      14:
        GotoState := 23;
      15:
        GotoState := 24;
      16:
        GotoState := 25;
      40:
        GotoState := 80;
    end; { case }
  end
  else if Production <= 10 then
  begin
    case State of
      0, 9, 12 .. 16, 20, 40:
        GotoState := 4;
    end; { case }
  end
  else if Production <= 12 then
  begin
    case State of
      0, 9, 12 .. 16, 20, 40:
        GotoState := 6;
      5:
        GotoState := 17;
    end; { case }
  end
  else
  begin
    case State of
      0, 5, 9, 12 .. 16, 20, 40:
        GotoState := 8;
    end; { case }
  end;
end; { GotoState }

function TMathParser.IsCustomFunc: Boolean;
var
  P, SLen: Integer;
  customFunctionName: string;
  foundAt: Integer;
begin
  P := fPosition;
  customFunctionName := '';
  while ( P <= Length( fInput ) ) and CharInSet( fInput[ P ], [ 'A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '.' ] ) do
  begin
    customFunctionName := customFunctionName + fInput[ P ];
    Inc( P );
  end;
  { if Valid function }
  Result := FFunctionNames.Find( customFunctionName, foundAt );
  if Result then
  begin
    SLen := Length( customFunctionName );
    fCurrToken.FuncName := UpperCase( Copy( fInput, fPosition, SLen ) );
    Inc( fPosition, SLen );
  end;
end;

function TMathParser.IsStandardFunc( const s: String ): Boolean;
{ Checks to see if the BitSoft.MathParser is about to read a function }
var
  P, SLen: Integer;
  FuncName: string;
begin
  P := fPosition;
  FuncName := '';
  while ( P <= Length( fInput ) ) and CharInSet( fInput[ P ], [ 'A' .. 'Z', 'a' .. 'z' ] ) do
  begin
    FuncName := FuncName + fInput[ P ];
    Inc( P );
  end;
  if UpperCase( FuncName ) = s then
  begin
    SLen := Length( s );
    fCurrToken.FuncName := UpperCase( Copy( fInput, fPosition, SLen ) );
    Inc( fPosition, SLen );
    Result := True;
  end
  else
    Result := False;
end;

function TMathParser.IsVar( var Value: Extended ): Boolean;
var
  VarName: string;
begin
  Result := False;
  VarName := '';
  while ( fPosition <= Length( fInput ) ) and CharInSet( fInput[ fPosition ], [ 'A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '.' ] ) do
  begin
    VarName := VarName + fInput[ fPosition ];
    Inc( fPosition );
  end; { while }
  if SameText( VarName, 'NOW' ) then
  begin
    Value := Now;
    Result := True;
  end
  else
  begin
    if Assigned( FOnGetVar ) then
      FOnGetVar( Self, VarName, Value, Result );
    if Result then
      fLogText := fLogText + Format( ' %s=%g', [ VarName, Value ] )
    else
      fLogText := fLogText + ' #' + VarName + '#';
  end;
end; { IsVar }

function TMathParser.NextToken: TokenTypes;
{ Gets the next Token from the Input stream }
var
  NumString: string;
  { FormLen, Place, } TLen, NumLen: Word;
  Check: Integer;
  Ch { , FirstChar } : Char;
  Decimal: Boolean;
begin
  NextToken := ERR;
  while ( fPosition <= Length( fInput ) ) and ( fInput[ fPosition ] in [ ' ' ] ) do
    Inc( fPosition );
  fTokenLen := fPosition;
  if fPosition > Length( fInput ) then
  begin
    NextToken := EOL;
    fTokenLen := 0;
    Exit;
  end; { if }
  Ch := UpCase( fInput[ fPosition ] );
  if CharInSet( Ch, [ '!' ] ) then
  begin
    NextToken := ERR;
    fTokenLen := 0;
    Exit;
  end; { if }
  if CharInSet( Ch, [ '0' .. '9', '.' ] ) then
  begin
    NumString := '';
    TLen := fPosition;
    Decimal := False;
    while ( TLen <= Length( fInput ) ) and ( CharInSet( fInput[ TLen ], [ '0' .. '9' ] ) or
      ( ( fInput[ TLen ] = '.' ) and ( not Decimal ) ) ) do
    begin
      NumString := NumString + fInput[ TLen ];
      if Ch = '.' then
        Decimal := True;
      Inc( TLen );
    end; { while }
    if ( TLen = 2 ) and ( Ch = '.' ) then
    begin
      NextToken := Bad;
      fTokenLen := 0;
      Exit;
    end; { if }
    if ( TLen <= Length( fInput ) ) and ( UpCase( fInput[ TLen ] ) = 'E' ) then
    begin
      NumString := NumString + 'E';
      Inc( TLen );
      if CharInSet( fInput[ TLen ], [ '+', '-' ] ) then
      begin
        NumString := NumString + fInput[ TLen ];
        Inc( TLen );
      end; { if }
      NumLen := 1;
      while ( TLen <= Length( fInput ) ) and CharInSet( fInput[ TLen ], [ '0' .. '9' ] ) and ( NumLen <= MaxExpLen ) do
      begin
        NumString := NumString + fInput[ TLen ];
        Inc( NumLen );
        Inc( TLen );
      end; { while }
    end; { if }
    if NumString[ 1 ] = '.' then
      NumString := '0' + NumString;
    Val( NumString, fCurrToken.Value, Check );
    if Check <> 0 then
    begin
      fMathError := True;
      FTokenError := ErrInvalidNum;
      Inc( fPosition, Pred( Check ) );
    end { if }
    else
    begin
      NextToken := Num;
      Inc( fPosition, System.Length( NumString ) );
      fTokenLen := fPosition - fTokenLen;
    end; { else }
    Exit;
  end { if }
  else if CharInSet( Ch, [ 'a' .. 'z', 'A' .. 'Z' ] ) then
  begin
    if IsStandardFunc( 'ABS' ) or IsStandardFunc( 'ATAN' ) or IsStandardFunc( 'TAN' ) or IsStandardFunc( 'COS' ) or
      IsStandardFunc( 'EXP' ) or IsStandardFunc( 'LN' ) or IsStandardFunc( 'ROUND' ) or IsStandardFunc( 'SIGN' ) or
      IsStandardFunc( 'SIN' ) or IsStandardFunc( 'SQRT' ) or IsStandardFunc( 'SQR' ) or IsStandardFunc( 'TRUNC' ) or IsCustomFunc
    then
    begin
      NextToken := Func;
      fTokenLen := fPosition - fTokenLen;
      Exit;
    end; { if }
    if IsStandardFunc( 'MOD' ) then
    begin
      NextToken := Modu;
      fTokenLen := fPosition - fTokenLen;
      Exit;
    end; { if }
    if IsVar( fCurrToken.Value ) then
    begin
      NextToken := Num;
      fTokenLen := fPosition - fTokenLen;
      Exit;
    end { if }
    else
    begin
      NextToken := Bad;
      fTokenLen := 0;
      Exit;
    end; { else }
  end { if }
  else
  begin
    case Ch of
      '+':
        NextToken := Plus;
      '-':
        NextToken := Minus;
      '*':
        NextToken := Times;
      '/':
        NextToken := Divide;
      '^':
        NextToken := Expo;
      '(':
        NextToken := OParen;
      ')':
        NextToken := CParen;
    else
      begin
        NextToken := Bad;
        fTokenLen := 0;
        Exit;
      end; { case else }
    end; { case }
    Inc( fPosition );
    fTokenLen := fPosition - fTokenLen;
    Exit;
  end; { else if }
end; { NextToken }

procedure TMathParser.Pop( var Token: TokenRec );
{ Pops the top Token off of the stack }
begin
  Token := fStack[ fStackTop ];
  Dec( fStackTop );
end; { Pop }

procedure TMathParser.Push( Token: TokenRec );
{ Pushes a new Token onto the stack }
begin
  if fStackTop = ParserStackSize then
    FTokenError := ErrParserStack
  else
  begin
    Inc( fStackTop );
    fStack[ fStackTop ] := Token;
  end; { else }
end; { Push }

function TMathParser.Parse: Extended;
{ Parses an input stream }
var
  FirstToken: TokenRec;
  Accepted: Boolean;
begin
  inherited;
  fPosition := 1;
  fStackTop := 0;
  FTokenError := 0;
  fMathError := False;
  FParseError := False;
  Accepted := False;
  FirstToken.State := 0;
  FirstToken.Value := 0;
  Push( FirstToken );
  fTokenType := NextToken;
  repeat
    case fStack[ fStackTop ].State of
      0, 9, 12 .. 16, 20, 40:
        begin
          if fTokenType = Num then
            Shift( 10 )
          else if fTokenType = Func then
            Shift( 11 )
          else if fTokenType = Minus then
            Shift( 5 )
          else if fTokenType = OParen then
            Shift( 9 )
          else if fTokenType = ERR then
          begin
            fMathError := True;
            Accepted := True;
          end { else if }
          else
          begin
            FTokenError := ErrExpression;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      1:
        begin
          if fTokenType = EOL then
            Accepted := True
          else if fTokenType = Plus then
            Shift( 12 )
          else if fTokenType = Minus then
            Shift( 13 )
          else
          begin
            FTokenError := ErrOperator;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      2:
        begin
          if fTokenType = Times then
            Shift( 14 )
          else if fTokenType = Divide then
            Shift( 15 )
          else
            Reduce( 3 );
        end; { case of }
      3:
        begin
          if fTokenType = Modu then
            Shift( 40 )
          else
            Reduce( 6 );
        end; { case of }
      4:
        begin
          if fTokenType = Expo then
            Shift( 16 )
          else
            Reduce( 8 );
        end; { case of }
      5:
        begin
          if fTokenType = Num then
            Shift( 10 )
          else if fTokenType = Func then
            Shift( 11 )
          else if fTokenType = OParen then
            Shift( 9 )
          else
          begin
            FTokenError := ErrExpression;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      6:
        Reduce( 10 );
      7:
        Reduce( 13 );
      8:
        Reduce( 12 );
      10:
        Reduce( 15 );
      11:
        begin
          if fTokenType = OParen then
            Shift( 20 )
          else
          begin
            FTokenError := ErrOpenParen;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      17:
        Reduce( 9 );
      18:
        raise Exception.Create( 'Bad token state' );
      19:
        begin
          if fTokenType = Plus then
            Shift( 12 )
          else if fTokenType = Minus then
            Shift( 13 )
          else if fTokenType = CParen then
            Shift( 27 )
          else
          begin
            FTokenError := ErrOpCloseParen;
            Dec( fPosition, fTokenLen );
          end;
        end; { case of }
      21:
        begin
          if fTokenType = Times then
            Shift( 14 )
          else if fTokenType = Divide then
            Shift( 15 )
          else
            Reduce( 1 );
        end; { case of }
      22:
        begin
          if fTokenType = Times then
            Shift( 14 )
          else if fTokenType = Divide then
            Shift( 15 )
          else
            Reduce( 2 );
        end; { case of }
      23:
        Reduce( 4 );
      24:
        Reduce( 5 );
      25:
        Reduce( 7 );
      26:
        Reduce( 11 );
      27:
        Reduce( 14 );
      28:
        begin
          if fTokenType = Plus then
            Shift( 12 )
          else if fTokenType = Minus then
            Shift( 13 )
          else if fTokenType = CParen then
            Shift( 29 )
          else
          begin
            FTokenError := ErrOpCloseParen;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      29:
        Reduce( 16 );
      80:
        Reduce( 100 );
    end; { case }
  until Accepted or ( FTokenError <> 0 );
  if FTokenError <> 0 then
  begin
    if FTokenError = ErrBadRange then
      Dec( fPosition, fTokenLen );
    if Assigned( FOnParseError ) then
      FOnParseError( Self, FTokenError );
  end; { if }
  FParseError := fMathError or ( FTokenError <> 0 );
  if FParseError then
    FParseValue := 0
  else
    FParseValue := fStack[ fStackTop ].Value;
  Result := FParseValue;
end; { Parse }

procedure TMathParser.Reduce( Reduction: Word );
{ Completes a reduction }
var
  Token1, Token2: TokenRec;
begin
  case Reduction of
    1:
      begin
        Pop( Token1 );
        Pop( Token2 );
        Pop( Token2 );
        fCurrToken.Value := Token1.Value + Token2.Value;
      end;
    2:
      begin
        Pop( Token1 );
        Pop( Token2 );
        Pop( Token2 );
        fCurrToken.Value := Token2.Value - Token1.Value;
      end;
    4:
      begin
        Pop( Token1 );
        Pop( Token2 );
        Pop( Token2 );
        fCurrToken.Value := Token1.Value * Token2.Value;
      end;
    5:
      begin
        Pop( Token1 );
        Pop( Token2 );
        Pop( Token2 );
        if Token1.Value = 0 then
          fMathError := True
        else
          fCurrToken.Value := Token2.Value / Token1.Value;
      end;

    { MOD operator }
    100:
      begin
        Pop( Token1 );
        Pop( Token2 );
        Pop( Token2 );
        if Token1.Value = 0 then
          fMathError := True
        else
          fCurrToken.Value := Round( Token2.Value ) mod Round( Token1.Value );
      end;

    7:
      begin
        Pop( Token1 );
        Pop( Token2 );
        Pop( Token2 );
        if Token2.Value <= 0 then
          fMathError := True
        else if ( Token1.Value * Ln( Token2.Value ) < -ExpLimit ) or ( Token1.Value * Ln( Token2.Value ) > ExpLimit ) then
          fMathError := True
        else
          fCurrToken.Value := Exp( Token1.Value * Ln( Token2.Value ) );
      end;
    9:
      begin
        Pop( Token1 );
        Pop( Token2 );
        fCurrToken.Value := -Token1.Value;
      end;
    11:
      raise Exception.Create( 'Invalid reduction' );
    13:
      raise Exception.Create( 'Invalid reduction' );
    14:
      begin
        Pop( Token1 );
        Pop( fCurrToken );
        Pop( Token1 );
      end;
    16:
      begin
        Pop( Token1 );
        Pop( fCurrToken );
        Pop( Token1 );
        Pop( Token1 );
        if Token1.FuncName = 'ABS' then
          fCurrToken.Value := Abs( fCurrToken.Value )
        else if Token1.FuncName = 'ATAN' then
          fCurrToken.Value := ArcTan( fCurrToken.Value )
        else if SameText( Token1.FuncName, 'TAN' ) then
          fCurrToken.Value := Tan( fCurrToken.Value )
        else if Token1.FuncName = 'COS' then
        begin
          if ( fCurrToken.Value < -9E18 ) or ( fCurrToken.Value > 9E18 ) then
            fMathError := True
          else
            fCurrToken.Value := Cos( fCurrToken.Value )
        end
        else if Token1.FuncName = 'EXP' then
        begin
          if ( fCurrToken.Value < -ExpLimit ) or ( fCurrToken.Value > ExpLimit ) then
            fMathError := True
          else
            fCurrToken.Value := Exp( fCurrToken.Value );
        end
        else if Token1.FuncName = 'LN' then
        begin
          if fCurrToken.Value <= 0 then
            fMathError := True
          else
            fCurrToken.Value := Ln( fCurrToken.Value );
        end
        else if Token1.FuncName = 'ROUND' then
        begin
          if ( fCurrToken.Value < -1E9 ) or ( fCurrToken.Value > 1E9 ) then
            fMathError := True
          else
            fCurrToken.Value := Round( fCurrToken.Value );
        end
        else if Token1.FuncName = 'SIN' then
        begin
          if ( fCurrToken.Value < -9E18 ) or ( fCurrToken.Value > 9E18 ) then
            fMathError := True
          else
            fCurrToken.Value := Sin( fCurrToken.Value )
        end
        else if Token1.FuncName = 'SQRT' then
        begin
          if fCurrToken.Value < 0 then
            fMathError := True
          else
            fCurrToken.Value := Sqrt( fCurrToken.Value );
        end
        else if Token1.FuncName = 'SQR' then
        begin
          if ( fCurrToken.Value < -SqrLimit ) or ( fCurrToken.Value > SqrLimit ) then
            fMathError := True
          else
            fCurrToken.Value := Sqr( fCurrToken.Value );
        end
        else if Token1.FuncName = 'TRUNC' then
        begin
          if ( fCurrToken.Value < -1E9 ) or ( fCurrToken.Value > 1E9 ) then
            fMathError := True
          else
            fCurrToken.Value := Trunc( fCurrToken.Value );
        end
        else
          fCurrToken.Value := Evaluate( Token1.FuncName, fCurrToken.Value )
      end;
    3, 6, 8, 10, 12, 15:
      Pop( fCurrToken );
  end; { case }
  fCurrToken.State := GotoState( Reduction );
  Push( fCurrToken );
end; { Reduce }

procedure TMathParser.Shift( State: Word );
{ Shifts a Token onto the stack }
begin
  fCurrToken.State := State;
  Push( fCurrToken );
  fTokenType := NextToken;
end; { Shift }

procedure TMathParser.SetInput( const AValue: string );
var
  n: Integer;
begin
  fInput := '';
  n := 1;
  while n <= Length( AValue ) do
  begin
    case AValue[ n ] of
      ' ', '+', '-', '*', '/', '!', '^', '(', ')', '_', '.', 'A' .. 'Z', 'a' .. 'z', '0' .. '9':
        fInput := fInput + AValue[ n ];
      #13, #10, #9:
        fInput := fInput + ' ';
    else
      raise Exception.CreateFmt( '%s.SetInput("%s") ', [ ClassName, Copy( AValue, 1, 24 ), n ] );
    end;
    Inc( n );
  end;
  fLogText := fInput;
end;

end.
