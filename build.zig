const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("zlog", .{
        .root_source_file = b.path("src/Logger.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe = b.addExecutable(.{ .name = "zlog", .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize });

    b.installArtifact(run_exe);

    const run_cmd = b.addRunArtifact(run_exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/Logger.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Unit testing");
    test_step.dependOn(&run_lib_unit_tests.step);
}
