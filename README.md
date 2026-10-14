# swift-vs-nodejs-perry

Does idiomatic Swift "surely outperform" idiomatic TypeScript because JavaScript's types are broader and more expensive? This repo tests that claim with four small workloads. Each is written once in plain, idiomatic TypeScript and once in plain, idiomatic Swift. The TypeScript runs on **Node** (V8 JIT) and is also compiled ahead of time to native code by **[Perry](https://perryts.com)**.

Every implementation must print identical output. `run.sh` checks this, and all 12 match on both machines.

## Results: Linux (AMD Ryzen 7 7700X)

These are the cleaner numbers. Each workload was pinned to 2 cores / 4 threads and started only once the machine's 1-minute load was below 3; actual load was 1.08–1.71. Times are the mean of 5 hyperfine runs after 1 warm-up. The largest standard deviation is 1.6%.

| workload | what it stresses | Node | Perry | Swift | fastest | Swift vs best TS |
|---|---|---:|---:|---:|---|---:|
| `collatz` | integer math (values exceed 32 bits) | 4.33 s | 2.28 s | 0.39 s | **Swift** | Swift 5.77× faster |
| `particles` | array of 1M small records, 100 update steps | 4.47 s | 1.34 s | 1.15 s | **Swift** | Swift 1.17× faster |
| `words` | build a 5M-word string, split, count in a hash map, sort | 1.15 s | 2.08 s | 1.34 s | **Node** | Swift 1.17× slower |
| `trees` | binary-trees: ~300M short-lived objects (GC vs ARC) | 6.38 s | 6.00 s | 15.64 s | **Perry** | Swift 2.61× slower |

## Results: macOS (Apple M1 Max)

This is a working desktop with background load of 4.8–7.4 on 10 cores, unpinned. Same method otherwise. The largest standard deviation is 6.1%.

| workload | what it stresses | Node | Perry | Swift | fastest | Swift vs best TS |
|---|---|---:|---:|---:|---|---:|
| `collatz` | integer math (values exceed 32 bits) | 7.60 s | 3.16 s | 0.62 s | **Swift** | Swift 5.12× faster |
| `particles` | array of 1M small records, 100 update steps | 3.50 s | 1.14 s | 0.83 s | **Swift** | Swift 1.37× faster |
| `words` | build a 5M-word string, split, count in a hash map, sort | 1.50 s | 2.58 s | 1.44 s | **Swift** | Swift 1.04× faster |
| `trees` | binary-trees: ~300M short-lived objects (GC vs ARC) | 6.35 s | 7.96 s | 23.54 s | **Node** | Swift 3.71× slower |

Peak memory (one run each; `/usr/bin/time`):

| workload | Linux: Node / Perry / Swift | macOS: Node / Perry / Swift |
|---|---|---|
| `collatz` | 68 MB / 8 MB / 9 MB | 80 MB / 5 MB / 2 MB |
| `particles` | 654 MB / 92 MB / 48 MB | 672 MB / 91 MB / 84 MB |
| `words` | 597 MB / 521 MB / 401 MB | 636 MB / 592 MB / 471 MB |
| `trees` | 1242 MB / 591 MB / 392 MB | 1261 MB / 666 MB / 259 MB |

## Verdict

The claim holds for some workloads and fails for others; neither "Swift always wins" nor "TypeScript always wins" survives.

- **Integer math (`collatz`): Swift wins by a lot,** 11–12× over Node and 5–6× over Perry, on both machines. This is the claim's strongest case. JavaScript has one `number` type, a 64-bit float. These values exceed the 32-bit range that JS engines keep as fast integers, so `%` and `/` work on floats, while Swift uses native 64-bit `Int` arithmetic. Idiomatic TypeScript has no cheap way around this. The alternative, `BigInt`, is generally slower still (not measured here).
- **Arrays of records (`particles`): Swift wins, but the type system isn't the deciding factor; the memory layout is.** Swift stores `struct`s inline in the array. Node keeps an array of pointers to heap objects and is about 4× slower. Perry compiles the same TypeScript to within 1.2× (Linux) to 1.4× (macOS) of Swift. Both sides use 64-bit floats, so "broader types" plays no part here.
- **Strings and maps (`words`): roughly a tie between Node and Swift.** Node wins on Linux (1.17×) and Swift edges it on macOS (1.04×, within that machine's noise). Perry is 1.7–1.8× behind Node here. Swift's `String` is Unicode-correct by design, which likely costs something in splitting and hashing; I didn't profile it.
- **Object graphs (`trees`): TypeScript wins clearly.** Swift is 2.6× slower than the fastest TS runtime on Linux (Perry) and 3.7× slower on macOS (Node). Swift's ARC updates a reference count on every object creation and release; a generational GC allocates by bumping a pointer and frees dead young objects in bulk.

The claim's own premise, that JS types are broader, really does cost performance in numeric code. But "many cases where idiomatic Swift will **surely** outperform" ignores the other side: in object-heavy and string-heavy code, which is a large share of typical app code, the JS runtimes were as fast or faster here.

## Versions

| | macOS | Linux |
|---|---|---|
| machine | Apple M1 Max, Darwin 25.5.0 arm64 | AMD Ryzen 7 7700X 8-Core Processor, Linux 6.17.0-23-generic x86_64 |
| Node | v26.5.1 | v26.8.1 |
| Perry | main `7bdf9b9d3a` (2026-10-13), runtime rebuilt at that commit | same |
| Swift | Swift version 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101) (-O) | Swift version 6.3.3 (swift-6.3.3-RELEASE) (-O) |
| hyperfine | hyperfine 1.20.0 | hyperfine 1.20.0 |

Measured 2026-10-13. Perry was built from source with `cargo build --release -p perry -p perry-runtime-static -p perry-stdlib-static` and linked with `PERRY_NO_AUTO_OPTIMIZE=1`. Node runs the `.ts` files directly, using its built-in type stripping. A first Linux-only round from 2026-10-12 is kept in [`results/archive-2026-10-12`](results/archive-2026-10-12).

## Caveats

- These are four microbenchmarks, not applications. Each one isolates one effect.
- "Idiomatic" is a judgement call. The TypeScript uses classes, arrays, `Map` and template strings, with no typed arrays. The Swift uses `struct`/`final class`, `[T]` and `[String: Int]`, with no `unsafe` code. Both could be hand-optimised further.
- Wall time only, single-threaded programs. Node and Perry also run GC work; Node does part of it on helper threads.
- The macOS machine wasn't idle; prefer the Linux numbers where the two differ.

## Reproduce

```sh
# needs: node >= 23, swiftc, hyperfine, perry
PERRY=perry SWIFTC=swiftc ./build.sh
./run.sh 5 results/<machine>
# on a shared machine:
MAXLOAD=3 WRAP='taskset -c 6,7,14,15 nice -n -10' ./run.sh 5 results/<machine>
```
