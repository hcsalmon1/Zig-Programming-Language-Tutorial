
const std = @import("std");
const enum_script = @import("enums.zig");
const error_script = @import("errors.zig");
const ArrayList = std.ArrayList;
const ASTNodeType = enum_script.ASTNodeType;
const TokenType = enum_script.TokenType;
const AstError = error_script.AstError;
const Allocator = std.mem.Allocator;
const ConvertError = error_script.ConvertError;

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
    token_list:*const std.ArrayList(Token),
    error_detail:?[]const u8 = null,
    error_token:?Token = null,
    error_function:?[]const u8 = null,

    pub fn getToken(self:*ASTData) !Token {
        if (self.token_index >= self.token_list.items.len) {
            return AstError.Index_Out_Of_Range;
        }
        const token:Token = self.token_list.items[self.token_index];
        self.error_token = token;
        return token;
    }

    pub fn getNextToken(self:*ASTData) !Token {
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

    pub fn incrementIndex(self:*ASTData) !void {
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            return AstError.Index_Out_Of_Range;
        }
    }
};

pub const ConvertData = struct {
    ast_nodes:*std.ArrayList(*ASTNode),
    node_index:usize = 0,
    error_detail:?[]const u8 = null,
    error_token:?Token = null,
    error_function:?[]const u8 = null,
    generated_code:*StringBuilder,
    temp_var_count:usize = 0,

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
};

pub const Token = struct {
    Text: []const u8,
    Type: TokenType,
    LineNumber: usize,
    CharNumber: usize,

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
    children: ?*std.ArrayList(*ASTNode),    // For blocks, function bodies, etc.

    is_array:bool = false,
    is_global:bool = false,
    is_const:bool = false,
    size:usize = 0,  //array size

    pub fn MakeAllNull(self:*ASTNode) void {
        self.Left = null;
        self.Middle = null;
        self.Right = null;
        self.Children = null;
        self.Token = null;
    }
};

pub const StringBuilder = struct {

    buffer: std.ArrayList(u8),
    
    const Self = @This();
    
    pub fn init(allocator: Allocator) !Self {
        return Self{
            .buffer = try std.ArrayList(u8).initCapacity(allocator, 0),
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