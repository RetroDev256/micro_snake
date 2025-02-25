const std = @import("std");
const assert = std.debug.assert;
const linux = std.os.linux;
const timespec = linux.timespec;

const food_add = 5; // snake increase from food
const width = 80; // width of terminal
const height = 24; // height of terminal
const area = width * height;

export fn memset(dest: ?[*]u8, c: u8, len: usize) ?[*]u8 {
    for (0..len) |i| {
        dest.?[i] = c;
    }
    return dest;
}

pub export fn _start() noreturn {
    enableRawMode();

    while (true) {
        var screen: [area]u8 = undefined;
        var grid: [area]u32 = undefined;
        banner(&screen);

        var snake: Snake = .init(&grid);
        while (snake.move()) {
            snake.renderArena(&screen);
            drawBuffer(&screen);
            sleep(std.time.ns_per_ms * 75);
        }
    }
}

// transition screen for the start of the game, and death
fn banner(screen: *[area]u8) void {
    const msg = "u-Snek!";
    for (0..area) |i| {
        screen[i] = msg[i % msg.len];
        drawBuffer(screen);
        sleep(std.time.ns_per_ms);
    }
}

// shortcut for sleeping
fn sleep(comptime ns: isize) void {
    comptime assert(ns < std.time.ns_per_s);
    const delay: timespec = .{ .sec = 0, .nsec = ns };
    _ = linux.nanosleep(&delay, null);
}

pub const Dir = enum { up, down, right, left };

// get a character if there is one to be read
// return the direction it represents, if it does.
pub fn getDir(last: Dir) Dir {
    while (getch()) |key| {
        const subbed = key -% 'A';
        if (subbed < 4) {
            const dir_read: Dir = @enumFromInt(subbed);
            if (blockDir(last) != dir_read) {
                return dir_read;
            }
        }
    }
    return last;
}

fn blockDir(a: Dir) Dir {
    return switch (a) {
        .left => .right,
        .right => .left,
        .up => .down,
        .down => .up,
    };
}

// Disable character echo & line buffering
// doesn't save old settings, so not reversible
pub fn enableRawMode() void {
    var termios: linux.termios = undefined;
    assert(linux.tcgetattr(0, &termios) == 0);
    termios.cc[@intFromEnum(linux.V.MIN)] = 0;
    termios.lflag.ICANON = false;
    assert(linux.tcsetattr(0, .FLUSH, &termios) == 0);
}

// flushes a buffer to the screen, adding
// newlines and positioning at top right corner
pub fn drawBuffer(buf: []const u8) void {
    putstr("\x1B[H");
    for (0..height) |y| {
        const line_start = buf[y * width ..];
        putstr(line_start[0..width]);
        putstr("\n");
    }
}

// Print a string at cursor - can fail, but likely won't
fn putstr(str: []const u8) void {
    assert(linux.write(1, str.ptr, str.len) == str.len);
}

// get a keypress from STDIN - silent on no input
pub fn getch() ?u8 {
    var key: u8 = undefined;
    const return_value = linux.read(0, @ptrCast(&key), 1);
    if (return_value == 0) return null;
    assert(return_value == 1);
    return key;
}

// dead simple PRNG
var prng: u32 = 1;
pub fn rand() u32 {
    prng = (prng *% 69069) +% 1;
    return prng;
}

// convert u32 to string representation
pub fn u32Conv(val: u32, buf: []u8) void {
    var conv: u32 = val;
    var i: usize = 0;
    while (conv > 0) : (i += 1) {
        const digit: u8 = @intCast(conv % 10);
        buf[buf.len - (i + 1)] = '0' + digit;
        conv /= 10;
    }
}

const Snake = struct {
    head: u32,
    food: u32,
    dir: Dir,
    length: u32,
    grid: *[area]u32,

    // initialize the snake and environment
    pub fn init(grid: *[area]u32) Snake {
        @memset(grid, 0);
        return .{
            .head = (width / 3) + (height / 3) * width,
            .food = 2 * (width / 3) + 2 * (height / 3) * width,
            .dir = .right,
            .length = food_add,
            .grid = grid,
        };
    }

    // returns false if a collision occurs
    pub fn move(self: *Snake) bool {
        self.dir = getDir(self.dir);

        // burn up those calories
        for (self.grid) |*cell| cell.* -|= 1;

        if (self.wallHit()) {
            // you done goofed
            return false;
        }

        // move the snake's head position
        switch (self.dir) {
            .up => self.head -= width,
            .down => self.head += width,
            .right => self.head += 1,
            .left => self.head -= 1,
        }

        if (self.grid[self.head] == 0) {
            // you didn't hit anything!
            self.grid[self.head] = self.length;
        } else {
            // you hit yourself, nitwit!
            return false;
        }

        if (self.head == self.food) {
            // you hit food!
            self.length += food_add;
            while (true) {
                self.food = rand() % area;
                if (self.grid[self.food] == 0) break;
            }
        }

        return true;
    }

    // render the entire game (slower, but fewer bytes)
    // TODO: investigate *const Snake for self
    pub fn renderArena(self: Snake, screen: *[area]u8) void {
        // clear the screen
        @memset(screen, '.');

        // render the score (bottom right)
        u32Conv(self.length, screen);

        // render the snake
        for (screen, self.grid) |*elem, cell| {
            if (cell == self.length) {
                elem.* = '@';
            } else if (cell > 0) {
                elem.* = 'o';
            }
        }

        // render the food
        screen[self.food] = '+';
    }

    // returns true if it will crash into a wall
    fn wallHit(self: Snake) bool {
        const head_x = self.head % width;
        const head_y = self.head / width;
        return switch (self.dir) {
            .down => head_y == height - 1,
            .left => head_x == 0,
            .right => head_x == width - 1,
            .up => head_y == 0,
        };
    }
};
