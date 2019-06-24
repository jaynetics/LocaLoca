import XCTest

@testable import LocaLoca

class YamlLoaderTests: XCTestCase {
    func testLoadSingleLocaleYaml() {
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "simple_de", withExtension: "yml")!

        let result = YamlLoader.load([url1])

        XCTAssertEqual(result.localesByFile, [url1: "simple_de"])
        XCTAssertEqual(result.dict as! [String: [String: String]], [
            "foo": [
                "simple_de": "ping"
            ],
            "bar": [
                "simple_de": "pong"
            ]
        ])
    }

    func testLoadMultipleLocaleYamls() {
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "simple_de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "simple_en", withExtension: "yml")!

        let result = YamlLoader.load([url1, url2])

        XCTAssertEqual(result.localesByFile, [url1: "simple_de", url2: "simple_en"])
        XCTAssertEqual(result.dict as! [String: [String: String]], [
            "foo": [
                "simple_de": "ping",
                "simple_en": "fizz"
            ],
            "bar": [
                "simple_de": "pong",
                "simple_en": "buzz"
            ]
        ])
    }
    
    func testLoadSkipsAndWarnsForYamlsWithNonMatchingFilename() {
        Warning.stub()
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "simple_de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "simple_en", withExtension: "yml")!
        let url3 = testBundle.url(forResource: "wrong_filename", withExtension: "yml")!

        let result = YamlLoader.load([url1, url2, url3])

        XCTAssertEqual(result.localesByFile, [url1: "simple_de", url2: "simple_en"])
        XCTAssertEqual(result.dict as! [String: [String: String]], [
            "foo": [
                "simple_de": "ping",
                "simple_en": "fizz"
            ],
            "bar": [
                "simple_de": "pong",
                "simple_en": "buzz"
            ]
        ])
        XCTAssertEqual(Warning.count, 1)
    }
    
    
    func testLoadNestedYaml() {
        let testBundle = Bundle(for: type(of: self))
        let url1 = testBundle.url(forResource: "nested_de", withExtension: "yml")!
        let url2 = testBundle.url(forResource: "nested_en", withExtension: "yml")!
        
        let result = YamlLoader.load([url1, url2])
        
        XCTAssertEqual(result.localesByFile, [url1: "nested_de", url2: "nested_en"])
        XCTAssertEqual(result.dict as! [String: [String: [String: String]]], [
            "foo": [
                "bar": [
                    "nested_de": "Hallo",
                    "nested_en": "Hello"
                ],
                "qux": [
                    "nested_de": "Tschüss",
                    "nested_en": "Goodbye"
                ]
            ]
        ])
    }
    
    func testLoadTypes() {
        let testBundle = Bundle(for: type(of: self))
        let url = testBundle.url(forResource: "types", withExtension: "yml")!
        
        let result = YamlLoader.load([url])
        
        XCTAssertEqual(result.localesByFile, [url: "types"])
        XCTAssertEqual(result.dict as! [String: [String: [String: String]]], [
            "numbers": [
                "int":           ["types": "1"],
                "float":         ["types": "2.0"],
                "float_abrv":    ["types": "3."]
            ],
            "strings": [
                "astral":        ["types": "😍😍😍"],
                "single_quoted": ["types": "hi"],
                "double_quoted": ["types": "hi"]
            ],
            "array": [
                "[0000]":        ["types": "a"],
                "[0001]":        ["types": "b"],
                "[0002]":        ["types": "c"]
            ]
        ])
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
