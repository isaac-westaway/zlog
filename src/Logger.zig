//! Logging module
const std = @import("std");

const Severity = enum {
    debug,
    // trace (verbose)
    info,
    warn,
    err,
    fatal,
};

const OptionalSeverity = union(enum) {
    none,
    severity: Severity,
};

/// Checks if the given year was a leap year
fn isLeapYear(year: u64) bool {
    return if ((@mod(year, 4) == 0 and @mod(year, 100) != 0) or @mod(year, 400) == 0) true else false;
}

/// Converts a unix epoch timestamp to a datetime in the form YYYY/MM/DD-HH:MM:SS
pub fn timestampToDatetime(allocator: std.mem.Allocator, timestamp: i64) []const u8 {
    var current_year_unix: u32 = 1970;

    const leap_timestamp: f80 = @as(f80, @floatFromInt(timestamp));

    const days_in_months: [12]i32 = [_]i32{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

    var extra_days: f80 = 0;

    // number of seconds that has passed from jan 1 1970
    var seconds_to_days: f80 = leap_timestamp / 86400;
    const extra_time: f80 = @mod(leap_timestamp, 86400);
    var flag: u8 = 0;

    while (true) {
        if (isLeapYear(current_year_unix)) {
            if (seconds_to_days < 366) {
                break;
            }
            seconds_to_days -= 366;
        } else {
            if (seconds_to_days < 365) {
                break;
            }
            seconds_to_days -= 365;
        }
        current_year_unix += 1;
    }

    extra_days = seconds_to_days + 1;

    if (isLeapYear(current_year_unix)) {
        flag = 1;
    }

    var date: f80 = 0;
    var month: u8 = 0;
    var index: u8 = 0;

    if (flag == 1) {
        while (true) {
            if (index == 1) {
                if (extra_days - 29 < 0) {
                    break;
                }

                month += 1;
                extra_days -= 29;
            } else {
                if (extra_days - @as(f80, @floatFromInt(days_in_months[index])) < 0) {
                    break;
                }

                month += 1;
                extra_days -= @as(f80, @floatFromInt(days_in_months[index]));
            }

            index += 1;
        }
    } else {
        while (true) {
            if (extra_days - @as(f80, @floatFromInt(days_in_months[index])) < 0) {
                break;
            }

            month += 1;
            extra_days -= @as(f80, @floatFromInt(days_in_months[index]));
            index += 1;
        }
    }

    if (extra_days > 0) {
        month += 1;
        date = extra_days;
    } else {
        if (month == 2 and flag == 1) {
            date = 29;
        } else {
            date = @as(f80, @floatFromInt(days_in_months[month - 1]));
        }
    }

    // TODO: adjust for AEST time
    const hours = extra_time / 3600;
    const minutes = @divExact(@mod(extra_time, 3600), 60);
    const seconds = @mod(@mod(extra_time, 3600), 60);

    // YYYY/MM/DD-HH:MM:SS
    // In UTC time, because the current computer system is in UTC time, adjust for AEST
    const formatted_time: []u8 = std.fmt.allocPrint(allocator, "{d}/{d}/{d}-{d}:{d}:{d}", .{ current_year_unix, month, @floor(date), @floor(hours), minutes, seconds }) catch {
        // TODO: handle errors
        return undefined;
    };

    return formatted_time;
}

const Logger = struct {
    allocator: std.mem.Allocator,

    // Zig callbacks
    // log_format: []const u8,
    // log_args_format: type,
    log_file: std.fs.File,
    log_level: Severity,

    // Could this mutex be replaced with std.fs.File.lock()?
    /// Mutex to control multithreaded access to the log file
    access_mutex: std.Thread.Mutex,

    pub fn close(self: *Logger) void {
        self.log_file.close();
    }
    // TODO: add struct arguments
    pub fn info(self: *Logger, namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.info)) return;

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        var arena_allocator = std.heap.ArenaAllocator.init(self.allocator);
        const allocator = arena_allocator.allocator();
        defer arena_allocator.deinit();

        const current_time: i64 = std.time.timestamp();
        const formatted_time: []const u8 = timestampToDatetime(allocator, current_time);

        const zipped_message: []const u8 = try std.fmt.allocPrint(allocator, message, args);

        // Custom callback prefix shall be defined here
        // If the custom prefix callback is null then we should resort to this, otherwise, the custom prefix will return a []const u8, and this "string"
        // will be assigned to zipped_prefix
        const prefix: []const u8 = "INFO-{s}-{s}-T{d}:";
        const zipped_prefix: []const u8 = try std.fmt.allocPrint(allocator, prefix, .{ namespace, formatted_time, std.Thread.getCurrentId() });

        const to_write = std.fmt.allocPrint(allocator, "{s} {s}\n", .{ zipped_prefix, zipped_message }) catch |the_error| {
            return the_error;
        };

        _ = try self.log_file.write(to_write);
    }

    pub fn warn(self: *Logger, namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.warn)) return;

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        var arena_allocator = std.heap.ArenaAllocator.init(self.allocator);
        const allocator = arena_allocator.allocator();
        defer arena_allocator.deinit();

        const current_time = std.time.timestamp();
        const formatted_time = timestampToDatetime(allocator, current_time);

        const zipped_message: []const u8 = try std.fmt.allocPrint(allocator, message, args);

        const prefix: []const u8 = "WARN-{s}-{s}-T{d}:";
        const zipped_prefix: []const u8 = try std.fmt.allocPrint(allocator, prefix, .{ namespace, formatted_time, std.Thread.getCurrentId() });

        const to_write = std.fmt.allocPrint(allocator, "{s} {s}\n", .{ zipped_prefix, zipped_message }) catch |the_error| {
            return the_error;
        };

        _ = try self.log_file.write(to_write);
    }

    pub fn err(self: *Logger, namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.err)) return;

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        var arena_allocator = std.heap.ArenaAllocator.init(self.allocator);
        const allocator = arena_allocator.allocator();
        defer arena_allocator.deinit();

        const current_time = std.time.timestamp();
        const formatted_time = timestampToDatetime(allocator, current_time);

        const zipped_message: []const u8 = try std.fmt.allocPrint(allocator, message, args);

        const prefix: []const u8 = "ERROR-{s}-{s}-T{d}:";
        const zipped_prefix: []const u8 = try std.fmt.allocPrint(allocator, prefix, .{ namespace, formatted_time, std.Thread.getCurrentId() });

        const to_write = std.fmt.allocPrint(allocator, "{s} {s}\n", .{ zipped_prefix, zipped_message }) catch |the_error| {
            return the_error;
        };

        _ = try self.log_file.write(to_write);
    }

    /// Will purposely crash the program if called
    pub fn fatal(self: *Logger, namespace: []const u8, message: []const u8) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.fatal)) return;

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        const current_time = std.time.timestamp();
        const formatted_time = self.timestampToDatetime(current_time);

        const combined = std.fmt.allocPrint(self.allocator, "FATAL-{s}-{s}: {s}\n", .{ namespace, formatted_time, message }) catch {
            return;
        };

        _ = try self.log_file.write(combined);

        std.posix.exit(1);
    }
};

pub var Log: Logger = Logger{
    .allocator = undefined,
    // .log_format = undefined,
    // .log_args_format = undefined,
    .log_file = undefined,
    .log_level = undefined,
    .access_mutex = std.Thread.Mutex{},
};

const LogfileOptions = struct {
    absolute_path: []const u8,
    file_name: []const u8,
};

/// Call once in the main function
/// Log Level defines the verbosity of the logger, for example, a log level of warning will only write log levels of warning, error and fatal to the logfile
pub fn initializeLogging(allocator: *std.mem.Allocator, logfile_options: LogfileOptions, logfile_strip: OptionalSeverity) !void {
    const timestamp: i64 = std.time.timestamp();
    const file: []const u8 = try std.fmt.allocPrint(allocator.*, "{s}/{s}-{d}.log", .{ logfile_options.absolute_path, logfile_options.file_name, timestamp });
    defer allocator.free(file);

    Log.allocator = allocator.*;
    Log.log_file = std.fs.createFileAbsolute(file, .{ .read = true }) catch {
        return undefined;
    };

    if (@TypeOf(Log.log_file) != std.fs.File) {
        std.log.err("Unable to create logfile", .{});

        std.posix.exit(1);
    }

    Log.log_level = switch (logfile_strip) {
        .severity => |severity| severity,
        .none => Severity.debug,
    };

    // The log format is how the prefixes will be generated,similar to the custom prefix formatter in glog
    // currently does nothing
    // Log.log_format = log_format;
    // Log.log_args_format = args;
    // This should be done in another function using a callback, setting the callback function

    Log.access_mutex.lock();
    defer Log.access_mutex.unlock();
}

test "LogTimestampTest" {
    var gpa_allocator = std.testing.allocator_instance;
    const allocator = gpa_allocator.allocator();

    // all shall be tested in UTC in 24 Hour Time
    // with the format YYYY/M,M/D,D-H,H:MM:SS
    const timestamp_1: u32 = 261325361;
    const datetime_1: []const u8 = timestampToDatetime(allocator, timestamp_1);
    defer allocator.free(datetime_1);

    try std.testing.expect(std.mem.eql(u8, datetime_1, "1978/4/13-14:22:41"));

    // create some custom timestamps, paste it into a unix epoch converter and check if the two strings match
    // contribute one every time u modify this file to make sure it works well
}

test "LogOutputTest" {}
