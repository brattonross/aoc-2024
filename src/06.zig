const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("./06.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("part 1: {}\n", .{try part_1(data)});
    try stdout.print("part 2: {}\n", .{try part_2(data)});
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

    try visited.put(try posKey(allocator, map.start_pos), {});

    var patrol = GuardPatrol.init(map);
    while (patrol.nextPos()) |pos| {
        const key = try posKey(allocator, pos);
        if (visited.getKey(key)) |_| {
            allocator.free(key);
        } else {
            try visited.put(key, {});
        }
    }

    return visited.count();
}

fn part_2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    var map = try Map.init(allocator, input);
    var initial_visits = std.ArrayList(Position).init(allocator);

    var patrol = GuardPatrol.init(map);
    while (patrol.nextPos()) |pos| try initial_visits.append(pos);

    var solutions = std.ArrayList(Position).init(allocator);
    for (initial_visits.items) |initial_visit| {
        map.grid.items[initial_visit.row][initial_visit.col] = '#';
        defer map.grid.items[initial_visit.row][initial_visit.col] = '.';

        var visited = std.ArrayList(Position).init(allocator);
        try visited.append(map.start_pos);

        var p = GuardPatrol.init(map);
        patrol: while (p.nextPos()) |pos| {
            for (visited.items) |v| {
                if (v.row == pos.row and v.col == pos.col and v.dir == pos.dir) {
                    try solutions.append(initial_visit);
                    break :patrol;
                }
            }
            try visited.append(pos);
        }
    }
    return solutions.items.len;
}

fn posKey(allocator: Allocator, pos: Position) ![]const u8 {
    return try std.fmt.allocPrint(allocator, "{},{}", .{ pos.row, pos.col });
}

fn posKeyWithDir(allocator: Allocator, pos: Position) ![]const u8 {
    return try std.fmt.allocPrint(allocator, "{},{}:{}", .{ pos.row, pos.col, pos.dir });
}

const GuardPatrol = struct {
    pos: Position,
    map: Map,

    pub fn init(map: Map) GuardPatrol {
        return .{ .pos = map.start_pos, .map = map };
    }

    pub fn nextPos(self: *GuardPatrol) ?Position {
        switch (self.pos.dir) {
            .up => {
                if (self.pos.row == 0) return null;
                if (self.map.get(self.pos.row - 1, self.pos.col) == '#') {
                    self.pos.dir = .right;
                } else {
                    self.pos.row -= 1;
                }
                return self.pos;
            },
            .right => {
                if (self.pos.col == self.map.width - 1) return null;
                if (self.map.get(self.pos.row, self.pos.col + 1) == '#') {
                    self.pos.dir = .down;
                } else {
                    self.pos.col += 1;
                }
                return self.pos;
            },
            .down => {
                if (self.pos.row == self.map.height - 1) return null;
                if (self.map.get(self.pos.row + 1, self.pos.col) == '#') {
                    self.pos.dir = .left;
                } else {
                    self.pos.row += 1;
                }
                return self.pos;
            },
            .left => {
                if (self.pos.col == 0) return null;
                if (self.map.get(self.pos.row, self.pos.col - 1) == '#') {
                    self.pos.dir = .up;
                } else {
                    self.pos.col -= 1;
                }
                return self.pos;
            },
        }
    }
};

const Position = struct { row: usize, col: usize, dir: Direction };
const Direction = enum { up, right, down, left };

const Map = struct {
    allocator: Allocator,
    grid: std.ArrayList([]u8),
    start_pos: Position,
    width: usize,
    height: usize,

    pub fn init(allocator: Allocator, input: []const u8) !Map {
        var grid = std.ArrayList([]u8).init(allocator);
        var pos: Position = undefined;
        var lines = std.mem.splitScalar(u8, input, '\n');
        var row: usize = 0;
        var width: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            if (line.len == 0) continue;
            width = line.len;
            if (std.mem.indexOfScalar(u8, line, '^')) |col| {
                pos = .{ .row = row, .col = col, .dir = .up };
            }
            const copy = try allocator.dupe(u8, line);
            try grid.append(copy);
        }
        return .{ .allocator = allocator, .grid = grid, .start_pos = pos, .width = width, .height = row };
    }

    pub fn deinit(self: *Map) void {
        for (self.grid.items) |row| {
            self.allocator.free(row);
        }
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

test "part 2" {
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
    const actual = try part_2(input);
    try std.testing.expectEqual(6, actual);
}
