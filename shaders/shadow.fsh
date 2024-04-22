#version 330 compatibility

in vec2 texcoord;
in vec4 color;

uniform sampler2D texture;

void main() {
    gl_FragData[0] = texture2D(texture, texcoord) * color;
}