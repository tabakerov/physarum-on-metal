//
//  PhysarumViewController.swift
//  physarum
//
//  Created by Dmitry Tabakerov on 28.01.21.
//

import MetalKit
import SwiftUI

class PhysarumViewController: NSViewController {

    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("View isn't MTKView")
        }
        let size = CGSize(width: 1920, height: 1080)
        metalView.drawableSize = size
        renderer = Renderer(metalView: metalView, size: size)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
/*
extension PhysarumViewController : NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> some NSViewController {

    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        <#code#>
    }
    
    static func dismantleNSViewController(_ nsViewController: NSViewControllerType, coordinator: ()) {
        
    }
}
*/
