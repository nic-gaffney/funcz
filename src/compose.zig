const std = @import("std");
const typeVerify = @import("util.zig").typeVerify;

/// ```zig
/// (fn (fn (b) c, fn (a) b) fn (a) c)
/// ```
/// Function composition
/// Type signature: (a -> b) -> (b -> c) -> (a -> c)
/// `outerFunc` and `innerFunc` are functions of types `b -> c` and `a -> b` respectively
/// Haskell equivalent: `outerFunc . innerFunc`
pub fn compose(
    comptime outerFunc: anytype,
    comptime innerFunc: anytype
) blk:{
    _=typeVerify(@TypeOf(outerFunc), .{ .@"fn" });
    _=typeVerify(@TypeOf(innerFunc), .{ .@"fn" });
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
