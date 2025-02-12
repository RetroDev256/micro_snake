const io = @import("io.zig");
pub const Dir = enum { up, down, right, left };

// get a character if there is one to be read
// return the direction it represents, if it does.
pub fn getDir(last: Dir) Dir {
    while (io.getch()) |key| {
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
        .up => .down,
        .down => .up,
        .right => .left,
        .left => .right,
    };
}
