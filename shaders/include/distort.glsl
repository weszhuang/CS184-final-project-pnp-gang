vec2 distortPosition(in vec2 position){
    float centerDistance = length(position);
    float distortionFactor = mix(1.0f, centerDistance, 0.9f);
    return position / distortionFactor;
}
