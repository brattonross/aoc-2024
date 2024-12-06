const std = @import("std");

const data = @embedFile("./04.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("part 1: {}\n", .{try part_1(data)});
    // try stdout.print("part 2: {}\n", .{part_2(data)});
}

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var grid = std.ArrayList([]const u8).init(allocator);
    defer grid.deinit();

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try grid.append(line);
    }

    var total: usize = 0;
    for (grid.items, 0..) |line, row| {
        for (0..line.len) |col| {
            total += numXmas(grid.items, row, col);
        }
    }
    return total;
}

fn numXmas(grid: [][]const u8, row: usize, col: usize) usize {
    if (grid[row][col] != 'X') return 0;

    const width = grid[0].len;
    const height = grid.len;

    var total: usize = 0;
    for (0..8) |i| {
        total += switch (i) {
            // n
            0 => if (row >= 3 and grid[row - 1][col] == 'M' and grid[row - 2][col] == 'A' and grid[row - 3][col] == 'S') 1 else 0,
            // ne
            1 => if (row >= 3 and col <= width - 4 and grid[row - 1][col + 1] == 'M' and grid[row - 2][col + 2] == 'A' and grid[row - 3][col + 3] == 'S') 1 else 0,
            // e
            2 => if (col <= width - 4 and grid[row][col + 1] == 'M' and grid[row][col + 2] == 'A' and grid[row][col + 3] == 'S') 1 else 0,
            // se
            3 => if (row <= height - 4 and col <= width - 4 and grid[row + 1][col + 1] == 'M' and grid[row + 2][col + 2] == 'A' and grid[row + 3][col + 3] == 'S') 1 else 0,
            // s
            4 => if (row <= height - 4 and grid[row + 1][col] == 'M' and grid[row + 2][col] == 'A' and grid[row + 3][col] == 'S') 1 else 0,
            // sw
            5 => if (row <= height - 4 and col >= 3 and grid[row + 1][col - 1] == 'M' and grid[row + 2][col - 2] == 'A' and grid[row + 3][col - 3] == 'S') 1 else 0,
            // w
            6 => if (col >= 3 and grid[row][col - 1] == 'M' and grid[row][col - 2] == 'A' and grid[row][col - 3] == 'S') 1 else 0,
            // nw
            7 => if (row >= 3 and col >= 3 and grid[row - 1][col - 1] == 'M' and grid[row - 2][col - 2] == 'A' and grid[row - 3][col - 3] == 'S') 1 else 0,
            else => @panic("direction not supported"),
        };
    }
    return total;
}

test "part 1" {
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX   
    ;
    const actual = try part_1(input);
    try std.testing.expectEqual(18, actual);
}
