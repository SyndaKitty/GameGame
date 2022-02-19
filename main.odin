package main

import "core:fmt"
import "core:runtime"

import "vendor:glfw"
import gl "vendor:OpenGL"

window: glfw.WindowHandle

main :: proc() {
    glfw.Init()
    window = glfw.CreateWindow(600, 600, "GameGame", nil, nil)

    if window == nil {
        fmt.println("Unable to create window")
        glfw.Terminate()
    }

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)
    glfw.SetKeyCallback(window, key_callback)
    glfw.SetFramebufferSizeCallback(window, size_callback)

    setup_opengl()

    for !glfw.WindowShouldClose(window) {
        gl.Clear(gl.COLOR_BUFFER_BIT)
        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}

get_proc_address :: proc(p: rawptr, name: cstring) {
    (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
    context = runtime.default_context()

    fmt.println("Key pressed:", key, scancode, action, mods)
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height)
    // TODO redraw
}