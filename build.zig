const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zlog_mod = b.addModule("zlog", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zlog_lib = b.addLibrary(.{
        .name = "zlog",
        .root_module = zlog_mod,
        .linkage = .static, // or .dynamic
    });

    b.installArtifact(zlog_lib);

    const zlog_tests = b.addTest(.{
        .root_module = zlog_mod,
    });

    const run_tests = b.addRunArtifact(zlog_tests);

    const test_step = b.step("test", "run zlog unit tests");
    test_step.dependOn(&run_tests.step);
}
