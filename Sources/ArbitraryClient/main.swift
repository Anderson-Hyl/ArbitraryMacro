import Arbitrary
import Foundation


let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")



@Arbitrary
struct HealthData {
    let id = UUID()
    let value: Double
}


