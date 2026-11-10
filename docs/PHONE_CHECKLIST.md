# Phone checklist (M7.6)

Run through this on a real phone before each test release. Tick in a copy of this file, or note failures in
`docs/PLAYTEST_NOTES.md`. Automated checks (tests, trail bot) don't cover any of this.

## App lifecycle (mid-hike unless noted)
- [ ] **Home button**, wait 10 s, reopen: the hike is paused (pause card showing), the sun didn't move, sounds come back
- [ ] **Recent apps**, switch to another app for 2+ minutes, come back: same as above
- [ ] **Lock the screen**, unlock: paused, nothing jumped
- [ ] **Incoming call** (ask someone to ring you): game pauses and goes quiet; after the call, resume works
- [ ] **Pull down the notification shade**: game pauses
- [ ] **Swipe the app away** from recent apps mid-hike, reopen: progress from earlier hikes is still there
- [ ] **Swipe the app away right after a summit** (on the results screen), reopen: the summit was saved
- [ ] Leave it in the background **overnight**, reopen: no crash; the Daily card shows a new day

## Android back button (gesture or button)
- [ ] Main menu: leaves the app. With the **Daily card open**: closes the card only
- [ ] Trail select, journal, gear, settings, profile: go back to the menu
- [ ] Journal with an enlarged postcard: closes the postcard only
- [ ] On a hike: opens the pause card; again: resumes. In photo mode: closes photo mode
- [ ] Results screen: goes on to the menu

## Touch
- [ ] Every list scrolls by swiping **on the cards**: trail select, journal (Postcards and Finds), gear, profile
- [ ] A swipe that ends on a card does **not** open it; a plain tap does
- [ ] Walk, jump and back pads respond with two thumbs at once; left-handed setting swaps them

## Clock and daily
- [ ] Do the daily, set the phone's date **back one day**: the daily stays done (no second reward)
- [ ] Set the date **forward one day**: a new daily, streak +1. Put the date back to automatic afterwards

## Low-end phone (borrow one with 2–3 GB RAM, or use Play's pre-launch report)
- [ ] Startup to the menu under 5 s
- [ ] Hikes hold ~60 fps (30 fps minimum) — debug builds log `PERF` lines: `adb logcat -s godot`
- [ ] A 30-minute session: no crash, phone not too hot, battery drop noted: ____ %

## Playtest (5–10 people)
- [ ] Hand them the phone with a fresh install and say nothing; note where they get stuck in `docs/PLAYTEST_NOTES.md`
