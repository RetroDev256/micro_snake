const linux = @import("std").os.linux;
const snek_io = @import("snek_io.zig");
const Direction = snek_io.Direction;

// length per food consumed
const food_add: u32 = 1;
// width of terminal
const dim_x: u32 = 80;
// height of terminal
const dim_y: u32 = 25;
// area of terminal
const area: u32 = dim_x * dim_y;

// initial snake starting position
const snake_pos: u32 = (dim_x / 3) + (dim_y / 2) * dim_x;
// initial food starting position
const food_pos: u32 = snake_pos + (dim_x / 3);

pub const Snake = struct {
    head: u32,
    dir: Direction,
    length: u32,
    foodLCG: u32,
    grid: [area]u32,
    // initialize the snake and environment
    pub fn init(self: *@This()) void {
        self.head = snake_pos;
        self.dir = .Right;
        self.length = 1;
        self.foodLCG = food_pos;
        self.grid = .{0} ** area;
    }
    // returns true if a collision occurs
    pub fn move(self: *@This()) bool {
        snek_io.get_dir(&self.dir);
        self.updateGrid();
        if (!self.wallHit()) {
            const head_diff: u32 = switch (self.dir) {
                .Up => area - dim_x,
                .Down => dim_x,
                .Right => 1,
                .Left => area - 1,
            };
            self.head = (self.head + head_diff) % area;
            if (self.grid[self.head] == 0) {
                self.grid[self.head] = self.length;
                if (self.head == self.foodLCG) {
                    self.length += food_add;
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
    // updates the grid
    fn updateGrid(self: *@This()) void {
        for (self.grid) |*cell| {
            cell.* -|= 1;
        }
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
        snek_io.u32Conv(self.length - 1, score_ctr_ptr);
        for (screen) |*elem, i| {
            if (self.grid[i] > 0) {
                const offset = @truncate(u8, self.grid[i] % 4);
                elem.* = offset + '#';
            }
        }
        screen[self.foodLCG] = '+';
        drawBuffer(&screen);
    }
    // flushes the buffer to the screen, adding
    // newlines and positioning at top right corner
    fn drawBuffer(buf: *[area]u8) void {
        _ = linux.write(1, "\x1B[1;1H", 6);
        var y: u32 = 0;
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
