
const std = @import("std");
const enum_script = @import("enums.zig");
const error_script = @import("errors.zig");
const ArrayList = std.ArrayList;
const ASTNodeType = enum_script.ASTNodeType;
const TokenType = enum_script.TokenType;
const AstError = error_script.AstError;

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