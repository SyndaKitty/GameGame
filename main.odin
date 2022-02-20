package main

import "core:fmt"
import "core:runtime"
import "core:math"

import "vendor:glfw"
import gl "vendor:OpenGL"

import "log"
import "data"

window: glfw.WindowHandle
sprite_a: ^data.Entity
sprite_b: ^data.Entity
running := b32(true)

main :: proc() {
    log.should_log_to_console(true)

    glfw.Init()
    window = glfw.CreateWindow(800, 800, "GameGame", nil, nil)

    if window == nil {
        log.write("Unable to create window")
        return
    }

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)
    glfw.SetKeyCallback(window, key_callback)
    glfw.SetFramebufferSizeCallback(window, size_callback)

    if !setup_opengl() {
        log.write("Unable to setup OpenGL")
        return
    }

    init()

    for !glfw.WindowShouldClose(window) && running {
        update()
        draw()
        glfw.PollEvents()
    }
    exit()
}

init :: proc() {
    log.write("init")
    sprite_a = create_entity()
    sprite_a.x = -0.5
    sprite_a.y = 0
    sprite_a.texture = load_texture("sprites/sprite.png")

    sprite_b = create_entity()
    sprite_b.x = 0.5
    sprite_b.y = 0
    sprite_b.texture = load_texture("sprites/sprite2.png")
}

update :: proc() {
    t := f32(glfw.GetTime())
    sprite_a.transform = translation(sprite_a.x, sprite_a.y) * rotation(t) * scale(math.sin(t))
    sprite_b.transform = translation(sprite_b.x, sprite_b.y) * rotation(-t) * scale(math.sin(t + math.PI / 2))
}

draw :: proc() {
    start_frame()
    draw_entity(sprite_a)
    draw_entity(sprite_b)
    end_frame()
}

exit :: proc() {
    log.write("exit")
}

create_entity :: proc() -> ^data.Entity {
    return new(data.Entity)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
    if action == 2 { // Ignore repeat
        return
    }
    if key == glfw.KEY_ESCAPE {
        running = false
    }
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height)
    // TODO redraw
}

rotation :: proc(theta: f32) -> matrix[4, 4]f32 {
    c := math.cos(theta);
    s := math.sin(theta);

    return matrix[4, 4]f32 {
        c,-s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
}

translation :: proc(x, y: f32) -> matrix[4, 4]f32 {
    return matrix[4, 4]f32 {
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
}

scale :: proc(s: f32) -> matrix[4, 4]f32 {
    return matrix[4, 4]f32 {
        s, 0, 0, 0,
        0, s, 0, 0,
        0, 0, s, 0,
        0, 0, 0, 1,
    };
}