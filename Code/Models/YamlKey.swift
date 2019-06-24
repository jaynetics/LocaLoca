import Foundation

struct YamlKey {
    var name: String

    private static let headCS = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
    private static let tailCS = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz_-")
    
    var sanitized: String? {
        guard name.count > 0 else { return nil }
        
        guard let idx = name.rangeOfCharacter(from: YamlKey.headCS)?.lowerBound,
              name.distance(from: name.startIndex, to: idx) == 0 else { return nil }
        
        return name.trimmingCharacters(in: YamlKey.tailCS.inverted)
    }
}
