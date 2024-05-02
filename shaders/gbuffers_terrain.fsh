#version 330 compatibility
#include "include/settings.glsl"

uniform vec3 cameraPosition;
uniform vec3 sunPosition;

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 bitangent, tangent;
in vec3 viewDir;
in vec2 screenCoord;
in vec4 textureBounds;
in vec2 singleTexSize;
in vec4 shadowPos;

const float sunPathRotation = -40.0f;
const int shadowMapResolution = 2048;
const int noiseTextureResolution = 64;

const float ambient = 0.02f;
const vec3 dayLight = vec3(255, 160, 80) * 1.2 / 255.0;

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

#define SHADOW_SAMPLES 2
const int shadowSamplesPerSize = 2 * SHADOW_SAMPLES + 1;
const int totalSamples = shadowSamplesPerSize * shadowSamplesPerSize;

vec3 getShadow(vec4 shadowPos){
	vec3 sampleCoords = shadowPos.xyz;
	float randomAngle = texture(noisetex, texcoord * 20.0f).r * 100.0f;
	float cosTheta = cos(randomAngle);
	float sinTheta = sin(randomAngle);
	mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution;
	vec3 shadowAccum = vec3(0.0f);
    for(int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++){
        for(int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++){
            vec2 offset = rotation * vec2(x, y);
            vec3 currentSampleCoordinate = vec3(sampleCoords.xy + offset, sampleCoords.z);
            shadowAccum += transparentShadow(currentSampleCoordinate);
        }
    }
    shadowAccum /= totalSamples;
	return shadowAccum;
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

vec3 computeSpecular(vec3 lightDirTS, vec3 viewDirTS, vec3 normalDirTS, vec2 specularInfo, vec3 lightColor){
	vec3 reflectDirTS = reflect(lightDirTS, normalDirTS);
	float specularIntensity = 3.0 * specularInfo.g * pow(max(dot(reflectDirTS, viewDirTS), 0.01), specularInfo.r * 64.0);
	return lightColor * specularIntensity;
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color;

#include "include/parallax.glsl"

void main() {
	#ifdef SPLIT_DEMO
	if (screenCoord.x < 0.0){
		color = texture(gtexture, texcoord) * glcolor;
		color *= texture(lightmap, lmcoord);
		if (color.a < 0.1) {
			discard;
		}
		return;
	}
	#endif
	mat3 tbnMatrix = mat3(tangent.x, bitangent.x, normal.x,
							tangent.y, bitangent.y, normal.y,
							tangent.z, bitangent.z, normal.z);
	#ifdef PARALLAX
	vec2 newCoord = parallaxMapping(texcoord, viewDir, normals, textureBounds, singleTexSize);
	#ifdef SPLIT_PARALLAX
	if (screenCoord.x < 0.0){
		newCoord = texcoord;
	}
	#endif
	#else
	vec2 newCoord = texcoord;
	#endif
	color = texture(gtexture, newCoord) * glcolor;
	if (color.a < 0.1) {
		discard;
	}
	color.rgb = pow(color.rgb, vec3(2.2));

	#ifdef NORMAL_MAPPING
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
	color.rgb *= ambientOcclusion * ambientOcclusion;

	vec3 normalWorld = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
	#ifdef SPLIT_NORMAL_MAPPING
	if (screenCoord.x < 0.0){
		normalMap = tbnMatrix * normal;
		normalWorld = normal;
	}
	#endif
	#else
	vec3 normalMap = tbnMatrix * normal;
	vec3 normalWorld = normal;
	#endif

	vec3 sunDirWorld = normalize(sunPosition);
	float normDotL = max(dot(normalWorld, sunDirWorld), 0.0f);
	vec3 lightMapColor = getLightMapColor(lmcoord);
	// Specular lighting
	#ifdef SPECULAR
	vec2 specularInfo = texture(specular, newCoord).rg;
	vec3 specular = dayLight * computeSpecular(normalize(tbnMatrix * sunDirWorld), normalize(viewDir), normalMap, specularInfo, dayLight);
	#ifdef SPLIT_SPECULAR
	if (screenCoord.x < 0.0){
		specular = vec3(0.0);
	}
	#endif
	color.rgb *= (lightMapColor + (normDotL + specular) * getShadow(shadowPos) + ambient);
	#else
	color.rgb *= (lightMapColor + normDotL * getShadow(shadowPos) + ambient);
	#endif
	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));
}