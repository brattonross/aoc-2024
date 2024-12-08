const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("./06.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("part 1: {}\n", .{try part_1(data)});
}

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var map = try Map.init(allocator, input);
    defer map.deinit();

    var visited = std.StringHashMap(void).init(allocator);
    defer {
        var keys = visited.keyIterator();
        while (keys.next()) |key| {
            allocator.free(key.*);
        }
        visited.deinit();
    }

    try visited.put(try allocKey(allocator, map.start_pos.row, map.start_pos.col), {});

    var patrol = GuardPatrol.init(map);
    while (patrol.nextPos()) |pos| {
        const key = try allocKey(allocator, pos.row, pos.col);
        if (visited.getKey(key)) |_| {
            allocator.free(key);
        } else {
            try visited.put(key, {});
        }
    }

    return visited.count();
}

fn allocKey(allocator: Allocator, row: usize, col: usize) ![]const u8 {
    return try std.fmt.allocPrint(allocator, "{},{}", .{ row, col });
}

const GuardPatrol = struct {
    dir: Direction,
    pos: Position,
    map: Map,

    pub fn init(map: Map) GuardPatrol {
        return .{ .pos = map.start_pos, .dir = .up, .map = map };
    }

    pub fn nextPos(self: *GuardPatrol) ?Position {
        switch (self.dir) {
            .up => {
                if (self.pos.row == 0) return null;
                if (self.map.get(self.pos.row - 1, self.pos.col) == '#') {
                    self.dir = .right;
                } else {
                    self.pos = .{ .row = self.pos.row - 1, .col = self.pos.col };
                }
                return self.pos;
            },
            .right => {
                if (self.pos.col == self.map.width - 1) return null;
                if (self.map.get(self.pos.row, self.pos.col + 1) == '#') {
                    self.dir = .down;
                } else {
                    self.pos = .{ .row = self.pos.row, .col = self.pos.col + 1 };
                }
                return self.pos;
            },
            .down => {
                if (self.pos.row == self.map.height - 1) return null;
                if (self.map.get(self.pos.row + 1, self.pos.col) == '#') {
                    self.dir = .left;
                } else {
                    self.pos = .{ .row = self.pos.row + 1, .col = self.pos.col };
                }
                return self.pos;
            },
            .left => {
                if (self.pos.col == 0) return null;
                if (self.map.get(self.pos.row, self.pos.col - 1) == '#') {
                    self.dir = .up;
                } else {
                    self.pos = .{ .row = self.pos.row, .col = self.pos.col - 1 };
                }
                return self.pos;
            },
        }
    }
};

const Position = struct { row: usize, col: usize };
const Direction = enum { up, right, down, left };

const Map = struct {
    grid: std.ArrayList([]const u8),
    start_pos: Position,
    width: usize,
    height: usize,

    pub fn init(allocator: Allocator, input: []const u8) !Map {
        var grid = std.ArrayList([]const u8).init(allocator);
        var pos: Position = undefined;
        var lines = std.mem.splitScalar(u8, input, '\n');
        var row: usize = 0;
        var width: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            if (line.len == 0) continue;
            width = line.len;
            if (std.mem.indexOfScalar(u8, line, '^')) |col| {
                pos = .{ .row = row, .col = col };
            }
            try grid.append(line);
        }
        return .{ .grid = grid, .start_pos = pos, .width = width, .height = row };
    }

    pub fn deinit(self: *Map) void {
        self.grid.deinit();
    }

    fn get(self: Map, row: usize, col: usize) ?u8 {
        var ret: ?u8 = null;
        loop: for (0..self.grid.items.len) |r| {
            for (0..self.grid.items[r].len) |c| {
                if (row == r and col == c) {
                    ret = self.grid.items[r][c];
                    break :loop;
                }
            }
        }
        return ret;
    }
};

test "part 1" {
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    const actual = try part_1(input);
    try std.testing.expectEqual(41, actual);
}
