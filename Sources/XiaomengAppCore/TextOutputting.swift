import Foundation

public protocol TextOutputting {
    func output(_ text: String) throws
}

public struct NoOpTextOutput: TextOutputting {
    public init() {}

    public func output(_ text: String) throws {}
}
