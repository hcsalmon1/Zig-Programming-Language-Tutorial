
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
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Token = structs_script.Token;
const ASTData = structs_script.ASTData;
const ASTNode = structs_script.ASTNode;
const ConvertData = structs_script.ConvertData;
const StringBuilder = structs_script.StringBuilder;
const TokenType = enums_script.TokenType;
const ConvertError = errors_script.ConvertError;
const ASTNodeType = enums_script.ASTNodeType;

pub fn processWhile(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processWhile";

    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.left == null) {
        return ConvertError.Node_Is_Null;
    }

    try convert_data.addTab(allocator);

    //if (compiler_settings.separate_expressions == true) {
        //try processDeclarationWithFlatten(allocator, convert_data, node);
        //return;
    //}

    const left:*ASTNode = node.left.?;

    const condition:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, left, false);

    convert_data.generated_code.appendFmt(allocator, "while ({s}) {{", .{
        condition,
    }) catch return ConvertError.Out_Of_Memory;

    convert_data.incrementIndexCount();
    try convert_data.addNLWithTabs(allocator);

    if (node.right == null) {
        convert_data.error_detail = "node.right is null in while";
        convert_data.error_token = node.token;
        return ConvertError.Node_Is_Null;
    }

    if (node.right.?.children == null) {
        convert_data.error_detail = "node.right.children is null in while";
        convert_data.error_token = node.token;
        return ConvertError.Node_Is_Null;
    }

    try c_body_script.processBody(allocator, convert_data, node.right.?);
    convert_data.decrementIndexCount();

    convert_data.generated_code.append(allocator, "}") catch return ConvertError.Out_Of_Memory;
    try convert_data.addNLWithTabs(allocator);
}

pub fn processIfStatement(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, add_new_line:bool, add_tabs:bool) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //i32 return_value = add i32 a, b
    //return return value

    convert_data.error_function = "processIfStatement";

    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.left == null) {
        return ConvertError.Node_Is_Null;
    }

    if (add_tabs == true) {
        try convert_data.addTab(allocator);
    }

    //if (compiler_settings.separate_expressions == true) {
        //try processDeclarationWithFlatten(allocator, convert_data, node);
        //return;
    //}

    const left:*ASTNode = node.left.?;

    const value:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, left, false);

    convert_data.generated_code.appendFmt(allocator, "if ({s}) {{", .{
        value,
    }) catch return ConvertError.Out_Of_Memory;

    if (node.right != null) {

        convert_data.incrementIndexCount();
        try convert_data.addNLWithTabs(allocator);

        try c_body_script.processBody(allocator, convert_data, node.right.?);

        convert_data.decrementIndexCount();
        convert_data.generated_code.append(allocator, "}") catch return ConvertError.Out_Of_Memory;
    }

    const child_list:ArrayList(*ASTNode) = node.children.?;
    const child_count = child_list.items.len;

    for (0..child_count) |i| {
        const child:*ASTNode = child_list.items[i];
        
        switch (child.node_type) {
            ASTNodeType.IfStatement => {
                convert_data.generated_code.append(allocator, " else ") catch return ConvertError.Out_Of_Memory;
                try processIfStatement(allocator, convert_data, child, false, false);
            },
            ASTNodeType.Else => {
                convert_data.generated_code.append(allocator, " else {") catch return ConvertError.Out_Of_Memory;

                convert_data.incrementIndexCount();
                try convert_data.addNLWithTabs(allocator);

                try c_body_script.processBody(allocator, convert_data, child.right.?);
                
                convert_data.decrementIndexCount();
                convert_data.generated_code.append(allocator, "}") catch return ConvertError.Out_Of_Memory;
            },
            else => {
                convert_data.error_token = child.token;
                convert_data.error_detail = std.fmt.allocPrint(allocator.*, "invalid node type: {}, in if chain", .{child.node_type}) catch return ConvertError.Out_Of_Memory;
                return ConvertError.Invalid_Node_Type;
            },
        }
    }
    if (add_new_line == true) {
        try convert_data.addNLWithTabs(allocator);
    }
}