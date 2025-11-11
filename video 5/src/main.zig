const std = @import("std");
const code_sample_script = @import("core//code_samples/code_samples.zig");
const parse_code_script = @import("parse/parse_code.zig");
const struct_script = @import("core/structs.zig");
const debugging_script = @import("debugging/debugging.zig");
const ast_script = @import("format/ast.zig");
const convert_script = @import("convert/convert.zig");
const static_analysis_script = @import("analysis/static_analysis.zig");
const enums_script = @import("core/enums.zig");
const print = std.debug.print;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const Token = struct_script.Token;
const ASTNode = struct_script.ASTNode;
const ArrayList = std.ArrayList;
const GlobalDefinitions = struct_script.GlobalDefinitions;
const LanguageTarget = enums_script.LanguageTarget;
const CompilerSettings = struct_script.CompilerSettings;
const ASTData = struct_script.ASTData;

fn convertCode(code:[]const u8, compiler_settings:*const CompilerSettings) void {

    if (compiler_settings.show_input_code == true) {
        print("Code: \n{s}\n", .{code});
    }

    const page_allocator:Allocator = std.heap.page_allocator;
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    var arena_allocator:Allocator = arena.allocator();

    //parse code
    const token_list:ArrayList(Token) = parse_code_script.parseToTokens(&arena_allocator, code) catch |err| {
        print("\tError {}\n", .{err});
        return;
    };

	//build ASTs
    const ast_nodes:ArrayList(*ASTNode) = ast_script.buildASTs(&arena_allocator, token_list, code) catch |err| {
        print("\tError {}\n", .{err});
        debugging_script.printTokens(token_list, compiler_settings);
        return;
    };

    //analyse code
    const global_definitions:GlobalDefinitions = static_analysis_script.analyseCode(&arena_allocator, ast_nodes, code) catch |err| {
        print("\tError {}\n", .{err});
        debugging_script.printTokens(token_list, compiler_settings);
        return;
    };

    //convert code
    convert_script.convertCode(&arena_allocator, ast_nodes, code, compiler_settings) catch |err| {
        print("\tError {}\n", .{err});
    };

    debugging_script.printTokens(token_list, compiler_settings);
    
    debugging_script.printASTNodes(&arena_allocator, ast_nodes, compiler_settings) catch |err| {
        print("\tError {}\n", .{err});
    };
    global_definitions.printAllData(compiler_settings);
}

fn createCompileSettings() CompilerSettings {
    return .{
        .language_target = LanguageTarget.Go,
        .separate_expressions = false,
        .show_input_code = true,
        .show_tokens = false,
        .show_definitions = false,
        .show_ast_nodes = true,
    };
}

pub fn main() void {

    //runTests();
    const compiler_settings:CompilerSettings = createCompileSettings();
    convertCode(code_sample_script.test_sample_script.TWO_SUM, &compiler_settings);
}

fn runTests() void {
    testChars() catch |err| {
        print("{}\n", .{err});
    };
}

fn testChars() !void {

    const code:[]const u8 = code_sample_script.SWITCH_1;

    const page_allocator:Allocator = std.heap.page_allocator;
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    var arena_allocator:Allocator = arena.allocator();

    //parse code
    const token_list:ArrayList(Token) = parse_code_script.parseToTokens(&arena_allocator, code) catch |err| {
        print("\tError {}\n", .{err});
        return;
    };
    var ast_nodes = try ArrayList(*ASTNode).initCapacity(arena_allocator, 0);
    var ast_data = ASTData {
        .ast_nodes = &ast_nodes,
        .token_list = token_list,
        .token_index = 0,
    }; //A struct to avoid having 5+ parameters
    ast_nodes.clearAndFree(arena_allocator);
    for (0..10) |index| {
        const token:Token = ast_data.token_list.items[index];
        ast_data.error_token = token;
        ast_data.error_detail = "example error";
        try debugging_script.printAstError(&arena_allocator, ast_data, code);
    }
}
