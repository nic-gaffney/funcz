const std = @import("std");
const typeVerify = @import("util.zig").typeVerify;

/// ```zig
/// (fn (Allocator, fn (fn (a) b, []a, *[]b) void)
/// ```
/// Map a function onto a list of values, using a buffer
/// Type signature: `(a -> b) -> [a] -> [b]`
/// `func` is of type `a -> b`, where `items` is of type `[a]` and `buffer` is a pointer to a value of type `[b]`.
/// Haskell equivalent: `map func items`
pub fn map(
    comptime func: anytype,
    items: []typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".params[0].type.?,
    buffer: *[]typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".return_type.?,
) void {
    _=typeVerify(@TypeOf(func), .{ .@"fn" });
    // const itemsInfo = typeVerify(@TypeOf(items), .{ .pointer, .array });
    // const bufferInfo = typeVerify(@TypeOf(buffer), .{ .pointer });
    // const bufferChildInfo = typeVerify(bufferInfo.pointer.child, .{ .pointer, .array });
    // switch (itemsInfo) {
    //     .pointer => |p| if(p.size != .many and p.size != .slice)
    //         @compileError("Expected pointer of size 'many' or 'slice', found '" ++ @tagName(p.size) ++ "'"),
    //     else =>{},
    // }
    // switch (bufferChildInfo) {
    //     .pointer => |p| if(p.size != .many and p.size != .slice)
    //         @compileError("Expected pointer of size 'many' or 'slice', found '" ++ @tagName(p.size) ++ "'"),
    //     else =>{},
    // }
    for (items, 0..) |item, i|
        buffer.*[i] = func(item);
}

/// ```zig
/// (fn (Allocator, fn (fn (a) b, []a) error{OutOfMemory}![]b)
/// ```
/// Map a function onto a list of values, allocating space for the new slice
/// Type signature: `(a -> b) -> [a] -> [b]`
/// `func` is of type `a -> b`, where `items` is of type `[a]`.
/// `map` will return a slice of type `[b]`
/// Haskell equivalent: `map func items`
pub fn mapAlloc(
    allocator: std.mem.Allocator,
    func: anytype,
    items: anytype,
) error{OutOfMemory}!blk:{
    const funcInfo = typeVerify(@TypeOf(func), .{ .@"fn" });
    const itemsInfo = typeVerify(@TypeOf(items), .{ .array, .pointer });
    switch (itemsInfo) {
        .pointer => |p| if(p.size != .many and p.size != .slice)
            @compileError("Expected pointer of size 'many' or 'slice', found " ++ @tagName(p)),
        else =>{},
    }

    break :blk []funcInfo.@"fn".return_type.?;
} {
    const funcInfo = typeVerify(@TypeOf(func), .{ .@"fn" });
    var result = try allocator.alloc(funcInfo.@"fn".return_type.?, items.len);
    for(items, 0..) |item, i|
        result[i] = func(item);
    return result;
}
