// Arrays of small records: 1M particles, 100 simulation steps.
// In JS each particle is a heap object; the array holds references.
class Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  constructor(x: number, y: number, vx: number, vy: number) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
  }
}

const COUNT = 1_000_000;
const STEPS = 100;
const DT = 0.01;

const particles: Particle[] = [];
for (let i = 0; i < COUNT; i++) {
  particles.push(new Particle(i % 1000, Math.floor(i / 1000), ((i * 7) % 13) - 6, ((i * 11) % 17) - 8));
}

for (let s = 0; s < STEPS; s++) {
  for (const p of particles) {
    p.vy -= 9.81 * DT;
    p.x += p.vx * DT;
    p.y += p.vy * DT;
    if (p.y < 0) {
      p.y = -p.y;
      p.vy = -p.vy * 0.9;
    }
  }
}

let energy = 0;
for (const p of particles) energy += 0.5 * (p.vx * p.vx + p.vy * p.vy) + 9.81 * p.y;
console.log(`total energy: ${energy.toFixed(3)}`);
