//
//  TaskItem.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 11.01.2025.
//

import SwiftUI

struct TaskItem: View {
    @Binding var task: Task
    var namespace: Namespace.ID
    var body: some View {
        HStack(alignment: .top,spacing: 15, content: {
            Circle()
                .fill(indicatorColor).frame(width: 10, height: 10)
                .padding(4).background(.white.shadow(.drop(color:.black.opacity(0.1), radius: 3)), in: .circle)
                .overlay{
                    Circle().frame(width:50, height: 50).blendMode(.destinationOver)
                        
                }.offset(y: task.title == "Break" ? 17 : 30)
            VStack(alignment: .leading,spacing: 8, content: {
                HStack{
                    
                    if(task.title == "Break"){
                        Text("Перерва").font(
                            Font.custom("Inter", size: 16)
                            .weight(.bold)
                            ).foregroundColor(.black).offset(y: 10)
                        Spacer()
                        Label("\(task.date.format("HH:mm"))",systemImage: "clock").font(
                            Font.custom("Inter", size: 14)
                                .weight(.semibold)
                            ).foregroundColor(.black).offset(y: 10)

                    }else
                    {
                        Text(task.fullTitle.count > 20 ? task.title : task.fullTitle).font(
                            Font.custom("Inter", size: 16)
                            .weight(.bold)
                        ).foregroundColor(.black)
                        Spacer()
                        Label("\(task.date.format("HH:mm"))",systemImage: "clock").font(
                            Font.custom("Inter", size: 14)
                                .weight(.semibold)
                            ).foregroundColor(.black)
                    }
                }.hSpacing(.leading)
                
                Text(task.caption).font(
                    Font.custom("Inter", size: 16)
                        .weight(.semibold)
                    ).foregroundColor(.black)
                
                
                
            })
            .frame(maxWidth: .infinity,maxHeight: task.title == "Break" ? 20 : nil)
            .padding()
            .background(task.tint.opacity(0.8))
            .clipShape(.rect(cornerRadius: 20))
        })
        .padding(.horizontal)
    }
    var indicatorColor: Color{
        if task.isCompleted{
            return .green
        }
        return task.date.isSameHour ? .black : (task.date.isPast ? .blue : .black)
    }
}

#Preview {
    ContentView()
}
