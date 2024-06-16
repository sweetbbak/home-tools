const std = @import("std");
const ansi = @import("format.zig");

// var usage_fmt =
//     \\ Sort files by type and put them into organized directories
//     \\
//     \\ {s}
//     \\     filesorter [options]
//     \\
//     \\ OPTIONS
//     \\    -h, --help       show this help message
//     \\    -d, --directory  directory to sort
//     \\    -D, --dry-run    print changes to stdout instead of moving any files
//     \\
// ;

pub fn GetHelp() void {
    const usage_fmt =
        \\ Sort files by type and put them into organized directories
        \\
        \\ {s}
        \\     filesorter [options]
        \\
        \\ {s}
        \\    -h, --help       show this help message
        \\    -d, --directory  directory to sort
        \\    -D, --dry    print changes to stdout instead of moving any files
        \\
    ;

    std.debug.print(usage_fmt, .{ "\x1b[4mUSAGE\x1b[0m", "\x1b[4mOPTIONS\x1b[0m" });
}
