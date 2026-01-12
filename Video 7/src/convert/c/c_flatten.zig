
const std = @import("std");

const structs_script = @import("../../core/structs.zig");
const enums_script = @import("../../core/enums.zig");
const errors_script = @import("../../core/errors.zig");
const c_utils_script = @import("c_utils.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ConvertData = structs_script.ConvertData;
const ASTNode = structs_script.ASTNode;
const AstError = errors_script.AstError;
const ASTNodeType = enums_script.ASTNodeType;
const ConvertError = errors_script.ConvertError;
const Token = structs_script.Token;

pub fn flattenBinaryExpression(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, no_strings:bool, statements:*ArrayList([]const u8)) ConvertError![]const u8 {
    //local definitions later
    if (node.left == null) {
        convert_data.error_detail = "Internal error: node.left is null in 'flattenBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }
    if (node.right == null) {
        convert_data.error_detail = "Internal error: node.right is null in 'flattenBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }
    if (node.token == null) {
        convert_data.error_detail = "Internal error: node.token is null in 'flattenBinaryExpression'";
        return ConvertError.Node_Is_Null;
    }

    var left_statements = std.ArrayList([]const u8).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };
    const left_value:[]const u8 = try flattenExpression(allocator, convert_data, node.left.?, no_strings, &left_statements);

    var right_statements = std.ArrayList([]const u8).initCapacity(allocator.*, 0) catch {
        return AstError.Out_Of_Memory;
    };
    const right_value:[]const u8 = try flattenExpression(allocator, convert_data, node.right.?, no_strings, &right_statements);

    const token_operator_text:[]const u8 = node.token.?.Text;

    const line:[]u8 = std.fmt.allocPrint(allocator.*, "\tvar return_value {s} = {s} {s} {s}", .{convert_data.function_return_type.?, left_value, token_operator_text, right_value}) catch {
        return ConvertError.Out_Of_Memory;
    };

    // Add all parts into the passed-in statements list
    statements.appendSlice(allocator.*, left_statements.items) catch return ConvertError.Out_Of_Memory;
    statements.appendSlice(allocator.*, right_statements.items) catch return ConvertError.Out_Of_Memory;
    statements.append(allocator.*, line) catch return ConvertError.Out_Of_Memory;
    return "return_value";
}

//returns list of strings and a string, it's recursive. false = strings allowed
pub fn flattenExpression(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, no_strings:bool, statements:*ArrayList([]const u8)) ConvertError![]const u8 {
    
    convert_data.error_function = "flattenExpression";

    if (node.token == null) {
        convert_data.error_detail = "Internal error: node.token is null in 'flattenExpression'";
        return ConvertError.Node_Is_Null;
    }

    switch (node.node_type)
    {
        ASTNodeType.BinaryExpression, ASTNodeType.ReturnExpression, ASTNodeType.PrintExpression, ASTNodeType.Parameter => {
            return try flattenBinaryExpression(allocator, convert_data, node, no_strings, statements);
        },

        //ASTNodeType.BoolExpression => return try flattenBoolExpression(allocator, convert_data, node, no_strings, statements),

        ASTNodeType.Identifier => return processIdentifier(allocator, convert_data, node),

        ASTNodeType.IntegerLiteral, ASTNodeType.BoolLiteral => {
            return node.token.?.Text;
        },

        ASTNodeType.Minus => {
            const expr:[]const u8 = try flattenExpression(allocator, convert_data, node.left.?, no_strings, statements);
            const string:[]u8 = std.fmt.allocPrint(allocator.*, "-{s}", .{expr}) catch {
                return ConvertError.Out_Of_Memory;
            };
            return string;
        },
        ASTNodeType.CharLiteral => return node.token.?.Text,

        ASTNodeType.StringLiteral => {
            if (no_strings) {
                convert_data.error_detail = "no_strings are expected in flattenExpression";
                return ConvertError.Unimplemented_Node_Type;
            }
            const string:[]u8 = std.fmt.allocPrint(allocator.*, "\"{s}\"", .{node.token.?.Text}) catch {
                return ConvertError.Out_Of_Memory;
            };
            return string;
        },

        //ASTNodeType.FunctionCall:

            //return WriteFunctionCall(ref cpp_data, ref node, statements, ref localDefinitions);

        //ASTNodeType.ArrayAccess:

            //return WriteArrayAccess(ref cpp_data, ref node, statements, ref localDefinitions);

        //ASTNodeType.StructVariable:

            //Debug.Assert(node.Left != null);
            //Debug.Assert(node.Left.Token != null);
          //  return $"{node.Token.Value.Text}.{node.Left.Token.Value.Text}";

        else => {
            std.debug.print("Error here in flatten expession\n", .{});
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

