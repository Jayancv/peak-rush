# Peak Rush — Google Play store listing (draft, M7.9)

Paste-ready text for Play Console > Grow > Store presence > Main store listing.
Images come from the screenshot script (see "Images" below); nothing here is final until the user approves it.

## App name (max 30)
Peak Rush: Hiking Journal

## Short description (max 80)
Hike Nordic peaks and tea country, beat the sunset and fill your travel journal.

## Full description (max 4000)
Lace up your boots. Peak Rush is a calm, side-scrolling hiking game about pacing yourself
from trailhead to summit before the sun goes down.

TWO SEASONS, ELEVEN TRAILS
Nordic Trails: forest lakes, island rocks, open fells, a rainy fjord ridge, a misty crane bog
and a night climb under the northern lights.
Tea Country: tea-estate terraces, a railway walk to Ella Rock, a train crossing a stone viaduct
in the monsoon, the misty edge of World's End, and a lantern-lit pilgrimage to watch the sunrise.

PACE YOUR ENERGY AND WATER
Hold to walk, tap to jump roots and rocks. Uphill climbs drain your energy; rest on a bench
or stand still to recover. Fill your bottle at springs and streams. Push too hard and you'll
stumble, but walk steadily and you'll find your flow.

RACE THE DAYLIGHT
The sun moves across the sky as you hike. Reach the summit cairn before dusk to earn the
third star, or take the long way round and enjoy the view.

TAKE THE PERFECT SHOT
Stop at scenic viewpoints and wait for the seabirds, a passing boat or the reindeer herd to
cross your viewfinder. Great photos become postcards in your travel journal.

FIND HIDDEN THINGS
Cloudberries, chanterelles, a lost compass, a shy arctic fox. Every trail hides finds, some
of them off the main path on hidden lookouts. Stand still and the animals might show up.

A NEW DAILY TRAIL
Every day brings one of your trails with a twist: thick fog, a headwind, a heavy pack,
a short day or a photo hunt. Keep your daily streak going.

GEAR UP
Spend trail points on grip boots, poles, a rain shell, a thermos and a brighter headlamp, choose your hiker's look, and earn
badges along the way.

- Short hikes of 2 to 4 minutes, perfect for a break
- Plays fully offline
- No lives, no waiting and nothing to buy
- Free, with optional ads for bonus trail points

## Category and tags
- App category: **Game > Casual** (alternative: Adventure)
- Tags (pick up to 5 in Console): Casual, Adventure, Offline, Single player, Stylized

## Contact details
- Email: *(user: a support address you're happy to show publicly)*
- Website: optional
- Privacy policy: *(URL once docs/PRIVACY.md is hosted; also set AboutCard.PRIVACY_URL)*

## Images
Made by `godot --path . --resolution 1920x1080 tools/store_shots/store_shots.tscn`
(writes `export/store/`, not committed). Upload in this order:

| File | Caption |
|---|---|
| `01_aurora.png` | Hike under the northern lights |
| `02_photo.png` | Snap the perfect postcard |
| `03_summit.png` | Beat the sunset to the summit |
| `04_forest.png` | Pace your energy, trail by trail |
| `05_mire.png` | Choose your path |
| `06_journal.png` | Fill your travel journal |
| `07_results.png` | Earn three stars on every trail |
| `08_fjord.png` | Brave rain, wind, fog and snow |
| `feature_graphic.png` | 1024 x 500 feature graphic |
| `icon_512.png` | 512 x 512 store icon (copy of shared_art/icons/icon_512.png) |

Captioned shots are what you upload; the uncaptioned originals are in `export/store/raw/` (handy
for A/B testing captioned vs plain in Play's store listing experiments). The first screenshot
matters most, so the aurora leads. Captions live in `CAPTIONS` in tools/store_shots/store_shots.gd.

Play's rules: 2–8 phone screenshots, 16:9 landscape is fine, each side 320–3840 px; the
feature graphic is required and must be exactly 1024 x 500 (no alpha). Tablet screenshots are
optional; the same 1920 x 1080 files can be reused for 7" and 10" tablets.

## Content rating (IARC questionnaire) — expected answers
- Category: Game
- Violence, fear, sexuality, language, controlled substances, gambling: **No** to all
  (a stumble or a slip off a ledge is not violence; the hiker just respawns at the checkpoint)
- Users can interact or exchange content: **No**
- Shares the user's location: **No**
- Digital purchases: **No**
- Contains ads: **Yes**
Expected result: PEGI 3 / Everyone.

## Target audience and content
- Target age: **13 and over** (recommended). Including under-13s puts the app under the Families
  policy (Families-certified ad SDKs only, child-directed ad settings). *Decision for the user.*
- Appeals to children? Answer honestly: the art is friendly but the game isn't made for kids; with
  13+ chosen, Play may still ask for a short explanation.

## Ads declaration
- Contains ads: **Yes** (AdMob: an optional rewarded ad on the results screen, a rare
  interstitial between hikes).

## Data safety form (once the AdMob SDK is in)
The game itself collects nothing. The answers come from the AdMob SDK; check Google's current
"AdMob data disclosure" page when filling the form, since it is the source of truth.
- Data collected and shared (by the ads SDK), for **Advertising or marketing** and **Analytics**:
  - Device or other IDs (advertising ID)
  - Approximate location (from the IP address)
  - App activity: app interactions (ad views and taps)
  - App info and performance: crash logs, diagnostics
- Collection is required? Yes (ads can't be turned off); the consent form controls personalisation.
- Data encrypted in transit: **Yes**
- Users can request deletion: **No account exists**; progress lives only on the device and is
  removed with Settings > About > Reset progress or by uninstalling.
- Until the AdMob SDK ships, a build without ads would answer "No data collected".
