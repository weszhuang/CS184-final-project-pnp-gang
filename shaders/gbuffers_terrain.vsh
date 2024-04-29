#version 330 compatibility

uniform ivec2 atlasSize;

in vec4 at_tangent;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 bitangent, tangent;
out vec3 viewDir;
out vec4 textureBounds;
out vec2 singleTexSize;

attribute vec4 mc_midTexCoord;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = (lmcoord * 33.05f / 32.0f) - (1.05f / 32.0f);
	glcolor = gl_Color;
	bitangent = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	normal = gl_NormalMatrix * gl_Normal;
	mat3 tbnMatrix = mat3(tangent.x, bitangent.x, normal.x,
							tangent.y, bitangent.y, normal.y,
							tangent.z, bitangent.z, normal.z);
	viewDir = tbnMatrix * normalize((gl_ModelViewMatrix * gl_Vertex).xyz);
	
	vec2 midCoord = (gl_TextureMatrix[0] *  mc_midTexCoord).xy;
	vec2 halfSize      = abs(texcoord - midCoord);
	textureBounds = vec4(midCoord.xy - halfSize, midCoord.xy + halfSize);
	singleTexSize = halfSize * 2.0;
}