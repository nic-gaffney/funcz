const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{.preferred_optimize_mode = .ReleaseSmall });

    const dep_opts = .{ .target = target, .optimize = optimize };
    _=dep_opts;

    const rootmod =b.addModule("funcz", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    const options = b.addOptions();
    rootmod.addOptions("build", options);

    // const lib = b.addLibrary(.{
    //     .name = "funcz",
    //     .root_module = rootmod,
    // });
    //
    // b.installArtifact(lib);

    // const exe = b.addExecutable(.{
    //     .name = "funczExample",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/example.zig"),
    //         .imports = &.{ .{.name = "funcz", .module = lib.root_module} },
    //         .target = target,
    //         .optimize = optimize,
    //     })
    // });
    //
    // b.installArtifact(exe);

    // const run_cmd = b.addRunArtifact(exe);
    // run_cmd.step.dependOn(b.getInstallStep());
    // if (b.args) |args| run_cmd.addArgs(args);
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

}
