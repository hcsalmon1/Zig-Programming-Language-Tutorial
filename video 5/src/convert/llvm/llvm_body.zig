


const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const printing_script = @import("../../core/printing.zig");
const enums_script = @import("../../core/enums.zig");
const debugging_script = @import("../../Debugging/debugging.zig");
const errors_script = @import("../../core/errors.zig");
const llvm_utils_script = @import("llvm_utils.zig");
const llvm_return_script = @import("llvm_return.zig");
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
        try processFunctionBodyNode(allocator, convert_data, child);
    }
}

fn processFunctionBodyNode(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode) ConvertError!void {

    const node_type:ASTNodeType = node.node_type;

    if (node_type == ASTNodeType.Invalid) {
        convert_data.error_token = node.token;
        return ConvertError.Invalid_Node_Type;
    }

    switch (node_type) {

        ASTNodeType.Return => try llvm_return_script.processReturn(allocator, convert_data, node),
        //ASTNodeType.Declaration => try CppDeclaration.ProcessDeclaration(allocator, convert_data, node),
        //ASTNodeType.Print => try CppPrint.processPrint(allocator, convert_data, node, false),
        //ASTNodeType.Println => try CppPrint.processPrint(allocator, convert_data, true),
        //ASTNodeType.FunctionCall => try processFunctionCall(allocator, convert_data, node),
        //ASTNodeType.IfStatement => try CppIf.processIfStatement(allocator, convert_data, node),
        //ASTNodeType.WhileLoop => try CppWhile.processWhile(allocator, convert_data, node),
        //ASTNodeType.ForLoop => try CppFor.processForLoop(allocator, convert_data, node),
        //ASTNodeType.DereferenceAssignment => CppAssignment.ProcessDereferenceAssignment(allocator, convert_data, node),
        //ASTNodeType.Assignment => CppAssignment.ProcessAssignment(allocator, convert_data, node),
        //ASTNodeType.ArrayDeclaration => CppArray.WriteArrayDeclaration(allocator, convert_data, node),
        //ASTNodeType.PointerDeclaration => CppPointers.WritePointerDeclaration(allocator, convert_data, node),
        //ASTNodeType.Comment => {
            //cppData.GeneratedCode.Append('/');
            //cppData.GeneratedCode.Append('/');
            //Debug.Assert(node.Children != null);
            //if (node.Children.Count != 0) {
//
                //for (int i = 0; i < node.Children.Count; i++) {
                    //ASTNode? child = node.Children[i];
                    //Debug.Assert(child != null);
                    //Debug.Assert(child.Token != null);
                    //cppData.GeneratedCode.Append(child.Token.Value.Text);
                    //cppData.GeneratedCode.Append(' ');
                //}
            //}
            //cppData.GeneratedCode.Append('\n');
            //cppData.GeneratedCode.Append('\t');
        //},
//        
        //case ASTNodeType.Continue:
            //cppData.GeneratedCode.Append("continue;");
            //cppData.GeneratedCode.Append('\n');
            //cppData.GeneratedCode.Append('\t');
            //break;
//
        //case ASTNodeType.Break:
            //cppData.GeneratedCode.Append("break;");
            //cppData.GeneratedCode.Append('\n');
            //cppData.GeneratedCode.Append('\t');
            //break;
//
        //default:
            //cppData.ErrorDetail = $"Unimplemented node type {nodeType}";
            //cppData.ErrorTrace.Append("processFunctionBodyNode");
            //cppData.ErrorToken = node.Token;
            ////cppData.CppResult = CPPConvertResult.Unimplemented_Node_Type;
              //  break;
        else => return,
    }
}