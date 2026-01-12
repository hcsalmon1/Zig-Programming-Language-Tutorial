
const std = @import("std");
const errors_script = @import("../core/errors.zig");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const printing_script = @import("../core/printing.zig");
const phase_1_script = @import("phase_1.zig");
const debugging_script = @import("../debugging/debugging.zig");
const SemanticError = errors_script.SemanticError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ASTNode = structs_script.ASTNode;
const Token = structs_script.Token;
const TypeList = structs_script.TypeList;
const StringHashMap = std.StringHashMap;
const ASTNodeType = enums_script.ASTNodeType;
const string = []const u8;
const Type = structs_script.Type;
const TypeMap = structs_script.TypeMap;
const AnalysisData = structs_script.AnalysisData;
const CompilerSettings = structs_script.CompilerSettings;
const print = std.debug.print;
const SymbolTable = structs_script.SymbolTable;
const HashSet = structs_script.HashSet;
const Symbol = structs_script.Symbol;
const SymbolNameAndId = structs_script.SymbolNameAndId;

pub fn analyseCode(allocator:*Allocator, ast_nodes:*ArrayList(*ASTNode), code:string, compiler_settings:*const CompilerSettings) SemanticError!TypeList {

    const types = ArrayList(Type).initCapacity(allocator.*, 0) catch return SemanticError.Out_Of_Memory;
    const type_map:TypeMap = try structs_script.newTypeTypeMap(allocator);
    const symbol_table:SymbolTable = .{
        .symbol_map = HashSet(SymbolNameAndId).init(allocator.*) catch return SemanticError.Out_Of_Memory,
        .symbols = ArrayList(Symbol).initCapacity(allocator.*, 0) catch return SemanticError.Out_Of_Memory,
    };

    var type_list:TypeList = .{
        .type_map = type_map,
        .types = types,
        .symbol_table = symbol_table,
    };

    var analysis_data:AnalysisData = .{
        .ast_nodes = ast_nodes,
        .compiler_settings = compiler_settings,
        .node_count = ast_nodes.items.len,
        .node_index = 0,
        .type_list = &type_list,
    };

    phase_1_script.runSemanticCheckingPhase1(allocator, &analysis_data) catch |err| {
        print("\t{s}Error{s}\n", .{printing_script.RED, printing_script.RESET});
        debugging_script.printSemanticError(allocator, analysis_data, code) catch return SemanticError.Out_Of_Memory;
        return err;
    };

    return type_list;
}