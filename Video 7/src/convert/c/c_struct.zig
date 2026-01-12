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
const c_assignment_script = @import("c_assignment.zig");
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

fn printStructMembers(allocator:*Allocator, convert_data:*ConvertData, member_list:*const ArrayList(*ASTNode)) ConvertError!void { 
    const member_count:usize = member_list.items.len;
    if (member_count != 0) {

        for (0..member_count) |member_index| {

            const member_node:*ASTNode = member_list.items[member_index];
            const var_name:Token = member_node.token.?;

            if (member_node.left == null) {
                convert_data.error_detail = "member type node is null in struct";
                return ConvertError.Node_Is_Null;
            }
            const type_node:*ASTNode = member_node.left.?;

            const c_type_text:?[]const u8 = c_utils_script.convertToCType(type_node.token.?);
            if (c_type_text == null) {
                convert_data.error_detail = "Invalid c type";
                return ConvertError.Invalid_Var_Type;
            }
            try convert_data.appendCodeFmt(allocator, "\t{s} {s}\n", .{c_type_text.?, var_name.Text});
        }
    }
}

pub fn processStruct(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //|-.StructDeclaration 'Person' - base
    //| |-.StructMembers NA - right
    //| | |-.StructMember 'age' - child
    //| |   |-.VarType 'int' - left
    //| | |-.StructMember 'name' - child
    //| |   |-.VarType 'string' - left

    convert_data.error_function = "processStruct";

    if (node.token == null) {
        convert_data.error_detail = "no struct name";
        return ConvertError.Node_Is_Null;
    }
    if (node.right == null) {
        convert_data.error_detail = "members node is null in struct";
        return ConvertError.Node_Is_Null;
    }
    const struct_name:Token = node.token.?;

    const struct_members_node:*ASTNode = node.right.?;
    if (struct_members_node.children == null) {
        convert_data.error_detail = "member list is null in struct";
        return ConvertError.Node_Is_Null;
    }

    try convert_data.appendCodeFmt(allocator, "struct {s} {{\n", .{struct_name.Text});


    const member_list:ArrayList(*ASTNode) = struct_members_node.children.?;

    try printStructMembers(allocator, convert_data, &member_list);

    try convert_data.appendCode(allocator, "}\n");
}