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
                                achievements, cosmetics
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

## Achievements, shop and settings

- 11 achievements pay coins once each (`achievement.dart`); unlocked ones
  can be shared with the poster.
- The shop sells tube styles (Jar 60, Flask 120) and backgrounds (Ocean 40,
  Sunset 80, Forest 80), defined in `core/theme/cosmetics.dart`.
- Settings: sound, vibration, colour-blind letters, pour speed, how to
  play, and reset progress.

## Profile

On first launch the game asks for a profile before play starts: a nickname
and an age range, both required, plus an optional picture from the gallery or camera. It is saved on the device only (`profile_repository.dart`)
and never sent anywhere. The nickname appears on the home screen and the
share poster; it can be changed in Settings.

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
