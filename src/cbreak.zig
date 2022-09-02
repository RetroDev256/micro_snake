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
