
const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const printing_script = @import("../../core/printing.zig");
const enums_script = @import("../../core/enums.zig");
const debugging_script = @import("../../debugging/debugging.zig");
const errors_script = @import("../../core/errors.zig");
const c_utils_script = @import("c_utils.zig");
const flatten_expression_script = @import("c_flatten.zig");
const print_expression_script = @import("c_print_expressions.zig");
const c_body_script = @import("c_body.zig");
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

fn processNoValueArrayDeclaration(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const var_name:Token = node.token.?;

    const type_text:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, node.left.?, false);

    const array_size:usize = node.left.?.size;

    convert_data.generated_code.appendFmt(allocator, "var {s} {s}", .{
        var_name.Text,
        type_text
    }) catch return ConvertError.Out_Of_Memory;

    if (array_size != 0) {
        
        convert_data.generated_code.appendFmt(allocator, " = make({s}, {})", .{
            type_text,
            array_size
        }) catch return ConvertError.Out_Of_Memory;
    }

    try convert_data.addNLWithTabs(allocator);
}

pub fn processArrayDeclaration(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //| | |-.ArrayDeclaration 'array' - child
    //| |   |-.Array NA - left
    //| |     |-.VarType 'int' - left
    //| |   |-.ArrayGroup '1' - right
    //| |     |-.IntegerLiteral '1' - child
    //| |     |-.IntegerLiteral '2' - child
    //| |     |-.IntegerLiteral '3' - child
    //| |     |-.IntegerLiteral '4' - child
    //| |     |-.IntegerLiteral '5' - child

    const is_invalid_declaration:bool = 
            node.token == null or
            node.left == null;

    if (is_invalid_declaration == true) {
        convert_data.error_token = node.*.token;
        convert_data.error_detail = "invalid array declaration";
        return ConvertError.Internal_Error;
    }

    try convert_data.addTab(allocator);

    if (node.right == null) {
        try processNoValueArrayDeclaration(allocator, convert_data, node);
        return;
    }

    const var_name:Token = node.token.?;

    const type_text:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, node.left.?, false);
    const array_value:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, node.right.?, false);

    if (node.right.?.node_type != ASTNodeType.ArrayGroup) {

        convert_data.generated_code.appendFmt(allocator, "var {s} {s} = {s}", .{
            var_name.Text,
            type_text,
            array_value,
        }) catch return ConvertError.Out_Of_Memory;

    } else {

        convert_data.generated_code.appendFmt(allocator, "var {s} {s} = {s}{s}", .{
            var_name.Text,
            type_text,
            type_text,
            array_value,
        }) catch return ConvertError.Out_Of_Memory;
    }
    try convert_data.addNLWithTabs(allocator);
}