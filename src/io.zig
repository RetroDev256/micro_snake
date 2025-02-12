const std = @import("std");
const assert = std.debug.assert;
const linux = std.os.linux;

// Disable character echo & line buffering
// doesn't save old settings, so not reversible
pub fn enable_raw() void {
    var termios: linux.termios = undefined;
    assert(linux.tcgetattr(0, &termios) == 0);
    termios.cc[@intFromEnum(linux.V.MIN)] = 0;
    termios.lflag.ICANON = false;
    assert(linux.tcsetattr(0, .FLUSH, &termios) == 0);
}

// flushes a buffer to the screen, adding
// newlines and positioning at top right corner
pub fn drawBuffer(comptime dim_x: usize, comptime dim_y: usize, buf: []const u8) void {
    const top_right = "\x1B[H";
    putstr(top_right.ptr, top_right.len);
    for (0..dim_y) |y| {
        const line = buf[y * dim_x ..];
        putstr(line.ptr, dim_x);
        putstr("\n", 1);
    }
}

// Print a string at cursor - can fail, but likely won't
fn putstr(str: [*]const u8, comptime len: usize) void {
    assert(linux.write(1, str, len) == len);
}

// get a keypress from STDIN - silent on no input
pub fn getch() ?u8 {
    var key: u8 = undefined;
    const return_value = linux.read(0, @ptrCast(&key), 1);
    if (return_value == 0) return null;
    assert(return_value == 1);
    return key;
}
