const std = @import("std");

const data = @embedFile("./03.input");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("part 1: {}\n", .{part_1(data)});
    try stdout.print("part 2: {}\n", .{part_2(data)});
}

fn part_1(input: []const u8) usize {
    var total: usize = 0;
    var iter = MulIterator.init(input);
    while (iter.next()) |mul| {
        total += mul.left * mul.right;
    }
    return total;
}

fn part_2(input: []const u8) usize {
    var total: usize = 0;
    var iter = MulIterator.init(input);
    while (iter.nextEnabled()) |mul| {
        total += mul.left * mul.right;
    }
    return total;
}

const Mul = struct { left: usize, right: usize };
const MulIterator = struct {
    buffer: []const u8,
    pos: usize,
    enabled: bool,

    pub fn init(buffer: []const u8) MulIterator {
        return .{ .buffer = buffer, .pos = 0, .enabled = true };
    }

    pub fn next(self: *MulIterator) ?Mul {
        while (self.current()) |curr| {
            switch (curr) {
                'd' => if (self.readConditional()) |enabled| {
                    self.enabled = enabled;
                },
                'm' => if (self.readMul()) |mul| return mul else {},
                else => self.advance(),
            }
        }
        return null;
    }

    pub fn nextEnabled(self: *MulIterator) ?Mul {
        while (self.next()) |mul| {
            if (self.enabled) return mul;
        }
        return null;
    }

    fn advanceIf(self: *MulIterator, expected: u8) bool {
        if (self.current() != expected) {
            return false;
        }
        self.advance();
        return true;
    }

    fn advance(self: *MulIterator) void {
        self.pos += 1;
    }

    fn current(self: MulIterator) ?u8 {
        return self.at(self.pos);
    }

    fn at(self: MulIterator, pos: usize) ?u8 {
        return if (pos >= self.buffer.len) null else self.buffer[pos];
    }

    fn readMul(self: *MulIterator) ?Mul {
        if (!self.advanceIf('m')) return null;
        if (!self.advanceIf('u')) return null;
        if (!self.advanceIf('l')) return null;
        if (!self.advanceIf('(')) return null;
        const left = self.readInt() catch {
            return null;
        } orelse return null;
        if (!self.advanceIf(',')) return null;
        const right = self.readInt() catch {
            return null;
        } orelse return null;
        if (!self.advanceIf(')')) return null;
        return .{ .left = left, .right = right };
    }

    fn readInt(self: *MulIterator) !?usize {
        var curr = self.current() orelse return null;
        if (!isDigit(curr)) return null;

        var num: usize = try std.fmt.parseInt(usize, &[_]u8{curr}, 10);
        self.advance();

        curr = self.current() orelse return num;
        if (!isDigit(curr)) return num;

        num = (num * 10) + try std.fmt.parseInt(usize, &[_]u8{curr}, 10);
        self.advance();

        curr = self.current() orelse return num;
        if (!isDigit(curr)) return num;

        num = (num * 10) + try std.fmt.parseInt(usize, &[_]u8{curr}, 10);
        self.advance();

        curr = self.current() orelse return num;
        if (isDigit(curr)) return null; // at this point, the number would be >3 digits long

        return num;
    }

    fn isDigit(value: u8) bool {
        return value >= '0' and value <= '9';
    }

    fn readConditional(self: *MulIterator) ?bool {
        if (!self.advanceIf('d')) return null;
        if (!self.advanceIf('o')) return null;
        const curr = self.current() orelse return null;
        switch (curr) {
            '(' => {
                self.advance();
                if (!self.advanceIf(')')) return null;
                return true;
            },
            'n' => {
                self.advance();
                if (!self.advanceIf('\'')) return null;
                if (!self.advanceIf('t')) return null;
                if (!self.advanceIf('(')) return null;
                if (!self.advanceIf(')')) return null;
                return false;
            },
            else => return null,
        }
    }
};

test "part 1" {
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const actual = part_1(input);
    try std.testing.expectEqual(161, actual);
}

test "part 2" {
    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const actual = part_2(input);
    try std.testing.expectEqual(48, actual);
}
