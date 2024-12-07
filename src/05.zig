const std = @import("std");
const Allocator = std.mem.Allocator;

const data = @embedFile("./05.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("part 1: {}\n", .{try part_1(data)});
    try stdout.print("part 2: {}\n", .{try part_2(data)});
}

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var graph = DirectedGraph.init(allocator);
    defer graph.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) break;

        const pipe_index = std.mem.indexOfScalar(u8, line, '|') orelse unreachable;
        const from = try std.fmt.parseInt(usize, line[0..pipe_index], 10);
        const to = try std.fmt.parseInt(usize, line[pipe_index + 1 ..], 10);
        try graph.add(from, to);
    }

    var total: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var list = std.ArrayList(usize).init(allocator);
        defer list.deinit();

        var nums = std.mem.splitScalar(u8, line, ',');
        while (nums.next()) |num| {
            const n = try std.fmt.parseInt(usize, num, 10);
            try list.append(n);
        }

        if (graph.canTraverse(list.items)) {
            total += list.items[list.items.len / 2];
        }
    }
    return total;
}

test "part 1" {
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;
    const actual = try part_1(input);
    try std.testing.expectEqual(143, actual);
}

fn part_2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var graph = DirectedGraph.init(allocator);
    defer graph.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) break;

        const pipe_index = std.mem.indexOfScalar(u8, line, '|') orelse unreachable;
        const from = try std.fmt.parseInt(usize, line[0..pipe_index], 10);
        const to = try std.fmt.parseInt(usize, line[pipe_index + 1 ..], 10);
        try graph.add(from, to);
    }

    var total: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var list = std.ArrayList(usize).init(allocator);
        defer list.deinit();

        var nums = std.mem.splitScalar(u8, line, ',');
        while (nums.next()) |num| {
            const n = try std.fmt.parseInt(usize, num, 10);
            try list.append(n);
        }

        if (graph.canTraverse(list.items)) {
            continue;
        }

        std.mem.sort(usize, list.items, graph, sort);
        total += list.items[list.items.len / 2];
    }
    return total;
}

/// Returns a bool indicating if left is less than right.
/// In this case, that means "can the node with value `left` NOT visit the node with value `right`".
fn sort(graph: DirectedGraph, left: usize, right: usize) bool {
    const left_node = graph.get(left) orelse std.debug.panic("unknown node {}", .{left});
    return !left_node.canVisit(right);
}

test "part 2" {
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;
    const actual = try part_2(input);
    try std.testing.expectEqual(123, actual);
}

const DirectedGraph = struct {
    const Node = struct {
        value: usize,
        to: std.ArrayList(*Node),

        pub fn init(allocator: Allocator, value: usize) Node {
            return .{ .to = std.ArrayList(*Node).init(allocator), .value = value };
        }

        pub fn deinit(self: *Node) void {
            self.to.deinit();
        }

        pub fn canVisit(self: Node, value: usize) bool {
            for (self.to.items) |to| {
                if (to.value == value) return true;
            }
            return false;
        }
    };

    allocator: Allocator,
    nodes: std.ArrayList(*Node),

    pub fn init(allocator: Allocator) DirectedGraph {
        return .{ .allocator = allocator, .nodes = std.ArrayList(*Node).init(allocator) };
    }

    pub fn deinit(self: *DirectedGraph) void {
        for (self.nodes.items) |node| {
            node.deinit();
            self.allocator.destroy(node);
        }
        self.nodes.deinit();
    }

    /// add an edge between `from` and `to`, creating the nodes if they don't exist.
    pub fn add(self: *DirectedGraph, from: usize, to: usize) !void {
        var from_node = try self.getOrAppend(from);
        const to_node = try self.getOrAppend(to);
        try from_node.to.append(to_node);
    }

    fn getOrAppend(self: *DirectedGraph, value: usize) !*Node {
        for (self.nodes.items) |node| {
            if (node.value == value) return node;
        }

        const node = try self.allocator.create(Node);
        node.* = Node.init(self.allocator, value);
        try self.nodes.append(node);

        return node;
    }

    pub fn format(self: DirectedGraph, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        for (self.nodes.items) |node| {
            for (node.to.items) |to| {
                try writer.print("{} -> {}\n", .{ node.value, to.value });
            }
        }
    }

    /// Returns a bool that indicates whether a path can be traversed for this graph.
    ///
    /// Starting from the node that matches the first value, the node's `to` list must
    /// contain all of the remaining path values. The last node passes by default.
    pub fn canTraverse(self: DirectedGraph, path: []usize) bool {
        for (0..path.len - 1) |i| {
            const node = self.get(path[i]) orelse return false;
            for (path[i + 1 ..]) |value| {
                if (!node.canVisit(value)) return false;
            }
        }
        return true;
    }

    fn get(self: DirectedGraph, value: usize) ?*Node {
        for (self.nodes.items) |node| {
            if (node.value == value) return node;
        }
        return null;
    }
};
