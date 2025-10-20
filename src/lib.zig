const std = @import("std");

/// Compose two single argument functions
pub fn compose(
    comptime outerFunc: anytype,
    comptime innerFunc: anytype
) blk:{
    const outerFuncType = @TypeOf(outerFunc);
    const outerFuncTypeInfo = @typeInfo(outerFuncType);
    if(outerFuncTypeInfo != .@"fn")
        @compileError("Expected function, found " ++ @typeName(outerFuncType));
    const innerFuncType = @TypeOf(innerFunc);
    const innerFuncTypeInfo = @typeInfo(innerFuncType);
    if(innerFuncTypeInfo != .@"fn")
        @compileError("Expected function, found " ++ @typeName(innerFuncType));
    const out = @typeInfo(@TypeOf(outerFunc)).@"fn".return_type.?;
    const in = @typeInfo(@TypeOf(innerFunc)).@"fn".params[0].type.?;
    break :blk fn(in) out;
} {
    const out = @typeInfo(@TypeOf(outerFunc)).@"fn".return_type.?;
    const in = @typeInfo(@TypeOf(innerFunc)).@"fn".params[0].type.?;
    return struct {
        fn func(input: in) out {
            return outerFunc(innerFunc(input));
        }
    }.func;
}

pub fn mapAlloc(
    allocator: std.mem.Allocator,
    func: anytype,
    items: anytype,
) error{OutOfMemory}!blk:{
    const itemsType = @TypeOf(items);
    const itemsTypeInfo = @typeInfo(itemsType);
    const funcType = @TypeOf(func);
    const funcTypeInfo = @typeInfo(funcType);
    if(funcTypeInfo != .@"fn")
        @compileError("Expected function, found " ++ @typeName(funcType));
    if(itemsTypeInfo != .array and itemsTypeInfo != .pointer) {
        @compileError("Expected array or slice, found " ++ @typeName(itemsType));
    }
    switch (itemsTypeInfo) {
        .pointer => |p| if(p.size != .many and p.size != .slice) @compileError("Expected pointer of size 'many' or 'slice', found " ++ @tagName(p)),
        else =>{},
    }

    break :blk []funcTypeInfo.@"fn".return_type.?;
} {
    const funcType = @TypeOf(func);
    const funcTypeInfo = @typeInfo(funcType);
    var result = try allocator.alloc(funcTypeInfo.@"fn".return_type.?, items.len);
    for(items, 0..) |item, i|
        result[i] = func(item);
    return result;
}

pub fn map(
    func: anytype,
    items: anytype,
    buffer: anytype,
) void {
    const funcType = @TypeOf(func);
    const bufferType = @TypeOf(buffer);
    const itemsType = @TypeOf(items);
    const funcTypeInfo = @typeInfo(funcType);
    const bufferTypeInfo = @typeInfo(bufferType);
    const itemsTypeInfo = @typeInfo(itemsType);
    if(funcTypeInfo != .@"fn")
        @compileError("Expected function, found " ++ @typeName(funcType));
    if(itemsTypeInfo != .array and itemsTypeInfo != .pointer)
        @compileError("Expected array, found " ++ @typeName(itemsType));
    if(bufferTypeInfo != .array and bufferTypeInfo != .pointer)
        @compileError("Expected array, found " ++ @typeName(bufferType));
    switch (itemsTypeInfo) {
        .pointer => |p| if(p.size != .many and p.size != .slice) @compileError("Expected pointer of size 'many' or 'slice', found '" ++ @tagName(p.size) ++ "'"),
        else =>{},
    }
    for (items, 0..) |item, i|
        buffer.*[i] = func(item);
}
