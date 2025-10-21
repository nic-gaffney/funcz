const std = @import("std");
const Type = std.builtin.Type;

pub fn typeVerify(T: type, expected: anytype) Type {
    const expectedType = @TypeOf(expected);
    const expectedTypeInfo = @typeInfo(expectedType);
    if (expectedTypeInfo != .@"struct")
        @compileError("Expected struct or tuple, found " ++ @typeName(expectedType));
    const realTypeInfo = @typeInfo(T);
    for (expected) |e| {
        if(realTypeInfo == e) return realTypeInfo;
    }
    for (expected) |e|
        @compileError("Expected one of " ++ @tagName(e) ++ ", found " ++ @typeName(T));
    return realTypeInfo;
}
