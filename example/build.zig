const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const e1 = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("src/example1.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(e1);

    const run_cmd = b.addRunArtifact(e1);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
