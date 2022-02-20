#version 330 core
out vec4 FragColor;
in vec2 vertexUV;
uniform sampler2D MainTex;

void main()
{
    vec4 tex1 = texture(MainTex, vertexUV);
	FragColor = tex1;

	if (tex1.a < 0.1) discard;
}