const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const enums_script = @import("../../core/enums.zig");
const errors_script = @import("../../core/errors.zig");
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

fn printEnumMembers(allocator:*Allocator, convert_data:*ConvertData, member_list:*const ArrayList(*ASTNode)) ConvertError!void { 
    const member_count:usize = member_list.items.len;
    if (member_count != 0) {

        for (0..member_count) |member_index| {

            const member_node:*ASTNode = member_list.items[member_index];
            const member_name_token:Token = member_node.token.?;
            try convert_data.appendCodeFmt(allocator, "\tint32_t {s};\n", .{member_name_token.Text});
        }
    }
}

fn printEnumMemberToString(allocator:*Allocator, convert_data:*ConvertData, member_list:*const ArrayList(*ASTNode), enum_name_token:Token) ConvertError!void { 
    const member_count:usize = member_list.items.len;
    if (member_count != 0) {

        try convert_data.appendCodeFmt(allocator, "const char* {s}ToString(int32_t input) {{\n", .{enum_name_token.Text});

        try convert_data.appendCode(allocator, "\tswitch input {\n");

        for (0..member_count) |member_index| {

            const member_node:*ASTNode = member_list.items[member_index];
            const member_name_token:Token = member_node.token.?;
            try convert_data.appendCodeFmt(allocator, "\tcase {s}.{s}:\n", .{enum_name_token.Text, member_name_token.Text});
            try convert_data.appendCodeFmt(allocator, "\t\treturn \"{s}\";\n", .{member_name_token.Text});
        }
        try convert_data.appendCodeFmt(allocator, "\tdefault:\n\t\treturn \"{s}\"\n", .{"Unknown"});

        try convert_data.appendCode(allocator, "}\n");
        try convert_data.appendCode(allocator, "}\n");
    }
}

pub fn processEnum(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    //|-.EnumDeclaration 'EmployeeType' - base
    //| |-.EnumMembers NA - right
    //| | |-.EnumMember 'Admin' - child
    //| | |-.EnumMember 'Regular' - child
    //| | |-.EnumMember 'Intern' - child

    convert_data.error_function = "processEnum";

    if (node.token == null) {
        convert_data.error_detail = "no enum name";
        return ConvertError.Node_Is_Null;
    }
    if (node.right == null) {
        convert_data.error_detail = "members node is null in struct";
        return ConvertError.Node_Is_Null;
    }
    const enum_name:Token = node.token.?;

    const enum_members_node:*ASTNode = node.right.?;
    if (enum_members_node.children == null) {
        convert_data.error_detail = "member list is null in struct";
        return ConvertError.Node_Is_Null;
    }

    try convert_data.appendCode(allocator, "typedef struct {\n");

    const member_list:ArrayList(*ASTNode) = enum_members_node.children.?;

    try printEnumMembers(allocator, convert_data, &member_list);

    try convert_data.appendCodeFmt(allocator, "}} {s}_Enum;\n", .{enum_name.Text});

    try convert_data.appendCodeFmt(allocator, "const {s}_Enum {s} = {{", .{enum_name.Text, enum_name.Text});
    const member_count:usize = member_list.items.len;
    for (0..member_count) |i| {
        try convert_data.appendCodeFmt(allocator, "{},", .{i});
    }
    try convert_data.appendCode(allocator, "}\n");

    try printEnumMemberToString(allocator, convert_data, &member_list, enum_name);
}