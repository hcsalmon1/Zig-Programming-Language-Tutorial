

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

pub fn processAssignment(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, add_new_nl_and_tabs:bool) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processDeclaration";

    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }

    if (add_new_nl_and_tabs) {
        try convert_data.addTab(allocator);
    }

    //if (convert_data.compiler_settings.separate_expressions == true) {
        //try processDeclarationWithFlatten(allocator, convert_data, node);
        //return;
    //}

    const value:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, node, false);

    convert_data.generated_code.appendFmt(allocator, "{s}", .{
        value,
    }) catch return ConvertError.Out_Of_Memory;
    
    if (add_new_nl_and_tabs) {
        try convert_data.addNLWithTabs(allocator);
    }
}