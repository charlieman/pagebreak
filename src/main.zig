const std = @import("std");
const builtin = @import("builtin");
const os = std.os;
const linux = os.linux;

const windows = os.windows;
const kernel32 = os.windows.kernel32;
const GetConsoleScreenBufferInfo = kernel32.GetConsoleScreenBufferInfo;
const GetStdHandle = kernel32.GetStdHandle;
const GetLastError = kernel32.GetLastError;

fn getWindowSizeLinux(rows: *i32, cols: *i32) !void {
    var ws: linux.winsize = undefined;
    var result = linux.ioctl(std.os.STDOUT_FILENO, linux.T.IOCGWINSZ, @ptrToInt(&ws));
    while (true) {
        switch (linux.getErrno(result)) {
            .SUCCESS => {
                cols.* = ws.ws_col;
                rows.* = ws.ws_row;
                return;
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

fn getWindowSizeWindows(rows: *i32, cols: *i32) !void {
    var csbi: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    var maybe_handle = GetStdHandle(windows.STD_OUTPUT_HANDLE);
    if (maybe_handle) |handle| {
        if (handle == windows.INVALID_HANDLE_VALUE) {
            switch (GetLastError()) {
                .INVALID_WINDOW_HANDLE => unreachable,
                .INVALID_PARAMETER => unreachable,
                else => |err| return os.windows.unexpectedError(err),
            }
        }
        var r = GetConsoleScreenBufferInfo(handle, &csbi);
        if (r == 0) {
            switch (GetLastError()) {
                .INVALID_WINDOW_HANDLE => unreachable,
                .INVALID_PARAMETER => unreachable,
                else => |err| return os.windows.unexpectedError(err),
            }
        }
        cols.* = csbi.srWindow.Right - csbi.srWindow.Left;
        rows.* = csbi.srWindow.Bottom - csbi.srWindow.Top;
    } else {
        return error.nullHandle;
    }
}

const getWindowSize = switch (builtin.os.tag) {
    .windows => getWindowSizeWindows,
    else => getWindowSizeLinux,
};

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
