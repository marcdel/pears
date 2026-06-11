// Celebration effects for whimsy mode. Everything here is fire-and-forget:
// a thrown error or missing DOM node must never break board functionality,
// hence the try/catch wrappers.
import confetti from '../vendor/canvas-confetti'

// Side-cannon finale from both bottom corners, used when the day's pears
// are recorded. Deliberately distinct from the local drop poof.
export function confettiBurst() {
  try {
    const cannon = {
      disableForReducedMotion: true,
      particleCount: 90,
      spread: 60,
      startVelocity: 55,
      gravity: 0.9,
    }
    confetti({ ...cannon, angle: 60, origin: { x: 0.05, y: 0.9 } })
    confetti({ ...cannon, angle: 120, origin: { x: 0.95, y: 0.9 } })
  } catch (_e) {}
}

// Small star poof at the given viewport coordinates, used when a pear
// lands in a track.
export function sparklePoof(x, y) {
  try {
    confetti({
      disableForReducedMotion: true,
      particleCount: 12,
      spread: 50,
      startVelocity: 18,
      gravity: 0.6,
      scalar: 0.7,
      shapes: ['star'],
      colors: ['#facc15', '#fde047', '#fff7c2'],
      origin: {
        x: x / window.innerWidth,
        y: y / window.innerHeight,
      },
    })
  } catch (_e) {}
}

// Low, grey dust kicked up under a card when it slams down. Tied to
// animationend so reduced-motion users (no animation) get no dust either.
function dustPoof(el) {
  try {
    const rect = el.getBoundingClientRect()
    confetti({
      disableForReducedMotion: true,
      particleCount: 10,
      spread: 120,
      startVelocity: 10,
      gravity: 0.5,
      decay: 0.82,
      scalar: 0.6,
      ticks: 40,
      colors: ['#e7e5e4', '#d6d3d1', '#a8a29e'],
      origin: {
        x: (rect.left + rect.width / 2) / window.innerWidth,
        y: rect.bottom / window.innerHeight,
      },
    })
  } catch (_e) {}
}

// Staggered slam-down on the pear cards that Suggest just placed — each card
// drops in from above scale, lands with a squash, and kicks up dust.
// Pear card DOM ids look like "42 pear" (id + space + "pear").
export function drumroll(pearIds) {
  try {
    pearIds.forEach((id, index) => {
      const el = document.getElementById(`${id} pear`)
      if (!el) return
      el.style.animationDelay = `${index * 150}ms`
      el.classList.add('whimsy-slam')
      el.addEventListener(
        'animationend',
        () => {
          el.classList.remove('whimsy-slam')
          el.style.animationDelay = ''
          dustPoof(el)
        },
        { once: true }
      )
    })
  } catch (_e) {}
}

// Client-side gate for client-initiated effects (drop sparkles). The board
// root renders data-whimsy={@whimsy_mode}, so this reflects the flag live.
export function whimsyEnabled() {
  return document.querySelector('[data-whimsy="true"]') !== null
}
