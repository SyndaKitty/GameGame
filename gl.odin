package main

import "core:os"

import gl "vendor:OpenGL"
import stbi "vendor:stb/image"
import "vendor:glfw"

import "log"

Renderer :: struct {
    program: u32,
}

Program :: struct {
    handle: u32,
    uniforms: gl.Uniforms,
}

Texture :: struct {
    width: i32,
    height: i32,
    channels: i32,
    data: ^byte,
}

GLTexture :: struct {
    using texture: Texture,
    unit: u32,
    handle: u32,
}

main_program: Program

get_proc_address :: proc(p: rawptr, name: cstring) {
    (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
}

setup_opengl :: proc() -> bool {
    gl.load_up_to(3, 0, get_proc_address)
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)

    main_program = create_program("shaders/vertex.glsl", "shaders/fragment.glsl") or_return

    return true
}

load_texture :: proc(filename: string) -> Texture {
    res: Texture
    res.data = stbi.load(cstring(raw_data(filename)), &res.width, &res.height, &res.channels, 4)
    return res
}

load_gltexture :: proc(texture: Texture, unit: u32) -> GLTexture {
    res: GLTexture
    res.texture = texture
    res.unit = unit
    gl.GenTextures(1, &res.handle)
    
    gl.ActiveTexture(unit)
    gl.BindTexture(gl.TEXTURE_2D, res.handle)

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texture.width, texture.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture.data)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    return res
}

create_program :: proc(vertex_path, fragment_path: string) -> (Program, bool) {
    fragment_source, vertex_source: []byte
    ok: bool
    program: Program

    fragment_source, ok = os.read_entire_file(fragment_path)
    defer delete(fragment_source)
    if !ok {
        log.write("Unable to load fragment shader:", fragment_path)
        return program, ok
    }
    vertex_source, ok = os.read_entire_file(vertex_path)
    defer delete(vertex_source)
    if !ok {
        log.write("Unable to load vertex shader:", vertex_path)
        return program, ok
    }

    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    fragment_source_len := i32(len(fragment_source))
    fragment_source_data := cstring(raw_data(fragment_source))
    gl.ShaderSource(fragment_shader, 1, &fragment_source_data, &fragment_source_len)
    gl.CompileShader(fragment_shader)

    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    vertex_source_len := i32(len(vertex_source))
    vertex_source_data := cstring(raw_data(vertex_source))
    gl.ShaderSource(vertex_shader, 1, &vertex_source_data, &vertex_source_len)
    gl.CompileShader(vertex_shader)

    program.handle = gl.CreateProgram()
    gl.AttachShader(program.handle, fragment_shader)
    gl.AttachShader(program.handle, vertex_shader)
    gl.LinkProgram(program.handle)

    gl.DetachShader(program.handle, fragment_shader)
    gl.DetachShader(program.handle, vertex_shader)
    gl.DeleteShader(fragment_shader)
    gl.DeleteShader(vertex_shader)

    program.uniforms = gl.get_uniforms_from_program(program.handle)

    return program, ok
}