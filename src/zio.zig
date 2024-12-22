const std = @import("std");
const testing = std.testing;

const clap = @import("clap");
const nexlog = @import("nexlog");

pub fn parse_args(gpa: std.mem.Allocator) !void {
    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-n, --number <usize>   An option parameter, which takes a value.
        \\-s, --string <str>...  An option parameter which can be specified multiple times.
        \\<str>...
        \\
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa,
    }) catch |err| {
        // Report useful error and exit.
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    if (res.args.number) |n|
        std.debug.print("--number = {}\n", .{n});
    for (res.args.string) |s|
        std.debug.print("--string = {s}\n", .{s});
    for (res.positionals) |pos|
        std.debug.print("{s}\n", .{pos});
}

pub const LogLevel = nexlog.LogLevel;
pub const LogMetadata = nexlog.LogMetadata;

pub const ZioContext = struct {
    gpa: std.mem.Allocator,
    logger: *nexlog.Logger,

    pub fn init(gpa: std.mem.Allocator, log_level: LogLevel) !ZioContext {
        // Initialize with builder pattern
        var builder = nexlog.LogBuilder.init(); // Create a mutable LogBuilder instance
        try builder
            .setMinLevel(log_level)
            .enableColors(true)
            .enableFileLogging(true, "app.log")
            .build(gpa);

        const logger = nexlog.getDefaultLogger().?;
        return ZioContext{
            .gpa = gpa,
            .logger = logger,
        };
    }

    pub fn deinit(self: *ZioContext) void {
        self.logger.deinit();
    }
};

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
