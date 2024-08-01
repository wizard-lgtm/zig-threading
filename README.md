# Zig threading context



## Just a library for threading examples in ziglang

## Example
```zig
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
```

### Works fine in 0.14.0 dev

### [video]() future planned

### you may contribute or support with starring :3
