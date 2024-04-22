#version 330 compatibility

#include "/include/distort.glsl"

out vec2 texcoord;
out vec4 color;

void main(){
    gl_Position = ftransform();
    gl_Position.xy = distortPosition(gl_Position.xy);
    texcoord = gl_MultiTexCoord0.xy;
    color = gl_Color;
}