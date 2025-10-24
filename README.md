# funcz: All the functional tools you need for zig

This is a work in progress library meant for bringing functional ideas to zig
in easy to understand and reasonable ways.

To add the latest version to your project, simply run
```
$ zig fetch --save git+https://git.ngaffney.dev/funcz/#HEAD
```

And then in your `build.zig`, add the following:
```zig
const funczmod = b.dependency("funcz", .{
    .target = target,
    .optimize = optimize,
}).module("funcz");
exe.root_module.addImport("funcz", funczmod);
```
