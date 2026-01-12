const std = @import("std");
const code_sample_script = @import("core//code_samples/code_samples.zig");
const parse_code_script = @import("parse/parse_code.zig");
const struct_script = @import("core/structs.zig");
const debugging_script = @import("debugging/debugging.zig");
const ast_script = @import("format/ast.zig");
const convert_script = @import("convert/convert.zig");
const static_analysis_script = @import("analysis/static_analysis.zig");
const enums_script = @import("core/enums.zig");
const error_script = @import("core/errors.zig");
const print = std.debug.print;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const Token = struct_script.Token;
const ASTNode = struct_script.ASTNode;
const ArrayList = std.ArrayList;
const TypeList = struct_script.TypeList;
const LanguageTarget = enums_script.LanguageTarget;
const CompilerSettings = struct_script.CompilerSettings;
const ASTData = struct_script.ASTData;
const string = []const u8;
const Child = std.process.Child;

const builtin = @import("builtin");

pub fn enableWindowsAnsiColors() void {
    if (builtin.os.tag != .windows) return;
    
    const windows = std.os.windows;
    const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;
    const STD_OUTPUT_HANDLE: windows.DWORD = @bitCast(@as(i32, -11));
    
    const handle = windows.kernel32.GetStdHandle(STD_OUTPUT_HANDLE);
    if (handle == windows.INVALID_HANDLE_VALUE) return;
    
    var mode: windows.DWORD = 0;
    if (windows.kernel32.GetConsoleMode(handle.?, &mode) == 0) return;
    
    mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    _ = windows.kernel32.SetConsoleMode(handle.?, mode);
}

fn convertCode(arena_allocator:*Allocator, code:string, compiler_settings:*const CompilerSettings) !string {

    if (compiler_settings.show_input_code == true) {
        print("Code: \n{s}\n", .{code});
    }
    //parse code
    const token_list:ArrayList(Token) = parse_code_script.parseToTokens(arena_allocator, code, compiler_settings) catch |err| {
        return err;
    };

    defer debugging_script.printTokens(token_list, compiler_settings);

	//build ASTs
    var ast_nodes:ArrayList(*ASTNode) = ast_script.buildASTs(arena_allocator, token_list, code, compiler_settings) catch |err| {
        return err;
    };

    defer debugging_script.printASTNodes(arena_allocator, ast_nodes, compiler_settings) catch |err| {
        print("\tError {}\n", .{err});
    };

    //analyse code
    const type_list:TypeList = static_analysis_script.analyseCode(arena_allocator, &ast_nodes, code, compiler_settings) catch |err| {
        return err;
    };

    //convert code
    //const converted_code:string = convert_script.convertCode(arena_allocator, ast_nodes, code, compiler_settings) catch |err| {
      //  return err;
    //};

    type_list.printAllTypes();
    //try global_definitions.printAllData(compiler_settings);
    return "";
    //return converted_code;
}

fn createCompileSettings() CompilerSettings {
    return .{
        .language_target = LanguageTarget.C,
        .separate_expressions = false,
        .show_input_code = true,
        .show_tokens = false,
        .show_definitions = true,
        .show_ast_nodes = true,
        .output_to_file = false,
        .debug_complex_declarations = false,
    };
}

fn printOutput(arena_allocator:*Allocator, compiler_settings:*const CompilerSettings) void {
    
    const code:string = code_sample_script.variables_sample_script.MANY_DECLARATIONS;
    
    const converted_code:string = convertCode(arena_allocator, code, compiler_settings) catch |err| {
        print("{}\n", .{err});
        return;
    };
    print("Generated_Code: \n{s}\n", .{converted_code});
}

fn outputToFile(arena_allocator:*Allocator, compiler_settings:*const CompilerSettings) !void {
    
    // Get args
    const args:[][:0]u8 = try std.process.argsAlloc(arena_allocator.*);
    defer std.process.argsFree(arena_allocator.*, args);
    
    if (args.len < 3 or !std.mem.eql(u8, args[1], "run")) {
        std.debug.print("Usage: cm run <file.cm>\n", .{});
        return;
    }
    
    const source_file:[]u8 = args[2];
    
    // 1. Read source file
    const code:[]u8 = try std.fs.cwd().readFileAlloc(arena_allocator.*, source_file, 1024 * 1024);
    defer arena_allocator.*.free(code);
    
    // 2. Parse and convert (your existing code)
    const generated_go_code:string = try convertCode(arena_allocator, code, compiler_settings);
    
    // 3. Create build directory
    const build_dir:string = ".cm_build";
    try std.fs.cwd().makePath(build_dir);
    
    // 4. Write main.go
    const go_file_path:[]u8 = try std.fs.path.join(arena_allocator.*, &.{ build_dir, "main.go" });
    defer arena_allocator.*.free(go_file_path);
    try std.fs.cwd().writeFile(.{ .sub_path = go_file_path, .data = generated_go_code });
    
    // 5. Write go.mod
    const go_mod_content:string = "module cmtemp\n\ngo 1.21\n";
    const go_mod_path:[]u8 = try std.fs.path.join(arena_allocator.*, &.{ build_dir, "go.mod" });
    defer arena_allocator.*.free(go_mod_path);
    try std.fs.cwd().writeFile(.{ .sub_path = go_mod_path, .data = go_mod_content });
    
    // 6. Run: go run main.go
    var child:Child = Child.init(&.{ "go", "run", "main.go" }, arena_allocator.*);
    child.cwd = build_dir;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    
    _ = try child.spawnAndWait();
}

fn run(arena_allocator:*Allocator, compiler_settings:*const CompilerSettings) void {

    if (compiler_settings.output_to_file == false) {
        printOutput(arena_allocator, compiler_settings);
        return;
    }

    outputToFile(arena_allocator, compiler_settings) catch |err| {
        print("{}\n", .{err});
    };
}

pub fn main() void {

    enableWindowsAnsiColors();

    const page_allocator:Allocator = std.heap.page_allocator;
    var arena = ArenaAllocator.init(page_allocator);
    defer arena.deinit();
	
	var arena_allocator:Allocator = arena.allocator();
	
	//runTests(&arena_allocator);

    const compiler_settings:CompilerSettings = createCompileSettings();
    run(&arena_allocator, &compiler_settings);
}

fn runTests(allocator:*Allocator) void {
    _ = allocator;
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
