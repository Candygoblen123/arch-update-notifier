import Foundation

struct Runner {
    static func runProgram(_ programPath: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let outputPipe: Pipe = Pipe()
                let task: Process = Process()
                task.executableURL = URL(fileURLWithPath: programPath)
                task.standardOutput = outputPipe
                task.terminationHandler = { _ in
                    do {
                        let outputData = try outputPipe.fileHandleForReading.readToEnd()
                        guard let outputData = outputData else {
                            continuation.resume(returning: "")
                            return
                        }
                        let output: String = String(decoding: outputData, as: UTF8.self)
                        continuation.resume(returning: output)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                try task.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
