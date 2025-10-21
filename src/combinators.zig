const std = @import("std");
const typeVerify = @import("util.zig").typeVerify;

pub fn I(x: anytype) @TypeOf(x) {
    return x;
}

pub fn K(x: anytype) fn(anytype) @TypeOf(x) {
    return struct {
        fn Kinner(y: anytype) @TypeOf(x) {
            _=y;
            return x;
        }
    }.Kinner;
}

fn SHelper(comptime x: anytype) type {
    return struct {
        pub fn call(comptime y: anytype) type {
            return struct {
                pub fn call(z: anytype) @TypeOf(x(z)(y(z))) {
                    return x(z)(y(z));
                }
            };
        }
    };
}

pub fn S(comptime x: anytype) fn(anytype) fn(anytype) @TypeOf(blk: {
    const dummy = struct {
        fn d(a: anytype) @TypeOf(a) { return a; }
    }.d;
    break :blk x(dummy)(dummy);
}) {
    const Helper = SHelper(x);
    return struct {
        fn inner1(y: anytype) fn(anytype) @TypeOf(blk: {
            const dummy = struct {
                fn d(a: anytype) @TypeOf(a) { return a; }
            }.d;
            break :blk x(dummy)(y(dummy));
        }) {
            return struct {
                fn inner2(z: anytype) @TypeOf(x(z)(y(z))) {
                    return Helper.call(y).call(z);
                }
            }.inner2;
        }
    }.inner1;
}
