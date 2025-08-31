const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("sudoku", .{
        .root_source_file = b.path("src/sudoku.zig"),
    });

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests.zig"),
            .imports = &.{
                .{ .name = "sudoku", .module = mod },
            },
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(tests);
    b.step("test", "Run all tests").dependOn(&b.addRunArtifact(tests).step);
}
