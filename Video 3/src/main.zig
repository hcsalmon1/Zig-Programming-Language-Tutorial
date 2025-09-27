const std = @import("std");
const code_sample_script = @import("core/code_samples.zig");
const parse_code_script = @import("parse/parse_code.zig");
const struct_script = @import("core/structs.zig");
const enum_script = @import("core/enums.zig");
const debugging_script = @import("debugging/debugging.zig");
const ast_script = @import("format/ast.zig");
const llvm_convert_script = @import("convert/llvm_convert.zig");
const print = std.debug.print;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const Token = struct_script.Token;
const ASTNode = struct_script.ASTNode;

fn convertCode(code:[]const u8) void {

    print("Code: \n{s}\n", .{code});

    const page_allocator = std.heap.page_allocator;
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    var arena_allocator:Allocator = arena.allocator();

    //parse code
    const token_list:*std.ArrayList(Token) = parse_code_script.parseToTokens(&arena_allocator, code) catch |err| {
        print("Error {}\n", .{err});
        return;
    };

    const ast_nodes:*std.ArrayList(*ASTNode) = ast_script.buildASTs(&arena_allocator, token_list, code) catch |err| {
        print("\tError {}\n", .{err});
        debugging_script.printTokens(token_list);
        return;
    };

    llvm_convert_script.convert(&arena_allocator, ast_nodes, code) catch |err| {
        print("\tError {}\n", .{err});
    };

    debugging_script.printTokens(token_list);
    debugging_script.printASTNodes(&arena_allocator, ast_nodes) catch |err| {
        print("\tError {}\n", .{err});
    };
}

pub fn main() void {
    convertCode(code_sample_script.RETURN_ZERO);
}

