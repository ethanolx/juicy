const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    switch (args.len) {
        1 => print("No input source specified :|\n", .{}),
        2 => {
            const src: []const u8 = args[1];
            if (std.fs.cwd().openFile(src, .{})) |file| {
                var buf = [_]u8{0} ** 100;
                const ins_count: usize = try file.readAll(&buf);
                if (ins_count == 0) {
                    print("Nothing to do :/\n", .{});
                    return;
                }
                print("Running \"{s}\" :D\n", .{src});
                var data = [_]u8{0} ** 256;
                var ptr: u8 = 0;
                var ins_ptr: u8 = 0;

                var stack_space: [255]u8 = undefined;
                var fbc = std.heap.FixedBufferAllocator.init(&stack_space);

                var stack = std.ArrayList(u8).init(fbc.allocator());
                defer stack.deinit();

                while (ins_ptr < ins_count) : (ins_ptr += 1) {
                    const c: u8 = buf[ins_ptr];
                    try switch (c) {
                        '<' => ptr -%= 1,
                        '>' => ptr +%= 1,
                        '+' => data[ptr] +%= 1,
                        '-' => data[ptr] -%= 1,
                        '.' => print("{c}", .{data[ptr]}),
                        ',' => {},
                        '[' => stack.append(@as(u8, ins_ptr)),
                        ']' => {
                            if (data[ptr] == 0) {
                                _ = stack.pop();
                            } else {
                                ins_ptr = stack.getLast();
                            }
                        },
                        else => {},
                    };
                }
            } else |_| {
                print("Error opening {s} :(\n", .{src});
            }
        },
        else => print("More than one input source specified ({s}) :P\n", .{args[1..]}),
    }
}
