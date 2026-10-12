// Strings and hash maps: build a 5M-word text, split it, count words, top 10.
const WORDS = 5_000_000;
const SYLLABLES = ["ka", "lo", "mi", "ne", "ru", "ta", "vo", "zi", "pe", "su"];

let seed = 42;
function next(): number {
  seed = (seed * 48271) % 2147483647; // Park-Miller, exact in a double
  return seed;
}

const parts: string[] = [];
for (let i = 0; i < WORDS; i++) {
  const r = next();
  let word = SYLLABLES[r % 10] + SYLLABLES[Math.floor(r / 10) % 10];
  if (r % 3 === 0) word += SYLLABLES[Math.floor(r / 100) % 10];
  parts.push(word);
}
const text = parts.join(" ");

const counts = new Map<string, number>();
for (const w of text.split(" ")) counts.set(w, (counts.get(w) ?? 0) + 1);

const top = [...counts.entries()]
  .sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0))
  .slice(0, 10);
console.log(`distinct words: ${counts.size}`);
for (const [w, c] of top) console.log(`${w} ${c}`);
