




const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const Token = structs_script.Token;
const TokenType = enums_script.TokenType;

pub fn convertToLLVMType(token:Token) ?[]const u8 {
    switch (token.Type) {
        TokenType.i8, TokenType.u8, TokenType.Char => return "i8",
        TokenType.i16, TokenType.u16 => return "i16",
        TokenType.Int, TokenType.i32, TokenType.u32 => return "i32",
        TokenType.i64, TokenType.u64, TokenType.Usize => return "i64",
        TokenType.f32 => return "float",
        TokenType.f64 => return "double",
        //TokenType.String,
        TokenType.Bool => return "i1",
        TokenType.Void => return "void",
        else => return null,
    }
}