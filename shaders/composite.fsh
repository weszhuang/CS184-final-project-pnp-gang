#version 330 compatibility

#include "/include/distort.glsl"

uniform vec3 sunPosition;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

in vec2 texcoord;

const float sunPathRotation = -40.0f;
const int shadowMapResolution = 2048;

const float ambient = 0.02f;

float visibiliity(in sampler2D shadowMap, in vec3 sampleCoords) {
	return step(sampleCoords.z - 0.001f, texture(shadowMap, sampleCoords.xy).r);
}

vec3 transparentShadow(in vec3 sampleCoords){
	float shadowVisibility0 = visibiliity(shadowtex0, sampleCoords);
	float shadowVisibility1 = visibiliity(shadowtex1, sampleCoords);
	vec4 shadowColor0 = texture(shadowcolor0, sampleCoords.xy);
	vec3 transmittedColor = shadowColor0.rgb * (1.0f - shadowColor0.a);
	return mix(transmittedColor * shadowVisibility1, vec3(1.0f), shadowVisibility0);
}

vec3 getShadow(float depth){
    vec3 clipSpace = vec3(texcoord, depth) * 2.0f - 1.0f;
	vec4 viewW = gbufferProjectionInverse * vec4(clipSpace, 1.0f);
	vec3 view = viewW.xyz / viewW.w;
	vec4 world = gbufferModelViewInverse * vec4(view, 1.0f);
	vec4 shadowSpace = shadowProjection * shadowModelView * world;
	shadowSpace.xy = distortPosition(shadowSpace.xy);
	vec3 sampleCoords = shadowSpace.xyz * 0.5f + 0.5f;
	return transparentShadow(sampleCoords);
}

float adjustLightmapTorch(in float torch) {
	const float k = 2.0f;
	const float p = 5.06f;
	return k * pow(torch, p);
}

float adjustLightMapSky(in float sky){
	float sky_2 = sky * sky;
	return sky_2 * sky_2;
}

vec2 adjustLightMap(in vec2 lightMap){
	vec2 newLightMap;
	newLightMap.x = adjustLightmapTorch(lightMap.x);
	newLightMap.y = adjustLightMapSky(lightMap.y);
	return newLightMap;
}

vec3 getLightMapColor(in vec2 lightMap){
	lightMap = adjustLightMap(lightMap);
	const vec3 torchColor = vec3(1.0f, 0.25f, 0.08f);
	const vec3 skyColor = vec3(0.05f, 0.15f, 0.3f);
	vec3 lightMapLighting = torchColor * lightMap.x + skyColor * lightMap.y;
	return lightMapLighting;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color;

void main() {
	vec3 albedo = pow(texture(colortex0, texcoord).rgb, vec3(2.2f));
	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0f) {
		color = vec4(albedo, 1.0f);
		return;
	}
	vec3 normal = normalize(texture(colortex1, texcoord).rgb * 2.0f - 1.0f);
	vec2 lightMap = texture(colortex2, texcoord).rg;
	vec3 lightMapColor = getLightMapColor(lightMap);

	float normDotL = max(dot(normal, normalize(sunPosition)), 0.0f);
	vec3 diffuse = albedo * (lightMapColor + normDotL * getShadow(depth) + ambient);
	color = vec4(diffuse, 1.0f);
}