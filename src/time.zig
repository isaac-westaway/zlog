const std = @import("std");

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

    const hours = extra_time / 3600;
    const minutes = @divExact(@mod(extra_time, 3600), 60);
    const seconds = @mod(@mod(extra_time, 3600), 60);

    // YYYY/MM/DD-HH:MM:SS
    // In UTC time, because the current computer system is in UTC time
    const formatted_time: []u8 = std.fmt.allocPrint(allocator, "{d}/{d}/{d}-{d}:{d}:{d}", .{ current_year_unix, month, @floor(date), @floor(hours), minutes, seconds }) catch unreachable;

    return formatted_time;
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
}
