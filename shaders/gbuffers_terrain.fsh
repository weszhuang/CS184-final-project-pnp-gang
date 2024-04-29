#version 330 compatibility
#include "include/settings.glsl"

uniform vec3 cameraPosition;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D normals;
// uniform sampler2D specular;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 bitangent, tangent;
in vec3 viewDir;
in vec4 textureBounds;
in vec2 singleTexSize;

/* DRAWBUFFERS:012 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bufNormal;
layout(location = 2) out vec4 buflmcoord;

#include "include/parallax.glsl"

void main() {
	mat3 tbnMatrix = mat3(tangent.x, bitangent.x, normal.x,
							tangent.y, bitangent.y, normal.y,
							tangent.z, bitangent.z, normal.z);
	vec3 tangentViewPos = tbnMatrix * cameraPosition;
	vec2 newCoord = parallaxMapping(texcoord, viewDir, normals, textureBounds, singleTexSize);
	// vec2 newCoord = texcoord;
	color = texture(gtexture, newCoord) * glcolor;
	if (color.a < 0.1) {
		discard;
	}
	vec3 normalMap = vec3(texture(normals, newCoord).xy, 0.0) * 2.0 - 1.0;
	float ambientOcclusion = texture(normals, newCoord).z;
	if (normalMap.x + normalMap.y > -1.999) {
        if (length(normalMap.xy) > 1.0) normalMap.xy = normalize(normalMap.xy);
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
    }else{
        normalMap = vec3(0.0, 0.0, 1.0);
		ambientOcclusion = 1.0;
    }
	color *= ambientOcclusion * ambientOcclusion;
	normalMap = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
	bufNormal = vec4(normalMap*0.5f + 0.5f, 1.0f);
	buflmcoord = vec4(lmcoord, 0.0f, 1.0f);
}