const std = @import("std");
const func = @import("funcz");
const c = func.combinators;

fn iter(n: i32) i32 {
    return n + 1;
}

fn mul2(n: i32) i32 {
    return n * 2;
}

fn add(n: i32, m: i32) i32 {
    return n + m;
}

fn addThenMultiply(n: i32, m: i32, q: i32) i32 {
    return (n + m) * q;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    // Currying
    const curriedAddResult = func.curry(add)(4)(5);
    // Composition
    const iterThenMul2 = func.compose(mul2, iter);
    const composed =  iterThenMul2(5);
    // Map
    var items = [_]i32{ 0, 1, 2, 3, 4 };
    const itemsSlice: []i32 = items[0..items.len];
    const buffer = try func.mapAlloc(allocator, iterThenMul2, itemsSlice);

    std.debug.print("curry(add)(4)(5) = {any}\n", .{ curriedAddResult });
    std.debug.print("compose(mul2, iter)(5) = {d}\n", .{ composed });
    std.debug.print("mapAlloc(allocator, compose(mul2, iter), []i32{{ 0, 1, 2, 3, 4 }}) = {{ ", .{});
    // func.map(func: anytype, items: anytype, buffer: anytype)
    for(buffer) |item| {
        std.debug.print("{d}, ", .{item});
    }
    std.debug.print("}}\n", .{});
    std.debug.print("I(5) = {any}\n", .{c.I(5)});
    std.debug.print("K(5)(7) = {any}\n", .{c.K(5)(7)});
    std.debug.print("(S K S K)(5)(7) = {any}\n", .{((c.S(c.K)(c.S)(c.K))(mul2)(func.curry(add)(3)))(7)});
}
