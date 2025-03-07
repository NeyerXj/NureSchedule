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
        HStack(alignment: .top, spacing: 15) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)
                .padding(4)
                .background(.white.shadow(.drop(color:.black.opacity(0.1), radius: 3)), in: .circle)
                .overlay {
                    Circle()
                        .frame(width: 50, height: 50)
                        .blendMode(.destinationOver)
                }
                .offset(y: getIndicatorOffset())
            
            VStack(alignment: .leading, spacing: 8) {
                if task.title == "Break" {
                    breakView
                } else if !task.subTasks.isEmpty {
                    multipleClassesView
                } else {
                    singleClassView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: task.title == "Break" ? 20 : nil)
            .padding()
            .background(task.tint.opacity(0.8))
            .clipShape(.rect(cornerRadius: 20))
        }
        .padding(.horizontal)
    }
    
    private func getIndicatorOffset() -> CGFloat {
        if task.title == "Break" {
            return 17 // Для перерыва
        } else if !task.subTasks.isEmpty {
            return 30 // Для сгруппированных задач - по верхнему краю
        } else {
            return 30 // Для обычных задач - по центру
        }
    }
    
    private var breakView: some View {
        HStack {
            Text("Перерва")
                .font(.custom("Inter", size: 16).weight(.bold))
                .foregroundColor(.black)
            Spacer()
            timeLabel
        }
        .frame(maxWidth: .infinity)
    }
    
    private var singleClassView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.fullTitle.count > 20 ? task.title : task.fullTitle)
                    .font(.custom("Inter", size: 16).weight(.bold))
                    .foregroundColor(.black)
                Spacer()
                timeLabel
            }
            
            Text(task.caption)
                .font(.custom("Inter", size: 16).weight(.semibold))
                .foregroundColor(.black)
        }
    }
    
    private var multipleClassesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.custom("Inter", size: 16).weight(.bold))
                    .foregroundColor(.black)
                Spacer()
                timeLabel
            }
            
            Text(task.caption)
                .font(.custom("Inter", size: 16).weight(.semibold))
                .foregroundColor(.black)
            
            HStack(spacing: 8) {
                if let firstGroup = task.subTasks.first {
                    NavigationLink(destination: DetailView(task: createTaskFromSubTask(firstGroup), namespace: namespace)) {
                        GroupSectionView(subTask: firstGroup)
                    }
                }
                
                if task.subTasks.count > 1 {
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.black.opacity(0.2))
                }
                
                if task.subTasks.count > 1 {
                    NavigationLink(destination: DetailView(task: createTaskFromSubTask(task.subTasks[1]), namespace: namespace)) {
                        GroupSectionView(subTask: task.subTasks[1])
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private struct GroupSectionView: View {
        let subTask: SubTask
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ауд. \(subTask.auditory)")
                    .font(.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(.black)
                
                Text(subTask.teacher)
                    .font(.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        }
    }
    
    private func createTaskFromSubTask(_ subTask: SubTask) -> Task {
        Task(
            title: subTask.title,
            fullTitle: subTask.fullTitle,
            caption: subTask.caption,
            date: task.date,
            tint: task.tint,
            isCompleted: task.isCompleted,
            auditory: subTask.auditory,
            type: subTask.type,
            teacher: subTask.teacher,
            subTasks: []
        )
    }
    
    private var timeLabel: some View {
        Label("\(task.date.format("HH:mm"))", systemImage: "clock")
            .font(.custom("Inter", size: 14).weight(.semibold))
            .foregroundColor(.black)
    }
    
    private var indicatorColor: Color {
        if task.isCompleted {
            return .green
        }
        return task.date.isSameHour ? .black : (task.date.isPast ? .blue : .black)
    }
}

#Preview {
    ContentView()
}
