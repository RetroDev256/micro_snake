const linux = @import("std").os.linux;
const snek_io = @import("snek_io.zig");
const Direction = snek_io.Direction;

pub fn Snake(comptime dim_x: comptime_int, comptime dim_y: comptime_int) type {
    const area: comptime_int = dim_x * dim_y;
    return struct {
        head: usize,
        length: usize,
        food: usize,
        segments: [area]usize,
        occupied: [area]bool,

        // create a new snake instance
        pub fn new() @This() {
            const snek_x: usize = dim_x / 4;
            const snek_y: usize = dim_y / 2;
            const snek_loc: usize = snek_x + snek_y * dim_x;
            var snek: @This() = .{
                .head = 0,
                .length = 1,
                .food = snek_loc + 1,
                .segments = .{snek_loc} ++ .{0} ** (area - 1),
                .occupied = .{false} ** area,
            };
            return snek;
        }

        // returns true if a collision occurs
        pub inline fn move(self: *@This(), dir: Direction) bool {
            const old_pos: usize = self.segments[self.head];
            if (!wallHit(old_pos, dir)) {
                const new_pos: usize = moveHead(old_pos, dir);
                printSymbol('@', new_pos);
                if (!self.occupied[new_pos]) {
                    const new_head: usize = (self.head + 1) % area;
                    self.head = new_head;
                    self.occupied[new_pos] = true;
                    self.segments[new_head] = new_pos;
                    if (new_pos == self.food % area) {
                        self.updateFood();
                        self.length += 1;
                        self.printScore();
                    } else {
                        const tail_ind: usize = (self.head + area) - self.length;
                        const tail_pos: usize = self.segments[tail_ind % area];
                        self.occupied[tail_pos] = false;
                        printSymbol('.', tail_pos);
                    }
                    return false;
                }
            }
            return true;
        }

        // prepare the screen for snake
        pub inline fn prepareArena() void {
            var y: usize = 0;
            while (y < dim_y) : (y += 1) {
                snek_io.move(0, y);
                var x: usize = 0;
                while (x < dim_x) : (x += 1) {
                    _ = linux.write(1, @ptrCast([*]u8, "."), 1);
                }
            }
        }

        // print out something on the screen
        fn printSymbol(symbol: u8, loc: usize) void {
            snek_io.move(loc % dim_x, loc / dim_x);
            _ = linux.write(1, @ptrCast([*]u8, &symbol), 1);
        }

        // print out the score in the bottom padding
        inline fn printScore(self: *@This()) void {
            var buf: [18]u8 = undefined;
            buf[0] = 'S';
            buf[1] = 'c';
            buf[2] = 'o'; // for some reason doing initialization
            buf[3] = 'r'; // like this actually reduces the size
            buf[4] = 'e'; // of the resulting binary.
            buf[5] = ':';
            buf[6] = ' ';
            buf[17] = ' ';
            snek_io.usizeConv(self.length - 2, buf[7..17]);
            snek_io.move(0, 0);
            _ = linux.write(1, @ptrCast([*]u8, &buf), 18);
        }

        // update the position of the food, simple LCG
        inline fn updateFood(self: *@This()) void {
            while (self.occupied[self.food % area]) {
                self.food *%= 0x9581f42d;
                self.food +%= 0x54057b7f;
            }
            printSymbol('+', self.food % area);
        }

        // change position of index based on direction
        inline fn moveHead(head: usize, dir: Direction) usize {
            return switch (dir) {
                .Down => head + dim_x,
                .Left => head - 1,
                .Right => head + 1,
                .Up => head - dim_x,
            };
        }

        // returns true if it will crash into a wall
        inline fn wallHit(head: usize, dir: Direction) bool {
            return switch (dir) {
                .Down => head / dim_x == dim_y - 1,
                .Left => head % dim_x == 0,
                .Right => head % dim_x == dim_x - 1,
                .Up => head / dim_x == 0,
            };
        }
    };
}