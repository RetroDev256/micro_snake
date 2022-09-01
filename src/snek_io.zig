const linux = @import("std").os.linux;

pub const Direction = enum { Up, Down, Right, Left };

// Disable character echo & line buffering
// doesn't save old settings, so not reversible
pub inline fn initTerm() void {
    var termios: linux.termios = undefined;
    _ = linux.tcgetattr(0, &termios);
    termios.lflag &= ~(linux.ICANON | linux.ECHO);
    termios.cc[linux.V.MIN] = 0; // nonblocking input
    termios.cc[linux.V.TIME] = 0; // no time delay for awaiting input
    _ = linux.tcsetattr(0, .FLUSH, &termios); // apply attributes
    _ = linux.write(1, "\x1B[2J\x1B[?25l", 10); // clear screen & turn off cursor
}

// get a character if there is one to be read
// return the direction it represents, if it does.
pub inline fn get_dir(last: *Direction) void {
    var input: u8 = undefined;
    const inp_ptr = @ptrCast([*]u8, &input);
    while (linux.read(0, inp_ptr, 1) == 1) {
        const subbed = input -% 65;
        if (subbed < 4) {
            last.* = @intToEnum(Direction, subbed);
            return;
        }
    }
}

// move terminal cursor position to a certain row
pub fn moveY(y: usize) void {
    var buf: [15]u8 = undefined;
    buf[0] = '\x1B';
    buf[1] = '[';
    buf[12] = ';';
    buf[13] = '0';
    buf[14] = 'H';
    usizeConv(y + 1, buf[2..12]);
    _ = linux.write(1, @ptrCast([*]u8, &buf), 15);
}

// convert usize to string representation
pub fn usizeConv(val: usize, buf: *[10]u8) void {
    var i: usize = 0;
    var left: usize = val;
    while (i < 10) {
        buf[9 - i] = '0' + @truncate(u8, left % 10);
        left /= 10;
        i += 1;
    }
}
