const std = @import("std");
const ArrayList = std.ArrayList;
const testing = std.testing;

const Player = enum {
    none,
    circle,
    cross,

    fn getSymbol(self: *Player) u32 {
        return switch (self) {
            Player.none => "_",
            Player.circle => "0",
            Player.cross => "X",
        };
    }
};

const gridError = error{outOfBound};
const invalidInput = error{unexpected};
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
            for (row) |player| {
                const c = player.getSymbol();

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

        // Check top-left to bottom-right diagonal
        const top_left_value = self.tiles[0][0];

        for (1..grid_size) |i| {
            if (self.tiles[i][i] != top_left_value) {
                break;
            }
        } else return top_left_value;

        // Check bottom-left to top-right diagonal
        const bottom_left_value = self.tiles[0][grid_size - 1];

        for (1..grid_size) |i| {
            if (self.tiles[i][grid_size - 1 - i] != bottom_left_value) {
                break;
            }
        } else return bottom_left_value;

        return Player.none;
    }

    pub fn isCellFree(self: *Grid, cell: *const Cell) !bool {
        if (cell.x >= grid_size or cell.y >= grid_size) {
            return error.outOfBound;
        }

        return self.tiles[cell.x][cell.y] == Player.none;
    }
};

pub fn main() !void {
    var want_to_play = true;

    while (want_to_play) {
        var grid = Grid{};
        grid.init();

        const winner = try gameLoop(&grid);
        grid.print();

        if (winner == Player.none) {
            std.debug.print("It's a draw!\n", .{});
        } else {
            std.debug.print("{s} win the game!\n", .{@tagName(winner)});
        }

        std.debug.print("Do you want to play again? y/n\n", .{});

        while (askPlayerInputChar()) |input| {
            const char = std.ascii.toLower(input);

            want_to_play = switch (char) {
                'y' => true,
                'n' => false,
                else => continue,
            };
        } else |err| {
            if (err == invalidInput.unexpected) continue;
        }
    }
}

pub fn gameLoop(grid: *Grid) !Player {
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

pub fn askPlayerInputChar() invalidInput!u8 {
    const buffer_size: u8 = 10;
    var buffer: [buffer_size]u8 = undefined;

    const stdin = std.io.getStdIn().reader();
    const input = stdin.readUntilDelimiterOrEof(buffer[0..], '\n') catch {
        return invalidInput.unexpected;
    } orelse return invalidInput.unexpected;

    const end_index = if (input[input.len - 1] == '\r') input.len - 1 else input.len;
    const slice = input[0..end_index];

    if (slice.len > 0) {
        return slice[0];
    } else {
        return invalidInput.unexpected;
    }

    return invalidInput.unexpected;
}

pub fn isValidGridIndex(index: u8) bool {
    return index < grid_size;
}

pub fn askPlayerCell(grid: *Grid) *const Cell {
    var is_valid_cell = false;

    while (!is_valid_cell) {
        grid.print();

        std.debug.print("Enter a row index please: ", .{});

        const row_char: u8 = askPlayerInputChar() catch {
            continue;
        };
        const row = std.fmt.parseInt(u8, &[1]u8{row_char}, 10) catch {
            continue;
        };

        std.debug.print("Enter a column index please: ", .{});

        const column_char: u8 = askPlayerInputChar() catch {
            continue;
        };
        const column = std.fmt.parseInt(u8, &[1]u8{column_char}, 10) catch {
            continue;
        };

        const cell = Cell{ .x = row, .y = column };

        is_valid_cell = grid.isCellFree(&cell) catch {
            std.debug.print("Invalid position, try again!\n", .{});
            continue;
        };

        if (is_valid_cell) {
            return &cell;
        } else {
            std.debug.print("Invalid position, try again!\n", .{});
        }
    } else {
        unreachable;
    }
}

test "test Grid.winCheck() row wins" {
    const player_types = [2]Player{ Player.circle, Player.cross };

    for (player_types) |player| {
        for (0..3) |row| {
            var grid = Grid{};
            grid.init();

            grid.tiles[row] = [_]Player{player} ** 3;
            try std.testing.expect(grid.checkWin() == player);
        }
    }
}

test "test Grid.winCheck() column wins" {
    const player_types = [2]Player{ Player.circle, Player.cross };

    for (player_types) |player| {
        for (0..3) |column| {
            var grid = Grid{};
            grid.init();

            for (0..3) |row| {
                grid.tiles[row][column] = player;
            }

            try std.testing.expect(grid.checkWin() == player);
        }
    }
}

test "test Grid.winCheck() top left to bottom right wins" {
    const player_types = [2]Player{ Player.circle, Player.cross };

    for (player_types) |player| {
        var grid = Grid{ .tiles = [3][3]Player{
            [3]Player{ player, Player.none, Player.none },
            [3]Player{ Player.none, player, Player.none },
            [3]Player{ Player.none, Player.none, player },
        } };

        try std.testing.expect(grid.checkWin() == player);
    }
}

test "test Grid.winCheck() top right to bottom left wins" {
    const player_types = [2]Player{ Player.circle, Player.cross };

    for (player_types) |player| {
        var grid = Grid{ .tiles = [3][3]Player{
            [3]Player{ Player.none, Player.none, player },
            [3]Player{ Player.none, player, Player.none },
            [3]Player{ player, Player.none, Player.none },
        } };

        try std.testing.expect(grid.checkWin() == player);
    }
}

test "test Grid.winCheck() non winning situations" {
    var grid = Grid{ .tiles = [3][3]Player{
        [3]Player{ Player.cross, Player.circle, Player.cross },
        [3]Player{ Player.cross, Player.circle, Player.none },
        [3]Player{ Player.circle, Player.cross, Player.none },
    } };

    try std.testing.expect(grid.checkWin() == Player.none);
}
