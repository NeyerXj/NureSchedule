import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let gifName: String
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.isUserInteractionEnabled = false

        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let gifData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            let base64String = gifData.base64EncodedString()

            let html = """
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        margin: 0;
                        width: 100%;
                        height: 100%;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        overflow: hidden;
                        background-color: transparent;
                    }
                    img {
                        width: 100%;
                        height: 100%;
                        object-fit: cover;
                    }
                </style>
            </head>
            <body>
                <img id="gif" src="data:image/gif;base64,\(base64String)">
                <canvas id="canvas" style="display: none;"></canvas>

                <script>
                    console.log("✅ JavaScript загружен в WebView");

                    let gif = document.getElementById('gif');
                    let canvas = document.getElementById('canvas');
                    let ctx = canvas.getContext('2d');
                    let playing = true;
                    window.isGIFReady = false;
                    let base64GIF = gif.src;

                    function registerFunctions() {
                        window.isGIFReady = true;

                        window.stopGIF = function() {
                            console.log("🛑 stopGIF() вызвана");
                            if (playing) {
                                playing = false;
                                canvas.width = gif.width;
                                canvas.height = gif.height;
                                ctx.drawImage(gif, 0, 0, gif.width, gif.height);
                                gif.style.display = 'none';
                                canvas.style.display = 'block';
                                console.log("⏸ GIF остановлен на последнем кадре");
                            } else {
                                console.warn("⚠ stopGIF() → GIF уже остановлен!");
                            }
                        };

                        window.startGIF = function() {
                            console.log("▶ startGIF() вызвана");
                            if (!playing) {
                                playing = true;
                                gif.style.display = 'block';
                                canvas.style.display = 'none';
                                
                                // Перезапуск GIF
                                gif.src = "";
                                setTimeout(() => {
                                    gif.src = base64GIF;
                                    console.log("🎬 GIF перезапущен с первого кадра");
                                }, 100);
                            } else {
                                console.warn("⚠ startGIF() → GIF уже запущен!");
                            }
                        };

                        console.log("✅ JS-функции `startGIF()` и `stopGIF()` загружены!");
                    }

                    window.onload = function() {
                        console.log("✅ GIF полностью загружен");
                        registerFunctions();
                    };
                </script>
            </body>
            </html>
            """

            webView.loadHTMLString(html, baseURL: nil)
        } else {
            print("❌ Ошибка: GIF-файл '\(gifName).gif' не найден в Bundle")
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // ⏳ Ждем загрузку HTML + JS
            let checkReadyJS = "window.isGIFReady === true"
            uiView.evaluateJavaScript(checkReadyJS) { (result, error) in
                if let error = error {
                    print("❌ Ошибка проверки isGIFReady: \(error)")
                } else if let isReady = result as? Bool, isReady {
                    let jsCommand = self.isPlaying ? "window.startGIF()" : "window.stopGIF()"
                    print("🔄 updateUIView() → isPlaying: \(self.isPlaying), выполняем: \(jsCommand)")

                    uiView.evaluateJavaScript(jsCommand) { (result, error) in
                        if let error = error {
                            print("❌ Ошибка выполнения \(jsCommand): \(error)")
                        } else {
                            print("✅ \(jsCommand) выполнена, результат: \(String(describing: result))")
                        }
                    }
                } else {
                    print("⚠️ GIF еще не готов, повторяем попытку через 0.5 сек...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.updateUIView(uiView, context: context) // Пробуем снова
                    }
                }
            }
        }
    }
}
