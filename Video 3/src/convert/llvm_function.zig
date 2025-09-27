


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

    //Parameters TO DO !!!!!
    convert_data.generated_code.append(allocator, ") {\n\t") catch return ConvertError.Out_Of_Memory;
}