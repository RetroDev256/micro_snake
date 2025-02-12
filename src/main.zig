const std = @import("std");
const linux = std.os.linux;
const timespec = linux.timespec;
const io = @import("io.zig");
const snake = @import("snake.zig");
const tools = @import("tools.zig");

pub const panic = std.debug.no_panic;

export fn memset(dest: ?[*]u8, c: u8, len: usize) callconv(.C) ?[*]u8 {
    for (dest.?[0..len]) |*d| d.* = c;
    return dest;
}

pub export fn _start() callconv(.C) noreturn {
    io.enable_raw();

    const dim_x = 80; // width of terminal
    const dim_y = 25; // height of terminal
    const Snake = snake.Snake(5, dim_x, dim_y);

    var screen: [dim_x * dim_y]u8 = undefined;
    @memset(&screen, ' ');
    banner(dim_x, dim_y, &screen);

    while (true) {
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
    const message = "µ-Snek!";
    const message_x: usize = dim_x / 2 - message.len / 2;
    const offset: usize = message_x + (dim_y / 2) * dim_x;
    @memcpy(screen[offset..][0..message.len], message);
    io.drawBuffer(dim_x, dim_y, screen);
    sleep(std.time.ns_per_ms * 750);
}

// for when the snake dies
fn deathAnim(comptime dim_x: u32, comptime dim_y: u32, screen: []u8) void {
    for (0..dim_x * dim_y * 2) |_| {
        const rand = tools.next();
        const place: u32 = rand % (dim_x * dim_y);
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
