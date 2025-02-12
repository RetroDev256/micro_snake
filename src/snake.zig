const dir = @import("dir.zig");
const tools = @import("tools.zig");
const Dir = dir.Dir;

pub fn Snake(
    comptime food_add: u32,
    comptime dim_x: u32,
    comptime dim_y: u32,
) type {
    const area: u32 = dim_x * dim_y;
    return struct {
        const Self = @This();

        dir: Dir = .right,
        length: u32 = food_add,
        head: u32,
        food: u32,
        grid: *[area]u32,

        // initialize the snake and environment
        pub fn init(grid: *[area]u32) Self {
            const head: u32 = (dim_x / 3) + (dim_y / 3) * dim_x;
            const food: u32 = 2 * (dim_x / 3) + 2 * (dim_y / 3) * dim_x;
            return .{ .head = head, .food = food, .grid = grid };
        }

        // returns false if a collision occurs
        pub fn move(self: *Self) bool {
            self.dir = dir.getDir(self.dir);
            self.subGrid(); // move the snake along
            if (!self.wallHit()) {
                switch (self.dir) {
                    .up => self.head -= dim_x,
                    .down => self.head += dim_x,
                    .right => self.head += 1,
                    .left => self.head -= 1,
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
        pub fn renderArena(self: *const Self, screen: *[area]u8) void {
            // clear the screen
            @memset(screen, '.');
            // draw the score
            @memcpy(screen[0..4], "Len:");
            // Render the score (max 6 digits) at index 5 on the screen
            tools.u32Conv(self.length, screen[5..][0..6]);
            // render the snake
            for (screen, self.grid) |*elem, cell| {
                if (cell > 0) elem.* = 'o';
                if (cell == self.length) elem.* = '@';
            }
            screen[self.food] = '+';
        }

        // simply moves the snake
        fn subGrid(self: *Self) void {
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
        fn wallHit(self: *const Self) bool {
            const head_x = self.head % dim_x;
            const head_y = self.head / dim_x;
            return switch (self.dir) {
                .down => head_y == dim_y - 1,
                .left => head_x == 0,
                .right => head_x == dim_x - 1,
                .up => head_y == 0,
            };
        }
    };
}
