import XCTest

@testable import LocaLoca

class YamlSaverTests: XCTestCase {
    func testStringFromTree() {
        let tree = [
            Node(fullKey: "foo", type: .container, children: [
                Node(fullKey: "bar", translations: ["de": "Hallo", "en": "Hello"]),
                Node(fullKey: "qux", translations: ["de": "Tschüss", "en": "Goodbye"]),
            ])
        ]
        
        let resultDe = YamlSaver.stringFromTree(tree, locale: "de")
        let resultEn = YamlSaver.stringFromTree(tree, locale: "en")
        
        XCTAssertEqual(resultDe, """
        ---
        de:
          foo:
            bar: Hallo
            qux: Tschüss\n
        """)

        XCTAssertEqual(resultEn, """
        ---
        en:
          foo:
            bar: Hello
            qux: Goodbye\n
        """)
    }
    
    func testArray() {
        let tree = [
            Node(fullKey: "foo", type: .container, children: [
                Node(fullKey: "[23]", translations: ["de": "Hallo"]),
                Node(fullKey: "[42]", translations: ["de": "Tschüss"]),
                ], array: true)
        ]
        
        let result = YamlSaver.stringFromTree(tree, locale: "de")
        
        XCTAssertEqual(result, """
        ---
        de:
          foo:
          - Hallo
          - Tschüss\n
        """)
    }
    
    func testEscaping() {
        let tree = [
            Node(fullKey: "foo", translations: ["de": "& ist ein schönes Zeichen"]),
        ]
        
        let result = YamlSaver.stringFromTree(tree, locale: "de")
        
        XCTAssertEqual(result, """
        ---
        de:
          foo: '& ist ein schönes Zeichen'\n
        """)
    }
    
    func testStringTypes() {
        let tree = [
            Node(fullKey: "astral_str",          translations: ["de": "😍😍😍"]),
            Node(fullKey: "float_abrv_like_str", translations: ["de": "3."]),
            Node(fullKey: "float_like_str",      translations: ["de": "2.0"]),
            Node(fullKey: "int_like_str",        translations: ["de": "1"]),
        ]
        
        let result = YamlSaver.stringFromTree(tree, locale: "de")
        
        XCTAssertEqual(result, """
        ---
        de:
          astral_str: "\\U0001F60D\\U0001F60D\\U0001F60D"
          float_abrv_like_str: '3.'
          float_like_str: '2.0'
          int_like_str: '1'\n
        """)
    }
}

extension Node {
    convenience init(fullKey: String, type: NodeType = .document, children: [Node] = [], translations: [String: String]? = nil, array: Bool = false) {
        self.init(fullKey: fullKey)
        self.type = type
        self.children = children
        self.translations = translations
        self.isSequenceContainer = array
    }
}
