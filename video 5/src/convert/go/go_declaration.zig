const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const printing_script = @import("../../core/printing.zig");
const enums_script = @import("../../core/enums.zig");
const debugging_script = @import("../../debugging/debugging.zig");
const errors_script = @import("../../core/errors.zig");
const go_utils_script = @import("go_utils.zig");
const flatten_expression_script = @import("go_flatten.zig");
const print_expression_script = @import("go_print_expressions.zig");
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


pub fn processDeclaration(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, add_new_nl_and_tabs:bool) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processDeclaration";

    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.left == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.left.?.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.right.?.token == null) {
        return ConvertError.Node_Is_Null;
    }

    if (add_new_nl_and_tabs) {
        try convert_data.addTab(allocator);
    }

    if (convert_data.compiler_settings.separate_expressions == true) {
        try processDeclarationWithFlatten(allocator, convert_data, node);
        return;
    }

    const left:*ASTNode = node.left.?;
    const type_token:Token = left.token.?;
    const go_type:?[]const u8 = go_utils_script.convertToGoType(type_token);

    if (go_type == null) {
        convert_data.error_detail = "go type is null in processDeclaration";
        return ConvertError.Internal_Error;
    }

    const value:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, node.right.?, false);

    convert_data.generated_code.appendFmt(allocator, "var {s} {s} = {s}", .{
        node.*.token.?.Text,
        go_type.?,
        value,
    }) catch return ConvertError.Out_Of_Memory;
    if (add_new_nl_and_tabs) {
        try convert_data.addNLWithTabs(allocator);
    }
}

fn processDeclarationWithFlatten(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    var statements = ArrayList([]const u8).initCapacity(allocator.*, 0) catch {
        return ConvertError.Out_Of_Memory;
    };

    const left:*ASTNode = node.left.?;
    const type_token:Token = left.token.?;
    const go_type:?[]const u8 = go_utils_script.convertToGoType(type_token);

    if (go_type == null) {
        convert_data.error_detail = "go type is null in processDeclaration";
        return ConvertError.Internal_Error;
    }

    const final_value:[]const u8 = try flatten_expression_script.flattenExpression(allocator, convert_data, node.right.?, true, &statements);

    if (statements.items.len > 0) {
        for (0..statements.items.len) |i| {
            convert_data.generated_code.appendFmt(allocator, "{s}", .{statements.items[i]}) catch return ConvertError.Out_Of_Memory;
            try convert_data.addNLWithTabs(allocator);
        }
    }

    convert_data.generated_code.appendFmt(allocator, "var {s} {s} = {s}", .{
        node.*.token.?.Text,
        go_type.?,
        final_value,
    }) catch return ConvertError.Out_Of_Memory;
    try convert_data.addNLWithTabs(allocator);
}