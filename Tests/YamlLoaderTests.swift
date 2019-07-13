import XCTest

@testable import LocaLoca

class YamlLoaderTests: XCTestCase {
    func testLoadSingleLocaleYaml() {
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "simple/de", withExtension: "yml")!

        let result = YamlLoader.load([url1])

        XCTAssertEqual(result.localesByFile, [url1: "de"])
        XCTAssertEqual(result.nodes, [
            Node(fullKey: "bar", translations: ["de": "pong"]),
            Node(fullKey: "foo", translations: ["de": "ping"]),
        ])
    }

    func testLoadMultipleLocaleYamls() {
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "simple/de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "simple/en", withExtension: "yml")!

        let result = YamlLoader.load([url1, url2])

        XCTAssertEqual(result.localesByFile, [url1: "de", url2: "en"])
        XCTAssertEqual(result.nodes, [
            Node(fullKey: "bar", translations: [
                "de": "pong",
                "en": "buzz",
            ]),
            Node(fullKey: "foo", translations: [
                "de": "ping",
                "en": "fizz",
            ]),
        ])
    }
    
    func testLoadSkipsNonMatchingFilename() {
        Warning.stub()
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "simple/de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "simple/en", withExtension: "yml")!
        let url3 = testBundle.url(forResource: "filename_mismatch/jp", withExtension: "yml")!

        let result = YamlLoader.load([url1, url2, url3])

        XCTAssertEqual(result.localesByFile, [url1: "de", url2: "en"])
        XCTAssertEqual(result.nodes, [
            Node(fullKey: "bar", translations: [
                "de": "pong",
                "en": "buzz",
            ]),
            Node(fullKey: "foo", translations: [
                "de": "ping",
                "en": "fizz",
            ]),
        ])
        XCTAssertEqual(Warning.count, 1)
    }
    
    
    func testLoadNestedYaml() {
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "nested/de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "nested/en", withExtension: "yml")!
        
        let result = YamlLoader.load([url1, url2])
        
        XCTAssertEqual(result.localesByFile, [url1: "de", url2: "en"])
        XCTAssertEqual(result.nodes, [
            Node(fullKey: "foo", children: [
                Node(fullKey: "foo.bar", translations: [
                    "de": "Hallo",
                    "en": "Hello",
                ]),
                Node(fullKey: "foo.qux", translations: [
                    "de": "Tschüss",
                    "en": "Goodbye",
                ]),
            ])
        ])
    }
    
    func testLoadTypes() {
        let testBundle = Bundle(for: type(of: self))
        let url = testBundle.url(forResource: "types/en", withExtension: "yml")!
        
        let result = YamlLoader.load([url])
        
        XCTAssertEqual(result.localesByFile, [url: "en"])
        XCTAssertEqual(result.nodes, [
            Node(fullKey: "array", children: [
                Node(fullKey: "array.[0]", translations: ["en": "a"]),
                Node(fullKey: "array.[1]", translations: ["en": "b"]),
                Node(fullKey: "array.[2]", translations: ["en": "c"]),
            ]),
            Node(fullKey: "numbers", children: [
                Node(fullKey: "numbers.float",      translations: ["en": "2.0"]),
                Node(fullKey: "numbers.float_abrv", translations: ["en": "3."]),
                Node(fullKey: "numbers.int",        translations: ["en": "1"]),
            ]),
            Node(fullKey: "strings", children: [
                Node(fullKey: "strings.astral",        translations: ["en": "😍😍😍"]),
                Node(fullKey: "strings.double_quoted", translations: ["en": "hi"]),
                Node(fullKey: "strings.single_quoted", translations: ["en": "hi"]),
            ]),
        ])
    }
    
    func testLoadBadDeviantStructures() {
        Warning.stub()
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "deviant_bad/de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "deviant_bad/en", withExtension: "yml")!
        
        let result = YamlLoader.load([url1, url2])
        
        XCTAssertEqual(result.localesByFile, [url1: "de", url2: "en"])
        XCTAssertEqual(result.nodes, [
            Node(fullKey: "ok", translations: ["de": "ok", "en": "ok"])
        ])
        XCTAssertEqual(Warning.count, 3)
    }

    func testLoadOKDeviantStructures() {
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "deviant_ok/de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "deviant_ok/en", withExtension: "yml")!
        
        let result = YamlLoader.load([url1, url2])
        
        XCTAssertEqual(result.localesByFile, [url1: "de", url2: "en"])
        XCTAssertEqual(result.nodes, [
            Node(fullKey: "house", type: .container, children: [
                Node(fullKey: "house.one", type: .document, translations: [
                    "de": "Haus",
                    "en": "house",
                    ]),
                Node(fullKey: "house.other", type: .document, translations: [
                    "de": "Häuser",
                    "en": "house",
                    ]),
            ]),
            Node(fullKey: "mouse", type: .container, children: [
                Node(fullKey: "mouse.one", type: .document, translations: [
                    "de": "Maus",
                    "en": "mouse",
                ]),
                Node(fullKey: "mouse.other", type: .document, translations: [
                    "de": "Maus",
                    "en": "mice",
                ]),
            ]),
        ])
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
