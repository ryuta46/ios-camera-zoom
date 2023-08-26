//
//  CALayerView.swift
//  SwiftUICamera
//  
//  Created by ryuta46 on 2023/04/10.
//  
//

import SwiftUI
import UIKit

struct CALayerView: UIViewRepresentable {
    var caLayer: CALayer?
    var aspectRatio: CGFloat?

    func makeUIView(context: Context) -> some UIView {
        let view = UIView()
        view.contentMode = .scaleAspectFit
        if let caLayer {
            view.layer.addSublayer(caLayer)
        }
        updateViewSize(view)

        return view
    }


    func updateUIView(_ uiView: UIViewType, context: Context) {
        updateViewSize(uiView)
    }
    
    private func updateViewSize(_ view: UIView) {
        guard let caLayer else {
            return
        }
        let size = UIScreen.main.bounds.size
        let aspectRatio = aspectRatio ?? 1.0
        let contentSize = CGSize(width: size.width, height: size.width / aspectRatio)
        view.frame = CGRect(origin: .zero, size: contentSize)
        caLayer.frame = view.frame
    }
}
