//
//  +View.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 11.01.2025.
//
import SwiftUI

extension View{
    @ViewBuilder
    func hSpacing(_ aligment: Alignment) -> some View{
        self.frame(maxWidth: .infinity, alignment: aligment)
    }
    func vSpacing(_ aligment: Alignment) -> some View{
        self.frame(maxHeight: .infinity, alignment: aligment)
    }
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}
