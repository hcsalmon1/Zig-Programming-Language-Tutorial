const std = @import("std");
const errors_script = @import("../core/errors.zig");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const printing_script = @import("../core/printing.zig");
const phase_1_script = @import("phase_1.zig");
const SemanticError = errors_script.SemanticError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ASTNode = structs_script.ASTNode;
const Token = structs_script.Token;
const TypeList = structs_script.TypeList;
const StringHashMap = std.StringHashMap;
const ASTNodeType = enums_script.ASTNodeType;
const string = []const u8;
const Type = structs_script.Type;
const TypeMap = structs_script.TypeMap;
const TypeId = structs_script.TypeId;
const TypeTag = enums_script.TypeTag;
const AnalysisData = structs_script.AnalysisData;

pub fn resolveTypeFromAst(allocator:*Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!TypeId {

    analysis_data.error_function = "resolveTypeFromAst";

    switch (node.node_type) {

        ASTNodeType.VarType => {
            const name:string = node.token.?.Text;

            return analysis_data.type_list.type_map.getIdFromName(name) orelse return SemanticError.Unknown_Type;
        },

        ASTNodeType.Pointer => {
            const child:*ASTNode = node.left orelse return SemanticError.Invalid_Type_Expression;

            const elem_id = try resolveTypeFromAst(allocator, analysis_data, child);

            return try getOrCreatePointerType(allocator, analysis_data, elem_id);
        },

        ASTNodeType.Array => {
            const child:*ASTNode = node.left orelse return SemanticError.Invalid_Type_Expression;

            const elem_id:TypeId = try resolveTypeFromAst(allocator, analysis_data, child);
            return try getOrCreateArrayType(allocator, analysis_data, elem_id, node.size);
        },

        ASTNodeType.Parameter => {
            const type_node:*ASTNode = node.left orelse return SemanticError.Invalid_Type_Expression;
            return resolveTypeFromAst(allocator, analysis_data, type_node);
        },

        else => {
            analysis_data.error_detail = std.fmt.allocPrint(allocator.*, "nodetype {} invalid", .{node.node_type}) catch return SemanticError.Out_Of_Memory;
            return SemanticError.Invalid_Type_Expression;
        },
    }
}

fn getOrCreatePointerType(allocator:*Allocator, analysis_data:*AnalysisData, elem:TypeId) SemanticError!TypeId {

    // 1. Look for existing pointer type
    const type_count:usize = analysis_data.type_list.types.items.len;
    for (0..type_count) |i| {
        const var_type:Type = analysis_data.type_list.types.items[i];

        switch (var_type.data) {
            .Pointer => |p| {
                if (p.elem == elem) {
                    return @intCast(i);
                }
            },
            else => {},
        }
    }

    // 2. Create new one
    const id:TypeId = @intCast(analysis_data.type_list.types.items.len);

    const _type:Type = .{
        .name = null,
        .data = .{
            .Pointer = .{
                .elem = elem,
            },
        }
    };

    analysis_data.type_list.types.append(allocator.*, _type) catch return SemanticError.Out_Of_Memory;

    return id;
}

fn getOrCreateArrayType(allocator:*Allocator, analysis_data:*AnalysisData, elem:TypeId, len:?usize) SemanticError!TypeId {

    // 1. Look for existing array type
    const type_count:usize = analysis_data.type_list.types.items.len;
    for (0..type_count) |i| {
        const var_type:Type = analysis_data.type_list.types.items[i];

        switch (var_type.data) {
            .Array => |a| {
                if (a.elem == elem and a.len == len) {
                    return @intCast(i);
                }
            },
            else => {},
        }
    }

    // 2. Create new one
    const id: TypeId = @intCast(analysis_data.type_list.types.items.len);

    analysis_data.type_list.types.append(allocator.*, .{
        .name = null,
        .data = .{
            .Array = .{
                .elem = elem,
                .len = len,
            },
        },
    }) catch return SemanticError.Out_Of_Memory;

    return id;
}

pub fn getOrCreateFunctionType(allocator:*std.mem.Allocator, analysis_data:*AnalysisData, parameter_types:ArrayList(TypeId), return_type:TypeId) !TypeId {

    // 1. Search existing types

    const types:ArrayList(Type) = analysis_data.type_list.types;
    const type_count:usize = types.items.len;

    for (0..type_count) |var_type_index| {

        const var_type:Type = types.items[var_type_index];

        switch (var_type.data) {
            .Function => |func| {
                if (func.return_type != return_type) continue;
                if (func.parameters.items.len != parameter_types.items.len) continue;

                var same:bool = true;
                const parameter_count:usize = func.parameters.items.len;
                for (0..parameter_count) |parameter_index| {

                    const saved_parameter:TypeId = func.parameters.items[parameter_index];
                    const input_parameter:TypeId = parameter_types.items[parameter_index];
                    if (saved_parameter != input_parameter) {
                        same = false;
                        break;
                    }
                }

                if (same) {
                    return @intCast(var_type_index);
                }
            },
            else => {},
        }
    }

    // 3. Create new function type
    const new_type = Type{
        .name = null,
        .data = .{
            .Function = .{
                .parameters = parameter_types,
                .return_type = return_type,
            },
        },
    };

    // 4. Append to type list
    try analysis_data.type_list.types.append(allocator.*, new_type);

    return @intCast(analysis_data.type_list.types.items.len - 1);
}