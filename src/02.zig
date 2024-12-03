const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("./02.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    try stdout.print("part 1: {}\n", .{try part_1(allocator, data)});
    try stdout.print("part 2: {}\n", .{try part_2(allocator, data)});
}

fn part_1(allocator: Allocator, input: []const u8) !usize {
    var total: usize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');

    line: while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var nums = std.ArrayList(isize).init(allocator);
        defer nums.deinit();

        var parts = std.mem.splitScalar(u8, line, ' ');
        while (parts.next()) |part| {
            const num = try std.fmt.parseInt(isize, part, 10);
            try nums.append(num);
        }

        var prev_diff: isize = 0;
        for (nums.items, 0..) |curr, i| {
            if (i == nums.items.len - 1) continue;
            const next = nums.items[i + 1];
            const diff = curr - next;
            const is_diff_too_large = diff == 0 or diff < -3 or diff > 3;
            const is_differing_direction = i != 0 and (diff > 0) != (prev_diff > 0);
            if (is_differing_direction or is_diff_too_large) continue :line;
            prev_diff = diff;
        }

        total += 1;
    }

    return total;
}

test "part 1" {
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const actual = try part_1(std.testing.allocator, input);
    try std.testing.expectEqual(2, actual);
}

fn part_2(allocator: Allocator, input: []const u8) !usize {
    var total: usize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');

    loop: while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var nums = std.ArrayList(isize).init(allocator);
        defer nums.deinit();

        var parts = std.mem.splitScalar(u8, line, ' ');
        while (parts.next()) |part| {
            const num = try std.fmt.parseInt(isize, part, 10);
            try nums.append(num);
        }

        if (!isSafe(nums.items)) {
            var is_safe = false;
            for (0..nums.items.len) |i| {
                const new_nums = try std.mem.concat(allocator, isize, &[_][]isize{ nums.items[0..i], nums.items[i + 1 ..] });
                defer allocator.free(new_nums);
                is_safe = isSafe(new_nums);
                if (is_safe) break;
            }
            if (!is_safe) continue :loop;
        }

        total += 1;
    }

    return total;
}

fn isSafe(nums: []isize) bool {
    const expected_diff = nums[0] - nums[1];
    for (0..nums.len - 1) |i| {
        const diff = nums[i] - nums[i + 1];
        if ((diff > 0) != (expected_diff > 0) or diff == 0 or diff < -3 or diff > 3) {
            return false;
        }
    }
    return true;
}

test "part 2" {
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const actual = try part_2(std.testing.allocator, input);
    try std.testing.expectEqual(4, actual);
}
