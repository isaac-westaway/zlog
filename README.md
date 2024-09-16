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
const zlog = b.dependency("zlog", .{
    .target = target,
    .optimize = optimize
}).module("zlog");

exe.root_module.addImport(zlog);
```

Usage
-----

You can get started by initializing the logging file:
```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try Logger.initializeLogging(@constCast(&allocator), .{ .absolute_path = "/home/isaacwestaway/Documents/zig/zlog/", .file_name = "log" }, .{ .severity = .info });
    defer Logger.Log.close();
}
```

And then log a message to the logfile:
```zig
const Log = Logger.Log;

const str: []const u8 = "world";
const timestamp: i64 = std.time.timestamp();

const current_time: []const u8 = Logger.timestampToDatetime(@constCast(&allocator).*, timestamp);
defer allocator.free(current_time);

try Log.info("MAIN", "Hello, {s}", .{str});
try Log.warn("MAIN", "Current Timestamp: {d}", .{timestamp});
try Log.err("MAIN", "Hello {s}, at {s}", .{ str, current_time });

// Will crash the program upon logging!
try Logger.Log.fatal("MAIN", "I am Crashing Now!");
```

Todo
----

- Add the ability for users to define a custom logging prefix, similar to glog, has been fleshed out in Logger.zig
```cpp
google::InstallPrefixFormatter(&MyPrefixFormatter);
```