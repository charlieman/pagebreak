const std = @import("std");
const builtin = std.builtin;
const os = std.os;
const linux = os.linux;

fn getWindowSize(rows: *i32, cols: *i32) !void {
    var ws: linux.winsize = undefined;
    var errno = linux.ioctl(std.os.STDOUT_FILENO, linux.TIOCGWINSZ, @ptrToInt(&ws));
    while (true) {
        switch (errno) {
            0 => {
                cols.* = ws.ws_col;
                rows.* = ws.ws_row;
                return;
            },
            os.EBADF => unreachable,
            os.EFAULT => unreachable,
            os.EINVAL => unreachable,
            os.ENOTTY => unreachable,
            os.EINTR => continue, // Interrupted function call, try again
            else => |err| return os.unexpectedErrno(err),
        }
    }
}

pub fn main() anyerror!void {
    var rows: i32 = undefined;
    var cols: i32 = undefined;
    try getWindowSize(&rows, &cols);

    const stdout = std.io.getStdOut().writer();

    var i: i32 = 0;
    while (i < rows) : (i += 1) {
        try stdout.writeAll("\n");
    }
}
