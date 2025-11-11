
const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const printing_script = @import("../../core/printing.zig");
const enums_script = @import("../../core/enums.zig");
const debugging_script = @import("../../debugging/debugging.zig");
const errors_script = @import("../../core/errors.zig");
const go_utils_script = @import("go_utils.zig");
const flatten_expression_script = @import("go_flatten.zig");
const print_expression_script = @import("go_print_expressions.zig");
const go_body_script = @import("go_body.zig");
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

    const invalid_declaration:bool = 
            node.token == null or
            node.left == null or
            node.right == null;

    if (invalid_declaration) {
        convert_data.error_token = node.*.token;
        convert_data.error_detail = "invalid array declaration";
        return ConvertError.Internal_Error;
    }

    try convert_data.addTab(allocator);

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