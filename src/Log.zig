const std = @import("std");
const time = @import("time.zig");

pub const Severity = enum {
    debug,
    // trace (verbose)
    info,
    warn,
    err,
    fatal,
};

pub const OptionalSeverity = union(enum) {
    none,
    severity: Severity,
};

pub const Logger = struct {
    allocator: *const std.mem.Allocator,

    // Zig callbacks

    installed_prefix: bool,
    /// Callback function which returns a string that will prefix the log message
    log_prefix: *const fn (allocator: *const std.mem.Allocator, log_level: []const u8) []const u8,

    /// The file to write to
    log_file: std.fs.File,

    /// The verbosity of the logger
    log_level: Severity,

    // Could this mutex be replaced with std.fs.File.lock()?
    /// Mutex to control multithreaded access to the log file
    access_mutex: std.Thread.Mutex,

    pub fn close(self: *Logger) void {
        self.log_file.close();
    }
    pub fn info(self: *Logger, namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.info)) return;

        const log_level: []const u8 = "INFO";

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        var arena_allocator = std.heap.ArenaAllocator.init(self.allocator.*);
        var allocator = arena_allocator.allocator();
        defer arena_allocator.deinit();

        const current_time: i64 = std.time.timestamp();
        const formatted_time: []const u8 = time.timestampToDatetime(allocator, current_time);

        const prefix: []const u8 = "INFO-{s}-{s}-T{d}:";
        var zipped_prefix: []const u8 = try std.fmt.allocPrint(allocator, prefix, .{ namespace, formatted_time, std.Thread.getCurrentId() });

        const zipped_message: []const u8 = try std.fmt.allocPrint(allocator, message, args);

        if (self.installed_prefix) {
            const extra_prefix = self.log_prefix(&allocator, log_level);
            zipped_prefix = try std.fmt.allocPrint(allocator, "{s}{s}", .{ extra_prefix, zipped_prefix });
        }

        const to_write = std.fmt.allocPrint(allocator, "{s} {s}\n", .{ zipped_prefix, zipped_message }) catch |the_error| {
            return the_error;
        };

        _ = try self.log_file.write(to_write);
    }

    pub fn warn(self: *Logger, namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.warn)) return;

        const log_level: []const u8 = "WARN";

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        var arena_allocator = std.heap.ArenaAllocator.init(self.allocator.*);
        var allocator = arena_allocator.allocator();
        defer arena_allocator.deinit();

        const current_time = std.time.timestamp();
        const formatted_time = time.timestampToDatetime(allocator, current_time);

        const zipped_message: []const u8 = try std.fmt.allocPrint(allocator, message, args);

        const prefix: []const u8 = "WARN-{s}-{s}-T{d}:";
        var zipped_prefix: []const u8 = try std.fmt.allocPrint(allocator, prefix, .{ namespace, formatted_time, std.Thread.getCurrentId() });

        if (self.installed_prefix) {
            const extra_prefix = self.log_prefix(&allocator, log_level);
            zipped_prefix = try std.fmt.allocPrint(allocator, "{s}{s}", .{ extra_prefix, zipped_prefix });
        }

        const to_write = std.fmt.allocPrint(allocator, "{s} {s}\n", .{ zipped_prefix, zipped_message }) catch |the_error| {
            return the_error;
        };

        _ = try self.log_file.write(to_write);
    }

    pub fn err(self: *Logger, namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.err)) return;

        const log_level: []const u8 = "ERROR";

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        var arena_allocator = std.heap.ArenaAllocator.init(self.allocator.*);
        var allocator = arena_allocator.allocator();
        defer arena_allocator.deinit();

        const current_time = std.time.timestamp();
        const formatted_time = time.timestampToDatetime(allocator, current_time);

        const zipped_message: []const u8 = try std.fmt.allocPrint(allocator, message, args);

        const prefix: []const u8 = "ERROR-{s}-{s}-T{d}:";
        var zipped_prefix: []const u8 = try std.fmt.allocPrint(allocator, prefix, .{ namespace, formatted_time, std.Thread.getCurrentId() });

        if (self.installed_prefix) {
            const extra_prefix = self.log_prefix(&allocator, log_level);
            zipped_prefix = try std.fmt.allocPrint(allocator, "{s}{s}", .{ extra_prefix, zipped_prefix });
        }

        const to_write = std.fmt.allocPrint(allocator, "{s} {s}\n", .{ zipped_prefix, zipped_message }) catch |the_error| {
            return the_error;
        };

        _ = try self.log_file.write(to_write);
    }

    /// Will purposely crash the program if called
    pub fn fatal(self: *Logger, namespace: []const u8, comptime message: []const u8, args: anytype) !void {
        if (@intFromEnum(self.log_level) > @intFromEnum(Severity.fatal)) return;

        self.access_mutex.lock();
        defer self.access_mutex.unlock();

        const log_level: []const u8 = "FATAL";

        var arena_allocator = std.heap.ArenaAllocator.init(self.allocator.*);
        var allocator = arena_allocator.allocator();
        defer arena_allocator.deinit();

        const current_time = std.time.timestamp();
        const formatted_time = time.timestampToDatetime(self.allocator.*, current_time);

        const prefix: []const u8 = "FATAL-{s}-{s}-T{d}:";
        var zipped_prefix: []const u8 = try std.fmt.allocPrint(allocator, prefix, .{ namespace, formatted_time, std.Thread.getCurrentId() });

        if (self.installed_prefix) {
            const extra_prefix = self.log_prefix(&allocator, log_level);
            zipped_prefix = try std.fmt.allocPrint(allocator, "{s}{s}", .{ extra_prefix, zipped_prefix });
        }

        const zipped_message: []const u8 = try std.fmt.allocPrint(allocator, message, args);

        const to_write = std.fmt.allocPrint(allocator, "{s} {s}\n", .{ zipped_prefix, zipped_message }) catch |the_error| {
            return the_error;
        };

        _ = try self.log_file.write(to_write);

        std.posix.exit(1);
    }
};

pub var Log: Logger = Logger{
    .allocator = undefined,
    .installed_prefix = false,
    .log_prefix = undefined,
    .log_file = undefined,
    .log_level = undefined,
    .access_mutex = std.Thread.Mutex{},
};

// discriminate between absolute and relative paths
pub const LogfilePath = union(enum) {
    absolute: []const u8,
    relative: []const u8,
};

pub const LogfileOptions = struct {
    path: LogfilePath,
    file_name: []const u8,
};

/// Call once in the main function
/// Log Level defines the verbosity of the logger, for example, a log level of warning will only write log levels of warning, error and fatal to the logfile
pub fn initializeLogging(allocator: *const std.mem.Allocator, logfile_options: LogfileOptions, logfile_strip: OptionalSeverity) !void {
    const timestamp: i64 = std.time.timestamp();
    const file_name: []const u8 = try std.fmt.allocPrint(allocator.*, "{s}-{d}.log", .{ logfile_options.file_name, timestamp });
    defer allocator.free(file_name);

    const base_path: []const u8 = switch (logfile_options.path) {
        .absolute => |base| base,
        .relative => |base| if (base.len == 0) "." else base,
    };
    const path_is_absolute = switch (logfile_options.path) {
        .absolute => true,
        .relative => std.fs.path.isAbsolute(base_path),
    };

    if (path_is_absolute) {
        if (!std.mem.eql(u8, base_path, ".")) {
            std.fs.makeDirAbsolute(base_path) catch {};
        }
    } else {
        if (!std.mem.eql(u8, base_path, ".")) {
            std.fs.cwd().makePath(base_path) catch {};
        }
    }

    const file_path: []const u8 = try std.fs.path.join(allocator.*, &.{ base_path, file_name });
    defer allocator.free(file_path);

    Log.allocator = allocator;
    Log.log_file = if (path_is_absolute)
        std.fs.createFileAbsolute(file_path, .{ .read = true }) catch {
            return undefined;
        }
    else
        std.fs.cwd().createFile(file_path, .{ .read = true }) catch {
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

    Log.access_mutex.lock();
    defer Log.access_mutex.unlock();
}

pub fn installLogPrefix(log_prefix: *const fn (allocator: *const std.mem.Allocator, log_level: []const u8) []const u8) !void {
    Log.installed_prefix = true;
    Log.log_prefix = log_prefix;
}

test "LogBasicTest" {
    var gpa_allocator = std.testing.allocator_instance;
    const allocator = gpa_allocator.allocator();

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    Log.allocator = &allocator;
    Log.installed_prefix = false;
    Log.log_level = Severity.debug;
    Log.access_mutex = std.Thread.Mutex{};
    Log.log_file = try tmp.dir.createFile("test.log", .{ .read = true });
    defer Log.log_file.close();

    try Log.info("a", "hello {s}", .{"world"});
    try Log.warn("b", "warn {d}", .{1});
    try Log.err("c", "uh oh", .{});
    // try Log.fatal("d", "this is fatal", .{});

    try Log.log_file.seekTo(0);
    const contents = try Log.log_file.readToEndAlloc(allocator, 4096);
    defer allocator.free(contents);

    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "INFO-a-"));
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "WARN-b-"));
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "ERROR-c-"));
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "hello world"));
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "warn 1"));
    try std.testing.expect(std.mem.containsAtLeast(u8, contents, 1, "uh oh"));
}
