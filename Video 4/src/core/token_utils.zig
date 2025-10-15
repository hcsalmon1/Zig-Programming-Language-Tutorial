

const std = @import("std");
const structs_script = @import("structs.zig");
const errors_script = @import("errors.zig");
const enums_script = @import("enums.zig");
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const AstError = errors_script.AstError;
const TokenType = enums_script.TokenType;



//get token - out of range error
pub fn getToken(astData:*const ASTData) !Token {

    if (astData.token_index >= astData.token_list.items.len) {
        return AstError.Index_Out_Of_Range;
    }
    return astData.token_list.items[astData.token_index];
}

pub fn getNextToken(astData:*ASTData) !Token {
    if (astData.token_index + 1 >= astData.token_list.items.len) {
        return AstError.Index_Out_Of_Range;
    }
    astData.token_index += 1;
    return astData.token_list.items[astData.token_index];
}

//Basically this could be a vartype or a custom type
pub fn isTypeToken(token: Token) bool {
    if (isVarType(token.Type) == true) {
        return true;
    }
    if (token.Type == TokenType.Identifier) {
        return true;
    }
    return false;
}

pub fn getTokenByIndex(astData:*const ASTData, index:usize) !Token {
    if (index >= astData.token_list.items.len) {
        return AstError.Index_Out_Of_Range;
    }
    return astData.token_list.items[index];
}

pub fn getExpectedToken(expectedType: TokenType, astData: ASTData) !Token {
    const token:Token = astData.TokenList[astData.TokenIndex];
    if (token.Type != expectedType) {
        return AstError.Missing_Expected_Type;
    }
    return token;
}

pub fn incrementIndex(astData:*ASTData) !void {
    if (astData.token_index + 1 >= astData.token_list.items.len) {
        return AstError.Index_Out_Of_Range;
    }
    astData.token_index += 1;
}

//false = error
pub fn incrementAndExpectType(astData:*const ASTData, expectedType: TokenType) !bool {
    if (astData.token_index + 1 >= astData.token_list.len) {
        return AstError.Index_Out_Of_Range;
    }
    astData.token_index += 1;
    return astData.token_list[astData.token_index].Type == expectedType;
}

pub fn getNearestToken(astData:*const ASTData) ?Token {
    var index:usize = astData.token_index;
    const count:usize = astData.token_list.items.len;
    while (index >= 0) {

        if (index >= count) {
            index -= 1;
            continue;
        }
        return astData.token_list.items[index];
    }
    return null;
}

//false = error
pub fn tokenIsCorrectType(tokenType:TokenType, expectedType:TokenType) bool {
    return tokenType == expectedType;
}

//false = error
pub fn expectToken(astData:*const ASTData, expectedType: TokenType) !bool {

    const token:Token = try getToken(astData);
    return token.Type == expectedType;
}

//false = error
pub fn checkTokenType(astData:*const ASTData, expectedType: TokenType) !bool {
    const token:Token = try getToken(astData); 
    return token.Value.Type == expectedType;
}

pub fn isBinaryOperator(tokenType:TokenType) bool {
    return tokenType == TokenType.Plus or
        tokenType == TokenType.Minus or
        tokenType == TokenType.Multiply or
        tokenType == TokenType.Divide;
}

pub fn isBinaryOperatorBool(tokenType: TokenType ) bool {
    return tokenType == TokenType.Plus or
        tokenType == TokenType.Minus or
        tokenType == TokenType.Multiply or
        tokenType == TokenType.Divide or
        tokenType == TokenType.AndAnd or
        tokenType == TokenType.OrOr or
        tokenType == TokenType.LessThan or
        tokenType == TokenType.LessThanEquals or
        tokenType == TokenType.GreaterThan or
        tokenType == TokenType.GreaterThanEquals or
        tokenType == TokenType.EqualsEquals or
        tokenType == TokenType.NotEquals;
}

pub fn isVarType(tokenType: TokenType) bool {

    return
        tokenType == TokenType.Bool or
        tokenType == TokenType.Char or
        tokenType == TokenType.Int or
        tokenType == TokenType.f32 or
        tokenType == TokenType.f64 or
        tokenType == TokenType.i16 or
        tokenType == TokenType.i32 or
        tokenType == TokenType.i64 or
        tokenType == TokenType.i8 or
        tokenType == TokenType.u16 or
        tokenType == TokenType.u32 or
        tokenType == TokenType.u64 or
        tokenType == TokenType.Usize or
        tokenType == TokenType.u8 or
        tokenType == TokenType.String or
        tokenType == TokenType.Void;
}

pub fn isIntegerVarType(tokenType: TokenType) bool {

    return
        tokenType == TokenType.Int or
        tokenType == TokenType.i16 or
        tokenType == TokenType.i32 or
        tokenType == TokenType.i64 or
        tokenType == TokenType.i8 or
        tokenType == TokenType.u16 or
        tokenType == TokenType.u32 or
        tokenType == TokenType.u64 or
        tokenType == TokenType.Usize or
        tokenType == TokenType.u8;
}

pub fn expectVarType(astData:*const ASTData, errorMessage:[]const u8) !void {
    const token:Token = try getToken(astData);
    if (token == null) {
        astData.ErrorDetail = errorMessage;
        astData.ErrorToken = getNearestToken(astData);
        return false;
    }
    if (isVarType(token.Value.Type) == false) {
        astData.ErrorDetail = errorMessage;
        astData.ErrorToken = getNearestToken(astData);
        return AstError.Missing_Expected_Type;
    }
    if (token.Value.Type == TokenType.Void) {
        astData.ErrorDetail = "vartype can't be 'void'";
        astData.ErrorToken = getNearestToken(astData);
        return AstError.Invalid_Declaration;
    }
    astData.TokenIndex += 1;
    return true;
}

//only sets an error if token is null or void
pub fn expectVarTypeNoError(astData:*ASTData) !bool {
    const token:Token = try getToken(astData);
    if (token == null) {
        astData.ErrorDetail = "Unexpected end of file";
        astData.ErrorToken = getNearestToken(astData);
        return false;
    }
    if (isVarType(token.Type) == false) {
        return false;
    }
    if (token.Value.Type == TokenType.Void) {
        astData.ErrorDetail = "vartype can't be 'void'";
        astData.ErrorToken = getNearestToken(astData);
        return AstError.Invalid_Declaration;
    }
    astData.token_index += 1;
    return true;
}

pub fn expectTokenTypes(astData:*ASTData, expectedType:TokenType, errorMessage:[]const u8) !void {
    const token:Token = getToken(astData) catch |err| {
        astData.ErrorDetail = errorMessage;
        astData.ErrorToken = getNearestToken(astData);
        return err;
    };

    if (expectedType == TokenType.IntegerVarType) {

        if (isIntegerVarType(token.Type) == true) {
            astData.token_index += 1;
            return;
        }
        astData.setErrorData(errorMessage, token);
        return AstError.Missing_Expected_Type;
    }
    if (token.Type != expectedType) {
        astData.setErrorData(errorMessage, token);
        return AstError.Missing_Expected_Type;
    }
    astData.token_index += 1;
}

pub fn expectTokenTypesNoError(astData:*ASTData, expectedType:TokenType) !bool {
    
    const token:Token = try getToken(astData);
    if (expectedType == TokenType.IntegerVarType) {

        if (isIntegerVarType(token.Type) == true) {
            astData.token_index += 1;
            return true;
        }
        return false;
    }
    if (token.Type != expectedType) {
        //Ast_Utils.setErrorData(ast_data, ASTResult.Missing_Expected_Type, error_message, token, "processIf");
        return false;
    }
    astData.token_index += 1;
    return true;
}

pub fn makeIntToken(text:[]const u8) Token {
    return Token {
        .Type = TokenType.IntegerValue,
        .Text = text,
    }; 
}

pub fn makeToken(text:[]const u8, _type:TokenType) Token {
    return Token {
        .Type = _type,
        .Text = text,
    }; 
}

pub fn parseIntFromToken(token:Token, astData:ASTData) !i32 {
    // if token == nil {
    //  ast_data.Error_detail = "token was nil";
    //AppendTraceAST(ast_data, "parseInt");
    //ast_data.Ast_error = AstError_Invalid_Declaration;
    //return -1;
    // }
    if (token.Type != TokenType.IntegerValue) {
        astData.ErrorDetail = "token was not an int";
        //astData.ErrorTrace.Add("parseInt");
        return AstError.Invalid_Declaration;
    }

    const integer:i32 = try std.fmt.parseInt(i32, token.Text, 10) catch {
        astData.ErrorDetail = "error parsing int {token.Text}";
        //astData.ErrorTrace.Add("parseInt");
        return AstError.Invalid_Declaration;
    };

    return integer;
}

pub fn getPrecedenceInt(tokenType: TokenType) usize {

    switch (tokenType) {
        TokenType.Identifier, TokenType.Multiply, TokenType.Divide => return 2,
        TokenType.Plus, TokenType.Minus => return 1,
        else => return 0,
    }
}

pub fn getPrecedenceBool(tokenType: TokenType) usize {
    
    switch (tokenType) {
        TokenType.OrOr => return 1, // lowest
        TokenType.AndAnd => return 2,
        TokenType.EqualsEquals, TokenType.NotEquals => return 3,
        TokenType.LessThan, TokenType.GreaterThan, TokenType.LessThanEquals, TokenType.GreaterThanEquals => return 4,
        TokenType.Plus, TokenType.Minus => return 5,
        TokenType.Multiply, TokenType.Divide => return 6,
        else => return 0,
    }
}

pub fn isAssignmentToken(_type: TokenType) bool {
    return
        _type == TokenType.Equals or
        _type == TokenType.PlusEquals or
        _type == TokenType.MinusEquals or
        _type == TokenType.MultiplyEquals or
        _type == TokenType.DivideEquals or
        _type == TokenType.ModulusEquals;
}