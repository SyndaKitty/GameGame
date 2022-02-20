package main

import "core:os"

import gl "vendor:OpenGL"
import stbi "vendor:stb/image"
import "vendor:glfw"

import "log"
import "data"

Renderer :: struct {
    program: u32,
}

Program :: struct {
    handle: u32,
    uniforms: gl.Uniforms,
}

GLTexture :: struct {
    using texture: data.Texture,
    unit: u32,
    handle: u32,
}

main_program: Program
max_texture_units: i32
textures: []GLTexture
vao: u32;
vbo: u32;
ebo: u32;

rectangle_vertices := [?]f32 {
    // positions      uvs
     0.5,  0.5, 0.0,  1.0, 1.0,
     0.5, -0.5, 0.0,  1.0, 0.0,
    -0.5, -0.5, 0.0,  0.0, 0.0,
    -0.5,  0.5, 0.0,  0.0, 1.0,
}

rectangle_indices := [?]u32 {
    0, 1, 3,
    1, 2, 3,
}

get_proc_address :: proc(p: rawptr, name: cstring) {
    (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
}

get_limits :: proc() {
    log.write(args={"Loaded OpenGL: ", gl.loaded_up_to[0], ".", gl.loaded_up_to[1]}, sep="")
    
    gl.GetIntegerv(gl.MAX_TEXTURE_IMAGE_UNITS, &max_texture_units)
    log.write("MAX_TEXTURE_IMAGE_UNITS:", max_texture_units)

    max_combined_texture_units: i32
    gl.GetIntegerv(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS, &max_combined_texture_units)
    log.write("MAX_COMBINED_TEXTURE_IMAGE_UNITS:", max_combined_texture_units)
}

setup_opengl :: proc() -> bool {
    gl.load_up_to(3, 3, get_proc_address)
    
    get_limits()
    setup_buffers()

    textures = make([]GLTexture, max_texture_units)
    for i in 0..<max_texture_units {
        gl.GenTextures(1, &textures[i].handle)
    }

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, textures[0].handle)

    gl.ClearColor(0.2, 0.3, 0.3, 1.0)


    main_program = create_program("shaders/vertex.glsl", "shaders/fragment.glsl") or_return

    return true
}

setup_buffers :: proc() {
    gl.GenVertexArrays(1, &vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)

    gl.BindVertexArray(vao)
    
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(rectangle_vertices) * size_of(f32), &rectangle_vertices, gl.STATIC_DRAW)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 5 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, 5 * size_of(f32), uintptr(3 * size_of(f32)))
    gl.EnableVertexAttribArray(1)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(rectangle_indices) * size_of(u32), &rectangle_indices, gl.STATIC_DRAW)
}

load_texture :: proc(filename: string) -> data.Texture {
    res: data.Texture
    stbi.set_flip_vertically_on_load(1)
    res.data = stbi.load(cstring(raw_data(filename)), &res.width, &res.height, &res.channels, 4)
    return res
}

create_program :: proc(vertex_path, fragment_path: string) -> (program: Program, ok: bool) {
    program.handle = gl.load_shaders_file(vertex_path, fragment_path) or_return
    program.uniforms = gl.get_uniforms_from_program(program.handle)

    return program, true
}

start_frame :: proc() {
    gl.Clear(gl.COLOR_BUFFER_BIT)
    gl.BindVertexArray(vao)
}

draw_entity :: proc(entity: ^data.Entity, program := main_program) {
    draw_texture(entity.texture, &entity.transform, program)
}

draw_texture :: proc(texture: data.Texture, transform: ^matrix[4, 4]f32, program := main_program) {
    // gl.ActiveTexture(gl.TEXTURE0)
    // log.write("ActiveTexture", gl.GetError())
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texture.width, texture.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture.data)
    // log.write("TexImage2D", gl.GetError())
    gl.GenerateMipmap(gl.TEXTURE_2D)
    // log.write("GenerateMipMap", gl.GetError())
    gl.UseProgram(program.handle)
    // log.write("UseProgram", gl.GetError())
    gl.Uniform1i(program.uniforms["MainTex"].location, 0)
    // log.write("Uniform1i", gl.GetError())
    gl.UniformMatrix4fv(program.uniforms["transform"].location, 1, false, &transform[0, 0])
    // log.write("UniformMatrix4fv", gl.GetError())
    gl.DrawElements(gl.TRIANGLES, len(rectangle_indices), gl.UNSIGNED_INT, nil)
    // log.write("DrawElements", gl.GetError())
}

end_frame :: proc() {
    glfw.SwapBuffers(window)
}