const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable("snek", "src/main.zig");
    exe.setBuildMode(mode);
    exe.setTarget(target);
    // TODO: Make it configurable instead, so that it will be possible to compile on other platfoms.
    exe.linkSystemLibrary("sdl2");
    exe.linkLibC();

    const run_cmd = exe.run();
    const run_step = b.step("run", "snek");
    run_step.dependOn(&run_cmd.step);

    exe.install();
}

