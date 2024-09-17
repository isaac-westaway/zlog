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
const std = @import("std");
const zlog = @import("zlog");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try zlog.initializeLogging(@constCast(&allocator), 
        .{ .absolute_path = "/home/isaacwestaway/Documents/zig/zlog/", .file_name = "log" },
        .{ .severity = .info }
    );
    defer zlog.Log.close();
}
```

And then log a message to the logfile:
```zig
...

var Logger = zlog.log;

const str: []const u8 = "world";
const timestamp: i64 = std.time.timestamp();

const current_time: []const u8 = Logger.timestampToDatetime(allocator, timestamp);
defer allocator.free(current_time);

try Logger.info("MAIN", "Hello, {s}", .{ str });
try Logger.warn("MAIN", "Current Timestamp: {d}", .{ timestamp} );
try Logger.err("MAIN", "Hello {s}, at {s}", .{ str, current_time });

// Will crash the program upon logging!
try Logger.fatal("MAIN", "I am Crashing Now!", .{});
```
Output:
```
INFO-MAIN-2024/9/17-0:31:57-T250650:Hello, world
WARN-MAIN-2024/9/17-0:31:57-T250650:Current Timestamp: 1726533117
ERROR-MAIN-2024/9/17-0:31:57-T250650:Hello world, at 2024/9/17-0:31:57
FATAL-MAIN-2024/9/17-0:31:57-T250650:I am Crashing Now!
```

### Using a custom prefix
```zig

// The callback must have these two arguments
fn testLogPrefix(allocator: *std.mem.Allocator, log_level: []const u8) []const u8 {
    const current_time = Logger.timestampToDatetime(allocator.*, std.time.timestamp());
    const str: []u8 = std.fmt.allocPrint(allocator.*, "{s}: Some Extra Messages!, such as the time: {s}: ", 
    .{ log_level, current_time }) catch {
        return undefined;
    };
    return str;
}

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try zlog.initializeLogging(@constCast(&allocator), 
        .{ .absolute_path = "/home/isaacwestaway/Documents/zig/zlog/", .file_name = "log" }, 
        .{ .severity = .info }
    );
    try zlog.installLogPrefix(@constCast(&allocator), &testLogPrefix);
    defer zlog.Log.close();

    var Logger = zlog.Log;

    const str: []const u8 = "world";
    const timestamp: i64 = std.time.timestamp();

    const current_time: []const u8 = Logger.timestampToDatetime(allocator, timestamp);
    defer allocator.free(current_time);

    try Logger.info("MAIN", "Hello, {s}", .{str});
    try Logger.warn("MAIN", "Current Timestamp: {d}", .{timestamp});
    try Logger.err("MAIN", "Hello {s}, at {s}", .{ str, current_time });

    // Will crash the program upon logging!
    try Logger.fatal("MAIN", "I am Crashing Now!", .{});
}
```

Output:
```
INFO: Some Extra Messages!, such as the time: 2024/9/17-0:32:51: Hello, world
WARN: Some Extra Messages!, such as the time: 2024/9/17-0:32:51: Current Timestamp: 1726533171
ERROR: Some Extra Messages!, such as the time: 2024/9/17-0:32:51: Hello world, at 2024/9/17-0:32:51
FATAL: Some Extra Messages!, such as the time: 2024/9/17-0:32:51: I am Crashing Now!
```

Todo
----

- Some better test cases
