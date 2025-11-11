

const std = @import("std");
const structs_script = @import("../core/structs.zig");
const printing_script = @import("../core/printing.zig");
const enums_script = @import("../core/enums.zig");
const debugging_script = @import("../Debugging/debugging.zig");
const errors_script = @import("../core/errors.zig");
const go_convert_script = @import("go/go_convert.zig");
const llvm_convert_script = @import("llvm/llvm_convert.zig");
const ASTNode = structs_script.ASTNode;
const ConvertError = errors_script.ConvertError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const LanguageTarget = enums_script.LanguageTarget;
const CompilerSettings = structs_script.CompilerSettings;

pub fn convertCode(allocator:*Allocator, ast_nodes:ArrayList(*ASTNode), code:[]const u8, compiler_settings:*const CompilerSettings) ConvertError!void {
    switch (compiler_settings.language_target) {
        LanguageTarget.LLVM => try llvm_convert_script.convert(allocator, ast_nodes, code, compiler_settings),
        LanguageTarget.Go => try go_convert_script.convert(allocator, ast_nodes, code, compiler_settings),
    }
}