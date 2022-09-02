const linux = @import("std").os.linux;
const cbreak = @import("cbreak.zig");
const Snake = @import("snake.zig").Snake;

const delay: linux.timespec = .{ .tv_sec = 0, .tv_nsec = 0x5000000 };

pub export fn _start() noreturn {
    cbreak.cbreakMode();
    var snek: Snake = undefined;
    while (true) {
        snek.init();
        while (snek.move()) {
            _ = linux.nanosleep(&delay, null);
        }
    }
}
