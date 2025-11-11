


const enums_script = @import("../core/enums.zig");
const constants_script = @import("../core/language_constants.zig");
const printing_script = @import("../core/printing.zig");
const TokenType = enums_script.TokenType;
const twoSlicesAreTheSame = printing_script.twoSlicesAreTheSame;

pub fn getTokenType(input:[]const u8) TokenType {
    // Keywords
    if (twoSlicesAreTheSame(input, constants_script.FN)) return TokenType.Fn;
    if (twoSlicesAreTheSame(input, constants_script.IF)) return TokenType.If;
    if (twoSlicesAreTheSame(input, constants_script.ELSE)) return TokenType.Else;
    if (twoSlicesAreTheSame(input, constants_script.FOR)) return TokenType.For;
    if (twoSlicesAreTheSame(input, constants_script.WHILE)) return TokenType.While;
    if (twoSlicesAreTheSame(input, constants_script.RETURN)) return TokenType.Return;
    if (twoSlicesAreTheSame(input, constants_script.BREAK)) return TokenType.Break;
    if (twoSlicesAreTheSame(input, constants_script.CONTINUE)) return TokenType.Continue;
    if (twoSlicesAreTheSame(input, constants_script.PRINT)) return TokenType.Print;
    if (twoSlicesAreTheSame(input, constants_script.PRINTLN)) return TokenType.Println;
    if (twoSlicesAreTheSame(input, constants_script.TRUE)) return TokenType.True;
    if (twoSlicesAreTheSame(input, constants_script.FALSE)) return TokenType.False;
    if (twoSlicesAreTheSame(input, constants_script.IN)) return TokenType.In;
    if (twoSlicesAreTheSame(input, constants_script.DEFER)) return TokenType.Defer;
    if (twoSlicesAreTheSame(input, constants_script.NEW)) return TokenType.New;

    // Types
    if (twoSlicesAreTheSame(input, constants_script.U8)) return TokenType.u8;
    if (twoSlicesAreTheSame(input, constants_script.I8)) return TokenType.i8;
    if (twoSlicesAreTheSame(input, constants_script.I32)) return TokenType.i32;
    if (twoSlicesAreTheSame(input, constants_script.F32)) return TokenType.f32;
    if (twoSlicesAreTheSame(input, constants_script.F64)) return TokenType.f64;
    if (twoSlicesAreTheSame(input, constants_script.I64)) return TokenType.i64;
    if (twoSlicesAreTheSame(input, constants_script.U64)) return TokenType.u64;
    if (twoSlicesAreTheSame(input, constants_script.STRING)) return TokenType.String;
    if (twoSlicesAreTheSame(input, constants_script.BOOL)) return TokenType.Bool;
    if (twoSlicesAreTheSame(input, constants_script.CHAR)) return TokenType.Char;
    if (twoSlicesAreTheSame(input, constants_script.VOID)) return TokenType.Void;
    if (twoSlicesAreTheSame(input, constants_script.CONST)) return TokenType.Const;
    if (twoSlicesAreTheSame(input, constants_script.INT)) return TokenType.i32;
    if (twoSlicesAreTheSame(input, constants_script.USIZE)) return TokenType.Usize;

    // Operators
    if (twoSlicesAreTheSame(input, constants_script.PLUS_PLUS)) return TokenType.PlusPlus;
    if (twoSlicesAreTheSame(input, constants_script.PLUS)) return TokenType.Plus;
    if (twoSlicesAreTheSame(input, constants_script.MINUS)) return TokenType.Minus;
    if (twoSlicesAreTheSame(input, constants_script.MULTIPLY)) return TokenType.Multiply;
    if (twoSlicesAreTheSame(input, constants_script.DIVIDE)) return TokenType.Divide;
    if (twoSlicesAreTheSame(input, constants_script.EQUALS)) return TokenType.Equals;
    if (twoSlicesAreTheSame(input, constants_script.PLUS_EQUALS)) return TokenType.PlusEquals;
    if (twoSlicesAreTheSame(input, constants_script.MINUS_EQUALS)) return TokenType.MinusEquals;
    if (twoSlicesAreTheSame(input, constants_script.MULTIPLY_EQUALS)) return TokenType.MultiplyEquals;
    if (twoSlicesAreTheSame(input, constants_script.DIVIDE_EQUALS)) return TokenType.DivideEquals;
    if (twoSlicesAreTheSame(input, constants_script.GREATER_THAN)) return TokenType.GreaterThan;
    if (twoSlicesAreTheSame(input, constants_script.LESS_THAN)) return TokenType.LessThan;
    if (twoSlicesAreTheSame(input, constants_script.EQUALS_EQUALS)) return TokenType.EqualsEquals;
    if (twoSlicesAreTheSame(input, constants_script.GREATER_THAN_EQUALS)) return TokenType.GreaterThanEquals;
    if (twoSlicesAreTheSame(input, constants_script.LESS_THAN_EQUALS)) return TokenType.LessThanEquals;
    if (twoSlicesAreTheSame(input, constants_script.MODULUS)) return TokenType.Modulus;
    if (twoSlicesAreTheSame(input, constants_script.NOT_EQUALS)) return TokenType.NotEquals;
    if (twoSlicesAreTheSame(input, constants_script.AND)) return TokenType.And;
    if (twoSlicesAreTheSame(input, constants_script.AND_AND)) return TokenType.AndAnd;
    if (twoSlicesAreTheSame(input, constants_script.OR)) return TokenType.Or;
    if (twoSlicesAreTheSame(input, constants_script.OR_OR)) return TokenType.OrOr;
    if (twoSlicesAreTheSame(input, constants_script.MODULUS_EQUALS)) return TokenType.ModulusEquals;

    if (twoSlicesAreTheSame(input, constants_script.COMMENT)) return TokenType.Comment;
    if (twoSlicesAreTheSame(input, constants_script.DELETE)) return TokenType.Delete;

    // Parentheses and Brackets
    if (twoSlicesAreTheSame(input, constants_script.LEFT_PARENTHESIS)) return TokenType.LeftParenthesis;
    if (twoSlicesAreTheSame(input, constants_script.RIGHT_PARENTHESIS)) return TokenType.RightParenthesis;
    if (twoSlicesAreTheSame(input, constants_script.LEFT_BRACE)) return TokenType.LeftBrace;
    if (twoSlicesAreTheSame(input, constants_script.RIGHT_BRACE)) return TokenType.RightBrace;
    if (twoSlicesAreTheSame(input, constants_script.LEFT_SQUARE_BRACKET)) return TokenType.LeftSquareBracket;
    if (twoSlicesAreTheSame(input, constants_script.RIGHT_SQUARE_BRACKET)) return TokenType.RightSquareBracket;

    if (twoSlicesAreTheSame(input, constants_script.SEMICOLON)) return TokenType.Semicolon;
    if (twoSlicesAreTheSame(input, constants_script.COMMA)) return TokenType.Comma;
    if (twoSlicesAreTheSame(input, constants_script.FULL_STOP)) return TokenType.FullStop;

    if (twoSlicesAreTheSame(input, constants_script.COLON)) return TokenType.Colon;
    if (twoSlicesAreTheSame(input, constants_script.CASE)) return TokenType.Case;
    if (twoSlicesAreTheSame(input, constants_script.DEFAULT)) return TokenType.Default;
    if (twoSlicesAreTheSame(input, constants_script.SWITCH)) return TokenType.Switch;

    // Number literals
    if (isInteger(input)) return TokenType.IntegerValue;
    if (isDecimal(input)) return TokenType.DecimalValue;

    // String or Char value
    if (printing_script.contains(input, '"')) return TokenType.StringValue;
    if (printing_script.contains(input, '\'')) return TokenType.CharValue;

    return TokenType.Identifier;
}

pub fn isOperator(char:u8) bool {

    const LENGTH:usize = constants_script.OPERATORS.len;
    for (0..LENGTH) |i| {

        if (char == constants_script.OPERATORS[i]) {
            return true;
        }
    }
    return false;
}

pub fn isSeparator(char:u8) bool {

    const LENGTH:usize = constants_script.SEPERATORS.len;
    for (0..LENGTH) |i| {

        if (char == constants_script.SEPERATORS[i]) {
            return true;
        }
    }
    return false;
}

pub fn isInteger(input:[]const u8) bool {
    const LENGTH:usize = input.len;

    for (0..LENGTH) |i| {
        
        const char:u8 = input[i];
        if (input[i] == '-') {
            if (i != 0 ) {
                return false;
            }
            continue;
        }   
        if (isDigit(char) == false) {
            return false;
        }
    }
    return true;
}

pub fn isDecimal(input:[]const u8) bool {
    const LENGTH:usize = input.len;

    for (0..LENGTH) |i| {
        
        const char:u8 = input[i];
        if (input[i] == '-') {
            if (i != 0 ) {
                return false;
            }
            continue;
        }   
        if (input[i] == '.') {
            continue;
        }
        if (isDigit(char) == false) {
            return false;
        }
    }
    return true;
}

pub fn isLetterOrDigit(char: u8) bool {
    switch (char) {
        'a'...'z', 'A'...'Z', '0'...'9' => return true,
        else => return false,
    }
}

pub fn isDigit(char: u8) bool {
    switch (char) {
        '0'...'9' => return true,
        else => return false,
    }
}