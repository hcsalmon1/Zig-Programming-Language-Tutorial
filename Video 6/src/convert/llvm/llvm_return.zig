


const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const printing_script = @import("../../core/printing.zig");
const enums_script = @import("../../core/enums.zig");
const debugging_script = @import("../../debugging/debugging.zig");
const errors_script = @import("../../core/errors.zig");
const llvm_utils_script = @import("llvm_utils.zig");
const flatten_expression_script = @import("llvm_flatten.zig");
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


pub fn processReturn(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processReturn";

    if (node.right == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.right.?.token == null) {
        return ConvertError.Node_Is_Null;
    }

    const statements:*ArrayList([]const u8) = allocator.*.create(ArrayList([]const u8)) catch {
        return ConvertError.Out_Of_Memory;
    };
    statements.* = std.ArrayList([]const u8).initCapacity(allocator.*, 0) catch {
        return ConvertError.Out_Of_Memory;
    };

    const final_value:[]const u8 = try flatten_expression_script.flattenExpression(allocator, convert_data, node.right.?, true, statements);

    if (statements.items.len > 0) {
        for (0..statements.items.len) |i| {
            convert_data.generated_code.appendFmt(allocator, "{s}\n\t", .{statements.items[i]}) catch return ConvertError.Out_Of_Memory;
        }
    }

    convert_data.generated_code.appendFmt(allocator, "\tret i32 {s}\n", .{
        final_value,
    }) catch return ConvertError.Out_Of_Memory;

    //cppData.GeneratedCode.Append($"return {finalValue};\n");
}