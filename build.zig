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

    const run_step = b.step("run", "Run the application");

    run_step.dependOn(&run_exe.step);

    const check_step = b.step("check", "Check the application");

    check_step.dependOn(&exe.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    unit_tests.linkFramework("CoreFoundation");
    unit_tests.linkFramework("IOKit");

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");

    test_step.dependOn(&run_unit_tests.step);
}
