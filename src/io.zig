const linux = @import("std").os.linux;

// Disable character echo & line buffering
// doesn't save old settings, so not reversible
pub fn cbreakMode() void {
    var termios: linux.termios = undefined;
    _ = linux.tcgetattr(0, &termios);
    termios.cc[linux.V.MIN] = 0; // nonblocking input
    termios.lflag &= ~(linux.ICANON | linux.ECHO);
    _ = linux.tcsetattr(0, .FLUSH, &termios);
}

// flushes a buffer to the screen, adding
// newlines and positioning at top right corner
pub fn drawBuffer(
    comptime dim_x: usize,
    comptime dim_y: usize,
    buf: []const u8,
) void {
    _ = linux.write(1, "\x1B[1;1H", 6);
    var y: usize = 0;
    while (y < dim_y) : (y += 1) {
        const row = @ptrCast([*]const u8, buf[y * dim_x ..]);
        _ = linux.write(1, row, dim_x);
        _ = linux.write(1, "\n", 1);
    }
}

// get a keypress from STDIN
pub fn getch() ?u8 {
    var input: u8 = undefined;
    const read: usize = linux.read(0, @ptrCast([*]u8, &input), 1);
    return if (read > 0) input else null;
}
