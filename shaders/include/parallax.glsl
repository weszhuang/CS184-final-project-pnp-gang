vec2 parallaxMapping(in vec2 texCoord, in vec3 viewDir, in sampler2D depthMap, in vec4 textureBounds, in vec2 textureSize){
    #if !defined PARALLAX || PARALLAX == 0
    return texCoord;

    #elif PARALLAX == 1 //Simple Parallax Mapping
    float height = 1.0 - texture(depthMap, texCoord).a;
    if (height < 0.0001){
        return texCoord;
    }
    vec2 p = viewDir.xy / viewDir.z * (height * max(textureSize.x, textureSize.y) * PARALLAX_DEPTH);
    return textureBounds.st + mod(texCoord - p - textureBounds.st, textureSize);

    #elif PARALLAX == 2 //Steep Parallax Mapping
    vec2 currentTexCoords = texCoord;
    float currentDepthValue = 1.0 - texture(depthMap, currentTexCoords).a;
    if (currentDepthValue < 0.0001){
        return texCoord;
    }
    float layerDepth = 1.0 / PARALLAX_LAYERS;
    float currentDepthLayer = 0.0;
    vec2 deltaTexCoords = ((viewDir.xy / viewDir.z) * PARALLAX_DEPTH) / PARALLAX_LAYERS;
    while(currentDepthLayer < currentDepthValue){
        // This line is bad performance. Consider using denormalized atlas coordinates instead.
        currentTexCoords = textureBounds.st + mod(currentTexCoords - deltaTexCoords - textureBounds.st, textureSize);
        currentDepthValue = 1.0 - texture(depthMap, currentTexCoords).a;
        currentDepthLayer += layerDepth;
    }
    return currentTexCoords;

    #elif PARALLAX == 3 //Parallax Occlusion Mapping
    vec2 currentTexCoords = texCoord;
    float currentDepthValue = 1.0 - texture(depthMap, currentTexCoords).a;
    if (currentDepthValue < 0.0001){
        return texCoord;
    }
    float layerDepth = 1.0 / PARALLAX_LAYERS;
    float currentDepthLayer = 0.0;
    vec2 deltaTexCoords = ((viewDir.xy / viewDir.z) * PARALLAX_DEPTH) / PARALLAX_LAYERS;
    while(currentDepthLayer < currentDepthValue){
        // This line is bad performance. Consider using denormalized atlas coordinates instead.
        currentTexCoords = textureBounds.st + mod(currentTexCoords - deltaTexCoords - textureBounds.st, textureSize);
        currentDepthValue = 1.0 - texture(depthMap, currentTexCoords).a;
        currentDepthLayer += layerDepth;
    }
    vec2 prevTexCoords = currentTexCoords + deltaTexCoords;
    float afterDepth =  currentDepthValue - currentDepthLayer;
    float beforeDepth = 1.0 - texture(depthMap, textureBounds.st + mod(prevTexCoords - textureBounds.st, textureSize)).a - currentDepthLayer + layerDepth;
    float weight = afterDepth / (afterDepth - beforeDepth);
    vec2 finalTexCoords = prevTexCoords * weight + (currentTexCoords) * (1.0 - weight) - deltaTexCoords;
    return textureBounds.st + mod(finalTexCoords - textureBounds.st, textureSize);
    #endif
}