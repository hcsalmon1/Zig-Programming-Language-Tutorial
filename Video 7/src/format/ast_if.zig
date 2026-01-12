
const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const debugging_script = @import("../Debugging/debugging.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ast_bools_script = @import("ast_bools.zig");
const ast_functions_script = @import("ast_functions.zig");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const ConvertData = structs_script.ConvertData;
const StringBuilder = structs_script.StringBuilder;
const TokenType = enums_script.TokenType;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;

pub fn processWhile(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {
    //if ( condition ) {
    //      body
    //}

    ast_data.error_function = "processWhile";

    var while_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    while_node.node_type = ASTNodeType.WhileLoop;

    const first_token:Token = try ast_data.getToken();
    if (first_token.Type != TokenType.While) {
        ast_data.error_detail = "missing 'if' in while";
        ast_data.error_token = first_token;
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    const second_token:Token = try ast_data.getToken();
    if (second_token.Type != TokenType.LeftParenthesis) {
        ast_data.error_detail = "missing initial '(' in while";
        ast_data.error_token = second_token;
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    //get if condition
    const condition_node:*ASTNode = try ast_bools_script.getValueNodeBool(allocator, ast_data);

    const right_parenth_token:Token = try ast_data.getToken();

    if (right_parenth_token.Type != TokenType.RightParenthesis) {

        ast_data.token_index += 1;
        const token_after_last:Token = try ast_data.getToken();

        if (token_after_last.Type == TokenType.RightParenthesis) {
            ast_data.error_detail = "missing ')' in while";
            ast_data.error_token = token_after_last;
            return AstError.Missing_Expected_Type;
        }
    }
    ast_data.token_index += 1;

    const left_brace_token:Token = try ast_data.getToken();
    if (left_brace_token.Type != TokenType.LeftBrace) {
        ast_data.error_detail = "missing '{' after ')' in while";
        ast_data.error_token = left_brace_token;
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    const body_node:*ASTNode = try ast_functions_script.buildBodyBlock(allocator, ast_data, ASTNodeType.WhileBody);
    while_node.right = body_node;

    //expect right brace
    const last_token:Token = try ast_data.getToken();
    ast_data.token_index += 1;

    if (last_token.Type != TokenType.RightBrace) {
        ast_data.error_detail = "missing closing '}' after while";
        ast_data.error_token = last_token;
        return AstError.Missing_Expected_Type;
    }

    while_node.left = condition_node;
    while_node.token = first_token;
    return while_node;
}

fn processElse(allocator:*Allocator, ast_data:*ASTData, body_node:*ASTNode, search_for_else:bool) AstError!void {

    ast_data.error_function = "processElse";

    const first_token:Token = try ast_data.getToken();

    if (first_token.Type != TokenType.Else) {
        return;
    }
    try ast_data.incrementIndex();
    
    //Expect 'If' or '{'
    const second_token:Token = try ast_data.getToken();

    if (second_token.Type == TokenType.If) {

        const else_if_block:*ASTNode = try processIf(allocator, ast_data, false);

        body_node.children.?.append(allocator.*, else_if_block) catch return AstError.Out_Of_Memory;
        try processElse(allocator, ast_data, body_node, search_for_else);
        return;
    }

    if (second_token.Type != TokenType.LeftBrace) {
        ast_data.error_token = second_token;
        ast_data.error_detail = "Missing '{' after else";
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    const else_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    else_node.node_type = ASTNodeType.Else;
    else_node.token = first_token;

    const else_body_node:*ASTNode = try ast_functions_script.buildBodyBlock(allocator, ast_data, ASTNodeType.ElseBody);
    else_node.right = else_body_node;

    try ast_data.expectType(TokenType.RightBrace, "missing expected '}' in else");
    ast_data.token_index += 1;

    body_node.children.?.append(allocator.*, else_node) catch return AstError.Out_Of_Memory;
}

//search for else should be false for nested else ifs
pub fn processIf(allocator:*Allocator, ast_data:*ASTData, search_for_else:bool) AstError!*ASTNode {
    //if ( condition ) {
    //      body
    //}

    ast_data.error_function = "processIf";

    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };
    var if_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    if_node.node_type = ASTNodeType.IfStatement;
    if_node.children = child_list;

    const first_token:Token = try ast_data.getToken();
    if (first_token.Type != TokenType.If) {
        ast_data.error_detail = "missing 'if' in if";
        ast_data.error_token = first_token;
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    try ast_data.expectType(TokenType.LeftParenthesis, "missing expected '(' in if");
    try ast_data.incrementIndex();

    //get if condition
    const condition_node:*ASTNode = try ast_bools_script.getValueNodeBool(allocator, ast_data);

    const right_parenth_token:Token = try ast_data.getToken();

    if (right_parenth_token.Type != TokenType.RightParenthesis) {

        ast_data.token_index += 1;
        const token_after_last:Token = try ast_data.getToken();

        if (token_after_last.Type == TokenType.RightParenthesis) {
            ast_data.error_detail = "missing ')' in if";
            ast_data.error_token = token_after_last;
            return AstError.Missing_Expected_Type;
        }
    }
    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftBrace, "missing expected '{' in if");
    try ast_data.incrementIndex();

    const body_node:*ASTNode = try ast_functions_script.buildBodyBlock(allocator, ast_data, ASTNodeType.IfBody);
    if_node.right = body_node;

    //expect right brace
    try ast_data.expectType(TokenType.RightBrace, "missing expected '}' in if");
    ast_data.token_index += 1;

    if (search_for_else == true) {
        try processElse(allocator, ast_data, if_node, search_for_else);
    }
    if_node.left = condition_node;
    if_node.token = first_token;
    return if_node;
}