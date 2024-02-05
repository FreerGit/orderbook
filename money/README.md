# money
A floating point representation of Money, with 15 digits of guaranteed precision. Money is represented with an f64 with units of 10^-6.

## Install
1. Declare Money as a dependecy:
```console
zig fetch --save git+https://github.com/freergit/money.git#main
```

2. Expose Money as a module in build.zig:
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const money_dep = b.dependency("money", .{ .target = target, .optimize = optimize });
    const money_module = money_dep.module("money");

    const exe = b.addExecutable(.{
        .name = "my-project",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("money", money_module);
    
    // ...
}
```

Of course, you can use simply download the repo and build it instead of using the package manager.