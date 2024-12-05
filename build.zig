const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zio",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/zio.zig"),
        .target = target,
        .optimize = optimize,
    });

    const clap = b.dependency("clap", .{});
    lib.root_module.addImport("clap", clap.module("clap"));

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const tui_exe = b.addExecutable(.{
        .name = "zio",
        .root_source_file = b.path("src/tui.zig"),
        .target = target,
        .optimize = optimize,
    });

    tui_exe.root_module.addImport("zio", &lib.root_module);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(tui_exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const tui_run_cmd = b.addRunArtifact(tui_exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    tui_run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        tui_run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const tui_run_step = b.step("run-tui", "Run the app");
    tui_run_step.dependOn(&tui_run_cmd.step);

    const gui_exe = b.addExecutable(.{
        .name = "ziog",
        .root_source_file = b.path("src/gui.zig"),
        .target = target,
        .optimize = optimize,
    });

    gui_exe.root_module.addImport("zio", &lib.root_module);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(gui_exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const gui_run_cmd = b.addRunArtifact(gui_exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    gui_run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        gui_run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const gui_run_step = b.step("run-gui", "Run the app");
    gui_run_step.dependOn(&gui_run_cmd.step);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&gui_run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/zio.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const tui_exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tui.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tui_run_exe_unit_tests = b.addRunArtifact(tui_exe_unit_tests);

    const gui_exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/gui.zig"),
        .target = target,
        .optimize = optimize,
    });

    const gui_run_exe_unit_tests = b.addRunArtifact(gui_exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&tui_run_exe_unit_tests.step);
    test_step.dependOn(&gui_run_exe_unit_tests.step);
}
