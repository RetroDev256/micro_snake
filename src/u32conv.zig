// convert u32 to string representation
pub fn u32Conv(val: u32, buf: [*]u8) void {
    var conv: u32 = val;
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        buf[9 - i] = '0' + @intCast(u8, conv % 10);
        conv /= 10;
    }
}