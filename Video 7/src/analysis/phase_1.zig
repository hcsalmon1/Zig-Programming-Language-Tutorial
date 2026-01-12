const std = @import("std");
const errors_script = @import("../core/errors.zig");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const printing_script = @import("../core/printing.zig");
const analysis_utils_script = @import("analysis_utils.zig");
const TypeTag = enums_script.TypeTag;
const TypeId = structs_script.TypeId;
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
const Field = structs_script.Field;
const AnalysisData = structs_script.AnalysisData;
const EnumVariant = structs_script.EnumVariant;
const print = std.debug.print;
const SymbolId = structs_script.SymbolId;
const SymbolNameAndId = structs_script.SymbolNameAndId;
const Symbol = structs_script.Symbol;
const HashSet = structs_script.HashSet;

fn getStructName(allocator:*Allocator, node:*ASTNode, analysis_data:*AnalysisData) SemanticError!void {
    
    analysis_data.error_function = "getStructName";
    
    const struct_name:string = node.*.token.?.Text;
    const id:TypeId = try addType(allocator, analysis_data, struct_name, TypeTag.Struct);
    try analysis_data.type_list.type_map.appendID(allocator, struct_name, id);
}

fn getStructAndEnumNames(allocator:*Allocator, analysis_data:*AnalysisData) SemanticError!void {
    
    analysis_data.error_function = "getStructAndEnumNames";

    var node_index:usize = 0;

    while (node_index < analysis_data.node_count) {
        const last_index:usize = node_index;

        const node:*ASTNode = analysis_data.ast_nodes.items[node_index];

        if (node.node_type == ASTNodeType.StructDeclaration) {
            try getStructName(allocator, node, analysis_data);
        }

        if (last_index == node_index) {
            node_index += 1;
        }
    }
}

fn addType(allocator:*Allocator, analysis_data:*AnalysisData, name:string, tag:TypeTag) SemanticError!TypeId {
   
    analysis_data.error_function = "addType";

    const id:TypeId = @intCast(analysis_data.type_list.types.items.len);
    const var_type: Type = switch (tag) {
        .None => .{ .name = name, .data = .None },
        .Void => .{ .name = name, .data = .Void },
        .Int32 => .{ .name = name, .data = .Int32 },
        .Int64 => .{ .name = name, .data = .Int64 },
        .F32 => .{ .name = name, .data = .F32 },
        .F64 => .{ .name = name, .data = .F64 },
        .Bool => .{ .name = name, .data = .Bool },
        .Char => .{ .name = name, .data = .Char },
        .String => .{ .name = name, .data = .String },

        .Struct => .{
            .name = name,
            .data = .{
                .Struct = .{
                    .fields = ArrayList(Field)
                        .initCapacity(allocator.*, 0)
                        catch return SemanticError.Out_Of_Memory,
                },
            },
        },

        .Enum => .{
            .name = name,
            .data = .{
                .Enum = .{
                    .variants = ArrayList(EnumVariant)
                        .initCapacity(allocator.*, 0)
                        catch return SemanticError.Out_Of_Memory,
                },
            },
        },

        // These MUST NOT be created here
        .Pointer, .Array, .Function => {
            return SemanticError.Internal_Error;
        },
    };
    analysis_data.type_list.types.append(allocator.*, var_type) catch return SemanticError.Out_Of_Memory;
    return id;
}

fn addPrimitiveTypes(allocator:*Allocator, analysis_data:*AnalysisData) SemanticError!void {

    analysis_data.error_function = "addPrimitiveTypes";

    var id:TypeId = undefined;
    id = try addType(allocator, analysis_data, "int", TypeTag.Int32);
    try analysis_data.type_list.type_map.appendID(allocator, "int", id);

    id = try addType(allocator, analysis_data, "bool", TypeTag.Bool);
    try analysis_data.type_list.type_map.appendID(allocator, "bool", id);

    id = try addType(allocator, analysis_data, "string", TypeTag.String);
    try analysis_data.type_list.type_map.appendID(allocator, "string", id);

    id = try addType(allocator, analysis_data, "char", TypeTag.Char);
    try analysis_data.type_list.type_map.appendID(allocator, "char", id);
    
    id = try addType(allocator, analysis_data, "void", TypeTag.Void);
    try analysis_data.type_list.type_map.appendID(allocator, "void", id);

    id = try addType(allocator, analysis_data, "f32", TypeTag.F32);
    try analysis_data.type_list.type_map.appendID(allocator, "f32", id);

    id = try addType(allocator, analysis_data, "f64", TypeTag.F64);
    try analysis_data.type_list.type_map.appendID(allocator, "f64", id);
}

fn resolveStructBodiesDebug(allocator:*Allocator, analysis_data:*AnalysisData) SemanticError!void {

    analysis_data.error_function = "resolveStructBodiesDebug";

    print("\n=== resolveStructBodies: start ===\n", .{});

    for (0..analysis_data.node_count) |i| {

        const node:*ASTNode = analysis_data.ast_nodes.items[i];

        print("\n[Node {}] AST node type: {}\n", .{ i, node.node_type });

        if (node.node_type != ASTNodeType.StructDeclaration) {
            print("  Skipping: not a StructDeclaration\n", .{});
            continue;
        }

        // 1. Struct name
        if (node.token == null) {
            print("  ERROR: StructDeclaration without token\n", .{});
            return SemanticError.Internal_Error;
        }

        const struct_name:string = node.token.?.Text;

        print("  Struct name: {s}\n", .{ struct_name });

        // 2. Lookup TypeId
        const struct_id: TypeId = analysis_data.type_list.type_map.getIdFromName(struct_name) orelse {
                    print("  ERROR: struct name not found in type_map\n", .{});
                    return SemanticError.Internal_Error;
                };

        print("  Struct TypeId: {}\n", .{ struct_id });

        {
            var struct_type = &analysis_data.type_list.types.items[struct_id];

            print("  Type before fill:\n", .{});
            struct_type.print();

            switch (struct_type.data) {
                .Struct => {
                    print("  Type is Struct (OK)\n", .{});
                },
                else => {
                    print("  ERROR: TypeId {} is not Struct\n", .{ struct_id });
                    return SemanticError.Internal_Error;
                },
            }
        }

        {
            var struct_type = &analysis_data.type_list.types.items[struct_id];

            print("  Initializing struct fields array\n", .{});

            struct_type.data = .{
                .Struct = .{
                    .fields = ArrayList(Field)
                        .initCapacity(allocator.*, 0)
                        catch {
                            print("  ERROR: Out of memory allocating fields\n", .{});
                            return SemanticError.Out_Of_Memory;
                        },
                },
            };
        }

        // 5. Get members node
        const members_node:*ASTNode =
            node.right orelse {
                print("  ERROR: Struct has no members node\n", .{});
                return SemanticError.Invalid_Struct_Declaration;
            };

        print("  Members node type: {}\n", .{ members_node.node_type });

        const members:ArrayList(*ASTNode) =
            members_node.children orelse {
                print("  ERROR: Members node has no children\n", .{});
                return SemanticError.Invalid_Struct_Declaration;
            };

        print("  Member count: {}\n", .{ members.items.len });

        // 6. Walk members
        for (members.items, 0..) |member_node, m| {

            print("    [Field {}] node type: {}\n", .{ m, member_node.node_type });

            if (member_node.node_type != ASTNodeType.StructMember) {
                print("    ERROR: Invalid member node type\n", .{});
                return SemanticError.Invalid_Struct_Declaration;
            }

            if (member_node.token == null) {
                print("    ERROR: StructMember missing name token\n", .{});
                return SemanticError.Invalid_Struct_Declaration;
            }

            const field_name = member_node.token.?.Text;

            print("    Field name: {s}\n", .{ field_name });

            const type_ast:*ASTNode =
                member_node.left orelse {
                    print("    ERROR: Field has no type AST\n", .{});
                    return SemanticError.Invalid_Struct_Declaration;
                };

            print("    Resolving field type AST...\n", .{});

            const field_type_id:TypeId = try analysis_utils_script.resolveTypeFromAst(allocator, analysis_data, type_ast);

            print("    Resolved field type id: {}\n", .{ field_type_id });

            print("    Field type info:\n", .{});
            analysis_data.type_list.types.items[field_type_id].print();

            {
                const struct_type:*Type = &analysis_data.type_list.types.items[struct_id];

                struct_type.data.Struct.fields.append(
                    allocator.*,
                    .{
                        .name = field_name,
                        .type = field_type_id,
                    },
                ) catch {
                    print("    ERROR: Out of memory appending field\n", .{});
                    return SemanticError.Out_Of_Memory;
                };
            }

            print("    Field appended successfully\n", .{});
        }

        {
            const struct_type:*const Type = &analysis_data.type_list.types.items[struct_id];
            print("  Struct after fill:\n", .{});
            struct_type.print();
        }
    }

    print("\n=== resolveStructBodies: end ===\n", .{});
}

fn getParameterTypes(allocator:*Allocator, analysis_data:*AnalysisData, middle_node:*ASTNode, parameter_types:*ArrayList(TypeId)) SemanticError!void {

    analysis_data.error_function = "getParameterTypes";

    //|-.FunctionDeclaration 'add' - base
    //| |-.VarType 'int' - left
    //| |-.Parameters NA - middle
    //| | |-.Parameter 'a' - child
    //| |   |-.VarType 'int' - left
    //| | |-.Parameter 'b' - child
    //| |   |-.VarType 'int' - left

    if (middle_node.children == null) {
        return SemanticError.Type_ArrayList_Is_Null;
    }

    const children:ArrayList(*ASTNode) = middle_node.children.?;

    const child_count:usize = middle_node.children.?.items.len;
    for (0..child_count) |i| {
        const parameter_node:*ASTNode = children.items[i];
        const parameter_type_id:TypeId = try analysis_utils_script.resolveTypeFromAst(allocator, analysis_data, parameter_node);
        parameter_types.append(allocator.*, parameter_type_id) catch return SemanticError.Out_Of_Memory;
    }   
}

fn collectFunction(allocator:*Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    analysis_data.error_function = "collectFunction";

    const name:string = node.token.?.Text;

    if (analysis_data.type_list.symbolTableContains(name) == true) {
        return SemanticError.Duplicate_Symbol;
    }

    // Resolve return type
    const ret_type_ast:*ASTNode = node.left orelse return SemanticError.Invalid_Function;

    const return_type:TypeId = try analysis_utils_script.resolveTypeFromAst(allocator, analysis_data, ret_type_ast);

    // Resolve params
    var parameter_types = ArrayList(TypeId).initCapacity(allocator.*, 0) catch return SemanticError.Out_Of_Memory;

    if (node.middle) |middle_node| {
        try getParameterTypes(allocator, analysis_data, middle_node, &parameter_types);
    }

    const func_type_id:TypeId = analysis_utils_script.getOrCreateFunctionType(allocator, analysis_data, parameter_types, return_type) catch return SemanticError.Out_Of_Memory;

    var symbols:*ArrayList(Symbol) = &analysis_data.type_list.symbol_table.symbols;
    const symbol_id:SymbolId = @intCast(symbols.items.len);

    symbols.append(allocator.*, .{
        .name = name,
        .kind = .Function,
        .type = func_type_id,
    }) catch return SemanticError.Out_Of_Memory;

    var symbol_map:*HashSet(SymbolNameAndId) = &analysis_data.type_list.symbol_table.symbol_map;

    const symbol_and_name:SymbolNameAndId = .{
        .id = symbol_id,
        .name = name,
    };
    const successful_add:bool = symbol_map.add(allocator, symbol_and_name) catch return SemanticError.Out_Of_Memory;
    if (successful_add == false) {
        return SemanticError.Duplicate_Symbol;
    }

    node.symbol_id = symbol_id;
    node.type_id = func_type_id;
}

fn resolveGlobalVariables(allocator:*Allocator, analysis_data:*AnalysisData, node:*ASTNode) SemanticError!void {

    if (node.node_type != ASTNodeType.Declaration) {
        return;
    }

    // 1. Name
    const name_token:Token = node.token orelse return SemanticError.Invalid_Global_Declaration;
    const var_name:string = name_token.Text;

    // 2. Type AST
    const type_ast:*ASTNode = node.left orelse return SemanticError.Invalid_Global_Declaration;

    const type_id:TypeId = try analysis_utils_script.resolveTypeFromAst(allocator, analysis_data, type_ast);

    // 3. Insert symbol
    var symbols:*ArrayList(Symbol) = &analysis_data.type_list.symbol_table.symbols;

    const symbol_id:SymbolId = @intCast(symbols.items.len);

    symbols.append(allocator.*, .{
        .name = var_name,
        .kind = .GlobalVar,
        .type = type_id,
        .is_const = node.is_const,
    }) catch return SemanticError.Out_Of_Memory;

    // 4. Add to symbol map
    var symbol_map:*HashSet(SymbolNameAndId) = &analysis_data.type_list.symbol_table.symbol_map;

    const entry:SymbolNameAndId = .{
        .id = symbol_id,
        .name = var_name,
    };

    const symbol_successfully_added:bool = symbol_map.add(allocator, entry) catch return SemanticError.Out_Of_Memory;

    if (symbol_successfully_added == false) {
        return SemanticError.Duplicate_Symbol;
    }

    // 5. Annotate AST
    node.symbol_id = symbol_id;
    node.type_id = type_id;
}

fn resolveStructBodies(allocator:*Allocator, analysis_data:*AnalysisData) SemanticError!void {

    analysis_data.error_function = "resolveStructBodies";

    for (0..analysis_data.node_count) |i| {

        const node:*ASTNode = analysis_data.ast_nodes.items[i];

        if (node.node_type != ASTNodeType.StructDeclaration) {
            continue;
        }

        // 1. Struct name
        if (node.token == null) {
            return SemanticError.Internal_Error;
        }

        const struct_name:string = node.token.?.Text;

        // 2. Lookup TypeId
        const struct_id:TypeId = analysis_data.type_list.type_map.getIdFromName(struct_name) orelse {
            return SemanticError.Internal_Error;
        };
        
        var struct_type:*Type = analysis_data.getTypeFromId(struct_id);

        switch (struct_type.data) {
            .Struct => {
            },
            else => {
                return SemanticError.Internal_Error;
            },
        }
                
        struct_type.data = .{
            .Struct = .{
                .fields = ArrayList(Field).initCapacity(allocator.*, 0) catch return SemanticError.Out_Of_Memory,
            },
        };
        
        // 5. Get members node
        const members_node:*ASTNode = node.right orelse {
            return SemanticError.Invalid_Struct_Declaration;
        };

        const members:ArrayList(*ASTNode) = members_node.children orelse {
            return SemanticError.Invalid_Struct_Declaration;
        };

        // 6. Walk members
        for (members.items) |member_node| {

            if (member_node.node_type != ASTNodeType.StructMember) {
                return SemanticError.Invalid_Struct_Declaration;
            }

            if (member_node.token == null) {
                return SemanticError.Invalid_Struct_Declaration;
            }

            const field_name = member_node.token.?.Text;

            const type_ast:*ASTNode = member_node.left orelse {
                return SemanticError.Invalid_Struct_Declaration;
            };

            const field_type_id:TypeId = try analysis_utils_script.resolveTypeFromAst(allocator, analysis_data, type_ast);

            //Get the pointer again just in case the append invalidated it
            struct_type = analysis_data.getTypeFromId(struct_id);

            struct_type.data.Struct.fields.append(
                allocator.*,
                .{
                    .name = field_name,
                    .type = field_type_id,
                },
            ) catch {
                return SemanticError.Out_Of_Memory;
            };
        }
    }
}

fn getFunctionsAndGlobals(allocator:*Allocator, analysis_data:*AnalysisData) SemanticError!void {
    
    analysis_data.error_function = "getFunctionsAndGlobals";

    for (0..analysis_data.node_count) |i| {
        const node:*ASTNode = analysis_data.ast_nodes.items[i];
        switch (node.node_type) {
            .FunctionDeclaration => try collectFunction(allocator, analysis_data, node),
            .Declaration => try resolveGlobalVariables(allocator, analysis_data, node),
            else => {}
        }
    }

}

pub fn runSemanticCheckingPhase1(allocator:*Allocator, analysis_data:*AnalysisData) SemanticError!void {
   
    analysis_data.error_function = "runSemanticCheckingPhase1";

    try addPrimitiveTypes(allocator, analysis_data);
    try getStructAndEnumNames(allocator, analysis_data);
    try resolveStructBodies(allocator, analysis_data);
    try getFunctionsAndGlobals(allocator, analysis_data);
}