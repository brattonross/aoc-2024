const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    // run a day with `zig build run -- <day>`
    const day = b.args.?[0];

    const root_source_file = b.fmt("src/{s}.zig", .{day});

    const exe = b.addExecutable(.{
        .name = "aoc-2024",
        .root_source_file = b.path(root_source_file),
        .optimize = optimize,
        .target = target,
    });
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path(root_source_file),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
