// Integer math: longest Collatz chain for starts below LIMIT.
// JS has one number type (a double); values here exceed 32 bits.
const LIMIT = 3_000_000;

function chainLength(start: number): number {
  let n = start;
  let steps = 1;
  while (n !== 1) {
    n = n % 2 === 0 ? n / 2 : 3 * n + 1;
    steps++;
  }
  return steps;
}

let best = 0;
let bestStart = 0;
for (let i = 1; i < LIMIT; i++) {
  const len = chainLength(i);
  if (len > best) {
    best = len;
    bestStart = i;
  }
}
console.log(`longest chain below ${LIMIT}: start ${bestStart}, length ${best}`);
