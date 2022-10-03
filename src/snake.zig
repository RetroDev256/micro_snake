const dir = @import("dir.zig");
const rng = @import("rng.zig");
const u32conv = @import("u32conv.zig");
const Direction = dir.Direction;

pub fn Snake(
    comptime food_add: u32,
    comptime dim_x: u32,
    comptime dim_y: u32,
) type {
    const area: u32 = dim_x * dim_y;
    return struct {
        head: u32,
        dir: Direction,
        length: u32,
        food: u32,
        grid: [area]u32,

        // initialize the snake and environment
        pub fn init() @This() {
            // initial snake starting position
            const head: u32 = (dim_x / 3) + (dim_y / 2) * dim_x;
            return .{
                .head = head,
                .dir = .Right,
                .length = 1,
                // initial food starting position
                .food = head + (dim_x / 3),
                .grid = .{0} ** area,
            };
        }

        // returns true if a collision occurs
        pub fn move(self: *@This()) bool {
            self.dir = dir.get_dir(self.dir);
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
                    self.updateFood();
                    return true;
                }
            }
            return false;
        }

        // render the entire game (slower, but fewer bytes)
        pub fn renderArena(self: *@This(), screen: *[area]u8) void {
            for (screen) |*cell| cell.* = '.';
            screen[0] = 'L';
            screen[1] = 'e';
            screen[2] = 'n';
            screen[3] = ':';
            u32conv.u32Conv(self.length - 1, @ptrCast([*]u8, screen[5..]));
            for (screen) |*elem, i| {
                if (self.grid[i] > 0) {
                    elem.* = '@';
                }
            }
            screen[self.food] = '+';
        }

        // updates the grid
        fn updateGrid(self: *@This()) void {
            for (self.grid) |*cell| {
                cell.* -|= 1;
            }
        }

        // updates the position of the food
        fn updateFood(self: *@This()) void {
            if (self.head == self.food) {
                self.length += food_add;
                while (self.grid[self.food] > 0) {
                    self.food = rng.next() % area;
                }
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
