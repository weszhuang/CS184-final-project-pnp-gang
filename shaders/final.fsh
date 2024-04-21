#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

void main() {
    // Sample the color
   vec3 Color = pow(texture(colortex0, texcoord).rgb, vec3(1.0f / 2.2f));
   // Output the color
   gl_FragColor = vec4(Color, 1.0f);
}