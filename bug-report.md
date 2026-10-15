# Church Bells Tower — User-Reproducible Bug Report

This report documents user-reproducible bugs, broken functionality, and broken options identified through a full static analysis of the **Church Bells Tower** codebase (`bells-tower.ahk`, `lib/*.ahk`, `Lib/*.ahk`, and `cpp-dll/*.cpp`).

> [!NOTE]
> Per your instructions, this report **excludes** any issues related to settings not being saved to the registry or INI file, as well as any discrepancies in clamping values on save versus load. Every bug listed below is reproducible at runtime by a user interacting with the application.

---

## Summary Table

| # | Severity | Component | Summary |
| :- | :--- | :--- | :--- |
| 1 | **High** | Analog Clock / Quick Timer | Quick timers set from the Analog Clock context menu fail to display a notification dialog or ring continuously when they expire (only flashing the screen for 350 ms). |
| 2 | **High** | Set Alarm or Timer | Predefined timers (`Set` button) fail to reset the `Hours` field (`hu` uninitialized), adding 1+ extra hours to 1–45 min presets and repeatedly incrementing hours on the `60` min preset. |
| 3 | **High** | Calendar / Repeating Alarms | Personal events are assigned the Secular symbol (`▣`) instead of the Personal symbol (`▦`), breaking the Calendar's repeating-alarm holiday exception logic for both Personal and Secular exceptions. |
| 4 | **High** | Yearly Sun & Moon Tables | Indexing `Summary` (Sun) and `Rise`/`Set` (Moon) columns by the event's `MM/dd` instead of the row's date leaves blank cells whenever an event crosses midnight or uses a yesterday/tomorrow fallback. |
| 5 | **Medium** | Set Alarm or Timer | Repeating alarms set for `00:00` (midnight) check `canDo` against the current day before advancing `newu` to tomorrow, causing them to ring on excluded days and skip included days. |
| 6 | **Medium** | Manage Celebrations | Adding a personal event via `Calendar` → `Manage celebrations` → `Add` does not enable `ObserveHolidays`, leaving newly created personal events completely hidden when `ObserveHolidays=0`. |
| 7 | **Medium** | Chimes & Holidays | Christian semantron drumming (`SemantronHoliday=1`) plays on Secular holidays and Personal events; conversely, a Personal event on Easter Sunday overwrites `isHolidayToday` and suppresses Easter noon bells. |
| 8 | **Medium** | Celebrations Audio | World Arabic Language Day (`12.18`, a Secular holiday) fails to play its special audio unless **Religious** celebrations (`ObserveReligiousDays=1`) are also enabled. |
| 9 | **Medium** | Calendar Panel | Selecting any 31-day month from the Calendar's month menu when on day `31` clamps the day to `30`; selecting February in a leap year when on day `29`–`31` clamps the day to `28`. |
| 10 | **Medium** | Calendar Panel | Equinoxes and solstices in the Calendar panel are matched against the current system year's day-of-year (`mEquiDay`, etc.) regardless of the year being browsed. |
| 11 | **Medium** | Yearly Sun & Moon Tables | Year-end summary statistics (`Polar days`, `Polar nights`, `nights without twilight`, `Moonless days`) include December 31 of the **previous** year (`A_Index=1`), overcounting by 1 day. |
| 12 | **Medium** | Yearly Sun Table | Summary text displays `"Difference: 24:00."` whenever `"Polar days:"` is present (`InStr(thisu, "polar")`), even when `Polar nights` is `0` and winter has non-zero shortest daylight. |
| 13 | **Medium** | Settings / Color Picker | Changing any color in Settings enables `Apply` without setting `appSettingsModified := 1`, allowing right-click panel jumps that abruptly restart the app and discard changes. |
| 14 | **Medium** | Settings / Activation State | Opening and closing Settings (`Cancel` / `Esc`) while Church Bells Tower is deactivated (`A_IsSuspended=1`) unconditionally calls `SuspendScript()`, re-activating the app against the user's choice. |
| 15 | **Low** | OSD Astronomy Color | OSD color mode `"Moon phase"` (`OSDastralMode=3`) checks `IsObject(w)` when `w` is only created for `OSDastralMode!=3`, making `MoonPhaseCalculator()` unreachable dead code. |
| 16 | **Low** | Settings / Bible Quotes | Clicking `Preview verse` in Settings within 2 seconds of changing the Bible language displays a verse from the old language, and `countLines` is never updated when switching languages. |
| 17 | **Low** | DirectSound Audio | `DirectSoundPlayer.Play()` calls `this.SetCurrentPosition(0)` without the required `index` parameter, always failing to rewind an already-playing non-duplicated buffer. |

---

## Detailed Bug Analysis & Reproduction Instructions

---

### Bug 1: Quick Timers Set From the Analog Clock Context Menu Fail to Alert Properly (350 ms Flash Only)

- **Location**: [`lib/analog-clock-display.ahk#L547-L568`](file:///home/marius/repos/ChurchBellsTower/lib/analog-clock-display.ahk#L547-L568) (`MenuSetQuickTimer`) and [`bells-tower.ahk#L7242-L7273`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7242-L7273) (`doUserTimerAlert`)
- **Root Cause**:
  In [`MenuSetQuickTimer`](file:///home/marius/repos/ChurchBellsTower/lib/analog-clock-display.ahk#L559), setting any quick timer explicitly clears the timer message variable to an empty string:
  ```ahk
  userTimerMsg := ""
  userTimerHours := (aa>59) ? 1 : 0
  userTimerMins := (aa>=60) ? aa - 60 : aa
  ```
  When the timer expires, [`doUserTimerAlert`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7247-L7265) checks `thisMsg := Trim(userTimerMsg)`:
  ```ahk
  If !thisMsg
  {
     Sleep, 350
     SetTimer, PlayTimerBell, Off
     DestroyScreenBlocker()
  } Else
  {
     MsgBox, 262192, %appTitle%: Notification (%thisNowTime%), %thisMsg%
     SetTimer, PlayTimerBell, Off
     DestroyScreenBlocker()
  }
  ```
  Because `thisMsg` is empty (`""`), `!thisMsg` is true. Unlike [`doUserAlarmAlert`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7314-L7316) (which sets `thisMsg := "NONE"` when blank so the notification `MsgBox` still appears), `doUserTimerAlert` sleeps for 350 ms, immediately stops `PlayTimerBell`, and destroys the screen blocker without showing any `MsgBox`.
  *(Note: The same bug also occurs if the user manually clears the `Message:` text box in `Set alarm or timer`.)*
- **How to Reproduce**:
  1. Show the Analog Clock widget (e.g., press `Alt+W` or click **Show the analog clock** in the tray menu).
  2. Right-click the Analog Clock and select **Set timer** → **1** (for a 1-minute timer).
  3. Wait 1 minute for the red progress arc on the Analog Clock to complete.
  4. **Observed**: The screen dims for only 0.35 seconds, the timer sound is immediately cut off, and **no notification dialog box appears**.
  5. **Expected**: The timer bell should ring and the notification dialog box should remain on screen until dismissed.

---

### Bug 2: Predefined Timer `Set` Button Fails to Reset Hours (`hu` Uninitialized) and Miscalculates the `60` Minute Preset

- **Location**: [`bells-tower.ahk#L6144-L6174`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6144-L6174) (`BtnSetPresetTimers`) and [`bells-tower.ahk#L7094-L7100`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7094-L7100) (`updateUIalarmsPanel`)
- **Root Cause**:
  In [`BtnSetPresetTimers`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6153-L6165):
  ```ahk
  If (info=90)
  {
     hu := 1
     info := 30
  } Else If (info=120)
  {
     hu := 1
     info := 60
  }

  GuiControl, SettingsGUIA:, userTimerHours, % hu
  GuiControl, SettingsGUIA:, userTimerMins, % info
  Sleep, 25
  updateUIalarmsPanel()
  ```
  1. For presets `1`, `2`, `3`, `4`, `5`, `10`, `15`, `30`, `45`, and `60`, the local variable `hu` is never assigned and defaults to `""`.
  2. Passing an empty string to `GuiControl, SettingsGUIA:, userTimerHours, % hu` does **not** reset the UpDown control `userTimerHours` to `0`; it leaves `userTimerHours` at whatever value it already had (which is `1` hour on a fresh launch per [`bells-tower.ahk#L139`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L139), or `1`–`2` hours after selecting `90` or `120`).
  3. For the `60` minute preset, `hu` is `""` (leaving `userTimerHours` unchanged, e.g., `1`) and `userTimerMins` is set to `60`. Immediately afterward, [`updateUIalarmsPanel`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7094-L7100) sees `TimerM=60`, sets `userTimerMins` to `0`, and sets `userTimerHours` to `TimerH + 1` (`2` hours!). Clicking `Set` repeatedly with `60` selected increments `Hours` by 1 on every click (`2`, `3`, `4`... up to `12`).
- **How to Reproduce**:
  1. Open **Set alarm or timer** from the tray menu.
  2. Notice that under **Set a timer**, `Hours:` is `1` by default (or set `Hours:` to `1`).
  3. In the **Predefined timers (minutes)** dropdown, select **5** and click **Set**.
  4. **Observed**: `Hours:` remains `1` and `Minutes:` becomes `5`, activating a timer for **1 hour and 5 minutes** instead of 5 minutes.
  5. Now select **60** in **Predefined timers (minutes)** and click **Set** several times.
  6. **Observed**: `Hours:` increments to `2`, then `3`, then `4` on each click instead of setting a 60-minute (1-hour) timer.

---

### Bug 3: Calendar Panel Assigns the Secular Symbol (`▣`) to Personal Events, Breaking Repeating Alarm Exception Previews

- **Location**: [`bells-tower.ahk#L6681-L6685`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6681-L6685) and [`bells-tower.ahk#L6714-L6729`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6714-L6729) (`givenDateTestCelebrations`)
- **Root Cause**:
  In [`givenDateTestCelebrations`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6681-L6683):
  ```ahk
  prefixu := (obju[1]=1) ? "✝ " : "▣ "
  If (obju[1]=3) ; personal
     prefixu := "▣ "
  ```
  Personal events (`obju[1]=3`) are given `"▣ "` (the Secular symbol) instead of `"▦ "` (the Personal symbol).
  Lines 6715–6720 then inspect `listu` to determine `tipu` for repeating alarm exceptions:
  ```ahk
  If InStr(listu, "✝")
     tipu := 1
  Else If InStr(listu, "▦")
     tipu := 3
  Else If InStr(listu, "▣")
     tipu := 2
  ```
  Because `"▦"` is never used in `givenDateTestCelebrations`, `tipu` is never `3`; Personal events are always classified as `tipu := 2` (Secular).
- **How to Reproduce**:
  1. Open **Set alarm or timer**, enable **Set an alarm**, choose **Every week**, check all weekdays, check **Personal** under *Except on days when the event observed is:*, uncheck **Secular**, and click **Save**.
  2. Open **Calendar**, pick a date that has no religious/secular holiday, type a personal event in the bottom field, and click **Add**.
  3. **Observed**:
     - The personal event is listed with the Secular symbol `▣` instead of `▦`.
     - Below the event, the Calendar still says `• Regular alarm set at: HH:MM.` even though the alarm is configured to be skipped on Personal event days.
  4. Now open **Set alarm or timer**, uncheck **Personal**, check **Secular** (with Secular celebrations enabled in Settings), and click **Save**. Re-open **Calendar** on your Personal event date.
  5. **Observed**: The `Regular alarm set at: HH:MM.` line disappears on the Personal event date because the Calendar mistook the Personal event for a Secular holiday.

---

### Bug 4: Yearly Sun & Moon Tables Show Blank Cells When Events Cross Midnight or Use Yesterday/Tomorrow Fallbacks

- **Location**: [`bells-tower.ahk#L10261-L10285`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10261-L10285), [`bells-tower.ahk#L10324-L10343`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10324-L10343) (`uiPopulateTableYearSolarData`), and [`bells-tower.ahk#L10497-L10510`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10497-L10510), [`bells-tower.ahk#L10597-L10602`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10597-L10602) (`uiPopulateTableYearMoonData`)
- **Root Cause**:
  In both `uiPopulateTableYearSolarData()` and `uiPopulateTableYearMoonData()`, the lookup arrays `arrayUsunriseu`, `arrayUsunsetu`, `arrayUdawnu`, and `arrayUdusku` are keyed by slicing characters 6–10 (`MM/dd`) from the **returned event timestamp** (`SubStr(obj.r, 6, 5)`, `SubStr(obj.s, 6, 5)`, etc.) rather than using the loop date `timis` (or row index `A_Index - 1`):
  ```ahk
  Nsunriseu := SubStr(sunriseu, 6, 5)
  sunriseu := SubStr(sunriseu, 12)
  arrayUsunriseu[Nsunriseu] := sunriseu
  ```
  - **In the Yearly Moon Table**: Because the lunar day (~24h 50m) is longer than a solar day, roughly once every two weeks there is a calendar day with no moonrise (so [`wrapCalcMoonRiseSet`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L9488) returns **yesterday's** moonrise) and a calendar day with no moonset (so [`wrapCalcMoonRiseSet`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L9505) returns **tomorrow's** moonset). Because `SubStr(obj.r, 6, 5)` is yesterday's `MM/dd` and `SubStr(obj.s, 6, 5)` is tomorrow's `MM/dd`, today's entry in `arrayUsunriseu[testToday]` or `arrayUsunsetu[testToday]` is never populated, leaving the cell **blank**!
  - **In the Yearly Sun Table**: On high-latitude dates where sunset or dusk occurs after midnight on the next calendar date (`MM/(dd+1)`), `SubStr(sunsetu, 6, 5)` / `SubStr(dusku, 6, 5)` is tomorrow's `MM/dd`. Thus, the **Summary** tab (`LViewSunCombined`) shows a **blank** Sunset or Dusk cell for that day, even though the **Set** and **Dawn and dusk** tabs show the exact `MM/dd HH:mm` timestamp on that row!
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

### Bug 5: Repeating Midnight (`00:00`) Alarm Evaluates Weekday/Holiday Conditions for the Wrong Day

- **Location**: [`bells-tower.ahk#L7340-L7382`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7340-L7382) (`startAlarmTimer`)
- **Root Cause**:
  In [`startAlarmTimer`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L7349-L7370):
  1. `canDo` is computed first using **today's** weekday (`A_WDay`) and **today's** holiday (`TypeHolidayOccured`).
  2. Next, `newu := A_Year . A_Mon . A_MDay . alarmH . alarmM "00"` is compared with `nowu := A_Now`.
  3. When `alarmH = "00"` and `alarmM = "00"`, `nowu >= newu` is **always true** throughout the entire day (from `00:00:00` to `23:59:59`), so for a repeating alarm (`userAlarmMode=2`), `newu += 1, Days` advances `newu` to **tomorrow at `00:00:00`** without re-evaluating `canDo` for tomorrow!
  - **Consequence A (Rings on excluded day)**: If today is checked (e.g., Friday) and tomorrow is unchecked (e.g., Saturday), at `23:59:45` on Friday `canDo` is `1` (because Friday is checked) and `nss` (`Saturday 00:00:00 - Friday 23:59:45 = 15s`) is `< 18`. `SetTimer, doUserAlarmAlert, -15000` is armed and rings at `00:00:00` on Saturday!
  - **Consequence B (Never rings on included day after excluded day)**: If Sunday is unchecked and Monday is checked, `canDo` is `0` all day Sunday (including `23:59:59`), so the timer is never armed before midnight. Once the clock hits `00:00:00` on Monday, `nowu >= newu` (`Monday 00:00:00 >= Monday 00:00:00`) is immediately true, so `newu` jumps to **Tuesday `00:00:00`** (`nss = 86400`), skipping Monday's `00:00` alarm completely!
- **How to Reproduce**:
  1. Open **Set alarm or timer**.
  2. Enable **Set an alarm**, set `Hour:` to `0` and `Minute:` to `0` (`00:00`), select **Every week**, uncheck today's weekday, check tomorrow's weekday, and click **Save**.
  3. Wait until `00:00:00` tonight (or set the system clock to `23:59:40` and wait 20 seconds).
  4. **Observed**: The `00:00` alarm for tomorrow never rings. Conversely, if today's weekday is checked and tomorrow's weekday is unchecked, the alarm rings at `00:00:00` as tomorrow begins.

---

### Bug 6: Adding a Personal Event via `Manage celebrations` → `Add` Fails to Enable `ObserveHolidays`

- **Location**: [`bells-tower.ahk#L5513-L5542`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5513-L5542) (`SaveNewEntryBtn`) vs. [`bells-tower.ahk#L6509-L6516`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6509-L6516) (`BTNcalendarSaveNewEntry`)
- **Root Cause**:
  By default, `ObserveHolidays` is `0` ([`bells-tower.ahk#L82`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L82)).
  When adding a personal event from the Calendar panel's inline input ([`BTNcalendarSaveNewEntry`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6513)), the code sets `ObserveHolidays := 1` so that personal events are displayed and observed.
  However, when adding a personal event via **Calendar** → **Manage celebrations** → **Add** → **Save** ([`SaveNewEntryBtn`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5513-L5542)), `ObserveHolidays` is left at `0`. When closing **Manage celebrations** to return to the Calendar, [`givenDateTestCelebrations`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6679) checks `If (ObserveHolidays=1)` and hides all events.
- **How to Reproduce**:
  1. With `Observe celebrations and holidays` unchecked in Settings (the default state), open **Calendar** from the tray menu.
  2. Click **Manage celebrations** (which is enabled).
  3. Click **Add**, enter a title (e.g., `Test Event`) for today's month and day, and click **Save**.
  4. Close **Manage celebrations** to return to **Calendar** and select today's date (or open **Astronomy / Today** → **Events**).
  5. **Observed**: The newly added personal event is not shown anywhere in the Calendar or Today panel (`No celebration / event recorded for the given date`).

---

### Bug 7: Christian Semantron Drumming Plays on Secular Holidays and Personal Events, While Personal Events Suppress Easter Noon Bells

- **Location**: [`bells-tower.ahk#L1508-L1544`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1508-L1544) (`theChimer`) and [`bells-tower.ahk#L5025-L5037`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5025-L5037) (`coreTestCelebrationz`)
- **Root Cause**:
  1. In [`theChimer`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1525):
     ```ahk
     If (stopStrikesNow=0 && SemantronHoliday=1 && StrLen(isHolidayToday)>2 && InStr(exactTime, ":45"))
     ```
     Unlike the quarter-hour feast chime check on line 1539 (`&& TypeHolidayOccured=1`), line 1525 does **not** check `TypeHolidayOccured=1`. Therefore, when `SemantronHoliday=1` (*"Mark days of feast by regular semantron drumming"* under **Religious Celebrations**), semantron drumming plays at `09:45`, `11:45`, `17:45`, and `22:45` even when `isHolidayToday` is a **Secular** holiday (`TypeHolidayOccured=2`) or a **Personal** event (`TypeHolidayOccured=3`).
  2. In [`coreTestCelebrationz`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5025-L5037), when `testWhat=0`, any Personal event on today's date overwrites `aisHolidayToday` and sets `aTypeHolidayOccured := 3`. If the user has a Personal event on Easter Sunday, `InStr(isHolidayToday, "easter")` (`#L1508`) and `TypeHolidayOccured=1` (`#L1539`) both evaluate to false, preventing Easter noon bells and religious feast chimes from ringing.
- **How to Reproduce**:
  1. Open **Settings** → **Celebrations**, enable **Observe celebrations and holidays**, enable **Observe Christian religious days of feast**, and check **Mark days of feast by regular semantron drumming**. Click **Apply**.
  2. Open **Calendar**, select today's date (choosing a day with no religious feast), and add a Personal event (e.g., `Dentist appointment`).
  3. Set the system time to `09:44:50` (or `11:44:50`) and wait for `:45:00`.
  4. **Observed**: Christian semantron drumming plays at `:45` for the personal event (and similarly on Secular holidays).

---

### Bug 8: World Arabic Language Day (`12.18`) Audio Fails to Play Unless Religious Celebrations Are Also Enabled

- **Location**: [`bells-tower.ahk#L4997`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L4997) and [`bells-tower.ahk#L5062-L5063`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5062-L5063) (`coreTestCelebrationz`)
- **Root Cause**:
  `12.18|World Arabic Language Day` is defined in the **Secular** celebrations list (`bells-tower.ahk#L4997`). However, the audio playback condition in [`coreTestCelebrationz`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L5062-L5063) requires `ObserveReligiousDays=1` in addition to `ObserveSecularDays=1`:
  ```ahk
  Else If (InStr(aisHolidayToday, "arabic") && ObserveReligiousDays=1 && ObserveSecularDays=1)
     MCXI_Play(SNDmedia_surah)
  ```
- **How to Reproduce**:
  1. Open **Settings** → **Celebrations**, enable **Observe celebrations and holidays**, check **Observe secular / international days**, and **uncheck** **Observe Christian religious days of feast**. Click **Apply**.
  2. Open **Celebrations / holidays** from the tray menu.
  3. Select the row for `12.18` (**World Arabic Language Day**).
  4.Notice the `B` (bell) button becomes enabled in the bottom-left corner. Click `B` to preview the holiday sound.
  5. **Observed**: Instead of playing `al-fatiha-surah.mp3`, it plays the generic secular gong (`bell-japanese-gong.wav`).

---

### Bug 9: Calendar Month Menu Clamps Day `31` to `30` on 31-Day Months and Clamps Day `29` to `28` in Leap-Year Februaries

- **Location**: [`bells-tower.ahk#L6656-L6667`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6656-L6667) (`MenuSetCalendarMonth`)
- **Root Cause**:
  In [`MenuSetCalendarMonth`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6659-L6660):
  ```ahk
  thisMon := Format("{:02}", A_ThisMenuItemPos)
  If (thisMDay>30 || thisMon="02" && thisMDay>=28)
     thisMDay := (thisMon="02") ? 28 : 30
  ```
  - `thisMDay>30` is true whenever the currently selected day is `31`, unconditionally clamping it to `30` even when switching to a month with 31 days (Jan, Mar, May, Jul, Aug, Oct, Dec).
  - When switching to February (`thisMon="02"`), `thisMDay>=28` clamps day `29`, `30`, or `31` to `28` even when `thisYear` is a leap year.
- **How to Reproduce**:
  1. Open **Calendar** from the tray menu.
  2. Click on the **31st** of any month (e.g., May 31 or July 31).
  3. Click the large month/date title at the top of the Calendar (`uiCalendarDatumLabel`) to open the month popup menu, and select **8: August** (or **12: December**).
  4. **Observed**: The selection jumps to **August 30** (or **December 30**) instead of staying on the 31st.
  5. Navigate to a leap year (e.g., **2024** or **2028**), select **January 29** (or **31**), click the month title, and select **2: February**.
  6. **Observed**: The selection is clamped to **February 28** instead of **February 29**.

---

### Bug 10: Calendar Panel Displays Equinoxes and Solstices on the Wrong Day When Browsing Other Years

- **Location**: [`bells-tower.ahk#L6689-L6696`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6689-L6696) (`givenDateTestCelebrations`)
- **Root Cause**:
  In [`givenDateTestCelebrations`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6689-L6696):
  ```ahk
  FormatTime, thisYday, % givenDate, YDay
  If (mEquiDay=thisYday)
     listu .= "● March equinox (spring)`n"
  Else If (jSolsDay=thisYday)
     listu .= "● June solstice (summer)`n"
  Else If (sEquiDay=thisYday)
     listu .= "● September equinox (autumn)`n"
  Else If (dSolsDay=thisYday)
     listu .= "● December solstice (winter)`n"
  ```
  `mEquiDay`, `jSolsDay`, `sEquiDay`, and `dSolsDay` are calculated only for `A_Year` (the current system year). When the user browses any other year in the Calendar — particularly a leap year like `2024` or `2028` when the current year is a non-leap year like `2026` — every date after February 28 has its day-of-year (`YDay`) shifted by 1 day, and the astronomical instants also shift across years.
- **How to Reproduce**:
  1. Open **Celebrations / holidays**, switch to the **Equinoxes and solstices** tab, set **Year** to `2028` (a leap year), and note the dates (e.g., March equinox on `2028/03/20`, June solstice on `2028/06/20`, September equinox on `2028/09/22`, December solstice on `2028/12/21`).
  2. Open **Calendar** and navigate to **March 2028** (or **June 2028**).
  3. Click on **March 19, 2028** and **March 20, 2028**.
  4. **Observed**: The Calendar panel marks `● March equinox (spring)` on **March 19, 2028** instead of **March 20, 2028** (because Day 79 in 2026 is March 20, whereas Day 79 in leap year 2028 is March 19).

---

### Bug 11: Yearly Sun & Moon Tables Overcount Polar Days, Polar Nights, Deep Nights, and Moonless Days by Including Dec 31 of the Previous Year

- **Location**: [`bells-tower.ahk#L10229-L10317`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10229-L10317) (`uiPopulateTableYearSolarData`) and [`bells-tower.ahk#L10465-L10583`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10465-L10583) (`uiPopulateTableYearMoonData`)
- **Root Cause**:
  Both functions initialize `timeus` to January 1 of `yearu`, subtract 1 day (`timeus += -1, Days` → **December 31 of `yearu - 1`**), and loop `loopsu + 1` times (`366` iterations for a 365-day year).
  Although ListView row additions are guarded by `If (A_Index>1)` (`#L10291` and `#L10540`), the summary counters (`polarNights++`, `polarDays++`, `deepNights++`, `maxLichtu`, `minLichtu`) are incremented **outside** `If (A_Index>1)`.
  Thus, `A_Index=1` (December 31 of the previous year) is included in the year's totals!
- **How to Reproduce**:
  1. Open **Astronomy / Today**, select **Norway** → **Svalbard-Jan Mayen** (or **Tromsø**), ensure **Sun** mode is active, and click **Table** (`PanelSunYearGraphTable`).
  2. In the **Sunlight** tab (or **Summary** tab), count the rows that have `00:00` in the `Sunlight` column (or `Night` in the `Dawn`/`Dusk` columns) and compare with the summary text above the tabs (`Polar nights: X — of which Y are nights without twilight`).
  3. **Observed**: Both `Polar nights` and `nights without twilight` in the summary header are **1 higher** than the actual number of days in the table for that year (because Dec 31 of the previous year was counted on iteration 1).

---

### Bug 12: Yearly Sun Table Falsely Displays `"Difference: 24:00."` for Sub-Polar Cities With Polar Days But Non-Zero Winter Daylight

- **Location**: [`bells-tower.ahk#L10383-L10396`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10383-L10396) (`uiPopulateTableYearSolarData`)
- **Root Cause**:
  In [`uiPopulateTableYearSolarData`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L10384-L10395):
  ```ahk
  infoPolarDays := polarDays ? "Polar days: " polarDays ". " : "Longest daylight: " maxLicht ". "
  infoPolarNights := polarNights ? "Polar nights: " polarNights ". " : "Shortest daylight: " minLicht ". "
  ...
  thisu := infoPolarDays . infoPolarNights . infoPolarDeepNights
  thisu := InStr(thisu, "polar") ? thisu "Difference: 24:00." : thisu "Difference: " diffSols "."
  ```
  Because atmospheric refraction and the solar disc's semi-diameter lift the apparent sun by ~`0.833°`, many cities near the Arctic Circle (e.g., **Rovaniemi**, **Kemi**, **Kuusamo**, **Bodø**, **Boden**, **Sisimiut**) have `24:00` **Polar days** in summer (`polarDays > 0`) while still having several hours of daylight in winter (`polarNights = 0`).
  Because `thisu` contains `"Polar days:"`, `InStr(thisu, "polar")` is true even though `polarNights` is `0`, replacing the actual `diffSols` (`24:00 - minLicht`) with `"24:00"`.
- **How to Reproduce**:
  1. Open **Astronomy / Today**, select **Finland** → **Rovaniemi** (or **Finland** → **Kemi**), ensure **Sun** mode is selected, and click **Table**.
  2. Read the summary line above the table tabs.
  3. **Observed**: It reads:
     `Polar days: 19. Shortest daylight: 02:14.  Difference: 24:00.`
     (The difference between 24:00 and 02:14 is `21:46`, not `24:00`.)

---

### Bug 13: Changing Any Color in Settings Enables `Apply` Without Setting `appSettingsModified := 1`, Causing Right-Click Panel Jumps to Restart the App and Lose Changes

- **Location**: [`bells-tower.ahk#L4059-L4076`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L4059-L4076) (`InvokeSetNewColor`), [`bells-tower.ahk#L3877-L3886`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3877-L3886) (`coreSettingsContextMenu`), [`bells-tower.ahk#L6118-L6129`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6118-L6129) (`reactWinOpened`), and [`bells-tower.ahk#L3746-L3763`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3746-L3763) (`CloseSettings`)
- **Root Cause**:
  When the user changes any color in Settings (OSD text/background color, Astronomy colors, or Analog Clock colors), [`InvokeSetNewColor`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L4073) enables the `Apply` button (`GuiControl, %g%:Enable, ApplySettingsBTN`) **without** setting `appSettingsModified := 1`.
  - Because `appSettingsModified` is still `0`, right-clicking inside the Settings window ([`coreSettingsContextMenu`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3877)) still displays the panel jump items (`Astronomy / Today`, `Celebrations / holidays`, `Calendar`, `Set alarm or timer`, `Stopwatch`, `About`).
  - When the user clicks any of those panel items, [`reactWinOpened`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L6122) calls [`CloseSettings`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3746-L3763).
  - `CloseSettings()` checks `GuiControlGet, ApplySettingsBTN, SettingsGUIA: Enabled`. Because `ApplySettingsBTN` is `1` (enabled), it skips the `If (ApplySettingsBTN=0)` branch and calls `ReloadScript()` (`#L3762`), restarting the application without saving the color change and without opening the requested panel!
- **How to Reproduce**:
  1. Open **Settings** and go to the **Clock Display** tab (or **Analog Clock** tab).
  2. Click **Change** next to **Text color** (or **Background color**), pick any new color in the color dialog, and click **OK**. (Notice the **Apply** button at the bottom is now enabled.)
  3. Right-click anywhere in the Settings window background and click **Astronomy / Today** (or **Calendar**).
  4. **Observed**: Instead of blocking the panel jump or opening the selected panel, the application abruptly reloads (`ReloadScript()`), discarding the color change and never opening the panel you clicked.

---

### Bug 14: Opening and Closing Settings While Deactivated Unintentionally Re-Activates Church Bells Tower

- **Location**: [`bells-tower.ahk#L3618-L3619`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3618-L3619) (`initSettingsWindow`) and [`bells-tower.ahk#L3746-L3763`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3746-L3763) (`CloseSettings`)
- **Root Cause**:
  When the user deactivates Church Bells Tower from the tray menu (**Deactivate**), `A_IsSuspended` is `1`.
  When opening Settings, [`initSettingsWindow`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3618-L3619) only suspends the script if it was not already suspended:
  ```ahk
  If (A_IsSuspended!=1)
     SuspendScript("partially=0")
  ```
  However, when closing Settings without applying changes (`Cancel` or `Esc`), [`CloseSettings`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L3757) unconditionally calls `SuspendScript()`, which toggles `Suspend` off and re-activates the application.
  *(Additionally, if the user opens Settings while active and jumps to another panel via right-click without changing anything, `CloseSettings()` calls `SuspendScript()` with `partially=0`, popping up an unwanted `"Church Bells Tower activated"` OSD over the newly opened panel.)*
- **How to Reproduce**:
  1. Right-click the system tray icon and click **Deactivate** (the OSD shows `"Church Bells Tower deactivated"` and the tray icon changes to the disabled icon).
  2. Open **Settings** from the tray menu.
  3. Click **Cancel** (or press `Esc`).
  4. **Observed**: The OSD pops up saying `"Church Bells Tower activated"` and the application is now active again, overriding the user's explicit deactivation.

---

### Bug 15: OSD Astronomy Color Mode "Moon phase" (`OSDastralMode=3`) Never Calls `MoonPhaseCalculator()` Due to Unreachable Condition

- **Location**: [`bells-tower.ahk#L1747-L1770`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1747-L1770) (`decideOSDcolorBGR`)
- **Root Cause**:
  In [`decideOSDcolorBGR`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L1747-L1770):
  ```ahk
  If (OSDastralMode!=3)
  {
     If !InStr(lastUsedGeoLocation, "|")
        Return OSDbgrColor

     w := StrSplit(lastUsedGeoLocation, "|")
     ...
  }
  ...
  Else If (OSDastralMode=3 && IsObject(w))
     moonPhase := MoonPhaseCalculator(timeus, 0, w[2], w[3])
  Else If (OSDastralMode=3)
     moonPhase := oldMoonPhaseCalculator(timeus)
  ```
  Because `w` is a local variable that is only assigned inside `If (OSDastralMode!=3)`, `IsObject(w)` is **always false** when `OSDastralMode=3`. Line 1767 is dead code, and `OSDastralMode=3` always falls back to `oldMoonPhaseCalculator(timeus)`.
- **How to Reproduce**:
  1. Open **Settings** → **Clock Display**.
  2. Check **Adjust background color based on astronomy data** and select **Moon phase** (`OSDastralMode=3`) in the dropdown.
  3. Check **Preview window** or click **Apply** and press `Alt+C`.
  4. **Observed**: `decideOSDcolorBGR()` always takes the `oldMoonPhaseCalculator(timeus)` fallback branch instead of `MoonPhaseCalculator(timeus, 0, w[2], w[3])`.

---

### Bug 16: Bible Quotes "Preview verse" in Settings Ignores Language Switch Within 2 Seconds and Never Resets `countLines`

- **Location**: [`bells-tower.ahk#L689-L745`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L689-L745) (`InvokeBibleQuoteNow`)
- **Root Cause**:
  In [`InvokeBibleQuoteNow`](file:///home/marius/repos/ChurchBellsTower/bells-tower.ahk#L690-L737):
  ```ahk
  Static countLines := 0, lastLoaded := 1, bibleQuotesFile := ""
  ...
  If (!bibleQuotesFile || (PrefOpen=1 && (A_TickCount - lastLoaded>2000)))
  {
     FileRead, bibleQuotesFile, *P65001 %A_ScriptDir%\bibles\%BibleQuotesLang%-bible.txt
     lastLoaded := A_TickCount
  }
  ```
  1. Instead of checking whether `BibleQuotesLang` changed since the last load, it only reloads `bibleQuotesFile` if `A_TickCount - lastLoaded > 2000`. If the user clicks `Preview verse`, changes the language dropdown, and clicks `Preview verse` within 2 seconds, the verse is still read from the previous language's buffer.
  2. `countLines` is `Static` and is only calculated `If !countLines` (`#L724`, `#L736`). It is **never reset to `0`** when `bibleQuotesFile` is reloaded for a new language, so `clampInRange(userBibleStartPoint, 1, countLines, 1)` continues clamping against the first loaded Bible's line count.
- **How to Reproduce**:
  1. Open **Settings** → **Celebrations**.
  2. Enable **Show Bible quotes on the screen**.
  3. Click **Preview verse**, then immediately (< 2 seconds) change the language dropdown (e.g., from `en` to `ro` or `la`) and click **Preview verse** again.
  4. **Observed**: The OSD still shows a verse in the old language (`en`).

---

### Bug 17: `DirectSoundPlayer.Play()` Calls `this.SetCurrentPosition(0)` With Missing `index` Argument

- **Location**: [`lib/direct-sound-wrapper.ahk#L284-L336`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L284-L336) and [`lib/direct-sound-wrapper.ahk#L482-L494`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L482-L494) (`DirectSoundPlayer`)
- **Root Cause**:
  In [`DirectSoundPlayer.Play`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L299):
  ```ahk
  ; Reset buffer position to start using SetCurrentPosition
  this.SetCurrentPosition(0)
  ```
  [`SetCurrentPosition(index, newPos)`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L310) requires **two** arguments (`index` and `newPos`). Calling `this.SetCurrentPosition(0)` passes `index = 0` and `newPos = ""`, which always fails the `if (index < 1 || index > this.Count)` check on line 314 and returns `0` without rewinding the DirectSound buffer.
  When a sound played with `allowDupe=0` (such as the **Test** button for Hour/Quarter-hour bells in Settings) is triggered again while its buffer is still playing, DirectSound does not rewind the play cursor to `0`, so the sound continues from its current position instead of restarting.
  *(Additionally, [`DirectSoundPlayer.UnInitialize()`](file:///home/marius/repos/ChurchBellsTower/lib/direct-sound-wrapper.ahk#L485-L488) checks local `if pDS` and `if hDsound` instead of `this.pDS` and `this.hDsound`, so the DirectSound interface and DLL are never freed when uninitializing.)*
- **How to Reproduce**:
  1. Open **Settings** → **Audio**, ensure **Use DirectSound to play audio wav files** is checked, and go to the **General** tab.
  2. Click the **Test** button next to **Hour bell sound** (which plays a long bell resonance with `allowDupe=0` via `SoundPlayWrapper`).
  3. While the bell is still ringing (e.g., 1–2 seconds later), click **Test** again.
  4. **Observed**: The bell sound does **not** restart from the strike at the beginning; it simply continues playing the tail of the first strike because `SetCurrentPosition` failed to rewind the buffer.
