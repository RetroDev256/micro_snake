const io = @import("io.zig");
pub const Direction = enum(u2) { Up, Down, Right, Left };

// get a character if there is one to be read
// return the direction it represents, if it does.
pub fn get_dir(last: Direction) Direction {
    while (true) {
        const input = io.getch();
        if (input == 0) break;
        const subbed = input -% 'A';
        if (subbed < 4) {
            const dir_read: Direction = @enumFromInt(subbed);
            if (!blockDir(last, dir_read)) {
                return dir_read;
            }
        }
    }
    return last;
}

fn blockDir(a: Direction, b: Direction) bool {
    return switch (a) {
        .Up => b == .Down,
        .Down => b == .Up,
        .Right => b == .Left,
        .Left => b == .Right,
    };
}
