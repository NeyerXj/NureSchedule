//
//  LoadingView.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 15.01.2025.
//

import SwiftUI

// MARK: - LoadingView
struct LoadingView: View {
    @State private var rotation:Double = 0
    @Binding var isLoading: Bool
    var body: some View {
        ZStack{
            Circle()
                .stroke(lineWidth: 4).opacity(0.3).foregroundStyle(.white.opacity(1))
            Circle()
                            .trim(from: 0, to: 0.25)
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(rotation))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                        self.rotation = 360
                                    }
                                }
                            }
            Text(isLoading ? "LOADING API" : "LOADING").font(Font.custom("Inter", size: isLoading ? 14 : 16).weight(.semibold)).foregroundStyle(.white)
        }.compositingGroup()
            .frame(width: 150)
        .hSpacing(.center)
        .vSpacing(.center)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(isLoading: .constant(true))
    }
}
