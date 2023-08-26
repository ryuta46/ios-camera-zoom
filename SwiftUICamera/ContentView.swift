//
//  ContentView.swift
//  SwiftUICamera
//  
//  Created by ryuta46 on 2023/04/10.
//  
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(contentMode: .fit)
                Button(action: {
                    viewModel.image = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 80, height: 80, alignment: .center)
                }
            } else {
                let aspectRatio = viewModel.imageAspectRatio ?? 1.0// {
                CALayerView(
                    caLayer: viewModel.previewLayer,
                    aspectRatio: aspectRatio
                )
                .onAppear {
                    viewModel.startSession()
                }
                .onDisappear {
                    viewModel.endSession()
                }
                .aspectRatio(aspectRatio, contentMode: .fit)

                Button(action: {
                    viewModel.captureImageOnce()
                }) {
                    Image(systemName: "camera.circle.fill")
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 80, height: 80, alignment: .center)
                }
            }
            Slider(
                value: $viewModel.linearZoomFactor,
                in: Float(viewModel.minFactor)...Float(viewModel.maxFactor)
            ).padding()


            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
