const std = @import("std");
const builtin = @import("builtin");
const os = std.os;
const linux = os.linux;

const windows = os.windows;
const kernel32 = os.windows.kernel32;
const GetConsoleScreenBufferInfo = kernel32.GetConsoleScreenBufferInfo;
const GetStdHandle = kernel32.GetStdHandle;
const GetLastError = kernel32.GetLastError;

const Size = struct {
    x: u16,
    y: u16,
};

fn getWindowSizeLinux() !Size {
    var ws: linux.winsize = undefined;
    var result = linux.ioctl(std.os.STDOUT_FILENO, linux.T.IOCGWINSZ, @ptrToInt(&ws));
    while (true) {
        switch (linux.getErrno(result)) {
            .SUCCESS => {
                return Size{
                    .x = ws.ws_col,
                    .y = ws.ws_row,
                };
            },
            .BADF => unreachable,
            .FAULT => unreachable,
            .INVAL => unreachable,
            .NOTTY => unreachable,
            .INTR => continue, // Interrupted function call, try again
            else => |err| return os.unexpectedErrno(err),
        }
    }
}

fn getWindowSizeWindows() !Size {
    var handle_ptr = GetStdHandle(windows.STD_OUTPUT_HANDLE) orelse return error.nullHandle;
    if (handle_ptr == windows.INVALID_HANDLE_VALUE) {
        switch (GetLastError()) {
            .INVALID_WINDOW_HANDLE => unreachable,
            .INVALID_PARAMETER => unreachable,
            else => |err| return os.windows.unexpectedError(err),
        }
    }
    var console_info: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    const r = GetConsoleScreenBufferInfo(handle_ptr, &console_info);
    if (r == 0) {
        switch (GetLastError()) {
            .INVALID_WINDOW_HANDLE => unreachable,
            .INVALID_PARAMETER => unreachable,
            else => |err| return os.windows.unexpectedError(err),
        }
    }
    const x = console_info.srWindow.Right - console_info.srWindow.Left;
    const y = console_info.srWindow.Bottom - console_info.srWindow.Top;
    if (x < 0 or y < 0) {
        return error.negativeSize;
    }
    return Size{
        .x = @intCast(u16, x),
        .y = @intCast(u16, y),
    };
}

const getWindowSize = switch (builtin.os.tag) {
    .windows => getWindowSizeWindows,
    else => getWindowSizeLinux,
};

pub fn main() anyerror!void {
    const size = try getWindowSize();

    const stdout = std.io.getStdOut().writer();

    var i: i32 = 0;
    while (i < size.y) : (i += 1) {
        //try stdout.writeByteNTimes(' ', size.x);
        try stdout.writeAll("\n");
    }
}
