Overview
========

`zlog` is an application-level logging library that provides some APIs to write logging message to an output file.

My inspiration came from using Google's `glog` library, writing some cool applications with the ability to log actions easily.

So credits go to Google.

This code was also taken from my `zigwm` project, which *needed* logging to figure out what was going on.

> [!TIP]
> Like Glog, this library is also thread-safe

Getting Started
---------------

You can install the library by running
```bash
zig fetch --save git+https://github.com/isaac-westaway/zlog
```

Then add the dependency in your `build.zig` file
```zig
const zlog = b.dependency("zlog", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("zlog", zlog.module("zlog"));
```

Usage
-----

### Quickstart
You can get started by initializing the logging file:
```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    var allocator = gpa.allocator();

    try zlog.initializeLogging(&allocator, .{ .path = .{ .relative = "log" }, .file_name = "log" }, .{ .severity = .info });
    try zlog.installLogPrefix(&logPrefix);

    defer zlog.Log.close();

    try zlog.Log.info("MAIN", "Hello World!", .{});
}
```

And then log a message to the logfile:
```zig
...

try zlog.Log.info("MAIN", "Hello World!", .{});
try zlog.Log.info("MAIN", "Current Timestamp: {d}", .{timestamp});
try zlog.Log.err("MAIN", "It is: {s}", .{current_time});

// Will crash the program upon logging!
try zlog.Log.fatal("MAIN", "I am Crashing Now!", .{});
```
Output:
```
INFO-MAIN-2024/9/17-0:31:57-T250650: Hello World!
WARN-MAIN-2024/9/17-0:31:57-T250650: Current Timestamp: 1726533117
ERROR-MAIN-2024/9/17-0:31:57-T250650: It is: 2024/9/17-0:31:57
FATAL-MAIN-2024/9/17-0:31:57-T250650: I am Crashing Now!
```

### Using a custom prefix
```zig
// The callback must have these two arguments
fn logPrefix(allocator: *const std.mem.Allocator, log_level: []const u8) []const u8 {
    const current_time = zlog.timestampToDatetime(allocator.*, std.time.timestamp());
    const str: []u8 = std.fmt.allocPrint(allocator.*, "{s}: Some Extra Messages!, such as the time: {s}: ", .{ log_level, current_time }) catch {
        return undefined;
    };
    return str;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try zlog.initializeLogging(&allocator, .{ .path = .{ .relative = "log" }, .file_name = "log" }, .{ .severity = .info });
    try zlog.installLogPrefix(&logPrefix);

    defer zlog.Log.close();

    try zlog.Log.info("MAIN", "Hello World!", .{});
}
```

Output:
```
INFO-MAIN: Some Extra Messages!, such as the time: 2024/9/17-0:32:51: Hello World!
```

#
See `example/src/main.zig` for a the full example.