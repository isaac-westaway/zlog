const std = @import("std");

const Logger = @import("Logger.zig");

// Log Level Argument
// Should Namespace be considered a prefix?
// TODO:: Could this be made more generic so the user can define their own arguments without having to change the Logger.zig?
/// Example function which defines the string that should prefix the log messages
fn testLogPrefix(allocator: *std.mem.Allocator, log_level: []const u8) []const u8 {
    const current_time = Logger.timestampToDatetime(allocator.*, std.time.timestamp());
    const str: []u8 = std.fmt.allocPrint(allocator.*, "{s}: Some Extra Messages!, such as the time: {s}: ", .{ log_level, current_time }) catch {
        return undefined;
    };
    return str;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try Logger.initializeLogging(@constCast(&allocator), .{ .absolute_path = "/home/isaacwestaway/Documents/zig/zlog/", .file_name = "log" }, .{ .severity = .info });
    try Logger.installLogPrefix(@constCast(&allocator), &testLogPrefix);
    defer Logger.Log.close();

    var Log = Logger.Log;

    const str: []const u8 = "world";
    const timestamp: i64 = std.time.timestamp();

    const current_time: []const u8 = Logger.timestampToDatetime(allocator, timestamp);
    defer allocator.free(current_time);

    try Log.info("MAIN", "Hello, {s}", .{str});
    try Log.warn("MAIN", "Current Timestamp: {d}", .{timestamp});
    try Log.err("MAIN", "Hello {s}, at {s}", .{ str, current_time });

    // Will crash the program upon logging!
    // try Logger.Log.fatal("MAIN", "I am Crashing Now!", .{});
}
