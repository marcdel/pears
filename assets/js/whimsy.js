// Celebration effects for whimsy mode. Everything here is fire-and-forget:
// a thrown error or missing DOM node must never break board functionality,
// hence the try/catch wrappers.
import confetti from '../vendor/canvas-confetti'

// Big center-screen burst, used when the day's pears are recorded.
export function confettiBurst() {
  try {
    confetti({
      particleCount: 150,
      spread: 90,
      origin: { y: 0.6 },
    })
  } catch (_e) {}
}

// Small star poof at the given viewport coordinates, used when a pear
// lands in a track.
export function sparklePoof(x, y) {
  try {
    confetti({
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

// Staggered scale-bounce on the pear cards that Suggest just assigned.
// Pear card DOM ids look like "42 pear" (id + space + "pear").
export function drumroll(pearIds) {
  try {
    pearIds.forEach((id, index) => {
      const el = document.getElementById(`${id} pear`)
      if (!el) return
      el.style.animationDelay = `${index * 150}ms`
      el.classList.add('whimsy-pop')
      el.addEventListener(
        'animationend',
        () => {
          el.classList.remove('whimsy-pop')
          el.style.animationDelay = ''
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
