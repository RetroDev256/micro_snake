const dir = @import("dir.zig");
const tools = @import("tools.zig");
const Direction = dir.Direction;

pub fn Snake(
    comptime food_add: u32,
    comptime dim_x: u32,
    comptime dim_y: u32,
) type {
    const area: u32 = dim_x * dim_y;
    return struct {
        const Self = @This();

        head: u32,
        dir: Direction,
        length: u32,
        food: u32,
        grid: []u32,

        // initialize the snake and environment
        pub fn init(grid: *[area]u32) Self {
            const head: u32 = (dim_x / 3) + (dim_y / 2) * dim_x;
            return .{
                .head = head,
                .dir = .Right,
                .length = 1,
                .food = head + (dim_x / 3),
                .grid = grid,
            };
        }

        // returns true if a collision occurs
        pub fn move(self: *Self) bool {
            self.dir = dir.get_dir(self.dir);
            self.updateGrid();
            if (!self.wallHit()) {
                switch (self.dir) {
                    .Up => self.head -= dim_x,
                    .Down => self.head += dim_x,
                    .Right => self.head += 1,
                    .Left => self.head -= 1,
                }
                if (self.grid[self.head] == 0) {
                    self.grid[self.head] = self.length;
                    self.updateFood();
                    return true;
                }
            }
            return false;
        }

        // render the entire game (slower, but fewer bytes)
        pub fn renderArena(self: *Self, screen: *[area]u8) void {
            for (screen) |*cell| cell.* = '.';
            @memcpy(screen[0..4], "Len:");
            tools.u32Conv(self.length - 1, @ptrCast(screen[5..]));
            for (screen, self.grid) |*elem, cell| {
                if (cell > 0) {
                    elem.* = '@';
                }
            }
            screen[self.food] = '+';
        }

        // updates the grid
        fn updateGrid(self: *Self) void {
            for (self.grid) |*cell| {
                cell.* -|= 1;
            }
        }

        // updates the position of the food
        fn updateFood(self: *Self) void {
            if (self.head == self.food) {
                self.length += food_add;
                while (self.grid[self.food] != 0) {
                    self.food = tools.next() % area;
                }
            }
        }

        // returns true if it will crash into a wall
        fn wallHit(self: *Self) bool {
            const head_x = self.head % dim_x;
            const head_y = self.head / dim_x;
            return switch (self.dir) {
                .Down => head_y == dim_y - 1,
                .Left => head_x == 0,
                .Right => head_x == dim_x - 1,
                .Up => head_y == 0,
            };
        }
    };
}
