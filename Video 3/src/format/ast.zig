

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const ast_integers_script = @import("ast_integers.zig");
//const ast_pointers_script = @import("ast_pointers.zig");
const debugging_script = @import("../debugging/debugging.zig");
const errors_script = @import("../core/errors.zig");
const ast_functions_script = @import("ast_functions.zig");
const print = std.debug.print;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn buildASTs(allocator:*Allocator, token_list:*const ArrayList(Token), code:[]const u8, ) !*ArrayList(*ASTNode) {
    
    std.debug.print("\t{s}Formatting{s}\t\t\t", .{printing_script.GREY, printing_script.RESET});

    const ast_nodes:*ArrayList(*ASTNode) = try allocator.*.create(ArrayList(*ASTNode));
    ast_nodes.* = try ArrayList(*ASTNode).initCapacity(allocator.*, 0);

    var ast_data = ASTData {
        .ast_nodes = ast_nodes,
        .token_list = token_list,
        .token_index = 0,
    }; //A struct to avoid having 5+ parameters

    const token_count:usize = token_list.items.len;

    while (ast_data.token_index < token_count) {

        const index_before:usize = ast_data.token_index;

        processGlobalTokenAST(allocator, &ast_data, false) catch |err| {
            print("{s}Error{s}\n", .{printing_script.RED, printing_script.RESET});
            try debugging_script.printAstError(allocator, ast_data, code);
            return err;
        };
        if (index_before == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }

    std.debug.print("{s}Done{s}\n", .{printing_script.CYAN, printing_script.RESET});

    return ast_nodes;
}

fn processGlobalTokenAST(allocator:*Allocator, ast_data:*ASTData, is_const:bool) !void {

    ast_data.error_function = "processGlobalTokenAST";

    const firstToken:Token = try ast_data.getToken();

    switch (firstToken.Type) {

        TokenType.Const => {
            ast_data.token_index += 1;
            try processGlobalTokenAST(allocator, ast_data, true);
        },
        TokenType.i32 => {
            const declaration_node:*ASTNode = try ast_integers_script.processIntDeclaration(allocator, ast_data, firstToken, true, is_const);
            try ast_data.ast_nodes.append(allocator.*, declaration_node);
        },
        TokenType.Multiply => {
            //const pointerNode:*ASTNode = try ast_pointers_script.processPointerDeclaration(ast_data, firstToken, true, is_const, allocator);
            //try ast_data.ast_nodes.append(allocator.*, pointerNode);
        },
        TokenType.Fn => {

            try ast_functions_script.processFunctionDeclaration(allocator, ast_data);
        },
        else => {
            ast_data.error_detail  = "unimplemented type in ast ";
            ast_data.error_token = firstToken;
            return AstError.Unimplemented_Type;
        }
    }
}