const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ASTNode = structs_script.ASTNode;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const TokenType = enums_script.TokenType;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn fillStruct(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    const struct_member_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };
    struct_member_node.children = child_list;
    struct_member_node.node_type = ASTNodeType.StructMembers;
    
    while (ast_data.tokenIndexInBounds()) {

        const first_token:Token = try ast_data.getToken();

        if (first_token.Type == TokenType.RightBrace) {
            break;
        }

        const member_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
        const type_node:*ASTNode = try expressions_script.createComplexDeclarations(allocator, ast_data);

        const name_token:Token = try ast_data.getToken();

        if (name_token.Type != TokenType.Identifier) {
            ast_data.error_detail = "missing var name in declaration";
            ast_data.error_token = name_token;
            return AstError.Missing_Expected_Type;
        }
        member_node.node_type = ASTNodeType.StructMember;
        member_node.left = type_node;
        member_node.token = name_token;
        struct_member_node.*.children.?.append(allocator.*, member_node) catch return AstError.Out_Of_Memory;

        try ast_data.incrementIndex();
        try ast_data.expectType(TokenType.Semicolon, "Missing expected ';' in struct");
        try ast_data.incrementIndex();
    }
    return struct_member_node;
}

pub fn processStruct(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    //struct Thing {
    //   int value;
    //   string name;
    //}

    try ast_data.incrementIndex();
    const struct_name_token:Token = try ast_data.getToken();

    const struct_declaration_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    struct_declaration_node.node_type = ASTNodeType.StructDeclaration;
    struct_declaration_node.token = struct_name_token;

    try ast_data.incrementIndex();
    try ast_data.expectType(TokenType.LeftBrace, "Missing '{' after struct name");
    try ast_data.incrementIndex();

    const struct_member_node:*ASTNode = try fillStruct(allocator, ast_data);

    try ast_data.expectType(TokenType.RightBrace, "Missing '}' after struct name");
    ast_data.token_index += 1;

    struct_declaration_node.right = struct_member_node;

    return struct_declaration_node;
}