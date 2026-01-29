const LogModule = @import("Log.zig");
const time = @import("time.zig");

pub const Logger = LogModule.Logger;
pub const Severity = LogModule.Severity;
pub const OptionalSeverity = LogModule.OptionalSeverity;
pub const LogfilePath = LogModule.LogfilePath;
pub const LogfileOptions = LogModule.LogfileOptions;
pub const initializeLogging = LogModule.initializeLogging;
pub const installLogPrefix = LogModule.installLogPrefix;
pub const timestampToDatetime = time.timestampToDatetime;

pub const Log = struct {
    pub fn close() void {
        LogModule.Log.close();
    }

    pub fn info(namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        return LogModule.Log.info(namespace, message, args);
    }

    pub fn warn(namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        return LogModule.Log.warn(namespace, message, args);
    }

    pub fn err(namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        return LogModule.Log.err(namespace, message, args);
    }

    pub fn fatal(namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        return LogModule.Log.fatal(namespace, message, args);
    }
};
