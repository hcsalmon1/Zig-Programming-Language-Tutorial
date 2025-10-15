


const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const debugging_script = @import("../Debugging/debugging.zig");
const errors_script = @import("../core/errors.zig");
const llvm_utils_script = @import("llvm_utils.zig");
const llvm_body_script = @import("llvm_body.zig");
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

pub fn processFunctionDeclaration(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) !void {

    convert_data.error_function = "processFunctionDeclaration";

    //Node_type: ASTNode_FunctionDeclaration,
    //Token:     third_token, - function name
    //Left:      &type_node, - return type node (i32, etc.)
    //Middle:    nil, - parameters
    //Right:     function_body_node, - function body

    try writeFunctionNameAndParameters(allocator, convert_data, node);

    if (node.right == null) {
        convert_data.error_detail = "node.Right is null";
        return ConvertError.Node_Is_Null;
    }

    convert_data.generated_code.appendLine(allocator, "entry:") catch return ConvertError.Out_Of_Memory;
    try llvm_body_script.processBody(allocator, convert_data, node.right.?);

    convert_data.generated_code.append(allocator, "\r}\n\n") catch return ConvertError.Out_Of_Memory;
}

fn writeFunctionNameAndParameters(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    convert_data.error_function = "writeFunctionNameAndParameters";

    if (node.left == null) {
        convert_data.error_detail = "node.Left is null";
        return ConvertError.Node_Is_Null;
    }

    const function_name:?Token = node.token;
    const return_type:?Token = node.left.?.token;

    if (function_name == null) {
        convert_data.error_detail = "node.Token is null";
        return ConvertError.Node_Is_Null;
    }
    if (return_type == null) {
        convert_data.error_detail = "node.Left.Token is null";
        return ConvertError.Node_Is_Null;
    }

    //write declaration

    const return_type_text:?[]const u8 = llvm_utils_script.convertToLLVMType(return_type.?);
    if (return_type_text == null) {
        convert_data.error_token = return_type.?;
        return ConvertError.Invalid_Return_Type;
    }

    convert_data.generated_code.appendFmt(allocator, "define {s} @{s}(", .{
        return_type_text.?,
        function_name.?.Text
    }) catch return ConvertError.Out_Of_Memory;

    if (node.middle != null) {
        try printParameters(allocator, convert_data, node);
    }

    convert_data.generated_code.append(allocator, ") {\n\t") catch return ConvertError.Out_Of_Memory;
}

fn printParameters(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    if (node.middle == null) {
        convert_data.error_detail = "Internal error: node.middle is null in printParameters";
        return ConvertError.Node_Is_Null;
    }
    if (node.middle.?.children == null) {
        convert_data.error_detail = "Internal error: node.middle.children is null in printParameters";
        return ConvertError.Node_Is_Null;
    }

    const child_count:usize = node.middle.?.children.?.items.len;
    const middle:*ASTNode = node.*.middle.?;

    if (child_count == 0) {
        return;
    }
    for (0..child_count) |i| {

        const child:?*ASTNode = middle.children.?.items[i];
        if (child == null) {
            convert_data.error_detail = "Internal error: child is null in printParameters";
            return ConvertError.Node_Is_Null;
        }
        if (child.?.token == null) {
            convert_data.error_detail = "Internal error: child.token is null in printParameters";
            return ConvertError.Node_Is_Null;
        }
        //localDefinitions.LocalVariables.Add(child);
        const parameter_name:[]const u8 = child.?.token.?.Text;

        const type_node:?*ASTNode = child.?.left;
        if (type_node == null) {
            convert_data.error_detail = "Internal error: type_node is null in printParameters";
            return ConvertError.Node_Is_Null;
        }

        //Recursively loop for the last node and expect it to a type
        var base_type_node:?*ASTNode = type_node;
        while (base_type_node.?.left != null) {
            base_type_node = base_type_node.?.left;
        }

        if (base_type_node == null) {
            convert_data.error_detail = "Internal error: base_type_node is null in printParameters";
            return ConvertError.Node_Is_Null;
        }
        if (base_type_node.?.token == null) {
            convert_data.error_detail = "Internal error: base_type_node.token is null in printParameters";
            return ConvertError.Node_Is_Null;
        }

        const var_type:?[]const u8 = llvm_utils_script.convertToLLVMType(base_type_node.?.token.?);

        // Now wrap it based on the chain of nodes
        var current:?*ASTNode = type_node;
        const full_type:[]const u8 = var_type.?;
        while (current != null and current != base_type_node)
        {
            //if (current.NodeType == ASTNodeType.Pointer) {
                //full_type = fullType + "*"; // Add pointer to the right
            //}
            //else if (current.NodeType == ASTNodeType.Array) {
                //fullType = $"Slice<{fullType}>"; // Wrap in Slice<>
            //}
            current = current.?.left;
        }

        //const i32 value = 10;
        //i32 number = 10;

        convert_data.generated_code.appendFmt(allocator, "{s} {s}", .{full_type, parameter_name}) catch {
            return ConvertError.Out_Of_Memory;
        };

        if (i < child_count - 1) {
            convert_data.generated_code.append(allocator, ", ") catch {
                return ConvertError.Out_Of_Memory; 
            };
        }
    }
}