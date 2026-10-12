// Arrays of small records: 1M particles, 100 simulation steps.
// In Swift each particle is a struct stored inline in the array.
import Foundation

struct Particle {
    var x: Double, y: Double, vx: Double, vy: Double
}

let COUNT = 1_000_000
let STEPS = 100
let DT = 0.01

var particles: [Particle] = []
for i in 0..<COUNT {
    particles.append(Particle(x: Double(i % 1000), y: Double(i / 1000),
                              vx: Double((i * 7) % 13 - 6), vy: Double((i * 11) % 17 - 8)))
}

for _ in 0..<STEPS {
    for i in particles.indices {
        particles[i].vy -= 9.81 * DT
        particles[i].x += particles[i].vx * DT
        particles[i].y += particles[i].vy * DT
        if particles[i].y < 0 {
            particles[i].y = -particles[i].y
            particles[i].vy = -particles[i].vy * 0.9
        }
    }
}

var energy = 0.0
for p in particles { energy += 0.5 * (p.vx * p.vx + p.vy * p.vy) + 9.81 * p.y }
print("total energy: \(String(format: "%.3f", energy))")
