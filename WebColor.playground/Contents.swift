import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution

let sRGBColorspace = CGColorSpaceCreateDeviceRGB()

extension UIColor {
    func hex() -> String {
        let components = cgColor.converted(to: sRGBColorspace, intent: .defaultIntent, options: nil)!.components!
        let hexStrings = components.map { String(format: "%02x", Int(255 * $0)) }
        return hexStrings[0] + hexStrings[1] + hexStrings[2]
    }
}

struct WebColorContrastResponse: Decodable {
    let ratio: CGFloat
    let AA: String
    let AALarge: String
    let AAA: String
    let AAALarge: String
}

// Example
// request: https://webaim.org/resources/contrastchecker/?fcolor=000000&bcolor=FFFFFF&api
// response: {"ratio":8.59,"AA":"pass","AALarge":"pass","AAA":"pass","AAALarge":"pass"}
func checkContrast(_ foreground: UIColor, _ background: UIColor, completionHandler: @escaping (WebColorContrastResponse?) -> ()) {
    let url = URL(string: "https://webaim.org/resources/contrastchecker/?fcolor=\(foreground.hex())&bcolor=\(background.hex())&api")!
    let task = URLSession.shared.dataTask(with: url) { (data, _, _) in
        guard let data = data else {
            completionHandler(nil)
            return
        }
        let response = try? JSONDecoder().decode(WebColorContrastResponse.self, from: data)
        completionHandler(response)
    }
    task.resume()
}

// Unit Tests
var testResults = ""
func test(_ expression: Bool) {
    testResults.append(expression ? "." : "F")
}
func testContrast(_ c1: UIColor, _ c2: UIColor, expectedRatio: CGFloat) {
    checkContrast(c1, c2) { (observed) in
//        print("\(String(describing: observed?.ratio)) =?= \(expectedRatio)")
        test(observed?.ratio == expectedRatio)
    }
}

test(UIColor.green.hex() == "00ff00")
test(UIColor.red.hex() == "ff0000")
test(UIColor.blue.hex() == "0000ff")
test(UIColor.black.hex() == "000000")
test(UIColor.gray.hex() == "7f7f7f")

testContrast(.black, .white, expectedRatio: 21.0)
testContrast(.white, .black, expectedRatio: 21.0)
testContrast(.green, .white, expectedRatio: 1.37)
testContrast(.green, .black, expectedRatio: 15.3)
testContrast(.red, .black, expectedRatio: 5.25)
testContrast(.red, .white, expectedRatio: 4.0)
testContrast(.blue, .black, expectedRatio: 2.44)
testContrast(.blue, .white, expectedRatio: 8.59)
testContrast(.gray, .black, expectedRatio: 5.24)
testContrast(.darkGray, .black, expectedRatio: 2.82)
testContrast(.lightGray, .white, expectedRatio: 2.32)
testContrast(.gray, .white, expectedRatio: 4.0)
sleep(2) // hack to wait for all tests to finish...tune for your internet speed.


print(testResults)
