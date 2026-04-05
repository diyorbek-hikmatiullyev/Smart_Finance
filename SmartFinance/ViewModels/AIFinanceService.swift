// AIFinanceService.swift
// SmartFinance
// Google Gemini API bilan moliyaviy maslahat

import Foundation

enum AIServiceError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Tarmoq xatosi: \(e.localizedDescription)"
        case .invalidResponse:    return "Server noto'g'ri javob qaytardi"
        case .apiError(let msg):  return "API xatosi: \(msg)"
        case .noContent:          return "Javob bo'sh keldi"
        }
    }
}

final class AIFinanceService {
    static let shared = AIFinanceService()
    private init() {}

    // ⚠️ API kalitni bu yerda saqlash faqat diplom ishi uchun.
    private let apiKey = "AIzaSyCAq8SjAR0Xn-lk9DgMNF5jQfLGkGhayXQ"

    // Gemini 2.0 Flash — tez va tekin
    private var apiURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
    }

    // MARK: - Asosiy so'rov

    func getAdvice(
        summary: FinancialSummary,
        userQuestion: String?,
        onStream: @escaping (String) -> Void,
        onComplete: @escaping (Result<Void, AIServiceError>) -> Void
    ) {
        let systemPrompt = AIPromptBuilder.buildSystemPrompt()
        let userPrompt   = AIPromptBuilder.buildUserPrompt(summary: summary, userQuestion: userQuestion)

        // Gemini format: system + user bitta "contents" massivida
        let fullPrompt = "\(systemPrompt)\n\n\(userPrompt)"

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 2048,
                "temperature": 0.7
            ]
        ]

        guard let url = URL(string: apiURL),
              let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            onComplete(.failure(.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod      = "POST"
        request.httpBody        = httpBody
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in

            // 1. Network xato
            if let error = error {
                DispatchQueue.main.async { onComplete(.failure(.networkError(error))) }
                return
            }

            // 2. HTTP status log
            if let http = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(http.statusCode)")
            }

            guard let data = data else {
                DispatchQueue.main.async { onComplete(.failure(.invalidResponse)) }
                return
            }

            // 3. Raw log (debug)
            if let raw = String(data: data, encoding: .utf8) {
                print("📥 Gemini response: \(String(raw.prefix(500)))")
            }

            // 4. JSON parse
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { onComplete(.failure(.invalidResponse)) }
                return
            }

            // 5. Xato tekshirish
            if let errorObj = json["error"] as? [String: Any],
               let message  = errorObj["message"] as? String {
                print("❌ Gemini Error: \(message)")
                DispatchQueue.main.async { onComplete(.failure(.apiError(message))) }
                return
            }

            // 6. Gemini response format:
            // { "candidates": [ { "content": { "parts": [ { "text": "javob" } ] } } ] }
            if let candidates = json["candidates"] as? [[String: Any]],
               let first      = candidates.first,
               let content    = first["content"] as? [String: Any],
               let parts      = content["parts"] as? [[String: Any]] {

                let fullText = parts
                    .compactMap { $0["text"] as? String }
                    .joined()

                if !fullText.isEmpty {
                    print("✅ Gemini javob: \(fullText.count) harf")
                    DispatchQueue.main.async {
                        onStream(fullText)
                        onComplete(.success(()))
                    }
                    return
                }
            }

            print("⚠️ Content topilmadi. Keys: \(json.keys.joined(separator: ", "))")
            DispatchQueue.main.async { onComplete(.failure(.noContent)) }

        }.resume()
    }
}
