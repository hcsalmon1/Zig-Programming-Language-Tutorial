

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

fn printSwitchCase(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //| |     |-.SwitchCase NA - child
    //| |       |-.StringLiteral '2' - left
    //| |       |-.SwitchBody NA - right
    //| |         |-.Println 'println' - child
    //| |           |-.StringLiteral 'Two' - child

    const is_invalid:bool = 
            node.left == null or
            node.right == null;
        
    if (is_invalid == true) {
        return ConvertError.Node_Is_Null;
    }

    const case_condition_node:*ASTNode = node.left.?;
    const case_body_node:*ASTNode = node.right.?;

    const condition_text:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, case_condition_node, false);
    try convert_data.appendCodeFmt(allocator, "case {s}:", .{condition_text});
    try convert_data.addNLWithTabs(allocator);

    try c_body_script.processBody(allocator, convert_data, case_body_node);
}

fn printDefaultCase(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //| |     |-.SwitchDefault NA - child
    //| |       |-.SwitchBody NA - right
    //| |         |-.Println 'println' - child
    //| |           |-.StringLiteral 'Other' - child

    const is_invalid:bool = 
            node.right == null;
        
    if (is_invalid == true) {
        return ConvertError.Node_Is_Null;
    }

    try convert_data.appendCodeFmt(allocator, "default:", .{});
    try convert_data.addNLWithTabs(allocator);

    try c_body_script.processBody(allocator, convert_data, node.right.?);

}

fn printSwitchBody(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    
    //| |     |-.SwitchCase NA - child
    //| |       |-.StringLiteral '0' - left
    //| |       |-.SwitchBody NA - right
    //| |         |-.Println 'println' - child
    //| |           |-.StringLiteral 'Zero' - child
    //| |     |-.SwitchCase NA - child
    //| |       |-.StringLiteral '1' - left
    //| |       |-.SwitchBody NA - right
    //| |         |-.Println 'println' - child
    //| |           |-.StringLiteral 'One' - child
    //| |     |-.SwitchCase NA - child
    //| |       |-.StringLiteral '2' - left
    //| |       |-.SwitchBody NA - right
    //| |         |-.Println 'println' - child
    //| |           |-.StringLiteral 'Two' - child
    //| |     |-.SwitchDefault NA - child
    //| |       |-.SwitchBody NA - right
    //| |         |-.Println 'println' - child
    //| |           |-.StringLiteral 'Other' - child

    if (node.children == null) {
        convert_data.error_detail = "children null is switchbody";
        convert_data.error_token = node.token;
        return ConvertError.Node_Is_Null;
    }

    const node_count:usize = node.children.?.items.len;

    for (0..node_count) |i| {
        const inner_node:*ASTNode = node.children.?.items[i];
    
        switch (inner_node.node_type) {
            ASTNodeType.SwitchCase => try printSwitchCase(allocator, convert_data, inner_node),
            ASTNodeType.SwitchDefault => try printDefaultCase(allocator, convert_data, inner_node),
            else => {
                convert_data.error_detail = std.fmt.allocPrint(allocator.*, "{} invalid node type in switch", .{inner_node.node_type}) catch return ConvertError.Out_Of_Memory;
                convert_data.error_token = inner_node.token;
                return ConvertError.Invalid_Node_Type;
            },
        }
    }
}

pub fn printSwitch(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //| | |-.SwitchStatement 'switch' - child
    //| |   |-.Identifier 'value' - left
    //| |   |-.SwitchBody NA - right


    const is_invalid_node:bool = 
            node.left == null or
            node.right == null;

    if (is_invalid_node == true) {
        convert_data.error_token = node.token;
        return ConvertError.Node_Is_Null;
    }



    const switch_condition:*ASTNode = node.left.?;
    const switch_body:*ASTNode = node.right.?;

    const condition_text:[]const u8 = try print_expression_script.printExpression(allocator, convert_data, switch_condition, false);

    try convert_data.addTab(allocator);
    try convert_data.appendCodeFmt(allocator, "switch {s} {{", .{condition_text});
    convert_data.incrementIndexCount();
    try convert_data.addNLWithTabs(allocator);
    try printSwitchBody(allocator, convert_data, switch_body);
    try convert_data.appendCode(allocator, "}");
    convert_data.decrementIndexCount();
    try convert_data.addNLWithTabs(allocator);
}