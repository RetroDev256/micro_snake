const std = @import("std");
const linux = std.os.linux;
const timespec = linux.timespec;
const io = @import("io.zig");
const snake = @import("snake.zig");
const tools = @import("tools.zig");

// override the default panic handler, make teeny :)
pub fn panic(_: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);
    @trap();
}

pub export fn _start() callconv(.C) noreturn {
    @setAlignStack(16);

    const old_termios = io.enable_raw();
    defer io.set_term(old_termios);

    const dim_x: u32 = 80; // width of terminal
    const dim_y: u32 = 25; // height of terminal

    var screen: [dim_x * dim_y]u8 = undefined;
    @memset(&screen, ' ');
    banner(dim_x, dim_y, &screen);

    while (true) {
        const Snake = snake.Snake(5, dim_x, dim_y);
        var grid: [dim_x * dim_y]u32 = undefined;
        @memset(&grid, 0);
        var cur_snake: Snake = Snake.init(&grid);

        while (cur_snake.move()) {
            cur_snake.renderArena(&screen);
            io.drawBuffer(dim_x, dim_y, &screen);
            sleep(std.time.ns_per_ms * 75);
        }
        deathAnim(dim_x, dim_y, &screen);
    }
}

// for when the game initially starts up
fn banner(comptime dim_x: usize, comptime dim_y: usize, screen: []u8) void {
    const message: []const u8 = "µ-Snek!";
    const message_x: usize = dim_x / 2 - message.len / 2;
    const offset: usize = message_x + (dim_y / 2) * dim_x;
    @memcpy(screen[offset..][0..message.len], message);
    io.drawBuffer(dim_x, dim_y, screen);
    sleep(std.time.ns_per_ms * 750);
}

// for when the snake dies
fn deathAnim(comptime dim_x: usize, comptime dim_y: usize, screen: []u8) void {
    for (0..dim_x * dim_y * 2) |_| {
        const rand = tools.next();
        const place: u32 = @intCast(rand % (dim_x * dim_y));
        const char: u32 = (rand % 64) + 32;
        screen[place] = @truncate(char);
        io.drawBuffer(dim_x, dim_y, screen);
    }
}

// shortcut for sleeping
fn sleep(comptime ns: isize) void {
    const delay: timespec = .{ .sec = 0, .nsec = ns };
    _ = linux.nanosleep(&delay, null);
}
