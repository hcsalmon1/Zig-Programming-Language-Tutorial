

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const expressions_script = @import("../core/expression.zig");
const enums_script = @import("../core/enums.zig");
const errors_script = @import("../core/errors.zig");
const token_utils_script = @import("../core/token_utils.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ASTNode = structs_script.ASTNode;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const TokenType = enums_script.TokenType;
const AstError = errors_script.AstError;
const ASTNodeType = enums_script.ASTNodeType;
const Allocator = std.mem.Allocator;

pub fn processPointerDeclaration(allocator:*Allocator, ast_data:*ASTData, first_token:Token, is_global:bool, is_const:bool) !*ASTNode {
    //i32 number = 10;

    ast_data.error_function = "processPointerDeclaration";
    const type_node:?*ASTNode = try expressions_script.createComplexDeclarations(allocator, ast_data);

    const name_token:Token = try ast_data.getToken();

    if (name_token.Type != TokenType.Identifier) {
        ast_data.error_detail = "Expected varname after array type";
        return AstError.Missing_Expected_Type;
    }

    const equalsToken:Token = try ast_data.getNextToken(ast_data);

    if (equalsToken.Type != TokenType.Equals) {
        ast_data.ErrorDetail = "Expected equals after array name, uninitialised arrays not implemented yet";
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    const valueNode:*ASTNode = try expressions_script.parseBinaryExprAny(ast_data, 0, ASTNodeType.BinaryExpression, allocator);
    const end_token:Token = try ast_data.getToken();

    if (end_token.Type != TokenType.Semicolon) {

        ast_data.token_index -= 1;

        if (end_token.Type != TokenType.Semicolon) {
            ast_data.error_detail = "Missing expected ';' after declaration";
            return AstError.Missing_Expected_Type;
        }
    }
    ast_data.token_index += 1;

    type_node.?.Token = first_token;

    var node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    node.node_type = ASTNodeType.PointerDeclaration;
    node.token = name_token;
    node.left = type_node.?;
    node.right = valueNode;
    node.is_global = is_global;
    node.is_const = is_const;

    return node;
}