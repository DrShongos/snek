const std = @import("std");
const sdl = @import("sdl.zig");
const game = @import("game.zig");

const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator(.{});
const Rng = std.rand.DefaultPrng;

pub fn main() anyerror!void {
    _ = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    var window = sdl.SDL_CreateWindow("Snake | [REDACTED] FPS", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, game.WINDOW_SIZE, game.WINDOW_SIZE, 0);
    defer sdl.SDL_DestroyWindow(window);

    var renderer = sdl.SDL_CreateRenderer(window, 0, sdl.SDL_RENDERER_PRESENTVSYNC);
    defer sdl.SDL_DestroyRenderer(renderer);

    var gpa = GeneralPurposeAllocator{};

    var rng = Rng.init(@intCast(u64, std.time.timestamp()));

    var alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var mainGame = try game.MainGame.new(alloc, rng.random());
    defer mainGame.cleanup();

    try mainGame.start();

    var time: usize = 0;

    mainloop: while (true) {
        // Input
        var sdl_event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                sdl.SDL_QUIT => break :mainloop,
                sdl.SDL_KEYDOWN => {
                    if (sdl_event.key.keysym.sym != sdl.SDLK_SPACE) {
                        mainGame.game_started = true;
                    }
                   
                    switch (sdl_event.key.keysym.sym) {
                        sdl.SDLK_LEFT => {
                            if (mainGame.snake.xDir == 0) {
                                mainGame.snake.xDir = -1;
                                mainGame.snake.yDir = 0;
                            }
                        },
                        sdl.SDLK_RIGHT => {
                            if (mainGame.snake.xDir == 0) {
                                mainGame.snake.xDir = 1;
                                mainGame.snake.yDir = 0;
                            }
                        },
                        sdl.SDLK_UP => {
                            if (mainGame.snake.yDir == 0) {
                                mainGame.snake.xDir = 0;
                                mainGame.snake.yDir = -1;
                            }
                        },
                        sdl.SDLK_DOWN => {
                            if (mainGame.snake.yDir == 0) {
                                mainGame.snake.xDir = 0;
                                mainGame.snake.yDir = 1;
                            }
                        },
                        sdl.SDLK_r => {
                            try mainGame.start();
                        },
                        sdl.SDLK_SPACE => {
                            mainGame.game_started = !mainGame.game_started;
                        },
                        else => {},
                    }
                },

                else => {},
            }
        }

        try mainGame.tick(time);

        // Render
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
        _ = sdl.SDL_RenderClear(renderer);

        for (mainGame.fruits) |fruit| {
            try fruit.drawColor(renderer);
        }

        try mainGame.snake.draw(renderer);

        _ = sdl.SDL_RenderPresent(renderer);

        time += 1;
    }
}
