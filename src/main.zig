const std = @import("std");
const assert = std.debug.assert;
const linux = std.os.linux;

const food_add = 5; // snake increase from food
const width = 80; // width of terminal
const height = 24; // height of terminal
const area = width * height;

pub export fn _start() noreturn {
    enableRawMode();

    while (true) {
        banner();

        var grid: [area]u32 = undefined;
        var snake: Snake = .init(&grid);
        while (snake.move()) {
            renderArena(&grid, snake.food, snake.length);
            sleep(std.time.ns_per_ms * 75);
        }
    }
}

// transition screen for the start of the game, and death
fn banner() void {
    const message = "μ-Snek!";
    const ansi = std.fmt.comptimePrint(
        "\x1B[2J\x1B[{};{}H",
        .{ height / 2, (width / 2) - (message.len / 2) },
    );
    putstr(ansi ++ message);
    sleep(std.time.ns_per_ms * 850);
}

// shortcut for sleeping
fn sleep(comptime ns: isize) void {
    comptime assert(ns < std.time.ns_per_s);
    const delay: linux.timespec = .{ .sec = 0, .nsec = ns };
    _ = linux.nanosleep(&delay, undefined);
}

const Dir = enum(u32) { up, down, right, left };

// get a character if there is one to be read
// return the direction it represents, if it does.
fn getDir(last: *const Dir) Dir {
    var key: u8 = undefined;
    while (getch(&key) != 0) {
        const subbed = key -% 'A';
        if (subbed >= 4) continue;
        const read: Dir = @enumFromInt(subbed);
        if (blockDir(last) == read) continue;
        return read;
    }
    return last.*;
}

fn blockDir(a: *const Dir) Dir {
    return switch (a.*) {
        .left => .right,
        .right => .left,
        .up => .down,
        .down => .up,
    };
}

// Disable character echo & line buffering
// doesn't save old settings, so not reversible
fn enableRawMode() void {
    var termios: linux.termios = undefined;
    assert(linux.tcgetattr(0, &termios) == 0);
    termios.cc[@intFromEnum(linux.V.MIN)] = 0;
    termios.lflag.ICANON = false;
    assert(linux.tcsetattr(0, .FLUSH, &termios) == 0);
}

// Print a string at cursor - can fail, but likely won't
// Normally I'd print to STDOUT, but STDERR saves 2 bytes
fn putstr(str: []const u8) void {
    assert(linux.write(2, str.ptr, str.len) == str.len);
}

// get a keypress from STDIN - return number of keys read
fn getch(key: *u8) u32 {
    switch (linux.read(0, key[0..1], 1)) {
        0, 1 => |read| return read,
        else => unreachable,
    }
}

// dead simple PRNG
var prng_state: u32 = 1;
fn rand() u32 {
    prng_state = (prng_state *% 69069) +% 1;
    return prng_state;
}

const Snake = struct {
    head: u32,
    food: u32,
    dir: Dir,
    length: u32,
    grid: *[area]u32,

    // initialize the snake and environment
    fn init(grid: *[area]u32) Snake {
        grid.* = @splat(0);
        return .{
            .head = (width / 3) + (height / 3) * width,
            .food = 2 * (width / 3) + 2 * (height / 3) * width,
            .dir = .right,
            .length = food_add,
            .grid = grid,
        };
    }

    // returns false if a collision occurs
    fn move(self: *Snake) bool {
        self.dir = getDir(&self.dir);

        // burn up those calories
        for (self.grid) |*cell| cell.* -|= 1;

        if (wallHit(self.head, self.dir)) {
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

        if (self.grid[self.head] != 0) {
            // you hit yourself, nitwit!
            return false;
        } else {
            // you didn't hit anything!
            self.grid[self.head] = self.length;
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
};

// render the entire game (slower, but fewer bytes)
fn renderArena(grid: *[area]u32, food: u32, length: u32) void {
    // Move to top left
    putstr("\x1B[H");

    // render the snake
    var idx: u32 = 0;
    var row: u32 = 0;
    while (idx < area) {
        const cell = grid[idx];

        // Empty cells are '.' by default
        var char: u8 = '.';
        if (idx == food) {
            char = '+';
        } else if (cell == length) {
            char = '@';
        } else if (cell != 0) {
            char = 'o';
        }
        putstr(&.{char});

        // Add a newline after each line
        idx += 1;
        row += 1;
        if (row == width) {
            row = 0;
            putstr("\n");
        }
    }
}

// returns true if it will crash into a wall
fn wallHit(head: u32, dir: Dir) bool {
    const head_x = head % width;
    const head_y = head / width;
    return switch (dir) {
        .down => head_y == height - 1,
        .left => head_x == 0,
        .right => head_x == width - 1,
        .up => head_y == 0,
    };
}
