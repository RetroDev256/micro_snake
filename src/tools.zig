// dead simple PRNG
pub fn next() u32 {
    const prng = &struct {
        var prng: u32 = 1;
    }.prng;
    prng.* ^= prng.* << 13;
    prng.* ^= prng.* >> 17;
    prng.* ^= prng.* << 5;
    return prng.*;
}

// convert u32 to string representation
pub fn u32Conv(val: u32, buf: []u8) void {
    var conv: u32 = val;
    for (0..10) |i| {
        buf[9 - i] = '0' + @as(u8, @intCast(conv % 10));
        conv = conv / 10;
    }
}
