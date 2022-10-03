const linux = @import("std").os.linux;
const timespec = linux.timespec;
const io = @import("io.zig");
const snake = @import("snake.zig");
const rng = @import("rng.zig");

const dim_x: u32 = 80; // width of terminal
const dim_y: u32 = 25; // height of terminal
const area: u32 = dim_x * dim_y; // area of terminal

pub export fn _start() noreturn {
    const delay: timespec = .{ .tv_sec = 0, .tv_nsec = 0x5000000 };
    var screen: [area]u8 = (" " ** area).*;
    io.cbreakMode();
    banner(&screen);
    while (true) {
        const Snake = snake.Snake(4, dim_x, dim_y);
        var cur_snake: Snake = Snake.init();
        while (cur_snake.move()) {
            cur_snake.renderArena(&screen);
            io.drawBuffer(dim_x, dim_y, &screen);
            _ = linux.nanosleep(&delay, null);
        }
        deathAnim(&screen);
    }
}

// for when the game initially starts up
fn banner(screen: []u8) void {
    const message: []const u8 = "µ-Snake!";
    const message_x: usize = dim_x / 2 - message.len / 2;
    const offset: usize = message_x + (dim_y / 2) * dim_x;
    for (message) |byte, i| screen[offset + i] = byte;
    io.drawBuffer(dim_x, dim_y, screen);
    const delay: timespec = .{ .tv_sec = 1, .tv_nsec = 0 };
    _ = linux.nanosleep(&delay, null);
}

// for when the snake dies
fn deathAnim(screen: []u8) void {
    var i: u32 = 0;
    while (i < area * 2) : (i += 1) {
        const place: u32 = rng.next() % area;
        const char: u32 = (rng.next() % 64) + 32;
        screen[place] = @truncate(u8, char);
        io.drawBuffer(dim_x, dim_y, screen);
    }
}
