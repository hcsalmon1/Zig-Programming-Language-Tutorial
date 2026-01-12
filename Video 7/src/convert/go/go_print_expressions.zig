


const std = @import("std");

const structs_script = @import("../../core/structs.zig");
const enums_script = @import("../../core/enums.zig");
const errors_script = @import("../../core/errors.zig");
const go_utils_script = @import("go_utils.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ConvertData = structs_script.ConvertData;
const ASTNode = structs_script.ASTNode;
const AstError = errors_script.AstError;
const ASTNodeType = enums_script.ASTNodeType;
const ConvertError = errors_script.ConvertError;
const Token = structs_script.Token;
const StringBuilder = structs_script.StringBuilder;

fn writeFunctionCall(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError![]const u8 {

    if (node.token == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.children == null) {
        return ConvertError.Node_Is_Null;
    }

    var output_builder = ArrayList(u8).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };

    const function_name:[]const u8 = node.*.token.?.Text;

    for (function_name) |character| {
        output_builder.append(allocator.*, character) catch return ConvertError.Out_Of_Memory;
    }
    output_builder.append(allocator.*, '(') catch return ConvertError.Out_Of_Memory;

    const child_count:usize = node.*.children.?.items.len;

    for (0..child_count) |i| {

        const arg_node:*ASTNode = node.*.children.?.items[i];

        const argument:[]const u8 = try printExpression(allocator, convert_data, arg_node, false);
        for (argument) |character| {
            output_builder.append(allocator.*, character) catch return ConvertError.Out_Of_Memory;
        }

        if (i < child_count - 1) {
            output_builder.append(allocator.*, ',') catch return ConvertError.Out_Of_Memory;
        }
    }
    output_builder.append(allocator.*, ')') catch return ConvertError.Out_Of_Memory;

    return output_builder.toOwnedSlice(allocator.*) catch return ConvertError.Out_Of_Memory;
}

pub fn printBinaryExpression(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, no_strings:bool) ConvertError![]const u8 {
    //local definitions later
    if (node.left == null) {
        convert_data.error_detail = "Internal error: node.left is null in 'printBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }
    if (node.right == null) {
        convert_data.error_detail = "Internal error: node.right is null in 'printBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }
    if (node.token == null) {
        convert_data.error_detail = "Internal error: node.token is null in 'printBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }

    const left_value:[]const u8 = try printExpression(allocator, convert_data, node.left.?, no_strings);
    const right_value:[]const u8 = try printExpression(allocator, convert_data, node.right.?, no_strings);

    const token_operator_text:[]const u8 = node.token.?.Text;

    const line:[]u8 = std.fmt.allocPrint(allocator.*, "{s} {s} {s}", .{left_value, token_operator_text, right_value}) catch {
        return ConvertError.Out_Of_Memory;
    };

    return line;
}

pub fn printBoolExpression(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, no_strings:bool) ConvertError![]const u8 {
    //local definitions later
    if (node.left == null) {
        convert_data.error_detail = "Internal error: node.left is null in 'printBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }
    if (node.right == null) {
        convert_data.error_detail = "Internal error: node.right is null in 'printBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }
    if (node.token == null) {
        convert_data.error_detail = "Internal error: node.token is null in 'printBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }

    const left_value:[]const u8 = try printExpression(allocator, convert_data, node.left.?, no_strings);
    const right_value:[]const u8 = try printExpression(allocator, convert_data, node.right.?, no_strings);

    const token_operator_text:[]const u8 = node.token.?.Text;

    const line:[]u8 = std.fmt.allocPrint(allocator.*, "{s} {s} {s}", .{
        left_value, 
        token_operator_text, 
        right_value
    }) catch {
        return ConvertError.Out_Of_Memory;
    };

    return line;
}

pub fn printArrayTypeValue(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError![]const u8 {

    _ = convert_data;
    var type_builder:StringBuilder = StringBuilder.init(allocator.*) catch return ConvertError.Out_Of_Memory;

    var left_node:?*ASTNode = node.left;
    var while_count:usize = 0;

    if (node.node_type == ASTNodeType.Array) {
        type_builder.append(allocator, "[]") catch return ConvertError.Out_Of_Memory;
    } else {
        type_builder.append(allocator, node.token.?.Text) catch return ConvertError.Out_Of_Memory;
    }

    while (left_node != null) {

        if (while_count >= 1000) {
            return ConvertError.Infinite_While_Loop;
        }
        while_count += 1;

        if (left_node.?.node_type == ASTNodeType.Array) {
            type_builder.append(allocator, "[]") catch return ConvertError.Out_Of_Memory;
        } else {
            const token:Token = left_node.?.token.?;
            const go_type:?[]const u8 = go_utils_script.convertToGoType(token);
            if (go_type == null) {
                type_builder.append(allocator, token.Text) catch return ConvertError.Out_Of_Memory;
            } else {
                type_builder.append(allocator, go_type.?) catch return ConvertError.Out_Of_Memory;
            }

        }

        left_node = left_node.?.left;
    }

    return type_builder.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
}

pub fn printStructMemberAccess(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, no_strings:bool) ConvertError![]const u8 {
    
    var output_builder:StringBuilder = StringBuilder.init(allocator.*) catch return ConvertError.Out_Of_Memory;

    if (node.left == null) {
        convert_data.error_detail = "Internal error: node.left is null in 'printArrayAccess'";
        convert_data.error_token = node.token;
        return ConvertError.Node_Is_Null;
    }
    const member_text:[]const u8 = try printExpression(allocator, convert_data, node.left.?, no_strings);

    output_builder.appendFmt(allocator, "{s}.{s}", .{
        node.token.?.Text, 
        member_text}
    ) catch return ConvertError.Out_Of_Memory;

    return output_builder.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
}

pub fn printArrayAccess(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, no_strings:bool) ConvertError![]const u8 {
    
    var output_builder:StringBuilder = StringBuilder.init(allocator.*) catch return ConvertError.Out_Of_Memory;

    if (node.left == null) {
        convert_data.error_detail = "Internal error: node.left is null in 'printArrayAccess'";
        convert_data.error_token = node.token;
        return ConvertError.Node_Is_Null;
    }
    const index_text:[]const u8 = try printExpression(allocator, convert_data, node.left.?, no_strings);

    output_builder.appendFmt(allocator, "{s}[{s}]", .{
        node.token.?.Text, 
        index_text}
    ) catch return ConvertError.Out_Of_Memory;

    return output_builder.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
}

pub fn printFloatLiteral(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError![]const u8 {
    
    convert_data.error_function = "printFloatLiteral";
    
    if (node.token == null) {
        convert_data.error_detail = "Token is null in float literal";
        return ConvertError.Node_Is_Null;
    }

    if (node.right == null) {
        return node.token.?.Text;
    }

    const right_node:*ASTNode = node.right.?;
    if (right_node.token == null) {
        convert_data.error_detail = "right.Token is null in float literal";
        return ConvertError.Node_Is_Null;
    }

    return std.fmt.allocPrint(allocator.*, "{s}.{s}", .{
        node.token.?.Text,
        right_node.token.?.Text
    }) catch return ConvertError.Out_Of_Memory;
}

//returns a string, it's recursive. false = strings allowed
pub fn printExpression(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, no_strings:bool) ConvertError![]const u8 {

    convert_data.error_function = "printExpression";    

    if (node.token == null and node.node_type != ASTNodeType.Array) {
        convert_data.error_detail = "Internal error: node.token is null in 'printExpression'";
        return ConvertError.Node_Is_Null;
    }

    switch (node.node_type)
    {
        ASTNodeType.BinaryExpression, ASTNodeType.ReturnExpression, ASTNodeType.PrintExpression, ASTNodeType.Parameter, ASTNodeType.Assignment => {
            return try printBinaryExpression(allocator, convert_data, node, no_strings);
        },

        ASTNodeType.BoolExpression => return try printBoolExpression(allocator, convert_data, node, no_strings),

        ASTNodeType.Identifier => return try processIdentifier(allocator, convert_data, node),

        ASTNodeType.IntegerLiteral, ASTNodeType.BoolLiteral => {
            return node.token.?.Text;
        },

        ASTNodeType.FloatLiteral => return try printFloatLiteral(allocator, convert_data, node),

        ASTNodeType.Minus => {
            const expr:[]const u8 = try printExpression(allocator, convert_data, node.left.?, no_strings);
            const string:[]u8 = std.fmt.allocPrint(allocator.*, "-{s}", .{expr}) catch {
                return ConvertError.Out_Of_Memory;
            };
            return string;
        },
        ASTNodeType.CharLiteral => {
            const string:[]u8 = std.fmt.allocPrint(allocator.*, "'{s}'", .{node.token.?.Text}) catch {
                return ConvertError.Out_Of_Memory;
            };
            return string;
        },

        ASTNodeType.StringLiteral => {
            if (no_strings) {
                return ConvertError.Unimplemented_Node_Type;
            }
            return std.fmt.allocPrint(allocator.*, "\"{s}\"", .{node.*.token.?.Text}) catch return ConvertError.Out_Of_Memory;
        },

        ASTNodeType.FunctionCall => {

            return try writeFunctionCall(allocator, convert_data, node);
        },
        ASTNodeType.Array => {
            return try printArrayTypeValue(allocator, convert_data, node);
        },
        ASTNodeType.ArrayGroup => {
            var type_builder:StringBuilder = StringBuilder.init(allocator.*) catch return ConvertError.Out_Of_Memory;
            type_builder.append(allocator, "{") catch return ConvertError.Out_Of_Memory;
            var count:usize = 0;
            for (node.children.?.items) |child| {
                if (count != 0) {
                    type_builder.append(allocator, ",") catch return ConvertError.Out_Of_Memory;  
                }
                const phrase:[]const u8 = try printExpression(allocator, convert_data, child, no_strings);
                type_builder.appendFmt(allocator, "{s}", .{phrase}) catch return ConvertError.Out_Of_Memory;    
                count += 1;
            }
            type_builder.append(allocator, "}") catch return ConvertError.Out_Of_Memory;
            return type_builder.toOwnedSlice(allocator) catch return ConvertError.Out_Of_Memory;
        },
        ASTNodeType.ArrayAccess => {

            return printArrayAccess(allocator, convert_data, node, no_strings);

        },
        ASTNodeType.StructMemberAccess => {

            return printStructMemberAccess(allocator, convert_data, node, no_strings);
        },
        else => {
            convert_data.error_detail = std.fmt.allocPrint(allocator.*, "node type: {}", .{node.node_type}) catch {
                return ConvertError.Out_Of_Memory;
            };
            convert_data.error_token = node.token;
            return ConvertError.Unimplemented_Node_Type;
        },
    }
}

pub fn processIdentifier(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError![]const u8 {
    
    _ = allocator;
    _ = convert_data;
    return node.*.token.?.Text;
    //const identifier_token:Token = node.Token.Value;
    //if (cppData.GlobalDefinitions.GlobalNameExists(identifier_token)) {
    //    return identifier_token.Text;
    //}
    //if (localDefinitions.CheckExistsLocally(identifier_token))
    //{
    //    return identifier_token.Text;
    //}

    //CppUtils.UndefinedName(ref cppData, "Undeclared identifier in expression", identifier_token, "ProcessIdentifier");
    //return null;
}
