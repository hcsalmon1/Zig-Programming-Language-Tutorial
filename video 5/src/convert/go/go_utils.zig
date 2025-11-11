

const std = @import("std");
const structs_script = @import("../../core/structs.zig");
const enums_script = @import("../../core/enums.zig");
const printing_script = @import("../../core/printing.zig");
const error_script = @import("../../core/errors.zig");
const Token = structs_script.Token;
const TokenType = enums_script.TokenType;
const ConvertError = error_script.ConvertError;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn convertToGoType(token:Token) ?[]const u8 {
    switch (token.Type) {
        TokenType.i8, TokenType.u8 => return "int8",
        TokenType.i16, TokenType.u16 => return "int16",
        TokenType.Int, TokenType.i32, TokenType.u32 => return "int",
        TokenType.i64, TokenType.u64, TokenType.Usize => return "int64",
        TokenType.f32 => return "float32",
        TokenType.f64 => return "float64",
        TokenType.String => return "string",
        TokenType.Char => return "byte",
        TokenType.Bool => return "bool",
        TokenType.Void => return "",
        else => return null,
    }
}



