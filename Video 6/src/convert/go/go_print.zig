

const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const enums_script = @import("../../core/enums.zig");
const expressions_script = @import("../../core/expression.zig");
const errors_script = @import("../../core/errors.zig");
const flatten_expression_script = @import("go_flatten.zig");
const go_print_expression_script = @import("go_print_expressions.zig");
const print = std.debug.print;
const ASTNode = structs_script.ASTNode;
const TokenType = enums_script.TokenType;
const ASTData = structs_script.ASTData;
const Token = structs_script.Token;
const ASTNodeType = enums_script.ASTNodeType;
const AstError = errors_script.AstError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ConvertError = errors_script.ConvertError;
const ConvertData = structs_script.ConvertData;

pub fn processPrint(allocator:*Allocator, convert_data:*ConvertData, node:*ASTNode, new_line:bool) !void {
   
    //Children = nodes to print
    //node type - print or println
    //token - print token for debugging

    if (node.children == null) {
        convert_data.error_detail = "node.children is null";
        return ConvertError.Node_Is_Null;
    }

    try convert_data.addTab(allocator);

    const child_count:usize = node.children.?.items.len;

    if (child_count == 0) {

        if (new_line == true) {
            convert_data.generated_code.append(allocator, "fmt.println()\n\t") catch return ConvertError.Out_Of_Memory;
            try convert_data.addNLWithTabs(allocator);
        }
        return;
    }

    var print_elements:[][]const u8 = allocator.alloc([]const u8, child_count) catch return ConvertError.Out_Of_Memory;
    var index:usize = 0;

    for (0..child_count) |child_index| {

        const temp_child:?*ASTNode = node.*.children.?.items[child_index];
        if (temp_child == null) {
            convert_data.error_detail = "child node is null in processPrint";
            convert_data.error_token = node.token;
            return ConvertError.Node_Is_Null;
        }
        const child:*ASTNode = temp_child.?;

        var statements = ArrayList([]const u8).initCapacity(allocator.*, 0) catch {
            return ConvertError.Out_Of_Memory;
        };

        var final_value:[]const u8 = undefined;
        
        if (convert_data.compiler_settings.separate_expressions) {
            final_value = try flatten_expression_script.flattenExpression(allocator, convert_data, child, false, &statements);
        } else {
            final_value = try go_print_expression_script.printExpression(allocator, convert_data, child, false);
        }

        if (statements.items.len > 0) {
            for (0..statements.items.len) |i| {
                convert_data.generated_code.appendFmt(allocator, "{s}", .{statements.items[i]}) catch return ConvertError.Out_Of_Memory;
                try convert_data.addNLWithTabs(allocator);
            }
        }
        print_elements[index] = final_value;
        index += 1;
    }

    if (new_line) {
        convert_data.generated_code.append(allocator, "fmt.Println(") catch return ConvertError.Out_Of_Memory;
    } else {
        convert_data.generated_code.append(allocator, "fmt.Print(") catch return ConvertError.Out_Of_Memory;
    }

    for (0..child_count) |i| {
        if (i == 0) {
            convert_data.generated_code.appendFmt(allocator, "{s}", .{print_elements[i]}) catch return ConvertError.Out_Of_Memory;
            continue;
        }
        convert_data.generated_code.appendFmt(allocator, ", {s}", .{print_elements[i]}) catch return ConvertError.Out_Of_Memory;
    }

    convert_data.generated_code.append(allocator, ")") catch return ConvertError.Out_Of_Memory;
    try convert_data.addNLWithTabs(allocator);

}