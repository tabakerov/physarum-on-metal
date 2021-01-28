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

struct Particle {
    float2 position;
    float2 direction;
    float3 intensity;
};

struct Uniforms {
    float2x2 MatrixStreight;
    float2x2 MatrixLeftSensor;
    float2x2 MatrixRightSensor;
    float2x2 MatrixLeftTurn;
    float2x2 MatrixRightTurn;
    float2 Dimensions;
};

kernel void compute_function(texture2d<half, access::read_write> texture [[texture(0)]],
                             device Particle *particles [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             uint index [[thread_position_in_grid]]) {

    /*
    const float2x2 streight = float2x2(1.0, 0.0, 0.0, 1.0);
    const float angle = 0.15;
    const float2x2 rot_right = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
    const float2x2 rot_left = float2x2(cos(-angle), -sin(-angle), sin(-angle), cos(-angle));
    const float angle_sample = 0.25;
    const float2x2 sample_rot_right = float2x2(cos(angle_sample), -sin(angle_sample), sin(angle_sample), cos(angle_sample));
    const float2x2 sample_rot_left = float2x2(cos(-angle_sample), -sin(-angle_sample), sin(-angle_sample), cos(-angle_sample));
    */
    
    float2x2 rot;
    
    half l_sample = length(texture.read(uint2(particles[index].position + 1.5*(uniforms.MatrixLeftSensor * particles[index].direction))));
    half r_sample = length(texture.read(uint2(particles[index].position + 1.5*(uniforms.MatrixRightSensor * particles[index].direction))));
    half f_sample = length(texture.read(uint2(particles[index].position + 1.5*(particles[index].direction))));
    rot = uniforms.MatrixStreight;
    if (l_sample > r_sample && l_sample > f_sample) {
        rot = uniforms.MatrixLeftTurn;
    }
    if (r_sample > l_sample && r_sample > f_sample) {
        rot = uniforms.MatrixRightTurn;
    }
        
    half4 t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    particles[index].direction = rot * particles[index].direction;
    
    particles[index].position += 0.25 * particles[index].direction;
    particles[index].position.x = fmod(particles[index].position.x + uniforms.Dimensions.x, uniforms.Dimensions.x);
    particles[index].position.y = fmod(particles[index].position.y + uniforms.Dimensions.y, uniforms.Dimensions.y);
    
    t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    
    particles[index].position += 0.25 * particles[index].direction;
    particles[index].position.x = fmod(particles[index].position.x + uniforms.Dimensions.x, uniforms.Dimensions.x);
    particles[index].position.y = fmod(particles[index].position.y + uniforms.Dimensions.y, uniforms.Dimensions.y);
    
    t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    
    particles[index].position += 0.25 * particles[index].direction;
    particles[index].position.x = fmod(particles[index].position.x + uniforms.Dimensions.x, uniforms.Dimensions.x);
    particles[index].position.y = fmod(particles[index].position.y + uniforms.Dimensions.y, uniforms.Dimensions.y);
    
    t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    particles[index].position += 0.25 * particles[index].direction;
    
    particles[index].position.x = fmod(particles[index].position.x + uniforms.Dimensions.x, uniforms.Dimensions.x);
    particles[index].position.y = fmod(particles[index].position.y + uniforms.Dimensions.y, uniforms.Dimensions.y);
}

kernel void blur_function(texture2d<half, access::read_write> texture [[texture(0)]],
                          constant Uniforms &uniforms [[buffer(0)]],
                          uint2 index [[thread_position_in_grid]])
{
    
    uint x0 = (index.x - 1 + int(uniforms.Dimensions.x)) % int(uniforms.Dimensions.y);
    uint x2 = (index.x + 1) % int(uniforms.Dimensions.x);
    uint y0 = (index.y - 1 + int(uniforms.Dimensions.y)) % int(uniforms.Dimensions.y);
    uint y2 = (index.y + 1) % int(uniforms.Dimensions.y);
    half4 out = 1.0/4.0 * texture.read(index)
    + 1.0/8.0 * texture.read(uint2(index.x, y0))
    + 1.0/8.0 * texture.read(uint2(index.x, y2))
    + 1.0/8.0 * texture.read(uint2(x0, index.y))
    + 1.0/8.0 * texture.read(uint2(x2, index.y))
    + 1.0/16.0 * texture.read(uint2(x0, y0))
    + 1.0/16.0 * texture.read(uint2(x2, y0))
    + 1.0/16.0 * texture.read(uint2(x0, y2))
    + 1.0/16.0 * texture.read(uint2(x2, y2));
    texture.write(0.99*half4(out.rgba), index);
    
}

vertex Vertex vertex_function(constant float4 *vertices [[buffer(0)]],
                              uint id [[vertex_id]]) {
    return {
        .position = vertices[id],
        .uv =  (vertices[id].xy + float2(1)) / float2(2)
    };
}

fragment float4 fragment_function(Vertex v [[stage_in]],
                                  texture2d<float> texture [[texture(0)]]) {
    constexpr sampler smplr(coord::normalized,
                            address::clamp_to_zero,
                            filter::nearest);
    return texture.sample(smplr, v.uv);
};
