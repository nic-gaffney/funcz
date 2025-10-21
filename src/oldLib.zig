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

pub fn curry(func: anytype) blk: {
    const typeInfo = typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn";
    if (typeInfo.params.len == 1)
        break :blk @TypeOf(func);
    if (typeInfo.params.len == 2)
        break :blk  fn(typeInfo.params[0].type.?)
                    fn(typeInfo.params[1].type.?) typeInfo.return_type.?;
    if (typeInfo.params.len == 3)
        break :blk  fn(typeInfo.params[0].type.?)
                    fn(typeInfo.params[1].type.?)
                    fn(typeInfo.params[2].type.?) typeInfo.return_type.?;

} {
    const typeInfo = typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn";
    if (typeInfo.params.len == 1)
        return func;
    if (typeInfo.params.len == 2)
        return struct {
            fn funct(arg1: typeInfo.params[0].type.?) fn(typeInfo.params[1].type.?) typeInfo.return_type.? {
                return struct {
                    fn func2(arg2: typeInfo.params[1].type.?) typeInfo.return_type.? {
                        return func(arg1, arg2);
                    }
                }.func2;
            }
        }.funct;
    if (typeInfo.params.len == 3)
        return struct {
            fn func1(arg1: typeInfo.params[0].type.?) fn(typeInfo.params[1].type.?) fn(typeInfo.params[2].type.?)
            typeInfo.return_type.? {
                return struct {
                    fn func2(arg2: typeInfo.params[1].type.?) fn(typeInfo.params[2].type.?) typeInfo.return_type.? {
                        return struct {
                            fn func3(arg3: typeInfo.params[2].type.?) typeInfo.return_type.? {
                                return func(arg1, arg2, arg3);
                            }
                        }.func3;
                    }
                }.func2;
            }
        }.func1;
}

pub fn curryHelper(func: anytype, args: anytype) blk: {
    const typeInfo = typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn";
    _=typeVerify(@TypeOf(args), .{ .@"struct" });
    if (typeInfo.params.len == 1)
        break :blk @TypeOf(func);
    const newInfo = std.builtin.Type{
        .@"fn" = .{
            .calling_convention = typeInfo.calling_convention,
            .is_generic = typeInfo.is_generic,
            .params = typeInfo.params[1..],
            .is_var_args = typeInfo.is_var_args,
            .return_type = typeInfo.return_type,
        }
    };
    _=newInfo;
    // break :blk fn(typeInfo.params[args.len].type.?) @Type(newInfo);
    break :blk type;
} {
    const typeInfo = typeVerify(@TypeOf(func), .{ .@"fn" }).@"fn";
    const argInfo = typeVerify(@TypeOf(args), .{ .@"struct" }).@"struct";
    if (args.len == typeInfo.params.len) return struct {
        pub fn funcCurry() typeInfo.return_type.? {
            return @call(.auto, func, args);
        }
    };
    const newInfo = std.builtin.Type{
        .@"fn" = .{
            .calling_convention = typeInfo.calling_convention,
            .is_generic = typeInfo.is_generic,
            .params = typeInfo.params[1..],
            .is_var_args = typeInfo.is_var_args,
            .return_type = typeInfo.return_type,
        }
    };
    _=newInfo;
    // const newType = @Type(newInfo);
    return struct {
        pub fn funcCurry(arg: typeInfo.params[0].type.?) type {
            var fields: [64]std.builtin.Type.StructField = .{std.builtin.Type.StructField{.name="10",.type=type,.is_comptime=false,.alignment=8,.default_value_ptr=null}} ** 64;
            for (argInfo.fields, 0..) |f, i| {
                fields[i] = f;
            }
            var buf2: [3:0]u8 = undefined;
            fields[args.len] = .{
                    .name =  blk: {
                    break :blk  try intToStringZ(args.len, &buf2);
                    },
                    .type = typeInfo.params[argInfo.fields.len].type.?,
                    .is_comptime = false,
                    .alignment = @alignOf(typeInfo.params[0].type.?),
                    .default_value_ptr = null,
                };
            const newStruct = std.builtin.Type{
                .@"struct" = .{
                    .backing_integer = argInfo.backing_integer,
                    .decls = argInfo.decls,
                    .fields = fields[0..args.len+1],
                    .is_tuple = argInfo.is_tuple,
                    .layout = argInfo.layout,
                }
            };

            // std.debug.print("{any}", .{fields[0..3]});
            const t = @Type(newStruct);
            var newArgs: t = undefined;
            for (@typeInfo(t).@"struct".fields, 0..) |f, i| {
                if (i == args.len) {
                    @field(newArgs, f.name) = arg;
                } else @field(newArgs, f.name) = args[i];

            }
            return curryHelper(func, newArgs);
        }
    };
}

fn intToStringZ(int: u32, buf: []u8) ![:0]u8 {
    return try std.fmt.bufPrintZ(buf, "{}", .{int});
}

// TODO: Add
