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
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_impl.deinit();
    const gpa = gpa_impl.allocator();

    var ctx = try zio.ZioContext.init(gpa, zio.LogLevel.info);
    defer ctx.deinit();

    const args_ok = try zio.parse_args(gpa);
    if (!args_ok) {
        return;
    }

    // Create metadata
    const metadata = zio.LogMetadata{
        .timestamp = std.time.timestamp(),
        .thread_id = 0,
        .file = @src().file,
        .line = @src().line,
        .function = @src().fn_name,
    };

    try ctx.logger.log(.info, "Hello World from zio tui.", .{}, metadata);

    try start_tui(gpa);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
