# swift-vs-typescript

Does idiomatic Swift "surely outperform" idiomatic TypeScript because JavaScript's types are broader and more expensive? This repo tests that claim with four small workloads. Each is written once in plain, idiomatic TypeScript and once in plain, idiomatic Swift. The TypeScript runs on **Node** (V8 JIT) and is also compiled ahead of time to native code by **[Perry](https://perryts.com)**.

Every implementation must print identical output. `run.sh` checks this, and all 12 match.

## Results (Linux, AMD Ryzen 7 7700X)

Times are the mean of 5 hyperfine runs after 1 warm-up. Runs were pinned to 2 cores / 4 threads, and each workload started only once the machine's 1-minute load was below 3; the measured load was 2.2–3.7 (`load.txt`). Standard deviations are in the JSON files and are at most 3.3%.

| workload | what it stresses | Node | Perry | Swift | fastest | Swift vs best TS |
|---|---|---:|---:|---:|---|---:|
| `collatz` | integer math (values exceed 32 bits) | 4.41 s | 2.30 s | 0.40 s | **Swift** | Swift 5.75× faster |
| `particles` | array of 1M small records, 100 update steps | 4.58 s | 1.48 s | 1.34 s | **Swift** | Swift 1.11× faster |
| `words` | build a 5M-word string, split, count in a hash map, sort | 1.14 s | 1.95 s | 1.35 s | **Node** | Swift 1.19× slower |
| `trees` | binary-trees: ~300M short-lived objects (GC vs ARC) | 6.76 s | 8.56 s | 15.63 s | **Node** | Swift 2.31× slower |

Peak memory (one run each, `/usr/bin/time -v`):

| workload | Node | Perry | Swift |
|---|---:|---:|---:|
| `collatz` | 68 MB | 9 MB | 9 MB |
| `particles` | 649 MB | 91 MB | 48 MB |
| `words` | 599 MB | 516 MB | 401 MB |
| `trees` | 1241 MB | 619 MB | 393 MB |

## Verdict

The claim holds for some workloads and fails for others; neither "Swift always wins" nor "TypeScript always wins" survives.

- **Integer math (`collatz`): Swift wins by a lot,** 11× over Node and 5.8× over Perry. This is the claim's strongest case. JavaScript has one `number` type, a 64-bit float. These values exceed the 32-bit range that JS engines keep as fast integers, so `%` and `/` work on floats, while Swift uses native 64-bit `Int` arithmetic. Idiomatic TypeScript has no cheap way around this. The alternative, `BigInt`, is generally slower still (not measured here).
- **Arrays of records (`particles`): the type system isn't the deciding factor; the memory layout is.** Swift stores `struct`s inline in the array. Node keeps an array of pointers to heap objects and is 3.4× slower. Perry compiles the same TypeScript to within 11% of Swift. Both sides use 64-bit floats, so "broader types" plays no part here.
- **Strings and maps (`words`): Node is fastest.** It beats Swift by 1.2× and Perry by 1.7×. Swift's `String` is Unicode-correct by design, which likely costs something in splitting and hashing; I didn't profile it.
- **Object graphs (`trees`): TypeScript wins.** Node is 2.3× faster than Swift and Perry 1.8× faster. Swift's ARC updates a reference count on every object creation and release; a generational GC allocates by bumping a pointer and frees dead young objects in bulk.

The claim's own premise, that JS types are broader, really does cost performance in numeric code. But "many cases where idiomatic Swift will **surely** outperform" ignores the other side: in object-heavy and string-heavy code, which is a large share of typical app code, the JS runtimes were as fast or faster here. The result depends on the workload, not on the type system alone.

## Versions

| | |
|---|---|
| machine | AMD Ryzen 7 7700X 8-Core Processor, Linux 6.17.0-23-generic x86_64 |
| Node | v26.8.1 |
| Perry | perry 0.5.1659, main `8d75cc43bd` (2026-10-12 10:48:37 +0200), runtime rebuilt at that commit |
| Swift | Swift version 6.3.3 (swift-6.3.3-RELEASE) (-O) |
| hyperfine | hyperfine 1.20.0 |

Perry was built from source with `cargo build --release -p perry -p perry-runtime-static -p perry-stdlib-static` and linked with `PERRY_NO_AUTO_OPTIMIZE=1`. Node runs the `.ts` files directly, using its built-in type stripping.

**macOS results are pending.** At this Perry commit, linking fails on macOS for every program (`section$start$__TEXT$__perry_strings` is undefined). The fix is in progress, and macOS numbers will be added once it lands.

## Caveats

- These are four microbenchmarks, not applications. Each one isolates one effect.
- "Idiomatic" is a judgement call. The TypeScript uses classes, arrays, `Map` and template strings, with no typed arrays. The Swift uses `struct`/`final class`, `[T]` and `[String: Int]`, with no `unsafe` code. Both could be hand-optimised further.
- Wall time only, single-threaded programs. Node and Perry also run GC work.

## Reproduce

```sh
# needs: node >= 23, swiftc, hyperfine, perry
PERRY=perry SWIFTC=swiftc ./build.sh
./run.sh 5 results/<machine>
# on a shared machine:
MAXLOAD=3 WRAP='taskset -c 6,7,14,15 nice -n -10' ./run.sh 5 results/<machine>
```
