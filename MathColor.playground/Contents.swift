import UIKit

struct WebColorContrastResponse: Decodable {
    let ratio: CGFloat
    let AA: String
    let AALarge: String
    let AAA: String
    let AAALarge: String
}

let sRGBColorspace = CGColorSpaceCreateDeviceRGB()
let linearRGBColorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear)!
let linearSRGB = CGColorSpace(name: CGColorSpace.linearSRGB)!
let cie = CGColorSpace(name: CGColorSpace.genericXYZ)!

func relativeLuminance(_ color: UIColor) -> CGFloat {
    let components = color.cgColor.converted(to: sRGBColorspace, intent: .defaultIntent, options: nil)!.components!
    let adjusted = components.map { (component) -> CGFloat in
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055)/1.055, 2.4)
        }
    }
    return 0.2126 * adjusted[0]
         + 0.7152 * adjusted[1]
         + 0.0722 * adjusted[2]
}

func contrastRatio(_ c1: UIColor, _ c2: UIColor) -> CGFloat {
    let r1 = relativeLuminance(c1) + 0.05
    let r2 = relativeLuminance(c2) + 0.05
    let contrast = r1 > r2 ? r1 / r2 : r2 / r1
    return contrast
}


func checkContrast(_ foreground: UIColor, _ background: UIColor, completionHandler: @escaping (WebColorContrastResponse?) -> ()) {
    let ratio = contrastRatio(foreground, background)
    let AA = ratio >= 4.5 ? "pass" : "fail"
    let AALarge = ratio >= 3.0 ? "pass" : "fail"
    let AAA = ratio >= 7.0 ? "pass" : "fail"
    let AAALarge = ratio >= 4.5 ? "pass" : "fail"

    let response = WebColorContrastResponse(ratio: ratio, AA: AA, AALarge: AALarge, AAA: AAA, AAALarge: AAALarge)
    completionHandler(response)
}

// Unit Tests
var testResults = ""
func test(_ expression: Bool) {
    testResults.append(expression ? "." : "F")
}

func testClose(_ f1: CGFloat?, f2: CGFloat, delta: CGFloat = 0.05) {
    guard let f1 = f1 else { test(false); return }
    test(abs(f1 - f2) <= delta)
}

func testContrast(_ c1: UIColor, _ c2: UIColor, expectedRatio: CGFloat) {
    checkContrast(c1, c2) { (observed) in
        print("\(String(describing: observed?.ratio)) =?= \(expectedRatio)")
        testClose(observed?.ratio, f2: expectedRatio)
    }
}

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


print(testResults)
