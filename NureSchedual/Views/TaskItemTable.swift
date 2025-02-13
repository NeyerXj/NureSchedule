//
//  TaskItemTable.swift
//  NureSchedual
//
//  Created by Kostiantyn Volkov on 09.02.2025.
//


import SwiftUI

struct TaskItemTable: View {
    var task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(displayTitle)
                .font(Font.custom("Inter", size: 14).weight(.bold))
                .foregroundColor(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.black)
                Text(task.date.format("HH:mm"))
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(task.auditory)
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(.black)
            }
        }
        .padding(8)
        .background(task.tint.opacity(0.7))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
    private var displayTitle: String {
        if task.title == "Break" {
            return "Перерва"
        }
        return task.fullTitle.count > 20 ? task.title : task.fullTitle
    }
}

// Превью
struct TaskItemTable_Previews: PreviewProvider {
    static var previews: some View {
        let exampleTask = Task(
            title: "Лекция",
            fullTitle: "Программирование на Swift",
            caption: "Основы Swift",
            date: Date(),
            tint: .blue,
            auditory: "Ауд. 201",
            type: "Лекция",
            teacher: "Иванов И.И."
        )

        TaskItemTable(task: exampleTask)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
