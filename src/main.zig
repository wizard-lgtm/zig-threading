const std = @import("std");

const Allocator = std.mem.Allocator;
const Thread = std.Thread;

pub fn Server(comptime T: type) type {
    const _FunctionType = fn (T) anyerror!void;

    const _HandlerType = struct {
        function: *const _FunctionType,
        id: u8,
    };

    return struct {
        ctx: T,
        //
        allocator: std.mem.Allocator,
        handler: _HandlerType,
        pool: *Thread.Pool,
        // more fields can be added here

        const Self = @This();

        pub fn init(
            ctx: T,
            allocator: Allocator,
        ) !*Self {
            var pool = try allocator.create(Thread.Pool);
            try pool.init(.{ .allocator = allocator });

            const self: *Self = try allocator.create(Self);

            self.ctx = ctx;
            self.allocator = allocator;
            self.handler = undefined;
            self.pool = pool;

            return self;
        }

        pub fn deinit(self: *Self) void {
            std.debug.print("{d}\n", .{self.pool.threads.len});
            self.pool.is_running = false;
            self.pool.deinit();
            self.allocator.destroy(self.pool); // Free the allocated pool

            // Stucks at deiniting pool
            _ = self.allocator.destroy(self);
        }

        pub fn set_handler(self: *@This(), function: _FunctionType, id: u8) void {
            self.*.handler = _HandlerType{
                .function = &function,
                .id = id,
            };
        }

        pub fn execute_handler(self: Self) void {
            self.handler.function(self.ctx) catch |err| {
                std.debug.print("An error happened while executing handler {d}, {any}\n", .{ self.handler.id, err });
            };
            return;
        }

        pub fn execute_all(self: Self) !void {
            const exec = Self.execute_handler;
            _ = try self.pool.spawn(exec, .{self});
        }

        // more methods for Server(T) can be added here
    };
}

const Ctx = struct {
    some_data: u32,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = Ctx{ .some_data = 42 };
    var server = try Server(Ctx).init(ctx, allocator);

    server.set_handler(my_handler_function, 1);

    _ = try server.execute_all();

    _ = server.deinit();
}

fn my_handler_function(ctx: Ctx) anyerror!void {
    std.debug.print("some_data: {d}\n", .{ctx.some_data});
    std.time.sleep(std.time.ns_per_s * 0.6);
}
