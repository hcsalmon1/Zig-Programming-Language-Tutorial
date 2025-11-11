
const std = @import("std");
const enum_script = @import("enums.zig");
const error_script = @import("errors.zig");
const debugging_script = @import("../debugging/debugging.zig");
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


pub const CompilerSettings = struct {
    language_target: LanguageTarget = LanguageTarget.Go,
    separate_expressions:bool = false,
    show_tokens:bool = false,
    show_ast_nodes:bool = false,
    show_input_code:bool = false,
    show_output_code:bool = false,
    show_definitions:bool = false,
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

        const string:[]u8 = std.fmt.allocPrint(allocator.*, "%temp_var_{}", .{self.temp_var_count}) catch {
            return ConvertError.Out_Of_Memory;
        };
        self.temp_var_count += 1;
        return string;
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

pub const ASTNode = struct {

    node_type:ASTNodeType = ASTNodeType.Invalid,

    // These fields are optional depending on the kind
    token: ?Token = null,       // Token, for literals, var types etc

    left:?*ASTNode = null,     // For expressions (e.g., a + b), return types
    middle:?*ASTNode = null,   // Rare, for things with 3, for loop, parameters
    right:?*ASTNode = null,      // right side of arithmetic a + b;, right = b
    children: ?std.ArrayList(*ASTNode),    // For blocks, function bodies, etc.

    is_const:bool = false,
    size:usize = 0,  //array size

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
        const string = try std.fmt.allocPrint(allocator.*, fmt, args);
        try self.append(allocator, string);
    }
    
    // Append a line (adds newline)
    pub fn appendLine(self: *Self, allocator:*Allocator, str: []const u8) !void {
        try self.buffer.appendSlice(allocator.*, str);
        try self.buffer.append(allocator.*, '\n');
    }
    
    // Append formatted line
    pub fn appendLineFmt(self: *Self, allocator:*Allocator, comptime fmt: []const u8, args: anytype) !void {
        const string:[]u8 = try std.fmt.allocPrint(allocator, fmt, args);
        try self.buffer.appendSlice(allocator.*, string);
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

pub const VariableDefinition = struct {
    name:[]const u8,
    type_node:*ASTNode,
};

pub const FunctionDefinition = struct {
    name:[]const u8,
    return_type_node:*ASTNode,
    parameters:?ArrayList(*ASTNode),
};

pub const GlobalDefinitions = struct {
    Variables:?StringHashMap(VariableDefinition) = null,
    Functions:?StringHashMap(FunctionDefinition) = null,

    const Self = @This();

    pub fn functionIsDefined(self:*const Self, function_name:[]const u8) bool {
        return self.Functions.contains(function_name);
    }

    pub fn variableIsDefined(self:*const Self, var_name:[]const u8) bool {
        return self.Variables.contains(var_name);
    }

    pub fn appendFunction(self:*Self, function_definition:FunctionDefinition) SemanticError!void {
        const result = self.Functions.?.getOrPut(function_definition.name) catch {
            return SemanticError.Out_Of_Memory;
        };
        if (result.found_existing == true) {
            return SemanticError.Function_Redefinition;
        }
        result.value_ptr.* = function_definition;
    } 

    pub fn appendGlobalVariable(self:*Self, global_definition:VariableDefinition) SemanticError!void {
        const result = self.Variables.?.getOrPut(global_definition.name) catch {
            return SemanticError.Out_Of_Memory;
        };
        if (result.found_existing == true) {
            return SemanticError.Function_Redefinition;
        }
        result.value_ptr.* = global_definition;
    } 

    pub fn printFunctionDeclarations(self:*const Self) void {
        print("\nPrinting function declarations:\n", .{});

        if (self.Functions.?.count() == 0) {
            print("\tNo functions found\n\n", .{});
            return;
        }

        var it = self.Functions.?.iterator();
        while (it.next()) |entry| {
            debugging_script.printFunctionNodeDetails(entry.value_ptr.*);
        }
        print("\n", .{});
    }

    pub fn printVariableDeclarations(self:*const Self) void {

        print("\nPrinting global variable declarations:\n", .{});

        if (self.Variables.?.count() == 0) {
            print("\tNo global vars found\n\n", .{});
            return;
        }

        var it = self.Variables.?.iterator();
        while (it.next()) |entry| {

            debugging_script.printVariableNodeDetails(entry.value_ptr.*);
        }
        print("\n", .{});
    }

    pub fn printAllData(self:*const Self, compiler_settings:*const CompilerSettings) void {

        if (compiler_settings.show_definitions == false) {
            return;
        }

        printFunctionDeclarations(self);
        printVariableDeclarations(self);
    }
};