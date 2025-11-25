

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ast_integers_script = @import("ast_integers.zig");
const ast_bool_script = @import("ast_bools.zig");
const ast_utils = @import("ast_utils.zig");
const token_utils_script = @import("../core/token_utils.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const LoopResult = enums_script.LoopResult;

fn fillNodeCurlyBracesInnerLoop(allocator:*Allocator, ast_data:*ASTData, while_count:*usize, max_loops:usize, node_type:ASTNodeType, recursion_count:usize, array_node:*ASTNode) AstError!LoopResult {
    try ast_data.isInfiniteLoop(while_count.*, max_loops);
    while_count.* += 1;
    
    const token:Token = try ast_data.getToken();
    
    // Check for end conditions BEFORE incrementing
    if (token.Type == TokenType.RightBrace) {
        try ast_data.incrementIndex(); 
        return LoopResult.Break;
    }
    
    if (token.Type == TokenType.Semicolon) {
        return LoopResult.Break;
    }
    
    // Skip commas - just increment and continue
    if (token.Type == TokenType.Comma) {
        try ast_data.incrementIndex();
        return LoopResult.Continue;
    }
    
    // If token is an opening brace, recursively handle it (nested array)
    if (token.Type == TokenType.LeftBrace) {
        try ast_data.incrementIndex();
        const nested:*ASTNode = try fillNodeInCurlyBracesArrayRecursive(allocator, ast_data, node_type, recursion_count + 1);
        array_node.children.?.append(allocator.*, nested) catch return AstError.Out_Of_Memory;
        return LoopResult.Continue;
    }
    
    // Parse literal values and add to the current node
    const value_node:*ASTNode = try expressions_script.parseBinaryExprAny(allocator, ast_data, 0, node_type);
    array_node.children.?.append(allocator.*, value_node) catch return AstError.Out_Of_Memory;
    
    return LoopResult.Continue;
}

fn fillNodeInCurlyBracesArrayRecursive(allocator:*Allocator, ast_data:*ASTData, node_type:ASTNodeType, recursion_count:usize) AstError!*ASTNode {
    
    if (recursion_count >= 1000) {
        return AstError.Infinite_Recursion;
    }
    ast_data.error_function = "fillNodeInCurlyBracesArrayRecursive";

    const open_brace_token:Token = try ast_data.getToken();

    const array_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);

    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };

    array_node.node_type = ASTNodeType.ArrayGroup;
    array_node.children = child_list;
    array_node.token = open_brace_token;

    const token_count:usize = ast_data.token_list.items.len;
    var while_count:usize = 0; 
    const max_loops:usize = 1000;

    while (ast_data.token_index < token_count) {

        const loop_result:LoopResult = try fillNodeCurlyBracesInnerLoop(allocator, ast_data, &while_count, max_loops, node_type, recursion_count, array_node);
        if (loop_result == LoopResult.Break) {
            break;
        }
    }

    return array_node;
}

fn fillArrayValue(allocator:*Allocator, ast_data:*ASTData) AstError!*ASTNode {

    ast_data.error_function = "fillArrayValue";
    const first_token:Token = try ast_data.getToken();
    if (first_token.Type == TokenType.LeftBrace) {
        try ast_data.incrementIndex();
        return try fillNodeInCurlyBracesArrayRecursive(allocator, ast_data, ASTNodeType.Array, 0);
    }
    const result_node:?*ASTNode = try expressions_script.parsePrimaryAny(allocator, ast_data);
    if (result_node == null) {
        return AstError.Null_Type;
    }

    return result_node.?;
    //ast_data.error_detail = std.fmt.allocPrint(allocator.*, "{} in fillArrayValue", .{first_token.Type}) catch return AstError.Out_Of_Memory;
    //ast_data.error_token = first_token;
    //return AstError.Unimplemented_Type;
}



pub fn processArrayDeclaration(allocator:*Allocator, ast_data:*ASTData, is_const:bool) AstError!*ASTNode {

    //[]int array;
    //[]int array = {1,2,3,4,5};
    //[5]char array;
    //[5]char array = {'a','b','c','d','e'};


    ast_data.error_function = "processArrayDeclaration";

    const array_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    const type_node:*ASTNode = try expressions_script.createComplexDeclarations(allocator, ast_data);

    const name_token:Token = try ast_data.getToken();

    if (name_token.Type != TokenType.Identifier) {
        ast_data.error_detail = "missing var name in declaration";
        ast_data.error_token = name_token;
        return AstError.Missing_Expected_Type;
    }
    try ast_data.incrementIndex();

    const next_token:Token = try ast_data.getToken();

    if (next_token.Type == TokenType.Semicolon) {
        ast_data.token_index += 1;
        array_node.left = type_node;
        array_node.node_type = ASTNodeType.ArrayDeclaration;
        array_node.is_const = is_const;
        array_node.token = name_token;
        return array_node;
    }

    if (next_token.Type != TokenType.Equals) {
        ast_data.error_token = next_token;
        ast_data.error_detail = "arrays with no value not implemented, '=' expected";
        return AstError.Unimplemented_Type;
    }
    try ast_data.incrementIndex();

    array_node.left = type_node;
    const array_value_nodes:*ASTNode = try fillArrayValue(allocator, ast_data);

    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in declaration");
    try ast_data.incrementIndex();

    array_node.node_type = ASTNodeType.ArrayDeclaration;
    array_node.right = array_value_nodes;
    array_node.is_const = is_const;
    array_node.token = name_token;

    return array_node;
}