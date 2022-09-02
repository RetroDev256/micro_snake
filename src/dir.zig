const linux = @import("std").os.linux;
pub const Direction = enum { Up, Down, Right, Left };

// get a character if there is one to be read
// return the direction it represents, if it does.
pub fn get_dir(last: *Direction) void {
    var input: u8 = undefined;
    while (linux.read(0, @ptrCast([*]u8, &input), 1) > 0) {
        const subbed = input -% 65;
        if (subbed < 4) {
            const dir_read = @intToEnum(Direction, subbed);
            if (!oppositeDir(last.*, dir_read)) {
                last.* = dir_read;
                return;
            }
        }
    }
}

fn oppositeDir(a: Direction, b: Direction) bool {
    return switch (a) {
        .Up => b == .Down,
        .Down => b == .Up,
        .Right => b == .Left,
        .Left => b == .Right,
    };
}
