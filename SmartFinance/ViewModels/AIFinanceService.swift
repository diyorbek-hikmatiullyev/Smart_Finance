// AIFinanceService.swift
// SmartFinance
// Google Gemini API — kalit koddan emas, GeminiSecrets.plist yoki Info.plist dan

import Foundation

enum AIServiceError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case noContent
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Tarmoq xatosi: \(e.localizedDescription)"
        case .invalidResponse:    return "Server noto'g'ri javob qaytardi"
        case .apiError(let msg):  return "API xatosi: \(msg)"
        case .noContent:          return "Javob bo'sh keldi"
        case .missingAPIKey:
            return """
            Gemini API kaliti topilmadi. Google AI Studio (https://aistudio.google.com/apikey) dan yangi kalit yarating, \
            SmartFinance/GeminiSecrets.plist.example faylini nusxalab GeminiSecrets.plist qiling va ichidagi kalitni to'ldiring. \
            Eski kalit sizib chiqqan bo'lsa, yangi kalit yaratish shart.
            """
        }
    }
}

final class AIFinanceService {
    static let shared = AIFinanceService()
    private init() {}

    /// Avvalo `GeminiSecrets.plist` (gitignore), keyin bo'sh bo'lmagan `Info.plist` → `GeminiAPIKey`.
    private func resolvedAPIKey() -> String? {
        if let key = loadKeyFromSecretsPlist(), !key.isEmpty {
            return key
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String,
           !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return key.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private func loadKeyFromSecretsPlist() -> String? {
        guard let url = Bundle.main.url(forResource: "GeminiSecrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let key = obj["GeminiAPIKey"] as? String else {
            return nil
        }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "BU_YERGA_GOOGLE_AI_STUDIO_KALITI" {
            return nil
        }
        return trimmed
    }

    private func makeAPIURL(key: String) -> String {
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(key)"
    }

    func getAdvice(
        summary: FinancialSummary,
        userQuestion: String?,
        onStream: @escaping (String) -> Void,
        onComplete: @escaping (Result<Void, AIServiceError>) -> Void
    ) {
        guard let apiKey = resolvedAPIKey() else {
            DispatchQueue.main.async { onComplete(.failure(.missingAPIKey)) }
            return
        }

        let systemPrompt = AIPromptBuilder.buildSystemPrompt()
        let userPrompt   = AIPromptBuilder.buildUserPrompt(summary: summary, userQuestion: userQuestion)

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

        let apiURL = makeAPIURL(key: apiKey)

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

            if let error = error {
                DispatchQueue.main.async { onComplete(.failure(.networkError(error))) }
                return
            }

            if let http = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(http.statusCode)")
            }

            guard let data = data else {
                DispatchQueue.main.async { onComplete(.failure(.invalidResponse)) }
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("📥 Gemini response: \(String(raw.prefix(500)))")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { onComplete(.failure(.invalidResponse)) }
                return
            }

            if let errorObj = json["error"] as? [String: Any],
               let message  = errorObj["message"] as? String {
                print("❌ Gemini Error: \(message)")
                DispatchQueue.main.async { onComplete(.failure(.apiError(message))) }
                return
            }

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
