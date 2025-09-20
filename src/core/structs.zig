
const std = @import("std");
const enum_script = @import("enums.zig");
const ArrayList = std.ArrayList;
const TokenType = enum_script.TokenType;

pub const ParseData = struct {

    token_list:*ArrayList(Token),
    last_token: ?Token = null,
    character_index:usize = 0,
    code:[]const u8 = "",
    line_count:usize = 0, //for token position
    char_count:usize = 0,
    was_comment:bool = false,
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