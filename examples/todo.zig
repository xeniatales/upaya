const std = @import("std");
const upaya = @import("upaya");
const Color = upaya.math.Color;
usingnamespace upaya.imgui;

const ToDoState = struct {
    todos: []ToDo = undefined,

    pub const ToDo = struct {
        label: [25]u8 = [_]u8{0} ** 25,
        done: bool = false,
    };

    pub fn init() ToDoState {
        return .{ .todos = &[_]ToDo{} };
    }

    pub fn deinit(self: ToDoState) void {
        _ = self;
    }

    pub fn addToDo(self: *ToDoState) void {
        self.todos = upaya.mem.allocator.realloc(self.todos, self.todos.len + 1) catch unreachable;
        self.todos[self.todos.len - 1] = ToDoState.ToDo{};
    }
};

var state: ToDoState = undefined;

pub fn main() !void {
    upaya.run(.{
        .init = init,
        .update = update,
        .shutdown = shutdown,
        .docking = true,
        .setupDockLayout = setupDockLayout,
        .window_title = "Upaya ToDos",
        .width = 300,
        .height = 500,
        .swap_interval = 4,
    });
}

fn init() void {
    upaya.colors.setTintColor(Color.aya.asImVec4());
    // TODO: figure out why on windows [25]u8 is saved as an array and not a string
    if (std.Target.current.os.tag == .windows) {
        state = ToDoState.init();
    } else {
        state = upaya.fs.readPrefsJson(ToDoState, "upaya-todo", "todos.json") catch ToDoState.init();
    }
}

fn update() void {
    upaya.menu.draw(&[_]upaya.MenuItem{.{
        .label = "File",
        .children = &[_]upaya.MenuItem{
            .{ .label = "New", .action = onNew },
            .{ .label = "Quit", .action = onQuit },
        },
    }});

    _ = igBegin("ToDos", null, ImGuiWindowFlags_None);
    defer igEnd();

    for (state.todos) |*todo| {
        igPushIDPtr(todo);
        defer igPopID();

        _ = igCheckbox("##cb", &todo.done);
        igSameLine(0, -1);

        if (todo.done) {
            var pos = ogGetCursorScreenPos();
            pos.y += igGetFrameHeight() / 2;

            igText(&todo.label);

            var line_end = pos;
            line_end.x += 250;
            ImDrawList_AddLine(igGetWindowDrawList(), pos, line_end, Color.white.value, 1);
        } else {
            igSetNextItemWidth(-1);
            if (ogInputText("##input", &todo.label, todo.label.len)) {
                // TODO: why does windows not properly handle 0-terminated strings?
                todo.label[24] = 0;
            }
        }
    }
}

fn shutdown() void {
    upaya.fs.savePrefsJson("upaya-todo", "todos.json", state) catch unreachable;
}

fn setupDockLayout(id: ImGuiID) void {
    igDockBuilderDockWindow("ToDos", id);
    igDockBuilderFinish(id);
}

// Menu callbacks
fn onQuit() void {
    upaya.quit();
}

fn onNew() void {
    state.addToDo();
}
