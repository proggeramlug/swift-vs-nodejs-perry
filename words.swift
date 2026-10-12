// Strings and hash maps: build a 5M-word text, split it, count words, top 10.
let WORDS = 5_000_000
let SYLLABLES = ["ka", "lo", "mi", "ne", "ru", "ta", "vo", "zi", "pe", "su"]

var seed = 42
func next() -> Int {
    seed = (seed * 48271) % 2147483647 // Park-Miller
    return seed
}

var parts: [String] = []
for _ in 0..<WORDS {
    let r = next()
    var word = SYLLABLES[r % 10] + SYLLABLES[(r / 10) % 10]
    if r % 3 == 0 { word += SYLLABLES[(r / 100) % 10] }
    parts.append(word)
}
let text = parts.joined(separator: " ")

var counts: [String: Int] = [:]
for w in text.split(separator: " ") { counts[String(w), default: 0] += 1 }

let top = counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.prefix(10)
print("distinct words: \(counts.count)")
for (w, c) in top { print("\(w) \(c)") }
