const std = @import("std");
const builtin = @import("builtin");

const zlog = @import("zlog");

// customize log prefix
fn logPrefix(allocator: *const std.mem.Allocator, log_level: []const u8) []const u8 {
    const current_time = zlog.timestampToDatetime(allocator.*, std.time.timestamp());
    const str: []u8 = std.fmt.allocPrint(allocator.*, "{s}: Some Extra Messages!, such as the time: {s}: ", .{ log_level, current_time }) catch {
        return undefined;
    };
    return str;
}

// the simplest log prefix, no extra messages...
// fn logPrefix(allocator: *const std.mem.Allocator, log_level: []const u8) []const u8 {
//     _ = log_level;
//     _ = allocator;
//     return ""; // no prefix
// }

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try zlog.initializeLogging(&allocator, .{ .path = .{ .relative = "log" }, .file_name = "log" }, .{ .severity = .info });
    try zlog.installLogPrefix(&logPrefix);

    defer zlog.Log.close();

    const timestamp: i64 = std.time.timestamp();
    const current_time: []const u8 = zlog.timestampToDatetime(allocator, timestamp);
    defer allocator.free(current_time);

    try zlog.Log.info("MAIN", "Hello World!", .{});
    try zlog.Log.info("MAIN", "Current Timestamp: {d}", .{timestamp});
    try zlog.Log.err("MAIN", "It is: {s}", .{current_time});

    try zlog.Log.info("MAIN", "multithreading!", .{});

    const ThreadArgs = struct {
        id: usize,
    };

    const threadFn = struct {
        fn run(args: ThreadArgs) !void {
            var i: usize = 0;
            while (i < 3) : (i += 1) {
                // sleep a bit to simulate work
                const jitter_ms: u64 = 500 + @as(u64, (args.id * 7 + i * 13) % 300);
                std.Thread.sleep(jitter_ms * std.time.ns_per_ms);
                const choice = (args.id + i) % 3;

                // randomly choose a log level
                switch (choice) {
                    0 => try zlog.Log.info("WORKER", "thread {d} message {d}", .{ args.id, i }),
                    1 => try zlog.Log.warn("WORKER", "thread {d} message {d}", .{ args.id, i }),
                    else => try zlog.Log.err("WORKER", "thread {d} message {d}", .{ args.id, i }),
                }
            }
        }
    }.run;

    var threads: [3]std.Thread = undefined;
    var idx: usize = 0;
    while (idx < threads.len) : (idx += 1) {
        threads[idx] = try std.Thread.spawn(.{}, threadFn, .{ThreadArgs{ .id = idx }});
    }

    for (threads) |t| {
        t.join();
    }

    try zlog.Log.info("MAIN", "done!", .{});
}
