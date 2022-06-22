const std = @import("std");
const sdl = @import("sdl.zig");

pub const CELL_SIZE = 16;
pub const WINDOW_SIZE = 640;
pub const TICK_SPEED = 15;
pub const FRUIT_AMOUNT = 1;

pub const SnakeBody = std.TailQueue(Cell);
const Node = SnakeBody.Node;

pub const DrawError = error{
    NoColor,
    NoTexture,
};

pub const BodyColor = Color.new(0xa3, 0x6a, 0x00);
pub const HeadColor = Color.new(0xff, 0xa5, 0x00);
pub const FruitColor = Color.new(0xb5, 0x25, 0x1b);

pub const MainGame = struct {
    snake: Snake,
    fruits: [FRUIT_AMOUNT]Cell,
    allocator: std.mem.Allocator,
    rng: std.rand.Random,
    game_started: bool,

    pub fn new(allocator: std.mem.Allocator, random: std.rand.Random) !MainGame {
        var fruitColor = FruitColor;
        var mainGame = MainGame{
            .snake = try Snake.init(allocator),
            .fruits = [FRUIT_AMOUNT]Cell{
                Cell.new(0, 0, fruitColor),
            },
            .allocator = allocator,
            .rng = random,
            .game_started = false,
        };

        return mainGame;
    }

    pub fn start(mainGame: *MainGame) !void {
        mainGame.game_started = false;
        mainGame.snake.deinit();
        mainGame.snake = try Snake.init(mainGame.allocator);

        for (mainGame.fruits) |*fruit| {
            fruit.randomPosition(mainGame.rng);
        }
    }

    pub fn tick(mainGame: *MainGame, time: usize) !void {
        var head = mainGame.snake.body.first.?;

        if (mainGame.game_started) {
            if ((time % TICK_SPEED) == 0) {
                mainGame.snake.update();
                for (mainGame.fruits) |*fruit| {
                    if (fruit.isTouching(&head.data)) {
                        try mainGame.snake.appendSegment();
                        fruit.randomPosition(mainGame.rng);
                    }
                }
            }
        }
    }

    pub fn cleanup(mainGame: *MainGame) void {
        mainGame.snake.deinit();
    }
};

pub const Snake = struct {
    body: SnakeBody,
    allocator: std.mem.Allocator,

    xDir: i8,
    yDir: i8,
    speed: i8 = 1,

    pub fn init(allocator: std.mem.Allocator) !Snake {
        var body = SnakeBody{};

        var headColor = HeadColor;
        var bodyColor = BodyColor;

        body.append(try Cell.as_node(9, 10, headColor, allocator));
        body.append(try Cell.as_node(10, 10, bodyColor, allocator));

        return Snake{
            .body = body,
            .xDir = -1,
            .yDir = 0,
            .allocator = allocator,
        };
    }

    pub fn draw(snake: *Snake, renderer: ?*sdl.SDL_Renderer) DrawError!void {
        var iter = snake.body.first;
        while (iter) |cell| : (iter = cell.next) {
            try cell.data.drawColor(renderer);
        }
    }

    pub fn update(snake: *Snake) void {
        var head = snake.body.first.?;
        var iter = head.next;

        var oldX = head.data.x;
        var oldY = head.data.y;

        // Move the head and then wrap it's position around the grid.
        head.data.setPosition((head.data.x + (snake.xDir * snake.speed)), head.data.y + (snake.yDir * snake.speed));
        head.data.setPosition(@mod(head.data.x, (WINDOW_SIZE / CELL_SIZE)), @mod(head.data.y, (WINDOW_SIZE / CELL_SIZE)));

        // Make next body parts go to previous segment's old position.
        while (iter) |cell| : (iter = cell.next) {
            var xTmp = cell.data.x;
            var yTmp = cell.data.y;

            cell.data.setPosition(oldX, oldY);

            if (head.data.isTouching(&cell.data)) {
                snake.speed = 0;
            }

            oldX = xTmp;
            oldY = yTmp;
        }
    }

    pub fn appendSegment(snake: *Snake) !void {
        var last = snake.body.last.?.data;
        var bodyColor = BodyColor;
        snake.body.append(try Cell.as_node(last.x, last.y, bodyColor, snake.allocator));
    }

    pub fn deinit(snake: *Snake) void {
        var iter = snake.body.first;
        while (iter) |cell| {
            iter = cell.next;
            snake.allocator.destroy(cell);
        }
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn new(r: u8, g: u8, b: u8) Color {
        return Color{
            .r = r,
            .g = g,
            .b = b,
        };
    }
};

pub const Cell = struct {
    x: i32,
    y: i32,
    color: ?Color,
    rect: sdl.SDL_Rect,

    /// Creates a Cell Node allocated on the heap.
    pub fn as_node(x: i32, y: i32, color: Color, allocator: std.mem.Allocator) !*Node {
        var new_node = try allocator.create(Node);
        new_node.data = Cell.new(x, y, color);

        return new_node;
    }

    /// Creates a new Cell on the stack.
    pub fn new(x: i32, y: i32, color: ?Color) Cell {
        return Cell{ .x = x, .y = y, .color = color, .rect = sdl.SDL_Rect{
            .x = x * CELL_SIZE,
            .y = y * CELL_SIZE,
            .w = CELL_SIZE,
            .h = CELL_SIZE,
        } };
    }

    /// Draws the Grid Cell using it's color.
    /// Will return a `DrawError` if the Cell has no color.
    pub fn drawColor(cell: *const Cell, renderer: ?*sdl.SDL_Renderer) DrawError!void {
        var color = cell.color orelse return DrawError.NoColor;

        _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 0xff);
        _ = sdl.SDL_RenderFillRect(renderer, &cell.rect);
    }

    pub fn setX(cell: *Cell, x: i32) void {
        cell.x = x;
        cell.rect.x = x * CELL_SIZE;
    }

    pub fn setY(cell: *Cell, y: i32) void {
        cell.y = y;
        cell.rect.y = y * CELL_SIZE;
    }

    pub fn setPosition(cell: *Cell, x: i32, y: i32) void {
        cell.setX(x);
        cell.setY(y);
    }

    pub fn randomPosition(cell: *Cell, random: std.rand.Random) void {
        var randX = random.intRangeAtMost(i32, 0, (WINDOW_SIZE / CELL_SIZE) - 1);
        var randY = random.intRangeAtMost(i32, 0, (WINDOW_SIZE / CELL_SIZE) - 1);

        cell.setPosition(randX, randY);
    }

    pub fn isTouching(cell: *const Cell, other: *const Cell) bool {
        return ((cell.x == other.x) and (cell.y == other.y));
    }
};
