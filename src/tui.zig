const std = @import("std");
const zio = @import("zio");

const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Model = struct {
    split: vxfw.SplitView,
    lhs: vxfw.Text,
    rhs: vxfw.Text,
    children: [1]vxfw.SubSurface = undefined,

    pub fn widget(self: *Model) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = Model.typeErasedEventHandler,
            .drawFn = Model.typeErasedDrawFn,
        };
    }

    fn typeErasedEventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(ptr));
        switch (event) {
            .init => {
                self.split.lhs = self.lhs.widget();
                self.split.rhs = self.rhs.widget();
            },
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    ctx.quit = true;
                    return;
                }
            },
            else => {},
        }
    }

    fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(ptr));
        const surf = try self.split.widget().draw(ctx);
        self.children[0] = .{
            .surface = surf,
            .origin = .{ .row = 0, .col = 0 },
        };
        return .{
            .size = ctx.max.size(),
            .widget = self.widget(),
            .buffer = &.{},
            .children = &self.children,
        };
    }
};

pub fn start_tui(gpa: std.mem.Allocator) !void {
    var app = try vxfw.App.init(gpa);
    defer app.deinit();

    const model = try gpa.create(Model);
    defer gpa.destroy(model);
    model.* = .{
        .lhs = .{ .text = "Left hand side" },
        .rhs = .{ .text = "right hand side" },
        .split = .{ .lhs = undefined, .rhs = undefined, .width = 10 },
    };

    model.split.lhs = model.lhs.widget();
    model.split.rhs = model.rhs.widget();

    try app.run(model.widget(), .{});
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.

    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_impl.deinit();
    const gpa = gpa_impl.allocator();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Hello World from zio tui.\n", .{});

    try zio.parse_args(gpa);
    try start_tui(gpa);

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
