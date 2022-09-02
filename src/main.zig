const linux = @import("std").os.linux;
const snek_io = @import("snek_io.zig");
const Snake = @import("snake.zig").Snake;

const delay: linux.timespec = .{ .tv_sec = 0, .tv_nsec = 0x5000000 };

pub export fn _start() callconv(.Naked) noreturn {
    snek_io.cbreakMode();
    var snek: Snake = undefined;
    while (true) {
        snek.init();
        while (snek.move()) {
            _ = linux.nanosleep(&delay, null);
        }
    }
}
