const std = @import("std");
const io = std.io;
const debug = std.debug;
const Allocator = std.mem.Allocator;
const Usage = @import("usage.zig");

const clap = @import("clap");

var DRYRUN: bool = false;

pub const Filetype = enum {
    IMAGE,
    VIDEO,
    ARCHIVE,
    EXE,
    PROGRAMMING,
    PKG,
    PDF,
    READING,
    DOCUMENT,
    APK,
    UNKNOWN,

    pub const string_map = std.ComptimeStringMap(Filetype, .{
        .{ ".gif", .IMAGE },
        .{ ".qoi", .IMAGE },
        .{ ".png", .IMAGE },
        .{ ".jpg", .IMAGE },
        .{ ".jpeg", .IMAGE },
        .{ ".webp", .IMAGE },
        .{ ".svg", .IMAGE },
        .{ ".tiff", .IMAGE },
        .{ ".tif", .IMAGE },

        .{ ".webm", .VIDEO },
        .{ ".mp4", .VIDEO },
        .{ ".avi", .VIDEO },
        .{ ".flv", .VIDEO },
        .{ ".mkv", .VIDEO },
        .{ ".mov", .VIDEO },
        .{ ".mpeg", .VIDEO },
        .{ ".mpg", .VIDEO },
        .{ ".mpv", .VIDEO },
        .{ ".svi", .VIDEO },
        .{ ".wmv", .VIDEO },
        .{ ".m4v", .VIDEO },
        .{ ".fly", .VIDEO },
        .{ ".fli", .VIDEO },
        .{ ".nsv", .VIDEO },
        .{ ".ogm", .VIDEO },
        .{ ".ogv", .VIDEO },
        .{ ".srt", .VIDEO },
        .{ ".yuv", .VIDEO },

        .{ ".zip", .ARCHIVE },
        .{ ".tar", .ARCHIVE },
        .{ ".gz", .ARCHIVE },
        .{ ".xz", .ARCHIVE },
        .{ ".tar.gz", .ARCHIVE },
        .{ ".tar.xz", .ARCHIVE },
        .{ ".7z", .ARCHIVE },
        .{ ".7zip", .ARCHIVE },
        .{ ".rar", .ARCHIVE },
        .{ ".bz2", .ARCHIVE },
        .{ ".iso", .ARCHIVE },
        .{ ".cab", .ARCHIVE },
        .{ ".arj", .ARCHIVE },
        .{ ".ace", .ARCHIVE },
        .{ ".z", .ARCHIVE },
        .{ ".lha", .ARCHIVE },
        .{ ".lhz", .ARCHIVE },

        .{ ".exe", .EXE },
        .{ ".dmg", .EXE },
        .{ ".appimage", .EXE },
        .{ ".AppImage", .EXE },
        .{ ".apk", .APK },

        .{ ".pdf", .PDF },
        .{ ".epub", .READING },
        .{ ".lit", .READING },
        .{ ".mobi", .READING },
        .{ ".azw", .READING },
        .{ ".cbr", .READING },
        .{ ".cbz", .READING },

        .{ ".txt", .DOCUMENT },
        .{ ".doc", .DOCUMENT },
        .{ ".docx", .DOCUMENT },
        .{ ".rtf", .DOCUMENT },
        .{ ".md", .DOCUMENT },
        .{ ".markdown", .DOCUMENT },
        .{ ".html", .DOCUMENT },
        .{ ".xtml", .DOCUMENT },
        .{ ".djvu", .DOCUMENT },

        .{ ".c", .PROGRAMMING },
        .{ ".lua", .PROGRAMMING },
        .{ ".py", .PROGRAMMING },
        .{ ".zig", .PROGRAMMING },
        .{ ".zon", .PROGRAMMING },
        .{ ".go", .PROGRAMMING },
        .{ ".sh", .PROGRAMMING },
        .{ ".zsh", .PROGRAMMING },
        .{ ".bash", .PROGRAMMING },
        .{ ".fish", .PROGRAMMING },
    });
};

pub fn mime(comptime ext: []const u8) Filetype {
    return Filetype.string_map.get(ext) orelse Filetype.UNKNOWN;
}

fn openDir(dirpath: []const u8) anyerror!std.fs.Dir {
    var path_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const realpath = try std.fs.realpath(dirpath, &path_buf);

    const opts = std.fs.Dir.OpenDirOptions{ .iterate = true, .no_follow = false };
    const dir = try std.fs.openDirAbsolute(realpath, opts);
    return dir;
}

fn openFile(file: []const []u8) !void {
    var path_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const realpath = try std.fs.realpath(file, &path_buf);
    const img: std.fs.File = try std.fs.openFileAbsolute(realpath, .{ .mode = .read_only });
    return img;
}

fn sortDir(dir: []const u8) !void {
    var tdir = try openDir(dir);
    // var mdir = tdir.iterate();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);

    const stdout = bw.writer();
    _ = try stdout.print(
        "#!/usr/bin/env bash\n#auto-generated script to clean up a directory\n\n",
        .{},
    );

    if (DRYRUN) {
        _ = try stdout.print(
            "DRYRUN=true\n",
            .{},
        );
    } else {
        _ = try stdout.print(
            "DRYRUN=false\n",
            .{},
        );
    }

    const movefunc =
        \\
        \\function _mv() {
        \\    fpath="$(printf "%s" "$1")"
        \\    if [ -f "$fpath" ]; then
        \\        if [[ "$DRYRUN" = true ]]; then
        \\            printf "mv [\x1b[32m%s\x1b[0m] [\x1b[36m%s\x1b[0m]\n" "$fpath" "$2"
        \\        else
        \\            mkdir -p "$2"
        \\            mv -i "$fpath" "$2"
        \\            exitcode=$?
        \\
        \\            if [ "$exitcode" -ne 0 ]; then
        \\                printf "\x1b[31m\x1b[4mfailed:\x1b[0m mv [\x1b[32m%s\x1b[0m] [\x1b[36m%s\x1b[0m]\n" "$fpath" "$2"
        \\            else
        \\                printf "mv [\x1b[32m%s\x1b[0m] [\x1b[36m%s\x1b[0m]\n" "$fpath" "$2"
        \\            fi
        \\        fi
        \\    else
        \\        printf "path \x1b[33m[%s]\x1b[0m is mangled\n" "$fpath"
        \\    fi
        \\}
    ;
    _ = try stdout.print(
        "{s}\n\n",
        .{movefunc},
    );

    try bw.flush();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var walker = try tdir.walk(alloc);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        var component_it = try std.fs.path.NativeComponentIterator.init(entry.path);
        var depth: usize = 0;
        while (component_it.next()) |_| {
            depth += 1;
        }

        if (depth > 1) {
            continue;
        }

        if (entry.kind == std.fs.Dir.Entry.Kind.directory) {
            continue;
        }

        const extConst = std.fs.path.extension(entry.path);
        const ext = alloc.alloc(u8, extConst.len) catch unreachable;
        defer alloc.free(ext);

        _ = std.ascii.lowerString(ext, extConst);

        if (!Filetype.string_map.has(ext)) {
            continue;
        }

        const ftenum = Filetype.string_map.get(ext);

        const taglower = @tagName(ftenum.?);
        const dest = alloc.alloc(u8, taglower.len) catch unreachable;
        defer alloc.free(dest);

        _ = std.ascii.lowerString(dest, taglower);

        _ = try stdout.print("_mv '{s}/{s}' {s}/{s}\n", .{ dir, entry.path, dir, dest });
        try bw.flush();

        // std.debug.print("depth: {} | {s} | type {any}\n", .{ depth, entry.path, @tagName(ftenum) });
        // std.debug.print("depth: {} | {s} \n", .{ depth, entry.path });
    }
}

fn printHelp() void {
    Usage.GetHelp();
}

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    try bw.flush();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-D, --dry              print changes to stdout
        \\-d, --directory <str>  a directory to parse and sort
        \\<str>...
        \\
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        // Report useful error and exit
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        printHelp();
        std.posix.exit(0);
    }

    if (res.args.dry != 0) {
        DRYRUN = true;
    }

    if (res.args.directory) |dir| {
        try sortDir(dir);
    }

    for (res.positionals) |pos| {
        debug.print("{s}\n", .{pos});
    }
}

test {
    const jpg = mime("jpg");
    try std.testing.expectEqual(jpg, Filetype.IMAGE);

    const pdf = mime("pdf");
    try std.testing.expectEqual(pdf, Filetype.PDF);

    const prog = mime("c");
    try std.testing.expectEqual(prog, Filetype.PROGRAMMING);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
