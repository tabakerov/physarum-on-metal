//
//  Shaders.metal
//  streamProjectOne
//
//  Created by Dmitry Tabakerov on 27.01.21.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float2 uv;
};

kernel void kernel_function(texture2d<uint, access::write> texture [[texture(0)]],
                            uint index [[thread_position_in_grid]]) {
    texture.write(1, uint2(50, 50));
}

vertex Vertex vertex_function(constant float4 *vertices [[buffer(0)]],
                              uint id [[vertex_id]]) {
    return {
        .position = vertices[id],
        .uv =  (vertices[id].xy + float2(1)) / float2(2)
    };
}

fragment float4 fragment_function(Vertex v [[stage_in]],
                                  texture2d<uint> texture [[texture(0)]]) {
    constexpr sampler smplr(coord::normalized,
                            address::clamp_to_zero,
                            filter::nearest);
    uint c = texture.sample(smplr, v.uv).r;
    return float4(c, 0.0, 0.0, 1.0);
};
