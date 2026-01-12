

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const errors_script = @import("errors.zig");
const ASTNode = structs_script.ASTNode;
const Allocator = std.mem.Allocator;
const ASTNodeType = enums_script.ASTNodeType;
const Token = structs_script.Token;
const AstError = errors_script.AstError;

pub fn createASTNode(
    allocator:*Allocator,
    node_type:ASTNodeType,
    token:Token,
    left:?*ASTNode,
    middle:?*ASTNode,
    right:?*ASTNode,
    children: ?*std.ArrayList(*ASTNode),
    is_array:bool,
    is_global:bool,
    is_const:bool,
    size:usize,
) !*ASTNode {
    var node:*ASTNode = try allocator.*.create(ASTNode);
    node.node_type = node_type;
    node.token = token;
    node.left = left;
    node.middle = middle;
    node.right = right;
    node.children = children;
    node.is_array = is_array;
    node.is_global = is_global;
    node.is_const = is_const;
    node.size = size;

    return node;
}

pub fn createDefaultAstNode(allocator:*Allocator) AstError!*ASTNode {
    var node:*ASTNode = allocator.*.create(ASTNode) catch {
        return AstError.Out_Of_Memory;
    };
    node.node_type = ASTNodeType.Invalid;
    node.token = null;
    node.left = null;
    node.middle = null;
    node.right = null;
    node.children = null;
    node.is_const = false;
    node.size = 0;

    return node;
}

pub fn copyNodeValues(destination_node:*ASTNode, source_node:*const ASTNode) void {
    destination_node.children = source_node.children;
    destination_node.is_const = source_node.is_const;
    destination_node.children = source_node.children;
    destination_node.left = source_node.left;
    destination_node.middle = source_node.middle;
    destination_node.right = source_node.right;
    destination_node.size = source_node.size;
    destination_node.token = source_node.token;
    destination_node.node_type = source_node.node_type;
}

pub fn createIdentifierNode(allocator:*Allocator, token:Token) AstError!*ASTNode {

    const literal_node:*ASTNode = try createDefaultAstNode(allocator);
    literal_node.node_type = ASTNodeType.Identifier;
    literal_node.token = token;
    return literal_node;
}

pub fn createTypeNode(allocator:*Allocator, token:Token) AstError!*ASTNode {
    const type_node:*ASTNode = try createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = token;
    return type_node;
}