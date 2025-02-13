//
//  ZoomTransition.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 17.01.2025.
//


import SwiftUI

struct ZoomTransition: ViewModifier {
    let sourceID: String
    let namespace: Namespace.ID
    let scale: CGFloat // Параметр для настройки интенсивности зума

    func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(id: sourceID, in: namespace)
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.3), value: scale) // Настройте анимацию по необходимости
    }
}

extension View {
    func zoomTransition(sourceID: String, namespace: Namespace.ID, scale: CGFloat = 1.0) -> some View {
        self.modifier(ZoomTransition(sourceID: sourceID, namespace: namespace, scale: scale))
    }
}