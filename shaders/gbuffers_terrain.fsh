#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform vec3 sunPosition;
uniform vec3 cameraPosition;  

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 vertex_position; 
in vec3 bitangent, tangent;

/* DRAWBUFFERS:012 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bufNormal;
layout(location = 2) out vec4 buflmcoord;

vec3 computeSpecular(vec3 lightDirTS, vec3 viewDirTS, vec3 normalTS, float shininess, vec3 specularColor) {
    vec3 reflectDirTS = reflect(-lightDirTS, normalTS);
    float specularIntensity = pow(max(dot(reflectDirTS, viewDirTS), 0.1), shininess);
    return specularColor * specularIntensity;
}

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	// color *= texture(lightmap, lmcoord);
	if (color.a < 0.1) {
		discard;
	}
	vec3 normalMap = vec3(texture(normals, texcoord).xy, 0.0) * 2.0 - 1.0;
	float ambientOcclusion = texture(normals, texcoord).z;
	if (normalMap.x + normalMap.y > -1.999) {
        if (length(normalMap.xy) > 1.0) normalMap.xy = normalize(normalMap.xy);
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
    }else{
        normalMap = vec3(0.0, 0.0, 1.0);
		ambientOcclusion = 1.0;
    }
	color *= ambientOcclusion * ambientOcclusion;
	mat3 tbnMatrix = mat3(tangent.x, bitangent.x, normal.x,
							tangent.y, bitangent.y, normal.y,
							tangent.z, bitangent.z, normal.z);
	normalMap = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
	bufNormal = vec4(normalMap*0.5f + 0.5f, 1.0f);
	buflmcoord = vec4(lmcoord, 0.0f, 1.0f);

	vec3 vertex_position_tangent = (vertex_position * tbnMatrix).xyz;
	vec3 camera_position_tangent = (cameraPosition * tbnMatrix).xyz; 
	vec3 normal_tangent = (normal * tbnMatrix).xyz; 
	vec3 viewDir = normalize(camera_position_tangent - vertex_position_tangent);
	vec3 lightDir = sunPosition * tbnMatrix; 
    vec4 specularColor = texture(specular, texcoord);
    float specularIntensity = specularColor.g;

	vec3 Specular_contribution = clamp(computeSpecular(lightDir, viewDir, normal_tangent, 0.4, specularColor.rgb), 0, 1);
    color.rgb += Specular_contribution;

}