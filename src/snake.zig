const linux = @import("std").os.linux;
const snek_io = @import("snek_io.zig");
const Direction = snek_io.Direction;

pub fn Snake(comptime dim_x: comptime_int, comptime dim_y: comptime_int) type {
    const area: comptime_int = dim_x * dim_y;

    return struct {
        head: usize,
        dir: Direction,
        length: usize,
        foodLCG: usize,
        grid: [area]usize,

        // create a new snake instance
        pub fn new() @This() {
            const snake_pos: usize = (dim_y / 2) * dim_x;
            return .{
                .head = snake_pos,
                .dir = .Right,
                .length = 1,
                .foodLCG = snake_pos + 1,
                .grid = .{0} ** area,
            };
        }

        // returns true if a collision occurs
        pub fn move(self: *@This()) bool {
            snek_io.get_dir(&self.dir);
            for (self.grid) |*cell| {
                cell.* -|= 1;
            }
            if (!self.wallHit()) {
                const head_diff: usize = switch (self.dir) {
                    .Up => area - dim_x,
                    .Down => dim_x,
                    .Right => 1,
                    .Left => area - 1,
                };
                self.head = (self.head + head_diff) % area;
                if (self.grid[self.head] == 0) {
                    self.grid[self.head] = self.length;
                    if (self.head == self.foodLCG) {
                        self.length += 1;
                        while (self.grid[self.foodLCG % area] > 0) {
                            self.foodLCG *%= 0x9581f42d;
                            self.foodLCG +%= 0x54057b7f;
                        }
                        self.foodLCG %= area;
                    }
                    self.drawArena();
                    return true;
                }
            }
            return false;
        }

        // render the entire game (slower, but fewer bytes)
        pub fn drawArena(self: *@This()) void {
            var screen: [area]u8 = ("." ** area).*;
            screen[0] = 'S';
            screen[1] = 'c';
            screen[2] = 'o';
            screen[3] = 'r';
            screen[4] = 'e';
            screen[5] = ':';
            const score_ctr_ptr = @ptrCast([*]u8, screen[7..]);
            snek_io.usizeConv(self.length - 2, score_ctr_ptr);
            for (screen) |*elem, i| {
                if (self.grid[i] > 0) {
                    elem.* = '@';
                }
            }
            screen[self.foodLCG] = '+';
            drawBuffer(&screen);
        }

        fn drawBuffer(buf: *[area]u8) void {
            _ = linux.write(1, "\x1B[1;1H", 6);
            var y: usize = 0;
            while (y < dim_y) : (y += 1) {
                const row = @ptrCast([*]u8, buf[y * dim_x ..]);
                _ = linux.write(1, row, dim_x);
                _ = linux.write(1, "\n", 1);
            }
        }

        // returns true if it will crash into a wall
        fn wallHit(self: *@This()) bool {
            return switch (self.dir) {
                .Down => self.head / dim_x == dim_y - 1,
                .Left => self.head % dim_x == 0,
                .Right => self.head % dim_x == dim_x - 1,
                .Up => self.head / dim_x == 0,
            };
        }
    };
}
