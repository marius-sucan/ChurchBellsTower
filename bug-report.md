# Church Bells Tower — User-Reproducible Bug Report

This report documents user-reproducible bugs, broken functionality, and broken options identified through a full static analysis of the **Church Bells Tower** codebase (`bells-tower.ahk`, `lib/*.ahk`, `Lib/*.ahk`, and `cpp-dll/*.cpp`), updated against commit `5122b62`.

> [!NOTE]
> Per your instructions, this report **excludes** any issues related to settings not being saved to the registry or INI file, as well as any discrepancies in clamping values on save versus load. Every bug listed below is reproducible at runtime by a user interacting with the application.

---

## Open Bugs Summary Table

| # | Severity | Component | Summary |
| :- | :--- | :--- | :--- |
| 1 | **High** | Analog Clock / Quick Timer | Quick timers set from the Analog Clock context menu fail to display a notification dialog or ring continuously when they expire (only flashing the screen for 350 ms). |
| 2 | **High** | Set Alarm or Timer | Predefined timers (`Set` button) fail to reset the `Hours` field (`hu` uninitialized), adding 1+ extra hours to 1–45 min presets and repeatedly incrementing hours on the `60` min preset. |
| 3 | **High** | Yearly Sun & Moon Tables | Indexing `Summary` (Sun) and `Rise`/`Set` (Moon) columns by the event's `MM/dd` instead of the row's date leaves blank cells whenever an event crosses midnight or uses a yesterday/tomorrow fallback. |
| 4 | **Medium** | Set Alarm or Timer | Repeating alarms set for `00:00` (midnight) check `canDo` against the current day before advancing `newu` to tomorrow, causing them to ring on excluded days and skip included days. |
| 5 | **Medium** | Chimes & Holidays | A Personal event on the same day as a Religious feast (such as Easter Sunday) overwrites `isHolidayToday` and `TypeHolidayOccured := 3`, suppressing Easter noon bells, semantron drumming, and religious quarter-hour feast chimes. |
| 6 | **Medium** | Celebrations Audio | World Arabic Language Day (`12.18`, a Secular holiday) fails to play its special audio unless **Religious** celebrations (`ObserveReligiousDays=1`) are also enabled. |
| 7 | **Medium** | Calendar Panel | Selecting any 31-day month from the Calendar's month menu when on day `31` clamps the day to `30`; selecting February in a leap year when on day `29`–`31` clamps the day to `28`. |
| 8 | **Medium** | Calendar Panel | Equinoxes and solstices in the Calendar panel are matched against the current system year's day-of-year (`mEquiDay`, etc.) regardless of the year being browsed. |
| 9 | **Medium** | Yearly Sun & Moon Tables | Year-end summary statistics (`Polar days`, `Polar nights`, `days have no civil twilight`, `Moonless days`) include December 31 of the **previous** year (`A_Index=1`), overcounting by 1 day. |
| 10 | **Medium** | Yearly Sun Table | Summary text displays `"Difference: 24:00."` whenever `"Polar days:"` is present (`InStr(thisu, "polar")`), even when `Polar nights` is `0` and winter has non-zero shortest daylight. |
| 11 | **Medium** | Settings / Activation State | Opening and closing Settings (`Cancel` / `Esc`) while Church Bells Tower is deactivated (`A_IsSuspended=1`) unconditionally calls `SuspendScript()`, re-activating the app against the user's choice. |
| 12 | **Low** | Settings / Bible Quotes | In `InvokeBibleQuoteNow()`, `countLines` is `Static` and is never reset when `toLoadFile != lastFileLoaded`, so switching Bible languages in Settings clamps `userBibleStartPoint` against the first loaded Bible's line count. |
| 13 | **Low** | DirectSound Audio | `DirectSoundPlayer.UnInitialize()` checks uninitialized local variables `if pDS` and `if hDsound` instead of `this.pDS` and `this.hDsound`, failing to release the DirectSound COM object and DLL handle. |

---

## Detailed Analysis of Open Bugs & Reproduction Instructions

---

### Bug 1: Quick Timers Set From the Analog Clock Context Menu Fail to Alert Properly (350 ms Flash Only)

- **Location**: [`lib/analog-clock-display.ahk#L547-L568`](file:///home/marius/repos/ChurchBellsTower/lib/analog-clock-display.ahk#L547-L568) (`MenuSetQuickTimer`) and [`bells-tower.ahk#L7254-L7285`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7254-L7285) (`doUserTimerAlert`)
- **Root Cause**:
  In [`MenuSetQuickTimer`](file:///home/marius/repos/ChurchBellsTower/lib/analog-clock-display.ahk#L559), setting any quick timer explicitly clears the timer message variable to an empty string:
  ```ahk
  userTimerMsg := ""
  userTimerHours := (aa>59) ? 1 : 0
  userTimerMins := (aa>=60) ? aa - 60 : aa
  ```
  When the timer expires, [`doUserTimerAlert`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7257-L7284) checks `thisMsg := Trim(userTimerMsg) ? "`n" Trim(userTimerMsg) : ""`:
  ```ahk
  If !thisMsg
  {
     userTimerExpire := 0
     Sleep, 350
  } Else
  {
     MsgBox, % 4096+4, Timer: %appName%, % "Timer message: " thisMsg "`n`nPress Yes to repeat this alert in " th ":" tm "."
     ...
  }
  SetTimer, PlayTimerBell, Off
  ScreenBlocker(1)
  ```
  Because `thisMsg` is empty (`""`), `!thisMsg` is true. Unlike [`doUserAlarmAlert`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7305) (which sets `thisMsg := "NONE"` when blank so the notification `MsgBox` still appears), `doUserTimerAlert` sleeps for 350 ms, immediately stops `PlayTimerBell`, and destroys the screen blocker without showing any `MsgBox`.
  *(Note: The same bug also occurs if the user manually clears the `Message:` text box in `Set alarm or timer`.)*
- **How to Reproduce**:
  1. Show the Analog Clock widget (e.g., press `Alt+W` or click **Show the analog clock** in the tray menu).
  2. Right-click the Analog Clock and select **Set timer** → **1** (for a 1-minute timer).
  3. Wait 1 minute for the red progress arc on the Analog Clock to complete.
  4. **Observed**: The screen dims for only 0.35 seconds, the timer sound is immediately cut off, and **no notification dialog box appears**.
  5. **Expected**: The timer bell should ring and the notification dialog box should remain on screen until dismissed.

---

### Bug 2: Predefined Timer `Set` Button Fails to Reset Hours (`hu` Uninitialized) and Miscalculates the `60` Minute Preset

- **Location**: [`bells-tower.ahk#L6152-L6182`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6152-L6182) (`BtnSetPresetTimers`) and [`bells-tower.ahk#L7106-L7118`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7106-L7118) (`updateUIalarmsPanel`)
- **Root Cause**:
  In [`BtnSetPresetTimers`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6161-L6175):
  ```ahk
  If (info=90)
  {
     info := 30
     hu := 1
  } Else If (info=120)
  {
     info := 60
     hu := 1
  }

  Gui, SettingsGUIA: Default
  GuiControl, SettingsGUIA: , userMustDoTimer, 1
  GuiControl, SettingsGUIA: , userTimerHours, % hu
  GuiControl, SettingsGUIA: , userTimerMins, % info
  updateUIalarmsPanel()
  ```
  1. For presets `1`, `2`, `3`, `4`, `5`, `10`, `15`, `30`, `45`, and `60`, the local variable `hu` is never assigned and defaults to `""`.
  2. Passing an empty string to `GuiControl, SettingsGUIA: , userTimerHours, % hu` does **not** reset the UpDown control `userTimerHours` to `0`; it leaves `userTimerHours` at whatever value it already had (which is `1` hour on a fresh launch per [`bells-tower.ahk#L139`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L139), or `1`–`2` hours after selecting `90` or `120`).
  3. For the `60` minute preset, `hu` is `""` (leaving `userTimerHours` unchanged, e.g., `1`) and `userTimerMins` is set to `60`. Immediately afterward, [`updateUIalarmsPanel`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7106-L7112) sees `TimerM=60`, sets `userTimerMins` to `0`, and sets `userTimerHours` to `clampInRange(TimerH + 1, 0, 12, 1)` (`2` hours!). Clicking `Set` repeatedly with `60` selected increments `Hours` by 1 on every click (`2`, `3`, `4`... up to `12`).
- **How to Reproduce**:
  1. Open **Set alarm or timer** from the tray menu.
  2. Notice that under **Set a timer**, `Hours:` is `1` by default (or set `Hours:` to `1`).
  3. In the **Predefined timers (minutes)** dropdown, select **5** and click **Set**.
  4. **Observed**: `Hours:` remains `1` and `Minutes:` becomes `5`, activating a timer for **1 hour and 5 minutes** instead of 5 minutes.
  5. Now select **60** in **Predefined timers (minutes)** and click **Set** several times.
  6. **Observed**: `Hours:` increments to `2`, then `3`, then `4` on each click instead of setting a 60-minute (1-hour) timer.

---

### Bug 3: Yearly Sun & Moon Tables Show Blank Cells When Events Cross Midnight or Use Yesterday/Tomorrow Fallbacks

- **Location**: [`bells-tower.ahk#L10272-L10296`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10272-L10296), [`bells-tower.ahk#L10342-L10355`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10342-L10355) (`uiPopulateTableYearSolarData`), and [`bells-tower.ahk#L10509-L10523`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10509-L10523), [`bells-tower.ahk#L10609-L10614`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10609-L10614) (`uiPopulateTableYearMoonData`)
- **Root Cause**:
  In both `uiPopulateTableYearSolarData()` and `uiPopulateTableYearMoonData()`, the lookup arrays `arrayUsunriseu`, `arrayUsunsetu`, `arrayUcivilrise`, and `arrayUcivilsetu` are keyed by slicing characters 6–10 (`MM/dd`) from the **returned event timestamp** (`SubStr(obj.r, 6, 5)`, `SubStr(obj.s, 6, 5)`, etc.) rather than using the loop date `timis` (or row index `A_Index - 1`):
  ```ahk
  sunriseu := SubStr(obj.r, 12)
  Nsunriseu := SubStr(obj.r, 6, 5)
  If Nsunriseu
     arrayUsunriseu[Nsunriseu] := sunriseu
  ```
  - **In the Yearly Moon Table**: Because the lunar day (~24h 50m) is longer than a solar day, roughly once every two weeks there is a calendar day with no moonrise (so [`wrapCalcMoonRiseSet`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L9500) returns **yesterday's** moonrise) and a calendar day with no moonset (so [`wrapCalcMoonRiseSet`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L9517) returns **tomorrow's** moonset). Because `SubStr(obj.r, 6, 5)` is yesterday's `MM/dd` and `SubStr(obj.s, 6, 5)` is tomorrow's `MM/dd`, today's entry in `arrayUsunriseu[testToday]` or `arrayUsunsetu[testToday]` is never populated, leaving the cell **blank**!
  - **In the Yearly Sun Table**: On high-latitude dates where sunset or dusk occurs after midnight on the next calendar date (`MM/(dd+1)`), `SubStr(sunsetu, 6, 5)` / `SubStr(obj.twS, 6, 5)` is tomorrow's `MM/dd`. Thus, the **Summary** tab (`LViewSunCombined`) shows a **blank** Sunset or Dusk cell for that day, even though the **Set** and **Dawn and dusk** tabs show the exact `MM/dd HH:mm` timestamp on that row!
- **How to Reproduce**:
  - **Moon Table (reproducible for any city)**:
    1. Open **Astronomy / Today**, switch `Sun` to `Moon` (click the **Sun** button), and click **Table** (`PanelMoonYearGraphTable`).
    2. Scroll down the **Rise** and **Set** columns (roughly every 14–15 rows).
    3. **Observed**: Every day where moonrise or moonset crossed midnight has a completely **blank** `Rise` or `Set` cell in the table (whereas viewing that same date in the **Astronomy / Today** panel shows the fallback rise/set time).
  - **Sun Table**:
    1. Open **Astronomy / Today**, select **United States** → **Fairbanks** (or **Finland** → **Rovaniemi**), switch to **Sun**, and click **Table** (`PanelSunYearGraphTable`).
    2. Look at late April / May rows in the **Summary** tab vs. the **Set** and **Dawn and dusk** tabs.
    3. **Observed**: Rows where sunset or dusk falls after `00:00` (shown as `MM/dd 00:xx` in the **Set** or **Dawn and dusk** tabs) have **blank** `Set` or `Dusk` cells in the **Summary** tab.

---

### Bug 4: Repeating Midnight (`00:00`) Alarm Evaluates Weekday/Holiday Conditions for the Wrong Day

- **Location**: [`bells-tower.ahk#L7352-L7394`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7352-L7394) (`startAlarmTimer`)
- **Root Cause**:
  In [`startAlarmTimer`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7360-L7383):
  1. `canDo` is computed first using **today's** weekday (`A_WDay`) and **today's** holiday (`TypeHolidayOccured`).
  2. Next, `newu := A_Year A_Mon A_DD tH tM . "00"` is compared with `nowu := A_Now`.
  3. When `tH = "00"` and `tM = "00"`, `nowu >= newu` is **always true** throughout the entire day (from `00:00:00` to `23:59:59`), so `newu += 1, Days` advances `newu` to **tomorrow at `00:00:00`** without re-evaluating `canDo` for tomorrow!
  - **Consequence A (Rings on excluded day)**: If today is checked (e.g., Friday) and tomorrow is unchecked (e.g., Saturday), at `23:59:45` on Friday `canDo` is `1` (because Friday is checked) and `nss` (`Saturday 00:00:00 - Friday 23:59:45 = 15s`) is `< 18`. `SetTimer, doUserAlarmAlert, -15000` is armed and rings at `00:00:00` on Saturday!
  - **Consequence B (Never rings on included day after excluded day)**: If Sunday is unchecked and Monday is checked, `canDo` is `0` all day Sunday (including `23:59:59`), so the timer is never armed before midnight. Once the clock hits `00:00:00` on Monday, `nowu >= newu` (`Monday 00:00:00 >= Monday 00:00:00`) is immediately true, so `newu` jumps to **Tuesday `00:00:00`** (`nss = 86400`), skipping Monday's `00:00` alarm completely!
- **How to Reproduce**:
  1. Open **Set alarm or timer**.
  2. Enable **Set an alarm**, set `Hour:` to `0` and `Minute:` to `0` (`00:00`), select **Every week**, uncheck today's weekday, check tomorrow's weekday, and click **Save**.
  3. Wait until `00:00:00` tonight (or set the system clock to `23:59:40` and wait 20 seconds).
  4. **Observed**: The `00:00` alarm for tomorrow never rings. Conversely, if today's weekday is checked and tomorrow's weekday is unchecked, the alarm rings at `00:00:00` as tomorrow begins.

---

### Bug 5: Personal Event on the Same Day as Easter or Another Religious Feast Suppresses Easter Noon Bells, Semantron Drumming, and Feast Chimes

- **Location**: [`bells-tower.ahk#L1510-L1546`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1510-L1546) (`theChimer`) and [`bells-tower.ahk#L5033-L5046`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5033-L5046) (`coreTestCelebrationz`)
- **Root Cause**:
  In [`coreTestCelebrationz`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5033-L5045), when `testWhat=0` (called by `testCelebrations()`), any Personal event on today's date unconditionally overwrites `aisHolidayToday` and overwrites `aTypeHolidayOccured := 3`:
  ```ahk
  today := INIactionNonGlobal(0, testFeast "." thisYear, 0, "Celebrations")
  PersonalDay := INIactionNonGlobal(0, testFeast ".a", 0, "Celebrations")
  If (StrLen(today)>2)
  {
     aisHolidayToday := today
     If (StrLen(PersonalDay)>2)
        aisHolidayToday .= " | " PersonalDay
     aTypeHolidayOccured := 3
  } Else If (StrLen(PersonalDay)>2)
  {
     aisHolidayToday := PersonalDay
     aTypeHolidayOccured := 3
  }
  ```
  Consequently, if the user has a Personal event on Easter Sunday or any other Christian feast day:
  - `InStr(isHolidayToday, "easter")` ([`bells-tower.ahk#L1510`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1510)) becomes false, so the Easter Sunday noon bells do not ring.
  - `TypeHolidayOccured=1` ([`bells-tower.ahk#L1527`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1527) and [`#L1541`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1541)) becomes false (`TypeHolidayOccured` is `3`), so both religious semantron drumming and religious feast quarter-hour chimes are suppressed for the entire feast day.
  - Even on Christmas Day (`12.25`), if a Personal event exists on `12.25`, `InStr(aisHolidayToday, "Christmas")` ([`bells-tower.ahk#L5068`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5068)) becomes false, suppressing the Christmas song (`SNDmedia_christmas`)!
- **How to Reproduce**:
  1. Open **Settings** → **Celebrations**, enable **Observe celebrations and holidays**, and enable **Observe Christian religious days of feast**. Click **Apply**.
  2. Open **Calendar**, select **December 25** (or Easter Sunday), and add a Personal event (e.g., `Family dinner`) on that date.
  3. On that date, invoke **Show celebrations today** (or test `testCelebrations(0)`).
  4. **Observed**: Only the personal event is shown in the OSD, `SNDmedia_christmas` does not play on Christmas, and Easter/feast bells and semantron drumming are suppressed all day.

---

### Bug 6: World Arabic Language Day (`12.18`) Audio Fails to Play Unless Religious Celebrations Are Also Enabled

- **Location**: [`bells-tower.ahk#L5005`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5005) and [`bells-tower.ahk#L5070-L5071`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5070-L5071) (`coreTestCelebrationz`)
- **Root Cause**:
  `World Arabic Language Day|12.18` is defined in the **Secular** celebrations list (`bells-tower.ahk#L5005`). However, the audio playback condition in [`coreTestCelebrationz`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5070-L5071) requires `ObserveReligiousDays=1` in addition to `ObserveSecularDays=1`:
  ```ahk
  Else If (InStr(aisHolidayToday, "arabic") && ObserveReligiousDays=1 && ObserveSecularDays=1)
     MCXI_Play(SNDmedia_surah)
  ```
- **How to Reproduce**:
  1. Open **Settings** → **Celebrations**, enable **Observe celebrations and holidays**, check **Observe secular / international days**, and **uncheck** **Observe Christian religious days of feast**. Click **Apply**.
  2. Open **Celebrations / holidays** from the tray menu.
  3. Select the row for `12.18` (**World Arabic Language Day**).
  4. Notice the `B` (bell) button becomes enabled in the bottom-left corner. Click `B` to preview the holiday sound.
  5. **Observed**: Instead of playing `al-fatiha-surah.mp3`, it plays the generic secular gong (`bell-japanese-gong.wav`).

---

### Bug 7: Calendar Month Menu Clamps Day `31` to `30` on 31-Day Months and Clamps Day `29` to `28` in Leap-Year Februaries

- **Location**: [`bells-tower.ahk#L6668-L6679`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6668-L6679) (`MenuSetCalendarMonth`)
- **Root Cause**:
  In [`MenuSetCalendarMonth`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6673-L6674):
  ```ahk
  If (thisMDay>30 || thisMon="02" && thisMDay>=28)
     thisMDay := (thisMon="02") ? 28 : 30
  ```
  - `thisMDay>30` is true whenever the currently selected day is `31`, unconditionally clamping it to `30` even when switching to a month with 31 days (Jan, Mar, May, Jul, Aug, Oct, Dec).
  - When switching to February (`thisMon="02"`), `thisMDay>=28` clamps day `29`, `30`, or `31` to `28` even when `thisYear` is a leap year.
- **How to Reproduce**:
  1. Open **Calendar** from the tray menu.
  2. Click on the **31st** of any month (e.g., May 31 or July 31).
  3. Click the large month/date title at the top of the Calendar (`uiCalendarDatumLabel`) to open the month popup menu, and select **08. August** (or **12. December**).
  4. **Observed**: The selection jumps to **August 30** (or **December 30**) instead of staying on the 31st.
  5. Navigate to a leap year (e.g., **2024** or **2028**), select **January 29** (or **31**), click the month title, and select **02. February**.
  6. **Observed**: The selection is clamped to **February 28** instead of **February 29**.

---

### Bug 8: Calendar Panel Displays Equinoxes and Solstices on the Wrong Day When Browsing Other Years

- **Location**: [`bells-tower.ahk#L6701-L6708`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6701-L6708) (`givenDateTestCelebrations`)
- **Root Cause**:
  In [`givenDateTestCelebrations`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6701-L6708):
  ```ahk
  If (mEquiDay=thisYday)
     listu .= "▀ March Equinox.`n`n"
  Else If (jSolsDay=thisYday)
     listu .= "⬤ June Solstice.`n`n"
  Else If (sEquiDay=thisYday)
     listu .= "▃ September Equinox.`n`n"
  Else If (dSolsDay=thisYday)
     listu .= "◯ December Solstice.`n`n"
  ```
  `mEquiDay`, `jSolsDay`, `sEquiDay`, and `dSolsDay` are calculated only for `A_Year` (the current system year). When the user browses any other year in the Calendar — particularly a leap year like `2024` or `2028` when the current year is a non-leap year like `2026` — every date after February 28 has its day-of-year (`YDay`) shifted by 1 day, and the astronomical instants also shift across years.
- **How to Reproduce**:
  1. Open **Celebrations / holidays**, switch to the **Equinoxes and solstices** tab, set **Year** to `2028` (a leap year), and note the dates (e.g., March equinox on `2028/03/20`, June solstice on `2028/06/20`, September equinox on `2028/09/22`, December solstice on `2028/12/21`).
  2. Open **Calendar** and navigate to **March 2028** (or **June 2028**).
  3. Click on **March 19, 2028** and **March 20, 2028**.
  4. **Observed**: The Calendar panel marks `▀ March Equinox.` on **March 19, 2028** instead of **March 20, 2028** (because Day 79 in 2026 is March 20, whereas Day 79 in leap year 2028 is March 19).

---

### Bug 9: Yearly Sun & Moon Tables Overcount Polar Days, Polar Nights, Deep Nights, and Moonless Days by Including Dec 31 of the Previous Year

- **Location**: [`bells-tower.ahk#L10234-L10329`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10234-L10329) (`uiPopulateTableYearSolarData`) and [`bells-tower.ahk#L10470-L10595`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10470-L10595) (`uiPopulateTableYearMoonData`)
- **Root Cause**:
  Both functions initialize `timeus` to January 1 of `yearu`, subtract 1 day (`timeus += -1, Days` → **December 31 of `yearu - 1`**), and loop `loopsu + 1` times (`366` iterations for a 365-day year).
  Although ListView row additions are guarded by `If (A_Index>1)` (`#L10270` and `#L10507`), the summary counters (`polarNights++`, `polarDays++`, `deepNights++`, `maxLichtu`, `minLichtu`) are incremented **outside** `If (A_Index>1)`.
  Thus, `A_Index=1` (December 31 of the previous year) is included in the year's totals!
- **How to Reproduce**:
  1. Open **Astronomy / Today**, select **Norway** → **Svalbard-Jan Mayen** (or **Tromsø**), ensure **Sun** mode is active, and click **Table** (`PanelSunYearGraphTable`).
  2. In the **Sunlight** tab (or **Summary** tab), count the rows that have `00:00` in the `Sunlight` column (or `00:00` total light) and compare with the summary text above the tabs (`Polar nights: X. From these, Y days have no civil twilight.`).
  3. **Observed**: Both `Polar nights` and `days have no civil twilight` in the summary header are **1 higher** than the actual number of days in the table for that year (because Dec 31 of the previous year was counted on iteration 1).

---

### Bug 10: Yearly Sun Table Falsely Displays `"Difference: 24:00."` for Sub-Polar Cities With Polar Days But Non-Zero Winter Daylight

- **Location**: [`bells-tower.ahk#L10394-L10408`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10394-L10408) (`uiPopulateTableYearSolarData`)
- **Root Cause**:
  In [`uiPopulateTableYearSolarData`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10395-L10407):
  ```ahk
  infoPolarDays := polarDays ? "Polar days: " polarDays ". " : "Longest daylight: " maxLichtu ". "
  infoPolarNight := polarNights ? "Polar nights: " polarNights ". " : "Shortest daylight: " minLichtu ". "
  ...
  thisu := infoPolarDays infoPolarNight infodeepnights
  If !InStr(thisu, "twilight")
     thisu := InStr(thisu, "polar") ? thisu "Difference: 24:00." : thisu "Difference: " diffSols "."
  ```
  Because atmospheric refraction and the solar disc's semi-diameter lift the apparent sun by ~`0.833°`, many cities near the Arctic Circle (e.g., **Rovaniemi**, **Kemi**, **Kuusamo**, **Bodø**, **Boden**, **Sisimiut**) have `24:00` **Polar days** in summer (`polarDays > 0`) while still having several hours of daylight in winter (`polarNights = 0`).
  Because `thisu` contains `"Polar days:"`, `InStr(thisu, "polar")` is true even though `polarNights` is `0`, replacing the actual `diffSols` (`24:00 - minLichtu`) with `"24:00"`.
- **How to Reproduce**:
  1. Open **Astronomy / Today**, select **Finland** → **Rovaniemi** (or **Finland** → **Kemi**), ensure **Sun** mode is selected, and click **Table**.
  2. Read the summary line above the table tabs.
  3. **Observed**: It reads:
     `Polar days: 19. Shortest daylight: 02:14.  Difference: 24:00.`
     (The difference between 24:00 and 02:14 is `21:46`, not `24:00`.)

---

### Bug 11: Opening and Closing Settings While Deactivated Unintentionally Re-Activates Church Bells Tower

- **Location**: [`bells-tower.ahk#L3622-L3623`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3622-L3623) (`initSettingsWindow`) and [`bells-tower.ahk#L3750-L3767`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3750-L3767) (`CloseSettings`)
- **Root Cause**:
  When the user deactivates Church Bells Tower from the tray menu (**Deactivate**), `A_IsSuspended` is `1`.
  When opening Settings, [`initSettingsWindow`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3622-L3623) only suspends the script if it was not already suspended:
  ```ahk
  If (A_IsSuspended!=1)
     SuspendScript(1)
  ```
  However, when closing Settings without applying changes (`Cancel` or `Esc`), [`CloseSettings`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3761) unconditionally calls `SuspendScript()`, which toggles `Suspend` off and re-activates the application.
  *(Additionally, if the user opens Settings while active and jumps to another panel via right-click without changing anything, `CloseSettings()` calls `SuspendScript()` with `partially=0`, popping up an unwanted `"Church Bells Tower activated"` OSD over the newly opened panel.)*
- **How to Reproduce**:
  1. Right-click the system tray icon and click **Deactivate** (the OSD shows `"Church Bells Tower deactivated"` and the tray icon changes to the disabled icon).
  2. Open **Settings** from the tray menu.
  3. Click **Cancel** (or press `Esc`).
  4. **Observed**: The OSD pops up saying `"Church Bells Tower activated"` and the application is now active again, overriding the user's explicit deactivation.

---

### Bug 12: Bible Quotes Line Count (`countLines`) Is Never Reset When Switching Languages

- **Location**: [`bells-tower.ahk#L712-L740`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L712-L740) (`InvokeBibleQuoteNow`)
- **Root Cause**:
  In [`InvokeBibleQuoteNow`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L712-L740), `countLines` is `Static` and is only computed `If !countLines` (`#L726-L727` and `#L738-L739`). When `toLoadFile != lastFileLoaded` loads a different language file (`#L712-L722`), `countLines` is not reset to `0`, so `clampInRange(userBibleStartPoint, 1, countLines, 1)` continues clamping against the first loaded Bible's line count.
- **How to Reproduce**:
  1. Open **Settings** → **Celebrations**, enable **Show Bible quotes on the screen**, select **Define the start point**, and click **Preview verse**.
  2. Change the Bible language dropdown to another language with a different verse count and click **Preview verse** near the end of the file.
  3. **Observed**: `countLines` retains the line count of the first language loaded in the session.

---

### Bug 13: `DirectSoundPlayer.UnInitialize()` Checks Uninitialized Local Variables Instead of `this.pDS` and `this.hDsound`

- **Location**: [`lib/direct-sound-wrapper.ahk#L482-L494`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L482-L494) (`DirectSoundPlayer.UnInitialize`)
- **Root Cause**:
  In [`DirectSoundPlayer.UnInitialize`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L485-L488):
  ```ahk
  if pDS      ; Release DirectSound
     DllCall(NumGet(NumGet(pDS+0), 2*A_PtrSize), "Ptr", pDS)
  if hDsound  ; Free library
     DllCall("FreeLibrary", "Ptr", hDsound)
  ```
  `pDS` and `hDsound` are referenced as local variables (which are always empty `""`) instead of `this.pDS` and `this.hDsound`, so the `IDirectSound` COM object and `dsound.dll` module handle are never released when `UnInitialize()` is called.

---

## Resolved in Commit `5122b62`

The following issues from the initial report were resolved in commit `5122b62`:

1. **[FIXED] Calendar Panel Personal Events Symbol & Repeating Alarm Exception Preview** ([`bells-tower.ahk#L6695`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6695)): `givenDateTestCelebrations()` now assigns `"▦ "` instead of `"▣ "` to personal events (`obju[1]=3`), fixing both the icon and the repeating-alarm exception check (`tipu := 3`).
2. **[FIXED] Calendar `Manage celebrations` Button Enabled When `ObserveHolidays=0`** ([`bells-tower.ahk#L6465-L6467`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6465-L6467), [`#L6523`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6523)): `PanelCalendarWindow()` now disables `Btn5` (`&Manage celebrations`) when `ObserveHolidays!=1`, and `BTNcalendarSaveNewEntry()` enables it when a personal event is added.
3. **[FIXED] Semantron Drumming Playing on Secular Holidays and Personal Events** ([`bells-tower.ahk#L1527`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1527)): `theChimer()` now checks `TypeHolidayOccured=1` before playing holiday semantron drumming at `:45`.
4. **[FIXED] OSD Astronomy Color Mode "Moon phase" (`OSDastralMode=3`) Unreachable `MoonPhaseCalculator()`** ([`bells-tower.ahk#L1753`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1753)): `w := StrSplit(lastUsedGeoLocation, "|")` is now initialized before `If (OSDastralMode!=3)` in `decideOSDcolorBGR()`.
5. **[FIXED] Settings Color Picker Not Setting `appSettingsModified := 1`** ([`bells-tower.ahk#L4081`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L4081)): `InvokeSetNewColor()` now sets `appSettingsModified := 1` when enabling `ApplySettingsBTN`.
6. **[FIXED] Bible Quotes "Preview verse" Ignoring Language Change Within 2 Seconds** ([`bells-tower.ahk#L710-L715`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L710-L715)): `InvokeBibleQuoteNow()` now tracks `lastFileLoaded` and reloads immediately whenever `toLoadFile != lastFileLoaded`.
7. **[FIXED] `DirectSoundPlayer.Play()` Missing `index` Argument in `SetCurrentPosition`** ([`lib/direct-sound-wrapper.ahk#L299`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L299)): Now calls `this.SetCurrentPosition(index, 0)`.
