
const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
//const token_utils_script = @import("../core/token_utils.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;


pub fn getStringValue(allocator:*Allocator, ast_data:*ASTData) !*ASTNode {

    const value_node:?*ASTNode = try expressions_script.parsePrimaryAny(allocator, ast_data);
    if (value_node) |val_node| {
        return val_node;
    }
    return AstError.Null_Type;
}

pub fn processStringDeclarations(allocator:*Allocator, ast_data:*ASTData, first_token:Token, is_const:bool) !*ASTNode {
    //string message = "Hello";

    ast_data.error_function = "processStringDeclarations";

    const var_name_token:Token = try ast_data.getNextToken();

    const equals_token:Token = try ast_data.getNextToken();
    if (equals_token.Type != TokenType.Equals) {
        ast_data.error_token = equals_token;
        ast_data.error_detail = "missing expected '=' in string declaration";
        return AstError.Missing_Expected_Type;
    }

    ast_data.token_index += 1;

    const string_declaration:*ASTNode =  try ast_node_utils_script.createDefaultAstNode(allocator);

    const type_node:*ASTNode =  try ast_node_utils_script.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = first_token;

    const value_node:*ASTNode = try getStringValue(allocator, ast_data);

    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in string declaration");
    ast_data.token_index += 1;

    string_declaration.node_type = ASTNodeType.Declaration;
    string_declaration.left = type_node;
    string_declaration.token = var_name_token;
    string_declaration.right = value_node;
    string_declaration.is_const = is_const;
    return string_declaration;
}

pub fn processCharDeclaration(allocator:*Allocator, ast_data:*ASTData, first_token:Token, is_const:bool) !*ASTNode {
    //char message = 'a';

    ast_data.error_function = "processCharDeclaration";

    const var_name_token:Token = try ast_data.getNextToken();

    const equals_token:Token = try ast_data.getNextToken();
    if (equals_token.Type != TokenType.Equals) {
        ast_data.error_token = equals_token;
        ast_data.error_detail = "missing expected '=' in char declaration";
        return AstError.Missing_Expected_Type;
    }

    ast_data.token_index += 1;

    const string_declaration:*ASTNode =  try ast_node_utils_script.createDefaultAstNode(allocator);

    const type_node:*ASTNode =  try ast_node_utils_script.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = first_token;

    const value_node:*ASTNode = try getStringValue(allocator, ast_data);

    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in char declaration");
    ast_data.token_index += 1;

    string_declaration.node_type = ASTNodeType.Declaration;
    string_declaration.left = type_node;
    string_declaration.token = var_name_token;
    string_declaration.right = value_node;
    string_declaration.is_const = is_const;
    return string_declaration;
}