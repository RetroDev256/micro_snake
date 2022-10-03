var prng: u32 = 1;
pub fn next() u32 {
    prng ^= prng << 13;
    prng ^= prng >> 17;
    prng ^= prng << 5;
    return prng;
}
