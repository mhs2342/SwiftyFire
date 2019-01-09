import XCTest
@testable import SwiftyFire

final class SwiftyFireTests: XCTestCase {
    var swiftyFire: SwiftyFire!

    override func setUp() {
        let group = DispatchGroup()
        group.enter()
        generateAuthentication { (swifty) in
            self.swiftyFire = swifty
            group.leave()

        }
        _ = group.wait(timeout: .now() + 10)
    }

    func testGet() {
        let exp1 = expectation(description: "com.swiftyfire.getbar")
        let exp2 = expectation(description: "com.swiftyfire.getfoo")
        swiftyFire.get(path: "tests/get/bar") { (val, error) in
            guard let val = val else {
                XCTFail()
                return
            }
            XCTAssertEqual(val, .null)
            XCTAssertNil(error)
            exp1.fulfill()
        }

        swiftyFire.get(path: "tests/get/foo") { (val, error) in
            guard let val = val else {
                XCTFail()
                return
            }

            if case .string(let val) = val {
                XCTAssertEqual("bar", val)
            } else {
                XCTFail()
            }
            exp2.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func testPut() {
        let exp1 = expectation(description: "com.swiftyfire.putbar")
        let payload = ["boo": "raz"] as [String: AnyObject]
        swiftyFire.put(path: "tests/put", val: payload) { (val, error) in
            guard let val = val else {
                XCTFail()
                return
            }

            if case .dictionary(let val) = val {
                XCTAssertEqual(val["boo"] as! String, "raz")
            }
            else {
                XCTFail()
            }
            exp1.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testComplexPut() {
        let complexDict: [String: Any] = [
            "key1": "key1",
            "key2": [
                "nested_key1": 1,
            ],
            "bool_val": false
        ]
        let exp1 = expectation(description: "com.swiftyfire.putcomplex")

        swiftyFire.put(path: "tests/complexput", val: complexDict as [String: AnyObject]) { (val, error) in
            guard let val = val else {
                XCTFail()
                return
            }
            if case .dictionary(let val) = val {
                XCTAssertEqual(val["key1"] as! String, "key1")
                XCTAssertFalse(val["bool_val"] as! Bool)
                let nested = val["key2"] as! [String: Int]
                XCTAssertEqual(nested["nested_key1"], 1)
            }
            else {
                XCTFail()
            }
            exp1.fulfill()
        }
        waitForExpectations(timeout: 10)

    }

    func testPatch() {
        let complexDict: [String: Any] = [
            "key1": "key1",
            "key2": [
                "nested_key1": 1,
            ],
            "bool_val": false
        ]
        let exp1 = expectation(description: "com.swiftyfire.patchcomplex1")
        swiftyFire.patch(path: "tests/patch", val: complexDict as [String: AnyObject]) { (val, error) in
            guard let val = val else {
                XCTFail()
                return
            }
            if case .dictionary(let val) = val {
                XCTAssertEqual(val["key1"] as! String, "key1")
                XCTAssertFalse(val["bool_val"] as! Bool)
                let nested = val["key2"] as! [String: Int]
                XCTAssertEqual(nested["nested_key1"], 1)
            }
            else {
                XCTFail()
            }
            exp1.fulfill()
        }

        let exp2 = expectation(description: "com.swiftyfire.patchcomplex2")
        swiftyFire.get(path: "tests/patch/immutable") { (val, err) in
            guard let val = val else {
                XCTFail()
                return
            }

            if case .string(let val) = val {
                XCTAssertEqual("value", val)
            } else {
                XCTFail()
            }
            exp2.fulfill()

        }
        waitForExpectations(timeout: 10)
    }

    func testPost() {
        let exp1 = expectation(description: "com.swiftyfire.post")
        let payload = ["message": "heyo!"]
        swiftyFire.post(path: "tests/post", val: payload as [String : AnyObject]) { (val, error) in
            guard let val = val else {
                XCTFail()
                return
            }
            if case .dictionary(let val) = val {
               XCTAssertNotNil(val["name"])
            }
            else {
                XCTFail()
            }
            exp1.fulfill()

        }
        waitForExpectations(timeout: 10)
    }

    func testDelete() {
        let exp1 = expectation(description: "com.swiftyfire.putbar")
        let exp2 = expectation(description: "com.swiftyfire.delete")

        let payload = ["boo": "raz"] as [String: AnyObject]
        swiftyFire.put(path: "tests/put", val: payload) { (val, error) in
            guard let val = val else {
                XCTFail()
                return
            }

            if case .dictionary(let val) = val {
                XCTAssertEqual(val["boo"] as! String, "raz")
            }
            else {
                XCTFail()
            }
            exp1.fulfill()

            self.swiftyFire.delete(path: "tests/put") { (val, err) in
                guard let val = val else { return }
                XCTAssertEqual(val, .null)
                exp2.fulfill()
            }
        }

        waitForExpectations(timeout: 10)
    }

    func generateAuthentication(completion: @escaping (SwiftyFire) -> Void) {
        let sensitive = Secrets()
        sensitive.getGoogleAuthToken { (token, error) in
            completion(SwiftyFire(token: token!))
        }
    }

    func createTestingEnvironment() {
        let payload = ["foo": "bar"] as [String: AnyObject]
        swiftyFire.put(path: "tests/", val: payload) { _, _ in
        }
    }

    static var allTests = [
        ("testPatch", testPatch),
        ("testPut", testPut),
        ("testComplexPut", testComplexPut),
        ("testGet", testGet)
    ]
}
