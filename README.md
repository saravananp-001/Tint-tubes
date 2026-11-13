# Tint Tubes: Color Sort Puzzle

Ad-free liquid colour sorting puzzle for Android, built with Flutter.

- Launcher name: **Tint Tubes**
- Store title: **Tint Tubes: Color Sort Puzzle**
- Package ID: `com.tinttubes.game`

## Project layout

```
lib/
  main.dart                     entry point
  app.dart                      MaterialApp and theme wiring
  app_services.dart             bundle of repositories, sound and vibration
  core/
    audio/, feedback/           sound effects and vibration
    theme/                      colours, tube styles, background themes
    widgets/                    shared widgets (coin badge, confetti, ...)
  data/                         saved data: progress, settings, daily,
                                achievements, cosmetics, profile
    cloud/                      online service (Firebase) and its stand-in
  features/
    home/                       start screen: daily cards and the tiers
    levels/                     level grid for one difficulty
    game/
      domain/                   pure Dart rules: tubes, solver, generator,
                                difficulty tiers, star scoring
      presentation/             game screen and its widgets
    share/                      milestone poster and sharing
    achievements/               achievement list
    shop/                       tube styles and backgrounds
    settings/                   settings, how to play, reset
    leaderboard/                online leaderboards
    missions/, spin/, stats/    daily missions, lucky wheel, statistics
    challenge/                  friend challenge codes
test/                           mirrors lib/
```

## Levels

- Easy is a 20-level learning tier (5 to 12 tubes). Medium has 100 levels
  (9 to 18 tubes) and Hard has 1000 (12 to 22 tubes).
- Every fifth level is a heart level: each colour fills two tubes, so the
  board is much bigger, a heart bottle fills as tubes are completed, and
  stars pay double coins.

- Hidden-colour levels (Medium from level 8, Hard from level 6): only the
  top colour of each tube shows; the rest is "?" until uncovered.
- Easy level 1 starts with a two-pour walkthrough for new players.

## Daily

- Daily gift: 5 coins on day 1, growing by 3 a day to 23 from day 7.
  Missing a day restarts the streak.
- Daily puzzle: one 7 to 9 colour puzzle per day, 30 coins for the first
  solve.

## Keeping players coming back

- **Daily reminder** (off by default, Settings): local notifications at
  7 pm on the next few days without play; opening the game pushes them
  back (`core/notifications/reminder_service.dart`).
- **Streak freeze**: 25 coins in the shop, two at most; one is used up
  for each missed day to keep the daily streak.
- **Daily missions**: three goals a day from `Mission`, the same for
  everyone that day, each paying coins when claimed.
- **Rush**: as many 4 to 6 colour puzzles as possible in two minutes;
  3 coins per puzzle and a best score.
- **Friend challenge**: any solved level or daily puzzle can be shared as
  a code such as `TT-M23-31`; entering it (home menu) plays the same
  puzzle against that move count. Challenges pay no coins.
- **Player level**: worked out from stars, daily puzzles, Rush best and
  challenge wins (`player_rank.dart`); shown on home and the leaderboard.
- **Lucky spin**: one free spin of the wheel for every 5 new levels.
- **Statistics**: lifetime counters, opened from the home menu.

## Achievements, shop and settings

- 11 achievements pay coins once each (`achievement.dart`); unlocked ones
  can be shared with the poster.
- The shop sells tube styles (Jar 60, Flask 120), backgrounds (Ocean 40,
  Sunset 80, Forest 80, Aurora 100, Candy 100), win effects (Stars 50,
  Bubbles 50, Hearts 70) and streak freezes, defined in
  `core/theme/cosmetics.dart`.
- Seasonal backgrounds (Festival, Winter, Spring, Summer; 60 each) are on
  sale only inside their `Season` and are kept once bought.
- Settings: sound, vibration, colour-blind letters, pour speed, how to
  play, and reset progress.

## Profile

On first launch the game asks for a profile before play starts: a nickname
and an age range, both required, plus an optional picture from the gallery
or camera. It is saved on the device (`profile_repository.dart`) and,
for players of 13 or over, also on the server (see below). The nickname
appears on the home screen and the share poster; it can be changed in
Settings.

## Online leaderboard (Firebase)

Off until `lib/firebase_options.dart` is filled in; until then the game is
fully offline and the leaderboard is hidden.

- Every player of 13 or over has their profile and score saved to
  Firestore; the profile screen says so. Nothing is uploaded for players
  under 13.
- The "Join the online leaderboard" switch on the profile screen only
  decides whether other players see the nickname and score.
- Three boards: stars this week (Monday to Sunday; the top 3 win 100, 60
  and 40 coins, the rest of the top 10 win 20, paid the next time the
  board is opened), today's daily puzzle in fewest moves
  (`daily/{day}/scores/{uid}`), and all-time stars.
- The weekly board needs the composite indexes in
  `firestore.indexes.json`.
- Sign-in is anonymous (no login screen).
- `players/{uid}` holds the private profile (nickname, age range, picture
  marker, stars, levels); `leaderboard/{uid}` holds the public row
  (nickname, stars, levels). The picture goes to Storage at
  `profile_photos/{uid}.jpg` and is readable only by its owner.
- "Delete my online data" in Settings removes all of it and the
  anonymous account, and stops uploads until the player joins the
  leaderboard again.
- Code: `lib/data/cloud/`, `lib/data/online_sync.dart`,
  `lib/features/leaderboard/`. Rules: `firestore.rules`, `storage.rules`
  (deploy with `firebase deploy --only firestore:rules,storage`).
- Scores are written by the app, so they can be forged; the rules only
  cap them at the game's maximum.

## Rewards

- Each level gives 1 to 3 stars, based on moves against the level's par.
- Every new star pays coins: 5 on Easy, 10 on Medium, 20 on Hard.
- Coins unlock tiers: Medium costs 150, Hard costs 400.
- Coins also buy help: a hint costs 1, the extra tube costs 5 (once per level).

These numbers live in `lib/features/game/domain/difficulty.dart` and
`scoring.dart`.

## Sound

All sounds are synthesised: `pour.wav` by `tool/generate_pour_sound.py`,
`complete.wav` (tube completed) and `win.wav` (level solved) by
`tool/generate_jingles.py`. Players switch sound off with the speaker button
or in Settings; the choice is saved.

## Commands

```bash
flutter run
flutter test
flutter build apk --release
```

## Sharing milestones

Clearing level 10, 25, 50, every 100th level, or the last level of a tier
adds a **Share this milestone** button to the win dialog. A share icon also
appears on the home screen once any milestone has been reached. Both open an
animated poster (tubes fill, stars pop, star and coin totals count up) that
is exported as a 1080 px PNG in **Story** (9:16) or **Post** (1:1) shape and
passed to the Android share sheet. The first share of each milestone pays 10 coins (`kShareReward`), only
when an app is actually picked in the share sheet. Code lives in
`lib/features/share/`.
