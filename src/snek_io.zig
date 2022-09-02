const linux = @import("std").os.linux;

pub const Direction = enum { Up, Down, Right, Left };

// Disable character echo & line buffering
// doesn't save old settings, so not reversible
pub fn cbreakMode() void {
    var termios: linux.termios = undefined;
    _ = linux.tcgetattr(0, &termios);
    termios.cc[linux.V.MIN] = 0; // nonblocking input
    termios.lflag &= ~(linux.ICANON | linux.ECHO);
    _ = linux.tcsetattr(0, .FLUSH, &termios);
}

// get a character if there is one to be read
// return the direction it represents, if it does.
pub fn get_dir(last: *Direction) void {
    var input: u8 = undefined;
    while (linux.read(0, @ptrCast([*]u8, &input), 1) > 0) {
        const subbed = input -% 65;
        if (subbed < 4) {
            last.* = @intToEnum(Direction, subbed);
            return;
        }
    }
}

// convert u32 to string representation
pub fn u32Conv(val: u32, buf: [*]u8) void {
    var conv: u32 = val;
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        buf[9 - i] = '0' + @intCast(u8, conv % 10);
        conv /= 10;
    }
}
