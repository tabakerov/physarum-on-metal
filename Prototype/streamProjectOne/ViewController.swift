//
//  ViewController.swift
//  streamProjectOne
//
//  Created by Dmitry Tabakerov on 27.01.21.
//

import MetalKit

class ViewController: NSViewController {

    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("View isn't MTKView")
        }
        let size = CGSize(width: 1920, height: 1080)
        metalView.drawableSize = size
        renderer = Renderer(metalView: metalView)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

