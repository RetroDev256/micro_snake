const linux = @import("std").os.linux;
const snek_io = @import("snek_io.zig");
const Direction = snek_io.Direction;

const Snake = @import("snake.zig").Snake(80, 25);

pub export fn _start() callconv(.Naked) noreturn {
    main();
}

fn main() noreturn {
    @setAlignStack(16);
    snek_io.initTerm();
    while (true) {
        Snake.prepareArena();
        var default_dir: Direction = .Right;
        var snek = Snake.new();
        while (!snek.move(default_dir)) {
            const ns: usize = 0x5000000 - snek.length * 0x2000;
            var delay = .{ .tv_sec = 0, .tv_nsec = @intCast(isize, ns) };
            _ = linux.nanosleep(&delay, null);
            snek_io.get_dir(&default_dir);
        }
    }
}
