
const std = @import("std");
const errors_script = @import("../core/errors.zig");
const structs_scripts = @import("../core/structs.zig");
const enums_scripts = @import("../core/enums.zig");
const SemanticError = errors_script.SemanticError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ASTNode = structs_scripts.ASTNode;
const Token = structs_scripts.Token;
const GlobalDefinitions = structs_scripts.GlobalDefinitions;
const StringHashMap = std.StringHashMap;
const FunctionDefinition = structs_scripts.FunctionDefinition;
const VariableDefinition = structs_scripts.VariableDefinition;
const ASTNodeType = enums_scripts.ASTNodeType;

pub fn analyseCode(allocator:*Allocator, ast_nodes:ArrayList(*ASTNode), code:[]const u8) SemanticError!GlobalDefinitions {

    const global_variable_map = StringHashMap(FunctionDefinition).init(allocator.*);
    const function_map = StringHashMap(VariableDefinition).init(allocator.*);

    var global_definitions:GlobalDefinitions = .{
        .Functions = global_variable_map,
        .Variables = function_map,
    };

    var node_index:usize = 0;
    const node_count = ast_nodes.items.len;

    while (node_index < node_count) {
        const last_index = node_index;

        const ast_node:*ASTNode = ast_nodes.items[node_index];
        
        if (ast_node.node_type == ASTNodeType.FunctionDeclaration) {
            const function_definition:FunctionDefinition = .{
                .name = ast_node.*.token.?.Text,
                .parameters = ast_node.*.middle.?.children,
                .return_type_node = ast_node.*.left.?,
            };
            try global_definitions.appendFunction(function_definition);
        }
        if (ast_node.node_type == ASTNodeType.Declaration) {
            const var_definition:VariableDefinition = .{
                .name = ast_node.token.?.Text,
                .type_node = ast_node.left.?,
            };
            try global_definitions.appendGlobalVariable(var_definition);
        }

        if (last_index == node_index) {
            node_index += 1;
        }
    }
    _ = code;

    return global_definitions;
}