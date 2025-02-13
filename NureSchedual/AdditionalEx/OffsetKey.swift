//
//  OffsetKey.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 11.01.2025.
//

import SwiftUI

struct OffsetKey:PreferenceKey{
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat){
        value = nextValue()
    }
}
