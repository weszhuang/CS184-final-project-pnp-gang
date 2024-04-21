#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;

/* DRAWBUFFERS:012 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bufNormal;
layout(location = 2) out vec4 buflmcoord;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	// color *= texture(lightmap, lmcoord);
	if (color.a < 0.1) {
		discard;
	}
	bufNormal = vec4(normal*0.5f + 0.5f, 1.0f);
	buflmcoord = vec4(lmcoord, 0.0f, 1.0f);
}