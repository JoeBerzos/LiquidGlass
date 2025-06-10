#include <metal_stdlib>
using namespace metal;

// ──────────────────────────────────────────
// Vertex → Fragment interface
struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// ──────────────────────────────────────────
// Constant buffer (buffer(0)) – 16-byte aligned
struct Uniforms {
    float2 resolution;
    float time;
    float blurScale;
    float2 boxSize;
    float cornerRadius;
};

// ──────────────────────────────────────────
// Signed-distance helpers
float sdRoundedRect(float2 pos, float2 halfSize, float4 cornerRadius) {
    cornerRadius.xy = (pos.x > 0.0) ? cornerRadius.xy : cornerRadius.zw;
    cornerRadius.x = (pos.y > 0.0) ? cornerRadius.x : cornerRadius.y;

    float2 q = abs(pos) - halfSize + cornerRadius.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - cornerRadius.x;
}

float boxSDF(float2 uv, float2 boxSize, float cornerRadius) {
    return sdRoundedRect(uv, boxSize * 0.5, float4(cornerRadius));
}

// ──────────────────────────────────────────
// Noise-based jitter for cheap blur
float2 randomVec2(float2 co) {
    return fract(sin(float2(
        dot(co, float2(127.1, 311.7)),
        dot(co, float2(269.5, 183.3))
    )) * 43758.5453);
}

float3 sampleWithNoise(float2 uv, float timeOffset, float mipLevel,
                       texture2d<float> tex, sampler samp,
                       constant Uniforms &u) {
    float2 offset = randomVec2(uv + float2(u.time + timeOffset)) / u.resolution.x;
    float lod = mipLevel - 1.0;
    return tex.sample(samp, uv + offset * pow(2.0, mipLevel), level(lod)).rgb;
}

// Gaussian-ish blur using 9 taps
float3 getBlurredColor(float2 uv, float mipLevel,
                       texture2d<float> tex, sampler samp,
                       constant Uniforms &u) {
    float3 c = 0.0;
    c += sampleWithNoise(uv, 0.0, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 0.25, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 0.5, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 0.75, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 1.0, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 1.25, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 1.5, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 1.75, mipLevel, tex, samp, u);
    c += sampleWithNoise(uv, 2.0, mipLevel, tex, samp, u);
    return c * (1.0 / 9.0);
}

// Colour helpers
float3 saturateColor(float3 color, float factor) {
    float gray = dot(color, float3(0.299, 0.587, 0.114));
    return mix(float3(gray), color, factor);
}

// Refraction offset based on SDF
float2 computeRefractOffset(float sdf) {
    if (sdf < 0.1) return float2(0.0);

    float2 grad = normalize(float2(dfdx(sdf), dfdy(sdf)));
    float offsetAmount = pow(abs(sdf), 12.0) * -0.1;
    return grad * offsetAmount;
}

// Edge highlight for glossy rim
float highlight(float sdf) {
    if (sdf < 0.1) return 0.0;

    float2 grad = normalize(float2(dfdx(sdf), dfdy(sdf)));
    return 1.0 - clamp(pow(1.0 - abs(dot(grad, float2(-1.0, 1.0))), 0.5), 0.0, 1.0);
}

// ──────────────────────────────────────────
// Fragment shader
fragment float4 liquidGlassFragment(VertexOut in [[stage_in]],
                                    constant Uniforms& u[[buffer(0)]],
                                    texture2d<float> iChannel0 [[texture(0)]],
                                    sampler iChannel0Sampler [[sampler(0)]]) {
    float2 fragCoord = in.uv * u.resolution;
    float2 centeredUV = fragCoord - u.resolution * 0.5;
    float sdf = boxSDF(centeredUV, u.boxSize, u.cornerRadius);

    float normalizedInside = (sdf / u.boxSize.y) + 1.0;
    float edgeBlendFactor  = pow(normalizedInside, 12.0);

    // Sharp background
    float2 uvTex = float2(in.uv.x, 1.0 - in.uv.y);
    float3 baseTex = iChannel0.sample(iChannel0Sampler, uvTex).rgb;

    // Blur strength via blurScale
    float s = u.blurScale;
    float mipLevel = mix(0.0, 6.0, pow(s, 1.8));
    float weight = pow(s, 1.5);

    float2 sampleUV = uvTex + computeRefractOffset(normalizedInside);
    float3 blurred = getBlurredColor(sampleUV, mipLevel, iChannel0, iChannel0Sampler, u);

    // Mix sharp/blurred by blurScale
    float3 mixed = mix(baseTex, blurred, weight);
    mixed = mix(mixed, pow(saturateColor(mixed, 2.0), float3(0.5)), edgeBlendFactor * weight);

    // Rim light
    mixed += weight * mix(0.0, 0.5, clamp(highlight(normalizedInside) * pow(edgeBlendFactor, 5.0), 0.0, 1.0));

    // Inside mask
    float boxMask = 1.0 - clamp(sdf, 0.0, 1.0);
    float3 final  = mix(baseTex, mixed, float3(boxMask));

    return float4(final, 1.0);
}

// ──────────────────────────────────────────
// Pass-through vertex
vertex VertexOut vertexPassthrough(uint vertexID [[vertex_id]]) {
    float2 positions[6] = {
        float2(-1.0, -1.0), float2( 1.0, -1.0), float2(-1.0,  1.0),
        float2(-1.0,  1.0), float2( 1.0, -1.0), float2( 1.0,  1.0)
    };
    VertexOut v;
    v.position = float4(positions[vertexID], 0.0, 1.0);
    v.uv = positions[vertexID] * 0.5 + 0.5;
    return v;
}
