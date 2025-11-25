

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const token_utils_script = @import("../core/token_utils.zig");
const expressions_script = @import("../core/expression.zig");
const errors_script = @import("../core/errors.zig");
const ast_node_utils_script = @import("../core/ast_node_utils.zig");
const ast_integers_script = @import("ast_integers.zig");
const ast_pointer_script = @import("ast_pointers.zig");
const ast_return_script = @import("ast_return.zig");
const ast_strings_script = @import("ast_strings.zig");
const ast_utils_script = @import("ast_utils.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn processPrint(allocator:*Allocator, ast_data:*ASTData, new_line:bool) !*ASTNode {

    ast_data.error_function = "processPrint";

    var print_node:*ASTNode = try ast_node_utils_script.createDefaultAstNode(allocator);
    const child_list = ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };
    print_node.children = child_list;

    if (new_line == true) {
        print_node.node_type = ASTNodeType.Println;
    } else {
        print_node.node_type = ASTNodeType.Print;
    }

    print_node.token = try ast_data.*.getToken();
    //skip print
    ast_data.token_index += 1;

    try ast_data.expectType(TokenType.LeftParenthesis, "missing expected '(' in print");
    ast_data.token_index += 1;

    const index_before:usize = ast_data.token_index;

    try ast_utils_script.fillNodeInBrackets(allocator, ast_data, print_node, ASTNodeType.PrintExpression);

    const isEmptyPrint:bool = index_before == ast_data.token_index;

    if (isEmptyPrint == true) {

        if (new_line == false) {
            ast_data.error_detail = "empty print function";
            return AstError.Unexpected_Type;
        }
    }

    try ast_data.expectType(TokenType.RightParenthesis, "missing expected ')' in print");
    ast_data.token_index += 1;
    try ast_data.expectType(TokenType.Semicolon, "missing expected ';' in print");
    ast_data.token_index += 1;

    return print_node;
}