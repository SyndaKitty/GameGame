package main

import gl "vendor:OpenGL"

Renderer :: struct {
    program: u32,
}

Program :: struct {
    handle: u32,
    uniforms: gl.Uniforms,
}

main_program: Program

setup_opengl :: proc() {
    gl.load_up_to(4, 6, get_proc_address)
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)

    main_program = create_program("shaders/vertex.glsl", "shaders/fragment.glsl")
}

create_program :: proc() -> Program {
    program: Program

    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    fragment_source := string(#load("shaders/fragment.glsl"));
    fragment_source_len := i32(len(fragment_source))
    fragment_source_data := cstring(raw_data(fragment_source))
    gl.ShaderSource(fragment_shader, 1, &fragment_source_data, &fragment_source_len)
    gl.CompileShader(fragment_shader);

    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    vertex_source := string(#load("shaders/vertex.glsl"))
    vertex_source_len := i32(len(vertex_source))
    vertex_source_data := cstring(raw_data(vertex_source))
    gl.ShaderSource(vertex_shader, 1, &vertex_source_data, &vertex_source_len)
    gl.CompileShader(vertex_shader)

    program.handle = gl.CreateProgram()
    gl.AttachShader(res.handle, fragment_shader)
    gl.AttachShader(res.handle, vertex_shader)
    gl.LinkProgram(res.handle)

    gl.DetachShader(res.handle, fragment_shader)
    gl.DetachShader(res.handle, vertex_shader)
    gl.DeleteShader(fragment_shader)
    gl.DeleteShader(vertex_shader)

    program.uniforms = gl.get_uniforms_from_program(program.handle)
}