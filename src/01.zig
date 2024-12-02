const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("./01.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    try stdout.print("part 1: {}\n", .{try part_1(allocator, data)});
    try stdout.print("part 2: {}\n", .{try part_2(allocator, data)});
}

fn part_1(allocator: Allocator, input: []const u8) !usize {
    var left_list = SortedLinkedList.init(allocator);
    defer left_list.deinit();

    var right_list = SortedLinkedList.init(allocator);
    defer right_list.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const first_space_idx = std.mem.indexOfScalar(u8, line, ' ') orelse unreachable;
        try left_list.insert(try std.fmt.parseInt(usize, line[0..first_space_idx], 10));
        try right_list.insert(try std.fmt.parseInt(usize, std.mem.trimLeft(u8, line[first_space_idx + 1 ..], " "), 10));
    }

    var total: usize = 0;
    var a_iter = left_list.iter();
    var b_iter = right_list.iter();
    while (a_iter.next()) |a_node| {
        const b_node = b_iter.next() orelse unreachable;
        const a = a_node.value;
        const b = b_node.value;
        total += if (a > b) a - b else b - a;
    }

    return total;
}

const test_input =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;
test "part 1" {
    const actual = try part_1(std.testing.allocator, test_input);
    try std.testing.expectEqual(11, actual);
}

fn part_2(allocator: Allocator, input: []const u8) !usize {
    var left_map = std.AutoArrayHashMap(usize, usize).init(allocator);
    defer left_map.deinit();

    var right_map = std.AutoArrayHashMap(usize, usize).init(allocator);
    defer right_map.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const first_space_idx = std.mem.indexOfScalar(u8, line, ' ') orelse unreachable;

        const left = try std.fmt.parseInt(usize, line[0..first_space_idx], 10);
        const left_total = left_map.get(left) orelse 0;
        try left_map.put(left, left_total + 1);

        const right = try std.fmt.parseInt(usize, std.mem.trimLeft(u8, line[first_space_idx + 1 ..], " "), 10);
        const right_total = right_map.get(right) orelse 0;
        try right_map.put(right, right_total + 1);
    }

    var total: usize = 0;
    var iter = left_map.iterator();
    while (iter.next()) |entry| {
        const key = entry.key_ptr.*;
        const right = right_map.get(key) orelse 0;
        total += key * right * entry.value_ptr.*;
    }
    return total;
}

test "part 2" {
    const actual = try part_2(std.testing.allocator, test_input);
    try std.testing.expectEqual(31, actual);
}

/// Linked list that maintains `usize` values in a sorted (asc) order.
const SortedLinkedList = struct {
    const Node = struct {
        next: ?*Node,
        value: usize,
    };

    allocator: Allocator,
    head: ?*Node,

    pub fn init(allocator: Allocator) SortedLinkedList {
        return .{ .allocator = allocator, .head = null };
    }

    pub fn deinit(self: *SortedLinkedList) void {
        var nodes = self.iter();
        while (nodes.next()) |node| {
            self.allocator.destroy(node);
        }
    }

    pub fn insert(self: *SortedLinkedList, value: usize) !void {
        const node = try self.allocator.create(Node);
        node.* = .{ .next = null, .value = value };

        const head = self.head orelse return {
            self.head = node;
        };

        var prev = head;
        var curr: ?*Node = head.next;

        while (curr) |c| {
            if (c.value >= value) break;
            prev = c;
            curr = c.next;
        }

        if (curr == null and prev.value > value) {
            self.head = node;
            node.next = prev;
        } else {
            prev.next = node;
            node.next = curr;
        }
    }

    const Iterator = struct {
        current: ?*Node,

        pub fn next(self: *Iterator) ?*Node {
            const current = self.current orelse return null;
            const ret = current;
            self.current = current.next;
            return ret;
        }
    };

    /// Returns an iterator that iterates over the nodes in the linked list.
    pub fn iter(self: SortedLinkedList) Iterator {
        return .{ .current = self.head };
    }
};

test "insert empty" {
    var s = SortedLinkedList.init(std.testing.allocator);
    defer s.deinit();

    try s.insert(69);

    try std.testing.expect(s.head != null);
    try std.testing.expectEqual(69, s.head.?.value);
}

test "insert larger" {
    var s = SortedLinkedList.init(std.testing.allocator);
    defer s.deinit();

    try s.insert(69);
    try s.insert(420);

    try std.testing.expectEqual(69, s.head.?.value);
    try std.testing.expectEqual(420, s.head.?.next.?.value);
}

test "insert smaller" {
    var s = SortedLinkedList.init(std.testing.allocator);
    defer s.deinit();

    try s.insert(420);
    try s.insert(69);

    try std.testing.expectEqual(69, s.head.?.value);
    try std.testing.expectEqual(420, s.head.?.next.?.value);
}

test "insert" {
    var s = SortedLinkedList.init(std.testing.allocator);
    defer s.deinit();

    try s.insert(420);
    try s.insert(42);
    try s.insert(69);
    try s.insert(59);

    try std.testing.expectEqual(42, s.head.?.value);
    try std.testing.expectEqual(59, s.head.?.next.?.value);
    try std.testing.expectEqual(69, s.head.?.next.?.next.?.value);
    try std.testing.expectEqual(420, s.head.?.next.?.next.?.next.?.value);
}
