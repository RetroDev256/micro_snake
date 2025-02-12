const std = @import("std");

// -Drelease for release build
// -Drisky for slighty smaller (but risky) build
// shrink for slighyl smaller output (safe, repends on sstrip from elf-kickers and wc)

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{
        // the x86 ELF is generally smaller
        // the pointers are also 32 bits shorter ;D
        .default_target = .{ .cpu_arch = .x86, .cpu_model = .baseline },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });
    // build
    const exe = b.addExecutable(.{
        .name = "micro_snake",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    // optimize
    if (optimize == .ReleaseFast or optimize == .ReleaseSmall) {
        // custom linker script
        const risky = b.option(bool, "risky", "Create binary with PHDR which is RWX") orelse false;
        exe.setLinkerScript(b.path(if (risky) "linker_risky.ld" else "linker_safe.ld"));
        // toggle compiler options
        exe.link_data_sections = true;
        exe.link_function_sections = true;
        exe.root_module.strip = true;
        exe.root_module.single_threaded = true;
        exe.bundle_compiler_rt = false;
        // further strip & stuff
        try furtherOptimize(b, exe); // "shrink" step
    }
    // run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    // tests
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
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
