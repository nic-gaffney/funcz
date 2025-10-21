const std = @import("std");
const Type = std.builtin.Type;

fn typeVerify(T: type, expected: anytype) Type {
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

/// ```zig
/// (fn (Allocator, fn (fn (a) b, []a, *[]b) void)
/// ```
/// Map a function onto a list of values, using a buffer
/// Type signature: `(a -> b) -> [a] -> [b]`
/// `func` is of type `a -> b`, where `items` is of type `[a]` and `buffer` is a pointer to a value of type `[b]`.
/// Haskell equivalent: `map func items`
pub fn map(
    func: anytype,
    items: anytype,
    buffer: anytype,
) void {
    _=typeVerify(@TypeOf(func), .{ .@"fn" });
    const itemsInfo = typeVerify(@TypeOf(items), .{ .pointer, .array });
    const bufferInfo = typeVerify(@TypeOf(buffer), .{ .pointer });
    const bufferChildInfo = typeVerify(bufferInfo.pointer.child, .{ .pointer, .array });
    switch (itemsInfo) {
        .pointer => |p| if(p.size != .many and p.size != .slice)
            @compileError("Expected pointer of size 'many' or 'slice', found '" ++ @tagName(p.size) ++ "'"),
        else =>{},
    }
    switch (bufferChildInfo) {
        .pointer => |p| if(p.size != .many and p.size != .slice)
            @compileError("Expected pointer of size 'many' or 'slice', found '" ++ @tagName(p.size) ++ "'"),
        else =>{},
    }
    for (items, 0..) |item, i|
        buffer.*[i] = func(item);
}

pub fn curry(func: anytype) curryTypeGetter(@TypeOf(func), @TypeOf(func), .{}) {
    return curryHelper(func, .{});
}

fn curryTypeGetter(comptime func: type, comptime newfunc: type, comptime args: anytype) type {
    const typeInfo = typeVerify(func, .{ .@"fn" = undefined }).@"fn";
    const newTypeInfo = typeVerify(newfunc, .{ .@"fn" = undefined }).@"fn";

    // Base case: if we've curried all but one parameter, return final function type
    if (typeInfo.params.len == args.len + 1) {
        return fn(typeInfo.params[args.len].type.?) typeInfo.return_type.?;
    }

    // Recursive case: return function that takes next param and returns curried function
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
    const typeInfo = typeVerify(@TypeOf(func), .{ .@"fn" = undefined }).@"fn";
    const argInfo = @typeInfo(@TypeOf(args)).@"struct";
    _=argInfo;

    const nextParamType = typeInfo.params[args.len].type.?;

    const Closure = struct {
        fn funcCurry(arg: nextParamType) curryTypeGetter(@TypeOf(func), @TypeOf(func), args).ReturnType {
            // Base case: if we have all arguments, call the function
            if (args.len + 1 == typeInfo.params.len) {
                return @call(.auto, func, args ++ .{arg});
            }

            // Recursive case: create new tuple with additional argument
            const newArgs = args ++ .{arg};
            return curryHelper(func, newArgs);
        }
    };

    return Closure.funcCurry;
}

fn intToStringZ(int: u32, buf: []u8) ![:0]u8 {
    return try std.fmt.bufPrintZ(buf, "{}", .{int});
}

// TODO: Add tests
