


//fn i32 add(i32 a, i32 b) {
//  return a + b;
//}

//func add(a int, b int) int {
//  return a + b
//}

//int add(int a, int b) {
//  return a + b
//}

//define i32 @add(i32 %a, i32 %b) {
//    %value = add i32 %a, %b ;// in a register
//    %var = alloca i32 ;// in memory    
//    ret i32 %value
//}



const std = @import("std");
const structs_script = @import("../core/structs.zig");
const enums_script = @import("../core/enums.zig");
const printing_script = @import("../core/printing.zig");
const error_script = @import("../core/errors.zig");
const Token = structs_script.Token;
const TokenType = enums_script.TokenType;
const ConvertError = error_script.ConvertError;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

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

pub fn convertToLLVMOperator(operator:[]const u8) ?[]const u8 {
    if (printing_script.twoSlicesAreTheSame(operator, "+")) {
        return "add i32";
    }
    if (printing_script.twoSlicesAreTheSame(operator, "-")) {
        return "sub i32";
    }
    if (printing_script.twoSlicesAreTheSame(operator, "*")) {
        return "mul i32";
    }
    if (printing_script.twoSlicesAreTheSame(operator, "/")) {
        return "sdiv i32";
    }
    if (printing_script.twoSlicesAreTheSame(operator, "%")) {
        return "srem i32";
    }
    return null;
}

