
const std = @import("std");
const enum_script = @import("enums.zig");
const error_script = @import("errors.zig");
const debugging_script = @import("../debugging/debugging.zig");
const printing_script = @import("../core/printing.zig");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const ASTNodeType = enum_script.ASTNodeType;
const TokenType = enum_script.TokenType;
const AstError = error_script.AstError;
const LanguageTarget = enum_script.LanguageTarget;
const Allocator = std.mem.Allocator;
const ConvertError = error_script.ConvertError;
const SemanticError = error_script.SemanticError;
const StringHashMap = std.StringHashMap;
const string = []const u8;
const TypeTag = enum_script.TypeTag;
pub const TypeId = usize;
pub const SymbolId = usize;
const SymbolTag = enum_script.SymbolTag;


pub const CompilerSettings = struct {
    language_target: LanguageTarget = LanguageTarget.Go,
    separate_expressions:bool = false,
    show_tokens:bool = false,
    show_ast_nodes:bool = false,
    show_input_code:bool = false,
    show_output_code:bool = false,
    show_definitions:bool = false,
    output_to_file:bool = true,
    debug_complex_declarations:bool = false,
};

pub const ParseData = struct {

    token_list:*ArrayList(Token),
    last_token: ?Token = null,
    character_index:usize = 0,
    code:[]const u8 = "",
    line_count:usize = 0, //for token position
    char_count:usize = 0,
    was_comment:bool = false,
};

pub const ASTData = struct {

    ast_nodes:*ArrayList(*ASTNode),
    token_index:usize = 0,
    token_list:ArrayList(Token),
    error_detail:?[]const u8 = null,
    error_token:?Token = null,
    error_function:?[]const u8 = null,
    compiler_settings:*const CompilerSettings,

    pub fn getToken(self:*ASTData) AstError!Token {
        if (self.token_index >= self.token_list.items.len) {
            return AstError.Index_Out_Of_Range;
        }
        const token:Token = self.token_list.items[self.token_index];
        self.error_token = token;
        return token;
    }

    pub fn getNextToken(self:*ASTData) AstError!Token {
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            return AstError.Index_Out_Of_Range;
        }
        const token:Token = self.token_list.items[self.token_index];
        self.error_token = token;
        return token;
    }

    pub fn setErrorData(self:*ASTData, error_message:[]const u8, error_token:Token) void {
        self.error_detail = error_message;
        self.error_token = error_token;
    }

    fn getLastToken(self:*const ASTData) ?Token {
        if (self.token_list.items.len == 0) {
            return null;
        }
        return self.token_list.items[self.token_list.items.len - 1];
    }

    pub fn incrementIndex(self:*ASTData) !void {
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            self.error_token = getLastToken(self);
            return AstError.Unexpected_End_Of_File;
        }
    }
    
    pub fn incrementIndexIfSame(self:*ASTData, prev_index:usize) !void {
        if (prev_index == self.token_index) {
            return;
        }
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            return AstError.Index_Out_Of_Range;
        }
    }

    pub fn expectType(self:*ASTData, expected_type:TokenType, detail:[]const u8) AstError!void {
        const token:Token = try getToken(self);
        if (token.Type != expected_type) {
            self.error_detail = detail;
            self.error_token = token;
            return AstError.Missing_Expected_Type;
        }
    }

    pub fn isInfiniteLoop(self:*const ASTData, count:usize, max:usize) AstError!void {
        _ = self;
        if (count >= max) {
            return AstError.Infinite_While_Loop;
        }
    }

    pub fn tokenIndexInBounds(self:*const ASTData) bool {
        if (self.token_index >= self.token_list.items.len) {
            return false;
        }
        return true;
    }

    pub fn logComplexDeclarations(self:*const ASTData, allocator:*Allocator, comptime fmt: []const u8, args: anytype) AstError!void {
        
        if (self.compiler_settings.debug_complex_declarations == false) {
            return;
        }
        const message:[]u8 = std.fmt.allocPrint(allocator.*, fmt, args) catch return AstError.Out_Of_Memory;
        print("{s}\n", .{message});
    }
};

pub const ConvertData = struct {
    ast_nodes:std.ArrayList(*ASTNode),
    node_index:usize = 0,
    error_detail:?[]const u8 = null,
    error_token:?Token = null,
    error_function:?[]const u8 = null,
    generated_code:*StringBuilder,
    temp_var_count:usize = 0,
    function_return_type:?[]const u8 = null,
    index_count:usize = 0,
    compiler_settings:*const CompilerSettings,

    pub fn getNode(self:*const ConvertData) ?*ASTNode {
        if (self.node_index >= self.ast_nodes.items.len) {
            return null;
        }
        return self.ast_nodes.items[self.node_index];
    }
    pub fn getTempVarName(self:*ConvertData, allocator:*Allocator) ConvertError![]const u8 {

        const input:[]u8 = std.fmt.allocPrint(allocator.*, "%temp_var_{}", .{self.temp_var_count}) catch {
            return ConvertError.Out_Of_Memory;
        };
        self.temp_var_count += 1;
        return input;
    }
    fn traverseAndAddTypeNodes(self:*ConvertData, allocator:*Allocator, return_type_builder:*ArrayList(u8), node:*ASTNode) ConvertError!void {
        if (node.node_type == ASTNodeType.Array) {
            
            return_type_builder.append(allocator.*, '[') catch return ConvertError.Out_Of_Memory;
            return_type_builder.append(allocator.*, ']') catch return ConvertError.Out_Of_Memory;

            if (node.*.left != null) {
                try traverseAndAddTypeNodes(self, allocator, return_type_builder, node.*.left.?);
            }
            return;
        }
        if (node.*.token == null) {
            self.error_detail = "function return type token is null";
            return ConvertError.Node_Is_Null;
        }
        for (node.*.token.?.Text) |character| {
            return_type_builder.append(allocator.*, character) catch return ConvertError.Out_Of_Memory;
        }
        if (node.*.left != null) {
            try traverseAndAddTypeNodes(self, allocator, return_type_builder, node.*.left.?);
        }
    }
    pub fn printType(self:*ConvertData, allocator:*Allocator, function_return_node:?*ASTNode) ConvertError![]const u8 {

        var return_type_builder = ArrayList(u8).initCapacity(allocator.*, 0) catch return ConvertError.Out_Of_Memory;

        if (function_return_node == null) {
            self.error_detail = "function return type node is null";
            return ConvertError.Node_Is_Null;
        }
        if (function_return_node.?.token == null and function_return_node.?.node_type != ASTNodeType.Array) {
            self.error_detail = "function return type token is null";
            return ConvertError.Node_Is_Null;
        }

        //return_type_builder.append(allocator.*, )

        if (function_return_node != null) {
            try traverseAndAddTypeNodes(self, allocator, &return_type_builder, function_return_node.?);
        }

        const builder_length:usize = return_type_builder.items.len;
        if (builder_length == 0) {
            self.error_detail = "function return type builder had no length";
            return ConvertError.Internal_Error;            
        }
        var var_type_text:[]u8 = allocator.alloc(u8, return_type_builder.items.len) catch return ConvertError.Out_Of_Memory;
        for (0..builder_length) |i| {
            const character:u8 = return_type_builder.items[i];
            var_type_text[i] = character;
        }
        self.function_return_type = var_type_text;

        return return_type_builder.toOwnedSlice(allocator.*) catch return ConvertError.Out_Of_Memory;
    }
    pub fn incrementIndexCount(self:*ConvertData) void {
        self.index_count += 1;
    }
    pub fn decrementIndexCount(self:*ConvertData) void {
        if (self.index_count == 0) {
            return;
        }
        self.index_count -= 1;
    }
    pub fn printIndexCount(self:*const ConvertData) void {
        print("\tincrement index {}\n", .{self.index_count});
    }
    pub fn addTabs(self:*ConvertData, allocator:*Allocator) ConvertError!void {
        if (self.index_count == 0) {
            return;
        }
        const index_count_minus_one:usize = self.index_count - 1;
        for (0..index_count_minus_one) |_| {
            self.generated_code.append(allocator, "\t") catch return ConvertError.Out_Of_Memory;
        }
    }
    pub fn addTab(self:*ConvertData, allocator:*Allocator) ConvertError!void {
        self.generated_code.append(allocator, "\t") catch return ConvertError.Out_Of_Memory;
    }
    pub fn addNLWithTabs(self:*ConvertData, allocator:*Allocator) ConvertError!void {
        self.generated_code.append(allocator, "\n") catch return ConvertError.Out_Of_Memory;
        try addTabs(self, allocator);
    }
    pub fn appendCode(self:*ConvertData, allocator:*Allocator, comptime input:[]const u8) ConvertError!void {
        self.generated_code.append(allocator, input) catch return ConvertError.Out_Of_Memory;
    }   
    pub fn appendCodeFmt(self:*ConvertData, allocator:*Allocator, comptime input:[]const u8, args: anytype) ConvertError!void {
        self.generated_code.appendFmt(allocator, input, args) catch return ConvertError.Out_Of_Memory;
    }   
    pub fn appendCodeLine(self:*ConvertData, allocator:*Allocator, comptime input:[]const u8) ConvertError!void {
        self.generated_code.appendLine(allocator, input) catch return ConvertError.Out_Of_Memory;
    }  
    pub fn appendCodeLineFmt(self:*ConvertData, allocator:*Allocator, comptime input:[]const u8, args: anytype) ConvertError!void {
        self.generated_code.appendLineFmt(allocator, input, args) catch return ConvertError.Out_Of_Memory;
    }   
};

pub const AnalysisData = struct {
    ast_nodes:*ArrayList(*ASTNode),
    node_index:usize,
    node_count:usize,
    type_list:*TypeList,
    error_detail:?string = null,
    error_token:?Token = null,
    error_function:?string = null,
    compiler_settings:*const CompilerSettings,

    const Self = @This();

    pub fn resetNodeIndex(self:*Self) void {
        self.node_index = 0;
    }
    pub fn indexInBounds(self:*const Self) bool {
        return self.node_index < self.node_count;
    }
    pub fn incrementIfSame(self:*Self, previous_index:usize) void {
        if (self.node_index == previous_index) {
            self.node_index += 1;
        }
    }
    pub fn setError(self:*Self, detail:string, error_token:?Token) void {
        self.error_detail = detail;
        self.error_token = error_token;
    }
    pub fn getTypeFromId(self:*const Self, id:TypeId) *Type {
        return &self.type_list.types.items[id];
    }   
};

pub const Token = struct {
    Text: []const u8,
    Type: TokenType,
    LineNumber: usize = 0,
    CharNumber: usize = 0,

    pub fn PrintValues(self:*const Token) void {
        std.debug.print("Token values:\n text: '{s}'\n type: {}\n line no: {}\n", .{
            self.Text,
            self.Type,
            self.LineNumber,
        });
    }
    pub fn IsType(self:*const Token, token_type: TokenType) bool {
        return self.Type == token_type;
    }
};

pub fn emptyToken() Token {
    return .{
        .Text = "",
        .Type = TokenType.Int,
        .LineNumber = 0,
        .CharNumber = 0,
    };
}

pub const ASTNode = struct {

    node_type:ASTNodeType = ASTNodeType.Invalid,

    // These fields are optional depending on the kind
    token:?Token = null,       // Token, for literals, var types etc

    left:?*ASTNode = null,     // For expressions (e.g., a + b), return types
    middle:?*ASTNode = null,   // Rare, for things with 3, for loop, parameters
    right:?*ASTNode = null,      // right side of arithmetic a + b;, right = b
    children: ?std.ArrayList(*ASTNode),    // For blocks, function bodies, etc.

    is_const:bool = false,
    size:usize = 0,  //array size

    type_id:?TypeId = null,        // Type of this expression / declaration
    symbol_id:?SymbolId = null,    // For vars, params, functions

    pub fn MakeAllNull(self:*ASTNode) void {
        self.Left = null;
        self.Middle = null;
        self.Right = null;
        self.Children = null;
        self.Token = null;
    }

    pub fn appendChild(self:*ASTNode, allocator:*Allocator, node:*ASTNode) AstError!void {
        if (self.children == null) {
            return AstError.Children_ArrayList_Is_Null;
        }
        self.children.?.append(allocator.*, node) catch return AstError.Out_Of_Memory;
    }
};

pub const StringBuilder = struct {

    buffer: ArrayList(u8),
    
    const Self = @This();
    
    pub fn init(allocator: Allocator) !Self {
        return Self{
            .buffer = try ArrayList(u8).initCapacity(allocator, 0),
        };
    }
    
    pub fn deinit(self: *Self, allocator:*Allocator) void {
        self.buffer.deinit(allocator.*);
    }
    
    // Append a string
    pub fn append(self: *Self, allocator:*Allocator, str: []const u8) !void {
        try self.buffer.appendSlice(allocator.*, str);
    }
    
    // Append with formatting (like printf)
    pub fn appendFmt(self: *Self, allocator:*Allocator, comptime fmt: []const u8, args: anytype) !void {
        const input:[]u8 = try std.fmt.allocPrint(allocator.*, fmt, args);
        try self.append(allocator, input);
    }
    
    // Append a line (adds newline)
    pub fn appendLine(self: *Self, allocator:*Allocator, str: []const u8) !void {
        try self.buffer.appendSlice(allocator.*, str);
        try self.buffer.append(allocator.*, '\n');
    }
    
    // Append formatted line
    pub fn appendLineFmt(self: *Self, allocator:*Allocator, comptime fmt: []const u8, args: anytype) !void {
        const input:[]u8 = try std.fmt.allocPrint(allocator, fmt, args);
        try self.buffer.appendSlice(allocator.*, input);
        try self.buffer.append(allocator.*, '\n');
    }
    
    // Get the final string
    pub fn toString(self: *Self) []u8 {
        return self.buffer.items;
    }
    
    // Get owned slice (caller must free)
    pub fn toOwnedSlice(self: *Self, allocator:*Allocator) ![]u8 {
        return try self.buffer.toOwnedSlice(allocator.*);
    }
    
    // Clear the buffer
    pub fn clear(self: *Self) void {
        self.buffer.clearRetainingCapacity();
    }
    
    // Get length
    pub fn len(self: *Self) usize {
        return self.buffer.items.len;
    }
};

pub const TypeList = struct {

    types:ArrayList(Type),
    type_map:TypeMap,
    symbol_table:SymbolTable,

    const Self = @This();

    pub fn addType(self:*Self, allocator:*Allocator, type_to_add:Type) SemanticError!void {
        const type_count:usize = self.types.?.items.len;
        self.types.?.append(allocator.*, type_to_add) catch return SemanticError.Out_Of_Memory;
        const type_id:TypeId = @intCast(type_count);
        try self.type_map.?.appendID(allocator, type_id);
    }
    pub fn getTypeAtIndex(self:*const Self, index:TypeId) ?Type {
        const count:usize = self.types.items.len;
        if (index >= count) {
            return null;
        }
        return self.*.types.items[index];
    }
    pub fn printBaseTypes(self:*const Self) void {
        print("Printing Definition data:\n", .{});

        const count:usize = self.type_map.ids.items.len;
        if (count == 0) {
            print("\tType count is zero\n\n", .{});
        }
        for (0..count) |i| {
            const id:?TypeId = self.*.type_map.getIdAtIndex(i);
            if (id == null) {
                print("\tNull id, continue", .{});
                continue;
            }
            print("\tid: {}: ", .{id.?});
            const _type:?Type = self.getTypeAtIndex(i);
            if (_type == null) {
                print("Type is null\n", .{});
                continue;
            }
            _type.?.print();
        }  
    }
    pub fn printAllTypes(self: *const Self) void {
        print("Printing ALL types:\n", .{});

        const count = self.types.items.len;
        for (0..count) |i| {
            print("\tid: {}: ", .{ i });
            self.types.items[i].print();
        }
        printSymbols(self);
    }
    pub fn getIdFromName(self:*const Self, name:string) ?TypeId { 
        return self.type_map.getIdFromName(name);
    }
    pub fn symbolTableContains(self:*const Self, name:string) bool {
        const count:usize = self.symbol_table.symbol_map.items.items.len;
        for (0..count) |i| {
            const symbol_id_and_name:SymbolNameAndId = self.symbol_table.symbol_map.items.items[i];
            if (printing_script.twoSlicesAreTheSame(name, symbol_id_and_name.name) == true) {
                return true;
            }
        }
        return false;
    }
    pub fn printSymbols(self:*const Self) void {
        self.symbol_table.print();
    }
};

pub const Type = struct {

    name:?[]const u8 = null, // for structs / enums / debugging

    data:union(TypeTag) {
        None, Void, Int32, Int64, F32, F64, Bool, Char, String: void,

        Pointer: struct {
            elem:TypeId,
        },

        Array: struct {
            elem:TypeId,
            len:?usize,
        },

        Struct: struct {
            fields:ArrayList(Field),
        },

        Enum: struct {
            variants:ArrayList(EnumVariant),
        },

        Function: struct {
            parameters:ArrayList(TypeId),
            return_type:TypeId,
        },
    },

    const Self = @This();

    pub fn print(self:*const Self) void {
        if (self.name) |n| {
            std.debug.print("Type {s} ", .{ n });
        } else {
            std.debug.print("Type <anon> ", .{ });
        }

        switch (self.data) {

            .Pointer => {
                std.debug.print(
                    "  pointer -> TypeId {}\n",
                    .{ self.data.Pointer.elem },
                );
            },

            .Array => {
                if (self.data.Array.len) |l| {
                    std.debug.print(
                        "  array [{}] of TypeId {}\n",
                        .{ l, self.data.Array.elem },
                    );
                } else {
                    std.debug.print(
                        "  array [] of TypeId {}\n",
                        .{ self.data.Array.elem },
                    );
                }
            },

            .Struct => {
                const fields = &self.data.Struct.fields;
                std.debug.print(
                    "  struct with {} fields\n",
                    .{ fields.items.len },
                );

                for (fields.items) |field| {
                    std.debug.print(
                        "\t\t{s}: TypeId {}\n",
                        .{ field.name, field.type },
                    );
                }
            },

            .Enum => {
                const variants = &self.data.Enum.variants;
                std.debug.print(
                    "  enum with {} variants\n",
                    .{ variants.items.len },
                );

                for (variants.items) |v| {
                    std.debug.print("    {s}\n", .{ v.name });
                }
            },

            .Function => {

                const params:*const ArrayList(TypeId) = &self.data.Function.parameters;

                std.debug.print("  fn ({} params) -> TypeId {}\n",
                    .{ params.items.len, self.data.Function.return_type },
                );

                for (params.items, 0..) |param_id, i| {
                    if (i == 0) {
                        std.debug.print("\t\t", .{});
                    }
                    std.debug.print("param {}: TypeId {}, ",
                        .{ i, param_id },
                    );
                }
                if (params.items.len != 0) {
                    std.debug.print("\n", .{});
                }
            },

            else => {
                
                    std.debug.print("  none\n", .{});
            },
        }
    }
    
};

pub const Field = struct {
    name:[]const u8,
    type:TypeId,
};

pub const EnumVariant = struct {
    name: []const u8,
    value: usize,
};

pub const Symbol = struct {
    name:[]const u8,
    kind:SymbolTag,
    type:TypeId,

    is_const: bool = false,
};

pub const TypeNameAndId = struct {
    name:string,
    id:TypeId,
};

pub const SymbolNameAndId = struct {
    name:string,
    id:SymbolId,
};

pub const TypeMap = struct {
    
    ids:ArrayList(TypeNameAndId),

    const Self = @This();

    pub fn init(self:*Self, allocator:*Allocator) SemanticError!void {
        self.ids = ArrayList(TypeNameAndId).initCapacity(allocator, 0) catch return SemanticError.Out_Of_Memory;
    }
 
    pub fn clearAndFree(self:*Self, allocator:*Allocator) void {
        if (self.Globals == null) {
            return;
        }
        self.Globals.?.clearAndFree(allocator);
    }

    pub fn clear(self:*Self) void {
        if (self.Globals == null) {
            return;
        }
        self.Globals.?.clearRetainingCapacity();
    }

    pub fn appendID(self:*Self, allocator:*Allocator, name:string, id:TypeId) SemanticError!void {
        if (try self.isDefined(name) == true) {
            return SemanticError.Variable_Redefinition;
        }
        const entry:TypeNameAndId = .{
            .name = name,
            .id = id,
        };
        self.ids.append(allocator.*, entry) catch return SemanticError.Out_Of_Memory;
    }   

    pub fn isDefined(self:*const Self, name:string) !bool {
        const count:usize = self.ids.items.len;
        if (count == 0) {
            return false;
        }
        for (0..count) |i| {
            const this_name:string = self.ids.items[i].name;
            if (printing_script.twoSlicesAreTheSame(this_name, name)) {
                return true;
            }
        }
        return false;
    }

    pub fn getIdAtIndex(self:*const Self, index:usize) ?TypeId {

        const count:usize = self.ids.items.len;
        if (index >= count) {
            return null;
        }
        return self.*.ids.items[index].id;
    }
    
    pub fn getIdFromName(self:*const Self, name:string) ?TypeId {
        
        const count:usize = self.ids.items.len;
        if (count == 0) {
            return null;
        }
        for (0..count) |i| {
            const this_name:string = self.ids.items[i].name;
            if (printing_script.twoSlicesAreTheSame(name, this_name)) {
                return @intCast(i);
            }
        }
        return null;
    }
};

pub const SymbolTable = struct {
    symbols:ArrayList(Symbol),
    symbol_map:HashSet(SymbolNameAndId),

    const Self = @This();

    pub fn print(self:*const Self) void {

        std.debug.print("Printing SymbolTable:\n", .{});

        const count:usize = self.symbols.items.len;
        if (count == 0) {
            std.debug.print("\t(no symbols)\n", .{});
            return;
        }

        for (self.symbols.items, 0..) |symbol, i| {
            std.debug.print(
                "\t[{}] name: {s}, kind: {}, type: {}, const: {}\n",
                .{
                    i,
                    symbol.name,
                    symbol.kind,
                    symbol.type,
                    symbol.is_const,
                },
            );
        }
    }
    pub fn getSymbolByIndex(self:*const Self, index:usize) ?Symbol {
        const symbol_count:usize = self.symbols.items.len;
        if (index >= symbol_count) {
            return null;
        }
        return self.symbols.items[index];
    }
    pub fn addToSymbolMap(self:*Self, allocator:*Allocator, symbol_name:string) bool {
        self.symbol_map.add( allocator, symbol_name) catch return false;
        return true;
    }
    pub fn addToSymbols(self:*Self, allocator:*Allocator, symbol:Symbol) bool {
        self.symbols.append(allocator.*, symbol) catch return false;
        return true;
    }
    pub fn addSymbol(self:*Self, allocator:*Allocator, symbol:Symbol) bool {
        if (addToSymbolMap(self, allocator, symbol.name) == false) {
            return false;
        }
        return addToSymbols(self, allocator, symbol);
    }
};

pub fn HashSet(comptime T: type) type {

    return struct {

        const Self = @This();
        
        items: ArrayList(T),
        
        pub fn init(allocator: Allocator) !Self {
            return Self{
                .items = try ArrayList(T).initCapacity(allocator, 0),
            };
        }
        
        pub fn deinit(self:*Self, allocator:*Allocator) void {
            self.items.deinit(allocator.*);
        }
        
        pub fn contains(self:*const Self, value:T) bool {
            for (self.items.items) |item| {
                if (std.meta.eql(item, value)) {
                    return true;
                }
            }
            return false;
        }
        
        pub fn add(self:*Self, allocator:*Allocator, value:T) !bool {
            if (self.contains(value)) {
                return false; 
            }
            try self.items.append(allocator.*, value);
            return true; 
        }
        
        pub fn remove(self:*Self, value:T) bool {
            for (self.items.items, 0..) |item, i| {
                if (std.meta.eql(item, value)) {
                    _ = self.items.swapRemove(i);
                    return true;
                }
            }
            return false;
        }
        
        pub fn count(self:*const Self) usize {
            return self.items.items.len;
        }
        
        pub fn clear(self:*Self) void {
            self.items.clearRetainingCapacity();
        }
    };
}

pub fn newTypeTypeMap(allocator:*Allocator) SemanticError!TypeMap { 
    const ids = ArrayList(TypeNameAndId).initCapacity(allocator.*, 0) catch return SemanticError.Out_Of_Memory;
    return TypeMap {
        .ids = ids,
    };
}