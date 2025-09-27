


const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const debugging_script = @import("../debugging/debugging.zig");
const errors_script = @import("../core/errors.zig");
const llvm_utils_script = @import("llvm_utils.zig");
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


pub fn processReturn(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {
    //Node_type = ASTNode_Return;
    //Token = return_token; "return"
    //Right = value_node;

    //List<string> expressions = new();
    //string finalValue;

    //finalValue = CPPExpressions.FlattenExpression(ref cppData, node.Right, false, expressions, ref localDefinitions);

    //if (expressions.Count != 0) {

        //for (int i = 0; i < expressions.Count; i += 1) {
            //cppData.GeneratedCode.Append(expressions[i]);
            //cppData.GeneratedCode.Append('\n');
            //cppData.GeneratedCode.Append('\t');
        //}
    //}

    convert_data.error_function = "processReturn";

    if (node.right == null) {
        return ConvertError.Node_Is_Null;
    }
    if (node.right.?.token == null) {
        return ConvertError.Node_Is_Null;
    }

    convert_data.generated_code.appendFmt(allocator, "\tret i32 {s}\n", .{
        node.right.?.token.?.Text,
    }) catch return ConvertError.Out_Of_Memory;

    //cppData.GeneratedCode.Append($"return {finalValue};\n");
}