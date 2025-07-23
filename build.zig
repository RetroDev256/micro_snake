const std = @import("std");

// -Drelease for release build
// -Drisky for slightly smaller (but risky) build
// shrink for slightly smaller output (safe, repends on sstrip from elf-kickers and wc)

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{
        .default_target = .{ .cpu_arch = .x86, .cpu_model = .baseline },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });
    const risky = b.option(bool, "risky", "Create binary with PHDR which is RWX");

    const root = b.addModule("micro_snake", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "micro_snake",
        .root_module = root,
    });
    b.installArtifact(exe);

    if (optimize == .ReleaseFast or optimize == .ReleaseSmall) {
        if (risky orelse false) {
            exe.setLinkerScript(b.path("linker_risky.ld"));
        } else {
            exe.setLinkerScript(b.path("linker_safe.ld"));
        }
        exe.link_data_sections = true;
        exe.link_function_sections = true;
        root.strip = true;
        root.single_threaded = true;
        // root.omit_frame_pointer = true;
        exe.bundle_compiler_rt = false;
        try furtherOptimize(b, exe);
    }

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{ .root_module = root });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn furtherOptimize(b: *std.Build, exe: *std.Build.Step.Compile) !void {
    const file = try std.fmt.allocPrint(b.allocator, "{s}/bin/{s}", .{ b.install_prefix, exe.name });
    defer b.allocator.free(file);
    // strip more stuff, plus the trailing zeros
    const sstrip = b.addSystemCommand(&.{ "sstrip", "-z", file });
    // count the bytes in the program
    const report = b.addSystemCommand(&.{ "wc", "-c", file });
    // set the order the steps are to run
    sstrip.step.dependOn(b.getInstallStep());
    report.step.dependOn(&sstrip.step);
    // ensure the steps will run when triggered
    const optimize_step = b.step("shrink", "Further size optimizations");
    optimize_step.dependOn(&report.step);
}
