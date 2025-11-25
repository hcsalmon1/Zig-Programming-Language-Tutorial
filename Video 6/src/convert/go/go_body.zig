


const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const printing_script = @import("../../core/printing.zig");
const enums_script = @import("../../core/enums.zig");
const debugging_script = @import("../../Debugging/debugging.zig");
const errors_script = @import("../../core/errors.zig");
const print_expression_script = @import("go_print_expressions.zig");
const go_utils_script = @import("go_utils.zig");
const go_return_script = @import("go_return.zig");
const go_declarations_script = @import("go_declaration.zig");
const go_print_script = @import("go_print.zig");
const go_if_script = @import("go_if.zig");
const go_for_script = @import("go_for.zig");
const go_assignment_script = @import("go_assignment.zig");
const go_array_script = @import("go_array.zig");
const go_switch_script = @import("go_switch.zig");
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

const NO_NEW_LINE:bool = false;
const NEW_LINE:bool = true;
const NO_TABS:bool = false;
const TABS:bool = true;

const string = []const u8;


pub fn processBody(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    convert_data.error_function = "processBody";

    //NodeType Type
    //Children body nodes

    if (node.children == null) {
        convert_data.error_detail = "node.children is null";
        return ConvertError.Node_Is_Null;
    } 

    const child_count:usize = node.children.?.items.len;
    if (child_count == 0) {
        return;
    }
    for (0..child_count) |i| {

        const child:*ASTNode = node.children.?.items[i];
        try processFunctionBodyNode(allocator, convert_data, child, NEW_LINE, TABS);
    }
}

fn processStructMemberAccess(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    
    convert_data.error_function = "processStructMemberAccess";
    
    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.*.left == null) {
        return ConvertError.Node_Is_Null;
    }

    try convert_data.addTab(allocator);
    try convert_data.appendCodeFmt(allocator, "{s}.", .{node.token.?.Text});
    try processFunctionBodyNode(allocator, convert_data, node.left.?, NEW_LINE, NO_TABS);
}

fn processFunctionBodyNode(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, add_new_line:bool, add_tabs:bool) ConvertError!void {

    convert_data.error_function = "processFunctionBodyNode";
    const node_type:ASTNodeType = node.node_type;

    if (node_type == ASTNodeType.Invalid) {
        convert_data.error_token = node.token;
        return ConvertError.Invalid_Node_Type;
    }

    switch (node_type) {

        ASTNodeType.StructMemberAccess => try processStructMemberAccess(allocator, convert_data, node),
        ASTNodeType.Return => try go_return_script.processReturn(allocator, convert_data, node),
        ASTNodeType.Declaration => try go_declarations_script.processDeclaration(allocator, convert_data, node, add_new_line, add_tabs),
        ASTNodeType.Print => try go_print_script.processPrint(allocator, convert_data, node, false),
        ASTNodeType.Println => try go_print_script.processPrint(allocator, convert_data, node, true),
        ASTNodeType.IfStatement => try go_if_script.processIfStatement(allocator, convert_data, node, add_new_line, add_tabs),
        ASTNodeType.WhileLoop => try go_if_script.processWhile(allocator, convert_data, node),
        ASTNodeType.ForLoop => try go_for_script.processFor(allocator, convert_data, node),
        ASTNodeType.Assignment => try go_assignment_script.processAssignment(allocator, convert_data, node, add_new_line, add_tabs),
        ASTNodeType.SwitchStatement => try go_switch_script.printSwitch(allocator, convert_data, node),
        ASTNodeType.ArrayDeclaration => try go_array_script.processArrayDeclaration(allocator, convert_data, node),
        ASTNodeType.Continue => { 
            try convert_data.addTab(allocator);
            convert_data.generated_code.append(allocator, "continue\n") catch return ConvertError.Out_Of_Memory;
            try convert_data.addTabs(allocator);
        },
        ASTNodeType.Break => { 
            try convert_data.addTab(allocator);
            convert_data.*.generated_code.append(allocator, "break\n") catch return ConvertError.Out_Of_Memory;
            try convert_data.addTabs(allocator);
        },
        ASTNodeType.FunctionCall => {
            const function_call_text:string = try print_expression_script.printExpression(allocator, convert_data, node, true);
            try convert_data.addTab(allocator);
            convert_data.generated_code.appendFmt(allocator, "{s}\n", .{function_call_text}) catch return ConvertError.Out_Of_Memory;
            try convert_data.addTabs(allocator);
        },
        else => {   
            convert_data.error_token = node.token;
            convert_data.error_detail = std.fmt.allocPrint(allocator.*, "{} not implemented yet", .{node.node_type}) catch return ConvertError.Out_Of_Memory;
            return ConvertError.Unimplemented_Node_Type;
        },
    }
}