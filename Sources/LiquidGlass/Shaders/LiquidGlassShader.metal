#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float time;
    float2 boxSize;
    float cornerRadius;
};

float sdRoundedRect(float2 pos, float2 halfSize, float4 cornerRadius) {
    cornerRadius.xy = (pos.x > 0.0) ? cornerRadius.xy : cornerRadius.zw;
    cornerRadius.x  = (pos.y > 0.0) ? cornerRadius.x  : cornerRadius.y;

    float2 q = abs(pos) - halfSize + cornerRadius.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - cornerRadius.x;
}

float boxSDF(float2 uv, float2 boxSize, float cornerRadius) {
    return sdRoundedRect(uv, boxSize * 0.5, float4(cornerRadius));
}

float2 randomVec2(float2 co) {
    return fract(sin(float2(
        dot(co, float2(127.1, 311.7)),
        dot(co, float2(269.5, 183.3))
    )) * 43758.5453);
}

float3 sampleWithNoise(float2 uv, float timeOffset, float mipLevel,
                       texture2d<float> iChannel0, sampler iChannel0Sampler,
                       constant Uniforms &uniforms) {
    float2 offset = randomVec2(uv + float2(uniforms.time + timeOffset)) / uniforms.resolution.x;
    float lod = mipLevel - 1.0;
    return iChannel0.sample(iChannel0Sampler, uv + offset * pow(2.0, mipLevel), level(lod)).rgb;
}

float3 getBlurredColor(float2 uv, float mipLevel,
                       texture2d<float> iChannel0, sampler iChannel0Sampler,
                       constant Uniforms &uniforms) {
    return (
        sampleWithNoise(uv, 0.0, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 0.25, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 0.5, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 0.75, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 1.0, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 1.25, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 1.5, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 1.75, mipLevel, iChannel0, iChannel0Sampler, uniforms) +
        sampleWithNoise(uv, 2.0, mipLevel, iChannel0, iChannel0Sampler, uniforms)
    ) * 0.1;
}

float3 saturateColor(float3 color, float factor) {
    float gray = dot(color, float3(0.299, 0.587, 0.114));
    return mix(float3(gray), color, factor);
}

float2 computeRefractOffset(float sdf) {
    if (sdf < 0.1) return float2(0.0);

    float2 grad = normalize(float2(dfdx(sdf), dfdy(sdf)));
    float offsetAmount = pow(abs(sdf), 12.0) * -0.1;
    return grad * offsetAmount;
}

float highlight(float sdf) {
    if (sdf < 0.1) return 0.0;

    float2 grad = normalize(float2(dfdx(sdf), dfdy(sdf)));
    return 1.0 - clamp(pow(1.0 - abs(dot(grad, float2(-1.0, 1.0))), 0.5), 0.0, 1.0);
}

fragment float4 liquidGlassFragment(VertexOut in [[stage_in]],
                                    constant Uniforms &uniforms [[buffer(0)]],
                                    texture2d<float> iChannel0 [[texture(0)]],
                                    sampler iChannel0Sampler [[sampler(0)]]) {

    float2 fragCoord = in.uv * uniforms.resolution;
    float2 centeredUV = fragCoord - uniforms.resolution * 0.5;
    
    float sdf = boxSDF(centeredUV, uniforms.boxSize, uniforms.cornerRadius);

    float normalizedInside = (sdf / uniforms.boxSize.y) + 1.0;
    float edgeBlendFactor = pow(normalizedInside, 12.0);

    float3 baseTex = iChannel0.sample(iChannel0Sampler, in.uv).rgb;

    float2 sampleUV = in.uv + computeRefractOffset(normalizedInside);
    float mipLevel = mix(3.5, 1.5, edgeBlendFactor);

    float3 blurredTex = getBlurredColor(sampleUV, mipLevel, iChannel0, iChannel0Sampler, uniforms) * 0.8 + 0.2;
    blurredTex = mix(blurredTex, pow(saturateColor(blurredTex, 2.0), float3(0.5)), edgeBlendFactor);

    blurredTex += mix(0.0, 0.5, clamp(highlight(normalizedInside) * pow(edgeBlendFactor, 5.0), 0.0, 1.0));

    float boxMask = 1.0 - clamp(sdf, 0.0, 1.0);

    float3 finalColor = mix(baseTex, blurredTex, float3(boxMask));

    return float4(finalColor, 1.0);
}

vertex VertexOut vertexPassthrough(uint vertexID [[vertex_id]]) {
    float2 positions[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = positions[vertexID] * 0.5 + 0.5;
    return out;
}
