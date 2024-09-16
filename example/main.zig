const std = @import("std");

const Logger = @import("Logger.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try Logger.initializeLogging(@constCast(&allocator), .{ .absolute_path = "/home/isaacwestaway/Documents/zig/zlog/", .file_name = "log" }, .{ .severity = .info });
    defer Logger.Log.close();

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
}
