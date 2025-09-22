

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
    node.is_array = false;
    node.is_global = false;
    node.is_const = false;
    node.size = 0;

    return node;
}

pub fn copyNodeValues(node:*ASTNode, source_node:*const ASTNode) void {
    node.children = source_node.Children;
    node.is_array = source_node.IsArray;
    node.is_const = source_node.IsConst;
    node.children = source_node.Children;
    node.left = source_node.Left;
    node.middle = source_node.Middle;
    node.right = source_node.Right;
    node.size = source_node.Size;
    node.token = source_node.Token;
}