

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const token_utils_script = @import("../core/token_utils.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ast_integers_script = @import("ast_integers.zig");
const ast_pointer_script = @import("ast_pointers.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;

pub fn processReturn(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    ast_data.error_function = "processReturn";

    const return_token:Token = try ast_data.getToken();
    ast_data.token_index += 1;
    const value_node:*ASTNode = try expressions_script.parseBinaryExprAny(
        allocator,
        ast_data, 
        0, //min precedence
        ASTNodeType.ReturnExpression, 
    );

    const semicolon_token:Token = try ast_data.getToken();
    if (semicolon_token.Type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected ';'";
        return AstError.Missing_Expected_Type;
    }
    ast_data.token_index += 1;

    const return_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    return_node.node_type = ASTNodeType.Return;
    return_node.token = return_token;
    return_node.right = value_node;
    return return_node;
}