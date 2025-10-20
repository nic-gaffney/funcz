const std = @import("std");
const func = @import("funcz");

fn iter(n: i32) i32 {
    return n + 1;
}

fn mul2(n: i32) i32 {
    return n * 2;
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    const iterThenMul2 = func.compose(mul2, iter);
    var items = [_]i32{ 0, 1, 2, 3, 4 };
    const itemsSlice: []i32 = items[0..items.len];
    const newItems = try func.mapAlloc(allocator, iterThenMul2, itemsSlice);
    defer allocator.free(newItems);
    var buffer: [128]i32 = undefined;
    func.map(iterThenMul2, itemsSlice, &buffer);
    std.debug.print("compose(mul2, iter)(5) = {d}\n", .{ iterThenMul2(5) });
    std.debug.print("mapAlloc(allocator, compose(mul2, iter), []i32{{ 0, 1, 2, 3, 4 }}) = {{ ", .{});
    for(newItems) |item| {
        std.debug.print("{d}, ", .{item});
    }
    std.debug.print("}}\n", .{});
    std.debug.print("map(compose(mul2, iter), []i32{{ 0, 1, 2, 3, 4 }}, &buffer) = {{ ", .{});
    for(buffer[0..items.len]) |item| {
        std.debug.print("{d}, ", .{item});
    }
    std.debug.print("}}\n", .{});
}
