const linux = @import("std").os.linux;

// Disable character echo & line buffering
// doesn't save old settings, so not reversible
pub fn cbreakMode() void {
    var termios: linux.termios = undefined;
    _ = linux.tcgetattr(0, &termios);
    termios.cc[@intFromEnum(linux.V.MIN)] = 0; // nonblocking input
    termios.lflag &= ~(linux.ICANON | linux.ECHO);
    _ = linux.tcsetattr(0, .FLUSH, &termios);
}

// returns the old termios so you can restore things
pub fn enable_raw() linux.termios {
    var old: linux.termios = undefined;
    _ = linux.tcgetattr(0, &old);
    var new: linux.termios = old;
    new.cc[@intFromEnum(linux.V.MIN)] = 0; // nonblocking input
    new.lflag.ICANON = false; // disable buffering
    new.lflag.ECHO = false; // disable echo
    set_term(new); // apply edits to terminal
    return old;
}

// resets the terminal from the return value of enable_raw
pub fn set_term(new: linux.termios) void {
    _ = linux.tcsetattr(0, linux.TCSA.NOW, &new);
}

// flushes a buffer to the screen, adding
// newlines and positioning at top right corner
pub fn drawBuffer(comptime dim_x: usize, comptime dim_y: usize, buf: []const u8) void {
    const top_right = "\x1B[1;1H";
    _ = linux.write(1, top_right.ptr, top_right.len);
    for (0..dim_y) |y| {
        const line = buf[y * dim_x ..][0..dim_x];
        _ = linux.write(1, line.ptr, line.len);
        _ = linux.write(1, "\n", 1);
    }
}

// get a keypress from STDIN
pub fn getch() u8 {
    var input: u8 = 0;
    _ = linux.read(0, @ptrCast(&input), 1);
    return input;
}
