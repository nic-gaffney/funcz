const std = @import("std");
const typeVerify = @import("util.zig").typeVerify;

/// ```zig
/// (fn (fn (fn (b, a) b, b, []a) void)
/// ```
/// Folds a list of items over a function with the accumulator as the first arg
/// Type signature: `(b -> a -> b) -> b -> [a] -> b`
/// `func` is of type `b -> a -> b`, where `items` is of type `[a]` and `accumulator` is of type `b`.
/// Haskell equivalent: `foldl func accumulator items`
pub fn foldl(
    comptime func: anytype,
    accumulator: (typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".params[0].type.?),
    items: ([]typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".params[1].type.?),
) typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".return_type.? {
    var accum_internal = accumulator;
    for(items) |i|
        accum_internal = func(accum_internal, i);
    return accum_internal;
}

/// ```zig
/// (fn (fn (fn (a, b) b, b, []a) void)
/// ```
/// Folds a list of items over a function with the accumulator as the second arg
/// Type signature: `(a -> b -> b) -> b -> [a] -> b`
/// `func` is of type `a -> b -> b`, where `items` is of type `[a]` and `accumulator` is of type `b`.
/// Haskell equivalent: `foldr func accumulator items`
pub fn foldr(
    comptime func: anytype,
    accumulator: (typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".params[1].type.?),
    items: ([]typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".params[0].type.?),
) typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".return_type.? {
    var accum_internal = accumulator;
    for(items) |i|
        accum_internal = func(i, accum_internal);
    return accum_internal;
}

/// Variant of `foldl` where the first element is the base case
pub fn foldl1(
    comptime func: anytype,
    items: ([]typeVerify(@TypeOf(func), .{.@"fn"}).@"fn".params[0].type.?)
) typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".return_type.? {
    return foldl(func, items[0], items);
}

/// Variant of `foldr` where the first element is the base case
pub fn foldr1(
    comptime func: anytype,
    items: ([]typeVerify(@TypeOf(func), .{.@"fn"}).@"fn".params[0].type.?)
) typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn".return_type.? {
    return foldr(func, items[0], items);
}
