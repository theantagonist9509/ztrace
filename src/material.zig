const Color = @Vector(3, f32);

pub const Material = struct {
    color: Color,
    shininess: f32,
};
