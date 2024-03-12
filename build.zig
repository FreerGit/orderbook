const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("orderbook", .{ .root_source_file = .{ .path = "src/main.zig" } });

    const money_dep = b.dependency("money", .{ .target = target, .optimize = optimize });
    const money_module = money_dep.module("money");

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.root_module.addImport("money", money_module);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
