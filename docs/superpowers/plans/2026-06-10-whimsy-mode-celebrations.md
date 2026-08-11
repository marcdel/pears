# Whimsy Mode Celebrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the (currently no-op) Whimsy Mode toggle trigger three celebration effects on the pairing board: confetti on Save, sparkles on pear drop, and a staggered fly-in "drumroll" on Suggest.

**Architecture:** All effects are gated on the existing `:whimsy_mode` FunWithFlags flag (per-team actor). Server-triggered effects (confetti, drumroll) use LiveView `push_event/3` — the server only pushes when whimsy is on, so the client needs no flag logic for those. The one client-initiated effect (drop sparkles) is gated by a `data-whimsy` attribute rendered from the existing `@whimsy_mode` assign. All celebration JS lives in a new isolated module, `assets/js/whimsy.js`.

**Tech Stack:** Elixir/Phoenix LiveView, esbuild (no npm — JS deps are vendored in `assets/vendor/`), Tailwind CSS, canvas-confetti v1.9.3 (vendored ESM build).

**Spec:** `docs/superpowers/specs/2026-06-10-whimsy-mode-celebrations-design.html`

**Environment notes (read before running anything):**
- Tests need the Docker postgres running and `CLOAK_KEY` set. If `mix` behaves strangely, unset `RELEASE_*`, `BINDIR`, `ROOTDIR` env vars and remove Milhouse entries from `PATH` first.
- Run tests with: `mix test test/pears_web/live/pairing_board_live_test.exs`
- Build assets with: `mix assets.build` (this is how you "compile" the JS — there is no node/npm test runner in this repo).
- **Do NOT enable auto-merge on the PR for this work.** Marc wants to test it locally before merging. This overrides the usual auto-merge habit for this repo.

**Key codebase facts:**
- `FeatureFlags.enabled?(:whimsy_mode, for: team)` / `FeatureFlags.enable(:whimsy_mode, for_actor: team)` — both `Pears.Core.Team` (domain) and `Pears.Accounts.Team` structs resolve to the same actor id `"team:#{name}"` (see `lib/pears/feature_flags.ex:10-16`), so tests can enable flags with the Accounts team from `register_and_log_in_team`.
- Pear cards render as `<li id={"#{@pear.id} pear"}>` (note the space in the DOM id) in `lib/pears_web/components/pear.html.heex:3`. A pear keeps the same DOM id whether it's in Available Pears or a track.
- `Pears.recommend_pears(team_name)` returns `{:ok, updated_team}`; the current handler ignores the result and relies on a PubSub broadcast to refresh. The drumroll task changes this (see Task 5).
- Events pushed via `push_event/3` in the same reply as an assign are dispatched on the client **after** the DOM patch, so drumroll animation targets will exist when the listener runs.
- The board has two drag systems: legacy `Pear`/`Destination` hooks in `assets/js/app.js` and the Sortable-based hook in `assets/js/dragHook.js` (behind the `:new_drag_n_drop` flag). Drop sparkles must cover both.

---

### Task 1: Vendor canvas-confetti

**Files:**
- Create: `assets/vendor/canvas-confetti.js`

- [ ] **Step 1: Download the pinned ESM build**

```bash
curl -fsSL https://cdn.jsdelivr.net/npm/canvas-confetti@1.9.3/dist/confetti.module.mjs -o assets/vendor/canvas-confetti.js
```

- [ ] **Step 2: Verify the file is a real ESM module**

Run: `tail -c 200 assets/vendor/canvas-confetti.js`
Expected: output ends with something like `export { ... as default, ... };` (an ESM export statement). If the file is empty or HTML, the download failed — stop and report.

- [ ] **Step 3: Add a provenance header comment**

Prepend these two lines to `assets/vendor/canvas-confetti.js` (above the existing first line):

```js
// canvas-confetti v1.9.3 — https://github.com/catdad/canvas-confetti (ISC license)
// Vendored from https://cdn.jsdelivr.net/npm/canvas-confetti@1.9.3/dist/confetti.module.mjs
```

- [ ] **Step 4: Commit**

```bash
git add assets/vendor/canvas-confetti.js
git commit -m "Vendor canvas-confetti 1.9.3 for whimsy mode celebrations"
```

---

### Task 2: whimsy.js module, CSS keyframes, and app.js listeners

No automated JS tests exist in this repo (no node toolchain); the verification step for client code is `mix assets.build` (esbuild catches syntax/import errors) plus manual browser verification at the end (Task 7).

**Files:**
- Create: `assets/js/whimsy.js`
- Modify: `assets/js/app.js`
- Modify: `assets/css/app.css`

- [ ] **Step 1: Create `assets/js/whimsy.js`**

```js
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
```

- [ ] **Step 2: Wire listeners and imports into `assets/js/app.js`**

Add the import after the existing `import Drag from './dragHook'` line (line 24):

```js
import {confettiBurst, sparklePoof, drumroll, whimsyEnabled} from './whimsy'
```

Add the window listeners next to the existing `phx:page-loading-*` listeners (after line 108):

```js
window.addEventListener("phx:whimsy:confetti", _e => confettiBurst())
window.addEventListener("phx:whimsy:drumroll", e => drumroll(e.detail.pears))
```

- [ ] **Step 3: Add the `whimsy-pop` keyframe animation to `assets/css/app.css`**

Append to the end of the file:

```css
/* Whimsy mode: staggered scale-bounce applied to pear cards after Suggest.
   animation-fill-mode backwards keeps delayed cards at scale(0) until their
   stagger delay elapses, so they "arrive" one by one. */
.whimsy-pop {
  animation: whimsy-pop 0.45s cubic-bezier(0.34, 1.56, 0.64, 1) backwards;
}

@keyframes whimsy-pop {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  60% {
    transform: scale(1.15);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}
```

- [ ] **Step 4: Verify the bundle builds**

Run: `mix assets.build`
Expected: exits 0, no esbuild errors. (Tailwind may print content warnings; only esbuild errors matter here.)

- [ ] **Step 5: Commit**

```bash
git add assets/js/whimsy.js assets/js/app.js assets/css/app.css
git commit -m "Add whimsy celebration JS module, listeners, and pop animation"
```

---

### Task 3: Render data-whimsy attribute on the board root

**Files:**
- Modify: `lib/pears_web/live/pairing_board_live.html.heex:17`
- Test: `test/pears_web/live/pairing_board_live_test.exs`

- [ ] **Step 1: Write the failing tests**

Add a new describe block at the bottom of `test/pears_web/live/pairing_board_live_test.exs` (before the final `end`):

```elixir
  describe "whimsy mode celebrations" do
    setup :register_and_log_in_team

    test "board root advertises whimsy mode to the client when enabled",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)

      {:ok, _view, html} = live(conn, ~p"/teams")

      assert html =~ ~s(data-whimsy="true")
    end

    test "board root advertises whimsy mode off by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/teams")

      assert html =~ ~s(data-whimsy="false")
    end
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/pears_web/live/pairing_board_live_test.exs`
Expected: the two new tests FAIL (no `data-whimsy` in the rendered HTML); all pre-existing tests still pass.

- [ ] **Step 3: Add the attribute to the board root div**

In `lib/pears_web/live/pairing_board_live.html.heex`, change line 17 from:

```heex
<div class="px-4 py-8 sm:px-0">
```

to:

```heex
<div class="px-4 py-8 sm:px-0" data-whimsy={to_string(@whimsy_mode)}>
```

(`@whimsy_mode` already exists — it's assigned in `mount/3` and updated by the `toggle-whimsy-mode` handler, so the attribute live-updates when the switch is flipped.)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/pears_web/live/pairing_board_live_test.exs`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/pears_web/live/pairing_board_live.html.heex test/pears_web/live/pairing_board_live_test.exs
git commit -m "Render data-whimsy attribute on board root for client-side gating"
```

---

### Task 4: Confetti push event on Save

**Files:**
- Modify: `lib/pears_web/live/pairing_board_live.ex:104-130` (the `record-pears` handler) plus a new private helper
- Test: `test/pears_web/live/pairing_board_live_test.exs`

- [ ] **Step 1: Write the failing tests**

Add inside the `describe "whimsy mode celebrations"` block from Task 3:

```elixir
    test "Save pushes a confetti event when whimsy mode is on",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Save") |> render_click()

      assert_push_event(view, "whimsy:confetti", %{})
    end

    test "Save pushes no confetti event when whimsy mode is off", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Save") |> render_click()

      refute_push_event(view, "whimsy:confetti", %{})
    end
```

Note: clicking Save with an empty board succeeds (the existing "recording pears when Slack is failing" test relies on this), so no pear/track setup is needed. The Slack summary is only posted when `:send_daily_pears_summary` is enabled for the team, which it is not here, so no Mox stubs are needed.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/pears_web/live/pairing_board_live_test.exs`
Expected: "Save pushes a confetti event..." FAILS (no `whimsy:confetti` event); the "no confetti when off" test passes trivially; all pre-existing tests still pass.

- [ ] **Step 3: Push the event from the record-pears handler**

In `lib/pears_web/live/pairing_board_live.ex`, change the success branch of the `record-pears` handler (currently lines 110-116) from:

```elixir
      {:ok, _updated_team} ->
        # Post the Slack summary off the reply path so a slow or failing Slack
        # call can't block the response or crash this handler. The board itself
        # refreshes via the PubSub team-updated broadcast that record_pears fires.
        send(self(), {:post_daily_pears_summary, team_name})

        {:noreply, put_flash(socket, :info, "Today's assigned pears have been recorded!")}
```

to:

```elixir
      {:ok, _updated_team} ->
        # Post the Slack summary off the reply path so a slow or failing Slack
        # call can't block the response or crash this handler. The board itself
        # refreshes via the PubSub team-updated broadcast that record_pears fires.
        send(self(), {:post_daily_pears_summary, team_name})

        {:noreply,
         socket
         |> put_flash(:info, "Today's assigned pears have been recorded!")
         |> maybe_push_confetti()}
```

Then add this private helper next to the other private helpers (e.g. directly below `whimsy_mode?/1` at line 33):

```elixir
  defp maybe_push_confetti(socket) do
    if whimsy_mode?(team(socket)) do
      push_event(socket, "whimsy:confetti", %{})
    else
      socket
    end
  end
```

(`whimsy_mode?/1` re-reads the flag rather than trusting the `@whimsy_mode` assign, because another browser tab for the same team can flip the flag after this LiveView mounted. `Pears.Core.Team` and `Pears.Accounts.Team` resolve to the same FunWithFlags actor id, so passing the domain team here matches what the toggle handler writes.)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/pears_web/live/pairing_board_live_test.exs`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/pears_web/live/pairing_board_live.ex test/pears_web/live/pairing_board_live_test.exs
git commit -m "Push whimsy:confetti event when pears are recorded with whimsy on"
```

---

### Task 5: Drumroll push event on Suggest

**Files:**
- Modify: `lib/pears_web/live/pairing_board_live.ex:76-88` (the `recommend-pears` handler) plus a new private helper
- Test: `test/pears_web/live/pairing_board_live_test.exs`

- [ ] **Step 1: Write the failing tests**

Add inside the `describe "whimsy mode celebrations"` block:

```elixir
    test "Suggest pushes a drumroll event with the newly assigned pear ids when whimsy mode is on",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)
      {:ok, _} = Pears.add_pear(team.name, "Pear One")
      {:ok, _} = Pears.add_pear(team.name, "Pear Two")
      {:ok, team_with_pears} = Pears.lookup_team_by(name: team.name)
      pear_ids = team_with_pears.available_pears |> Map.values() |> Enum.map(& &1.id)

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Suggest") |> render_click()

      assert_push_event(view, "whimsy:drumroll", %{pears: pushed_ids})
      assert Enum.sort(pushed_ids) == Enum.sort(pear_ids)
    end

    test "Suggest pushes no drumroll event when whimsy mode is off",
         %{conn: conn, team: team} do
      {:ok, _} = Pears.add_pear(team.name, "Pear One")

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Suggest") |> render_click()

      refute_push_event(view, "whimsy:drumroll", %{pears: _})
    end

    test "Suggest pushes no drumroll event when nothing gets assigned",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Suggest") |> render_click()

      refute_push_event(view, "whimsy:drumroll", %{pears: _})
    end
```

Notes:
- `Pears.add_pear/2` (`lib/pears.ex:85`) adds an available pear. No tracks are needed: `Pears.recommend_pears/1` calls `maybe_add_empty_tracks/1`, which creates tracks for available pears, so both pears get assigned.
- The assertion sorts ids because the recommendation order is not guaranteed.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `mix test test/pears_web/live/pairing_board_live_test.exs`
Expected: the first new test FAILS (no `whimsy:drumroll` event); the two refute tests pass trivially; all pre-existing tests still pass.

- [ ] **Step 3: Implement the drumroll push**

In `lib/pears_web/live/pairing_board_live.ex`, replace the `recommend-pears` handler (currently lines 76-88):

```elixir
  @impl true
  @decorate trace("team_live.recommend_pears", include: [:team_name])
  def handle_event("recommend-pears", _params, socket) do
    team_before = team(socket)
    team_name = team_before.name

    case Pears.recommend_pears(team_name) do
      {:ok, updated_team} ->
        {:noreply, maybe_push_drumroll(socket, team_before, updated_team)}

      {:error, error} ->
        O11y.set_error(error)
        {:noreply, socket}

      error ->
        O11y.set_error(error)
        {:noreply, socket}
    end
  end
```

Then add this private helper next to `maybe_push_confetti/1`:

```elixir
  # Assigns the updated team in the same reply as the push_event so the
  # DOM patch (pears in their new tracks) is applied before the client
  # dispatches the drumroll event — the animation targets must exist.
  defp maybe_push_drumroll(socket, team_before, updated_team) do
    socket = assign(socket, team: updated_team)

    assigned_pear_ids =
      team_before.available_pears
      |> Map.values()
      |> Enum.reject(fn pear -> Map.has_key?(updated_team.available_pears, pear.name) end)
      |> Enum.map(& &1.id)

    if whimsy_mode?(updated_team) and assigned_pear_ids != [] do
      push_event(socket, "whimsy:drumroll", %{pears: assigned_pear_ids})
    else
      socket
    end
  end
```

(The PubSub team-updated broadcast still fires and re-assigns the team via `handle_info`; the extra `assign` here is idempotent and exists for event/patch ordering.)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `mix test test/pears_web/live/pairing_board_live_test.exs`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/pears_web/live/pairing_board_live.ex test/pears_web/live/pairing_board_live_test.exs
git commit -m "Push whimsy:drumroll event with assigned pears on Suggest"
```

---

### Task 6: Sparkles on drop (both drag systems)

Client-side only, gated by `whimsyEnabled()` (the `data-whimsy` attribute from Task 3). No sparkles when dropping a pear on the remove zone — celebrating a removal would be off-key.

**Files:**
- Modify: `assets/js/app.js` (the `Hooks.Destination` drop handler, currently lines 87-98)
- Modify: `assets/js/dragHook.js` (the Sortable `onEnd` callback)

- [ ] **Step 1: Add sparkles to the legacy Destination drop handler**

In `assets/js/app.js`, change the `drop` listener inside `Hooks.Destination` from:

```js
    this.el.addEventListener("drop", e => {
      e.preventDefault()
      e.target.classList.remove("dragged-over")

      let from = event.dataTransfer.getData("current-location")
      let to = e.target.getAttribute("phx-value-destination")
      let pear = event.dataTransfer.getData("pear-name")

      console.debug({from, to, pear})

      this.pushEvent("move-pear", {from, to, pear})
    })
```

to:

```js
    this.el.addEventListener("drop", e => {
      e.preventDefault()
      e.target.classList.remove("dragged-over")

      let from = event.dataTransfer.getData("current-location")
      let to = e.target.getAttribute("phx-value-destination")
      let pear = event.dataTransfer.getData("pear-name")

      console.debug({from, to, pear})

      this.pushEvent("move-pear", {from, to, pear})

      if (whimsyEnabled() && to !== "Removed") {
        sparklePoof(e.clientX, e.clientY)
      }
    })
```

- [ ] **Step 2: Add sparkles to the Sortable drag system**

In `assets/js/dragHook.js`, add the import at the top and extend `onEnd`:

```js
import Sortable from '../vendor/Sortable';
import {sparklePoof, whimsyEnabled} from './whimsy';

export default {
  mounted() {
    let dragged;
    const hook = this;

    const selector = '#' + this.el.id;

    document.querySelectorAll('.dropzone').forEach((dropzone) => {
      new Sortable(dropzone, {
        animation: 0,
        delay: 50,
        delayOnTouchOnly: true,
        group: 'shared',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        onEnd: function (evt) {
          hook.pushEventTo(selector, 'move-pear', {
            from: evt.from.id,
            pear: evt.item.id,
            to: evt.to.id,
          });

          if (whimsyEnabled() && evt.to.id !== 'Removed') {
            const rect = evt.item.getBoundingClientRect();
            sparklePoof(rect.left + rect.width / 2, rect.top + rect.height / 2);
          }
        },
      });
    });
  },
};
```

(The whole file is shown — only the two-line import and the `if (whimsyEnabled() ...)` block are new. The element's bounding rect is used for coordinates because Sortable's `onEnd` event doesn't carry reliable pointer coordinates across mouse and touch.)

- [ ] **Step 3: Verify the bundle builds**

Run: `mix assets.build`
Expected: exits 0, no esbuild errors.

- [ ] **Step 4: Commit**

```bash
git add assets/js/app.js assets/js/dragHook.js
git commit -m "Fire sparkle poof on pear drop when whimsy mode is on"
```

---

### Task 7: Full verification and PR

- [ ] **Step 1: Run the full test suite**

Run: `mix test`
Expected: all tests pass, no new warnings from the changed files. Remember the environment notes at the top (docker postgres, `CLOAK_KEY`, clean env).

- [ ] **Step 2: Build assets cleanly**

Run: `mix assets.build`
Expected: exits 0.

- [ ] **Step 3: Manual browser verification**

Start the app (`mix phx.server`) and on the board:

1. With Whimsy Mode **off**: Save, Suggest, and drag-drop a pear — confirm **no** effects appear and everything works as before.
2. Flip Whimsy Mode **on** (no page reload):
   - Drag a pear into a track → small gold star poof at the drop point.
   - Drag a pear onto the remove zone → no poof.
   - Click Suggest with available pears → assigned pear cards pop into their tracks one by one, ~150 ms apart.
   - Click Save → full confetti burst; flash message still shows.
3. Flip Whimsy Mode **off** again (no reload) and drag a pear → no poof (proves the `data-whimsy` gate live-updates).

- [ ] **Step 4: Open a PR — WITHOUT auto-merge**

```bash
git push -u origin HEAD
gh pr create --title "Make whimsy mode actually whimsical: confetti, sparkles, and a suggest drumroll" --body "$(cat <<'EOF'
## Summary
- Whimsy Mode (previously a no-op April Fools toggle) now triggers three celebration effects, all gated on the existing `:whimsy_mode` flag
- Confetti burst when the day's pears are recorded (server-pushed `whimsy:confetti` event)
- Star sparkle poof when a pear is dropped into a track, in both drag systems (client-gated via `data-whimsy`)
- Staggered fly-in animation on pear cards assigned by Suggest (server-pushed `whimsy:drumroll` event)
- canvas-confetti 1.9.3 vendored into `assets/vendor/` (this repo has no npm toolchain)

With the flag off, behavior is unchanged.

## Test plan
- [ ] `mix test` passes (push-event and `data-whimsy` attribute coverage added)
- [ ] Manual: effects appear with whimsy on, absent with whimsy off (see plan Task 7)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Do NOT run `gh pr merge --auto`.** Marc will test locally first and merge himself.
