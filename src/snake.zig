const std = @import("std");
const SDL = @import("SDL.zig");
const Fruit = @import("fruit.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const PrevPosition = struct {
    x: i32,
    y: i32,
};

pub const SnakeHead = struct {
    rect: SDL.c.SDL_Rect,
    first: *Body,
    last: *Body,
    prev_position: PrevPosition,

    pub fn create_snake(x: i32, y: i32, size: u8) !SnakeHead {
        var first = try Body.create_first(x - 1, y, size);

        var new_snake = SnakeHead {
            .rect = SDL.c.SDL_Rect {
                .x = x * size,
                .y = y * size,
                .w = size,
                .h = size,
            },
            .first = first,
            .last = first,
            .prev_position = PrevPosition {
                .x = 0,
                .y = 0,
            }
        };
        return new_snake;
    }

    pub fn draw(self: *SnakeHead, renderer: ?*SDL.c.SDL_Renderer) void {
        _ = SDL.c.SDL_SetRenderDrawColor(renderer.?, 0xff, 0xA5, 0x00, 0xff); // Orange
        _ = SDL.c.SDL_RenderFillRect(renderer.?, &self.rect);

        self.first.draw(renderer);
    }

    pub fn update(self: *SnakeHead, x_vel: i8, y_vel: i8, window_size: i32) anyerror!void {
        self.prev_position = PrevPosition {
            .x = self.rect.x,
            .y = self.rect.y,
        };

        self.rect.x += x_vel * self.rect.w;
        self.rect.y += y_vel * self.rect.w;
        
        // Wrap the player around the map
        // Body segments don't need to do this, as they follow each other's previous positions anyways.
        if (self.rect.x > window_size - 1) self.rect.x = 0;
        if (self.rect.x < 0) self.rect.x = window_size;

        if (self.rect.y > window_size - 1) self.rect.y = 0;
        if (self.rect.y < 0) self.rect.y = window_size;
 
        try self.first.update_first(self);
    }

    pub fn append_new_body(self: *SnakeHead) anyerror!void {
        // Because of the fact that variable memory is dropped when a function's block exits, the memory of the snake's segment is allocated on the heap
        // TODO: Consider cleaning this up.
        const allocator = gpa.allocator();
        var child = try allocator.create(Body);

        child.rect.x = self.last.prev_position.x;
        child.rect.y = self.last.prev_position.y;
        child.rect.w = self.last.rect.w;
        child.rect.h = self.last.rect.h;
        child.prev_position = PrevPosition {
            .x = 0,
            .y = 0,
        };

        child.next = self.last;
        child.prev = null;
        self.last.prev = child;
        self.last = child;
    }

    pub fn touching_body(self: *SnakeHead) bool {
        // This feels like something hacky, but whatever.
        var current: ?*Body = self.first;
        while (current != null) {
            if (self.rect.x == current.?.rect.x and self.rect.y == current.?.rect.y) return true;
            current = current.?.prev;
        }

        return false;
    }

    pub fn touching_fruit(self: *SnakeHead, fruit: *Fruit.Fruit) bool {
        return (self.rect.x == fruit.rect.x and self.rect.y == fruit.rect.y);
    }
    
};

pub const Body = struct {
    rect: SDL.c.SDL_Rect,
    prev: ?*Body,
    next: ?*Body,
    prev_position: PrevPosition,

    fn create_first(x: i32, y: i32, size: u8) anyerror!*Body {
        // Same thing as in `SnakeHead.append_new_child()`
        const allocator = gpa.allocator();
        var child = try allocator.create(Body);

        child.rect.x = x;
        child.rect.y = y;
        child.rect.w = size;
        child.rect.h = size;
        child.prev_position = PrevPosition {
            .x = 0,
            .y = 0,
        };

        child.next = null;
        child.prev = null;

        return child;
    }

    fn update_first(self: *Body, head: *SnakeHead) anyerror!void {
        self.prev_position = PrevPosition {
            .x = self.rect.x,
            .y = self.rect.y,
        };
        self.rect.x = head.prev_position.x;
        self.rect.y = head.prev_position.y;

        const prev: *Body = self.prev orelse return;
        try prev.update();
    }

    pub fn draw(self: *Body, renderer: ?*SDL.c.SDL_Renderer) void {
        _ = SDL.c.SDL_SetRenderDrawColor(renderer, 0xA3, 0x6A, 0x00, 0xff); // Vomit
        _ = SDL.c.SDL_RenderFillRect(renderer, &self.rect);

        const prev: *Body = self.prev orelse return;
        prev.draw(renderer);
    }

    pub fn update(self: *Body) anyerror!void {
        self.prev_position = PrevPosition {
            .x = self.rect.x,
            .y = self.rect.y,
        };
        self.rect.x = self.next.?.prev_position.x;
        self.rect.y = self.next.?.prev_position.y;

        const prev: *Body = self.prev orelse return;
        try prev.update();
    }

};