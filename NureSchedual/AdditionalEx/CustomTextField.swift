//
//  CustomTextField.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 13.01.2025.
//


import SwiftUI

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardAppearance: UIKeyboardAppearance = .dark // Тёмная клавиатура

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        
        // Настройка текстового поля
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.keyboardAppearance = keyboardAppearance
        textField.borderStyle = .none // Без стандартной границы
        textField.textColor = .white
        textField.backgroundColor = UIColor(white: 1, alpha: 0.1) // Полупрозрачный фон
        textField.layer.cornerRadius = 12
        textField.layer.masksToBounds = true
        textField.font = UIFont(name: "Inter", size: 16)
        textField.setLeftPaddingPoints(10) // Внутренний отступ слева

        // Плейсхолдер с цветом
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 1, alpha: 0.5)]
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder() // Скрытие клавиатуры при нажатии "Return"
            return true
        }
    }
}

// Расширение для добавления отступов
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}