const std = @import("std");

const SDL = @import("SDL.zig");
const snake = @import("snake.zig");
const fruit = @import("fruit.zig");

const TILE_SIZE = 32;
const TICK_SPEED = 25;

const WINDOW_SIZE = 640;

const stdio = std.io.getStdOut().writer();

pub fn main() anyerror!void {
    _ = SDL.c.SDL_Init(SDL.c.SDL_INIT_VIDEO);
    defer SDL.c.SDL_Quit();

    var window = SDL.c.SDL_CreateWindow("Snek", SDL.c.SDL_WINDOWPOS_CENTERED, SDL.c.SDL_WINDOWPOS_CENTERED, WINDOW_SIZE, WINDOW_SIZE, 0);
    defer SDL.c.SDL_DestroyWindow(window);

    var renderer = SDL.c.SDL_CreateRenderer(window, 0, SDL.c.SDL_RENDERER_PRESENTVSYNC);
    defer SDL.c.SDL_DestroyRenderer(renderer);

    var player = try snake.SnakeHead.create_snake(1, 0, TILE_SIZE);

    var fruit_instance = fruit.Fruit {
        .rect = SDL.c.SDL_Rect{
            .x = 0,
            .y = 0,
            .w = TILE_SIZE,
            .h = TILE_SIZE,
        }
    };

    // Pick a new fruit position before the game is even initalized
    fruit_instance.pick_position(WINDOW_SIZE, TILE_SIZE);

    var x_velocity: i8 = 1;
    var y_velocity: i8 = 0;

    var frame_count: usize = 0;

    mainloop: while (true) {
        var sdl_event: SDL.c.SDL_Event = undefined;
        while (SDL.c.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                SDL.c.SDL_QUIT => break :mainloop,
                SDL.c.SDL_KEYDOWN => switch (sdl_event.key.keysym.sym) {
                    SDL.c.SDLK_LEFT => {
                        if (x_velocity == 0) {
                            x_velocity = -1;
                            y_velocity = 0;
                        }
                    },
                    SDL.c.SDLK_RIGHT => {
                        if (x_velocity == 0) {
                            x_velocity = 1;
                            y_velocity = 0;
                        }
                    },
                    SDL.c.SDLK_UP => {
                        if (y_velocity == 0) {
                            x_velocity = 0;
                            y_velocity = -1;
                        }
                    },
                    SDL.c.SDLK_DOWN => {
                        if (y_velocity == 0) {
                            x_velocity = 0;
                            y_velocity = 1;
                        }
                    },
                    else => {},
                },
                else => {},
            }
        }

        if (frame_count >= TICK_SPEED) {
            try player.update(x_velocity, y_velocity, WINDOW_SIZE);
            
            if (player.touching_body() == true) break :mainloop;
            if (player.touching_fruit(&fruit_instance) == true) {
                fruit_instance.pick_position(WINDOW_SIZE, TILE_SIZE);
                try player.append_new_body();
            }

            frame_count = 0;
        }

        _ = SDL.c.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
        _ = SDL.c.SDL_RenderClear(renderer);

        player.draw(renderer);
        fruit_instance.draw(renderer);

        SDL.c.SDL_RenderPresent(renderer);

        frame_count += 1;
    }

    try stdio.print("Game Over! \n", .{});
}
