const std = @import("std");
const ArrayList = std.ArrayList;
const testing = std.testing;

const Player = enum { none, circle, cross };
const gridError = error{outOfBound};
const grid_size = 3;

const Cell = struct {
    x: u8,
    y: u8,
};

const Grid = struct {
    tiles: [grid_size][grid_size]Player = undefined,

    pub fn init(self: *Grid) void {
        for (0..grid_size) |row| {
            for (0..grid_size) |column| {
                self.tiles[row][column] = Player.none;
            }
        }
    }

    pub fn setTileState(self: *Grid, x: u8, y: u8, state: Player) gridError!void {
        if ((self.tiles.len <= y) or (self.tiles[y].len <= x)) {
            return gridError.outOfBound;
        }

        self.tiles[y][x] = state;
    }

    pub fn print(self: *Grid) void {
        for (self.tiles) |row| {
            for (row) |tile| {
                const c: *const [1]u8 = switch (tile) {
                    Player.none => "_",
                    Player.circle => "0",
                    Player.cross => "X",
                };

                std.debug.print("{s}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn checkWin(self: *Grid) Player {
        // Check lines
        for (0..grid_size) |row| {
            const first_value = self.tiles[row][0];

            const result: Player = for (1..grid_size) |i| {
                if (self.tiles[row][i] != first_value) {
                    break Player.none;
                }
            } else first_value;

            if (result != Player.none) return result;
        }

        // Check columns
        for (0..grid_size) |column| {
            const first_value = self.tiles[0][column];

            const result: Player = for (1..grid_size) |i| {
                if (self.tiles[i][column] != first_value) {
                    break Player.none;
                }
            } else first_value;

            if (result != Player.none) return result;
        }

        return Player.none;
    }

    pub fn isCellFree(self: *Grid, cell: *const Cell) !bool {
        if (cell.x < 0 or cell.x >= grid_size or cell.y < 0 or cell.y >= grid_size) {
            return error.outOfBound;
        }

        return self.tiles[cell.x][cell.y] == Player.none;
    }
};

pub fn ask_user(str: []const u8) !u8 {
    const buffer_size: u8 = 10;
    var buffer: [buffer_size]u8 = undefined;

    const stdin = std.io.getStdIn().reader();

    std.debug.print("Enter a {s} index please: ", .{str});

    if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |input| {
        const end_index = if (input[input.len - 1] == '\r') input.len - 1 else input.len;

        const slice = input[0..end_index];
        const value = try std.fmt.parseInt(u8, slice, buffer_size);

        if (value < 3) {
            return value;
        } else {
            return error.InvalidCharacter;
        }
    } else {
        return error.InvalidCharacter;
    }
}

pub fn askPlayerCell(grid: *Grid) *const Cell {
    var is_valid_cell = false;

    while (!is_valid_cell) {
        grid.print();
        const row: u8 = ask_user("row") catch {
            continue;
        };
        const column: u8 = ask_user("column") catch {
            continue;
        };
        const cell = Cell{ .x = row, .y = column };

        is_valid_cell = grid.isCellFree(&cell) catch {
            std.debug.print("Invalid position, try again!", .{});
            continue;
        };

        if (is_valid_cell) {
            return &cell;
        }
    } else {
        unreachable;
    }
}

pub fn game_loop(grid: *Grid) !Player {
    var current_player = Player.circle;
    var turn_count: u8 = 0;
    const max_nb_turns = grid_size * grid_size;

    while (turn_count < max_nb_turns) : (turn_count += 1) {
        std.debug.print("{s} is playing!\n", .{@tagName(current_player)});
        const cell = askPlayerCell(grid);

        try grid.setTileState(cell.x, cell.y, current_player);

        if (turn_count % 2 == 0) {
            current_player = Player.cross;
        } else {
            current_player = Player.circle;
        }

        const winner = grid.checkWin();

        if (winner != Player.none) {
            return winner;
        }
    }

    return Player.none;
}

pub fn main() !void {
    var grid = Grid{};
    grid.init();

    const winner = try game_loop(&grid);
    grid.print();
    std.debug.print("{s} win the game!", .{@tagName(winner)});
}
