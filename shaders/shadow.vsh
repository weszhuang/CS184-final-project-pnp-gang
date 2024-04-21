#version 330 compatibility

#include "/include/distort.glsl"

void main(){
    gl_Position = ftransform();
    gl_Position.xy = distortPosition(gl_Position.xy);
}