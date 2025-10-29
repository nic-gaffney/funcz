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
    const fInfo =typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn";
    if(fInfo.params.len > 1)
        @compileError("Function passed into map must have exactly one argument");
    for (items, 0..) |item, i|
        buffer.*[i] = func(item);
}

/// ```zig
/// (fn (Allocator, fn (fn (a) b, []a) error{OutOfMemory}![]b)
/// ```
/// Map a function onto a list of values, allocating space for the new slice
/// The return value of this function must be freed using `allocator.free()`
/// Type signature: `(a -> b) -> [a] -> [b]`
/// `func` is of type `a -> b`, where `items` is of type `[a]`.
/// `map` will return a slice of type `[b]`
/// Haskell equivalent: `map func items`
pub fn mapAlloc(
    allocator: std.mem.Allocator,
    func: anytype,
    items: []typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".params[0].type.?,
) error{OutOfMemory}!blk:{
    const funcInfo = typeVerify(@TypeOf(func), .{ .@"fn" });
    break :blk []funcInfo.@"fn".return_type.?;
} {
    const funcInfo = typeVerify(@TypeOf(func), .{ .@"fn" });
    var result = try allocator.alloc(funcInfo.@"fn".return_type.?, items.len);
    for(items, 0..) |item, i|
        result[i] = func(item);
    return result;
}
