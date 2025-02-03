const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "asm",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkFramework("CoreFoundation");
    exe.linkFramework("IOKit");

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    if (b.args) |args| {
        run_exe.addArgs(args);
    }

    const run_step = b.step("run", "Run the application"); // zig build run

    run_step.dependOn(&run_exe.step);

    const exe_check = b.addExecutable(.{
        .name = "asm",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const check_step = b.step("check", "Check the application"); // zig build check

    check_step.dependOn(&exe_check.step);
}
