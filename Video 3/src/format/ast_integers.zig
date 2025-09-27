

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
//const token_utils_script = @import("../core/token_utils.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_utils_script = @import("../core/ast_utils.zig");
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;

pub fn getValueNodeI32(astData:*ASTData, allocator:*Allocator) !*ASTNode {

    const valueNode:*ASTNode = try expressions_script.parseBinaryExprAny(allocator, astData, 0, ASTNodeType.BinaryExpression);
    return valueNode;
}

fn processIntNoValue(allocator:*Allocator, ast_data:*ASTData, type_node:*ASTNode, second_token:Token, third_token:Token, is_global:bool) AstError!*ASTNode {
    //if not semicolon
    if (third_token.Type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected '=' or ';' in declaration";
        ast_data.error_token = third_token;
        return AstError.Unexpected_Type;
    }

    var default_text:[]u8 = allocator.alloc(u8, 1) catch return AstError.Out_Of_Memory;
    default_text[0] = '0';

    const var_node:*ASTNode =  try ast_utils_script.createDefaultAstNode(allocator);

    var_node.*.node_type = ASTNodeType.IntegerLiteral;
    var_node.*.token = .{ 
        .Text = default_text[0..], 
        .CharNumber = 0, 
        .LineNumber = 0, 
        .Type = TokenType.IntegerValue
    };

    var default_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
    
    default_node.node_type = ASTNodeType.Declaration;
    default_node.token = second_token;
    default_node.left = type_node;
    default_node.right = var_node;
    default_node.is_global = is_global;
    return default_node;
}

pub fn processIntDeclaration(allocator:*Allocator, ast_data:*ASTData, first_token:Token, is_global:bool, is_const:bool) AstError!*ASTNode {

    ast_data.error_function = "processIntDeclaration";

    const type_node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = first_token;

    //var name expected
    const second_token:Token = try ast_data.getNextToken();
    if (second_token.Type != TokenType.Identifier) {
        ast_data.error_detail = "Missing expected identifier in declaration";
        ast_data.error_token = second_token;
        return AstError.Unexpected_Type;
    }
    const third_token:Token = try ast_data.getNextToken();
    try ast_data.incrementIndex();
    
    //if not equals
    if (third_token.Type != TokenType.Equals) {
        return processIntNoValue(allocator, ast_data, type_node, second_token, third_token, is_global);
    }

    const valueNode:*ASTNode = try getValueNodeI32(ast_data, allocator);

    const fourth_token:Token = try ast_data.getToken();
    ast_data.token_index += 1;

    if (fourth_token.Type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected ';' in declaration";
        ast_data.error_token = fourth_token;
        return AstError.Unexpected_Type;
    }

    var node:*ASTNode = try ast_utils_script.createDefaultAstNode(allocator);

    node.node_type = ASTNodeType.Declaration;
    node.token = second_token;
    node.left = type_node;
    node.right = valueNode;
    node.is_global = is_global;
    node.is_const = is_const;

    return node;
}