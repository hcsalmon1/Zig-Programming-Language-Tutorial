

const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const printing_script = @import("../../core/printing.zig");
const enums_script = @import("../../core/enums.zig");
const debugging_script = @import("../../Debugging/debugging.zig");
const errors_script = @import("../../core/errors.zig");
const llvm_function_script = @import("llvm_function.zig");
const print = std.debug.print;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ConvertError = errors_script.ConvertError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ConvertData = structs_script.ConvertData;
const StringBuilder = structs_script.StringBuilder;
const ASTNodeType = enums_script.ASTNodeType;
const CompilerSettings = structs_script.CompilerSettings;
const string = []const u8;

pub fn convert(allocator:*Allocator, ast_nodes:ArrayList(*ASTNode), code:string, compiler_settings:*const CompilerSettings) ConvertError!string {
    //print("\t{s}Converting{s}\t\t\t", .{printing_script.GREY, printing_script.RESET});

    var generated_code:StringBuilder = StringBuilder.init(allocator.*) catch return ConvertError.Out_Of_Memory;

    var convert_data:ConvertData = .{
        .ast_nodes = ast_nodes,
        .generated_code = &generated_code,
        .compiler_settings = compiler_settings,
    };

    convert_data.error_function = "convert";

    const node_count:usize = ast_nodes.items.len;
    if (node_count == 0) {
        return ConvertError.No_AST_Nodes;
    }

    convert_data.generated_code.appendLine(allocator, "declare i32 @printf(i8*, ...)") catch return ConvertError.Out_Of_Memory;

    while (convert_data.node_index < node_count) {

        const previous_index:usize = convert_data.node_index;

        processGlobalNode(allocator, &convert_data) catch |err| {
            print("{s}Error{s}\n", .{printing_script.RED, printing_script.RESET});
            debugging_script.printConvertError(allocator, convert_data, code) catch |err2| {
                print("error printing convert data: {}\n",.{err2});
            };
            return err;
        };

        if (previous_index == convert_data.node_index) {
            convert_data.node_index += 1;
        }
    }
    //print("{s}Done{s}\n", .{printing_script.CYAN, printing_script.RESET});

    const generated_output:[]u8 = generated_code.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
    return generated_output;
}

fn processGlobalNode(allocator:*Allocator, convert_data:*ConvertData) ConvertError!void {

    convert_data.error_function = "processGlobalNode";

    const node:?*ASTNode = convert_data.getNode();

    if (node == null) {
        return ConvertError.Node_Is_Null;
    }

    switch (node.?.node_type) {
        ASTNodeType.FunctionDeclaration => try llvm_function_script.processFunctionDeclaration(allocator, convert_data, node.?),
        ASTNodeType.Declaration => return,
        else => return ConvertError.Unimplemented_Node_Type,
    }
}