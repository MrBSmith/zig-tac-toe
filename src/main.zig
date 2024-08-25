const std = @import("std");
const ArrayList = std.ArrayList;
const testing = std.testing;

const TileState = enum { empty, circle, cross };
const gridError = error{outOfBound};

const String = struct {
    bytes: ArrayList(u8) = ArrayList(u8).init(std.heap.page_allocator),

    pub fn set(self: *String, str: []u8) !void {
        try self.bytes.appendSlice(str);
    }

    pub fn filter(self: *String, char: u8) void {
        var result = ArrayList(u8).init(std.heap.page_allocator);

        for (self.bytes.toOwnedSlice()) |byte| {
            if (byte != char) {
                result.append(byte);
            }
        }
        self.bytes = result;
    }
};

const Grid = struct {
    tiles: [3][3]TileState = undefined,

    pub fn init(self: *Grid) void {
        for (0..3) |row| {
            for (0..3) |column| {
                self.tiles[row][column] = TileState.empty;
            }
        }
    }

    pub fn setTileState(self: *Grid, x: u8, y: u8, state: TileState) gridError!void {
        if ((self.tiles.len <= y) or (self.tiles[y].len <= x)) {
            return gridError.outOfBound;
        }

        self.tiles[y][x] = state;
    }

    pub fn print(self: *Grid) void {
        for (self.tiles) |row| {
            for (row) |tile| {
                const c: *const [1]u8 = switch (tile) {
                    TileState.empty => "_",
                    TileState.circle => "0",
                    TileState.cross => "X",
                };

                std.debug.print("{s}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn ask_user(str: []const u8) !u8 {
    const buffer_size: u8 = 10;
    var buffer: [buffer_size]u8 = undefined;

    const stdin = std.io.getStdIn().reader();

    std.debug.print("Enter a {s} index please: ", .{str});

    if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| {
        var user_input = String{};
        user_input.set(input);
        user_input.filter('\r');

        const value = try std.fmt.parseInt(u8, user_input.bytes.allocatedSlice(), buffer_size);

        if (value < 3) {
            return value;
        } else {
            return error.InvalidCharacter;
        }
    } else {
        return error.InvalidCharacter;
    }
}

pub fn main() !void {
    var grid = Grid{};
    grid.init();
    grid.print();

    const row: u8 = try ask_user("row");
    const column: u8 = try ask_user("column");

    try grid.setTileState(row, column, TileState.circle);

    grid.print();
}
