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
  Later
  * Refactored extensively.
  * Added date functions

  ========================================================================= }

interface

uses
  BitSoft.MathParser.StdFunctions,
  {Standard}
  System.SysUtils, System.DateUtils, System.Math;

type
  TTokenError = ( errNone = 0, errParserStack = 1, errBadRange = 2, errExpression = 3, errOperator = 4, errOpenParen = 5, errCloseParen = 6, errInvalidNum = 7 );

const
  PARSER_STACK_SIZE        = 32;
  MAX_FUNCTION_NAME_LENGTH = 24;
  EXP_LIMIT                = 11356;
  MAX_EXP_LENGTH           = 4;
  EULERS_NUMBER            = 2.7182818284590452353602874;

type

  TTokenType = ( ttAdd, ttSubtract, ttMultiply, ttDivide, ttExponentiate, ttParenthesisOpen, ttParenthesisClose, ttNumericValue, ttFunction, ttEndOfLine, ttBadToken, ttError, ttModulus );

  TTokenRecord = record
    State: Byte;
    case Byte of
      0: ( Value: Extended );
      2: ( FuncName: string[MAX_FUNCTION_NAME_LENGTH] );
  end; { TokenRec }

  TGetVarEvent = procedure( Sender: TObject; VarName: string; var Value: Extended; var Found: Boolean ) of object;

  TOnFunctionEvent = function( const FunctionName: string; const Value: Extended ): Extended of object;

  TMathParser = class;

  TParseErrorEvent = procedure( Sender: TMathParser; const TokenError: TTokenError ) of object;

  TMathParser = class( TStandardFunctions )
  strict private
    { Private declarations }
    fInput: string;
    fLogText: string;
    fOnGetVar: TGetVarEvent;
    fOnParseError: TParseErrorEvent;
    fParseValue: Extended;
    fParseError: Boolean;
    fTokenError: TTokenError;
    fCurrToken: TTokenRecord;
    fMathError: Boolean;
    fStack: array [1 .. PARSER_STACK_SIZE] of TTokenRecord;
    fStackTop: 0 .. PARSER_STACK_SIZE;
    fTokenLen: Word;
    fTokenType: TTokenType;
    fPosition: Word;
  private
    { Protected declarations }
    function GotoState( AProduction: Word ): Word;
    function IsCustomFunction: Boolean;
    function NextTokenIs( const AFunctionNameToLookFor: string ): Boolean;
    function NextTokenIsVariable( var AValue: Extended ): Boolean;
    function NextToken: TTokenType;
    procedure Pop( var AToken: TTokenRecord );
    procedure Push( const AToken: TTokenRecord );
    procedure Reduce( Reduction: Word );
    procedure Shift( State: Word );
    procedure ValidateInput( const AValue: string );
  public
    { Evaluation methods }
    function Evaluate: Extended; overload;
    function Evaluate( const AExpression: string ): Extended; overload;
    { Properties }
    property LogText: string read fLogText;
    property ParseError: Boolean read fParseError;
    property ParseValue: Extended read fParseValue;
    property TokenError: TTokenError read fTokenError;
    { Event hooks }
    property OnGetVar: TGetVarEvent read fOnGetVar write fOnGetVar;
    property OnParseError: TParseErrorEvent read fOnParseError write fOnParseError;
  end;

implementation

function TMathParser.GotoState( AProduction: Word ): Word;
{ Finds the new state based on the just-completed production and the top state. }
var
  State: Word;
begin
  GotoState := 0;
  State := fStack[fStackTop].State;
  if ( AProduction <= 3 ) then
  begin
    case State of
      0: GotoState := 1;
      9: GotoState := 19;
      20: GotoState := 28;
    end; { case }
  end
  else if AProduction <= 6 then
  begin
    case State of
      0, 9, 20: GotoState := 2;
      12: GotoState := 21;
      13: GotoState := 22;
    end; { case }
  end
  else if ( AProduction <= 8 ) or ( AProduction = 100 ) then
  begin
    case State of
      0, 9, 12, 13, 20: GotoState := 3;
      14: GotoState := 23;
      15: GotoState := 24;
      16: GotoState := 25;
      40: GotoState := 80;
    end; { case }
  end
  else if AProduction <= 10 then
  begin
    case State of
      0, 9, 12 .. 16, 20, 40: GotoState := 4;
    end; { case }
  end
  else if AProduction <= 12 then
  begin
    case State of
      0, 9, 12 .. 16, 20, 40: GotoState := 6;
      5: GotoState := 17;
    end; { case }
  end
  else
  begin
    case State of
      0, 5, 9, 12 .. 16, 20, 40: GotoState := 8;
    end; { case }
  end;
end; { GotoState }

function TMathParser.IsCustomFunction: Boolean;
var
  P, SLen: Integer;
  customFunctionName: string;
begin
  P := fPosition;
  customFunctionName := '';
  while ( P <= Length( fInput ) ) and CharInSet( fInput[P], ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '.'] ) do
  begin
    customFunctionName := customFunctionName + fInput[P];
    Inc( P );
  end;
  Result := FunctionExists( customFunctionName );
  if Result then
  begin
    SLen := Length( customFunctionName );
    fCurrToken.FuncName := UpperCase( Copy( fInput, fPosition, SLen ) );
    Inc( fPosition, SLen );
  end;
end;

function TMathParser.NextTokenIs( const AFunctionNameToLookFor: string ): Boolean;
{ Checks to see if the BitSoft.MathParser is about to read a function }
var
  P, functionLength: Integer;
  FunctionName: string;
begin
  P := fPosition;
  FunctionName := '';
  { Standard functions have A-Z in their names only }
  while ( P <= Length( fInput ) ) and CharInSet( fInput[P], ['A' .. 'Z', 'a' .. 'z'] ) do
  begin
    FunctionName := FunctionName + fInput[P];
    Inc( P );
  end;
  if SameText( FunctionName, AFunctionNameToLookFor ) then
  begin
    functionLength := Length( AFunctionNameToLookFor );
    fCurrToken.FuncName := UpperCase( Copy( fInput, fPosition, functionLength ) );
    Inc( fPosition, functionLength );
    Result := True;
  end
  else
    Result := False;
end;

function TMathParser.NextTokenIsVariable( var AValue: Extended ): Boolean;
var
  variableName: string;
begin
  Result := False;
  variableName := '';
  { Custom functions can have underscores and numbers as well }
  while ( fPosition <= Length( fInput ) ) and CharInSet( fInput[fPosition], ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '.'] ) do
  begin
    variableName := variableName + fInput[fPosition];
    Inc( fPosition );
  end; { while }
  if SameText( variableName, 'NOW' ) then
  begin
    AValue := Now;
    Result := True;
  end
  else if SameText( variableName, 'PI' ) then
  begin
    AValue := System.Pi;
    Result := True;
  end
  else if SameText( variableName, 'E' ) then
  begin
    AValue := EULERS_NUMBER;
    Result := True;
  end
  else
  begin
    if Assigned( fOnGetVar ) then
      fOnGetVar( Self, variableName, AValue, Result );
    if Result then
      fLogText := fLogText + Format( ' %s=%g', [variableName, AValue] )
    else
      fLogText := fLogText + ' #' + variableName + '#';
  end;
end;

function TMathParser.NextToken: TTokenType;
{ Gets the next Token from the Input stream }
var
  NumString: string;
  { FormLen, Place, } TLen, NumLen: Word;
  Check: Integer;
  Ch { , FirstChar } : Char;
  Decimal: Boolean;
begin
  NextToken := ttError;
  while ( fPosition <= Length( fInput ) ) and ( fInput[fPosition] in [' '] ) do
    Inc( fPosition );
  fTokenLen := fPosition;
  if fPosition > Length( fInput ) then
  begin
    NextToken := ttEndOfLine;
    fTokenLen := 0;
    Exit;
  end; { if }
  Ch := UpCase( fInput[fPosition] );
  if CharInSet( Ch, ['!'] ) then
  begin
    NextToken := ttError;
    fTokenLen := 0;
    Exit;
  end; { if }
  if CharInSet( Ch, ['0' .. '9', '.'] ) then
  begin
    NumString := '';
    TLen := fPosition;
    Decimal := False;
    while ( TLen <= Length( fInput ) ) and ( CharInSet( fInput[TLen], ['0' .. '9'] ) or ( ( fInput[TLen] = '.' ) and ( not Decimal ) ) ) do
    begin
      NumString := NumString + fInput[TLen];
      if Ch = '.' then
        Decimal := True;
      Inc( TLen );
    end; { while }
    if ( TLen = 2 ) and ( Ch = '.' ) then
    begin
      NextToken := ttBadToken;
      fTokenLen := 0;
      Exit;
    end; { if }
    if ( TLen <= Length( fInput ) ) and ( UpCase( fInput[TLen] ) = 'E' ) then
    begin
      NumString := NumString + 'E';
      Inc( TLen );
      if CharInSet( fInput[TLen], ['+', '-'] ) then
      begin
        NumString := NumString + fInput[TLen];
        Inc( TLen );
      end; { if }
      NumLen := 1;
      while ( TLen <= Length( fInput ) ) and CharInSet( fInput[TLen], ['0' .. '9'] ) and ( NumLen <= MAX_EXP_LENGTH ) do
      begin
        NumString := NumString + fInput[TLen];
        Inc( NumLen );
        Inc( TLen );
      end; { while }
    end; { if }
    if NumString[1] = '.' then
      NumString := '0' + NumString;
    Val( NumString, fCurrToken.Value, Check );
    if Check <> 0 then
    begin
      fMathError := True;
      fTokenError := errInvalidNum;
      Inc( fPosition, Pred( Check ) );
    end { if }
    else
    begin
      NextToken := ttNumericValue;
      Inc( fPosition, System.Length( NumString ) );
      fTokenLen := fPosition - fTokenLen;
    end; { else }
    Exit;
  end { if }
  else if CharInSet( Ch, ['a' .. 'z', 'A' .. 'Z'] ) then
  begin
    if NextTokenIs( 'ABS' ) or NextTokenIs( 'EXP' ) or NextTokenIs( 'LN' ) or NextTokenIs( 'ROUND' ) or NextTokenIs( 'TRUNC' ) or IsCustomFunction then
    begin
      NextToken := ttFunction;
      fTokenLen := fPosition - fTokenLen;
      Exit;
    end; { if }
    if NextTokenIs( 'MOD' ) then
    begin
      NextToken := ttModulus;
      fTokenLen := fPosition - fTokenLen;
      Exit;
    end; { if }
    if NextTokenIsVariable( fCurrToken.Value ) then
    begin
      NextToken := ttNumericValue;
      fTokenLen := fPosition - fTokenLen;
      Exit;
    end { if }
    else
    begin
      NextToken := ttBadToken;
      fTokenLen := 0;
      Exit;
    end; { else }
  end { if }
  else
  begin
    case Ch of
      '+': NextToken := ttAdd;
      '-': NextToken := ttSubtract;
      '*': NextToken := ttMultiply;
      '/': NextToken := ttDivide;
      '^': NextToken := ttExponentiate;
      '(': NextToken := ttParenthesisOpen;
      ')': NextToken := ttParenthesisClose;
    else
      begin
        NextToken := ttBadToken;
        fTokenLen := 0;
        Exit;
      end; { case else }
    end; { case }
    Inc( fPosition );
    fTokenLen := fPosition - fTokenLen;
    Exit;
  end; { else if }
end; { NextToken }

procedure TMathParser.Pop( var AToken: TTokenRecord );
{ Pops the top Token off of the stack }
begin
  AToken := fStack[fStackTop];
  Dec( fStackTop );
end; { Pop }

procedure TMathParser.Push( const AToken: TTokenRecord );
{ Pushes a new Token onto the stack }
begin
  if fStackTop = PARSER_STACK_SIZE then
    fTokenError := errParserStack
  else
  begin
    Inc( fStackTop );
    fStack[fStackTop] := AToken;
  end; { else }
end; { Push }

function TMathParser.Evaluate( const AExpression: string ): Extended;
begin
  ValidateInput( AExpression );
  Result := Evaluate;
end;

function TMathParser.Evaluate: Extended;
{ Parses an input stream }
var
  FirstToken: TTokenRecord;
  Accepted: Boolean;
begin
  fPosition := 1;
  fStackTop := 0;
  fTokenError := errNone;
  fMathError := False;
  fParseError := False;
  Accepted := False;
  FirstToken.State := 0;
  FirstToken.Value := 0;
  Push( FirstToken );
  fTokenType := NextToken;
  repeat
    case fStack[fStackTop].State of
      0, 9, 12 .. 16, 20, 40:
        begin
          if fTokenType = ttNumericValue then
            Shift( 10 )
          else if fTokenType = ttFunction then
            Shift( 11 )
          else if fTokenType = ttSubtract then
            Shift( 5 )
          else if fTokenType = ttParenthesisOpen then
            Shift( 9 )
          else if fTokenType = ttError then
          begin
            fMathError := True;
            Accepted := True;
          end { else if }
          else
          begin
            fTokenError := errExpression;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      1:
        begin
          if fTokenType = ttEndOfLine then
            Accepted := True
          else if fTokenType = ttAdd then
            Shift( 12 )
          else if fTokenType = ttSubtract then
            Shift( 13 )
          else
          begin
            fTokenError := errOperator;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      2:
        begin
          if fTokenType = ttMultiply then
            Shift( 14 )
          else if fTokenType = ttDivide then
            Shift( 15 )
          else
            Reduce( 3 );
        end; { case of }
      3:
        begin
          if fTokenType = ttModulus then
            Shift( 40 )
          else
            Reduce( 6 );
        end; { case of }
      4:
        begin
          if fTokenType = ttExponentiate then
            Shift( 16 )
          else
            Reduce( 8 );
        end; { case of }
      5:
        begin
          if fTokenType = ttNumericValue then
            Shift( 10 )
          else if fTokenType = ttFunction then
            Shift( 11 )
          else if fTokenType = ttParenthesisOpen then
            Shift( 9 )
          else
          begin
            fTokenError := errExpression;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      6: Reduce( 10 );
      7: Reduce( 13 );
      8: Reduce( 12 );
      10: Reduce( 15 );
      11:
        begin
          if fTokenType = ttParenthesisOpen then
            Shift( 20 )
          else
          begin
            fTokenError := errOpenParen;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      17: Reduce( 9 );
      18: raise Exception.Create( 'Bad token state' );
      19:
        begin
          if fTokenType = ttAdd then
            Shift( 12 )
          else if fTokenType = ttSubtract then
            Shift( 13 )
          else if fTokenType = ttParenthesisClose then
            Shift( 27 )
          else
          begin
            fTokenError := errCloseParen;
            Dec( fPosition, fTokenLen );
          end;
        end; { case of }
      21:
        begin
          if fTokenType = ttMultiply then
            Shift( 14 )
          else if fTokenType = ttDivide then
            Shift( 15 )
          else
            Reduce( 1 );
        end; { case of }
      22:
        begin
          if fTokenType = ttMultiply then
            Shift( 14 )
          else if fTokenType = ttDivide then
            Shift( 15 )
          else
            Reduce( 2 );
        end; { case of }
      23: Reduce( 4 );
      24: Reduce( 5 );
      25: Reduce( 7 );
      26: Reduce( 11 );
      27: Reduce( 14 );
      28:
        begin
          if fTokenType = ttAdd then
            Shift( 12 )
          else if fTokenType = ttSubtract then
            Shift( 13 )
          else if fTokenType = ttParenthesisClose then
            Shift( 29 )
          else
          begin
            fTokenError := errCloseParen;
            Dec( fPosition, fTokenLen );
          end; { else }
        end; { case of }
      29: Reduce( 16 );
      80: Reduce( 100 );
    end; { case }
  until Accepted or ( fTokenError <> errNone );
  if fTokenError <> errNone then
  begin
    if fTokenError = errBadRange then
      Dec( fPosition, fTokenLen );
    if Assigned( fOnParseError ) then
      fOnParseError( Self, fTokenError );
  end; { if }
  fParseError := fMathError or ( fTokenError <> errNone );
  if fParseError then
    fParseValue := 0
  else
    fParseValue := fStack[fStackTop].Value;
  Result := fParseValue;
end; { Parse }

procedure TMathParser.Reduce( Reduction: Word );
{ Completes a reduction }
var
  Token1, Token2: TTokenRecord;
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
        else if ( Token1.Value * Ln( Token2.Value ) < -EXP_LIMIT ) or ( Token1.Value * Ln( Token2.Value ) > EXP_LIMIT ) then
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
    11: raise Exception.Create( 'Invalid reduction' );
    13: raise Exception.Create( 'Invalid reduction' );
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
        else if Token1.FuncName = 'EXP' then
        begin
          if ( fCurrToken.Value < -EXP_LIMIT ) or ( fCurrToken.Value > EXP_LIMIT ) then
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
        else if Token1.FuncName = 'TRUNC' then
        begin
          if ( fCurrToken.Value < -1E9 ) or ( fCurrToken.Value > 1E9 ) then
            fMathError := True
          else
            fCurrToken.Value := Trunc( fCurrToken.Value );
        end
        else
          fCurrToken.Value := EvaluateFunction( Token1.FuncName, fCurrToken.Value )
      end;
    3, 6, 8, 10, 12, 15: Pop( fCurrToken );
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

procedure TMathParser.ValidateInput( const AValue: string );
var
  n: Integer;
  errMsg: string;
begin
  fInput := '';
  n := 1;
  while n <= Length( AValue ) do
  begin
    case AValue[n] of
      ' ', '+', '-', '*', '/', '!', '^', '(', ')', '_', '.', 'A' .. 'Z', 'a' .. 'z', '0' .. '9': fInput := fInput + AValue[n];
      #13, #10, #9: fInput := fInput + ' ';
    else
      begin
        errMsg := AValue;
        errMsg.Insert( n - 1, '!' );
        { } raise EInvalidArgument.CreateFmt( 'Invalid input at position %d in "%s" (at exclamation point).', [n, errMsg] );
      end;
    end;
    Inc( n );
  end;
  fLogText := fInput;
end;

end.
