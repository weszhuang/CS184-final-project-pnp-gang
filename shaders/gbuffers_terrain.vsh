#version 330 compatibility
uniform vec3 cameraPosition;  
uniform mat4 gbufferModelView;
in vec4 at_tangent;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 bitangent, tangent;
out vec3 vertex_position; 

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = (lmcoord * 33.05f / 32.0f) - (1.05f / 32.0f);
	glcolor = gl_Color;
	bitangent = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	normal = gl_NormalMatrix * gl_Normal;
	vertex_position =  gl_Position.xyz;
}