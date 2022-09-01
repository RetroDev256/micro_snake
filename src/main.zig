const linux = @import("std").os.linux;
const snek_io = @import("snek_io.zig");
const Snake = @import("snake.zig").Snake(80, 25);

pub export fn _start() callconv(.Naked) noreturn {
    main();
}

const delay: linux.timespec = .{
    .tv_sec = 0,
    .tv_nsec = 0x5000000,
};

fn main() noreturn {
    @setAlignStack(16);
    while (true) {
        snek_io.cbreakMode();
        var snek = Snake.new();
        while (snek.move()) {
            _ = linux.nanosleep(&delay, null);
        }
    }
}
