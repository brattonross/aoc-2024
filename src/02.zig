const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("./02.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    try stdout.print("part 1: {}\n", .{try part_1(allocator, data)});
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
