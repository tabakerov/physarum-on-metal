//
//  PhysarumView.swift
//  physarum
//
//  Created by Dmitry Tabakerov on 28.01.21.
//

import SwiftUI
import MetalKit

struct MyParticle {
    var Position: SIMD2<Float>
    var Direction: SIMD2<Float>
    var Intensity: SIMD3<Float>
}

struct MyUniforms {
    var MatrixStreight: SIMD4<Float>
    var MatrixLeftSensor: SIMD4<Float>
    var MatrixRightSensor: SIMD4<Float>
    var MatrixLeftTurn: SIMD4<Float>
    var MatrixRightTurn: SIMD4<Float>
    var Dimensions: SIMD2<Float>
}


struct PhysarumView : NSViewRepresentable {
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<PhysarumView>) -> MTKView {
        let view = MTKView()
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = true
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            view.device = metalDevice
        }
        
        view.drawableSize = view.frame.size
        return view
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
    }
}

class Coordinator : NSObject, MTKViewDelegate {
    var parent: PhysarumView
    static var metalDevice: MTLDevice!
    static var metalCommandQueue: MTLCommandQueue!
    
    static var uniforms: MyUniforms!
    var renderPipelineState: MTLRenderPipelineState!
    var computePipelineState: MTLComputePipelineState!
    var blurPipelineState: MTLComputePipelineState!
    var vertexData: [Float]
    var vertexBuffer: MTLBuffer
    var texture: MTLTexture
    var particles: [MyParticle]
    var particlesBuffer: MTLBuffer
    
    init(_ parent: PhysarumView) {
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            Coordinator.metalDevice = metalDevice
        }
        Coordinator.metalCommandQueue = Coordinator.metalDevice.makeCommandQueue()!
        
        
        let sensor_angle = 0.25
        let turn_angle   = 0.15
        let matrixTurnR = SIMD4<Float>(
            Float(cos(turn_angle)), Float(-1.0 * sin(turn_angle)),
            Float(sin(turn_angle)),      Float(cos(turn_angle))
        )
        let matrixTurnL : SIMD4<Float> = SIMD4<Float>(
            Float(cos(-1 * turn_angle)), Float(-1 * sin(-1 * turn_angle)),
            Float(sin(-1 * turn_angle)),      Float(cos(-1 * turn_angle))
        )
        let matrixSensR = SIMD4<Float>(
            Float(cos(sensor_angle)), Float(-1.0 * sin(sensor_angle)),
            Float(sin(sensor_angle)),      Float(cos(sensor_angle))
        )
        let matrixSensL : SIMD4<Float> = SIMD4<Float>(
            Float(cos(-1 * sensor_angle)), Float(-1 * sin(-1 * sensor_angle)),
            Float(sin(-1 * sensor_angle)),      Float(cos(-1 * sensor_angle))
        )
        Coordinator.uniforms = MyUniforms(
            MatrixStreight: SIMD4<Float>(1.0, 0.0,
                                         0.0, 1.0),
            MatrixLeftSensor: matrixSensL,
            MatrixRightSensor: matrixSensR,
            MatrixLeftTurn: matrixTurnL,
            MatrixRightTurn: matrixTurnR,
            Dimensions: SIMD2<Float>(Float(1000), Float(1000))
        )
        
        particles = []
        
        for _ in 1...2000 {
            particles.append(MyParticle(
                                Position: SIMD2<Float>(
                                    Float.random(in: 0.0...Float(Coordinator.uniforms.Dimensions.x)),
                                    Float.random(in: 0.0...Float(Coordinator.uniforms.Dimensions.y))
                                ),
                                Direction: SIMD2<Float>(
                                    Float.random(in: -10.0...10.0),
                                    Float.random(in: -10.0...10.0)
                                ),
                Intensity: SIMD3<Float>(Float.random(in: 0.2...3), Float.random(in: 0.2...3), Float.random(in: 0.2...3))
                ))
        }
        
        particlesBuffer = Coordinator.metalDevice.makeBuffer(bytes: particles, length: MemoryLayout<Particle>.stride * particles.count, options: [])!
        
        vertexData = [-1.0, -1.0, 0.0, 1.0, //0.0, 0.0,
                       1.0, -1.0, 0.0, 1.0, //1.0, 0.0,
                      -1.0,  1.0, 0.0, 1.0, //0.0, 1.0,
                      -1.0,  1.0, 0.0, 1.0, //0.0, 1.0,
                       1.0, -1.0, 0.0, 1.0, //1.0, 0.0,
                       1.0,  1.0, 0.0, 1.0, //1.0, 1.0
                      ]
        vertexBuffer = Coordinator.metalDevice.makeBuffer(bytes: vertexData,
                                         length: MemoryLayout<Float>.size * vertexData.count,
                                         options: [])!
        
        let library = Coordinator.metalDevice.makeDefaultLibrary()
        
        let kernelFunction = library?.makeFunction(name: "compute_function")
        let fragmentFunction = library?.makeFunction(name: "fragment_function")
        let vertexFunction = library?.makeFunction(name: "vertex_function")
        let blurFunction = library?.makeFunction(name: "blur_function")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm // MTLPixelFormatBGRA8Unorm
        
        do {
            renderPipelineState = try Coordinator.metalDevice.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            computePipelineState = try Coordinator.metalDevice.makeComputePipelineState(function: kernelFunction!)
            blurPipelineState = try Coordinator.metalDevice.makeComputePipelineState(function: blurFunction!)
        } catch let error {
            print(error.localizedDescription)
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.pixelFormat = .rgba32Float
        textureDescriptor.width = Int(Coordinator.uniforms.Dimensions.x)
        textureDescriptor.height = Int(Coordinator.uniforms.Dimensions.y)
        textureDescriptor.depth = 1
        texture = Coordinator.metalDevice.makeTexture(descriptor: textureDescriptor)!
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Coordinator.metalCommandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        guard let blurEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        blurEncoder.setComputePipelineState(blurPipelineState)
        blurEncoder.setTexture(texture, index: 0)
        blurEncoder.setBytes(&Coordinator.uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        
        var width = blurPipelineState.threadExecutionWidth
        var height = blurPipelineState.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        width = Int(view.drawableSize.width)
        height = Int(view.drawableSize.height)
        let threadsPerGrid = MTLSizeMake(width, height, 1)
        
        blurEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        blurEncoder.endEncoding()
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBuffer(particlesBuffer, offset: 0, index: 0)
        computeEncoder.setBytes(&Coordinator.uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        computeEncoder.dispatchThreads(MTLSize(width: particles.count, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
        computeEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
