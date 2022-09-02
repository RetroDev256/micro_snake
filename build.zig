const std = @import("std");
const Mode = std.builtin.Mode;
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    // config
    b.setPreferredReleaseMode(Mode.ReleaseSmall);
    b.is_release = true;
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .i386,
        .os_tag = .freestanding,
    } });
    const mode = b.standardReleaseOptions();

    // build
    const exe = b.addExecutable("micro_snake", "src/main.zig");
    exe.strip = true;
    exe.headerpad_size = 0;
    exe.link_gc_sections = true;
    exe.dead_strip_dylibs = true;
    exe.disable_sanitize_c = true;
    exe.disable_stack_probing = true;
    exe.single_threaded = true;
    exe.stack_protector = false;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const path = try std.fmt.allocPrint(
        b.allocator,
        "{s}/{s}",
        .{ b.exe_dir, exe.out_filename },
    );
    defer b.allocator.free(path);

    // strip step
    const strip_step = b.addSystemCommand(&.{
        "strip",
        "-R",
        ".comment",
        path,
    });
    b.default_step.dependOn(&strip_step.step);

    // sstrip step
    const sstrip_step = b.addSystemCommand(&.{
        "sstrip",
        "-z",
        path,
    });
    b.default_step.dependOn(&sstrip_step.step);

    // echo binary size
    const report_step = b.addSystemCommand(&.{
        "wc",
        "-c",
        path,
    });
    b.default_step.dependOn(&report_step.step);

    // run
    const run_step = b.step("run", "Run the app");
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_step.dependOn(&run_cmd.step);

    // tests
    const test_step = b.step("test", "Run unit tests");
    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    test_step.dependOn(&exe_tests.step);
}
