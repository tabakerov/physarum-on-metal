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

kernel void compute_function(texture2d<half, access::read_write> texture [[texture(0)]],
                            device Particle *particles [[buffer(0)]],
                            uint index [[thread_position_in_grid]]) {

    
    const float2x2 streight = float2x2(1.0, 0.0, 0.0, 1.0);
    const float angle = 0.15;
    const float2x2 rot_right = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
    const float2x2 rot_left = float2x2(cos(-angle), -sin(-angle), sin(-angle), cos(-angle));
    const float angle_sample = 0.25;
    const float2x2 sample_rot_right = float2x2(cos(angle_sample), -sin(angle_sample), sin(angle_sample), cos(angle_sample));
    const float2x2 sample_rot_left = float2x2(cos(-angle_sample), -sin(-angle_sample), sin(-angle_sample), cos(-angle_sample));
    
    float2x2 rot;
    
    half l_sample = length(texture.read(uint2(particles[index].position + 1.5*(sample_rot_left * particles[index].direction))));
    half r_sample = length(texture.read(uint2(particles[index].position + 1.5*(sample_rot_right * particles[index].direction))));
    half f_sample = length(texture.read(uint2(particles[index].position + 1.5*(particles[index].direction))));
    rot = streight;
    if (l_sample > r_sample && l_sample > f_sample) {
        rot = rot_left;
    }
    if (r_sample > l_sample && r_sample > f_sample) {
        rot = rot_right;
    }
    
    const float dimensions = 2000;
    
    half4 t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    particles[index].direction = rot * particles[index].direction;
    particles[index].position += 0.25 * particles[index].direction;
    
    t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    
    particles[index].position += 0.25 * particles[index].direction;
    t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    
    particles[index].position += 0.25 * particles[index].direction;
    t = texture.read(uint2(particles[index].position));
    texture.write(t + 0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    particles[index].position += 0.25 * particles[index].direction;
    
    if (particles[index].position.x > dimensions) {
        particles[index].position.x -= dimensions;
    }
    if (particles[index].position.y > dimensions) {
        particles[index].position.y -= dimensions;
    }
    if (particles[index].position.x < 0.0) {
        particles[index].position.x += dimensions;
    }
    if (particles[index].position.y < 0.0) {
        particles[index].position.y += dimensions;
    }
    //particles[index].position = float2(fmod(particles[index].position.x, 400.0), fmod(particles[index].position.y, 400.0));
}

kernel void blur_function(texture2d<half, access::read_write> texture [[texture(0)]],
                          uint2 index [[thread_position_in_grid]])
{
    half4 out = 1.0/4.0 * texture.read(index)
    + 1.0/8.0 * texture.read(index+uint2(1,0))
    + 1.0/8.0 * texture.read(index+uint2(-1,0))
    + 1.0/8.0 * texture.read(index+uint2(0,1))
    + 1.0/8.0 * texture.read(index+uint2(0,-1))
    + 1.0/16.0 * texture.read(index+uint2(1,1))
    + 1.0/16.0 * texture.read(index+uint2(-1,1))
    + 1.0/16.0 * texture.read(index+uint2(1,-1))
    + 1.0/16.0 * texture.read(index+uint2(-1,-1));
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
