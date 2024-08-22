const std = @import("std");

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
        exe.setLinkerScript(b.path("linker.ld"));
        // toggle compiler options
        standardOptimize(exe);
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

fn standardOptimize(exe: *std.Build.Step.Compile) void {
    // general stuff
    exe.root_module.strip = true;
    exe.root_module.error_tracing = false;
    exe.root_module.unwind_tables = false;
    exe.root_module.omit_frame_pointer = true;
    exe.root_module.pic = false;
    exe.root_module.single_threaded = true;
    exe.root_module.sanitize_thread = false;
    exe.root_module.stack_protector = false;
    exe.root_module.stack_check = false;
    exe.root_module.red_zone = false;
    exe.root_module.code_model = .small;
    exe.root_module.sanitize_c = false;
    exe.formatted_panics = false;
    // garbage collect stuff
    exe.link_function_sections = true;
    exe.link_data_sections = true;
    exe.link_gc_sections = true;
    exe.dead_strip_dylibs = true;
    // linker magic
    exe.linkage = .static;
    exe.link_z_notext = false;
    exe.link_z_lazy = false;
    exe.link_z_relro = true;
    exe.link_eh_frame_hdr = true;
    exe.linker_allow_shlib_undefined = true;
    exe.linker_enable_new_dtags = true;
    exe.shared_memory = false;
    exe.rdynamic = false;
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
