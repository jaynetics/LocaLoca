import XCTest

@testable import LocaLoca

class YamlFinderTests: XCTestCase {
    func testSearchLocalesDir() {
        YamlFinder.stubDirContents(["de.yml"])
        YamlFinder.stubNestedExists(false)
        
        let result = YamlFinder.openUrl(URL(fileURLWithPath: "/foo"))
        
        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.dir, URL(fileURLWithPath: "/foo"))
        XCTAssertEqual(result.files, [URL(fileURLWithPath: "/foo/de.yml")])
    }
    
    func testSearchRailsRoot() {
        YamlFinder.stubDirContents(["de.yml"])
        YamlFinder.stubNestedExists(true)
        
        let result = YamlFinder.openUrl(URL(fileURLWithPath: "/foo"))
        
        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.dir, URL(fileURLWithPath: "/foo/config/locales/"))
        XCTAssertEqual(result.files, [URL(fileURLWithPath: "/foo/config/locales/de.yml")])
    }
    
    func testSearchWithIgnoredFiles() {
        YamlFinder.stubDirContents(["de.yml", "en.yml", "some.gem.de.yml", "es.toml", "fr.json"])
        YamlFinder.stubNestedExists(false)
        
        let result = YamlFinder.openUrl(URL(fileURLWithPath: "/foo"))
        
        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.dir, URL(fileURLWithPath: "/foo"))
        XCTAssertEqual(result.files, [URL(fileURLWithPath: "/foo/de.yml"), URL(fileURLWithPath: "/foo/en.yml")])
    }
    
    func testSearchOnlyIgnoredFiles() {
        YamlFinder.stubDirContents(["some.gem.de.yml", "en.toml", "fr.json"])
        YamlFinder.stubNestedExists(false)
        Warning.stub()
        
        let result = YamlFinder.openUrl(URL(fileURLWithPath: "/foo"))
        
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.dir, URL(fileURLWithPath: "/foo"))
        XCTAssertEqual(result.files, [])
        XCTAssertEqual(Warning.count, 1)
    }

    func testSearchEmptyDir() {
        YamlFinder.stubDirContents([])
        YamlFinder.stubNestedExists(false)
        Warning.stub()
        
        let result = YamlFinder.openUrl(URL(fileURLWithPath: "/foo"))
        
        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.dir, URL(fileURLWithPath: "/foo"))
        XCTAssertEqual(result.files, [])
        XCTAssertEqual(Warning.count, 1)
    }
}
