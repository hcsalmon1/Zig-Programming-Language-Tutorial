const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const token_utils_script = @import("token_utils.zig");
const debugging_script = @import("../Debugging/debugging.zig");
const errors_script = @import("errors.zig");
const ast_utils_script = @import("../core/ast_utils.zig");
const print = std.debug.print;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const LoopResult = enums_script.LoopResult;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

                                               

pub fn parsePrimaryAny(allocator:*Allocator, ast_data:*ASTData, node_type: ASTNodeType) AstError!?*ASTNode {

    _ = node_type;
    if (ast_data.token_index >= ast_data.token_list.items.len) { 
        return AstError.Unexpected_End_Of_File;
    }

    const token:Token = ast_data.token_list.items[ast_data.token_index];
    var node:*ASTNode = ast_utils_script.createDefaultAstNode(allocator) catch {
        return AstError.Out_Of_Memory;
    };

    switch (token.Type) {

        //TokenType.False, TokenType.True => {
            //node.NodeType = ASTNodeType.BoolLiteral;
            //node.Token = token;
        //},
        TokenType.IntegerValue => {
            node.node_type = ASTNodeType.IntegerLiteral;
            node.token = token;
        },
        //TokenType.Identifier => try parseProcessIdentifier(ast_data, node, token, allocator),
        //TokenType.StringValue => {
            //node.NodeType = ASTNodeType.StringLiteral;
            //node.Token = token;
        //},
        //TokenType.CharValue => {
            //node.NodeType = ASTNodeType.CharLiteral;
            //node.Token = token;
        //},
        //TokenType.LeftParenthesis => return ProcessParsePrimaryLeftParenthesis(ast_data, node_type, allocator),
        //TokenType.RightParenthesis => return null,
        //TokenType.And => return ProcessReference(ast_data, token, allocator),
        //TokenType.Minus => return ProcessMinus(ast_data, token, allocator),
        else => { 
            ast_data.error_detail = "Unexpected type in expression, {token.Type}";
            ast_data.error_token = token;
            return AstError.Unexpected_Type;
        }
    }

    ast_data.token_index += 1;
    return node;
}

pub fn parseBinaryExprAny(allocator:*Allocator, ast_data:*ASTData, minPrec:usize, nodeType:ASTNodeType) AstError!*ASTNode {

    var left:?*ASTNode = try parsePrimaryAny(allocator, ast_data, nodeType);

    var whileCount:usize = 0;
    const MAX:usize = 1000;

    while (ast_data.token_index < ast_data.token_list.items.len) {

        if (debugging_script.isInfiniteWhileLoop(&whileCount, MAX) == true) {
            return AstError.Infinite_While_Loop;
        }

        const operator_token:Token = ast_data.token_list.items[ast_data.token_index];

        if (token_utils_script.isBinaryOperatorBool(operator_token.Type) == false) {
            break;
        }

        const precedence:usize = token_utils_script.getPrecedenceBool(operator_token.Type);

        if (precedence < minPrec) {
            break;
        }

        ast_data.token_index += 1; // move past operator
        const right:?*ASTNode = try parseBinaryExprAny(allocator, ast_data, precedence + 1, nodeType);

        if (right == null) {
            ast_data.error_detail = "Missing value after equation symbol";
            ast_data.error_token = operator_token;
            return AstError.Unexpected_Type;
        }

        var new_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);

        new_node.node_type = nodeType;
        new_node.token = operator_token;
        new_node.left = left;
        new_node.right = right;

        left = new_node;
    }
    return left.?;
}