// Integer math: longest Collatz chain for starts below LIMIT.
// Swift uses native 64-bit Int.
let LIMIT = 3_000_000

func chainLength(_ start: Int) -> Int {
    var n = start
    var steps = 1
    while n != 1 {
        n = n % 2 == 0 ? n / 2 : 3 * n + 1
        steps += 1
    }
    return steps
}

var best = 0
var bestStart = 0
for i in 1..<LIMIT {
    let len = chainLength(i)
    if len > best {
        best = len
        bestStart = i
    }
}
print("longest chain below \(LIMIT): start \(bestStart), length \(best)")
