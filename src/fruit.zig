const SDL = @import("SDL.zig");
const std = @import("std");
// TODO: Choose the game's seed at runtime (Can it even be achieved the same way like in C?)
const rngGen = std.rand.DefaultPrng;
var random = rngGen.init(2137);

pub const Fruit = struct {
    rect: SDL.c.SDL_Rect,

    pub fn draw(self: *Fruit, renderer: ?*SDL.c.SDL_Renderer) void {
        _ = SDL.c.SDL_SetRenderDrawColor(renderer, 0xA3, 0x00, 0x00, 0xff);
        _ = SDL.c.SDL_RenderFillRect(renderer, &self.rect);
    }

    pub fn pick_position(self: *Fruit, window_size: i32, tile_size: i32) void {
        const potential_places: i32 = @divFloor(window_size, tile_size);
        
        // Substract possible places by 1 so that the fruit won't spawn outside the game's bounds.
        var random_x = random.random().intRangeAtMost(i32, 0, potential_places - 1);
        var random_y = random.random().intRangeAtMost(i32, 0, potential_places - 1);

        self.rect.x = random_x * tile_size;
        self.rect.y = random_y * tile_size;
    }
};