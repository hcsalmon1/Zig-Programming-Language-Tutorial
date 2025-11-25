

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const debugging_script = @import("../Debugging/debugging.zig");
const errors_script = @import("../core/errors.zig");
const ast_utils_script = @import("ast_utils.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const expressions_script = @import("../core/expression.zig");
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

pub fn getValueNodeBool(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    return try expressions_script.parseBinaryExprAny(allocator, ast_data, 0, ASTNodeType.BoolExpression);
}

pub fn processBoolDeclaration(allocator:*Allocator, ast_data:*ASTData, first_token:Token, is_const:bool) AstError!*ASTNode {

    ast_data.error_function = "processBoolDeclaration";

    var type_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = first_token;

    ast_data.token_index += 1;
    const var_name_token:Token = try ast_data.getToken();
    ast_data.token_index += 1;

    const second_token:Token = try ast_data.getToken();

    const token_is_equals = second_token.Type == TokenType.Equals;

    //expect '='
    if (token_is_equals == false) {
        // or expect ';'
        if (second_token.Type != TokenType.Semicolon) {
            ast_data.error_detail = "Missing expected ';' or '='";
            return AstError.Missing_Expected_Type;
        }
        const false_node:*ASTNode = try ast_utils_script.createBoolLiteralNode(allocator, "false");

        const undefined_bool_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
        undefined_bool_node.node_type = ASTNodeType.Declaration;
        undefined_bool_node.token = var_name_token;
        undefined_bool_node.left = type_node;
        undefined_bool_node.right = false_node;
        undefined_bool_node.is_const = is_const;
        return undefined_bool_node;
    } 
    try ast_data.incrementIndex();

    const value_node = try getValueNodeBool(allocator, ast_data);

    const last_token:Token = try ast_data.getToken();
    if (last_token.Type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected ';'";
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    const bool_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    bool_node.node_type = ASTNodeType.Declaration;
    bool_node.token = var_name_token;
    bool_node.left = type_node;
    bool_node.right = value_node;
    bool_node.is_const = is_const;
    return bool_node;
}