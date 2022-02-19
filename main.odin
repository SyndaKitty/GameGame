package main

import "core:fmt"
import "core:runtime"

import "vendor:glfw"
import gl "vendor:OpenGL"

window: glfw.WindowHandle

Entity :: struct {
    x: f32,
    y: f32,    
}

main :: proc() {
    glfw.Init()
    window = glfw.CreateWindow(800, 800, "GameGame", nil, nil)

    if window == nil {
        fmt.println("Unable to create window")
        glfw.Terminate()
    }

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)
    glfw.SetKeyCallback(window, key_callback)
    glfw.SetFramebufferSizeCallback(window, size_callback)

    setup_opengl()
    setup()

    for !glfw.WindowShouldClose(window) {
        gl.Clear(gl.COLOR_BUFFER_BIT)
        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}

sprite: ^Entity

setup :: proc() {
    sprite := create_entity()
    sprite.x = 400
    sprite.y = 400

    load_gltexture(load_texture("sprites/sprite.png"), 0)
}

create_entity :: proc() -> ^Entity {
    return new(Entity)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
    
    if action == 2 {
        return
    }
    context = runtime.default_context()

    if action == 0 {
        fmt.println("Key pressed:", rune(key))
    }
    else if action == 1 {
        fmt.println("Key release:", rune(key))
    }
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height)
    // TODO redraw
}