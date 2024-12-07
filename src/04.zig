const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("./04.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("part 1: {}\n", .{try part_1(data)});
    try stdout.print("part 2: {}\n", .{try part_2(data)});
}

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var grid = try buildGrid(allocator, input);
    defer grid.deinit();

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

fn part_2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var grid = try buildGrid(allocator, input);
    defer grid.deinit();

    var total: usize = 0;
    for (grid.items, 0..) |line, row| {
        for (0..line.len) |col| {
            total += isXmas(grid.items, row, col);
        }
    }
    return total;
}

fn isXmas(grid: [][]const u8, row: usize, col: usize) usize {
    if (row < 1 or row > grid.len - 2 or col < 1 or col > grid[0].len - 2 or grid[row][col] != 'A') return 0;

    const nw = grid[row - 1][col - 1];
    const ne = grid[row - 1][col + 1];
    const se = grid[row + 1][col + 1];
    const sw = grid[row + 1][col - 1];

    if (!isMS(nw) or !isMS(ne) or !isMS(se) or !isMS(sw)) return 0;
    if (nw == se or ne == sw) return 0;

    return 1;
}

fn isMS(c: u8) bool {
    return c == 'M' or c == 'S';
}

test "part 2" {
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
    const actual = try part_2(input);
    try std.testing.expectEqual(9, actual);
}

// foo
fn buildGrid(allocator: Allocator, input: []const u8) !std.ArrayList([]const u8) {
    var grid = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try grid.append(line);
    }
    return grid;
}
