const std = @import("std");

/// ```zig
/// (fn (a, b, ..., n) r) fn (a) fn (b) ... fn (n) r
/// ```
/// Function currying
/// Type signature: (a -> b -> ... -> n -> r) -> a -> b -> ... -> n -> r
/// Transforms a function taking multiple arguments into a sequence of functions each taking a single argument
/// `func` is a function of type `(a, b, ..., n) -> r`
/// Haskell equivalent: automatic currying (all functions are curried by default)
pub fn curry(func: anytype) curryTypeGetter(@TypeOf(func), @TypeOf(func), .{}) {
    return curryHelper(func, .{});
}


fn curriedTypeVerify(comptime T: type, comptime expected: std.builtin.Type) std.builtin.Type {
    const info = @typeInfo(T);
    if (@as(std.meta.Tag(std.builtin.Type), info) != @as(std.meta.Tag(std.builtin.Type), expected)) {
        @compileError("Type mismatch");
    }
    return info;
}

fn curryTypeGetter(comptime func: type, comptime newfunc: type, comptime args: anytype) type {
    const typeInfo = curriedTypeVerify(func, .{ .@"fn" = undefined }).@"fn";
    const newTypeInfo = curriedTypeVerify(newfunc, .{ .@"fn" = undefined }).@"fn";

    if (typeInfo.params.len == args.len + 1) {
        return fn(typeInfo.params[args.len].type.?) typeInfo.return_type.?;
    }

    const nextParamType = typeInfo.params[args.len].type.?;
    var buf: [64]type = undefined;
    for (args, 0..) |a, i| {
        buf[i] = if (@TypeOf(a) != type) @TypeOf(a) else a;
    }
    buf[args.len] = nextParamType;

    return fn(nextParamType) curryTypeGetter(func, @Type(.{
        .@"fn" = .{
            .calling_convention = newTypeInfo.calling_convention,
            .is_generic = newTypeInfo.is_generic,
            .params = newTypeInfo.params[1..],
            .is_var_args = newTypeInfo.is_var_args,
            .return_type = newTypeInfo.return_type,
        }
    }), buf[0..args.len+1].*);
}

fn curryHelper(comptime func: anytype, args: anytype) curryTypeGetter(@TypeOf(func), @TypeOf(func), args) {
    const typeInfo = curriedTypeVerify(@TypeOf(func), .{ .@"fn" = undefined }).@"fn";
    const argInfo = @typeInfo(@TypeOf(args)).@"struct";
    _=argInfo;

    const nextParamType = typeInfo.params[args.len].type.?;

    const Closure = struct {
        fn funcCurry(arg: nextParamType) @typeInfo(curryTypeGetter(@TypeOf(func), @TypeOf(func), args)).@"fn".return_type.? {
            if (args.len + 1 == typeInfo.params.len) {
                return @call(.auto, func, args ++ .{arg});
            }
            const newArgs = args ++ .{arg};
            return curryHelper(func, newArgs);
        }
    };

    return Closure.funcCurry;
}
