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
pub fn u32Conv(val: u32, noalias buf: []u8) void {
    var conv: u32 = val;
    var i: usize = 0;
    while (conv > 0) : (i += 1) {
        const digit: u8 = @intCast(conv % 10);
        buf[buf.len - (i + 1)] = '0' + digit;
        conv /= 10;
    }
}
