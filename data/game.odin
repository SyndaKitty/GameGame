package data

Entity :: struct {
    x: f32,
    y: f32,
    texture: Texture,
    transform: matrix[4, 4]f32,
}

Texture :: struct {
    width: i32,
    height: i32,
    channels: i32,
    data: ^byte,
}