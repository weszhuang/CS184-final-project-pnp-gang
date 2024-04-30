#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

void main() {
   // Output the color
   gl_FragColor = vec4(texture(colortex0, texcoord).rgb, 1.0f);
}