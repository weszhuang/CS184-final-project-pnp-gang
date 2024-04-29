vec2 parallaxMapping(in vec2 texCoord, in vec3 viewDir, in sampler2D depthMap, in vec4 textureBounds, in vec2 textureSize){
    float height = 1.0 - texture(depthMap, texCoord).a;
    if (height < 0.0001){
        return texCoord;
    }
    vec2 p = viewDir.xy / viewDir.z * (height * max(textureSize.x, textureSize.y) * 0.25);
    return textureBounds.st + mod(texCoord - p - textureBounds.st, textureSize);
}