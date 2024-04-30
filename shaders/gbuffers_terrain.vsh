#version 330 compatibility

uniform ivec2 atlasSize;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

in vec4 at_tangent;
in vec4 mc_midTexCoord;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 bitangent, tangent;
out vec3 viewDir;
out vec4 textureBounds;
out vec2 singleTexSize;
out vec4 shadowPos;
#include "include/distort.glsl"

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp((lmcoord * 33.05f / 32.0f) - (1.05f / 32.0f), vec2(0.0), vec2(1.0));
	glcolor = gl_Color;
	bitangent = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	normal = gl_NormalMatrix * gl_Normal;
	mat3 tbnMatrix = mat3(tangent.x, bitangent.x, normal.x,
							tangent.y, bitangent.y, normal.y,
							tangent.z, bitangent.z, normal.z);
	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	viewDir = tbnMatrix * (viewPos).xyz;

	vec2 midCoord = (gl_TextureMatrix[0] *  mc_midTexCoord).xy;
	vec2 halfSize      = abs(texcoord - midCoord);
	textureBounds = vec4(midCoord.xy - halfSize, midCoord.xy + halfSize);
	singleTexSize = halfSize * 2.0;

	vec4 playerPos = gbufferModelViewInverse * viewPos;
	shadowPos = shadowProjection * (shadowModelView * playerPos);
	shadowPos.xy = distortPosition(shadowPos.xy);
	shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
}