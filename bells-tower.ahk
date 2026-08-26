; bells-tower.ahk - main file
; https://github.com/marius-sucan/ChurchBellsTower
;
; Charset for this file must be UTF 8 with BOM.
; it may not function properly otherwise.
;
; Sounds copied from various «random» online sources.
; All audios were edited and processed to fit the needs
; of this application.
;
; Disclaimer: this script is provided "as is", without any kind of warranty.
; The author(s) shall not be liable for any damage caused by using
; this script or its derivatives,  et cetera.
;
; Compilation directives; include files in binary and set file properties
; =========================================================================
;
;@Ahk2Exe-SetName Church Bells Tower
;@Ahk2Exe-SetCopyright Marius Şucan (2017-2026)
;@Ahk2Exe-SetCompanyName https://marius.sucan.ro
;@Ahk2Exe-SetDescription Church Bells Tower
;@Ahk2Exe-SetVersion 3.6.1
;@Ahk2Exe-SetOrigFilename bells-tower.ahk
;@Ahk2Exe-SetMainIcon bells-tower.ico

;================================================================
; Section. Auto-exec.
;================================================================

; Script Initialization

#SingleInstance Force
#NoEnv
#MaxMem 512
#MaxHotkeysPerInterval, 950
#Include, Lib\va.ahk                   ; windows vista audio APIs wrapper by Lexikos
#Include, Lib\mci.ahk
#Include, Lib\gdip_all.ahk
#Include, Lib\gdi.ahk
#Include, Lib\analog-clock-display.ahk
#Include, Lib\Class_CtlColors.ahk
#Include, Lib\hashtable.ahk
#Include, Lib\Class_ImageButton.ahk
#Include, Lib\windows-geolocation.ahk
; #Include, Lib\direct-sound-wrapper.ahk

DetectHiddenWindows, On
ComObjError(false)
SetTitleMatchMode, 2
Coordmode, Mouse, Screen
SetBatchLines, -1
ListLines, Off
SetWorkingDir, %A_ScriptDir%
Critical, On

; Default Settings
Global IniFile         := "bells-tower.ini"
, LargeUIfontValue     := 13
, uiDarkMode           := 0
, tollQuarters         := 1 
, tollQuartersException:= 0 
, tollHours            := 1
, tollHoursAmount      := 1
, tollNoon             := 1
, BeepsVolume          := 35
, dynamicVolume        := 1
, silentHours          := 1
, silentHoursA         := 12
, silentHoursB         := 14
, gongAudioVerseDisplay:= 1
, userAstroInfodMode   := 1
, AutoUnmute           := 1
, tickTockNoise        := 0
, strikeInterval       := 2000
, AdditionalStrikes    := 0
, strikeEveryMin       := 5
, showBibleQuotes      := 0
, useDirectSound       := 0
, BibleQuotesLang      := 1
, makeScreenDark       := 1
, BibleQuotesInterval  := 5
, OverrideOSDcolorsAstro := 0
, OSDastralMode        := 1
, noBibleQuoteMhidden  := 1
, userBibleStartPoint  := 1
, orderedBibleQuotes   := 0
, UserReligion         := 1
, SemantronHoliday     := 0
, ObserveHolidays      := 0
, ObserveSecularDays   := 1
, ObserveReligiousDays := 1
, userMuteAllSounds    := 0
, PreferSecularDays    := 0
, noTollingWhenMhidden := 0
, noTollingWhenLocked  := 0
, noTollingBgrSounds   := 0
, NoWelcomePopupInfo   := 0
, showTimeWhenIdle     := 0
, showTimeIdleAfter    := 5 ; [in minutes]
, markFullMoonHowls    := 0
, allowDSTchanges      := 1
, allowAltitudeSolarChanges := 1
, constantOSDlockPosition := 0

; OSD settings
Global displayTimeFormat := 1
, OSDlongDateFormat      := 1
, OSDalwaysDateShow      := 0
, DisplayTimeUser        := 3     ; in seconds
, displayClock           := 1
, showMoonPhaseOSD       := 0
, constantAnalogClock    := 0
, constantOSDvisible     := 0
, showOSDprogressBar     := 2
, GuiX                   := 40
, GuiY                   := 250
, ClockGuiX              := 40
, ClockGuiY              := 250
, OSDroundCorners        := 1
, FontName               := (A_OSVersion="WIN_XP") ? "Lucida Sans Unicode" : "Arial"
, FontSize               := 26
, FontSizeQuotes         := 20
, PrefsLargeFonts        := 0
, clockOutColor          := "222222"
, clockBgrColor          := "eeEEee"
, clockFgrColor          := "111111"
, OSDbgrColor            := "131209"
, OSDastroALTcolor       := "106699"
, OSDastroALTOcolor      := "006612"
, OSDalpha               := 230
, OSDtextColor           := "FFFEFA"
, OSDmarginTop           := 20
, OSDmarginBottom        := 20
, OSDmarginSides         := 25
, maxBibleLength         := 55

; Timers and alarms
, userMustDoTimer    := 0
, userTimerHours     := 1
, userTimerMins      := 30
, userMustDoAlarm    := 0
, userTimerMsg       := "What is the purpose of God?"
, userAlarmMsg       := "Why do people anthropomorphize God?"
, userAlarmHours     := 12
, userAlarmMins      := 30
, AlarmersDarkScreen := 1
, userTimerSound     := 2
, userTimerFreq      := 1
, userAlarmSound     := 1
, userAlarmFreq      := 1
, userAlarmSnooze    := 5
, userAlarmRepeated  := 0
, userAlarmWeekDays  := 1234567
, stopWatchDoBeeps   := 0

; Analog clock stuff
, mainOSDopacity:= 230
, faceOpacity   := 254
, roundedClock  := 0
, faceOpacityBgr:= Round(faceOpacity/1.25)
, ClockPosX     := 30
, ClockPosY     := 90
, ClockDiameter := 480
, ClockWinSize  := ClockDiameter + 2
, ClockCenter   := Round(ClockWinSize/2)
, roundedCsize  := Round(ClockDiameter/4)
, analogClockOpacity     := 230
, swapColorAnalogClock   := 0
, transparentAnalogClock := 0
, coloredAnalogClockBgr  := 1
, showAnalogHourLabels   := 1
, useArabNumeralsAnalogClock := 0
, analogClockScalesList  := "0.12|0.25|0.50|0.75|1.00|1.50|2.00|3.00|4.00|5.00"
, analogClockScale       := "0.50"
, analogMoonPhases       := 0
, lockAnalogClockPosition := 0

; Release info
, ThisFile               := A_ScriptName
, Version                := "3.6.1"
, ReleaseDate            := "2026 / 08 / 24"
, storeSettingsREG := (FileExist("win-store-mode.ini") && A_IsCompiled && InStr(A_ScriptFullPath, "WindowsApps")) ? 1 : 0
, ScriptInitialized, FirstRun := 1, uiUserCountry, uiUserCity, lastUsedGeoLocation, EquiSolsCache := 0
, QuotesAlreadySeen := "", LastWinOpened, hasHowledDay := 0, WinStorePath := A_ScriptDir
, LastNoonAudio := 0, appName := "Church Bells Tower"
, APPregEntry := "HKEY_CURRENT_USER\SOFTWARE\" appName "\v1-1"
, StoreStartupTaskId := "ChurchBellsTower"   ; the TaskId of the windows.startupTask extension in the Store package's AppxManifest.xml
, appSettingsModified := 0

If !A_IsCompiled
   Menu, Tray, Icon, bells-tower.ico

DetermineWindowsStorePath()
INIaction(0, "FirstRun", "SavedSettings")
If (FirstRun=0)
{
   INIsettings(0)
} Else
{
   TrayTip, %appName%, Please configure the application for optimal experience.
   CheckSettings()
   INIsettings(1)
}

; Initialization variables. Altering these may lead to undesired results.

Global CSthin := "░"   ; light gray 
, CSmid       := "▒"   ; gray
, DisplayTime := DisplayTimeUser*1000
, OSDGuiaVisible := 0
, DoNotRepeatTimer := 0
, PrefOpen := 0, FontList := []
, userIdleAfter := showTimeIdleAfter * 60000
, AdditionalStrikeFreq := strikeEveryMin * 60000  ; minutes
, bibleQuoteFreq := BibleQuotesInterval * 3600000 ; hours
, ShowPreview := 0, ShowPreviewDate := 0
, LastNoonZeitSound := 1, hCelebsMan
, OSDprefix, OSDsuffix, lastTodayPanelZeitUpdate := 1
, windowManageCeleb := 0, hBtnTodayPrev, hBtnTodayNext
, stopStrikesNow := 0, mouseToolTipWinCreated := 0
, ClockVisibility := 0, quoteDisplayTime := 100
, stopAdditionalStrikez := 0, lastAudioPlayed := 1
, strikingBellsNow := 0, generatingEarthMapNow := 0
, yearTableMemo := ""     ; see yearTableMemoKey()
, DoGuiFader := 1, showEarthSunMapModus := 1
, lastFaded := 1, geoData := new hashtable()
, cutVolumeHalf := 0, listedCountries := 0, countriesList
, defAnalogClockPosChanged := 0, allowAutoUpdateTodayPanel := 0
, FontChangedTimes := 0, AnyWindowOpen := 0, CurrentPrefWindow := 0
, mEquiDay := 79, jSolsDay := 172, sEquiDay := 266, dSolsDay := 356
, mEquiDate := A_Year "0320010203", jSolsDate := A_Year "0621010203", sEquiDate := A_Year "0923010203", dSolsDate := A_Year "1222010203"
, LastBibleQuoteDisplay := 1, hSolarGraphPic, gDllType := 0
, LastBibleQuoteDisplay2 := 1, countriesArrayList := []
, LastBibleMsg := "", AllowDarkModeForWindow := ""
, celebYear := A_Year, userAlarmIsSnoozed := 0
, isHolidayToday := 0, stopWatchRecordsInterval := []
, TypeHolidayOccured := 0, userTimerExpire := 0, SolarYearGraphMode := 0
, stopWatchIntervalInfos := []
, lastOSDredraw := 1, stopWatchHumanStartTime := 0
, semtr2play := 0, stopWatchRealStartZeit := 0, attempts2Quit := 0
, stopWatchBeginZeit := 0, stopWatchLapBeginZeit := 0, combosDarkModus := ""
, stopWatchPauseZeit := 0.001, stopWatchLapPauseZeit := 0.001
, AboutTitleColor
, listedExtendedLocations := 0, extendedGeoData := []
, roundCornerSize := Round(FontSize/2) + Round(OSDmarginSides/5)
, StartRegPath := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
, tickTockSound := A_ScriptDir "\sounds\ticktock.wav"
, hWinOSD, hSetWinGui, hOSDtxt, hBibleOSD, hSetWinGui, ColorPickerHandles, hDatTime
, hWinMM := DllCall("kernel32\LoadLibraryW", "Str", "winmm.dll", "Ptr")
, quartersTotalTime := 0, hoursTotalTime := 0
, SNDmedia_auxil_bell, SNDmedia_japan_bell, SNDmedia_christmas, todaySunMoonGraphMode := 0
, SNDmedia_evening, SNDmedia_midnight, SNDmedia_morning, SNDmedia_beep
, SNDmedia_noon1, SNDmedia_noon2, SNDmedia_noon3, SNDmedia_noon4, SNDmedia_surah
, SNDmedia_orthodox_chimes1, SNDmedia_orthodox_chimes2, SNDmedia_howl, SNDmedia_armistice
, SNDmedia_semantron1, SNDmedia_semantron2, SNDmedia_hours12, SNDmedia_hours11
, SNDmedia_quarters1, SNDmedia_quarters2, SNDmedia_quarters3, SNDmedia_quarters4
, SNDmedia_hours1, SNDmedia_hours2, SNDmedia_hours3, SNDmedia_hours4, SNDmedia_hours5
, SNDmedia_hours6, SNDmedia_hours7, SNDmedia_hours8, SNDmedia_hours9, SNDmedia_hours10
, hFaceClock, pToken, scriptStartZeit := A_TickCount
, globalG, globalhbm, globalhdc, globalobm, uiUserFullDateUTC
, clockFgrClr, clockBgrClr, isAlarmTmrw := 0
, moduleAnalogClockInit := 0, darkWindowColor := "0x202020", darkControlColor := "0xEDedED"
, debugMode := !A_IsCompiled, lastCalendarClickedDate := 0

; initDLLhack()
If !pToken
   pToken := Gdip_Startup()

If (roundCornerSize<20)
   roundCornerSize := 20

; Initialization of the core components and functionality

; If (A_IsCompiled && storeSettingsREG=0)
;    VerifyFiles()

If (uiDarkMode=1)
{
   setMenusTheme(1)
   setDarkWinAttribs(A_ScriptHwnd, 1)
}

Sleep, 1
SetMyVolume(1)
InitializeTrayMenu()
InitSoundChannels()

hCursM := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32646, "Ptr")  ; IDC_SIZEALL
hCursH := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32649, "Ptr")  ; IDC_HAND
OnMessage(0x205, "WM_RBUTTONUP")
OnMessage(0x201, "WM_LBUTTONDOWN")
OnMessage(0x200, "WM_MouseMove")
OnMessage(0x20A, "WM_MouseWheel")  ; vertical
OnMessage(0x20E, "WM_MouseWheel")  ; horizontal
OnMessage(0x404, "AHK_NOTIFYICON")
Sleep, 1
theChimer()
SetTimer, wrapChimerTimer, 3500, 950
Sleep, 1
ScriptInitialized := 1      ; the end of the autoexec section and INIT
If (tickTockNoise=1 && userMuteAllSounds!=1)
   SoundLoop(tickTockSound)

If (StrLen(isHolidayToday)<3)
   CreateOSDGUI(generateDateTimeTxt())

If (showBibleQuotes=1)
   SetTimer, InvokeBibleQuoteNow, % bibleQuoteFreq

If (constantAnalogClock=1)
   InitClockFace()

If (constantAnalogClock=1)
   SetTimer, analogClockStarter, -1000

If (NoWelcomePopupInfo!=1)
   ShowWelcomeWindow()

If (AdditionalStrikes=1)
{
   rr := (strikeEveryMin>59) ? AdditionalStrikeFreq : calcNextQuarter(strikeEveryMin)
   SetTimer, AdditionalStrikerPerformer, % -rr
}

If (constantOSDvisible=1)
   SetTimer, TimerAlwaysShowOSD, 1500
Else If (showTimeWhenIdle=1)
   SetTimer, TimerShowOSDidle, 1500

Return    ; the end of auto-exec section

InitSoundChannels() {
  SNDfile_auxil_bell := A_ScriptDir "\sounds\auxilliary-bell.mp3"
  SNDfile_christmas := A_ScriptDir "\sounds\christmas.mp3"
  SNDfile_evening := A_ScriptDir "\sounds\evening.mp3"
  SNDfile_hours := A_ScriptDir "\sounds\hours.mp3"
  SNDfile_japan_bell := A_ScriptDir "\sounds\japanese-bell.mp3"
  SNDfile_midnight := A_ScriptDir "\sounds\midnight.mp3"
  SNDfile_morning := A_ScriptDir "\sounds\morning.mp3"
  SNDfile_noon1 := A_ScriptDir "\sounds\noon1.mp3"
  SNDfile_noon2 := A_ScriptDir "\sounds\noon2.mp3"
  SNDfile_noon3 := A_ScriptDir "\sounds\noon3.mp3"
  SNDfile_noon4 := A_ScriptDir "\sounds\noon4.mp3"
  SNDfile_howl := A_ScriptDir "\sounds\howling.mp3"
  SNDfile_chimes1 := A_ScriptDir "\sounds\orthodox-chimes1.mp3"
  SNDfile_chimes2 := A_ScriptDir "\sounds\orthodox-chimes2.mp3"
  SNDfile_quarters := A_ScriptDir "\sounds\quarters.mp3"
  SNDfile_semantron1 := A_ScriptDir "\sounds\semantron1.mp3"
  SNDfile_semantron2 := A_ScriptDir "\sounds\semantron2.mp3"
  SNDfile_surah := A_ScriptDir "\sounds\al-fatiha-surah.mp3"
  SNDfile_armistice := A_ScriptDir "\sounds\armistice.mp3"
  SNDfile_beep := A_ScriptDir "\sounds\beep.wav"

  Loop, 12
    SNDmedia_hours%A_Index% := (useDirectSound=1) ? SNDfile_hours : MCI_Open(SNDfile_hours)
  Loop, 4
    SNDmedia_quarters%A_Index% := (useDirectSound=1) ? SNDfile_quarters : MCI_Open(SNDfile_quarters)

  SNDmedia_auxil_bell := (useDirectSound=1) ? SNDfile_auxil_bell : MCI_Open(SNDfile_auxil_bell)
  SNDmedia_christmas := (useDirectSound=1) ? SNDfile_christmas : MCI_Open(SNDfile_christmas)
  SNDmedia_surah := (useDirectSound=1) ? SNDfile_surah : MCI_Open(SNDfile_surah)
  SNDmedia_armistice := (useDirectSound=1) ? SNDfile_armistice : MCI_Open(SNDfile_armistice)
  SNDmedia_beep := (useDirectSound=1) ? SNDfile_beep : MCI_Open(SNDfile_beep)
  SNDmedia_evening := (useDirectSound=1) ? SNDfile_evening : MCI_Open(SNDfile_evening)
  SNDmedia_japan_bell := (useDirectSound=1) ? SNDfile_japan_bell : MCI_Open(SNDfile_japan_bell)
  SNDmedia_midnight := (useDirectSound=1) ? SNDfile_midnight : MCI_Open(SNDfile_midnight)
  SNDmedia_morning := (useDirectSound=1) ? SNDfile_morning : MCI_Open(SNDfile_morning)
  SNDmedia_noon1 := (useDirectSound=1) ? SNDfile_noon1 : MCI_Open(SNDfile_noon1)
  SNDmedia_noon2 := (useDirectSound=1) ? SNDfile_noon2 : MCI_Open(SNDfile_noon2)
  SNDmedia_noon3 := (useDirectSound=1) ? SNDfile_noon3 : MCI_Open(SNDfile_noon3)
  SNDmedia_noon4 := (useDirectSound=1) ? SNDfile_noon4 : MCI_Open(SNDfile_noon4)
  SNDmedia_orthodox_chimes1 := (useDirectSound=1) ? SNDfile_chimes1 : MCI_Open(SNDfile_chimes1)
  SNDmedia_orthodox_chimes2 := (useDirectSound=1) ? SNDfile_chimes2 : MCI_Open(SNDfile_chimes2)
  SNDmedia_howl := (useDirectSound=1) ? SNDfile_howl : MCI_Open(SNDfile_howl)
  SNDmedia_semantron1 := (useDirectSound=1) ? SNDfile_semantron1 : MCI_Open(SNDfile_semantron1)
  SNDmedia_semantron2 := (useDirectSound=1) ? SNDfile_semantron2 : MCI_Open(SNDfile_semantron2)
}

TimerShowOSDidle() {
     Static isThisIdle := 0, lastFullMoonZeitTest := -9020
          , lastCalcZeit := 1, prevTime

     If (PrefOpen=1 || A_IsSuspended || constantOSDvisible=1)
        Return

     If !A_IsSuspended
        mouseHidden := checkMcursorState()

     If (showTimeWhenIdle=1 && (A_TimeIdle > userIdleAfter) && mouseHidden!=1 && DestroyIdleOSDgui("test")!=1)
     {
        FormatTime, HoursIntervalTest,, H ; 0-23 format
        If (markFullMoonHowls=1 && hasHowledDay!=A_YDay && userMuteAllSounds!=1 && lastFullMoonZeitTest!=HoursIntervalTest && (A_TickCount - lastCalcZeit>28501) )
        {
           lastFullMoonZeitTest := HoursIntervalTest
           pk := oldMoonPhaseCalculator()
           lastCalcZeit := A_TickCount
           If InStr(pk[1], "full moon")
           {
              hasHowledDay := A_YDay
              INIaction(1, "hasHowledDay", "SavedSettings")
              volumeAction := SetMyVolume()
              MCXI_Play(SNDmedia_howl)
           }
        }

        isThisIdle := 1
        DoGuiFader := 0
        stru := generateDateTimeTxt(0, 1)
        If (OSDGuiaVisible!=1)
           CreateOSDGUI(stru " ", 0, 1)

        If (prevTime!=stru)
        {
           GuiControl, osdGuia: +Center, osdGuiaTXT
           GuiControl, osdGuia:, osdGuiaTXT, % stru
           prevTime := stru
        }

        SetTimer, DestroyOSDguia, Delete
        SetTimer, DestroyIdleOSDgui, -500
        DoGuiFader := 1
     } Else If (showTimeWhenIdle=1 && OSDGuiaVisible=1 && isThisIdle=1)
     {
        isThisIdle := 0
        SetTimer, DestroyOSDguia, -500
     } Else isThisIdle := 0
}

TimerAlwaysShowOSD() {
    Static isThisIdle := 0, lastFullMoonZeitTest := -9020
         , lastCalcZeit := 1, prevTime
     ; ToolTip, % "l=" PrefOpen "|" A_IsSuspended "|" constantOSDvisible , , , 2
    If (PrefOpen=1 || A_IsSuspended || constantOSDvisible!=1  || (A_TickCount - lastOSDredraw<2000)) 
       Return

    FormatTime, HoursIntervalTest,, H ; 0-23 format
    If (markFullMoonHowls=1 && hasHowledDay!=A_YDay && userMuteAllSounds!=1 && lastFullMoonZeitTest!=HoursIntervalTest && (A_TickCount - lastCalcZeit>28501) )
    {
       lastFullMoonZeitTest := HoursIntervalTest
       pk := oldMoonPhaseCalculator()
       lastCalcZeit := A_TickCount
       If InStr(pk[1], "full moon")
       {
          hasHowledDay := A_YDay
          INIaction(1, "hasHowledDay", "SavedSettings")
          volumeAction := SetMyVolume()
          MCXI_Play(SNDmedia_howl)
       }
    }

    isThisIdle := 1
    DoGuiFader := 0
    stru := generateDateTimeTxt(0, 1)
    ll := ( StrLen( CreateOSDGUI(0, "last") ) != StrLen(stru) + 1 ) ? 1 : 0
    If (OSDGuiaVisible!=1 || ll=1)
    {
       ; ToolTip, % "l=" ll , , , 2
       CreateOSDGUI(stru " ", 0, 1)
       prevTime := ""
    }

    If (prevTime!=stru)
    {
       GuiControl, osdGuia: +Center, osdGuiaTXT
       GuiControl, osdGuia:, osdGuiaTXT, % stru
       prevTime := stru
    }
    SetTimer, DestroyOSDguia, Delete
    DoGuiFader := 1
}

DestroyIdleOSDgui(test:=0) {
  Static prevu
  MouseGetPos, xu, yu, OutputVarWin, OutputVarControl
  thisu := "a" xu "|" yu
  If (test="test")
     Return (thisu=prevu) ? 1 : 0

  If (OutputVarWin=hWinOSD)
  {
     DestroyOSDguia()
     prevu := "a" xu "|" yu
  }
}

ShowWelcomeWindow() {
    If reactWinOpened(A_ThisFunc, 2)
       Return

    Global BtnSilly0, BtnSilly1, BtnSilly2
    GenericPanelGUI()
    AnyWindowOpen := 2
    Gui, Font, c%AboutTitleColor% s20 Bold, Arial, -wrap
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section hwndhIcon, %A_ScriptDir%\resources\bell-image.png
    Gui, Add, Text, x+7 y10, %appName%
    Gui, Font, s12 Bold, Arial, -wrap
    Gui, Add, Text, y+5, Quick start window - read me
    doResetGuiFont()
    btnWid := 150
    txtWid := 310
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 100
       txtWid := txtWid + 170
       Gui, Font, s%LargeUIfontValue%
    }

    sm := (PrefsLargeFonts=1) ? 40 : 28
    Gui, Add, Text, xs y+10 w%txtWid%, %appName% is currently running in background. To configure it or exit, please locate its icon in the system tray area, next to the system clock in the taskbar. To access the settings double click or right click on the bell icon.
    Gui, Add, Button, xs y+15 w%btnWid% h%sm% gPanelShowSettings, &Settings panel
    Gui, Add, Checkbox, x+5 w%btnWid% hp +0x1000 gToggleLargeFonts Checked%PrefsLargeFonts% vPrefsLargeFonts, Large UI font sizes
    Gui, Add, Button, xs y+10 w%btnWid% hp gPanelTodayInfos, &About today
    Gui, Add, Checkbox, x+5 w%btnWid% hp +0x1000 gToggleAnalogClock Checked%constantAnalogClock% vconstantAnalogClock, &Analog clock display
    Gui, Add, Checkbox, xs y+10 hp gToggleWelcomeInfos Checked%NoWelcomePopupInfo% vNoWelcomePopupInfo, &Never show this window
    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Welcome to %appName% v%Version%
}

ToggleWelcomeInfos() {
  Gui, SettingsGUIA: Default
  GuiControlGet, NoWelcomePopupInfo
  ; NoWelcomePopupInfo := !NoWelcomePopupInfo
  INIaction(1, "NoWelcomePopupInfo", "SavedSettings")
}

analogClockStarter() {
  If (constantAnalogClock=1)
  {
     If (moduleAnalogClockInit!=1)
        InitClockFace()
     ; ClockVisibility := 1
     ; DestroyOSDguia(A_ThisFunc)
     showAnalogClock()
  }
}

friendlyAlarmInfoz() {
    alarmInfos := ""
    If (userMustDoAlarm=1 && isValidAlarmTime(userAlarmHours, userAlarmMins))
    {
       timeu := Format("{:02}:{:02}", userAlarmHours, userAlarmMins)
       If (userAlarmIsSnoozed=1)
       {
          alarmInfos := "`nAlarm is set at: " timeu " (snoozed for " userAlarmSnooze " min.)"
       } Else If (userAlarmRepeated=1)
       {
          canDo := InStr(userAlarmWeekDays, A_WDay) ? 1 : 0
          ; ToolTip, % canDo "=" ObserveHolidays "=" isHolidayToday , , , 2
          If (canDo && ObserveHolidays=1 && StrLen(isHolidayToday)>2)
             canDo := (InStr(userAlarmWeekDays, "p") && TypeHolidayOccured=3) || (InStr(userAlarmWeekDays, "s") && TypeHolidayOccured=2 && ObserveSecularDays=1) || (InStr(userAlarmWeekDays, "r") && TypeHolidayOccured=1 && ObserveReligiousDays=1) ? 0 : 1

          alarmInfos := canDo ? "`nRegular alarm set at: " timeu : "" ; "`nRegular alarm set: exception rule applies for today"
       } Else
       {
          tmr := (isAlarmTmrw=1) ? " (tomorrow)" : ""
          alarmInfos := "`nAlarm set at: " timeu tmr
       }
    }

    Return alarmInfos
}

decideSysTrayTooltip(modus:=0) {
    Static lastInvoked := 1, lastMsg
    If (modus!="about")
    {
       If (A_TickCount - lastInvoked<450)
          Return lastMsg
    }

    RunType := A_IsCompiled ? "" : " [script]"
    If A_IsSuspended
       RunType := " [DEACTIVATED]"
    If (userMustDoTimer=1 && userTimerExpire)
       timerInfos := "`nTimer set to expire at: " userTimerExpire "."

    alarmInfos := friendlyAlarmInfoz()
    If (stopWatchRealStartZeit || stopWatchBeginZeit)
       stopwInfos := "`nStopwatch is running."
    If (userMuteAllSounds=1 || BeepsVolume<1)
       soundsInfos := "`nAll sounds are muted."

    relName := (UserReligion=1) ? "a Catholic" : "an Orthodox"
    thisHoli := (TypeHolidayOccured=3) ? "a personal" : relName " Christian"
    If (TypeHolidayOccured=2) ; secular
       thisHoli := "a secular"

    thisHoli := (StrLen(isHolidayToday)>2) ? "`nToday " thisHoli " event is observed." : ""
    If (modus!="about")
    {
       testu := wrapCalculateEquiSolsDates(A_YDay)
       If InStr(testu.msg, "now")
          resu := "`n" SubStr(testu.msg, 4)

       If (InStr(lastUsedGeoLocation, "|") && OverrideOSDcolorsAstro=1)
       {
          w := StrSplit(lastUsedGeoLocation, "|")
          If (w.Count()>5)
          {
             getSunAzimuthElevation(A_NowUTC, w[2], w[3], 0, azii, elevu)
             obj := SolarCalculator(A_NowUTC, w[2], w[3])
             getSunAzimuthElevation(obj.RawN, w[2], w[3], 0, azii, eleva)
             j := decideJijiReadable(A_NowUTC, elevu, w[2], w[3], Round(eleva, 2))
             sunInfos := (j="daylight" || j="night" || !j) ? "" : "`n" j "."
          }
       }
    }

    Menu, Tray, Tip, % appName " v" Version RunType sunInfos timerInfos alarmInfos stopwInfos  thisHoli resu soundsInfos
    lastInvoked := A_TickCount
    lastMsg := sunInfos timerInfos alarmInfos stopwInfos thisHoli resu soundsInfos
    Return lastMsg
}

AHK_NOTIFYICON(wParam, lParam, uMsg, hWnd) {
; lParam 
  ; WM_LBUTTONDOWN = 0x201
  ; WM_LBUTTONUP = 0x202
  ; WM_LBUTTONDBLCLK = 0x203
  ; WM_RBUTTONDOWN = 0x204
  ; WM_RBUTTONUP = 0x205
  ; WM_MBUTTONDOWN = 0x207
  ; WM_MBUTTONUP = 0x208

  Static lastLClick := 1, LastInvoked := 1, LastInvoked2 := 1
  extras := decideSysTrayTooltip()
  If (PrefOpen=1 || A_IsSuspended) || (A_TickCount - scriptStartZeit < 1550)
  {
     If (PrefOpen=1) && ((lParam = 0x203) || (lParam = 0x202))
        WinActivate, ahk_id %hSetWinGui%
     Return
  }

  ; If (storeSettingsREG=1 && lParam = 0x204)   ; r-button down: the tray menu follows on its release
  ;    StoreStartupRefreshMark()

  If (lParam = 0x203) ; double-click
  {
     stopStrikesNow := 1
     strikingBellsNow := 0
     If IsFunc(LastWinOpened)
        %LastWinOpened%()
     Else
        PanelAboutWindow()
  } Else If (lParam = 0x202) ; l-click
  {
     stopStrikesNow := 1
     strikingBellsNow := 0
     DoGuiFader := 0
     ; If (ClockVisibility=0 || defAnalogClockPosChanged=1 && ClockVisibility=1) && (lParam=0x201 && ScriptInitialized=1)         ; left click
     If (ScriptInitialized=1)
        CreateOSDGUI(generateDateTimeTxt() extras, 0, 1)
     DoGuiFader := 1
     LastInvoked2 := A_TickCount
  } Else If (lParam = 0x208) && (strikingBellsNow=0)   ; middle click
  {
     LastInvoked2 := A_TickCount
     If (AnyWindowOpen=1)
        stopStrikesNow := 0
     SetMyVolume(1)
     DoGuiFader := 0
     ; If (ClockVisibility=0 || defAnalogClockPosChanged=1 && ClockVisibility=1)
     If (ScriptInitialized=1)
        CreateOSDGUI(generateDateTimeTxt() extras, 0, 1)
     If (tollQuarters=1)
        strikeQuarters(1)
     If (tollHours=1 || tollHoursAmount=1)
        strikeHours(1)
     DoGuiFader := 1
  } Else If (OSDGuiaVisible=0 && strikingBellsNow=0)
    && (A_TickCount-lastInvoked>2000) && (A_TickCount-lastFaded>1500)
  {
     LastInvoked := A_TickCount
     DoGuiFader := 0
     ; If (ClockVisibility=0 || defAnalogClockPosChanged=1 && ClockVisibility=1) && (ScriptInitialized=1)
     If (ScriptInitialized=1)
        CreateOSDGUI(generateDateTimeTxt(0))
     DoGuiFader := 1
  }
}

strikeJapanBell() {
  If (noTollingBgrSounds>=2)
     isSoundPlayingNow()

  SetMyVolume(1)
  MCXI_Play(SNDmedia_japan_bell)
}

InvokeBibleQuoteNow() {
  Static bibleQuotesFile, countLines, menuAdded, lastLoaded := 1
  
  If (PrefOpen=0 && A_IsSuspended) || (stopAdditionalStrikez=1 && PrefOpen=0)
     Return

  If (PrefOpen=1)
     VerifyTheOptions(1, 1)

  If ((noTollingWhenMhidden=1 || noBibleQuoteMhidden=1) && PrefOpen=0) ; (noTollingWhenMhidden=1)
  {
     mouseHidden := checkMcursorState()
     If (mouseHidden=1 && showBibleQuotes=1 && noBibleQuoteMhidden=1)
     {
        SetTimer, InvokeBibleQuoteNow, % bibleQuoteFreq//2
        Return
     }
  }

  stopStrikesNow := 0
  DoGuiFader := 1
  If (!bibleQuotesFile || (PrefOpen=1 && (A_TickCount - lastLoaded>2000)))
  {
     lang := bibleQuotesLangCode(BibleQuotesLang)
     Try FileRead, bibleQuotesFile, %A_ScriptDir%\resources\bible-quotes-%lang%.txt
     lastLoaded := A_TickCount
     If (ErrorLevel || !bibleQuotesFile || !lang)
     {
        bibleQuotesFile := ""
        Return
     }
  }

  If (orderedBibleQuotes=1)
  {
     If !countLines
        countLines := ST_Count(bibleQuotesFile, "`n") + 1

     ; the verse the start point names is the one shown; what is kept afterwards is the
     ; verse to come next, so the field in the settings window always names the next verse
     Line2Read := clampInRange(userBibleStartPoint, 1, countLines, 1)
     userBibleStartPoint := clampInRange(Line2Read + 1, 1, countLines, 1)
     INIaction(1, "userBibleStartPoint", "SavedSettings")
     If (PrefOpen=1)
        GuiControl, SettingsGUIA:, userBibleStartPoint, % userBibleStartPoint
  } Else If (PrefOpen!=1)
  {
     If !countLines
        countLines := ST_Count(bibleQuotesFile, "`n") + 1

     Loop
     {
         Random, Line2Read, 1, %countLines%
         If !InStr(QuotesAlreadySeen, "a" Line2Read "a")
            stopLoop := 1
     } Until (stopLoop=1 || A_Index>912)
  } Else Line2Read := "R"
  ; Line2Read := 670

  bibleQuote := ST_ReadLine(bibleQuotesFile, Line2Read)
  If (p := InStr(bibleQuote, "▪"))
     bibleQuote := SubStr(bibleQuote, p + 1)
  
  If InStr(bibleQuote, " || ")
  {
     lineArr := StrSplit(bibleQuote, " || ")
     bibleQuote := lineArr[2]
  }

  If (ST_Count(bibleQuote, """")=1)
     bibleQuote := StrReplace(bibleQuote, """")

  If (BibleQuotesLang=1)
  {
     bibleQuote := RegExReplace(bibleQuote, "i)(\ssaying.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\ssaid.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\sand.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\sbut)$")
  }

  bibleQuote := RegExReplace(bibleQuote, "i)(\;|\,|\:)$")
  lineArr := StrSplit(bibleQuote, " | ")
  bibleQuote := Trim(lineArr[2]) " (" Trim(lineArr[1]) ")"
  If (StrLen(bibleQuote)>8)
  {
     LastBibleMsg := bibleQuote
     QuotesAlreadySeen .= "a" Line2Read "a"
     QuotesAlreadySeen := StrReplace(QuotesAlreadySeen, "aa", "a")
     StringRight, QuotesAlreadySeen, QuotesAlreadySeen, 91550
     LastBibleQuoteDisplay := LastBibleQuoteDisplay2 := A_TickCount
     Sleep, 2
     CreateBibleGUI(bibleQuote)
     If (PrefOpen!=1)
     {
        SetMyVolume(1)
        INIaction(1, "QuotesAlreadySeen", "SavedSettings")
     }

     If (mouseHidden!=1 && gongAudioVerseDisplay=1)
        strikeJapanBell()
 
     quoteDisplayTime := 1200 + StrLen(bibleQuote) * 123
     If (quoteDisplayTime>120100)
        quoteDisplayTime := 120100
     Else If (PrefOpen=1)
        quoteDisplayTime := quoteDisplayTime/2 + DisplayTime
 
     LastBibleQuoteDisplay := A_TickCount
     SetTimer, DestroyBibleGui, % -quoteDisplayTime
     If (showBibleQuotes=1)
        SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%
  } Else If (showBibleQuotes=1)
     SetTimer, InvokeBibleQuoteNow, % bibleQuoteFreq//2
}

DestroyOSDguia(funcu:=0, forced:=0) {
  Critical, On
  If (forced=1 || PrefOpen=1)
     LastBibleQuoteDisplay := 1

  ; ToolTip, % "f=" funcu , , , 2
  GuiFader("ChurchTowerOSDwin","hide", OSDalpha)
  Gui, osdGuia: Destroy
  OSDGuiaVisible := 0
}

ShowLastBibleMsg() {
  If (StrLen(LastBibleMsg)>6 && PrefOpen!=1)
  {
     DoGuiFader := 1
     LastBibleQuoteDisplay := A_TickCount
     CreateBibleGUI(LastBibleMsg)
     strikeJapanBell()
     quoteDisplayTime := 1500 + StrLen(LastBibleMsg) * 123
     SetTimer, DestroyBibleGui, % -quoteDisplayTime
  } Else
     CreateOSDGUI("No Bible quote previously displayed", 0, 1)
}

ForcedDestroyBibleGui() {
    DestroyBibleGui(A_ThisFunc, 1)
}

DestroyBibleGui(funcu:=0, forced:=0) {
  Critical, On
  If (forced=1 || PrefOpen=1)
     LastBibleQuoteDisplay := 1

  If (A_TickCount - LastBibleQuoteDisplay<quoteDisplayTime) && (PrefOpen=0 && forced=0)
  {
     SetTimer, DestroyBibleGui, -50
     Return
  }
  ; SoundBeep
  ; ToolTip, % "f=" funcu , , , 2
  GuiFader("ChurchTowerBibleWin","hide", OSDalpha)
  Gui, BibleGui: Destroy
  GuiFader("ScreenShader","hide", 130)
  Gui, ScreenBl: Destroy
  GuiFader("BibleShareBtn","hide", OSDalpha)
  Gui, ShareBtnGui: Destroy
  BibleGuiVisible := 0
}


SetMyVolume(noRestore:=0) {
  Static mustRestoreVol, LastInvoked := 1

  If (PrefOpen=1 && hSetWinGui)
  {
     Gui, SettingsGUIA: Default
     GuiControlGet, DynamicVolume
  }
  ; Else If (AnyWindowOpen>0)
  ;    CloseWindow()

  If (DynamicVolume=0)
  {
     actualVolume := (cutVolumeHalf=1) ? Floor(BeepsVolume/2.5) : BeepsVolume
     SetVolume(actualVolume)
     Return
  }

  If (BeepsVolume<1)
  {
     SetVolume(0)
     Return
  }

  If (A_TickCount - LastNoonZeitSound<150000) && (PrefOpen=0 && noTollingBgrSounds=2)
     Return

  If (ScriptInitialized=1 && AutoUnmute=1 && BeepsVolume>1 && userMuteAllSounds=0
  && (A_TickCount - LastInvoked > 290100) && noRestore=0)
  {
     mustRestoreVol := 0
     LastInvoked := A_TickCount
     SoundGet, master_mute, , mute
     If (master_mute="on")
     {
        SoundSet, 0, , mute
        mustRestoreVol := 1
     }

     SoundGet, master_vol
     If (Round(master_vol)<1)
     {
        SoundSet, 3
        mustRestoreVol := 1
     }
  }

  SoundGet, master_volume
  If (master_volume>50 && BeepsVolume>50)
     val := BeepsVolume - Round(master_volume/3)
  Else If (master_volume<49 && BeepsVolume>50)
     val := BeepsVolume + Round(master_volume/6)
  Else If (master_volume<50 && BeepsVolume<50)
     val := BeepsVolume + Round(master_volume/4)
  Else
     val := BeepsVolume

  If (master_volume<25 && BeepsVolume<25)
     val := BeepsVolume + Round(master_volume/1.3)
  Else If (master_volume<25 && BeepsVolume>70)
     val := BeepsVolume + master_volume

  Random, randySound, -2, 2
  actualVolume := val + randySound
  If (actualVolume>99)
     actualVolume := 99
  If (cutVolumeHalf=1)
     actualVolume := Floor(actualVolume/2.5)

  SetVolume(actualVolume)
  Return mustRestoreVol
}

SetVolume(val:=100,r:="") {
; Function by Drugwash
  v := Round(val*655.35), vr := r="" ? v : Round(r*655.35)
  DllCall("winmm\waveOutSetVolume", "UInt", 0, "UInt", (v|vr<<16))
}

menuSetAudioVolume(a, b, c) {
   oldu := BeepsVolume "%"
   BeepsVolume := StrReplace(Trimmer(a), "%")
   SetMyVolume(1)
   If (tollQuarters=1)
      strikeQuarters(1)
   Else If (tollHours=1 || tollHoursAmount=1)
      strikeHours(1)
   ; ToolTip, % a "|" b "|" c , , , 2
   Menu, menuSoundOptionz, Rename, % "VOL: " oldu, % "VOL: " BeepsVolume "%"
   INIaction(1, "BeepsVolume", "SavedSettings")
   If (userMuteAllSounds=1)
      ToggleAllMuteSounds()
}

UIvolumeSlider() {
    Critical, Off
    Gui, SettingsGUIA: Default
    GuiControlGet, result , , BeepsVolume, 
    GuiControlGet, tollQuarters
    GuiControlGet, tollHours
    GuiControlGet, tollHoursAmount
    GuiControlGet, strikeInterval

    stopStrikesNow := 0
    BeepsVolume := result
    SetMyVolume(1)
    VerifyTheOptions()
    GuiControl, SettingsGUIA:, volLevel, % (result<2) ? "Audio: [ MUTE ]" : "Audio volume: " result " % "
    If (tollQuarters=1)
       strikeQuarters(1)
    Else If (tollHours=1 || tollHoursAmount=1)
       strikeHours(1)
}

RandomNumberCalc(minVariation:=100,maxVariation:=250) {
  Static newNumber := 1
       , lastNumber := 1
  Loop
  {
     Random, newNumber, 5, %maxVariation%
     If (newNumber - lastNumber > minVariation) || (lastNumber - newNumber > minVariation)
        allGood := 1
  } Until (allGood=1 || A_Index>90000)

  lastNumber := newNumber
  Return newNumber
}

strikeQuarters(beats, delayu:=0) {
  Critical, on
  quartersTotalTime := 0
  Loop, %beats%
  {
      randomDelay := RandomNumberCalc()
      fn := Func("MCXI_Play").Bind(SNDmedia_quarters%A_Index%)
      thisDelay := strikeInterval * (A_Index - 1) + randomDelay//3 + delayu
      quartersTotalTime := thisDelay + 2500
      SetTimer, % fn, % -thisDelay, 500
      Sleep, 10
  }
}

strikeHours(beats, delayu:=0, thisZeit:=0) {
  Critical, on
  hoursTotalTime := 0
  Loop, %beats%
  {
      randomDelay := RandomNumberCalc()
      fn := Func("MCXI_Play").Bind(SNDmedia_hours%A_Index%)
      thisDelay := strikeInterval * (A_Index - 1) + randomDelay//3 + delayu
      hoursTotalTime := thisDelay + 5500
      SetTimer, % fn, % -thisDelay, 900
      Sleep, 10
  }
}

playSemantron(snd:=1, delayu:=1) {
  If (snd=1)
     semtr2play := "semantron1"
  Else If (snd=2)
     semtr2play := "semantron2"
  Else If (snd=3)
     semtr2play := "orthodox_chimes2"
  Else If (snd=4)
     semtr2play := "orthodox_chimes1"
  Else
      Return

  sleepDelay := RandomNumberCalc()
  fn := Func("MCXI_Play").Bind(SNDmedia_%semtr2play%)
  SetTimer, % fn, % -(delayu + sleepDelay*2)
  Global LastNoonZeitSound := A_TickCount
}

tollGivenNoon(snd, delayu) {
  If (noTollingBgrSounds=2)
     SetMyVolume(1)

  If !snd
  {
     ; INIaction(0, "LastNoonAudio", "SavedSettings")
     choice := clampInRange(LastNoonAudio + 1, 1, 4, 1)
     LastNoonAudio := choice
     INIaction(1, "LastNoonAudio", "SavedSettings")
  } Else choice := snd

  ; ToolTip, % "Noon audio playing: " choice
  sleepDelay := RandomNumberCalc()
  fn := Func("MCXI_Play").Bind(SNDmedia_noon%choice%)
  SetTimer, % fn, % -(strikeInterval//2 + sleepDelay//2 + delayu)
  Global LastNoonZeitSound := A_TickCount
  ; SetTimer, removeTooltip, -1000
}


clampInRange(value, min, max, reverse:=0) {
   If (reverse=1)
   {
      If (value>max)
         value := min
      Else If (value<min)
         value := max
   } Else
   {
      If (value>max)
         value := max
      Else If (value<min)
         value := min
   }

   Return value
}

isInDSTperiod(yd, dStartYday, dEndYday) {
; Tests if a given day of year falls within a daylight saving time period.
; dEndYday is exclusive. In the southern hemisphere the DST period wraps around
; the end of the year (it starts in October and ends in April), so a plain
; min/max range test - like isInRange() does - would return the exact opposite there.

   If (!dStartYday || !dEndYday || !yd)
      Return 0

   Return (dStartYday<=dEndYday) ? (yd>=dStartYday && yd<dEndYday) : (yd>=dStartYday || yd<dEndYday)
}

summerHalfYdays(tziObj, ByRef startYday, ByRef endYday) {
; Returns the days of year that delimit the northern summer half, the stretch during which
; every location uses the second of the two offsets it carries in geo-locations-final.txt.
;
; Those two offsets are the ones in effect on the 1st of January and on the 1st of July -
; see the header of resources/timezones.txt. They are indexed by season, not by standard
; and daylight time: a southern location is on standard time in July, exactly while a
; northern one is on daylight time, so in both hemispheres the second column is the one
; that applies between spring and autumn as seen from the north.
;
; The host machine's own daylight saving calendar is the only source of transition days at
; hand and it is used to place the boundary, but only when it is a northern calendar. A
; southern host switches at the opposite ends of the year and, taken at face value, would
; invert the offset of every location on Earth all year long. A host in a zone that keeps
; no daylight saving time reports no transition day at all, which used to pin the whole
; world to its January offset from spring to autumn.

   Static defaultStart := 84    ; around the last Sunday of March
        , defaultEnd := 303     ; around the last Sunday of October

   startYday := defaultStart
   endYday := defaultEnd
   If !IsObject(tziObj)
      Return

   dStart := tziObj.DaylightDateYday
   dEnd := tziObj.StandardDateYday
   If (dStart && dEnd && dStart<dEnd)
   {
      startYday := dStart
      endYday := dEnd
   }
}

pickSeasonalGmtOffset(yd, tziObj, janOffset, julOffset) {
; Picks the offset a location keeps on the given day of year out of the two seasonal ones
; stored for it. See summerHalfYdays() for why the choice cannot be made by simply asking
; the host machine whether it is currently observing daylight saving time.

   summerHalfYdays(tziObj, sYday, eYday)
   Return isInDSTperiod(yd, sYday, eYday) ? julOffset : janOffset
}

buildDSTinfo(tziObj, standardOffset, daylightOffset) {
; Bundles everything wrapCalcSunInfos() needs to resolve the GMT offset of the days that
; surround the reference day. Returns 0 when there is no time zone information to work
; with, which simply keeps the single offset the caller supplied.

   If !IsObject(tziObj)
      Return 0

   summerHalfYdays(tziObj, sYday, eYday)
   Return {dstStartYday: sYday, dstEndYday: eYday, stdOffset: standardOffset, dstOffset: daylightOffset}
}

resolveGmtOffset(timeStampu, dstInfo, gmtOffset) {
; Returns the GMT offset in effect on the local day of timeStampu.
; The sun wrappers are handed a single offset, the one valid for the reference day, yet they
; also compute the day before and the two days after it. Around a daylight saving switch
; those neighbours belong to the other offset and would otherwise come out an hour off.
; Without a DST descriptor the offset of the reference day is kept, as before.

   If (!IsObject(dstInfo) || !timeStampu)
      Return gmtOffset

   FormatTime, ydu, % timeStampu, Yday
   If !ydu
      Return gmtOffset

   Return isInDSTperiod(ydu, dstInfo.dstStartYday, dstInfo.dstEndYday) ? dstInfo.dstOffset : dstInfo.stdOffset
}

nearestAnalogClockScale(givenScale) {
; The analog clock scale can only be set from a menu built out of analogClockScalesList.
; Any other value - like a default shipped in a previous release - would leave the menu
; unable to mark the entry in use, so stored values are snapped to the closest preset.

   bestDiff := 99999
   If !isNumber(givenScale)
      givenScale := 1

   Loop, Parse, analogClockScalesList, |
   {
      thisDiff := Abs(A_LoopField - givenScale)
      If (thisDiff<bestDiff)
      {
         bestDiff := thisDiff
         bestScale := A_LoopField
      }
   }

   Return bestScale ? bestScale : "1.00"
}

TollExtraNoon() {
  ; Static lastToll := 1
  If (noTollingBgrSounds>=2)
     isSoundPlayingNow()

  If (AnyWindowOpen=1)
     stopStrikesNow := 0

  If (PrefOpen=1)  ; || ((A_TickCount - lastToll<100000) && (AnyWindowOpen=1))
     Return

  If (stopStrikesNow=1)
     Return

  Global LastNoonZeitSound := A_TickCount
  Sleep, 2
  If (noTollingBgrSounds=2)
     SetMyVolume(1)

  ; Random, snd, 1, 4
  tollGivenNoon(0, 250)
  ; lastToll := A_TickCount
}

AdditionalStrikerPerformer() {
  Static lastInvoked := 1
  If (noTollingBgrSounds>=2)
     isSoundPlayingNow()

  If (noTollingWhenMhidden=1)
     mouseHidden := checkMcursorState()

  rr := (strikeEveryMin>59) ? AdditionalStrikeFreq : calcNextQuarter(strikeEveryMin)
  ; ToolTip, % strikeEveryMin "|" rr , , , 2
  SetTimer, AdditionalStrikerPerformer, % -rr
  If (A_TickCount - lastInvoked<9500)
  || (mouseHidden=1 || A_IsSuspended || strikingBellsNow=1)
     Return

  SetMyVolume(1)
  MCXI_Play(SNDmedia_auxil_bell)
  lastInvoked := A_TickCount
}

PlayAlarmedBell(firstu:=0) {
; The auxiliary bell and the gong ring long, so they are sounded on every other tick of the
; repeat timer that calls this; bu keeps count of the ticks. firstu=1 marks the first call of
; an alert, or a click on the Test button, and always rings
   Static indexu := 0, bu := 0
   If (firstu=1)
      bu := 0

   SetMyVolume(1)
   If (userAlarmSound=1)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_auxil_bell, 1)
   } Else If (userAlarmSound=2)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_quarters%indexu%, 1)
   } Else If (userAlarmSound=3)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_hours%indexu%, 1)
   } Else If (userAlarmSound=4)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_japan_bell, 1)
   } Else If (userAlarmSound=5)
   {
      MCXI_Play(SNDmedia_beep, 1)
   }
}

PlayTimerBell(firstu:=0) {
; see PlayAlarmedBell() for firstu
   Static indexu := 0, bu := 0
   If (firstu=1)
      bu := 0

   SetMyVolume(1)
   If (userTimerSound=1)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_auxil_bell, 1)
   } Else If (userTimerSound=2)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_quarters%indexu%, 1)
   } Else If (userTimerSound=3)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_hours%indexu%, 1)
   } Else If (userTimerSound=4)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_japan_bell, 1)
   } Else If (userTimerSound=5)
   {
      MCXI_Play(SNDmedia_beep, 1)
   }
}

MCXI_Play(hSND, forced:=0) {
; forced=1 is for the bells of the alarms and of the timers, which the user asked for outright:
; they play through stopAdditionalStrikez and stopStrikesNow, the flags the tolling schedule
; («keep silence in the defined interval»), the background sounds check and a click on the
; tray icon raise to hold the tower bells back. A muted application stays silent either way.
    Critical, on
    If (userMuteAllSounds=1 || BeepsVolume<1)
       Return

    If ((stopAdditionalStrikez=1 || stopStrikesNow=1) && forced!=1)
       Return

    If (useDirectSound=1)
    {
       dupes := (InStr(hSND, "\hours") || InStr(hSND, "\quarters")) ? 1 : 0
       DirectSoundSndPlay(hSND, "ext", dupes)
    } Else
    {
       MCI_SendString("seek " hSND " to 1 wait")
       Sleep, -1
       MCI_Play(hSND)
    }
}

DirectSoundSndPlay(SNDfile:=0, sndID:=0, dupes:=0) {
    Critical, on
    fSNDfile := (sndID="ext") ? SNDfile : A_ScriptDir "\sounds\" SNDfile ".wav"
    If !FileExist(fSNDfile)
    {
       fnOutputDebug(A_ThisFunc "(): wave file does not exist: " SNDfile " | " fSNDfile)
       Return 0
    }

    allowDupe := ((A_TickCount - lastAudioPlayed<250) || dupes=1) ? 1 : 0
    p := DirectSoundPlayer.PlayFile(fSNDfile, allowDupe)
    If (DirectSoundPlayer.FilesLoaded()>20)
       DirectSoundPlayer.DiscardFirstBuffers(15, 1)

    If p
       lastAudioPlayed := A_TickCount

    If (DirectSoundPlayer.FilesLoaded()>15)
       SetTimer, discardDirectSoundFiles, -2000

    ; fnOutputDebug(A_ThisFunc ": " hSND "|" SNDfile "|" p "|" DirectSoundPlayer.FilesLoaded())
    Return p ? 1 : 0
}

discardDirectSoundFiles() {
  If (A_TickCount - lastAudioPlayed>1500)
     DirectSoundPlayer.DiscardAllFiles(1)
}

readjustBibleTimer() {
  SetTimer, InvokeBibleQuoteNow, Off
  Sleep, 5
  SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%
}

wrapChimerTimer() {
  Critical, on
  Static lastInvoked := 1
  If (A_IsSuspended || PrefOpen=1)
     Return

  lolz := A_Hour "|" A_Min "|" A_Sec//10
  If (lastInvoked!=lolz)
  {
     lastInvoked := lolz
     ; nq := calcNextQuarter()
     theChimer()
  } 
  ; ToolTip, % lolz " YAAAAAY `n" lastInvoked "nq=" nq , , , 2
}

theChimer() {
  Critical, on
  Static lastChimed, todayTest, lastFullMoonZeitTest := -9000
       , lastCalcZeit := 1

  FormatTime, exactTime,, HH:mm
  FormatTime, CurrentTime,, hh:mm
  If (lastChimed=CurrentTime || A_IsSuspended || PrefOpen=1)
     mustEndNow := 1

  FormatTime, HoursIntervalTest,, H ; 0-23 format
  If (noTollingWhenLocked=1 && mustEndNow!=1)
     mustEndNow := wrapGetLockedState()

  If (noTollingWhenMhidden=1 && mustEndNow!=1)
     mustEndNow := wrapGetLockedState() ? 0 : checkMcursorState()

  If (noTollingBgrSounds>=2 && mustEndNow!=1)
  { 
     testBgrNoise := isSoundPlayingNow()
     If (testBgrNoise=1 && noTollingBgrSounds=3)
        mustEndNow := stopAdditionalStrikez := 1
  }

  startAlarmTimer()
  If (hourInDefinedInterval(HoursIntervalTest, silentHoursA, silentHoursB) && silentHours=2)
     soundBells := 1

  If (hourInDefinedInterval(HoursIntervalTest, silentHoursA, silentHoursB) && silentHours=3)
  || (soundBells!=1 && silentHours=2) || (mustEndNow=1)
  {
     If (mustEndNow!=1)
        stopAdditionalStrikez := 1
     ; SetTimer, theChimer, % calcNextQuarter()
     lastChimed := CurrentTime
     If (todayTest!=A_YDay && ScriptInitialized=1 && mustEndNow!=1)
     {
        Sleep, 5
        todayTest := A_YDay
        testCelebrations(1)
     }
     Return
  }

  If (todayTest!=A_YDay && ScriptInitialized=1 && mustEndNow!=1)
  {
     Sleep, 5
     todayTest := A_YDay
     testCelebrations()
  }

  If (markFullMoonHowls=1 && hasHowledDay!=A_YDay && mustEndNow!=1 && userMuteAllSounds!=1 && lastFullMoonZeitTest!=HoursIntervalTest && (A_TickCount - lastCalcZeit>28501)) 
  {
     lastFullMoonZeitTest := HoursIntervalTest
     pk := oldMoonPhaseCalculator()
     lastCalcZeit := A_TickCount
     If InStr(pk[1], "full moon")
     {
        hasHowledDay := A_YDay
        INIaction(1, "hasHowledDay", "SavedSettings")
        volumeAction := SetMyVolume()
        MCXI_Play(SNDmedia_howl)
     }
  }

  If (A_TickCount - LastBibleQuoteDisplay2<95000) && (showBibleQuotes=1)
     SetTimer, readjustBibleTimer, -265100, 900

  SoundGet, master_vol
  DoGuiFader := 1
  stopStrikesNow := stopAdditionalStrikez := 0
  strikingBellsNow := 1
  Random, delayRandNoon, 950, 5050
  NoonTollQuartersDelay := 0
  If (InStr(exactTime, "06:00") && tollNoon=1)
  {
     NoonTollQuartersDelay := 7500
     volumeAction := SetMyVolume()
     showTimeNow()
     MCXI_Play(SNDmedia_morning)
  } Else If (InStr(exactTime, "18:00") && tollNoon=1)
  {
     NoonTollQuartersDelay := 18500
     volumeAction := SetMyVolume()
     showTimeNow()
     If (BeepsVolume>0)
        MCXI_Play(SNDmedia_evening)

     If (StrLen(isHolidayToday)>2 && SemantronHoliday=0 && TypeHolidayOccured>1)
        tollGivenNoon(0, 51000 + delayRandNoon + NoonTollQuartersDelay)
  } Else If (InStr(exactTime, "00:00") && tollNoon=1)
  {
     NoonTollQuartersDelay := 6500
     volumeAction := SetMyVolume()
     showTimeNow()
     If (BeepsVolume>0)
        MCXI_Play(SNDmedia_midnight)
  }

  quartersTotalTime := 0
  hoursTotalTime := 0
  If (InStr(CurrentTime, ":15") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     strikeQuarters(1, NoonTollQuartersDelay)
  } Else If (InStr(CurrentTime, ":30") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     strikeQuarters(2, NoonTollQuartersDelay)
  } Else If (InStr(CurrentTime, ":45") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     strikeQuarters(3, NoonTollQuartersDelay)
  } Else If InStr(CurrentTime, ":00")
  {
     FormatTime, countHours2beat,, h   ; 0-12 format
     If (tollQuarters=1 && tollQuartersException=0)
     {
        volumeAction := SetMyVolume()
        showTimeNow()
        strikeQuarters(4, NoonTollQuartersDelay)
     }

     Random, delayRand, 900, 1600
     If (countHours2beat="00") || (countHours2beat=0)
        countHours2beat := 12

     If (tollHoursAmount=1 && tollHours=1)
     {
        volumeAction := SetMyVolume()
        showTimeNow()
        strikeHours(countHours2beat, delayRand//3 + quartersTotalTime)
     } Else If (tollHours=1)
     {
        volumeAction := SetMyVolume()
        showTimeNow()
        strikeHours(1, delayRand//3 + quartersTotalTime)
     }

     If (InStr(exactTime, "12:0") && tollNoon=1)
     {
        Random, delayRand2, 2000, 8500
        volumeAction := SetMyVolume()
        If (tollHours=0)
           showTimeNow()

        If (stopStrikesNow=0 && BeepsVolume>0)
        {
           tollGivenNoon(0, delayRand2 + hoursTotalTime)
           If InStr(isHolidayToday, "easter")  ; on Easter
           {
              Random, newDelay, 1500, 6000
              tollGivenNoon(0, delayRand2 + newDelay + hoursTotalTime)
              Random, newDelay, 3500, 4000
              tollGivenNoon(0, delayRand2 + newDelay + hoursTotalTime)
              Random, newDelay, 2500, 5000
              tollGivenNoon(0, delayRand2 + newDelay + hoursTotalTime)
           } Else If (A_WDay=1 || StrLen(isHolidayToday)>2)  ; on Sundays or holidays
           {
              Random, newDelay, 49000, 99000
              tollGivenNoon(0, delayRand2 + newDelay + hoursTotalTime)
           }
        }
     }
  }

  If (stopStrikesNow=0 && SemantronHoliday=1 && StrLen(isHolidayToday)>2 && InStr(exactTime, ":45"))
  {
     If InStr(exactTime, "09:45")
        playSemantron(1, quartersTotalTime)
     Else If InStr(exactTime, "17:45")
        playSemantron(2, quartersTotalTime)
     Else If InStr(exactTime, "22:45")
        playSemantron(3, quartersTotalTime)
     Else If (InStr(exactTime, "11:45") && (A_WDay=1 || A_WDay=7))
     {
        Random, newDelay, 55100, 65100
        playSemantron(4, quartersTotalTime)
        playSemantron(1, quartersTotalTime + newDelay)
     }
  } Else If (StrLen(isHolidayToday)>2 && SemantronHoliday=0 && TypeHolidayOccured=1) && (tollNoon=1 || tollQuarters=1)
  {
     Random, newDelay, 39000, 89000
     If (InStr(exactTime, "09:45") || InStr(exactTime, "17:45"))
        tollGivenNoon(0, newDelay)
  }

  strikingBellsNow := 0
  lastChimed := CurrentTime
  ; SetTimer, theChimer, % calcNextQuarter()
}

showTimeNow() {
  Static lastu := 0
  If ((displayClock=0) || (A_TickCount - scriptStartZeit<1500))
     Return

  stru := generateDateTimeTxt(1, 1)
  pp := (showMoonPhaseOSD=1 || OverrideOSDcolorsAstro=1 || showOSDprogressBar>1) ? 1 : 0
  kk := (InStr(stru, ":00") && constantOSDvisible=1 && pp=1 && OSDGuiaVisible=1) ? 1 : 0
  If (OSDGuiaVisible!=1 || kk=1 && lastu=1)
  {
     If (kk=1)
     {
        DoGuiFader := 0
        stru := generateDateTimeTxt(0, 1) A_Space
     }

     lastu := !lastu
     CreateOSDGUI(stru)
     SetTimer, DestroyOSDguia, % - (DisplayTime + 50)
  } Else
  {
     ; GuiControl, osdGuia: +Center, osdGuiaTXT
     ; GuiControl, osdGuia:, osdGuiaTXT, % stru
     SetTimer, DestroyOSDguia, % - (DisplayTime + 50)
  }
}

calcNextQuarter(tt:=15) {
  result := ((tt - Mod(A_Min, tt)) * 60 - A_Sec) * 1000 - A_MSec + 50
  ; formula provided by Bon [AHK forums]
  Return result
}

bibleQuotesLangCode(langIdx) {
; The file name tag of the Bible the settings list names at the given position:
; bible-quotes-<tag>.txt in the resources folder.
   Static codes := {1:"eng", 2:"fra", 3:"esp", 4:"lat", 5:"ger", 6:"grk", 7:"rus"}
   Return codes.HasKey(langIdx) ? codes[langIdx] : ""
}

countBibleVerses(langIdx) {
; How many verses - lines - the Bible file of the given language holds, or 0 where the
; file cannot be read. The Bibles differ by thousands of verses, so the start point of the
; ordered display can only be allowed to reach as far as the chosen one goes. Counted once
; per language and kept.
   Static counts := {}
   lang := bibleQuotesLangCode(langIdx)
   If !lang
      Return 0

   If counts.HasKey(lang)
      Return counts[lang]

   FileRead, cnt, %A_ScriptDir%\resources\bible-quotes-%lang%.txt
   If (ErrorLevel || !cnt)
      Return 0

   counts[lang] := ST_Count(cnt, "`n") + 1
   Return counts[lang]
}

ST_Count(string, searchFor="`n") {
   StringReplace, string, string, %searchFor%, %searchFor%, UseErrorLevel
   Return ErrorLevel
}

ST_ReadLine(string, line, delim="`n", exclude="`r") {
; String Things - Common String & Array Functions, 2014
; by tidbit https://autohotkey.com/board/topic/90972-string-things-common-text-and-array-functions/

   StringReplace, string, string, %delim%, %delim%, UseErrorLevel
   countE := ErrorLevel+1

   if (abs(line)>countE && (line!="L" || line!="R"))
      Return 0
   if (Line="R")
      Random, Rand, 1, %countE%
   if (line<=0)
      line := countE+line

   loop, parse, String, %delim%, %exclude%
   {
      out := (Line="R" && A_Index==Rand)   ? A_LoopField
          :  (Line="L" && A_Index==countE) ? A_LoopField
          :  (A_Index==Line)               ? A_LoopField
          :  -1
      If (out!=-1) ; Something was found so stop searching.
         Break
   }
   Return out
}

ST_wordWrap(string, column=56, indentChar="") {
; String Things - Common String & Array Functions, 2014
; by tidbit https://autohotkey.com/board/topic/90972-string-things-common-text-and-array-functions/
; fixed by Marius Șucan, such that it does not give Continuable Exception Error on some systems

    indentLength := StrLen(indentChar)
    Loop, Parse, string, `n
    {
        If (StrLen(A_LoopField) > column)
        {
            pose := 1
            Loop, Parse, A_LoopField, %A_Space%
            {
                loopLength := StrLen(A_LoopField)
                If (pose + loopLength <= column)
                {
                   out .= (A_Index = 1 ? "" : " ") A_LoopField
                   pose += loopLength + 1
                } Else
                {
                   pose := loopLength + 1 + indentLength
                   out .= "`n" indentChar A_LoopField
                }
            }
            out .= "`n"
        } Else
            out .= A_LoopField "`n"
    }
    result := SubStr(out, 1, -1)
    Return result
}

GuiFader(guiName,toggle,alphaLevel) {
   Static lastEvent, lastGuiName

   If !WinExist(guiName)
      Return

   If (A_TickCount-lastFaded<1000) && (lastEvent=toggle && lastGuiName=guiName) || (DoGuiFader=0)
   {
      If (toggle="show")
         WinSet, Transparent, %alphaLevel%, %guiName%
      Return
   }

   fadeInterval := (alphaLevel<125) ? 30 : 6
   fadeStep := (alphaLevel<125) ? 8 : 18
   If (toggle="show")
   {
      Loop
      {
         interimAlphaLevel := A_Index * fadeStep
         If (interimAlphaLevel>alphaLevel)
         {
            interimAlphaLevel := alphaLevel
            toBreak := 1
         }
         WinSet, Transparent, %interimAlphaLevel%, %guiName%
         Sleep, %fadeInterval%
         If (toBreak=1)
            Break
      }
   } Else If (toggle="hide")
   {
      Loop
      {
         interimAlphaLevel := alphaLevel - A_Index * fadeStep
         If (interimAlphaLevel<25)
         {
            interimAlphaLevel := 10
            toBreak := 1
         }
         WinSet, Transparent, %interimAlphaLevel%, %guiName%
         Sleep, %fadeInterval%
         If (toBreak=1)
            Break
      }
   }

   lastFaded := A_TickCount
   lastGuiName := guiName
   lastEvent := toggle
}

decideJiji(elevu, m:=0) {
   If (isInRange(elevu, -6.1, -0.611))
      j := 0.45
   Else If (isInRange(elevu, -12, -6.1))
      j := 0.2
   Else If (isInRange(elevu, 0.15, -0.61))
      j := 0.7
   Else If (isInRange(elevu, -0.61, 5.9))
      j := 0.8
   Else If (elevu>5.9)
      j := 1 ; daylight
   Else
      j := 0 ; night
 
   If (m=1 && j<0.5)
      j := 0 
   Else If (m=1 && j=0.7)
      j := 0.25
   Else If (m=1 && j=0.8)
      j := (elevu>3.9) ? 0.75 : 0.5
   Return j
}

decideOSDcolorBGR() {
  If (OSDastralMode!=3)
  {
     If !InStr(lastUsedGeoLocation, "|")
        Return OSDbgrColor
 
     w := StrSplit(lastUsedGeoLocation, "|")
     If (w.Count()<5)
        Return OSDbgrColor
  }

  timeus := A_NowUTC
  If (OSDastralMode=1)
     getSunAzimuthElevation(timeus, w[2], w[3], 0, azii, elevu)
  Else If (OSDastralMode=2)
     getMoonElevation(timeus, w[2], w[3], 0, azii, elevu)
  Else If (OSDastralMode=3 && IsObject(w))
     moonPhase := MoonPhaseCalculator(timeus, 0, w[2], w[3])
  Else If (OSDastralMode=3)
     moonPhase := oldMoonPhaseCalculator(timeus)

  If (OSDastralMode=1)
  {
     j := decideJiji(elevu, 0)
  } Else If (OSDastralMode=2)
  {
     j := decideJiji(elevu, 1)
  } Else If (OSDastralMode=3)
  {
     j := Round(moonPhase[4], 1)
  } Else If (OSDastralMode=4)
  {
     eleva := -90
     getSunAzimuthElevation(timeus, w[2], w[3], 0, azii, elevu)
     If (elevu<6)
        moonPhase := MoonPhaseCalculator(timeus, 0, w[2], w[3])

     mf := moonPhase[4] ? clampInRange(moonPhase[4] + 0.2, 0, 1) : 0
     ju := decideJiji(elevu, 0)
     ja := decideJiji(moonPhase[7], 1) * mf
     j := ju
  }
  ; ToolTip, % j "==" elevu "=" w[2] "=" w[3] "=" w[1] , , , 2
  If (j=0)
     j := "0xFF" OSDbgrColor
  Else If (j=1)
     j := "0xFF" OSDastroALTcolor
  Else
     j := MixARGB("0xFF" OSDbgrColor, "0xFF" OSDastroALTcolor, j)

  If (ju<1 && isNumber(ju) && ja>0)
     j := MixARGB(j, "0xFF" OSDastroALTOcolor, ja)

  Return SubStr(j, 5)
}

MixRGB(clrA, clrB, t) {
   t := 1 - t
   Ra := Format("{1:d}", "0x" SubStr(clrA, 1, 2))
   Ga := Format("{1:d}", "0x" SubStr(clrA, 3, 2))
   Ba := Format("{1:d}", "0x" SubStr(clrA, 5, 2))

   Rb := Format("{1:d}", "0x" SubStr(clrB, 1, 2))
   Gb := Format("{1:d}", "0x" SubStr(clrB, 3, 2))
   Bb := Format("{1:d}", "0x" SubStr(clrB, 5, 2))
  
   r := clampInRange(Round(Ra * (1-t) + Rb * t), 0, 255)
   g := clampInRange(Round(Ga * (1-t) + Gb * t), 0, 255)
   b := clampInRange(Round(Ba * (1-t) + Bb * t), 0, 255)
   Return Format("{1:02x}", R) Format("{1:02x}", G) Format("{1:02x}", B)
}

OSDmoonColorBitmap(thisBgrColor, datu:=0) {
   boxSize := imgW := imgH := 600
   cX := imgW*0.48
   cY := -imgH*0.45

   newBitmap := Gdip_CreateBitmap(imgW, imgH, "0xE200B")
   If (StrLen(newBitmap)<3)
      Return

   G3 := Gdip_GraphicsFromImage(newBitmap)
   r2 := Gdip_GraphicsClear(G3, "0xFF" thisBgrColor)
   brightColor := MixRGB(thisBgrColor, "EEeeEE", 0.75)
   darkColor := MixRGB(thisBgrColor, "222222", 0.25)
   If (swapColorAnalogClock=1)
      swapVars(brightColor, darkColor)

   elevation := coreMoonPhaseDraw(brightColor, darkColor, cX, cY, boxSize*4.95, lastUsedGeoLocation, G3, datu)
   If (elevation<0)
   {
      br := Gdip_BrushCreateSolid("0x77" thisBgrColor)
      Gdip_FillRectangle(G3, br, 0, 0, imgW, imgH)
      Gdip_DeleteBrush(br)
   }

   Gdip_DeleteGraphics(G3)
   Return newBitmap
}

centerWindowScreen(hwnd, g, mX, mY, ByRef fx, ByRef fy) {
   ActiveMon := MWAGetMonitorMouseIsIn()
   If ActiveMon
   {
      SysGet, mCoord, MonitorWorkArea, %ActiveMon%
      semiFinal_x := semiFinal_y := mCoordLeft + 20
      Gui, %g%: Show, NoActivate Hide AutoSize x%semiFinal_x% y%semiFinal_y%
      Sleep, 25
      WinGetPos,,, mainWid, mainHeig, ahk_id %hwnd%
      fX := mCoordLeft + ((mCoordRight  - mCoordLeft) - mainWid)  / 2
      fY := mCoordTop  + ((mCoordBottom - mCoordTop)  - mainHeig) / 2
      Return 1
   } Else
   {
      fx := mX
      fy := mY
      Return 0
   }
}

CreateBibleGUI(msg2Display, centerMsg:=1, twoLinez:=0) {
    Critical, On
    FontSizeMin := FontSizeQuotes
    GuiFader("ChurchTowerBibleWin","hide", OSDalpha)
    Sleep, 2
    Gui, BibleGui: Destroy
    Sleep, 50
    Global BibleGuiTXT
    msg2Display := ST_wordWrap(msg2Display, maxBibleLength)
    pzx := FontSizeQuotes*2.5
    pzy := FontSizeQuotes*1.8
    Gui, BibleGui: -DPIScale -Caption +Owner +ToolWindow +HwndhBibleOSD
    Gui, BibleGui: Margin, % pzx, % pzy
    Gui, BibleGui: Color, %OSDbgrColor%
    If (FontChangedTimes>190)
       Gui, BibleGui: Font, c%OSDtextColor% s%FontSizeMin% Q4 Bold,
    Else
       Gui, BibleGui: Font, c%OSDtextColor% s%FontSizeMin% Q4 Bold, %FontName%

    Gui, BibleGui: Add, Text, vBibleGuiTXT +BackgroundTrans gForcedDestroyBibleGui, % msg2Display
    If twoLinez
    {
       ff := FontSizeMin//2 + 1
       Gui, BibleGui: Font, s%ff% Q4
       Gui, BibleGui: Add, Text, xp y+5 -wrap +BackgroundTrans gForcedDestroyBibleGui, % twoLinez
    }
    Gui, BibleGui: Font, s1 Q4
    pzy := pzy//3
    Gui, BibleGui: Add, Text, xp y+%pzy% -wrap +BackgroundTrans, .
    Gui, BibleGui: Show, NoActivate AutoSize Hide x%GuiX% y%GuiY%, ChurchTowerBibleWin
    WinSet, Transparent, 1, ChurchTowerBibleWin
    WinGetPos,,, mainWid, mainHeig, ahk_id %hBibleOSD%
    If (centerMsg=1)
    {
       If (makeScreenDark=1)
          ScreenBlocker(0, 1)

       centerWindowScreen(hBibleOSD, "BibleGui", GuiX, GuiY, fx, fy)
       If !twoLinez
          CreateShareButton()
    } Else
    {
       fx := GuiX
       fy := GuiY
    }

    If (!fx || !fy)
       fx := fy := 1

    Gui, BibleGui: Show, NoActivate x%fx% y%fy%, ChurchTowerBibleWin
    WinSet, Transparent, 1, ChurchTowerBibleWin
    WinSet, AlwaysOnTop, On, ChurchTowerBibleWin
    If (OSDroundCorners=1)
    {
       WinSet, Region, 0-0 R%roundCornerSize%-%roundCornerSize% w%mainWid% h%mainHeig%, ChurchTowerBibleWin
       Try FrameShadow(hBibleOSD)     
    }

    GuiFader("ChurchTowerBibleWin","show", OSDalpha)
}

CreateOSDGUI(msg2Display, centerMsg:=0, noAdds:=0) {
    Critical, On
    Static lastMsg
    If (msg2Display=0 && centerMsg="last")
       Return lastMsg

    lastOSDredraw := A_TickCount
    FontSizeMin := FontSize
    If (noAdds=1 && InStr(msg2Display, "`n"))
       FontSizeMin := Round(FontSize*0.7)

    GuiFader("ChurchTowerOSDwin","hide", OSDalpha)
    Sleep, 2
    Gui, osdGuia: Destroy
    Sleep, 50
    Global osdGuiaTXT
    If (noAdds=0)
       msg2Display := OSDprefix msg2Display OSDsuffix

    lastMsg := msg2Display
    thisBgrColor := (OverrideOSDcolorsAstro!=1) ? OSDbgrColor : decideOSDcolorBGR()
    Gui, osdGuia: -DPIScale -Caption +Owner +ToolWindow +HwndhWinOSD
    Gui, osdGuia: Margin, 0, 0
    Gui, osdGuia: Color, %thisBgrColor%
    ; Gui, Add, Text, x0 y0 w%gW% h%gH% Section -Border +0xE gPanelsLivePreviewResponder +hwndhCropCornersPic +TabStop, Preview area

    If (FontChangedTimes>190)
       Gui, osdGuia: Font, c%OSDtextColor% s%FontSizeMin% Q4 Bold,
    Else
       Gui, osdGuia: Font, c%OSDtextColor% s%FontSizeMin% Q4 Bold, %FontName%

    Gui, osdGuia: Font, s1
    Gui, osdGuia: Font, s%FontSizeMin% Q4
    heightProgressu := (showOSDprogressBar>1) ? Ceil(FontSizeMin*0.15 + 1) : 0
    If (!InStr(msg2Display, "`n") && showMoonPhaseOSD=1)
    {
       Global TempusLol
       moonPicBMP := OSDmoonColorBitmap(thisBgrColor)
       If moonPicBMP
       {
          moonPic := Gdip_CreateHBITMAPFromBitmap(moonPicBMP)
          Gdip_DisposeImage(moonPicBMP, 1)
       }

       If moonPic
       {
          Gui, osdGuia: Add, Text, x0 y0 vTempusLol, .
          GuiControl, osdGuia: Hide, TempusLol
          pzay := clampInRange(OSDmarginTop + OSDmarginBottom - heightProgressu, 0, 1223349)
          Gui, osdGuia: Add, Picture, x0 y%heightProgressu% w-1 hp+%pzay%, hBitmap:%moonPic%
       }
    }

    Gui, osdGuia: Add, Text, x%OSDmarginSides% y%OSDmarginTop% hwndhOSDtxt vosdGuiaTXT +BackgroundTrans, %msg2Display%
    Gui, osdGuia: Font, s1
    Gui, osdGuia: Add, Text, x+1 w%OSDmarginSides% y+0 h%OSDmarginBottom% BackgroundTrans, .

    Gui, osdGuia: Show, NoActivate AutoSize x%GuiX% y%GuiY%, ChurchTowerOSDwin
    WinSet, Transparent, 1, ChurchTowerOSDwin
    WinGetPos,,, mainWid, mainHeig, ahk_id %hWinOSD%

    If (InStr(msg2Display, ":") && !InStr(msg2Display, "`n") && showOSDprogressBar>1)
    {
       If (showOSDprogressBar=2)
       {
          percu := Round(getPercentOfToday() * 100)
       } Else If (showOSDprogressBar=3)
       {
          moonPhase := oldMoonPhaseCalculator()
          percu := Round(moonPhase[3] * 100)
       } Else If (showOSDprogressBar=4)
       {
          percu := Round((A_MDay/calendarDaysInMonth(A_Year, A_Mon)) * 100)   ; not every month has 31 days
       } Else If (showOSDprogressBar=5)
       {
          percu := Round(getPercentOfAstroSeason() * 100)
       } Else If (showOSDprogressBar=6)
       {
          percu := Round((A_YDay/366) * 100)
       }

       coloru := (percu=25 || percu=49 || percu=50 || percu=51 || percu=75) ? OSDtextColor : decideFadeColor(thisBgrColor)
       thisBgrColor := SubStr( MixARGB("0xFF" thisbgrColor, "0xFF001100", 0.2), 5)
       Gui, osdGuia: Add, Progress, x0 y0 w%mainWid% h%heightProgressu% c%coloru% background%thisBgrColor%, % percu "%"
    }

    If (centerMsg=1)
    {
       centerWindowScreen(hWinOSD, "osdGuia", GuiX, GuiY, fx, fy)
       Gui, osdGuia: Show, NoActivate AutoSize x%fx% y%fy%, ChurchTowerOSDwin
    } Else
    {
       ActiveMon := MWAGetMonitorMouseIsIn(GuiX, GuiY)
       If !ActiveMon
          ActiveMon := MWAGetMonitorMouseIsIn()
       SysGet, mCoord, MonitorWorkArea, %ActiveMon%
       Final_x := max(mCoordLeft, min(GuiX, mCoordRight - mainWid)) + 1
       Final_y := max(mCoordTop, min(GuiY, mCoordBottom - mainHeig)) + 1
       If !ActiveMon
       {
          Final_x := GuiX
          Final_y := GuiY
       }

       If (!Final_x || !Final_y)
          Final_x := Final_y := mCoordLeft ? mCoordLeft + 10 : 1

       Gui, osdGuia: Show, NoActivate AutoSize x%Final_x% y%Final_y%, ChurchTowerOSDwin
    }

    WinSet, Transparent, 1, ChurchTowerOSDwin
    WinSet, AlwaysOnTop, On, ChurchTowerOSDwin
    If (PrefOpen!=1)
       SetTimer, DestroyOSDguia, % -DisplayTime

    If (OSDroundCorners=1)
    {
       WinSet, Region, 0-0 R%roundCornerSize%-%roundCornerSize% w%mainWid% h%mainHeig%, ChurchTowerOSDwin
       Try FrameShadow(hWinOSD)     
    }

    OSDGuiaVisible := 1
    GuiFader("ChurchTowerOSDwin","show", OSDalpha)
    lastOSDredraw := A_TickCount
}

FrameShadow(HGui) {
; function from https://www.autohotkey.com/boards/viewtopic.php?f=6&t=29117
; by Just Me
   If (SafeModeExec!=1 && OSDroundCorners=1)
   {
      CS_DROPSHADOW := 0x00020000
      ClassStyle := GetGuiClassStyle()
      SetGuiClassStyle(HGUI, ClassStyle | CS_DROPSHADOW)
   } Else If (PrefOpen=1 && ShowPreview=1 && OSDroundCorners=0)
   {
      ClassStyle := GetGuiClassStyle()
      SetGuiClassStyle(HGUI, ClassStyle)
   }
}

GetGuiClassStyle() {
   Static ClassStyle
   If ClassStyle
      Return ClassStyle

   Gui, GetGuiClassStyleGUI: Add, Text
   Module := DllCall("GetModuleHandle", "Ptr", 0, "UPtr")
   VarSetCapacity(WNDCLASS, A_PtrSize * 10, 0)
   ClassStyle := DllCall("GetClassInfo", "Ptr", Module, "Str", "AutoHotkeyGUI", "Ptr", &WNDCLASS, "UInt")
                 ? NumGet(WNDCLASS, "Int")
                 : ""
   Gui, GetGuiClassStyleGUI: Destroy
   Return ClassStyle
}

SetGuiClassStyle(HGUI, Style) {
   result := DllCall("SetClassLong" . (A_PtrSize = 8 ? "Ptr" : ""), "Ptr", HGUI, "Int", -26, "Ptr", Style, "UInt")
   Return result
}

CreateShareButton() {
    FontSizeMin := Round(FontSizeQuotes/2)
    If (FontSizeMin<9)
       FontSizeMin := 9

    marginz := FontSizeMin*2
    If (marginz<FontSizeMin)
       marginz := FontSizeMin
    Gui, ShareBtnGui: Destroy
    Sleep, 25
    Gui, ShareBtnGui: -DPIScale -Caption +Owner +ToolWindow +hwndhShareBtn
    Gui, ShareBtnGui: Margin, % marginz*1.5 , % marginz
    Gui, ShareBtnGui: Color, c%OSDtextColor%
    Gui, ShareBtnGui: Font, %OSDbgrColor% s%FontSizeMin% Bold,
    Gui, ShareBtnGui: Add, Text, c%OSDbgrColor% gCopyLastQuote, Copy and share quote
    ActiveMon := MWAGetMonitorMouseIsIn()
    If ActiveMon
    {
       SysGet, mCoord, MonitorWorkArea, %ActiveMon%
       Final_x := mCoordLeft + FontSizeMin*2
       Final_y := mCoordTop + FontSizeMin*2
    } Else
    {
       Final_x := GuiX
       Final_y := GuiY
    }
    Gui, ShareBtnGui: Show, NoActivate AutoSize x%Final_x% y%Final_y%, BibleShareBtn
    WinSet, Transparent, 1, BibleShareBtn
    WinSet, AlwaysOnTop, On, BibleShareBtn
    If (OSDroundCorners=1)
    {
       WinGetPos,,, mainWid, mainHeig, ahk_id %hShareBtn%
       WinSet, Region, 0-0 R%roundCornerSize%-%roundCornerSize% w%mainWid% h%mainHeig%, BibleShareBtn
    }
    GuiFader("BibleShareBtn","show", OSDalpha)
}

CopyLastQuote() {
  Try Clipboard := LastBibleMsg
  ToolTip, Text sent to clipboard.
  Sleep, 100
  GuiFader("BibleShareBtn","hide", OSDalpha)
  Sleep, 100
  Gui, ShareBtnGui: Destroy
  SetTimer, removeTooltip, -950
}

ResetAnalogClickPosition() {
   ClockPosX := ClockPosY := 1
   saveAnalogClockPosition("no")
   If (constantAnalogClock=1)
      reInitializeAnalogClock()
}

JEE_ScreenToClient(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2) {
; function by jeeswg found on:
; https://autohotkey.com/boards/viewtopic.php?t=38472
  VarSetCapacity(POINT, 8, 0)
  NumPut(vPosX, &POINT, 0, "Int")
  NumPut(vPosY, &POINT, 4, "Int")
  DllCall("user32\ScreenToClient", "UPtr", hWnd, "UPtr", &POINT)
  vPosX2 := NumGet(&POINT, 0, "Int")
  vPosY2 := NumGet(&POINT, 4, "Int")
  POINT := ""
}

GetLogicalCursorPos(ByRef mX, ByRef mY) {
; The cursor position as this process is shown it, which is the space
; ScreenToClient(), Gui Show and SysGet Monitor all work in. Unlike
; GetPhysicalCursorPos() it reports no raw device pixels.
   VarSetCapacity(POINT, 8, 0)
   If !DllCall("user32\GetCursorPos", "Ptr", &POINT)
   {
      MouseGetPos, mX, mY
      Return (mX="" || mY="") ? 0 : 1
   }

   mX := NumGet(POINT, 0, "Int")
   mY := NumGet(POINT, 4, "Int")
   POINT := ""
   Return 1
}

getGraphMousePos(ctrlHwnd, ByRef fx, ByRef fy) {
; Converts the current mouse position into coordinates over the graph drawn
; inside ctrlHwnd, normalized to the 0-1 range. Returns 0 when the pointer is
; not over the graph, so that callers never compute with positions outside it.
;
; Two rectangles take part here and they are not the same one.
; Gdip_SetPbitmapCtrl() stretches the graph to the size WinGetPos() reports,
; the window rectangle, and the static control then blits that bitmap unscaled
; at the client origin. SS_SUNKEN (+0x1000) gives these controls a
; WS_EX_STATICEDGE border, so their client area is two pixels narrower and
; shorter than the window. Hit testing therefore belongs to the client
; rectangle, while the scale of the graph belongs to the window rectangle.
; Dividing by the client size, as this used to, stretched every reading by the
; ratio between the two.
;
; The cursor must be read in the same coordinate space ScreenToClient() answers
; in, which is what GetLogicalCursorPos() returns. GetPhysicalCursorPos()
; reports raw device pixels instead, and the two only agree while the window
; sits on a monitor running at the system DPI. 

   fx := fy := 0
   If (!ctrlHwnd || !DllCall("user32\IsWindow", "Ptr", ctrlHwnd))
      Return 0

   If !GetLogicalCursorPos(mx, my)
      Return 0

   JEE_ScreenToClient(ctrlHwnd, mx, my, nx, ny)
   GetWinClientSize(cw, ch, ctrlHwnd, 0)
   If (cw<1 || ch<1)
      Return 0

   If (nx<0 || ny<0 || nx>=cw || ny>=ch)
      Return 0

   GetWinClientSize(imgW, imgH, ctrlHwnd, 2)
   If (imgW<cw || imgH<ch)     ; unreadable window rectangle; the client area is the closest guess
      imgW := cw, imgH := ch

   fx := nx/imgW
   fy := ny/imgH
   Return 1
}

GetWindowBounds(hWnd) {
   ; function by GeekDude: https://gist.github.com/G33kDude/5b7ba418e685e52c3e6507e5c6972959
   ; W10 compatible function to find a window's visible boundaries
   ; modified by Marius Șucan to return an array
   size := VarSetCapacity(rect, 16, 0)
   er := DllCall("dwmapi\DwmGetWindowAttribute"
      , "UPtr", hWnd  ; HWND  hwnd
      , "UInt", 9     ; DWORD dwAttribute (DWMWA_EXTENDED_FRAME_BOUNDS)
      , "UPtr", &rect ; PVOID pvAttribute
      , "UInt", size  ; DWORD cbAttribute
      , "UInt")       ; HRESULT

   If er
      DllCall("GetWindowRect", "UPtr", hwnd, "UPtr", &rect, "UInt")

   r := []
   r.x1 := NumGet(rect, 0, "Int"), r.y1 := NumGet(rect, 4, "Int")
   r.x2 := NumGet(rect, 8, "Int"), r.y2 := NumGet(rect, 12, "Int")
   r.w := Abs(max(r.x1, r.x2) - min(r.x1, r.x2))
   r.h := Abs(max(r.y1, r.y2) - min(r.y1, r.y2))
   rect := ""
   ; ToolTip, % r.w " --- " r.h , , , 2
   Return r
}

GetWinClientSize(ByRef w, ByRef h, hwnd, mode) {
; by Lexikos http://www.autohotkey.com/forum/post-170475.html
; modified by Marius Șucan
; mode 0 = client area, mode 1 = visible window bounds (DWM aware), mode 2 = window rectangle.
    Static prevW, prevH, prevHwnd, prevMode := -1, lastInvoked := 1
    If (A_TickCount - lastInvoked<95) && (prevHwnd=hwnd) && (prevMode=mode)
    {
       W := prevW, H := prevH
       Return
    }

    prevHwnd := hwnd, prevMode := mode
    If (mode=1)
    {
       r := GetWindowBounds(hwnd)
       prevW := W := r.w
       prevH := H := r.h
    } Else If (mode=2)
    {
       VarSetCapacity(rc, 16, 0)
       DllCall("user32\GetWindowRect", "Ptr", hwnd, "Ptr", &rc)
       prevW := W := NumGet(rc, 8, "Int") - NumGet(rc, 0, "Int")
       prevH := H := NumGet(rc, 12, "Int") - NumGet(rc, 4, "Int")
       rc := ""
    } Else
    {
       ; the buffer address must be passed as a pointer; "uint" truncates it to
       ; 32 bits and corrupts the call in the 64 bits edition
       VarSetCapacity(rc, 16, 0)
       DllCall("user32\GetClientRect", "Ptr", hwnd, "Ptr", &rc)
       prevW := W := NumGet(rc, 8, "Int")
       prevH := H := NumGet(rc, 12, "Int")
       rc := ""
    }

    lastInvoked := A_TickCount
}

getListViewData(guiu, lvu, cols, userDelim:=" | ", minRows:=0, allowEmpty:=0) {
   Gui, %guiu%: Default
   Gui, %guiu%: ListView, %lvu%
   minRows := abs(minRows)
   aR := aC := 0
   textu := ""
   Loop
   {
       aC++
       If (aC>cols)
       {
          aR++
          aC := 1
       }

       LV_GetText(valu, aR, aC)
       delimu := (aC!=cols) ? userDelim : "`n"
       If (valu!="" && allowEmpty=0)
          textu .= valu delimu
       Else
          textu .= valu delimu
       Sleep, -1
       ; ToolTip, %valu% -- %aC% -- %aR%
       If (valu="" && A_Index>950 && !minRows) || (aR>minRows && minRows>1)
          Break
   }
   textu := Trim(textu, delimu)
   Return textu
}

btnCopySolarData() {
   Gui, SettingsGUIA: Default
   GuiControlGet, CurrentTabLV
   GuiControlGet, uiInfoGeoData
   GuiControlGet, UIastroInfoAnnum
   yearu := SubStr(uiUserFullDateUTC, 1, 4)
   lvTagLine .= uiInfoGeoData "`n" UIastroInfoAnnum "`nData for " yearu ".`n`n"
   If (AnyWindowOpen=9)
   {
      If (CurrentTabLV=1)
      {
         lvu := "LViewSunCombined"
         lvn := 8
      } Else If (CurrentTabLV=3)
      {
         lvu := "LViewMuna"
         lvn := 5
      }
   } Else If (CurrentTabLV=1)
   {
      lvu := "LViewSunCombined"
      lvn := 9
   } Else If (CurrentTabLV=2)
   {
      lvu := "LViewRises"
      lvn := 4
   } Else If (CurrentTabLV=3)
   {
      lvu := "LViewSets"
      lvn := 4
   } Else If (CurrentTabLV=4)
   {
      lvu := "LViewOthers"
      lvn := 8
   }

   If !lvu 
   {
      tabsu := (AnyWindowOpen=9) ? "Summary or Moon phases" : "Summary, Rise, Set or Durations"
      MsgBox, , % appName, % "No table is active to copy the data from. Please switch the window's tab to " tabsu "."
      Return
   }

   dayz := isLeapYear(yearu) ? 366 : 365
   textu := lvTagLine "`n"
   textu .= getListViewData("SettingsGUIA", lvu, lvn,, dayz)
   If StrLen(textu)>10
   {
      If (AnyWindowOpen=9 && CurrentTabLV=3)
         textu := Trim(StrReplace(textu, " |  |  |  | "), "`n") "`n"

      Try Clipboard := textu
      Catch wasError
          Sleep, 1

      If wasError
      {
         SoundBeep , 300, 100
         MsgBox, , % appName, Failed to copy the data to clipboard. Please try again.
      } Else SoundBeep 900, 100
   }
}

createMenuOSDprefs() {
    Try Menu, MenuOSDprefs, DeleteAll
    Menu, MenuOSDprefs, Add, &Constantly display the OSD, toggleOSDconstDisplay
    If (constantOSDvisible=0)
    {
       minu := (showTimeIdleAfter>60) ? Round(showTimeIdleAfter/60, 1) " hours" : showTimeIdleAfter " minutes"
       Menu, MenuOSDprefs, Add, &Show OSD when idle for %minu%, toggleOSDidleDisplay
       If (showTimeWhenIdle=1)
          Menu, MenuOSDprefs, Check, &Show OSD when idle for %minu%
    } Else
       Menu, MenuOSDprefs, Check, &Constantly display the OSD

    Menu, MenuOSDprefs, Add
    Menu, MenuOSDprefs, Add, &Moon phase on the OSD, toggleOSDmoonPhase
    If (showMoonPhaseOSD=1)
    {
       Menu, MenuOSDprefs, Check, &Moon phase on the OSD
       Menu, MenuOSDprefs, Add, &Howling wolves on full moon, toggleOSDwolvesHowling
       If (markFullMoonHowls=1)
          Menu, MenuOSDprefs, Check, &Howling wolves on full moon
    }

    Menu, MenuOSDprefs, Add, Over&ride OSD colors (astronomy), toggleOSDastralColors
    If (OverrideOSDcolorsAstro=1)
       Menu, MenuOSDprefs, Check, Over&ride OSD colors (astronomy)

    Menu, MenuOSDprefs, Add, Rounded OSD corners, toggleOSDroundCorners
    If (OSDroundCorners=1)
       Menu, MenuOSDprefs, Check, Rounded OSD corners

    Menu, MenuOSDprefs, Add
    Menu, MenuOSDprefs, Add, &24 hours format, toggleOSDtimeFormat
    If (displayTimeFormat=1)
       Menu, MenuOSDprefs, Check, &24 hours format
    Menu, MenuOSDprefs, Add, &Always display the date, toggleOSDallDate
    If (OSDalwaysDateShow=1)
       Menu, MenuOSDprefs, Check, &Always display the date

    Menu, MenuOSDprefs, Add, &Long date format, toggleOSDlongDate
    If (OSDlongDateFormat=1)
       Menu, MenuOSDprefs, Check, &Long date format
}

invokeOSDmenu() {
    Try Menu, ContextMenu, DeleteAll
    Try Menu, ClockOpacityMenu, DeleteAll
    Try Menu, ClockTimersMenu, DeleteAll

    Loop, Parse, % "1|2|3|4|5|10|15|30|60|90", |
        Menu, ClockTimersMenu, Add, % A_LoopField, MenuSetQuickTimer
    Menu, ClockTimersMenu, Add
    If (userTimerExpire && userMustDoTimer=1)
    {
       Menu, ClockTimersMenu, Add, Turn off timer, MenuSetQuickTimer
       Menu, ClockTimersMenu, Add, % "Expires at: " userTimerExpire, dummy
       Menu, ClockTimersMenu, Disable, % "Expires at: " userTimerExpire
       Menu, ClockTimersMenu, Add
    }
    Menu, ClockTimersMenu, Add, Custom interval, MenuSetQuickTimer

    Loop, 9
        Menu, ClockOpacityMenu, Add, % (A_Index + 1) * 10 "%", ChangeMenuOSDopacity
    pop := Round(OSDalpha/255 * 100) "%"
    Menu, ClockOpacityMenu, Add
    Menu, ClockOpacityMenu, Add, % " " pop " ", dummy
    Menu, ClockOpacityMenu, Disable, % " " pop " "
    Try Menu, ClockOpacityMenu, Check, % pop

    createMenuOSDprefs()
    Menu, ContextMenu, Add, &Opacity, :ClockOpacityMenu
    Menu, ContextMenu, Add, &Customize, :MenuOSDprefs
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Lock OSD position, toggleOSDDlockPosition
    If (constantOSDlockPosition=1)
       Menu, ContextMenu, Check, Lock OSD position
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, &Set timer, :ClockTimersMenu
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, &Mute all sounds, ToggleAllMuteSounds
    If (userMuteAllSounds=1)
       Menu, ContextMenu, Check, &Mute all sounds

    If FileExist(tickTockSound)
    {
       Menu, ContextMenu, Add, Tick/Toc&k sound, ToggleTickTock
       If (tickTockNoise=1)
          Menu, ContextMenu, Check, Tick/Toc&k sound
    }

    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Astronom&y / Today, PanelTodayInfos
    Menu, ContextMenu, Add, Celebrations / &holidays, PanelIncomingCelebrations
    Menu, ContextMenu, Add, Calen&dar, PanelCalendarWindow
    Menu, ContextMenu, Add, Set &alarm or timer, PanelSetAlarm
    Menu, ContextMenu, Add, Stop&watch, PanelStopWatch
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Analo&g clock display, toggleAnalogClock
    If (constantAnalogClock=1)
       Menu, ContextMenu, Check, Analo&g clock display
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Settings, PanelShowSettings
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Restart app, ReloadScript
    Menu, ContextMenu, Show
}

WM_MouseMove(wP, lP, msg, hwnd) {
  Global
  Static lastInvoked := 1, prevenThisu := 1
  MouseGetPos, xu, yu, OutputVarWin, OutputVarControl, 2
  ; ToolTip, % AnyWindowOpen "=" OutputVarWin "=" OutputVarControl "=" hSolarGraphPic , , , 2
  If (generatingEarthMapNow=0 && hSolarGraphPic && OutputVarControl=hSolarGraphPic && isInRange(AnyWindowOpen, 7, 9))
  {
     ; The readout is throttled, but the pointer usually comes to rest between
     ; two updates. Without the delayed pass below, that last position is simply
     ; dropped and the info line keeps describing a spot the mouse swept over.
     If (A_TickCount - lastInvoked>60)
     {
        lastInvoked := A_TickCount
        refreshGraphInfoLine()
     }
     SetTimer, refreshGraphInfoLine, -85
  }

  Local A
  SetFormat, Integer, H
  hwnd+=0, A := OutputVarWin, hwnd .= "", A .= ""
  SetFormat, Integer, D
  HideDelay := (PrefOpen=1) ? 600 : 2050
  If (A_TickCount - LastBibleQuoteDisplay<HideDelay+100) || (A_TickCount - lastOSDredraw<1000)
     Return

  If (constantAnalogClock=1 && A=hFaceClock && lockAnalogClockPosition=0)
  {
     If (wP&0x1)
     {
        PostMessage, 0xA1, 2,,, ahk_id %hFaceClock%
        SetTimer, trackMouseAnalogClockDragging, -25
     }
     DllCall("user32\SetCursor", "Ptr", hCursM)
  } Else If InStr(hWinOSD, hwnd)
  {
     If (PrefOpen=0 && constantOSDvisible!=1 & (A_TickCount - prevenThisu>350))
     {
        DestroyOSDguia(A_ThisFunc, 1)
        prevenThisu := A_TickCount
     }

     rClick := ((wP&0x2) || (wP&0x10)) ? 1 : 0
     If (constantOSDvisible=1 && PrefOpen=0 && constantOSDlockPosition=1 && rClick=0)
        Return

     DllCall("user32\SetCursor", "Ptr", hCursM)
     If !(wP&0x13)    ; no LMR mouse button is down, we hover
     {
        If A not in %hWinOSD%
           hAWin := A
     } Else If (wP&0x1) ; L mouse button is down, we're dragging
     {
        SetTimer, DestroyOSDguia, Off
        PostMessage, 0xA1, 2,,, ahk_id %hWinOSD%
        DllCall("user32\SetCursor", "Ptr", hCursM)
        SetTimer, trackMouseDragging, -50
        Sleep, 2
     } Else If (rClick=1)
     {
        If (constantOSDvisible=1 && PrefOpen=0)
           invokeOSDmenu()
        Else
           DestroyOSDguia(A_ThisFunc)
     }
  } Else If (hwnd=hSolarGraphPic && isInRange(AnyWindowOpen, 6, 9))
  {
     DllCall("user32\SetCursor", "Ptr", hCursH)
  } Else If ColorPickerHandles
  {
     If InStr(ColorPickerHandles, hwnd)
        DllCall("user32\SetCursor", "Ptr", hCursH)
  } ; Else If (InStr(hwnd, hBibleOSD) && hBibleOSD && bibleQuoteVisible=1 && (A_TickCount - LastBibleQuoteDisplay>HideDelay))
    ;  DestroyOSDguia(A_ThisFunc, 1)
}

refreshGraphInfoLine() {
; Recomputes the GraphInfoLine readout of whichever year graph or earth map is
; on screen. Reached both straight from WM_MouseMove() and from its trailing
; timer, so it verifies the whole context again instead of trusting the caller.
   If (generatingEarthMapNow!=0 || !isInRange(AnyWindowOpen, 7, 9))
      Return

   If !getGraphMousePos(hSolarGraphPic, fx, fy)
      Return

   If (AnyWindowOpen=7)
      graphInfoLineSunYear(fx, fy)
   Else If (AnyWindowOpen=9)
      graphInfoLineMoonYear(fx, fy)
   Else If (AnyWindowOpen=8)
      graphInfoLineEarthMap(fx, fy)
}

graphRowForDay(dayNo, rowsCount) {
; Maps a day of the year to a row of the default ListView. The graphs plot one
; column per day in calendar order, but the tables sort themselves when a column
; header is clicked, after which the row number is no longer the day. Column 1
; always holds the day of the year, so check it first and only search when the
; two have drifted apart.
   If (rowsCount<1)
      Return 0

   dayNo := clampInRange(Round(dayNo), 1, rowsCount)
   LV_GetText(v, dayNo, 1)
   If (v=dayNo)
      Return dayNo

   Loop, % rowsCount
   {
      LV_GetText(v, A_Index, 1)
      If (v=dayNo)
         Return A_Index
   }
   Return 0
}

graphDayForPos(fx, dayz) {
; Turns a horizontal position over the graph into a day of the year. Each day
; owns one slice of the width, so the slice has to be floored, not rounded, and
; the count of days must come from the plotted year: rounding against a fixed
; 365 shifted every reading by half a day and hid the 29th of February.
   Return clampInRange(Floor(fx*dayz) + 1, 1, dayz)
}

graphHourReadable(fy) {
; The vertical axis of the rise and set graphs spans a full day, 00:00 at the
; top down to 23:59 at the bottom.
   hh := clampInRange(Round(fy*24, 1), 0, 24)
   Return (hh<10) ? "0" hh : hh
}

graphInfoLineSunYear(fx, fy) {
   Gui, SettingsGUIA: ListView, LViewSunCombined
   dayz := LV_GetCount()
   If (dayz<1)
      Return

   dayNo := graphDayForPos(fx, dayz)
   zp := graphRowForDay(dayNo, dayz)
   LV_GetText(datu, zp, 2)
   If (!datu || datu="date")
      Return

   LV_GetText(dawn, zp, 3)
   LV_GetText(riseu, zp, 4)
   LV_GetText(noonu, zp, 5)
   LV_GetText(elevu, zp, 6)
   LV_GetText(setu, zp, 7)
   LV_GetText(dusk, zp, 8)
   LV_GetText(duru, zp, 9)
   Gui, SettingsGUIA: ListView, LViewOthers
   zq := graphRowForDay(dayNo, LV_GetCount())
   LV_GetText(bumpu, zq, 4)
   LV_GetText(twdur, zq, 5)
   dawn := (dawn && dawn!="*") ? dawn : "--:--"
   dusk := (dusk && dusk!="*") ? dusk : "--:--"
   setu := setu ? setu : "--:--"
   riseu := riseu ? riseu : "--:--"
   datu := SubStr(uiUserFullDateUTC, 1, 4) . StrReplace(datu, "/") "020304"
   FormatTime, datu, % datu, dd/MM/yyyy
   hh := (SolarYearGraphMode!=1) ? "" : " @ " graphHourReadable(fy) " h"
   t := datu hh ". Sunlight length: " duru " (" bumpu  "). Twilight length: " twdur "."
   t .= "`nDawn: " dawn ". Sunrise: " riseu ". Noon: " noonu " (" elevu "). Sunset: " setu ". Dusk: " dusk "."
   GuiControl, SettingsGUIA:, GraphInfoLine, % t
}

graphInfoLineMoonYear(fx, fy) {
   Gui, SettingsGUIA: ListView, LViewSunCombined
   dayz := LV_GetCount()
   If (dayz<1)
      Return

   zp := graphRowForDay(graphDayForPos(fx, dayz), dayz)
   LV_GetText(datu, zp, 2)
   If (!datu || datu="date")
      Return

   LV_GetText(riseu, zp, 3)
   LV_GetText(noonu, zp, 4)
   LV_GetText(elevu, zp, 5)
   LV_GetText(setu, zp, 6)
   LV_GetText(duru, zp, 7)
   LV_GetText(bumpu, zp, 8)   ; this panel has no LViewOthers; its daily difference is column 8 here
   setu := setu ? setu : "--:--"
   riseu := riseu ? riseu : "--:--"
   datu := SubStr(uiUserFullDateUTC, 1, 4) . StrReplace(datu, "/") "020304"
   FormatTime, datu, % datu, dd/MM/yyyy
   hh := (SolarYearGraphMode!=1) ? "" : " @ " graphHourReadable(fy) " h"
   t := datu hh ". Moonlight duration: " duru " (" bumpu  ")."
   t .= "`nMoon rise: " riseu ". Culminant: " noonu " (" elevu "). Moon set: " setu "."
   GuiControl, SettingsGUIA:, GraphInfoLine, % t
}

graphInfoLineEarthMap(fx, fy) {
   py := 1 - fy
   gmtu := Round(24 * fx - 12)
   zx := Round(fx*360 - 180, 3)
   zy := Round(py*180 - 90, 3)
   If (showEarthSunMapModus=3)
      getMoonElevation(uiUserFullDateUTC, zy, zx, 0, azii, elevu)
   Else
      getSunAzimuthElevation(uiUserFullDateUTC, zy, zx, 0, azii, elevu)

   astralObj := (showEarthSunMapModus=1) ? "Sun" : "Moon"
   t := "Lat / long: " zy " / " zx ". GMT estimated offset: " gmtu " h. " astralObj " elev.: " Round(elevu) "°."
   GuiControl, SettingsGUIA:, GraphInfoLine, % t
}

trackMouseAnalogClockDragging() {
     defAnalogClockPosChanged := 1
     WinGetPos, ClockPosX, ClockPosY,,, ahk_id %hFaceClock%
     ; SetTimer, trackMouseDragging, -150
     SetTimer, saveAnalogClockPosition, -150
}

trackMouseDragging() {
  Global
  If (PrefOpen!=1 && constantOSDvisible=0)
     Return

  WinGetPos, NewX, NewY,,, ahk_id %hWinOSD%
  GuiX := !NewX ? "2" : NewX
  GuiY := !NewY ? "2" : NewY
  If (PrefOpen=1)
     lastOSDredraw := 1

  If hAWin
  {
     If hAWin not in %hWinOSD%
        WinActivate, ahk_id %hAWin%
  }

  SetTimer, saveGuiPositions, -150
  If (GetKeyState("LButton", "P") && PrefOpen=0)
     SetTimer, trackMouseDragging, -150
}

saveGuiPositions() {
; function called after dragging the OSD to a new position

  If (PrefOpen!=1)
  {
     ; Sleep, 100
     ; SetTimer, DestroyOSDguia, -1500
     INIaction(1, "GuiX", "OSDprefs")
     INIaction(1, "GuiY", "OSDprefs")
  } Else ; If (PrefOpen=1)
  {
     GuiControl, SettingsGUIA:, GuiX, %GuiX%
     GuiControl, SettingsGUIA:, GuiY, %GuiY%
  }
}

saveAnalogClockPosition(dummy:=0) {
; function called after dragging the OSD to a new position
   defAnalogClockPosChanged := 1
   If (dummy!="no")
      WinGetPos, ClockPosX, ClockPosY, , , ahk_id %hFaceClock%

   ClockGuiY := ClockPosY, ClockGuiX := ClockPosX
   INIaction(1, "ClockGuiX", "OSDprefs")
   INIaction(1, "ClockGuiY", "OSDprefs")
   Sleep, 10
   If GetKeyState("LButton", "P")
      SetTimer, saveAnalogClockPosition, -150
}

GetWindowRectum(hwnd) {
   size := VarSetCapacity(rect, 16, 0)
   DllCall("GetWindowRect", "UPtr", hwnd, "UPtr", &rect, "UInt")
   r := []
   r.x1 := NumGet(rect, 0, "Int"), r.y1 := NumGet(rect, 4, "Int")
   r.x2 := NumGet(rect, 8, "Int"), r.y2 := NumGet(rect, 12, "Int")
   r.w := Abs(max(r.x1, r.x2) - min(r.x1, r.x2))
   r.h := Abs(max(r.y1, r.y2) - min(r.y1, r.y2))
   Return r
}

SetStartUp() {
  If (A_IsSuspended || PrefOpen=1)
  {
     SoundBeep, 300, 900
     WinActivate, ahk_id %hSetWinGui%
     Return
  }

  If (storeSettingsREG=1)
  {
     StoreStartupToggle()
     Return
  }

  regEntry := """" A_ScriptFullPath """"
  StringReplace, regEntry, regEntry, .ahk", .exe"
  RegRead, currentReg, %StartRegPath%, %appName%
  If (ErrorLevel=1 || currentReg!=regEntry)
  {
     StringReplace, TestThisFile, ThisFile, .ahk, .exe
     If !FileExist(TestThisFile)
     {
        MsgBox, This option works only in the compiled edition of this script.
        Return
     }
     RegWrite, REG_SZ, %StartRegPath%, %appName%, %regEntry%
     Menu, moreOpts, Check, Start at boot
     CreateOSDGUI("Enabled Start at Boot", 0, 1)
  } Else
  {
     RegDelete, %StartRegPath%, %appName%
     Menu, moreOpts, Uncheck, Start at boot
     CreateOSDGUI("Disabled Start at Boot", 0, 1)
  }
}

;================================================================
; Start at boot for the Windows Store edition
;
; Inside an app package the Run registry key is a dead letter: the write
; lands in the package's own virtualized hive and Windows never reads it at
; logon. What Windows does read is the windows.startupTask extension of the
; package manifest, the entry the user sees on the Start-up apps page of the
; Task Manager and of the Windows Settings. Windows.ApplicationModel.StartupTask
; is the programmatic door to that entry, open to packaged desktop apps since
; Windows 10 version 1607, and for them RequestEnableAsync raises no consent
; dialog. Windows keeps the user in charge though: an entry switched off in
; the Task Manager reports DisabledByUser and the API may not overrule it,
; so all the application can do then is walk the user to the Settings page.
;
; The calls go straight against the ABI vtables, with the helpers that
; Lib\windows-geolocation.ahk already has for it: WinGeoRuntimeReady,
; WinGeoInitApartment, WinGeoSlot, WinGeoRelease and WinGeoQueryInterface.
; The slot numbers are the declaration order in the SDK's
; windows.applicationmodel.idl, fixed for good once published, and the first
; six slots of every interface belong to IInspectable.
;================================================================

StoreStartupStatics(ByRef stHr) {
; The activation factory of Windows.ApplicationModel.StartupTask, as its
; IStartupTaskStatics, to be released by the caller, or 0 with the HRESULT
; in stHr. A -1 there says this Windows has no runtime to ask at all.

   Static IID_IStartupTaskStatics := "{EE5B60BD-A148-41A7-B26E-E8B88A1E62F8}"
        , stClass := "Windows.ApplicationModel.StartupTask"

   stHr := -1
   If (!WinGeoRuntimeReady() || !WinGeoInitApartment())
      Return 0

   VarSetCapacity(stGuid, 16, 0)
   DllCall("ole32\CLSIDFromString", "WStr", IID_IStartupTaskStatics, "Ptr", &stGuid)
   stString := 0
   stHr := DllCall("combase.dll\WindowsCreateString", "WStr", stClass, "UInt", StrLen(stClass), "Ptr*", stString, "Int")
   If stHr
      Return 0

   stStatics := 0
   stHr := DllCall("combase.dll\RoGetActivationFactory", "Ptr", stString, "Ptr", &stGuid, "Ptr*", stStatics, "Int")
   DllCall("combase.dll\WindowsDeleteString", "Ptr", stString)
   Return (stHr || !stStatics) ? 0 : stStatics
}

StoreStartupTask(ByRef stTask, ByRef stFault, stTimeout) {
; The startup task this app package declares, as an IStartupTask the caller
; must release, giving back 1, or 0 with a sentence in stFault fit to put in
; front of the user. The task is asked for by the name the package manifest
; gives it, StoreStartupTaskId, and should Windows not know that name - a
; package built under another id, say - by listing the package's tasks and
; taking the first.

   Static SLOT_GETFORCURRENTPACKAGE := 6, SLOT_GETASYNC := 7   ; IStartupTaskStatics
        , SLOT_GETAT := 6, SLOT_SIZE := 7                     ; IVectorView

   stTask := 0, stFault := ""
   stStatics := StoreStartupStatics(stHr)
   If !stStatics
   {
      stFault := StoreStartupFault(stHr)
      Return 0
   }

   stAsync := 0, stString := 0, stStatus := 0
   If (StoreStartupTaskId!="" && !DllCall("combase.dll\WindowsCreateString", "WStr", StoreStartupTaskId, "UInt", StrLen(StoreStartupTaskId), "Ptr*", stString, "Int"))
   {
      stHr := DllCall(WinGeoSlot(stStatics, SLOT_GETASYNC), "Ptr", stStatics, "Ptr", stString, "Ptr*", stAsync, "Int")
      DllCall("combase.dll\WindowsDeleteString", "Ptr", stString)
      If (!stHr && stAsync)
         stStatus := StoreStartupAwaitObject(stAsync, stTimeout, stTask, stHr)
   }

   If (stStatus=1)
   {
      WinGeoRelease(stStatics)
      Return 1
   } Else If (stStatus=-1)
   {
      WinGeoRelease(stStatics)
      stFault := "Windows did not find the startup task of this app package within " Round(stTimeout/1000) " seconds."
      Return 0
   }

   stAsync := 0
   stHr := DllCall(WinGeoSlot(stStatics, SLOT_GETFORCURRENTPACKAGE), "Ptr", stStatics, "Ptr*", stAsync, "Int")
   WinGeoRelease(stStatics)
   If (stHr || !stAsync)
   {
      stFault := StoreStartupFault(stHr)
      Return 0
   }

   stList := 0
   stStatus := StoreStartupAwaitObject(stAsync, stTimeout, stList, stHr)
   If (stStatus=-1)
   {
      stFault := "Windows did not list the startup tasks of this app package within " Round(stTimeout/1000) " seconds."
      Return 0
   } Else If (stStatus!=1)
   {
      stFault := StoreStartupFault(stHr)
      Return 0
   }

   stCount := 0
   DllCall(WinGeoSlot(stList, SLOT_SIZE), "Ptr", stList, "UInt*", stCount, "Int")
   stHr := stCount ? DllCall(WinGeoSlot(stList, SLOT_GETAT), "Ptr", stList, "UInt", 0, "Ptr*", stTask, "Int") : 0
   WinGeoRelease(stList)
   If !stCount
   {
      stFault := "This app package declares no startup task, so Windows has no entry to switch on or off."
      Return 0
   } Else If (stHr || !stTask)
   {
      stTask := 0
      stFault := StoreStartupFault(stHr)
      Return 0
   }

   Return 1
}

StoreStartupAwaitObject(stAsync, stTimeout, ByRef stObject, ByRef stHr) {
; Waits for an asynchronous operation whose result is an object, releases
; the operation and hands the object over. The AsyncStatus given back is
; the one of StoreStartupAwait, with 3 standing also for a completed
; operation that would not part with its result.

   Static SLOT_GETRESULTS := 8   ; IAsyncOperation

   stObject := 0
   stStatus := StoreStartupAwait(stAsync, stTimeout, stHr)
   If (stStatus=1)
   {
      stHr := DllCall(WinGeoSlot(stAsync, SLOT_GETRESULTS), "Ptr", stAsync, "Ptr*", stObject, "Int")
      If (stHr || !stObject)
         stStatus := 3, stObject := 0
   }

   WinGeoRelease(stAsync)
   Return stStatus
}

StoreStartupAwait(stAsync, stTimeout, ByRef stHr) {
; Waits up to stTimeout milliseconds for an asynchronous WinRT operation to
; run its course and gives back its final AsyncStatus: 1 is Completed, 2
; Canceled, 3 Error with the HRESULT of the failure in stHr, and -1 the
; timeout, after which the operation has been cancelled. The work is done
; on a thread of the runtime's own, so the status is simply watched, and
; Sleep keeps the message queue running meanwhile.

   Static IID_IAsyncInfo := "{00000036-0000-0000-C000-000000000046}"
        , SLOT_STATUS := 7, SLOT_ERRORCODE := 8, SLOT_CANCEL := 9   ; IAsyncInfo

   stHr := 0
   stInfo := WinGeoQueryInterface(stAsync, IID_IAsyncInfo)
   If !stInfo
   {
      stHr := 0x80004002   ; E_NOINTERFACE
      Return 3
   }

   stDeadline := A_TickCount + stTimeout
   stStatus := 0
   Loop
   {
      stHr := DllCall(WinGeoSlot(stInfo, SLOT_STATUS), "Ptr", stInfo, "Int*", stStatus, "Int")
      If stHr
         stStatus := 3
      If (stStatus!=0)   ; AsyncStatus.Started
         Break

      If (A_TickCount>stDeadline)
      {
         DllCall(WinGeoSlot(stInfo, SLOT_CANCEL), "Ptr", stInfo)
         stStatus := -1
         Break
      }
      Sleep, 15
   }

   If (stStatus=3 && !stHr)
      DllCall(WinGeoSlot(stInfo, SLOT_ERRORCODE), "Ptr", stInfo, "Int*", stHr, "Int")

   WinGeoRelease(stInfo)
   Return stStatus
}

StoreStartupState(stTimeout := 2500) {
; The state of the package's startup task: 0 Disabled, 1 DisabledByUser,
; 2 Enabled, 3 DisabledByPolicy, 4 EnabledByPolicy, or -1 when Windows
; would not say.

   Static SLOT_STATE := 8   ; IStartupTask

   If !StoreStartupTask(stTask, stFault, stTimeout)
      Return -1

   stState := -1
   If DllCall(WinGeoSlot(stTask, SLOT_STATE), "Ptr", stTask, "Int*", stState, "Int")
      stState := -1

   WinGeoRelease(stTask)
   Return stState
}

StoreStartupMenuMark(stState) {
; The check mark beside Start at boot, made to agree with the task's state.

   If (stState=2 || stState=4)   ; Enabled, EnabledByPolicy
      Menu, moreOpts, Check, Start at boot
   Else
      Menu, moreOpts, Uncheck, Start at boot
}

StoreStartupRefreshMark(stForce := 0) {
; Reads the task's state afresh and sets the check mark by it, since the user
; may have changed the entry in the Task Manager meanwhile. Called when the
; tray menu is built and again on the right-click that opens it, no more
; than once every couple of seconds, and when Windows would not answer only
; once a minute, so that a runtime that is not working never makes the tray
; menu sluggish.

   Static stNextLook := 0

   If (storeSettingsREG!=1)
      Return
   If (!stForce && A_TickCount<stNextLook)
      Return

   stState := StoreStartupState(stForce ? 2500 : 1200)
   stNextLook := A_TickCount + ((stState=-1) ? 60000 : 2000)
   StoreStartupMenuMark(stState)
}

StoreStartupToggle() {
; Start at boot for the Windows Store edition, switched the other way from
; whatever Windows presently reports. Called by SetStartUp().

   Static SLOT_REQUESTENABLE := 6, SLOT_DISABLE := 7, SLOT_STATE := 8   ; IStartupTask
        , SLOT_GETRESULTS := 8   ; IAsyncOperation<StartupTaskState>
        , stBusy := 0

   If stBusy   ; the waits below let the message queue run, so a second click can arrive before the first is done
      Return

   stBusy := 1
   If !StoreStartupTask(stTask, stFault, 4000)
   {
      stBusy := 0
      simpleMsgBoxWrapper(appName, "The Start at boot setting could not be reached.`n`n" stFault "`n`nIt can still be switched by hand: open the Task Manager with Ctrl+Shift+Esc and look for " appName " on its Start-up apps page.", 0, 1, 48)
      Return
   }

   stState := -1
   DllCall(WinGeoSlot(stTask, SLOT_STATE), "Ptr", stTask, "Int*", stState, "Int")
   StoreStartupMenuMark(stState)
   If (stState=2)   ; Enabled: switch it off, and take Windows' word for the outcome rather than the call's
   {
      stHr := DllCall(WinGeoSlot(stTask, SLOT_DISABLE), "Ptr", stTask, "Int")
      DllCall(WinGeoSlot(stTask, SLOT_STATE), "Ptr", stTask, "Int*", stState, "Int")
      StoreStartupMenuMark(stState)
      If (stState=2)
         simpleMsgBoxWrapper(appName, "Windows kept the Start at boot entry switched on.`n`n" StoreStartupFault(stHr), 0, 1, 48)
      Else
         CreateOSDGUI("Disabled Start at Boot", 0, 1)
   } Else If (stState=0)   ; Disabled: ask Windows to switch it on
   {
      stAsync := 0, stNew := -1, stStatus := 0
      stHr := DllCall(WinGeoSlot(stTask, SLOT_REQUESTENABLE), "Ptr", stTask, "Ptr*", stAsync, "Int")
      If (!stHr && stAsync)
      {
         stStatus := StoreStartupAwait(stAsync, 4000, stHr)
         If (stStatus=1)
            DllCall(WinGeoSlot(stAsync, SLOT_GETRESULTS), "Ptr", stAsync, "Int*", stNew, "Int")
         WinGeoRelease(stAsync)
      }

      StoreStartupMenuMark(stNew)
      If (stNew=2 || stNew=4)
         CreateOSDGUI("Enabled Start at Boot", 0, 1)
      Else If (stNew=1)
         StoreStartupSwitchedOffByUser()
      Else If (stStatus=-1)
         simpleMsgBoxWrapper(appName, "Windows did not answer the request to start " appName " at boot within 4 seconds. Please try again.", 0, 1, 48)
      Else
         simpleMsgBoxWrapper(appName, "Windows did not switch on the Start at boot entry.`n`n" StoreStartupFault(stHr), 0, 1, 48)
   } Else If (stState=1)   ; DisabledByUser
      StoreStartupSwitchedOffByUser()
   Else If (stState=3 || stState=4)   ; DisabledByPolicy, EnabledByPolicy
      simpleMsgBoxWrapper(appName, "Whether " appName " starts at boot is decided by a system policy on this computer, and it cannot be changed from here.", 0, 1, 48)
   Else
      simpleMsgBoxWrapper(appName, "Windows would not say whether " appName " is set to start at boot. The entry can be checked on the Start-up apps page of the Task Manager, opened with Ctrl+Shift+Esc.", 0, 1, 48)

   WinGeoRelease(stTask)
   stBusy := 0
}

StoreStartupSwitchedOffByUser() {
; An entry switched off on the Start-up apps page of the Task Manager or of
; the Windows Settings is the user's decision, and Windows lets no
; application overrule it. The most the application may do is bring the
; user there.

   stMsg := "Starting " appName " at boot was switched off from outside the application, on the Start-up apps page of the Task Manager or of the Windows Settings. Windows does not let an application overrule that choice, so the entry has to be switched back on from there.`n`nOpen the Start-up apps page of the Windows Settings now?"
   If (simpleMsgBoxWrapper(appName, stMsg, 4, 1, 32)="Yes")
      Try Run, ms-settings:startupapps
}

StoreStartupFault(stHr) {
; The handful of failures worth naming plainly. Everything else is given back
; as the bare HRESULT, which is at least something to search for.

   stHr := stHr & 0xFFFFFFFF
   If (stHr=0xFFFFFFFF)
      Return "The Windows Runtime could not be started on this thread."
   Else If (stHr=0x80040154 || stHr=0x80040111)   ; REGDB_E_CLASSNOTREG, CLASS_E_CLASSNOTAVAILABLE
      Return "This edition of Windows knows nothing of startup tasks. Windows 10 version 1607 or newer is wanted."
   Else If (stHr=0x80073D54)   ; APPMODEL_ERROR_NO_PACKAGE
      Return "The application is running without a package identity, so Windows keeps no startup task for it."
   Else If (stHr=0x80070005)   ; E_ACCESSDENIED
      Return "Windows denied the application access to its startup task."
   Else If !stHr
      Return "Windows gave back nothing to work with."

   Return "Windows startup task error code: " Format("0x{:08X}", stHr) "."
}

SuspendScriptNow() {
   SuspendScript(0)
}

SuspendScript(partially:=0) {
   Suspend, Permit
   Thread, Priority, 150
   Critical, On

   If (PrefOpen=1 && A_IsSuspended=1)
   {
      SoundBeep, 300, 900
      Return
   }

   sillySoundHack()
   GuiFader("ChurchTowerOSDwin","hide", OSDalpha)
   If !A_IsSuspended
   {
      stopStrikesNow := 1
      DoGuiFader := 0
      ; SetTimer, theChimer, Off
      Menu, Tray, Uncheck, &%appName% activated
      SoundLoop("")
      If (constantAnalogClock=1)
         hideAnalogClock()
   } Else
   {
      If (partially=1)
         Gui, osdGuia: Destroy
      stopStrikesNow := 0
      Menu, Tray, Check, &%appName% activated
      ; theChimer()
      DoGuiFader := 1
      If (tickTockNoise=1)
         SoundLoop(tickTockSound)
      analogClockStarter()
   }

   If (partially=0)
   {
      DoGuiFader := 1
      friendlyName := A_IsSuspended ? " activated" : " deactivated"
      If (ClockVisibility!=1 || defAnalogClockPosChanged=1)
         CreateOSDGUI(appName friendlyName, 0, 1)
   }
   stopStrikesNow := 1
   Sleep, 20
   Suspend
}

ReloadScriptNow() {
    ReloadScript(0)
}

;================================================================
; Tray menu and related functions.
;================================================================

createMenuSoundOptions() {
  Menu, menuSoundOptionz, Add, VOL: %BeepsVolume%`%, dummy
  Menu, menuSoundOptionz, Disable, VOL: %BeepsVolume%`%
  Menu, menuSoundOptionz, Add
  Menu, menuSoundOptionz, Add, 10`%, menuSetAudioVolume
  Menu, menuSoundOptionz, Add, 20`%, menuSetAudioVolume
  Menu, menuSoundOptionz, Add, 40`%, menuSetAudioVolume
  Menu, menuSoundOptionz, Add, 60`%, menuSetAudioVolume
  Menu, menuSoundOptionz, Add, 80`%, menuSetAudioVolume
  Menu, menuSoundOptionz, Add, 90`%, menuSetAudioVolume
  Menu, menuSoundOptionz, Add
  Menu, menuSoundOptionz, Add, &Dynamic volume, ToggleDynamicVolSound
  If (dynamicVolume=1)
     Menu, menuSoundOptionz, Check, &Dynamic volume
  Menu, menuSoundOptionz, Add
  Menu, menuSoundOptionz, Add, &Mute all sounds, ToggleAllMuteSounds
  If (userMuteAllSounds=1)
     Menu, menuSoundOptionz, Check, &Mute all sounds
}

InitializeTrayMenu() {
    Menu, moreOpts, Add, Large UI &fonts, ToggleLargeFonts
    If (PrefsLargeFonts=1)
       Menu, moreOpts, Check, Large UI &fonts

    Menu, moreOpts, Add, Dar&k mode UI, ToggleDarkMode
    If (uiDarkMode=1)
       Menu, moreOpts, Check, Dar&k mode UI

    Menu, moreOpts, Add, Start at boot, SetStartUp
    If (storeSettingsREG=1)
    {
       StoreStartupRefreshMark(1)
    } Else
    {
       RegRead, currentReg, %StartRegPath%, %appName%
       If (StrLen(currentReg)>5)
          Menu, moreOpts, Check, Start at boot
    }

    If FileExist(tickTockSound)
    {
       Menu, moreOpts, Add, Tick/Toc&k sound, ToggleTickTock
       If (tickTockNoise=1)
          Menu, moreOpts, Check, Tick/Toc&k sound
    }

    Menu, moreOpts, Add, Reset analog clock position, ResetAnalogClickPosition
    Menu, moreOpts, Add
    Menu, moreOpts, Add, &Customize, PanelShowSettings

    Menu, Tray, NoStandard

    Menu, Tray, Add, &Preferences, :moreOpts
    Menu, Tray, Add, 
    Menu, Tray, Add, Astronom&y / Today, PanelTodayInfos
    Menu, Tray, Add, Celebrations / &holidays, PanelIncomingCelebrations
    Menu, Tray, Add, Calen&dar, PanelCalendarWindow
    Menu, Tray, Add
    Menu, Tray, Add, Set &alarm or timer, PanelSetAlarm
    Menu, Tray, Add, Stop&watch, PanelStopWatch
    Menu, Tray, Add
    Menu, Tray, Add, Analo&g clock display, toggleAnalogClock

    createMenuSoundOptions()
    If (ShowBibleQuotes=1)
       Menu, Tray, Add, Show pre&vious Bible quote, ShowLastBibleMsg
    Menu, Tray, Add, Show a Bible &quote now, InvokeBibleQuoteNow
    Menu, Tray, Add
    Menu, Tray, Add, &%appName% activated, SuspendScriptNow
    Menu, Tray, Check, &%appName% activated
    Menu, Tray, Add, &Audio volume, :menuSoundOptionz
    Menu, Tray, Add
    Menu, Tray, Add, Abou&t, PanelAboutWindow
    Menu, Tray, Add
    Menu, Tray, Add, &Restart app, ReloadScriptNow
    Menu, Tray, Add, E&xit, KillScript, P50

    ; Menu, Tray, Default, Abou&t
    Menu, Tray, % (constantAnalogClock=0 ? "Uncheck" : "Check"), Analo&g clock display
    decideSysTrayTooltip()
}

ToggleDarkMode() {
    IF (PrefOpen=1)
    {
       SoundBeep , 300, 100
       Return
    }

    uiDarkMode := !uiDarkMode
    INIaction(1, "uiDarkMode", "SavedSettings")
    Menu, moreOpts, % (uiDarkMode=0 ? "Uncheck" : "Check"), Dar&k mode UI
    setMenusTheme(uiDarkMode)
    setDarkWinAttribs(A_ScriptHwnd, uiDarkMode)
    reopenCurrentWin()
    ; ReloadScript()
}

ToggleLargeFonts() {
    PrefsLargeFonts := !PrefsLargeFonts
    LargeUIfontValue := 13
    INIaction(1, "PrefsLargeFonts", "SavedSettings")
    INIaction(1, "LargeUIfontValue", "SavedSettings")
    Menu, moreOpts, % (PrefsLargeFonts=0 ? "Uncheck" : "Check"), Large UI &fonts
    reopenCurrentWin()
}

reopenCurrentWin() {
    If (PrefOpen=1)
    {
       SwitchPreferences(1)
       Return
    }
 
    o_win := AnyWindowOpen
    CloseWindow()
    Sleep, 50
    If (o_win=1)
       PanelAboutWindow()
    Else If (o_win=2)
       ShowWelcomeWindow()
    Else If (o_win=3)
       PanelIncomingCelebrations()
    Else If (o_win=4)
       PanelSetAlarm()
    Else If (o_win=5)
       PanelStopWatch()
    Else If (o_win=6)
       PanelTodayInfos()
    Else If (o_win=7)
       PanelSunYearGraphTable()
    Else If (o_win=8)
       PanelEarthMap()
    Else If (o_win=9)
       PanelMoonYearGraphTable()
    Else If (o_win=10)
       PanelCalendarWindow()
    Else If (windowManageCeleb=1)
    {
       CloseCelebListWin()
       PanelManageCelebrations()
    }  
}

ToggleAllMuteSounds() {
    If (A_IsSuspended || PrefOpen=1)
    {
       SoundBeep, 300, 900
       If (PrefOpen=1)
          WinActivate, ahk_id %hSetWinGui%
       Return
    }

    userMuteAllSounds := !userMuteAllSounds
    INIaction(1, "userMuteAllSounds", "SavedSettings")
    Menu, menuSoundOptionz, % (userMuteAllSounds=0 ? "Uncheck" : "Check"), &Mute all sounds
    If (tickTockNoise=1)
    {
       ToggleTickTock()
       Sleep, 1
       ToggleTickTock()
    }
}

ToggleDynamicVolSound() {
    If (A_IsSuspended || PrefOpen=1)
    {
       SoundBeep, 300, 900
       If (PrefOpen=1)
          WinActivate, ahk_id %hSetWinGui%
       Return
    }

    dynamicVolume := !dynamicVolume
    INIaction(1, "dynamicVolume", "SavedSettings")
    Menu, menuSoundOptionz, % (dynamicVolume=0 ? "Uncheck" : "Check"), &Dynamic volume
    If (tickTockNoise=1)
    {
       ToggleTickTock()
       Sleep, 1
       ToggleTickTock()
    }
}

ToggleTickTock() {
    If (A_IsSuspended || PrefOpen=1)
    {
       SoundBeep, 300, 900
       If (PrefOpen=1)
          WinActivate, ahk_id %hSetWinGui%
       Return
    }

    tickTockNoise := !tickTockNoise
    INIaction(1, "tickTockNoise", "SavedSettings")
    Menu, moreOpts, % (tickTockNoise=0 ? "Uncheck" : "Check"), Tick/Toc&k sound
    If (tickTockNoise=1 && userMuteAllSounds!=1)
    {
       SoundLoop(tickTockSound)
       If (constantAnalogClock=1)
          SynchSecTimer()
 
       If (noTollingBgrSounds>=2)
          isSoundPlayingNow()
 
       SetMyVolume(1)
    } Else
       SoundLoop("")
}

toggleMoonPhasesAnalog() {
    analogMoonPhases := (analogMoonPhases=1) ? 0 : 1
    INIaction(1, "analogMoonPhases", "SavedSettings")
}

toggleDigitalTimeAnalog() {
    analogMoonPhases := (analogMoonPhases=2) ? 0 : 2
    INIaction(1, "analogMoonPhases", "SavedSettings")
}

toggleHourLabelsAnalog() {
    showAnalogHourLabels := !showAnalogHourLabels
    INIaction(1, "showAnalogHourLabels", "SavedSettings")
    ; reInitializeAnalogClock()
}

toggleRoundedWidget() {
   roundedClock := !roundedClock
   ClockDiameter := Round(FontSize * 4 * analogClockScale)
   ClockWinSize := ClockDiameter + Round((OSDmarginBottom//2 + OSDmarginTop//2 + OSDmarginSides//2) * analogClockScale)
   Width := Height := ClockWinSize + 2      ; make width and height slightly bigger to avoid cut away edges
   roundsize := Round(roundedCsize * (analogClockScale/1.5))
   If (ClockDiameter<=80)
   {
      ClockDiameter := 80
      ClockWinSize := 90
      roundsize := 20
   }

   rsz := roundsize*2 ; (width + height)//4
   If (constantAnalogClock=1 && hFaceClock)
   {
       If (roundedClock=1)
          WinSet, Region, 0-0 R%rsz%-%rsz% w%Width% h%Height%, ahk_id %hFaceClock%
       Else
          WinSet, Region, 0-0 R1-1 w%Width% h%Height%, ahk_id %hFaceClock%
   }

   INIaction(1, "roundedClock", "OSDprefs")
}

toggleAnalogClock() {
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
      If (PrefOpen=1)
         WinActivate, ahk_id %hSetWinGui%
      Return
   }

   o_constantAnalogClock := constantAnalogClock
   constantAnalogClock := !constantAnalogClock
   If (o_constantAnalogClock=1 && hFaceClock)
      saveAnalogClockPosition()

   If (constantAnalogClock=1 && moduleAnalogClockInit!=1)
      InitClockFace()

   ; LastWinOpened := A_ThisFunc
   ; INIaction(1, "LastWinOpened", "SavedSettings")
   INIaction(1, "constantAnalogClock", "OSDprefs")
   Menu, Tray, % (constantAnalogClock=0 ? "Uncheck" : "Check"), Analo&g clock display
   If (constantAnalogClock=1)
      showAnalogClock()
   Else
      hideAnalogClock()
}

ForceReloadNow() {
    Sleep, 25
    Try Reload
    Sleep, 50
    ExitApp
}

ReloadScript(silent:=1) {
    Thread, Priority, 50
    Critical, On
    If (ScriptInitialized!=1 || attempts2Quit>0)
    {
       ForceReloadNow()
       Return
    }

    attempts2Quit++
    CloseWindow()
    DoGuiFader := 1
    DestroyOSDguia(A_ThisFunc)
    Sleep, 15
    If FileExist(ThisFile)
    {
       Sleep, 50
       Cleanup()
       Try Reload
       Sleep, 50
       ExitApp
    } Else
    {
       SoundBeep
       simpleMsgBoxWrapper(appName, "FATAL ERROR: Main file missing. Execution terminated.", 0, 1, 16)
       ExitApp
    }
}

DeleteSettings() {
    obju := listUserDefinedCelebrations()
    keptEvents := obju[1]
    countu := obju[2]
    brr := (ObserveHolidays=1) ? " The feasts, holidays and events you chose to no longer observe will be observed again." : ""
    msgu := "Are you sure you want to restore the default settings?`n`nEvery option will go back to its default value." brr
    msgu .= countu ? "`n`nThe " countu " personal event" ((countu>1) ? "s" : "") " you defined will be kept, and so will the custom locations." : "`n`nThe custom user-defined locations will be kept."

    r := simpleMsgBoxWrapper(appName, msgu, 4, 2, 32)
    If (r!="Yes")
       Return

    If (storeSettingsREG=0)
    {
       FileSetAttrib, -R, %IniFile%
       FileDelete, %IniFile%
    } Else
    {
       RegDelete, %APPregEntry%\Celebrations
       RegWrite, REG_SZ, %APPregEntry%, FirstRun, 1
    }

    Loop, Parse, keptEvents, `n, `r
    {
        p := InStr(A_LoopField, CSmid)
        If (p>1)
           INIactionNonGlobal(1, SubStr(A_LoopField, 1, p - 1), SubStr(A_LoopField, p + 1), "Celebrations")
    }

    Cleanup()
    Try Reload
    Sleep, 70
    ExitApp
}

KillScript(showMSG:=1) {
   Thread, Priority, 50
   Critical, On
   If (ScriptInitialized!=1 || attempts2Quit>0)
   {
      ExitApp
      Return
   }

   attempts2Quit++
   CloseWindow()
   DoGuiFader := 1
   PrefOpen := 0
   DestroyOSDguia(A_ThisFunc)
   Sleep, 50
   If (FileExist(ThisFile) && showMSG)
   {
      INIsettings(1)
      CreateOSDGUI("Bye byeee :-)", 0, 1)
      Sleep, 350
   } Else If showMSG
   {
      CreateOSDGUI("Adiiooosss :-(((", 0, 1)
      Sleep, 950
   }
   DestroyOSDguia(A_ThisFunc)
   Sleep, 50
   Cleanup()
   ExitApp
}

;================================================================
;  Settings window.
;   various functions used in the UI.
;================================================================

GenericPanelGUI(themed:=0) {
   Global
   Gui, SettingsGUIA: Destroy
   Sleep, 15
   Gui, SettingsGUIA: Default
   Gui, SettingsGUIA: -MaximizeBox -MinimizeBox +hwndhSetWinGui
   Gui, SettingsGUIA: Margin, 15, 15
   combosDarkModus := (uiDarkMode=1) ? "-theme -border " : ""
   applyDarkMode2guiPre(hSetWinGui)
}

applyDarkMode2guiPre(hThisWin) {
   combosDarkModus := (uiDarkMode=1) ? "-theme -border " : ""
   If (uiDarkMode=1)
   {
      Gui, Color, % darkWindowColor, % darkWindowColor
      Gui, Font, c%darkControlColor%
      AboutTitleColor := "eebb22"
      setDarkWinAttribs(hThisWin)
   } Else AboutTitleColor := "1166AA"
}

doResetGuiFont() {
   If (uiDarkMode=1)
   {
      Gui, Font
      Gui, Color, % darkWindowColor, % darkWindowColor
      Gui, Font, c%darkControlColor%
   } Else
   {
      Gui, Font
   }

   If (PrefsLargeFonts=1)
      Gui, Font, s%LargeUIfontValue%
}

initSettingsWindow() {
    Global ApplySettingsBTN
    If (PrefOpen=1)
    {
        SoundBeep, 300, 900
        doNotOpen := 1
        Return doNotOpen
    }

    If (A_IsSuspended!=1)
       SuspendScript(1)

    PrefOpen := 1
    GenericPanelGUI()
}

LinkUseDefaultColor(hLink, Use, whichGui) {
   VarSetCapacity(LITEM, 4278, 0)            ; 16 + (MAX_LINKID_TEXT * 2) + (L_MAX_URL_LENGTH * 2)
   NumPut(0x03, LITEM, "UInt")               ; LIF_ITEMINDEX (0x01) | LIF_STATE (0x02)
   NumPut(Use ? 0x10 : 0, LITEM, 8, "UInt")  ; ? LIS_DEFAULTCOLORS : 0
   NumPut(0x10, LITEM, 12, "UInt")           ; LIS_DEFAULTCOLORS
   While DllCall("SendMessage", "Ptr", hLink, "UInt", 0x0702, "Ptr", 0, "Ptr", &LITEM, "UInt") ; LM_SETITEM
         NumPut(A_Index, LITEM, 4, "Int")
   GuiControl, %whichGUI%: +Redraw, %hLink%
}

applyDarkMode2winPost(whichGui, hwndGUI) {
    Static lastAsked := 1, BS_PUSHLIKE := 0x1000, WS_CLIPSIBLINGS := 0x4000000
         , BS_CHECKBOX := 0x2, BS_RADIOBUTTON := 0x8, BS_AUTORADIOBUTTON := 0x09
         , RCBUTTONS := BS_CHECKBOX | BS_RADIOBUTTON | BS_AUTORADIOBUTTON

    If (uiDarkMode=1)
    {
       Static clrBG := "303030"
       clrTX := SubStr(darkControlColor, 3)
       If !whichGui
          whichGui := "SettingsGUIA"
       if !hwndGUI
          hwndGUI := hSetWinGui

       setDarkWinAttribs(hwndGUI)
       WinGet,strControlList, ControlList, ahk_id %hwndGUI%
       ; Gui, %whichGUI%: Color, %darkWindowColor%, %darkControlColor%
       for strKey, strControl in StrSplit(strControlList,"`n","`r`n")
       {
         ControlGet, strControlHwnd, HWND, , %strControl%, ahk_id %hwndGUI%
         WinGetClass, CtrlClass, ahk_id %strControlhwnd%
         ControlGet, CtrlStyle, Style, , , ahk_id %strControlhwnd%
         doAttachCtlColor := 0
         ; MsgBox, % CtrlClass
         If InStr(CtrlClass, "systab")
         {
            GuiControl, %whichGUI%:-Border +Buttons cFFFFaa, %strControl%
            doAttachCtlColor := -2
         } Else If InStr(CtrlClass, "Button")
         {
              doAttachCtlColor := -2
              If (CtrlStyle & BS_PUSHLIKE)
              {
                 doAttachCtlColor := 0
                 WinSet, Style, +%WS_CLIPSIBLINGS%, ahk_id %strControlhwnd%
                 GetWinClientSize(w, h, strControlHwnd, 1)
                 WinSet, Region, % "1-1 w" w - 2 " h" h - 2, ahk_id %strControlhwnd%
              } Else IF (CtrlStyle & BS_RADIOBUTTON) || ((CtrlStyle & RCBUTTONS) > 1)
              {
                 Sleep, -1
              } Else 
              {
                 doAttachCtlColor := 0
                 ; SetImgButtonStyle(strControlHwnd)
                 WinSet, Style, +%WS_CLIPSIBLINGS%, ahk_id %strControlhwnd%
                 GetWinClientSize(w, h, strControlHwnd, 1)
                 WinSet, Region, % "1-1 w" w - 2 " h" h - 2, ahk_id %strControlhwnd%
              }
         } Else If InStr(CtrlClass, "ComboBox")
         {
            doAttachCtlColor := -2
            CtlColors.Attach(strControlHwnd, clrBG, clrTX)
            If (A_OSVersion="WIN_7" || A_OSVersion="WIN_XP")
            {
               WinSet, Style, +%WS_CLIPSIBLINGS%, ahk_id %strControlhwnd%
               GetWinClientSize(w, h, strControlHwnd, 1)
               WinSet, Region, % "1-1 w" w - 3 " h" h - 2, ahk_id %strControlhwnd%
            } Else
               DllCall("uxtheme\SetWindowTheme", "uptr", strControlHwnd, "str", "DarkMode_CFD", "ptr", 0)
         } Else If InStr(CtrlClass, "Edit")
            doAttachCtlColor := -1
         Else If (InStr(CtrlClass, "Static") || InStr(CtrlClass, "syslink"))
            doAttachCtlColor := -2 

         If InStr(CtrlClass, "syslink")
            LinkUseDefaultColor(strControlHwnd, 1, whichGui)

         If (doAttachCtlColor=1)
            CtlColors.Attach(strControlHwnd, SubStr(darkWindowColor, 3), SubStr(darkControlColor, 3))

         If (doAttachCtlColor!=2 && doAttachCtlColor!=-2)
            DllCall("uxtheme\SetWindowTheme", "uptr", strControlHwnd, "str", "DarkMode_Explorer", "ptr", 0)
       }
    }
}

SwitchPreferences(forceReopenSame:=0) {
    PrefOpen := 0
    Gui, SettingsGUIA: Default
    GuiControlGet, ApplySettingsBTN, Enabled
    Gui, Submit
    Gui, SettingsGUIA: Destroy
    Sleep, 25
    GenericPanelGUI()
    CheckSettings()
    PanelShowSettings()
    VerifyTheOptions(ApplySettingsBTN)
}

ApplySettings() {
    Gui, SettingsGUIA: Submit, NoHide
    CheckSettings()
    PrefOpen := 0
    INIsettings(1)
    Sleep, 50
    ReloadScript()
}

CloseWindow() {
    AnyWindowOpen := 0
    mouseTurnOFFtooltip()
    SetTimer, regularUpdaterTodayPanel, Off
    ResetStopWatchCounter()
    If (tickTockNoise!=1)
       SoundLoop("")

    Gui, SettingsGUIA: Destroy
    trackImageListButtons("kill")
    hSetWinGui := ""
}

CloseSettings() {
   Gui, SettingsGUIA: Default
   GuiControlGet, ApplySettingsBTN, Enabled
   PrefOpen := 0
   CloseWindow()
   trackImageListButtons("kill")
   If (ApplySettingsBTN=0)
   {
      ; ShowPreview := 1
      ; SetTimer, OSDpreview, -150
      Sleep, 25
      SuspendScript()
      ShowPreview := 0
      Return
   }
   Sleep, 100
   ReloadScript()
}

isVarEqualTo(value, vals*) {
   yay := 0
   for index, param in vals
   {
       If (value=param)
       {
          yay := 1
          Break
       }
   }
   Return yay
}

SettingsGUIAGuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y) {
    Static lastInvoked := 1
    If (CtrlHwnd && IsRightClick=1) || (mouseToolTipWinCreated=1)
    || ((A_TickCount-lastInvoked>250) && IsRightClick=0)
    {
       lastInvoked := A_TickCount
       Return
    }
 
    k := (IsRightClick) ? "rclick" : 0
    coreSettingsContextMenu(k)
    lastInvoked := A_TickCount
    Return
}

invokeSettingsContextMenu() {
    coreSettingsContextMenu("rclick")
}

coreSettingsContextMenu(modus:=0) {
   ActiveWin := WinActive("A")
   If (ActiveWin=hCelebsMan && windowManageCeleb=1)
      Gui, CelebrationsGuia: Default
   Else
      Gui, SettingsGUIA: Default

   GuiControlGet, WhatsFocused, FocusV
   If (isVarEqualTo(WhatsFocused, "holiListu", "UIcalendarEventsEditu", "UIcalendarNewEventEdit", "GeoDataSearchField", "newGeoDataLocationUserEdit", "UItodayEventsEditu") && modus!="rclick")
   {
      SendInput, {AppsKey}
      Return
   }

    Menu, ContextMenu, UseErrorLevel
    Menu, ContextMenu, Delete
    Sleep, 25
    Menu, ContextMenu, Add, L&arge UI fonts, ToggleLargeFonts
    If (PrefsLargeFonts=1)
       Menu, ContextMenu, Check, L&arge UI fonts

    If (PrefOpen=0)
    {
       Menu, ContextMenu, Add, Dar&k mode UI, ToggleDarkMode
       If (uiDarkMode=1)
          Menu, ContextMenu, Check, Dar&k mode UI

       Menu, ContextMenu, Add
       createMenuOSDprefs()
       Menu, ContextMenu, Add, OSD &settings, :MenuOSDprefs
       Menu, ContextMenu, Add
       Menu, ContextMenu, Add, &Mute all sounds, ToggleAllMuteSounds
       If (userMuteAllSounds=1)
          Menu, ContextMenu, Check, &Mute all sounds

       If FileExist(tickTockSound)
       {
          Menu, ContextMenu, Add, Tick/Toc&k sound, ToggleTickTock
          If (tickTockNoise=1)
             Menu, ContextMenu, Check, Tick/Toc&k sound
       }

       If (AnyWindowOpen=6)
       {
          Menu, ContextMenu, Add
          Menu, ContextMenu, Add, &Detect device location, MenuDetectDeviceLocation
          If (uiUserCountry=1)
             Menu, ContextMenu, Add, &Rename custom location, MenuRenameUserLocation

          Menu, ContextMenu, Add, Altitude based &solar times, toggleLocationSolarInfluence
          Menu, ContextMenu, Add, &Observe DST changes, toggleDSTchanges
          If (allowDSTchanges=1)
             Menu, ContextMenu, Check, &Observe DST changes
          If (allowAltitudeSolarChanges=1)
             Menu, ContextMenu, Check, Altitude based &solar times
       }

       Menu, ContextMenu, Add
       If (AnyWindowOpen!=6)
          Menu, ContextMenu, Add, Astronom&y / Today, PanelTodayInfos
       If (AnyWindowOpen!=3)
          Menu, ContextMenu, Add, Celebrations / &holidays, PanelIncomingCelebrations
       If (AnyWindowOpen!=10)
          Menu, ContextMenu, Add, Calen&dar, PanelCalendarWindow

       Menu, ContextMenu, Add
       Menu, ContextMenu, Add, Analo&g clock display, toggleAnalogClock
       If (constantAnalogClock=1)
          Menu, ContextMenu, Check, Analo&g clock display

       If (AnyWindowOpen!=4)
          Menu, ContextMenu, Add, Set &alarm or timer, PanelSetAlarm
       If (AnyWindowOpen!=5)
          Menu, ContextMenu, Add, Stop&watch, PanelStopWatch

       If (AnyWindowOpen!=1)
       {
          Menu, ContextMenu, Add
          Menu, ContextMenu, Add, Abou&t, PanelAboutWindow
       }
    } Else If (PrefOpen=1 && appSettingsModified=0)
    {
       Menu, ContextMenu, Add
       Menu, ContextMenu, Add, Astronom&y / Today, PanelTodayInfos
       Menu, ContextMenu, Add, Celebrations / &holidays, PanelIncomingCelebrations
       Menu, ContextMenu, Add, Calen&dar, PanelCalendarWindow
       Menu, ContextMenu, Add, Set &alarm or timer, PanelSetAlarm
       Menu, ContextMenu, Add, Stop&watch, PanelStopWatch
       Menu, ContextMenu, Add, Abou&t, PanelAboutWindow
    }

    Menu, ContextMenu, Add
    If (PrefOpen=0)
    {
        Menu, ContextMenu, Add, &Settings, PanelShowSettings
        Menu, ContextMenu, Add
    }

    Menu, ContextMenu, Add, Donate now, DonateNow
    Menu, ContextMenu, Add, &Restart app, ReloadScriptNow
    Menu, ContextMenu, Show
}

toggleOSDastralColors() {
    OverrideOSDcolorsAstro := !OverrideOSDcolorsAstro
    INIaction(1, "OverrideOSDcolorsAstro", "OSDprefs")
    If (constantOSDvisible=1)
       CreateOSDGUI(generateDateTimeTxt(), 0, 1)
}

toggleOSDidleDisplay() {
    showTimeWhenIdle := !showTimeWhenIdle
    If (showTimeWhenIdle=1)
       SetTimer, TimerShowOSDidle, 1500
    Else
       SetTimer, TimerShowOSDidle, Off

    INIaction(1, "showTimeWhenIdle", "OSDprefs")
}

toggleOSDconstDisplay() {
    constantOSDvisible := !constantOSDvisible
    If (constantOSDvisible=1)
    {
       If (showTimeWhenIdle=1)
          SetTimer, TimerShowOSDidle, Off

       showTimeWhenIdle := 0
       SetTimer, TimerAlwaysShowOSD, 1500
       INIaction(1, "showTimeWhenIdle", "OSDprefs")
    } Else
    {
       DestroyOSDguia(A_ThisFunc)
       SetTimer, TimerAlwaysShowOSD, Off
    }

    INIaction(1, "constantOSDvisible", "OSDprefs")
}

toggleOSDtimeFormat() {
    displayTimeFormat := !displayTimeFormat
    INIaction(1, "displayTimeFormat", "OSDprefs")
    If (constantOSDvisible=1)
       CreateOSDGUI(generateDateTimeTxt(), 0, 1)
}

toggleOSDallDate() {
    OSDalwaysDateShow := !OSDalwaysDateShow
    INIaction(1, "OSDalwaysDateShow", "OSDprefs")
    If (constantOSDvisible=1)
       CreateOSDGUI(generateDateTimeTxt(), 0, 1)
}

toggleOSDlongDate() {
    OSDlongDateFormat := !OSDlongDateFormat
    INIaction(1, "OSDlongDateFormat", "OSDprefs")
    If (constantOSDvisible=1)
       CreateOSDGUI(generateDateTimeTxt(), 0, 1)
}

toggleOSDroundCorners() {
    OSDroundCorners := !OSDroundCorners
    INIaction(1, "OSDroundCorners", "OSDprefs")
    If (constantOSDvisible=1)
       CreateOSDGUI(generateDateTimeTxt(), 0, 1)
}

ChangeMenuOSDopacity() {
   newSize := ( StrReplace(A_ThisMenuItem, "%") /100 ) * 255
   OSDalpha := Round(newSize)
   INIaction(1, "OSDalpha", "OSDprefs")
   If (constantOSDvisible=1)
      CreateOSDGUI(generateDateTimeTxt(), 0, 1)
}

toggleOSDwolvesHowling() {
    markFullMoonHowls := !markFullMoonHowls
    INIaction(1, "markFullMoonHowls", "OSDprefs")
}

toggleOSDDlockPosition() {
    constantOSDlockPosition := !constantOSDlockPosition
    INIaction(1, "constantOSDlockPosition", "OSDprefs")
}

toggleOSDmoonPhase() {
    showMoonPhaseOSD := !showMoonPhaseOSD
    INIaction(1, "showMoonPhaseOSD", "OSDprefs")
    If (constantOSDvisible=1)
       CreateOSDGUI(generateDateTimeTxt(), 0, 1)
}

toggleDSTchanges() {
    allowDSTchanges := !allowDSTchanges
    INIaction(1, "allowDSTchanges", "SavedSettings")
    UIcityChooser()
}

toggleLocationSolarInfluence() {
    allowAltitudeSolarChanges := !allowAltitudeSolarChanges
    INIaction(1, "allowAltitudeSolarChanges", "SavedSettings")
    UIcityChooser()
}

CelebrationsGuiaGuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y) {
    SettingsGUIAGuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y)
}

SettingsGUIAGuiEscape:
   If (PrefOpen=1)
      CloseSettings()
   Else
      CloseWindow()
Return

SettingsGUIAGuiClose:
   If (PrefOpen=1)
      CloseSettings()
   Else
      CloseWindow()
Return

CelebrationsGuiaGuiEscape:
   CloseCelebListWin()
Return

CelebrationsGuiaGuiClose:
   CloseCelebListWin()
Return

hexRGB(c) {
; unknown source
  r := ((c&255)<<16)+(c&65280)+((c&0xFF0000)>>16)
  c := "000000"
  DllCall("msvcrt\sprintf", "AStr", c, "AStr", "%06X", "UInt", r, "CDecl")
  Return c
}

Standard_Dlg_Color(Color,hwnd) {
; Function by maestrith 
; from: [AHK 1.1] Font and Color Dialogs 
; https://autohotkey.com/board/topic/94083-ahk-11-font-and-color-dialogs/
; Modified by Marius Șucan and Drugwash

  Static
  If !cpdInit {
     VarSetCapacity(CUSTOM,64,0), cpdInit:=1, size:=VarSetCapacity(CHOOSECOLOR,9*A_PtrSize,0)
  }

  Color := "0x" hexRGB(InStr(Color, "0x") ? Color : Color ? "0x" Color : 0x0)
  NumPut(size,CHOOSECOLOR,0,"UInt"),NumPut(hwnd,CHOOSECOLOR,A_PtrSize,"Ptr")
  ,NumPut(Color,CHOOSECOLOR,3*A_PtrSize,"UInt"),NumPut(3,CHOOSECOLOR,5*A_PtrSize,"UInt")
  ,NumPut(&CUSTOM,CHOOSECOLOR,4*A_PtrSize,"Ptr")
  If !ret := DllCall("comdlg32\ChooseColorW","Ptr",&CHOOSECOLOR,"UInt")
     Exit

  SetFormat, Integer, H
  Color := NumGet(CHOOSECOLOR,3*A_PtrSize,"UInt")
  SetFormat, Integer, D
  Return Color
}

InvokeSetNewColor(hC, event, c, err=0) {
; Function by Drugwash
; Critical MUST be disabled below! If that's not done, script will enter a deadlock !
  Static
  oc := A_IsCritical
  Critical, Off
  If (event != "Normal")
     Return
  g := A_Gui, ctrl := A_GuiControl
  r := %ctrl% := hexRGB(Standard_Dlg_Color(%ctrl%, hC))
  Critical, %oc%
  updateColoredRectCtrl(r, ctrl, g, hC)

  ; GuiControl, %g%:+Background%r%, %ctrl%
  If (CurrentPrefWindow=5)
     GuiControl, %g%:Enable, ApplySettingsBTN
  SetTimer, OSDpreview, -150
}

UpdateFntNow() {
  Global
  Fnt_DeleteFont(hfont)
  fntOptions := "s" FontSize " Bold Q5"
  hFont := Fnt_CreateFont(FontName,fntOptions)
  Fnt_SetFont(hOSDtxt,hfont,true)
}

OSDpreview() {
    Static lastInvoked := 1, LastBorderState, lastFnt := FontName
    Gui, SettingsGUIA: Submit, NoHide
    SetTimer, DestroyOSDguia, Off
    If (ShowPreview=0 || PrefOpen=0)
    {
       DoGuiFader := 1
       If (ClockVisibility=1)
          hideAnalogClock()
       DestroyOSDguia(A_ThisFunc)
       Return
    }

    CreateOSDGUI(generateDateTimeTxt(1, !ShowPreviewDate))
    ; If (A_TickCount - lastInvoked > 200) && (PrefOpen=1 && !GetKeyState("LButton", "P"))
    ; {
    ;    reInitializeAnalogClock()
    ;    lastInvoked := A_TickCount
    ;    Sleep, 25
    ; }

    DoGuiFader := 0
    Sleep, 25
    If (lastFnt!=FontName)
    {
       FontChangedTimes++
       lastFnt := FontName
    }
    ; ToolTip, nr. %FontChangedTimes%
    If (FontChangedTimes>190)
       UpdateFntNow()
}

reInitializeAnalogClock() {
   hideAnalogClock()
   Sleep, 2
   exitAnalogClock()
   Sleep, 2
   InitClockFace()
   DestroyOSDguia(A_ThisFunc)
   Sleep, 2
   showAnalogClock()
}

generateDateTimeTxt(LongD:=1, noDate:=0) {
; function to be used only for CreateOSDGUI()
    If (displayTimeFormat=1)
    {
       FormatTime, CurrentTime,, H:mm
    } Else
    {
       timeSuffix := (A_Hour<12) ? " AM" : " PM"
       FormatTime, CurrentTime,, h:mm
    }

    If (LongD=1 && OSDlongDateFormat=1)
       FormatTime, CurrentDate,, LongDate
    Else
       FormatTime, CurrentDate,, ShortDate

    If (noDate=3)
       Return CurrentDate

    txtReturn := CurrentTime timeSuffix
    If (noDate!=1 || OSDalwaysDateShow=1)
       txtReturn .= " | " CurrentDate
    Return txtReturn
}

editsOSDwin() {
  If (A_TickCount-DoNotRepeatTimer<1000)
     Return
  VerifyTheOptions()
}

checkBoxStrikeQuarter() {
  Gui, SettingsGUIA: Default
  GuiControlGet, tollQuarters
  stopStrikesNow := 0
  VerifyTheOptions()
  If (tollQuarters=1)
     strikeQuarters(1)
}

checkBoxStrikeHours() {
  Gui, SettingsGUIA: Default
  GuiControlGet, tollHours
  stopStrikesNow := 0
  VerifyTheOptions()
  If (tollHours=1)
     strikeHours(1)
}

checkBoxStrikeAdditional() {
  Gui, SettingsGUIA: Default
  GuiControlGet, AdditionalStrikes
  stopStrikesNow := 0
  VerifyTheOptions()
  If (AdditionalStrikes=1)
     MCXI_Play(SNDmedia_auxil_bell)
}

BtnHelpOrderedDisplay() {
  Gui, SettingsGUIA: +OwnDialogs
  MsgBox, , % "Help: " appName, Please select the option "Define start point" to set the index of the verse from which to begin displaying verses at the specified frequency. If the option is activated`, the verses will be displayed in the order they appear in the selected Bible`, otherwise the verse to be displayed will be chosen randomly.
}

PanelShowSettings() {
    doNotOpen := initSettingsWindow()
    If (doNotOpen=1)
    {
       WinActivate, ahk_id %hSetWinGui%
       Return
    }

    Global CurrentPrefWindow := 5
    Global DoNotRepeatTimer := A_TickCount
    Global editF1, editF2, editF3, editF4, editF5, editF6, Btn1, volLevel, editF40, editF60, editF73, Btn2, txt4, Btn3, editF99, txt100, txt200
         , editF7, editF8, editF9, editF10, editF11, editF13, editF35, editF36, editF37, editF38, txt1, txt2, txt3, txt10, Btn4, Btn5

    appSettingsModified := 0
    columnBpos1 := columnBpos2 := 160
    editFieldWid := 220
    btnWid := 90
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 45
       editFieldWid := editFieldWid + 65
       columnBpos1 := columnBpos2 := columnBpos2 + 90
    }

    columnBpos1b := columnBpos1 + 20
    Gui, Add, Tab3, +hwndhTabs, Bells|Bible|Restrictions|OSD|More
    LastWinOpened := A_ThisFunc
    INIaction(1, "LastWinOpened", "SavedSettings")

    Gui, Tab, 1 ; general
    Gui, Add, Text, x+15 y+15 Section +0x200 vvolLevel, % "Audio volume: " BeepsVolume " % "
    Gui, Add, Slider, x+5 hp ToolTip NoTicks gUIVolumeSlider w200 vBeepsVolume Range0-99, %BeepsVolume%
    Gui, Add, Checkbox, gVerifyTheOptions xs y+7 Checked%DynamicVolume% vDynamicVolume, Dynamic volume (adjusted relative to the master volume)
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%AutoUnmute% vAutoUnmute, Automatically unmute master volume
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%userMuteAllSounds% vuserMuteAllSounds, Mute all sounds
    Gui, Add, Text, xs+17 y+10 hp+4 +0x200, Interval between tower strikes (in milisec.):
    GuiAddEdit("x+5 w70 geditsOSDwin +0x200 r1 limit5 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF37", strikeInterval)
    Gui, Add, UpDown, gVerifyTheOptions vstrikeInterval Range900-5500, %strikeInterval%

    Gui, Add, Checkbox, xs y+15 gVerifyTheOptions Checked%tollNoon% vtollNoon, Toll distinctively every six hours [eg., noon, midnight]
    Gui, Add, Checkbox, y+10 gcheckBoxStrikeQuarter Checked%tollQuarters% vtollQuarters, Strike quarter-hours
    Gui, Add, Checkbox, x+10 wp -wrap hp gVerifyTheOptions Checked%tollQuartersException% vtollQuartersException, ... except on the hour
    Gui, Add, Checkbox, xs y+10 wp gcheckBoxStrikeHours Checked%tollHours% vtollHours, Strike on the hour
    Gui, Add, Checkbox, x+10 gVerifyTheOptions Checked%tollHoursAmount% vtollHoursAmount, ... and the number of hours
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%markFullMoonHowls% vmarkFullMoonHowls, Mark full moon by wolves howling
    Gui, Add, Checkbox, xs y+10 hp+5 gcheckBoxStrikeAdditional Checked%AdditionalStrikes% vAdditionalStrikes, Additional strike every (in minutes):
    GuiAddEdit("x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF38", strikeEveryMin, "Additional strike every (in minutes)")
    Gui, Add, UpDown, gVerifyTheOptions vstrikeEveryMin Range1-720, %strikeEveryMin%

    wu := (PrefsLargeFonts=1) ? 125 : 95
    vu := (PrefsLargeFonts=1) ? 55 : 45
    mf := (PrefsLargeFonts=1) ? 260 : 193
    Gui, Tab, 2 ; extras
    Gui, Add, Checkbox, x+15 y+15 Section gVerifyTheOptions Checked%showBibleQuotes% vshowBibleQuotes +hwndhTemp, Show a Bible verse every (in hours)
    GuiAddEdit("x+10 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF40", BibleQuotesInterval, "Show a Bible verse every (in hours)")
    Gui, Add, UpDown, gVerifyTheOptions vBibleQuotesInterval Range1-12, %BibleQuotesInterval%
    GuiAddDropDownList("xs+15 y+7 w" mf " gVerifyTheOptions AltSubmit Choose" BibleQuotesLang " vBibleQuotesLang", "World English Bible (2000)|Français: La Bible de Jérusalem (1998?)|Español: Reina Valera (1989)|Latin: Clementine Vulgate (1598)|German: Lutherbibel (1912)|Greek: Revised Vamvas (1994?)|Russian: Synodal edition (1956)", [hTemp, 0, "Bible edition and language"])
    Gui, Add, Checkbox, x+5 hp gVerifyTheOptions Checked%orderedBibleQuotes% vorderedBibleQuotes, Define the start point
    Gui, Add, Text, xs+15 y+10 hp +0x200 vTxt10, Font size:
    GuiAddEdit("x+10 w" vu " geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF73", FontSizeQuotes, "Font size for Bible quotes")
    Gui, Add, UpDown, gVerifyTheOptions vFontSizeQuotes Range10-200, %FontSizeQuotes%
    Gui, Add, Button, x+10 hp w%wu% gInvokeBibleQuoteNow vBtn2, Preview verse
    GuiAddEdit("x+10 w" vu " r1 limit5 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF4", userBibleStartPoint, "Bible verse starting point")
    Gui, Add, UpDown, gVerifyTheOptions vuserBibleStartPoint Range1-35000, % userBibleStartPoint   ; VerifyTheOptions() narrows the range to the chosen Bible
    ml := (PrefsLargeFonts=1) ? 40 : 32
    GuiAddButton("x+5 hp w" ml " gBtnHelpOrderedDisplay vBtn5", " ?", "Help")
    Gui, Add, Text, xs+15 y+10 hp +0x200 vTxt4, Maximum line length (in characters):
    GuiAddEdit("x+10 w" vu " geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF60", maxBibleLength)
    Gui, Add, UpDown, vmaxBibleLength gVerifyTheOptions Range20-130, %maxBibleLength%
    Gui, Add, Checkbox, xs+15 y+10 gVerifyTheOptions Checked%makeScreenDark% vmakeScreenDark, Dim the screen when displaying Bible verses
    Gui, Add, Checkbox, y+7 gVerifyTheOptions Checked%gongAudioVerseDisplay% vgongAudioVerseDisplay, Play a sound when displaying the verse

    Gui, Add, Checkbox, xs y+20 gVerifyTheOptions Checked%ObserveHolidays% vObserveHolidays, Observe feasts`, holidays and other events
    Gui, Add, Checkbox, xs y+7 gVerifyTheOptions Checked%SemantronHoliday% vSemantronHoliday, Mark days of feast by regular semantron drumming
    Gui, Add, Button, xs+15 y+7 h30 gOpenListCelebrationsBtn vBtn3, Manage the list of events

    Gui, Tab, 3 ; restrictions
    widu := (PrefsLargeFonts=1) ? 270 : 210
    Gui, Add, Text, x+15 y+15 Section, When other sounds are playing (e.g., music or movies)
    GuiAddDropDownList("xs+15 y+7 w" widu " gVerifyTheOptions AltSubmit Choose" noTollingBgrSounds " vnoTollingBgrSounds", "Ignore|Strike the bells at half the volume|Do not strike the bells")
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%noTollingWhenMhidden% vnoTollingWhenMhidden, Do not toll bells when mouse cursor is hidden`,`neven if no sounds are playing
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%noTollingWhenLocked% vnoTollingWhenLocked, Do not toll bells when the Windows session is locked
     GuiAddDropDownList("xs y+25 w" widu " gVerifyTheOptions AltSubmit Choose" silentHours " vsilentHours", "Toll through the entire day and night|Toll only in the defined interval|Keep silence in the defined interval", "Bell tolling interval")
    Gui, Add, Text, xp+15 y+6 hp +0x200 vtxt1, from
    GuiAddEdit("x+5 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF35", silentHoursA, "Start hour")
    Gui, Add, UpDown, gVerifyTheOptions vsilentHoursA Range0-23, %silentHoursA%
    Gui, Add, Text, x+2 hp +0x200 vtxt2, :00   to
    GuiAddEdit("x+10 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF36", silentHoursB, "End hour.`nAn end before the start hour makes the interval run through midnight.")
    Gui, Add, UpDown, gVerifyTheOptions vsilentHoursB Range0-23, %silentHoursB%
    Gui, Add, Text, x+1 hp +0x200 vtxt3, :59
    Gui, Add, Checkbox, xs y+15 gVerifyTheOptions Checked%noBibleQuoteMhidden% vnoBibleQuoteMhidden, Do not show Bible verses when the mouse cursor is hidden`n(e.g., when watching videos on full-screen)

    Gui, Tab, 4 ; style
    Gui, Add, Text, x+15 y+15 Section, OSD position (x, y)
    GuiAddEdit("xs+" columnBpos2 " ys w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF1", GuiX, "OSD position on X")
    Gui, Add, UpDown, vGuiX gVerifyTheOptions 0x80 Range-9995-9998, %GuiX%
    GuiAddEdit("x+5 w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF2", GuiY, "OSD position on Y")
    Gui, Add, UpDown, vGuiY gVerifyTheOptions 0x80 Range-9995-9998, %GuiY%
    Gui, Add, Button, x+5 w65 hp gLocatePositionA vBtn4, Locate

    Gui, Add, Text, xm+15 ys+30 Section, Margins (top, bottom, sides)
    GuiAddEdit("xs+" columnBpos2 " ys+0 w65 Section geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF11", OSDmarginTop, "Top margin")
    Gui, Add, UpDown, gVerifyTheOptions vOSDmarginTop Range1-900, %OSDmarginTop%
    GuiAddEdit("x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF9 ", OSDmarginBottom, "Bottom margin")
    Gui, Add, UpDown, gVerifyTheOptions vOSDmarginBottom Range1-900, %OSDmarginBottom%
    GuiAddEdit("x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF13", OSDmarginSides, "Sides margin")
    Gui, Add, UpDown, gVerifyTheOptions vOSDmarginSides Range10-900, %OSDmarginSides%

    Gui, Add, Text, xm+15 y+10 Section, Font name
    Gui, Add, Text, xs yp+30, OSD colors and opacity
    Gui, Add, Text, xs yp+30, Font size
    Gui, Add, Text, xs yp+30 hp +0x200, Display time (in sec.)
    Gui, Add, Checkbox, xs yp+30 hp gVerifyTheOptions Checked%showTimeWhenIdle% vshowTimeWhenIdle, Display time when idle
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%displayClock% vdisplayClock, Display time when bells toll
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%constantOSDvisible% vconstantOSDvisible, Always display the OSD
    Gui, Add, Checkbox, xs+%columnBpos2% yp gVerifyTheOptions Checked%displayTimeFormat% vdisplayTimeFormat, 24 hours format
    Gui, Add, Checkbox, xs y+15 h25 +0x1000 gVerifyTheOptions Checked%ShowPreview% vShowPreview, Show preview window
    Gui, Add, Checkbox, xs+%columnBpos2% yp hp gVerifyTheOptions Checked%ShowPreviewDate% vShowPreviewDate, Include current date

    mf := (PrefsLargeFonts=1) ? 170 : 143
    GuiAddDropDownList("xs+" columnBpos2 " ys+0 section w205 gVerifyTheOptions Sort Choose1 vFontName", FontName, "OSD font name")
    hLV1 := GuiAddColor("xp+0 yp+30 w65 h25", "OSDtextColor", "OSD text color")
    hLV2 := GuiAddColor("x+5 wp hp", "OSDbgrColor", "OSD background color")
    GuiAddEdit("x+5 yp+0 w65 hp geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF10", OSDalpha, "OSD opacity")
    Gui, Add, UpDown, vOSDalpha gVerifyTheOptions Range75-255, %OSDalpha%
    GuiAddEdit("xp-140 yp+30 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF5", FontSize, "OSD font size")
    Gui, Add, UpDown, gVerifyTheOptions vFontSize Range12-295, %FontSize%
    GuiAddEdit("xs yp+30 w65 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF6", DisplayTimeUser, "OSD display duration in seconds")
    Gui, Add, UpDown, vDisplayTimeUser gVerifyTheOptions Range1-99, %DisplayTimeUser%
    GuiAddEdit("xp yp+30 w65 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF99", showTimeIdleAfter, "Idle time in minutes")
    Gui, Add, UpDown, vshowTimeIdleAfter gVerifyTheOptions Range1-950, %showTimeIdleAfter%
    Gui, Add, Text, x+5 vtxt100 hp +0x200, idle time (in min.)
    If !FontList._NewEnum()[k, v]
    {
        Fnt_GetListOfFonts()
        FontList := trimArray(FontList)
    }

    Loop, % FontList.MaxIndex()
    {
        fontNameInstalled := FontList[A_Index]
        If (fontNameInstalled ~= "i)(@|oem|extb|symbol|marlett|wst_|glyph|reference specialty|system|terminal|mt extra|small fonts|cambria math|this font is not|fixedsys|emoji|hksc| mdl|wingdings|webdings)") || (fontNameInstalled=FontName)
           Continue

        GuiControl, SettingsGUIA:, FontName, %fontNameInstalled%
    }
    zw := StrSplit(lastUsedGeoLocation, "|")
    ppl := (zw[1] && zw.Count()>4) ? zw[1] : "NONE" 

    Gui, Tab, 5 ; more
    Gui, Add, Text, x+15 y+15 Section +0x200 +hwndhTemp, OSD progress bar line:
    GuiAddDropDownList("x+5 wp+20 gVerifyTheOptions AltSubmit Choose" showOSDprogressBar " vshowOSDprogressBar", "None|Current day|Moon's synodic period|Current month|Astronomical seasons|Current year", [hTemp])
    Gui, Add, Checkbox, xs y+12 gVerifyTheOptions Checked%OSDroundCorners% vOSDroundCorners, Round corners for the OSD
    Gui, Add, Checkbox, xs y+12 gVerifyTheOptions Checked%showMoonPhaseOSD% vshowMoonPhaseOSD, Display the moon illumination fraction (phase)
    Gui, Add, Checkbox, xs y+12 gVerifyTheOptions Checked%overrideOSDcolorsAstro% vOverrideOSDcolorsAstro, Override OSD colors based on:
    GuiAddDropDownList("xp+15 y+5 wp gVerifyTheOptions AltSubmit Choose" OSDastralMode " vOSDastralMode", "Daylight|Moonlight|Moon phase|Automatic", "OSD colors based on")
    Gui, Add, Button, x+5 hp ghelpOSDastroColors, &Help
    Gui, Add, Text, xs+15 y+10 hp +0x200 vtxt200, Astro colors:
    hLV6 := GuiAddColor("x+10 w55 h25", "OSDastroALTcolor", "Daylight color")
    hLV7 := GuiAddColor("x+10 wp hp", "OSDastroALTOcolor", "Moonlight color")
    Gui, Add, Text, xs+15 y+10 hp, Currently defined location:`n%ppl%
    If (A_PtrSize!=8)
       Gui, Add, Text, xs+15 y+10 wp, WARNING: The astronomy features are not available on the 32 bits edition.

    Gui, Add, Text, xs y+10, Analog clock colors:
    hLV8 := GuiAddColor("xs+15 y+5 w55 h25", "clockBgrColor", "Background face color")
    hLV9 := GuiAddColor("x+10 wp hp", "clockFgrColor", "Hands and numbers color")
    hLV10 := GuiAddColor("x+10 wp hp", "clockOutColor", "Exterior color")
    Gui, Add, Button, x+5 hp ghelpAnalogClock, &Info
 
    Gui, Tab
    Gui, Add, Button, xm+0 y+10 w75 h30 Default gApplySettings vApplySettingsBTN, A&pply
    Gui, Add, Button, x+5 wp hp gCloseSettings, C&ancel
    Gui, Add, Button, x+5 w%btnWid% hp gDeleteSettings, R&estore defaults
    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Customize: %appName%
    VerifyTheOptions(0)
    ColorPickerHandles := hLV1 "," hLV2 "," hLV6 "," hLV7 "," hLV8 "," hLV9 "," hLV10
}

helpOSDastroColors() {
    Gui, SettingsGUIA: +OwnDialogs
    MsgBox, , % appName, The defined color will be used when the sun or moon is up in the sky (above the horizon line). Or`, if the user selects the Moon Phase option`, the OSD color will be mixed with the color defined here based on the illumination fraction of the moon. When new moon occurs`, the main OSD color will not be altered.`n`nDaylight and moonlight options rely on the location of the observer on the planet Earth. To define the location use the Astronomy/Today panel.`n`nThe Automatic Mode. In this mode`, the sun and moon altitudes`, and the moon phase`, are used to determine the color of the OSD. If it is night time`, the OSD colour will be based on the moon elevation and illumination fraction. If the moon is below the horizon or if it is a new moon`, the colour of the OSD will not be changed.
}

helpAnalogClock() {
    Gui, SettingsGUIA: +OwnDialogs
    MsgBox, , % appName, The Analog Clock widget can be toggled via the system tray menu of %appName%. To customize the widget`, right-click on the clock.
}

VerifyTheOptions(EnableApply:=1,forceNoPreview:=0) {
    Gui, SettingsGUIA: Default
    GuiControlGet, ShowPreview
    GuiControlGet, markFullMoonHowls
    GuiControlGet, silentHours
    GuiControlGet, tollHours
    GuiControlGet, tollQuarters
    GuiControlGet, AdditionalStrikes
    GuiControlGet, showBibleQuotes
    GuiControlGet, SemantronHoliday
    GuiControlGet, ObserveHolidays
    GuiControlGet, OSDmarginSides
    GuiControlGet, maxBibleLength
    GuiControlGet, BibleQuotesLang
    GuiControlGet, displayClock
    ; the start point of the ordered verses may reach the last verse of the chosen Bible and no
    ; further; the Bibles differ by thousands of verses, so the range follows the language
    Static lastVersesRange := ""
    GuiControlGet, hUpDownVerses, Hwnd, userBibleStartPoint
    If (hUpDownVerses && BibleQuotesLang "|" hUpDownVerses!=lastVersesRange)
    {
       maxVerses := countBibleVerses(BibleQuotesLang)
       If (maxVerses>1)
       {
          lastVersesRange := BibleQuotesLang "|" hUpDownVerses
          SendMessage, 0x046F, 1, % maxVerses,, ahk_id %hUpDownVerses%   ; UDM_SETRANGE32
       }
    }
    GuiControlGet, showOSDprogressBar
    GuiControlGet, constantOSDvisible
    GuiControlGet, showTimeIdleAfter
    GuiControlGet, showTimeWhenIdle
    GuiControlGet, userBibleStartPoint
    GuiControlGet, orderedBibleQuotes
    GuiControlGet, userMuteAllSounds
    GuiControlGet, OSDastralMode
    GuiControlGet, OverrideOSDcolorsAstro
    GuiControlGet, gongAudioVerseDisplay

    appSettingsModified := (EnableApply=0) ? 0 : 1
    GuiControl, % (EnableApply=0 ? "Disable" : "Enable"), ApplySettingsBTN
    GuiControl, % (AdditionalStrikes=0 ? "Disable" : "Enable"), editF38
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF40
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF60
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF73
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Btn2
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Txt4
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Txt10
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), makeScreenDark
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), BibleQuotesLang
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), gongAudioVerseDisplay
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Btn5
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), noBibleQuoteMhidden
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), orderedBibleQuotes
    GuiControl, % (showBibleQuotes=0 || orderedBibleQuotes-1) ? "Disable" : "Enable", userBibleStartPoint
    GuiControl, % (showBibleQuotes=0 || orderedBibleQuotes-1) ? "Disable" : "Enable", editF4
    GuiControl, % (displayClock=0 ? "Disable" : "Enable"), constantOSDvisible
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursA
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursB
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF35
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF36
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt1
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt2
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt3
    GuiControl, % (showTimeWhenIdle=1 ? "Enable" : "Disable"), showTimeIdleAfter
    GuiControl, % (showTimeWhenIdle=1 ? "Enable" : "Disable"), editF99
    GuiControl, % (showTimeWhenIdle=1 ? "Enable" : "Disable"), txt100
    GuiControl, % (OverrideOSDcolorsAstro=1 ? "Enable" : "Disable"), OSDastralMode
    GuiControl, % (OverrideOSDcolorsAstro=1 ? "Show" : "Hide"), OSDastroALTcolor
    GuiControl, % (OverrideOSDcolorsAstro=1 ? "Enable" : "Disable"), txt200
    GuiControl, % (OverrideOSDcolorsAstro=1 && OSDastralMode=4) ? "Show" : "Hide", OSDastroALTOcolor
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), BeepsVolume
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), AutoUnmute
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), dynamicVolume
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), volLevel
    GuiControl, % (tollHours=0 ? "Disable" : "Enable"), tollHoursAmount
    GuiControl, % (tollQuarters=0 ? "Disable" : "Enable"), tollQuartersException
    GuiControl, % (ShowPreview=0 ? "Hide" : "Show"), ShowPreviewDate
    GuiControl, % (ObserveHolidays=0 ? "Disable" : "Enable"), btn3
    GuiControl, % (ObserveHolidays=0 ? "Disable" : "Enable"), SemantronHoliday

    roundCornerSize := Round(FontSize/2) + Round(OSDmarginSides/5)
    If (roundCornerSize<20)
       roundCornerSize := 20

    Static LastInvoked := 1
    If (forceNoPreview=1)
       Return

    If (A_TickCount - LastInvoked>250) || (OSDGuiaVisible=0 && ShowPreview=1)
    || (OSDGuiaVisible=1 && ShowPreview=0)
    {
       If (A_TickCount - LastInvoked>9500)
          DoGuiFader := 1
       LastInvoked := A_TickCount
       ; OSDpreview()
    } 
    SetTimer, OSDpreview, -150
}

trimArray(arr) {
; Hash O(n) 
; Function by errorseven from:
; https://stackoverflow.com/questions/46432447/how-do-i-remove-duplicates-from-an-autohotkey-array
    hash := {}, newArr := []
    For e, v in arr
    {
        If (!hash.Haskey(v))
        {
           hash[(v)] := 1
           newArr.push(v)
        }
    }
    Return newArr
}

MWAGetMonitorMouseIsIn(coordX:=0,coordY:=0) {
; function from: https://autohotkey.com/boards/viewtopic.php?f=6&t=54557
; by Maestr0

  ; get the mouse coordinates first
  MouseGetPos, Mx, My
  If (coordX && coordY)
  {
     Mx := coordX
     My := coordY
  }

  SysGet, MonitorCount, 80  ; monitorcount, so we know how many monitors there are, and the number of loops we need to do
  Loop, %MonitorCount%
  {
      SysGet, mon%A_Index%, Monitor, %A_Index%  ; "Monitor" will get the total desktop space of the monitor, including taskbars

      If (Mx>=mon%A_Index%left) && (Mx<mon%A_Index%right)
      && (My>=mon%A_Index%top) && (My<mon%A_Index%bottom)
      {
         ActiveMon := A_Index
         Break
      }
  }
  Return ActiveMon
}

ScreenBlocker(killNow:=0, darkner:=0, doOnTop:=1, forceIT:=0) {
    Static
    If (killNow=1) || (darkner=1 && makeScreenDark=0 && forceIT=0)
    {
       Gui, ScreenBl: Destroy
       Return
    }

    ActiveMon := MWAGetMonitorMouseIsIn()
    If ActiveMon
    {
       SysGet, mCoord, MonitorWorkArea, %ActiveMon%
       ResolutionWidth := Abs(max(mCoordRight, mCoordLeft) - min(mCoordRight, mCoordLeft))
       ResolutionHeight := Abs(max(mCoordTop, mCoordBottom) - min(mCoordTop, mCoordBottom))
    } Else
    {
       ResolutionWidth := A_ScreenWidth
       ResolutionHeight := A_ScreenHeight
       mCoordLeft := mCoordTop := 1
    }

    blockerAlpha := (darkner=1) ? 130 : 30
    Gui, ScreenBl: Destroy
    Gui, ScreenBl: +AlwaysOnTop -DPIScale -Caption +ToolWindow
    Gui, ScreenBl: Margin, 0, 0
    Gui, ScreenBl: Color, % (darkner=1) ? 221122 : 543210
    Gui, ScreenBl: Show, NoActivate Hide x%mCoordLeft% y%mCoordTop% w%ResolutionWidth% h%ResolutionHeight%, ScreenShader
    WinSet, Transparent, % (darkner=1) ? 1 : 30, ScreenShader
    Gui, ScreenBl: Show, NoActivate, ScreenShader
    If (doOnTop=1)
       WinSet, AlwaysOnTop, On, ScreenShader

    If (darkner=1)
    {
       Gui, ScreenBl: +E0x20
       GuiFader("ScreenShader" MonDest,"show", blockerAlpha)
    }
}

LocatePositionA() {
    ScreenBlocker()
    ToolTip, Move mouse to desired location and click
    KeyWait, LButton, D, T10
    MouseGetPos, mX, mY
    ToolTip
    ScreenBlocker(1)
    GuiControl, SettingsGUIA:, ShowPreview, 1
    GuiControl, SettingsGUIA:, GuiX, %mX%
    GuiControl, SettingsGUIA:, GuiY, %mY%
    DoGuiFader := 0
    VerifyTheOptions()
}

DonateNow() {
   Run, https://www.paypal.me/MariusSucan/10
   CloseWindow()
}
ReplaceNthChar(str, n, char) {
; str  - The original string
; n    - 1-based position of the character to replace
; char - The replacement character (or string)
;
; Returns the modified string, or the original if n is out of bounds.

    strLen := StrLen(str)
    if (n < 1 || n > strLen)
        return str

    l  := SubStr(str, 1, n - 1)
    r := SubStr(str, n + 1)

    return l . char . r
}

CalcTextHorizPrev(txtCenter, txtTotal, addYearMarkers:=1, Barlength:=26) {
   horizProgress := ""
   percA := txtCenter / txtTotal * 100
   perc := Round(Barlength/100 * percA)
   percT := Barlength - perc
;   ToolTip, %perca% -- %perc% -- %percT% -- %txtCenter% -- %txtTotal%
   Loop, %perc%
        horizProgress .= CSmid
   Loop, %percT%
        horizProgress .= CSthin
   If (addYearMarkers=1)
   {
      horizProgress := ReplaceNthChar(horizProgress, 6, "▀")
      horizProgress := ReplaceNthChar(horizProgress, 13, "⬤")
      horizProgress := ReplaceNthChar(horizProgress, 19, "▃")
      horizProgress := ReplaceNthChar(horizProgress, 26, "◯")
      ; horizProgress := ST_Insert("▀", horizProgress, 6)
      ; horizProgress := ST_Insert("⬤", horizProgress, 12)
      ; horizProgress := ST_Insert("▃", horizProgress, 17)
      ; horizProgress := ST_Insert("◯", horizProgress, 24)
   } Else
      horizProgress := ST_Insert("||", horizProgress, Barlength/2+1)

   Return horizProgress
}

ST_Insert(insert,input,pos=1) {
; String Things - Common String & Array Functions, 2014
; by tidbit https://autohotkey.com/board/topic/90972-string-things-common-text-and-array-functions/

  Length := StrLen(input)
  ((pos > 0) ? (pos2 := pos - 1) : (((pos = 0) ? (pos2 := StrLen(input),Length := 0) : (pos2 := pos))))
  output := SubStr(input, 1, pos2) . insert . SubStr(input, pos, Length)
  If (StrLen(output) > StrLen(input) + StrLen(insert))
     ((Abs(pos) <= StrLen(input)/2) ? (output := SubStr(output, 1, pos2 - 1) . SubStr(output, pos + 1, StrLen(input)))
     : (output := SubStr(output, 1, pos2 - StrLen(insert) - 2) . SubStr(output, pos - StrLen(insert), StrLen(input))))
  Return output
}

calcEasterDate(ByRef aisHolidayToday, thisYDay, yearu:=0) {
; yearu is the year thisYDay belongs to. Without it, the year the celebrations list is
; browsing, celebYear, is taken - the list is what that variable is for. The daily tests and
; the calendar name their own year: celebYear is set on start-up and left there, so the Easter
; cycle of the start-up year used to be laid over every other year, and over the new year of
; an instance that stayed up past New Year's Eve.
  If !yearu
     yearu := celebYear

  If (UserReligion=1)
     result := CatholicEaster(yearu)
  Else
     result := OrthodoxEaster(yearu)

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
  {
     aisHolidayToday := (UserReligion=1) ? "Catholic Easter" : "Orthodox Easter"
     aisHolidayToday .= " - the resurrection of the Lord Jesus Christ"
  }
  Return Result
}

OrthodoxEaster(Year) {
; Returns the Orthodox Easter date for the Year in "YYYYMMDD000000" format.
; Function from https://autohotkey.com/board/topic/41342-func-calculating-date-of-christian-easter/
; posted by Art
    i := Year 0301
    i += 21+13+(MOD(19*MOD(Year,19)+16,30)+MOD(2*MOD(Year,4)+4*MOD(Year,7)+6*MOD(19*MOD(Year,19)+16,30),7))-1, days
    RETURN i
}

CatholicEaster(year) {
; function from: https://gist.github.com/hoppfrosch/6882628
; by hoppfrosch

  ; Saekularzahl: K(X) = X div 100 
  k := Floor(year/100)  
  ; saekulare Mondschaltung:  M(K) = 15 + (3K + 3) div 4 - (8K + 13) div 25 
  m := 15 + floor((3 * k + 3)/4) - floor((8 * k + 13)/25)
  ; saekulare Sonnenschaltung: S(K) = 2 - (3K + 3) div 4 
  s := 2 - floor((3 * k + 3)/4)
  ; Mondparameter: A(X) = X mod 19 
  a := Mod(year,19)
  ; Keim fuer den ersten Vollmond im Fruehling:  D(A,M) = (19A + M) mod 30 
  d := Mod((19 * a + m), 30)
  ; kalendarische Korrekturgroesse: R(D,A) = D div 29 + (D div 28 - D div 29) (A div 11)
  r := floor(d/29) + (floor(d/29)-floor(d/28))*floor(a/11)  
  ; Ostergrenze: OG(D,R) = 21 + D - R
  og := 21 + d - r
  ; erster Sonntag im Maerz:  SZ(X,S) = 7 - (X + X div 4 + S) mod 7 
  sz := 7 - Mod((year + Floor(year/4) + s),7)
  ; Osterentfernung in Tagen): OE(OG,SZ) = 7 - (OG - SZ) mod 7 
  oe := 7 - Mod((og - sz),7)
  ; Datum des Ostersonntags als Märzdatum: OS = OG + OE
  os := og + oe
  ; Korrektur um 1 Tag noetig, da man vom 01.03 ausgeht
  os := os - 1

  Result := year 0301
  EnvAdd, Result, %os%, days

  Return Result
}

ashwednesday(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, -46, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=1)
     aisHolidayToday := "Ash Wednesday - first day of Lent; a reminder we were made from dust and we will return to dust"

  return result
}

palmSunday(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, -7, days

  FormatTime, lola, %result%, yday
  ; fnOutputDebug("palmSunday=" thisYday "|" result "|" lola)
  If (lola=thisYDay)
     aisHolidayToday := "Flowery/Palm Sunday - Jesus' triumphal entry into Jerusalem"

  return result
}

goodFriday(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, -2, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
  {
     aisHolidayToday := (UserReligion=1) ? "Good Friday" : "The Great and Holy Friday"
     aisHolidayToday .= " - the crucifixion and death of Jesus Christ"
  }

  return result
}

MaundyT(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, -3, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Maundy Thursday - the washing of the disciples' feet and Last Supper of Jesus Christ"

  return result
}

HolySaturday(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, -1, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Holy Saturday - the day that Jesus' body lay in the tomb"

  return result
}

SecondDayEaster(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 1, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := (UserReligion=1) ? "Catholic Easter Monday" : "Orthodox Easter Monday"

  return result
}

DivineMercy(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 7, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=1)
     aisHolidayToday := "Divine Mercy Sunday - related to His Merciful Divinity and Faustina Kowalska, a Polish Catholic nun"

  return result
}

ascensionday(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 39, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Ascension of the Lord Jesus Christ into Heaven"

  return result
}

pentecost(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 49, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Pentecost - the descent of the Holy Spirit upon the Apostles"

  return result
}

holyTrinityOrthdox(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 50, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=2)
     aisHolidayToday := "The Holy Trinity - celebrates the Christian doctrine of the Trinity, the three Persons of God: the Father, the Son, and the Holy Spirit"

  return result
}

TrinitySunday(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 56, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := (UserReligion=1) ? "Holy Trinity Sunday -  celebrates the Christian doctrine of the Trinity, the three Persons of God: the Father, the Son, and the Holy Spirit" : "All saints day"

  return result
}

corpuschristi(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 60, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=1)
     aisHolidayToday := "Corpus Cristi - the real presence of the Body and Blood of Jesus"

  return result
}

lifeGivingSpring(ByRef aisHolidayToday, thisYDay, yearu:=0) {
  result := calcEasterDate(isHoliday, thisYDay, yearu)
  EnvAdd, result, 5, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=2)
     aisHolidayToday := "The Life-Giving Spring - when Blessed Mary healed a blind man by having him drink water from a spring"

  return result
}

movableFeastsList() {
; The feasts of the Easter cycle: the function that recognises each one, and the name it is
; filed under in the Celebrations section when the user chooses to no longer observe it. The
; celebrations list carries the very same names in the third column of its Easter tab, so
; that a choice made there is the one acted upon here.
   Static listu := "calcEasterDate|easter,SecondDayEaster|eastermonday,DivineMercy|divinemercy,palmSunday|palmsunday,MaundyT|maundythursday,HolySaturday|holysaturday,goodFriday|goodfriday,ashwednesday|ashwednesday,ascensionday|ascension,pentecost|pentecost,TrinitySunday|trinitysunday,corpuschristi|corpuschristi,lifeGivingSpring|lifegivingspring,holyTrinityOrthdox|holytrinity"
   Return listu
}

testCelebrations(noSounds:=0) {
   obju := coreTestCelebrationz(A_Mon, A_MDay, A_YDay, 0, 0, A_Year, noSounds)
   TypeHolidayOccured := obju[1]
   isHolidayToday := obju[2]
}

coreTestCelebrationz(thisMon, thisMDay, thisYDay, isListMode, testWhat, thisYear, noSounds:=0) {
  Critical, On
  testEquiSols()
  If (ObserveHolidays=0 && SemantronHoliday=0)
     Return [0, 0]

  aTypeHolidayOccured := aisHolidayToday := 0
  testFeast := thisMon "." thisMDay
  If (ObserveReligiousDays=1)
  {
     ; The movable feasts, those of the Easter cycle, are each tried for the year of the date
     ; in hand. The feast whose name is given second is the one it is filed under when the
     ; user chooses to no longer observe it - see movableFeastsList() - since the date it
     ; falls on changes from year to year; a feast so filed is dropped again right here.
     Loop, Parse, % movableFeastsList(), `,
     {
        pairu := StrSplit(A_LoopField, "|")
        prevu := aisHolidayToday
        funcu := pairu[1]
        %funcu%(aisHolidayToday, thisYDay, thisYear)
        If (aisHolidayToday!=prevu && StrLen(INIactionNonGlobal(0, pairu[2] ".r", 0, "Celebrations"))>2)
           aisHolidayToday := prevu
     }

     If (testFeast="01.01" && UserReligion=1)
        q := "The commemoration of the Blessed Virgin Mary as Mother of God (Θεοτόκος) as proclaimed in the Council of Ephesus (431 A.D.). It is also the octave of Christmas traditionally commemorating the circumcision of the Lord Jesus Christ"
     Else If (testFeast="01.06")
        q := (UserReligion=1) ? "Epiphany - the revelation of God incarnate as Jesus Christ" : "Theophany - the baptism of Jesus in the Jordan River"
     Else If (testFeast="01.07" && UserReligion=2)
        q := "Synaxis of Saint John the Baptist - a Jewish itinerant preacher, and a prophet"
     Else If (testFeast="01.30" && UserReligion=2)
        q := "The Three Holy Hierarchs - Basil the Great, John Chrysostom and Gregory the Theologian"
     Else If (testFeast="02.02")
        q := "Presentation of the Lord Jesus Christ - at the Temple in Jerusalem to induct Him into Judaism, episode described in the 2nd chapter of the Gospel of Luke"
     Else If (testFeast="03.17" && !aisHolidayToday && UserReligion=1)
       q := "Saint Patrick's Day - He was a 5th-century Romano-British Christian missionary and Bishop in Ireland."
     Else If (testFeast="03.19" && !aisHolidayToday && UserReligion=1)
       q := "Saint Joseph's Day - Spouse of the Blessed Virgin Mary and legal father of the Lord Jesus Christ"
     Else If (testFeast="03.25" && !aisHolidayToday)
        q := "Annunciation of the Lord Jesus Christ - when the Blessed Virgin Mary was told she would conceive and become the mother of Jesus of Nazareth"
     Else If (testFeast="04.23" && !aisHolidayToday)
        q := "Saint George - a Roman soldier of Greek origin under the Roman emperor Diocletian, sentenced to death for refusing to recant his Christian faith, venerated as a military saint since the Crusades."
     Else If (testFeast="06.24")
        q := "Birth of Saint John the Baptist - a Jewish itinerant preacher, and a prophet known for having anticipated a messianic figure greater than himself"
     Else If (testFeast="06.29")
        q := "Solemnity of the Apostles Peter and Paul - a feast in honour of the martyrdom in Rome of the apostles Saint Peter and Saint Paul"
     Else If (testFeast="08.06")
        q := "Feast of the Transfiguration of the Lord Jesus Christ - when He becomes radiant in glory upon Mount Tabor"
     Else If (testFeast="08.15")
        q := (UserReligion=1) ? "Assumption of the Blessed Virgin Mary - her body and soul are assumed into heavenly glory after her death" : "Dormition of the Blessed Virgin Mary - her body and soul are assumed into heavenly glory after her death"
     Else If (testFeast="08.29")
        q := "Beheading of Saint John the Baptist - killed on the orders of Herod Antipas through the vengeful request of his step-daughter Salomé and her mother Herodias"
     Else If (testFeast="09.08")
        q := "Birth of the Blessed Virgin Mary - according to an apocryphal writing, her parents are known as Saint Anne and Saint Joachim"
     Else If (testFeast="09.14")
        q := "Exaltation of the Holy Cross - the recovery of the cross on which Jesus Christ was crucified by the Roman government on the order of Pontius Pilate"
     Else If (testFeast="10.01" && UserReligion=2)
        q := "The Protection of Our Most Holy Lady (Virgin Mary) - a celebration of the protection offered by Saint Mary to mankind"
     Else If (testFeast="10.04" && UserReligion=1)
        q := "Saint Francis of Assisi - an Italian friar, deacon, preacher and founder of the Friar Minors (OFM) within the Catholic church who lived between 1182 and 1226"
     Else If (testFeast="10.12" && UserReligion=1)
        q := "Our Lady of the Pillar - Virgin Mary appeared to the Apostle James the Greater in AD 40, in Spain, while being alive in Jerusalem. It is considered the first Marian apparition and the only recorded instance of Mary exhibiting the mystical phenomenon of bilocation"
     Else If (testFeast="10.14" && UserReligion=2)
        q := "Saint Paraskeva of the Balkans - an ascetic female saint of the 11th century, born in Epivates, Thrace, venerated as the protector of Moldavia"
     Else If (testFeast="10.31" && UserReligion=1)
        q := "All Hallows' Eve - the eve of the Solemnity of All Saints"
     Else If (testFeast="11.01" && UserReligion=1)
        q := "All Saints' day - a commemoration day for all Christian saints"
     Else If (testFeast="11.02" && UserReligion=1)
        q := "All souls' day - a commemoration day of all the faithful departed"
     Else If (testFeast="11.21")
        q := "Presentation of the Blessed Virgin Mary - when she was brought, as a child, to the Temple in Jerusalem to be consecrated to God"
     Else If (testFeast="12.08" && UserReligion=1)
        q := "Immaculate Conception of the Blessed Virgin Mary - a celebration of her sinless lifespan. It is believed she was conceived without the original sin. This is celebrated nine months before the feast of the Nativity of Mary, on the 8th of September"
     Else If (testFeast="12.06")
        q := "Saint Nicholas' Day - an early Christian bishop of Greek origins from 270 - 342 AD, known as the bringer of gifts for the poor"
     Else If (testFeast="12.24")
        q := "Christmas Eve"
     Else If (testFeast="12.25")
        q := "Christmas day - the birth of Jesus Christ in Bethlehem"
     Else If (testFeast="12.26")
        q := (UserReligion=2) ? "Christmas - 2nd day" : "Saint Stephen's Day - a deacon honoured as the first Christian martyr who was stoned to death in 36 A.D. (Acts 7:55-60). Second day of Christmastide"
     Else If (testFeast="12.28" && UserReligion=1)
        q := "Feast of the Holy Innocents - in remembrance of the young children killed in Bethlehem by King Herod the Great in his attempt to kill the infant Jesus of Nazareth"

     ; a fixed feast the user chose to no longer observe is filed under its date; the movable
     ; ones were settled above, so only the fixed feast of this date is dropped here, where
     ; the marker used to wipe out a movable feast landing on the same date as well
     If (q && StrLen(INIactionNonGlobal(0, testFeast ".r", 0, "Celebrations"))>2)
        q := ""

     If (q && aisHolidayToday)
        aisHolidayToday := aisHolidayToday ". | ✝ " q
     Else
        aisHolidayToday := q ? q : aisHolidayToday
     If (StrLen(aisHolidayToday)>2)
        aTypeHolidayOccured := 1
  }

  If (testWhat=1)
     Return [aTypeHolidayOccured, aisHolidayToday]

  If (testWhat=2)
     aisHolidayToday := aTypeHolidayOccured := ""

  If (ObserveSecularDays=1)
  {
     Static theList := "New Year's Day - Happy New Year!|01.01`n"
        . "International Day of Commemoration of the Holocaust victims from World War II|01.27`n"
        . "Saint Valentine's Day - the celebration of love and affection|02.14`n"
        . "Leap Year Day - February is extended by one day every four years to keep the calendar year synchronized with the astronomical year|02.29`n"
        . "International Women's Day|03.08`n"
        . "International Day for the Elimination of Racial Discrimination|03.21`n"
        . "World Autism Awareness Day|04.02`n"
        . "Earth Day|04.22`n"
        . "International Workers' Day [Labor Day]|05.01`n"
        . "International Day of Light|05.16`n"
        . "World Environment Day|06.05`n"
        . "Nelson Mandela International Day - he was a South African anti-apartheid revolutionary, political leader, and philanthropist who served as President of South Africa|07.18`n"
        . "International Day of Friendship|07.30`n"
        . "International Youth Day|08.12`n"
        . "International Day for the Remembrance of the Slave Trade and its Abolition|08.23`n"
        . "International Literacy Day|09.08`n"
        . "International Day of Peace|09.21`n"
        . "International Day for Universal Access to Information - the right of everyone to seek, receive and impart information|09.28`n"
        . "Armistice Day (also Remembrance Day or Veterans Day) - recalling the victims of World War I|11.11`n"
        . "International Day for Tolerance|11.16`n"
        . "International Day for the Elimination of Violence against Women|11.25`n"
        . "International Day of Disabled Persons - the largest minority of the world|12.03`n"
        . "Human Rights Day|12.10`n"
        . "World Arabic Language Day|12.18"

     ; a secular day the user chose to no longer observe is filed under its date with the «s»
     ; marker - see ActionListViewKBDs(); it is left out here, before it can take the place of
     ; the religious feast of the same date
     NoSecDay := INIactionNonGlobal(0, testFeast ".s", 0, "Celebrations")
     If (StrLen(NoSecDay)<3)
     {
        Loop, Parse, theList, `n, `r
        {
           lineArr := StrSplit(A_LoopField, "|")
           miniDate := lineArr[2]
           If (miniDate=testFeast && (PreferSecularDays=1 || !aisHolidayToday))
           {
              aTypeHolidayOccured := 2
              aisHolidayToday := lineArr[1]
              Break
           }
        }
     }
  }

  If (testWhat=2)
     Return [aTypeHolidayOccured, aisHolidayToday]

  If (testWhat=3)
     aisHolidayToday := aTypeHolidayOccured := ""

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
  } Else PersonalDay := ""

  If (isListMode=0)
     OSDprefix := ""

  If (testWhat=3)
     Return [aTypeHolidayOccured, aisHolidayToday]

  If (StrLen(aisHolidayToday)>2 && ObserveHolidays=1 && isListMode=0)
  {
     OSDprefix := (aTypeHolidayOccured=3) ? "▦ " : "✝ "
     If (aTypeHolidayOccured=2) ; secular
        OSDprefix := "▣ "

     ; ToolTip, % OSDprefix "== lol" , , , 2
     If (AnyWindowOpen!=1 && AnyWindowOpen!=6 && windowManageCeleb!=1)
     {
        Gui, ShareBtnGui: Destroy
        CreateBibleGUI(aisHolidayToday, 1, OSDprefix generateDateTimeTxt(1, 3))
        Gui, ShareBtnGui: Destroy
        quoteDisplayTime := StrLen(aisHolidayToday) * 356
        If (noSounds!=1)
        {
            If (InStr(aisHolidayToday, "Christmas") && !InStr(aisHolidayToday, "octave"))
               MCXI_Play(SNDmedia_christmas)
            Else If (InStr(aisHolidayToday, "arabic") && ObserveReligiousDays=1 && ObserveSecularDays=1)
               MCXI_Play(SNDmedia_surah)
            Else If (InStr(aisHolidayToday, "armistice") && ObserveSecularDays=1)
               MCXI_Play(SNDmedia_armistice)
            Else
               strikeJapanBell()
            Sleep, 100
        }
        SetTimer, DestroyBibleGui, % -quoteDisplayTime
     }
  }

  Return [aTypeHolidayOccured, aisHolidayToday]
}

OpenListCelebrationsBtn() {
  celebYear := A_Year
  If (PrefOpen=1 && hSetWinGui)
     VerifyTheOptions()

  PanelManageCelebrations()
}

BTNimportCalendarEvents() {
  Gui, CelebrationsGuia: +OwnDialogs
  FileSelectFile, filu, 3, % A_WorkingDir, Import calendar events, CBT calendar (*.clbt)
  If ErrorLevel
     Return

  ll := 0
  FileRead, content, % filu
  ; chr := SubStr(content, 1, 1)
  Loop, Parse, content, `n`r
  {
      pp := StrSplit(A_LoopField, CSmid)
      zz := StrSplit(pp[1], ".")
      okay := (StrLen(zz[1])=2 && StrLen(zz[2])=2 && StrLen(zz[3])>0 && StrLen(zz[3])<5) ? 1 : 0
      ; fnOutputDebug(chr " | " okay " | " pp[1] " | " pp[2] " | " zz[1])
      If (StrLen(pp[2])>2 && okay=1)
      {
         INIactionNonGlobal(1, pp[1], pp[2], "Celebrations")
         ll++
      }
  }

  GuiControl, CelebrationsGuia: Choose, CurrentTabLV, 4
  updateHolidaysLVs()
  If ll 
  {
     Tooltip, Imported %ll% events.
     SetTimer, removeTooltip, -1500
  }
}

BTNexportCalendarEvents() {
  ; to-do todo use FileSelectFile, not the special function
  obju := listUserDefinedCelebrations()
  listum := obju[1]
  ll := obju[2]
  Gui, CelebrationsGuia: +OwnDialogs
  If (!ll)
  {
     MsgBox, , % appName, No user defined events identified. Nothing to export.
     Return
  }

  FileSelectFile, file2save, 18, % A_WorkingDir "\personal-events", Export user defined events, CBT calendar (*.clbt)
  ; file2save := saveFileDialogWrapper("S", "PathMustExist", A_ScriptDir "\personal-events", "Export the list of user defined events", "User-defined celebrations (*.clbt)|All (*.*)", 1, 1)
  If (!RegExMatch(file2save, "i)(.\.clbt)$") && file2save)
     file2save .= ".clbt"

  If !file2save
     Return

  FileSetAttrib, -R, %file2save%
  Sleep, 5
  Try FileDelete, %file2save%
  Sleep, 5
  Try FileAppend, % listum, % file2save, UTF-8
  Catch wasError
  {
        MsgBox, , % appName, Failed to save to file the user deefined events. Access denied? Please try again.
        Return
  } 

  ToolTip, Saved to file succesfully.
  SoundBeep 900, 100
  SetTimer, removeTooltip, -500
}

PanelManageCelebrations(tabChoice:=1) {
  Global LViewEaster, LViewOthers, LViewSecular, LViewPersonal, CurrentTabLV, ResetYearBTN
  If (AnyWindowOpen && PrefOpen!=1)
     CloseWindow()

  Gui, CelebrationsGuia: Destroy
  Sleep, 15
  Gui, CelebrationsGuia: Default
  Gui, CelebrationsGuia: -MaximizeBox -MinimizeBox +hwndhCelebsMan
  Gui, CelebrationsGuia: Margin, 15, 15
  applyDarkMode2guiPre(hCelebsMan)
  relName := (UserReligion=1) ? "Catholic" : "Orthodox"
  lstWid := 435
  If (PrefsLargeFonts=1)
  {
     lstWid := lstWid + 245
     Gui, Font, s%LargeUIfontValue%
  }

  doResetGuiFont()
  windowManageCeleb := 1
  Gui, Add, Checkbox, x15 y10 gupdateOptionsLVsGui Checked%ObserveReligiousDays% vObserveReligiousDays, Observe religious feasts / holidays
  GuiAddDropDownList("x+2 w100 gupdateOptionsLVsGui AltSubmit Choose" UserReligion " vUserReligion", "Catholic|Orthodox", "Religion",,"CelebrationsGuia")
  btnWid := (PrefsLargeFonts=1) ? 71 : 48
  lstWid2 := lstWid - (btnWid)*3
  Gui, Add, Button, x+10 gPanelAddNewCalendarEvent w%btnWid% hp +hwndhTemp, &Add
  ToolTip2ctrl(hTemp, "Define a new personal event or celebration.")
  Gui, Add, Button, x+5 gBTNimportCalendarEvents wp hp +hwndhTemp, &Import
  ToolTip2ctrl(hTemp, "Import personal events or celebrations.")
  Gui, Add, Button, x+5 gBTNexportCalendarEvents wp hp +hwndhTemp, &Export
  ToolTip2ctrl(hTemp, "Export personal events or celebrations.")
  Gui, Add, Tab3, xs y+10 AltSubmit Choose%tabChoice% vCurrentTabLV, Religious|Easter related|Secular|Personal
  rz := (PrefsLargeFonts=1) ? 9 : 11
  Gui, Tab, 1
  GuiAddListView("y+10 w" lstWid " gActionListViewKBDs -multi ReadOnly r" rz " Grid NoSort -Hdr vLViewOthers", "Date|Details|Indexed date", "Religious celebrations", "CelebrationsGuia")
  Gui, Tab, 2
  GuiAddListView("y+10 w" lstWid " gActionListViewKBDs -multi ReadOnly r" rz " Grid NoSort -Hdr vLViewEaster", "Date|Details|Indexed date", "Easter related celebrations", "CelebrationsGuia")
  Gui, Tab, 3
  GuiAddListView("y+10 w" lstWid " gActionListViewKBDs -multi ReadOnly r" rz " Grid NoSort -Hdr vLViewSecular", "Date|Details|Indexed date", "Secular celebrations", "CelebrationsGuia")
  Gui, Tab, 4
  GuiAddListView("y+10 w" lstWid " gActionListViewKBDs -multi ReadOnly r" rz " Grid NoSort -Hdr vLViewPersonal", "Date|Details|Indexed date", "User defined celebrations", "CelebrationsGuia")

  Gui, Tab
  Gui, Add, Checkbox, y+15 Section gupdateOptionsLVsGui Checked%ObserveSecularDays% vObserveSecularDays, Observe secular events
  Gui, Add, Checkbox, x+5 gupdateOptionsLVsGui Checked%PreferSecularDays% vPreferSecularDays, Prefer these events over religious ones

  btnWid := (PrefsLargeFonts=1) ? 55 : 45
  If (PrefOpen=1 && hSetWinGui)
     Gui, Add, Button, xs y+15 w%btnWid% h30 gCloseCelebListWin, &Back
  Else
     Gui, Add, Button, xs y+15 w%btnWid% h30 gPanelIncomingCelebrations, &Back

  btnWid := (PrefsLargeFonts=1) ? 42 : 32
  GuiAddButton("x+5 w" btnWid " h30 gPrevYearList", "<", "Previous year", 0, "CelebrationsGuia")
  Gui, Add, Button, x+1 wp+15 hp gResetYearList vResetYearBTN +hwndhTemp, %celebYear%
  ToolTip2ctrl(hTemp, "Reset to current year")
  GuiAddButton("x+1 wp-15 hp gNextYearList", ">", "Next year", 0, "CelebrationsGuia")
  applyDarkMode2winPost("CelebrationsGuia", hCelebsMan)
  Gui, Show, AutoSize, Celebrations list: %appName%
  updateOptionsLVsGui()
  If (PrefOpen=1 && hSetWinGui)
     SetTimer, AutoDestroyCelebList, 200
}

updateOptionsLVsGui() {
  Gui, CelebrationsGuia: Default
  GuiControlGet, ObserveSecularDays
  GuiControlGet, ObserveReligiousDays
  GuiControlGet, PreferSecularDays
  GuiControlGet, UserReligion

  GuiControl, % ((ObserveReligiousDays=0) ? "Disable" : "Enable"), UserReligion
  GuiControl, % ((ObserveSecularDays=0) ? "Disable" : "Enable"), PreferSecularDays
  INIaction(1, "ObserveSecularDays", "SavedSettings")
  INIaction(1, "ObserveReligiousDays", "SavedSettings")
  INIaction(1, "PreferSecularDays", "SavedSettings")
  INIaction(1, "UserReligion", "SavedSettings")
  updateHolidaysLVs()
}

updateHolidaysLVs() {
  Static MaterDei := "01.01"
  , Epiphany := "01.06"
  , SynaxisSaintJohnBaptist := "01.07"
  , ThreeHolyHierarchs := "01.30"
  , PresentationLord := "02.02"
  , SaintPatrick := "03.17"
  , SaintJoseph := "03.19"
  , AnnunciationLord := "03.25"
  , SaintGeorge := "04.23"
  , BirthJohnBaptist := "06.24"
  , SsPeterAndPaul :="06.29"
  , FeastTransfiguration := "08.06"
  , AssumptionVirginMary := "08.15"
  , BeheadingJohnBaptist := "08.29"
  , BirthVirginMary := "09.08"
  , ExaltationHolyCross := "09.14"
  , ProtectSaintMary := "10.01"
  , SaintFrancisAssisi := "10.04"
  , LadyPilar := "10.12"
  , SaintParaskeva := "10.14"
  , HalloweenDay := "10.31"
  , Allsaintsday := "11.01"
  , Allsoulsday := "11.02"
  , PresentationVirginMary := "11.21"
  , SaintNicola := "12.06"
  , ImmaculateConception := "12.08"
  , ChristmasEve := "12.24"
  , Christmasday := "12.25"
  , Christmas2nday := "12.26"
  , FeastHolyInnocents := "12.28"

  Gui, CelebrationsGuia:Default
  Gui, CelebrationsGuia:ListView, LViewEaster
  LV_Delete()
  Gui, CelebrationsGuia:ListView, LViewOthers
  LV_Delete()
  Gui, CelebrationsGuia:ListView, LViewSecular
  LV_Delete()
  Gui, CelebrationsGuia:ListView, LViewPersonal
  LV_Delete()
  easterdate := calcEasterDate(isHoliday, A_YDay)
  2ndeasterdate := SecondDayEaster(isHoliday, A_YDay)
  divineMercyDate := DivineMercy(isHoliday, A_YDay)
  palmdaydate := palmSunday(isHoliday, A_YDay)
  maundydate := MaundyT(isHoliday, A_YDay)
  HolySaturdaydate := HolySaturday(isHoliday, A_YDay)
  goodFridaydate := goodFriday(isHoliday, A_YDay)
  ashwednesdaydate := ashwednesday(isHoliday, A_YDay)
  ascensiondaydate := ascensionday(isHoliday, A_YDay)
  pentecostdate := pentecost(isHoliday, A_YDay)
  TrinitySundaydate := TrinitySunday(isHoliday, A_YDay)
  corpuschristidate := corpuschristi(isHoliday, A_YDay)
  lifeSpringDate := lifeGivingSpring(isHoliday, A_YDay)
  holyTrinityOrthdoxDate := holyTrinityOrthdox(isHoliday, A_YDay)

  If (UserReligion=1 && ObserveReligiousDays=1)
  {
     ; the third field names the feast - see movableFeastsList(); the user's choice to no
     ; longer observe one of these is filed under that name, since the date changes every year
     theList := "Ash Wednesday|" ashwednesdaydate "|ashwednesday`n"
        . "Palm Sunday|" palmdaydate "|palmsunday`n"
        . "Maundy Thursday|" maundydate "|maundythursday`n"
        . "Good Friday|" goodFridaydate "|goodfriday`n"
        . "Holy Saturday|" HolySaturdaydate "|holysaturday`n"
        . "Catholic Easter|" easterdate "|easter`n"
        . "Catholic Easter - Monday|" 2ndeasterdate "|eastermonday`n"
        . "Divine Mercy|" divineMercyDate "|divinemercy`n"
        . "Ascension of Jesus|" ascensiondaydate "|ascension`n"
        . "Pentecost|" pentecostdate "|pentecost`n"
        . "Trinity Sunday|" TrinitySundaydate "|trinitysunday`n"
        . "Corpus Christi|" corpuschristidate "|corpuschristi"

     Gui, ListView, LViewEaster
     processHolidaysList(theList, ".r")
     Static theList2 := "Divine Maternity of the Blessed Virgin Mary|" MaterDei "`n"
        . "Epiphany|" Epiphany "`n"
        . "Presentation of the Lord Jesus Christ|" PresentationLord "`n"
        . "Saint Patrick's Day|" SaintPatrick "`n"
        . "Saint Joseph's Day|" SaintJoseph "`n"
        . "Annunciation of the Blessed Virgin Mary|" AnnunciationLord "`n"
        . "Saint George|" SaintGeorge "`n"
        . "Birth of Saint John the Baptist|" BirthJohnBaptist "`n"
        . "Solemnity of Saints Peter and Paul|" SsPeterAndPaul "`n"
        . "Transfiguration of the Lord Jesus Christ|" FeastTransfiguration "`n"
        . "Assumption of the Blessed Virgin Mary|" AssumptionVirginMary "`n"
        . "Beheading of Saint John the Baptist|" BeheadingJohnBaptist "`n"
        . "Birth of the Blessed Virgin Mary|" BirthVirginMary "`n"
        . "Exaltation of the Holy Cross|" ExaltationHolyCross "`n"
        . "Saint Francis of Assisi|" SaintFrancisAssisi "`n"
        . "Our Lady of the Pillar|" LadyPilar "`n"
        . "All Hallows' Eve [Hallowe'en]|" HalloweenDay "`n"
        . "All Saints' day|" Allsaintsday "`n"
        . "All souls' day|" Allsoulsday "`n"
        . "Presentation of the Blessed Virgin Mary|" PresentationVirginMary "`n"
        . "Saint Nicholas Day|" SaintNicola "`n"
        . "Immaculate Conception of the Blessed Virgin Mary|" ImmaculateConception "`n"
        . "Christmas Eve|" ChristmasEve "`n"
        . "Christmas|" Christmasday "`n"
        . "Saint Stephen's Day|" Christmas2nday "`n"
        . "Feast of the Holy Innocents|" FeastHolyInnocents

     Gui, ListView, LViewOthers
     processHolidaysList(theList2, ".r")
  } Else If (UserReligion=2 && ObserveReligiousDays=1)
  {
     ; the third field names the feast - see movableFeastsList(); the user's choice to no
     ; longer observe one of these is filed under that name, since the date changes every year
     theList3 := "Flowery Sunday|" palmdaydate "|palmsunday`n"
        . "Maundy Thursday|" maundydate "|maundythursday`n"
        . "Holy Friday|" goodFridaydate "|goodfriday`n"
        . "Holy Saturday|" HolySaturdaydate "|holysaturday`n"
        . "Orthodox Easter|" easterdate "|easter`n"
        . "Orthodox Easter - Monday|" 2ndeasterdate "|eastermonday`n"
        . "Life-Giving Spring|" lifeSpringDate "|lifegivingspring`n"
        . "Ascension of Jesus|" ascensiondaydate "|ascension`n"
        . "Pentecost|" pentecostdate "|pentecost`n"
        . "Holy Trinity|" holyTrinityOrthdoxDate "|holytrinity`n"
        . "All Saints' day|" TrinitySundaydate "|trinitysunday"

     Gui, ListView, LViewEaster
     processHolidaysList(theList3, ".r")

     Static theList4 := "Theophany|" Epiphany "`n"
        . "Synaxis of Saint John the Baptist|" SynaxisSaintJohnBaptist "`n"
        . "The Three Holy Hierarchs|" ThreeHolyHierarchs "`n"
        . "Presentation of the Lord Jesus Christ|" PresentationLord "`n"
        . "Annunciation of the Blessed Virgin Mary|" AnnunciationLord "`n"
        . "Saint George|" SaintGeorge "`n"
        . "Birth of Saint John the Baptist|" BirthJohnBaptist "`n"
        . "Solemnity of Saints Peter and Paul|" SsPeterAndPaul "`n"
        . "Transfiguration of the Lord Jesus Christ|" FeastTransfiguration "`n"
        . "Dormition of the Blessed Virgin Mary|" AssumptionVirginMary "`n"
        . "Beheading of Saint John the Baptist|" BeheadingJohnBaptist "`n"
        . "Birth of the Blessed Virgin Mary|" BirthVirginMary "`n"
        . "Exaltation of the Holy Cross|" ExaltationHolyCross "`n"
        . "The Protection of Our Most Holy Lady Virgin Mary|" ProtectSaintMary "`n"
        . "Saint Paraskeva of the Balkans|" SaintParaskeva "`n"
        . "Presentation of the Blessed Virgin Mary|" PresentationVirginMary "`n"
        . "Saint Nicholas Day|" SaintNicola "`n"
        . "Christmas Eve|" ChristmasEve "`n"
        . "Christmas|" Christmasday "`n"
        . "Christmas - 2nd day|" Christmas2nday

     Gui, ListView, LViewOthers
     processHolidaysList(theList4, ".r")
  } Else
  {
     response := "-- { religious holidays are not observed } --"
     Gui, ListView, LViewOthers
        LV_Add(1, response)
     Gui, ListView, LViewEaster
        LV_Add(1, response)
  }

  Gui, ListView, LViewSecular
  If (ObserveSecularDays=1)
  {
     Static theListS := "New Year's Day|01.01`n"
       . "Commemoration of the Holocaust victims|01.27`n"
       . "Saint Valentine's Day|02.14`n"
       . "Leap Year Day|02.29`n"
       . "International Women's Day|03.08`n"
       . "Elimination of Racial Discrimination|03.21`n"
       . "World Autism Awareness Day|04.02`n"
       . "Earth Day|04.22`n"
       . "Workers' Day / Labor Day|05.01`n"
       . "International Day of Light|05.16`n"
       . "World Environment Day|06.05`n"
       . "Nelson Mandela International Day|07.18`n"
       . "Friendship Day|07.30`n"
       . "International Youth Day|08.12`n"
       . "Remembrance of the Slave Trade and its Abolition|08.23`n"
       . "Literacy Day|09.08`n"
       . "International Day of Peace|09.21`n"
       . "Universal Access to Information Day|09.28`n"
       . "Armistice Day / Remembrance Day / Veterans Day|11.11`n"
       . "Tolerance Day|11.16`n"
       . "Elimination of Violence Against Women|11.25`n"
       . "International Day of Disabled Persons|12.03`n"
       . "Human Rights Day|12.10`n"
       . "World Arabic Language Day|12.18"
     processHolidaysList(theListS, ".s")
  } Else
  {
     response := "-- { secular holidays are not observed } --"
     LV_Add(1, response)
  }

  Gui, ListView, LViewPersonal
  CheckDay := 0
  CheckMonth := "01"
  Loop, 400
  {
     CheckDay++
     If (CheckDay>31)
     {
        CheckDay := "01"
        CheckMonth++
        If (CheckMonth<10)
           CheckMonth := "0" CheckMonth
     } Else If (CheckDay<10)
        CheckDay := "0" CheckDay

     PersonalDate := celebYear CheckMonth CheckDay 010101
     FormatTime, PersonalDate, %PersonalDate%, LongDate
     If (StrLen(PersonalDate)<3)
        Continue

     testFeast := CheckMonth "." CheckDay
     PersonalDay := INIactionNonGlobal(0, testFeast ".a", 0, "Celebrations")
     dayum := INIactionNonGlobal(0, testFeast "." celebYear, 0, "Celebrations")
     If (StrLen(PersonalDay)>2 || StrLen(dayum)>2)
     {
        If (StrLen(PersonalDay)>2)
           LV_Add(A_Index, PersonalDate, PersonalDay, testFeast ".a")
        If (StrLen(dayum)>2)
           LV_Add(A_Index, PersonalDate, dayum, testFeast "." celebYear)

        loopsOccured++
     }
  }

  If (loopsOccured<1)
     LV_Add(1,"-- { no personal entries added } --")

  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (loopsOccured>0)
     LV_ModifyCol(3, 1)

  Gui, ListView, LViewEaster
  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (ObserveReligiousDays=1)
     LV_ModifyCol(3, 1)
  Gui, ListView, LViewOthers
  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (ObserveReligiousDays=1)
     LV_ModifyCol(3, 1)

  Gui, ListView, LViewSecular
  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (ObserveSecularDays=1)
     LV_ModifyCol(3, 1)

  GuiControl, CelebrationsGuia:, ResetYearBTN, %celebYear%
}

PanelAddNewCalendarEvent() {
  Global newDay, newMonth, newEvent, uiCalendarNewAllYears
  Gui, CelebrationsGuia: Destroy
  Sleep, 15
  Gui, CelebrationsGuia: Default
  Gui, CelebrationsGuia: -MaximizeBox -MinimizeBox +hwndhCelebsMan
  Gui, CelebrationsGuia: Margin, 15, 15
  applyDarkMode2guiPre(hCelebsMan)
  If (PrefsLargeFonts=1)
     Gui, Font, s%LargeUIfontValue%

  doResetGuiFont()
  windowManageCeleb := 2
  btnWid := (PrefsLargeFonts=1) ? 125 : 90
  drpWid := (PrefsLargeFonts=1) ? 75 : 50
  drpWid2 := (PrefsLargeFonts=1) ? 125 : 100
  Gui, Add, Text, x15 y10 Section, Please enter the day month, and event name.
  GuiAddDropDownList("y+10 Choose" A_MDay " w" drpWid " vnewDay", "01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31", "Day of month",, "CelebrationsGuia")
  GuiAddDropDownList("x+5 Choose" A_Mon " w" drpWid2 " vnewMonth", "01 January|02 February|03 March|04 April|05 May|06 June|07 July|08 August|09 September|10 October|11 November|12 December", "Month of year",, "CelebrationsGuia")
  GuiAddEdit("xs y+7 w400 r1 limit90 -multi -wantReturn -wantTab -wrap vnewEvent", "", "Event name", "CelebrationsGuia")
  Gui, Add, Checkbox, y+10 Checked1 vuiCalendarNewAllYears, Observe the event every year

  Gui, Add, Button, xs y+15 w%btnWid% h30 Default gSaveNewEntryBtn , &Add entry
  Gui, Add, Button, x+5 wp-25 hp gCancelNewEntryBtn, &Cancel
  applyDarkMode2winPost("CelebrationsGuia", hCelebsMan)
  Gui, Show, AutoSize, Add new celebration: %appName%
  If (PrefOpen=1 && hSetWinGui)
     SetTimer, AutoDestroyCelebList, 200
}

SaveNewEntryBtn() {
  Gui, CelebrationsGuia: Default
  GuiControlGet, newDay
  GuiControlGet, newMonth
  GuiControlGet, newEvent
  GuiControlGet, uiCalendarNewAllYears

  If (StrLen(newEvent)<4)
     wrongThis := 1

  newMonth := SubStr(newMonth, 1,2)
  testYear := (uiCalendarNewAllYears=1) ? 2024 : celebYear
  If (newDay<1 || newDay>calendarDaysInMonth(testYear, newMonth))
     wrongThis := 1

  If (wrongThis=1)
  {
     ToolTip, Wrong date or event name too short.
     SoundBeep, 300, 900
     Sleep, 900
     ToolTip
  } Else
  {
     Gui, CelebrationsGuia: Destroy
     pp := (uiCalendarNewAllYears=1) ? ".a" : "." celebYear
     PersonalDay := INIactionNonGlobal(1, newMonth "." newDay pp, newEvent, "Celebrations")
     Sleep, 200
     PanelManageCelebrations(4)
  }
}

processHolidaysList(theList, typu) {
   Loop, Parse, theList, `n
   {
      lineArr := StrSplit(A_LoopField, "|")
      miniDate := lineArr[2]
      If (StrLen(miniDate)>5)
         miniDate := SubStr(miniDate, 5,2) "." SubStr(miniDate, 7,2)

      StringReplace, rawDate, miniDate, .
      rawDate := celebYear rawDate "010101"
      FormatTime, LongaData, %rawDate%, LongDate
      If (StrLen(LongaData)<3)
         Continue

      idu := lineArr[3] ? lineArr[3] : miniDate
      PersonalDay := INIactionNonGlobal(0, idu typu, 0, "Celebrations")
      byeFlag := (StrLen(PersonalDay)>2) ? "(*) " : ""
      LV_Add(A_Index, byeFlag LongaData, lineArr[1], idu)
   }
}

ActionListViewKBDs() {
  Static lastAsked := 1
  If (A_GuiEvent="DoubleClick")
  {
     Gui, CelebrationsGuia: Default
     GuiControlGet, CurrentTabLV
     If (CurrentTabLV=1)
        Gui, CelebrationsGuia:ListView, LViewOthers
     Else If (CurrentTabLV=2)
        Gui, CelebrationsGuia:ListView, LViewEaster
     Else If (CurrentTabLV=3)
        Gui, CelebrationsGuia:ListView, LViewSecular
     Else If (CurrentTabLV=4)
        Gui, CelebrationsGuia:ListView, LViewPersonal

     LV_GetText(dateSelected, A_EventInfo, 3)
     LV_GetText(eventusName, A_EventInfo, 2)
     If (eventusName="Details" || !eventusName || !dateSelected || StrLen(dateSelected)>24)
        Return

     DisableMsg := "default disabled"
     If (CurrentTabLV<4)
     {
        dateSelected := (CurrentTabLV=3) ? dateSelected ".s" : dateSelected ".r"
        PersonalDay := INIactionNonGlobal(0, dateSelected, 0, "Celebrations")
        If (StrLen(PersonalDay)>2)
        {
           reactivate := 1
           questionMsg := "Do you want to begin observing again " eventusName " ?"
        } Else
        {
           reactivate := 2
           questionMsg := "Do you want to no longer observe " eventusName " ?"
        }

        ; questionMsg .= " | " dateSelected
        If (A_TickCount - lastAsked>4000)
        {
           answerPositive := 0
           Gui, CelebrationsGuia: +OwnDialogs
           MsgBox, 36, %appName%, %questionMsg%
           IfMsgBox, Yes
           {
             lastAsked := A_TickCount
             answerPositive := 1
           }
        } Else answerPositive := 1

        If (answerPositive=1)
        {
          If (reactivate=2)
             INIactionNonGlobal(1, dateSelected, "-- { " DisableMsg " } --", "Celebrations")
          Else If (reactivate=1)
             INIactionNonGlobal(1, dateSelected, "-", "Celebrations")
         
          updateHolidaysLVs()
        }
     } Else If (CurrentTabLV=4)
     {
        ; If InStr(eventusName, DisableMsg)
        ;    questionMsg := "Do you want to begin observing again the default celebration ?"
        ; Else
           questionMsg := "Do you want to remove " eventusName " ?"

        If (A_TickCount - lastAsked>2000)
        {
           answerPositive := 0
           Gui, CelebrationsGuia: +OwnDialogs
           MsgBox, 36, %appName%, %questionMsg%
           IfMsgBox, Yes
           {
              lastAsked := A_TickCount
              answerPositive := 1
           }
        } Else answerPositive := 1

        If (answerPositive=1)
        {
           INIactionNonGlobal(1, dateSelected, "-", "Celebrations")
           updateHolidaysLVs()
        }
     }
  }
}

PrevYearList() {
  If (A_Year - celebYear>=10)
     Return

  celebYear--
  updateHolidaysLVs()
}

NextYearList() {
  If (celebYear - A_Year>=10)
     Return

  celebYear++
  updateHolidaysLVs()
}

ResetYearList() {
  If (celebYear=A_Year)
     Return

  celebYear := A_Year
  updateHolidaysLVs()
}

AutoDestroyCelebList() {
  CurrWin := WinExist("A"),
  If (CurrWin=hSetWinGui && PrefOpen=1 && hSetWinGui)
     CloseCelebListWin()
}

CloseCelebListWin() {
   celebYear := A_Year
   hCelebsMan := 0
   Gui, CelebrationsGuia: Default
   If (windowManageCeleb=1)
   {
      GuiControlGet, ObserveSecularDays
      GuiControlGet, ObserveReligiousDays
      GuiControlGet, PreferSecularDays
      GuiControlGet, UserReligion
   }

   SetTimer, AutoDestroyCelebList, Off
   Gui, CelebrationsGuia: Destroy
   Sleep, 50
   If (PrefOpen=1 && hSetWinGui)
   {
      WinActivate, ahk_id %hSetWinGui%
   } Else
   {
      If (windowManageCeleb=1)
      {
         INIaction(1, "ObserveSecularDays", "SavedSettings")
         INIaction(1, "ObserveReligiousDays", "SavedSettings")
         INIaction(1, "PreferSecularDays", "SavedSettings")
         INIaction(1, "UserReligion", "SavedSettings")
      }
      testCelebrations(1)
   }

   If (windowManageCeleb=2)
      mustReopen := 1
   
   windowManageCeleb := 0
   If (mustReopen=1)
      PanelManageCelebrations()
   Else
      startAlarmTimer()
}

CancelNewEntryBtn() {
   celebYear := A_Year
   WinActivate, ahk_id %hSetWinGui%
   Sleep, 50
   PanelManageCelebrations(4)
}

wrapCalculateEquiSolsDates(givenDay) {
  Critical, on
  Static lastInvoked := 1, prevYear := 0, prevBias := -1, prevDay := 0, TZI := [], z := []

  startZeit := A_TickCount
  If (prevDay!=givenDay || prevBias=-1)
  {
     TZI := TZI_GetTimeZoneInformation()
     prevBias := -1 * TZI.TotalCurrentBias
     prevDay := givenDay
  }

  If (InStr(EquiSolsCache, "|") && prevYear!=A_Year)
  {
     arrayu := StrSplit(EquiSolsCache, "|", "`r")
     mEquiDay := arrayu[1]
     mEquiDate := arrayu[2]
     jSolsDay := arrayu[3]
     jSolsDate := arrayu[4]
     sEquiDay := arrayu[5]
     sEquiDate := arrayu[6]
     dSolsDay := arrayu[7]
     dSolsDate := arrayu[8]
     prevYear := arrayu[9]
     If (arrayu[10]!=prevBias)
        prevYear := 0
  }

  If (prevYear!=A_Year)
  {
     answered := 0
     Loop, 4
     {
         k := calculateEquiSols(A_Index, A_Year)
         If (StrLen(k)!=14)
         {
            ; no DLL to ask - the 32 bits edition, or a library that failed to load; a blank
            ; stamp would have FormatTime answer with today, and today would then pass for the
            ; event, so the usual date the variable already carries is kept instead
            Continue
         }

         FormatTime, OutputVar, % k, Yday
         thisBias := isInDSTperiod(OutputVar, TZI.DaylightDateYday, TZI.StandardDateYday) ? TZI.Bias + TZI.DaylightBias + TZI.StandardBias : TZI.Bias + TZI.StandardBias
         thisBias := -1*thisBias
         k += thisBias, M
         FormatTime, OutputVar, % k, Yday
         If (A_Index=1 && OutputVar>70)
         {
            mEquiDay := OutputVar
            mEquiDate := k
            answered++
         } Else If (A_Index=2 && OutputVar>165)
         {
            jSolsDay := OutputVar
            jSolsDate := k
            answered++
         } Else If (A_Index=3 && OutputVar>260)
         {
            sEquiDay := OutputVar
            sEquiDate := k
            answered++
         } Else If (A_Index=4 && OutputVar>350)
         {
            dSolsDay := OutputVar
            dSolsDate := k
            answered++
         }
         ; fnOutputDebug(A_Index "=" k "==" OutputVar)
     }

     ; The four defaults these variables carry are the usual dates of the events, give
     ; or take a day. Without the DLL they are what the loop above leaves behind, and
     ; writing them out would hand the next session a table that looks computed and is
     ; not; the year is still marked done, so this is attempted only once per session.
     If (answered=4)
     {
        EquiSolsCache := mEquiDay "|" mEquiDate "|" jSolsDay "|" jSolsDate "|" sEquiDay "|" sEquiDate "|" dSolsDay "|" dSolsDate "|" A_Year "|" prevBias
        INIaction(1, "EquiSolsCache", "SavedSettings")
     }
     prevYear := A_Year
  }

  If (A_TickCount - lastInvoked<9500)
     Return z

  z := []
  z.msg := giveYearDayProximity(mEquiDay, givenDay) . "March equinox."      ; 03 / 20
  If InStr(z.msg, "hide")
     z.msg := giveYearDayProximity(jSolsDay, givenDay) . "June solstice."      ; 06 / 21
  If InStr(z.msg, "hide")
     z.msg := giveYearDayProximity(sEquiDay, givenDay) . "September equinox."  ; 09 / 22
  If InStr(z.msg, "hide")
     z.msg  := giveYearDayProximity(dSolsDay, givenDay) . "December solstice."  ; 12 / 21
  If InStr(z.msg, "hide")
     z.msg := ""

  ; ToolTip, % sEquiDay "==" givenDay , , , 2
  If (mEquiDay=givenDay)
     z.r := 1
  Else If (jSolsDay=givenDay)
     z.r := 2
  Else If (sEquiDay=givenDay)
     z.r := 3
  Else If (dSolsDay=givenDay)
     z.r := 4

  lastInvoked := A_TickCount
  endZeit :=  A_TickCount - startZeit
  ; ToolTip, % endzeit , , , 2
  Return z
}

giveYearDayProximity(givenDay, CurrentDay) {
  If (CurrentDay>givenDay)
  {
      passedDays := CurrentDay - givenDay
      Weeksz := Round(passedDays/7,1)
      If (Weeksz>1)
      {
         If (Round(Weeksz)>Floor(Weeksz))
            Result := Floor(Weeksz)=1 ? "More than a week" : "More than " Floor(Weeksz) " weeks"
         Else
            Result := Floor(Weeksz)=1 ? "One week" : Floor(Weeksz) " weeks"
      } Else If (passedDays>2)
         Result := "Less than a week"

      Result .= " since the "
  } Else
  {
      DaysUntil := givenDay - CurrentDay
      Weeksz := Round(DaysUntil/7,1)
      If (Weeksz>1)
      {
         If (Round(Weeksz)>Floor(Weeksz))
            Result := Floor(Weeksz)=1 ? "More than a week" : "More than " Floor(Weeksz) " weeks"
         Else
            Result := Floor(Weeksz)=1 ? "One week" : Floor(Weeksz) " weeks"
      } Else If (DaysUntil>2)
         Result := "Less than a week"
     Result .= " until the "
  }

  If (Floor(Weeksz)>=4)
     Result := "hide"
  Else If (givenDay=CurrentDay)
     Result := "Now"
  Else If (givenDay=CurrentDay + 1)
     Result := "Tomorrow is the "
   Else If (givenDay=CurrentDay + 2)
     Result := "In two days is the "
  Else If (givenDay=CurrentDay - 1)
     Result := "Yesterday was the "
  Else If (givenDay=CurrentDay - 2)
     Result := "Two days ago was the "

  Return Result
}

testEquiSols() {
  OSDsuffix := ""
  z := wrapCalculateEquiSolsDates(A_YDay)
  If (z.r=1)
     OSDsuffix := " ▀"
  Else If (z.r=2)
     OSDsuffix := " ⬤"
  Else If (z.r=3)
     OSDsuffix := " ▃"
  Else If (z.r=4)
     OSDsuffix := " ◯"

  testFeast := A_Mon "." A_MDay
  If (testFeast="02.29")
     OSDsuffix := " ▒"
}

PanelIncomingCelebrations() {
    If reactWinOpened(A_ThisFunc, 3)
       Return

    GenericPanelGUI(0)
    AnyWindowOpen := 3
    LastWinOpened := A_ThisFunc
    INIaction(1, "LastWinOpened", "SavedSettings")
    btnWid := 100
    txtWid := 360
    Global holiListu, btn1, txtLine
    Gui, Font, c%AboutTitleColor% s20 Bold, Arial, -wrap
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section gTollExtraNoon hwndhBellIcon, %A_ScriptDir%\resources\bell-image.png
    Gui, Add, Text, x+7 y10, %appName%
    Gui, Font, s12 Bold, Arial, -wrap
    Gui, Add, Text, y+4 vtxtLine, Celebrations in the next 30 days.
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
    }

    If (tickTockNoise!=1 && userMuteAllSounds!=1)
       SoundLoop(tickTockSound)

    btnW1 := (PrefsLargeFonts=1) ? 90 : 65
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    Gui, Add, Button, xs+1 y+15 w1 h1, L
    doResetGuiFont()
    GuiAddEdit("xp+1 yp+1 ReadOnly r15 w" txtWid " vholiListu", "---", "Celebrations list")
    Gui, Add, Checkbox, xs y+8 gToggleObsHoliEvents Checked%ObserveHolidays% vObserveHolidays, &Observe feasts`, holidays and other events

    Gui, Add, Button, xs+0 y+20 h%btnH% w%btnW1% Default gOpenListCelebrationsBtn vbtn1, &Manage
    Gui, Add, Button, x+5 hp wp+25 gPanelTodayInfos, &Astronomy
    Gui, Add, Button, x+5 hp wp gPanelCalendarWindow, &Calendar
    Gui, Add, Button, x+5 hp wp-25 gCloseWindow, C&lose
    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Celebrations list: %appName%
    PopulateIncomingCelebs()
}

ToggleObsHoliEvents() {
    Gui, SettingsGUIA: Default
    GuiControlGet, ObserveHolidays
    INIaction(1, "ObserveHolidays", "SavedSettings")
    PopulateIncomingCelebs()
}

coreUpcomingEvents(doToday, dayzCheck, limitList) {
    startDate := listu := ""
    If (StrLen(isHolidayToday)>2 && ObserveHolidays=1 && doToday=1)
    {
       relName := (UserReligion=1) ? "Catholic" : "Orthodox"
       holidayMsg := relName " Christians celebrate today: " isHolidayToday "."
       If (TypeHolidayOccured>1)
          holidayMsg := "Today's event: " isHolidayToday "."
       FormatTime, PersonalDate, , yyyy/MM/dd
       listu .= PersonalDate " = " holidayMsg "`n `n"
    }

    startYday := A_YDay
    ; startDate := 20241231111536
    ; FormatTime, startYday, % startDate, yday
    totalYDays := isLeapYear() ? 366 : 365
    listed := 0
    If (doToday=2)
    {
       startYday -= 2
       startDate += -2, Days
    }

    friendlyInitDating(ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
    ; yesterday := 20241230
    ; tudayDate := 20241231
    ; tmrwDate := 20250101
    ; mtmrwDate := 20250102
    ; fnOutputDebug("s=" startDate)
    ; fnOutputDebug("y=" yesterday)
    ; fnOutputDebug("t=" tudayDate)
    ; fnOutputDebug("m=" tmrwDate)
    ; fnOutputDebug("o=" mtmrwDate)
    Loop, % dayzCheck
    {
        startDate += 1, Days
        thisMon := SubStr(startDate, 5, 2)
        thisMDay := SubStr(startDate, 7, 2)
        thisYear := SubStr(startDate, 1, 4)
        startYday++
        thisYday := (startYday>totalYDays) ? startYday - totalYDays : startYday
        wasItem := 0
        Loop, 3 ; for every type of celebration
        {
           obju := coretestCelebrationz(thisMon, thisMDay, thisYday, 1, A_Index, thisYear)
           ; fnOutputDebug(thisYear "/" thisMon "/" thisMDay " = " thisYday "[" totalYDays "]")
           ; ToolTip, % thisYear "/" thisMon "/" thisMDay " = " thisYday "[" totalYDays "]"  , , , 2
           ; Sleep, 950
           If obju[2]
           {
              wasItem := 1
              prefixu := (obju[1]=1) ? "✝ " : ""
              datum := friendlyDating(thisYear "/" thisMon "/" thisMDay, startDate, ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
              listu .= Format("{:U}", datum) ". " prefixu obju[2] ".`n`n"
           }
        }

        If wasItem
        {
           listed++
           If (listed>=limitList && limitList>0)
              Break
        }
    }
    Return listu
}

friendlyDating(datum, startDate, ereday, yesterday, tudayDate, tmrwDate, mtmrwDate) {
  pp :=  SubStr(startDate, 1, 8)
  If (pp=ereday)
     datum := "Ereyesterday"
  Else If (pp=yesterday)
     datum := "Yesterday"
  Else If (pp=tudayDate)
     datum := "Today"
  Else If (pp=tmrwDate)
     datum := "Tomorrow"
  Else If (pp=mtmrwDate)
     datum := "Overmorrow"

  Return datum
}

listSolarSeasons(ereday, yesterday, tudayDate, tmrwDate, mtmrwDate, showAll, dayz) {
    listu := ""
    FormatTime, OutputVar, % mEquiDate, yyyy/MM/dd
    OutputVar := friendlyDating(OutputVar, mEquiDate, ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
    If (isinRange(mEquiDay, A_YDay, A_YDay + dayz) || showAll=1)
       listu .= OutputVar ". ▀ March Equinox`n`n"
 
    FormatTime, OutputVar, % jSolsDate, yyyy/MM/dd
    OutputVar := friendlyDating(OutputVar, jSolsDate, ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
    If (isinRange(jSolsDay, A_YDay, A_YDay + dayz) || showAll=1)
       listu .= OutputVar ". ⬤ June Solstice`n`n"
  
    FormatTime, OutputVar, % sEquiDate, yyyy/MM/dd
    OutputVar := friendlyDating(OutputVar, sEquiDate, ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
    If (isinRange(sEquiDay, A_YDay, A_YDay + dayz) || showAll=1)
       listu .= OutputVar ". ▃ September Equinox`n`n"
  
    FormatTime, OutputVar, % dSolsDate, yyyy/MM/dd
    OutputVar := friendlyDating(OutputVar, dSolsDate, ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
    If (isinRange(dSolsDay, A_YDay, A_YDay + dayz) || showAll=1)
       listu .= OutputVar ". ◯ December Solstice`n`n"

    Return listu
}

friendlyInitDating(ByRef ereday, ByRef yesterday, ByRef tudayDate, ByRef tmrwDate, ByRef mtmrwDate) {
    ereday := yesterday := tmrwDate := mtmrwDate := ""
    tmrwDate += 1, Days
    tmrwDate := SubStr(tmrwDate, 1, 8)
    mtmrwDate += 2, Days
    mtmrwDate := SubStr(mtmrwDate, 1, 8)
    yesterday += -1, Days
    tudayDate := yesterday
    tudayDate += 1, Days
    tudayDate := SubStr(tudayDate, 1, 8)
    yesterday := SubStr(yesterday, 1, 8)
    ereday += -2, Days
    ereday := SubStr(ereday, 1, 8)
}

PopulateIncomingCelebs() {
    friendlyInitDating(ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
    If (ObserveHolidays=1)
       listu := coreUpcomingEvents(2, 32, 0)
    If !Trim(listu)
       listu := "No religious or secular events are observed for the next 30 days.`n`n"
    listu .= "Astronomic events:`n`n"
    listu .= listSolarSeasons(ereday, yesterday, tudayDate, tmrwDate, mtmrwDate, 0, 30)

    shiftu := localTimeShift()
    zeitu := A_Year A_Mon A_MDay "000000"   ; the list opens on the top of today
    zeitu += -1*shiftu, Seconds             ; ... which is this moment in UTC
    endZeit := zeitu
    endZeit += 30, Days
    Loop, 6
    {
        If !getNextMoonPhases(zeitu, toNew, toFirstQ, toFull, toLastQ)
           Break

        nameu := (toNew<toFull) ? "New moon" : "Full moon"
        secsu := (toNew<toFull) ? toNew : toFull
        zeitu += Round(secsu), Seconds
        If (zeitu>endZeit)
           Break

        localZeit := zeitu
        localZeit += shiftu, Seconds
        FormatTime, OutputVar, % localZeit, yyyy/MM/dd
        OutputVar := friendlyDating(OutputVar, localZeit, ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
        listu .= Format("{:U}", OutputVar) ". " nameu "`n`n"
        zeitu += 60, Seconds   ; step past it, so the next round finds the one after
    }

    If InStr(listu, ". | ✝ ") 
       listu := StrReplace(listu, ". | ✝ ", ".`n`n✝ ")

    GuiControl, SettingsGUIA:, holiListu, % listu
    If (ObserveHolidays=1)
       GuiControl, SettingsGUIA: Enable, btn1
    Else
       GuiControl, SettingsGUIA: Disable, btn1
}

reactWinOpened(funcu, idu) {
    If (PrefOpen=1 || AnyWindowOpen=idu)
    {
       If (PrefOpen=1 && appSettingsModified=0)
       {
          CloseSettings()
          Sleep, 50
          Return
       } Else If (PrefOpen=1)
          SoundBeep, 300, 900
       WinActivate, ahk_id %hSetWinGui%
       Return 1
    } Else If AnyWindowOpen
    {
       CloseWindow()
       Sleep, 25
    } Else If windowManageCeleb
    {
       CloseCelebListWin()
       Sleep, 25
    }

    ; If IsFunc(funcu)
    ;    %funcu%()
}

BtnSetPresetTimers(a, b, c) {
   Static lastInvoked := 1, prevu := 0
   GuiControlGet, a, SettingsGUIA: hwnd, userUItimerQuickSet
   ControlGetText, info, , ahk_id %a%
   info := StrReplace(info, "&")
   info := Trim(StrReplace(info, "m"))
   If !info
      Return

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
   If (A_TickCount - lastInvoked<300) && (prevu=info)
      SetTimer, BtnApplyAlarms, -250

   prevu := info
   lastInvoked := A_TickCount
   ; ToolTip, % a "=" b "=" c "=" info , , , 2
}

PanelSetAlarm() {
    If reactWinOpened(A_ThisFunc, 4)
       Return

    INIaction(0, "userTimerMins", "SavedSettings")
    INIaction(0, "userTimerHours", "SavedSettings")
    INIaction(0, "userTimerMsg", "SavedSettings")
    INIaction(0, "userAlarmWeekDays", "SavedSettings")
    MinMaxVar(userTimerMins, 0, 59, 2)
    MinMaxVar(userTimerHours, 0, 12, 0)

    GenericPanelGUI(0)
    AnyWindowOpen := 4
    LastWinOpened := A_ThisFunc
    INIaction(1, "LastWinOpened", "SavedSettings")
    btnWid := 100
    txtWid := 360
    Global btn1, editF1, editF2, editF4, editF5, userTimerInfos, UItimerInfoz
         , userAlarmWday1, userAlarmWday2, userAlarmWday3, userAlarmWday4
         , userAlarmWday5, userAlarmWday6, userAlarmWday7, txt1, userUItimerQuickSet
         , userAlarmExceptPerso, userAlarmExceptRelu, userAlarmExceptSeculu

    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
       Gui, Font, s%LargeUIfontValue%
    }

    btnW1 := (PrefsLargeFonts=1) ? 105 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    nW := (PrefsLargeFonts=1) ? 65 : 60
    nH := (PrefsLargeFonts=1) ? 35 : 30
    userAlarmWday1 := InStr(userAlarmWeekDays, "1") ? 1 : 0
    userAlarmWday2 := InStr(userAlarmWeekDays, "2") ? 1 : 0
    userAlarmWday3 := InStr(userAlarmWeekDays, "3") ? 1 : 0
    userAlarmWday4 := InStr(userAlarmWeekDays, "4") ? 1 : 0
    userAlarmWday5 := InStr(userAlarmWeekDays, "5") ? 1 : 0
    userAlarmWday6 := InStr(userAlarmWeekDays, "6") ? 1 : 0
    userAlarmWday7 := InStr(userAlarmWeekDays, "7") ? 1 : 0
    userAlarmExceptPerso := InStr(userAlarmWeekDays, "p") ? 1 : 0
    userAlarmExceptRelu := InStr(userAlarmWeekDays, "r") ? 1 : 0
    userAlarmExceptSeculu := InStr(userAlarmWeekDays, "s") ? 1 : 0
    If !userAlarmWeekDays
       userAlarmWday7 := userAlarmWday1 := 1

    doResetGuiFont()
    Gui, Add, Tab3,, Timer|Alarm
    Gui, Tab, 1
    Gui, Add, Text, x+15 y+15 Section +hwndhTemp, Predefined timer (in minutes):
    ml := (PrefsLargeFonts=1) ? 60 : 50
    GuiAddDropDownList("x+5 w" ml " Choose5 vuserUItimerQuickSet", "1|2|3|4|5|10|15|30|45|60|90|120", [hTemp])
    Gui, Add, Button, x+5 wp hp gBtnSetPresetTimers, Set
    Gui, Add, Checkbox, xs y+10 Section gupdateUIalarmsPanel Checked%userMustDoTimer% vuserMustDoTimer, Set timer duration (in hours`, mins):
    Gui, Font, % (PrefsLargeFonts=1) ? "s18" : "s16"
    GuiAddEdit("xs+15 y+10 w" nW " h" nH " Center number -multi limit2 gupdateUIalarmsPanel veditF1", userTimerHours, "Hours")
    Gui, Add, UpDown, vuserTimerHours Range0-12 gupdateUIalarmsPanel, % userTimerHours
    GuiAddEdit("x+5 w" nW " h" nH " Center number -multi limit2 veditF2 gupdateUIalarmsPanel", userTimerMins, "Minutes")
    Gui, Add, UpDown, vuserTimerMins Range-1-60 gupdateUIalarmsPanel, % userTimerMins
    Gui, Add, Text, x+10 hp +0x200 vuserTimerInfos, 00:00.
    doResetGuiFont()
    GuiAddEdit("xs+15 y+10 w255 -multi limit512 vuserTimerMsg", userTimerMsg, "Timer message")
    timerDetails := (userTimerExpire && userMustDoTimer=1) ? "Current timer expires at: " userTimerExpire "." : "Press Apply to start the timer."
    ml := (PrefsLargeFonts=1) ? 170 : 115
    zl := (PrefsLargeFonts=1) ? 55 : 45
    GuiAddDropDownList("xs+15 y+10 w" ml " AltSubmit Choose" userTimerSound " vuserTimerSound", "Auxilliary bell|Quarters bell|Hours bell|Gong|Beep|No sound alert", "Audio alert for the timer")
    GuiAddEdit("x+5 w" zl " hp Center number -multi limit2 veditF10 gupdateUIalarmsPanel", userTimerFreq, "Timer chiming frequency in seconds")
    Gui, Add, UpDown, vuserTimerFreq Range1-99 gupdateUIalarmsPanel, % userTimerFreq
    Gui, Add, Button, x+5 wp hp gBtnTestTimerAudio vbtn1, Test
    Gui, Add, Text, xs+15 y+15 w255 vUItimerInfoz, % timerDetails

    Gui, Tab, 2
    Gui, Add, Checkbox, x+15 y+15 Section gupdateUIalarmsPanel Checked%userMustDoAlarm% vuserMustDoAlarm, Set alarm at (hours`, mins`, snooze mins.):
    Gui, Font, % (PrefsLargeFonts=1) ? "s18" : "s16"
    GuiAddEdit("xs+15 y+10 w" nW " h" nH " Center number -multi limit2 veditF3 hwndhEdit", userAlarmHours, "Hours")
    Gui, Add, UpDown, vuserAlarmHours Range0-23, % userAlarmHours
    GuiAddEdit("x+5 w" nW " h" nH " gupdateUIalarmsPanel Center number -multi limit2 veditF4", userAlarmMins, "Minutes")
    Gui, Add, UpDown, vuserAlarmMins gupdateUIalarmsPanel Range-1-60, % userAlarmMins
    GuiAddEdit("x+35 w" nW " h" nH " Center number -multi limit2 veditF5", userAlarmSnooze, "Snooze duration in minutes")
    Gui, Add, UpDown, vuserAlarmSnooze Range1-59, % userAlarmSnooze
    doResetGuiFont()

    GuiAddEdit("xs+15 y+10 w255 -multi limit512 vuserAlarmMsg", userAlarmMsg, "Alarm message")
    Gui, Add, Checkbox, xs y+10 gupdateUIalarmsPanel Checked%userAlarmRepeated% vuserAlarmRepeated, &Repeat alarm on every...
    Gui, Add, Checkbox, xs+15 y+5 hp+6 +0x1000 Checked%userAlarmWday1% vuserAlarmWday1, Sun
    Gui, Add, Checkbox, x+1 wp-2 hp +0x1000 Checked%userAlarmWday2% vuserAlarmWday2, Mon
    Gui, Add, Checkbox, x+1 wp-2 hp +0x1000 Checked%userAlarmWday3% vuserAlarmWday3, Tue
    Gui, Add, Checkbox, x+1 wp-2 hp +0x1000 Checked%userAlarmWday4% vuserAlarmWday4, Wed
    Gui, Add, Checkbox, x+1 wp-2 hp +0x1000 Checked%userAlarmWday5% vuserAlarmWday5, Thu
    Gui, Add, Checkbox, x+1 wp-2 hp +0x1000 Checked%userAlarmWday6% vuserAlarmWday6, Fri
    Gui, Add, Checkbox, x+1 wp-2 hp +0x1000 Checked%userAlarmWday7% vuserAlarmWday7, Sat

    Gui, Add, Text, xs+15 y+10 vtxt1, Except on the days when the event observed is...
    Gui, Add, Checkbox, xs+15 y+5 hp+6 +0x1000 Checked%userAlarmExceptRelu% vuserAlarmExceptRelu, Religious
    Gui, Add, Checkbox, x+1 hp +0x1000 Checked%userAlarmExceptSeculu% vuserAlarmExceptSeculu, Secular
    Gui, Add, Checkbox, x+1 hp +0x1000 Checked%userAlarmExceptPerso% vuserAlarmExceptPerso, Personal
    GuiAddDropDownList("xs+15 y+10 w" ml " AltSubmit Choose" userAlarmSound " vuserAlarmSound", "Auxilliary bell|Quarters bell|Hours bell|Gong|Beep|No sound alert", "Audio alert for the alarm")
    GuiAddEdit("x+5 w" zl " hp Center number -multi limit2 veditF6 gupdateUIalarmsPanel", userAlarmFreq, "Alarm audio alert frequency in seconds")
    Gui, Add, UpDown, vuserAlarmFreq Range1-99 gupdateUIalarmsPanel, % userAlarmFreq
    Gui, Add, Button, x+5 wp hp gBtnTestAlarmAudio vBtn2, Test
    p := friendlyAlarmInfoz()
    Gui, Add, Text, xs+15 y+10 w255, % p

    Gui, Tab
    Gui, Add, Checkbox, xm y+10 Section gupdateUIalarmsPanel Checked%AlarmersDarkScreen% vAlarmersDarkScreen, Flash dark screen on alerts
    Gui, Add, Button, xs+0 y+10 h%btnH% w%btnW1% Default gBtnApplyAlarms, &Apply
    Gui, Add, Button, x+5 hp wp-15 gCloseWindow , &Cancel

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Alarm and timer: %appName%
    SetTimer, updateUIalarmsPanel, -150
}

BtnTestTimerAudio() {
    GuiControlGet, userTimerSound
    stopStrikesNow := 0
    PlayTimerBell(1)
}

BtnTestAlarmAudio() {
    GuiControlGet, userAlarmSound
    stopStrikesNow := 0
    PlayAlarmedBell(1)
}

PanelStopWatch() {
    If reactWinOpened(A_ThisFunc, 5)
       Return

    GenericPanelGUI(0)
    LastWinOpened := A_ThisFunc
    AnyWindowOpen := 5
    INIaction(1, "LastWinOpened", "SavedSettings")
    btnWid := 100
    txtWid := 360
    Global btn1, editF1, editF2, editF4, UIstopWatchLabel, UserStopWatchListZeits, UIstopWatchAvgInterval
         , UIstopWatchInfos, setAlwaysOnTop, UIstopWatchInterval, LViewStopWatch, UIstopWatchDetailsInterval

    stopWatchIntervalInfos[1] := 9876543210
    stopWatchIntervalInfos[2] := 0
    stopWatchIntervalInfos[3] := 0
    stopWatchRecordsInterval := []
    setAlwaysOnTop := 0
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
    }

    doResetGuiFont()
    stopWatchBeginZeit := 0
    stopWatchPauseZeit := 0.001
    stopWatchLapBeginZeit := 0
    stopWatchLapPauseZeit := 0.001
    stopWatchRealStartZeit := 0
    btnW1 := (PrefsLargeFonts=1) ? 105 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    Gui, Add, Tab3,, Main|Records

    Gui, Tab, 1 ; general
    Gui, Add, Text, x+15 y+15 Section, Start time and total time:
    Gui, Add, Text, y+5 vUIstopWatchInfos gstartStopWatchCounter, 00:00:00 - 00:00:00
    ; Gui, Add, Text, x+5 gstartStopWatchCounter, (total time)
    Gui, Font, s22
    Gui, Add, Text, xs y+10 vUIstopWatchLabel gstartStopWatchCounter, 00:00:00.00
    doResetGuiFont()
    Gui, Add, Text, x+5 hp +0x200 gstartStopWatchCounter, (laps total time)
    Gui, Font, s18
    Gui, Add, Text, xs y+5 vUIstopWatchInterval gBtnRecordStopWatchInterval, 00:00:00.00
    doResetGuiFont()
    Gui, Add, Text, x+5 hp +0x200 vUIstopWatchDetailsInterval gBtnRecordStopWatchInterval, (current lap details)
    Gui, Add, Text, xs y+5 vUIstopWatchAvgInterval gBtnRecordStopWatchInterval, 00:00:00.00
    Gui, Add, Text, x+5 gBtnRecordStopWatchInterval, (average time per lap)
    Gui, Add, Checkbox, xs y+15 gToggleStopWatchBeeps Checked%stopWatchDoBeeps% vstopWatchDoBeeps, Beep when the current lap`nis the longest
    ; Gui, Add, ComboBox, xs y+10 w250 vUserStopWatchListZeits, No records||
    
    Gui, Tab, 2
    nW := (PrefsLargeFonts=1) ? 265 : 240
    GuiAddListView("x+15 y+15 Section w" nW " r8 Grid -multi +ReadOnly vLViewStopWatch", "Index|Lap duration|Laps total|Total|System time", "Recorded time intervals")

    Gui, Tab
    Global UIbtnRecordInterval, UIbtnStartStopWatch
    Gui, Add, Checkbox, xm+0 y+15 gToggleAlwaysOnTopSettingsWindow  Checked%setAlwaysOnTop% vsetAlwaysOnTop, Always on top
    Gui, Add, Button, xm+0 y+5 h30 wp Section Default gstartStopWatchCounter vUIbtnStartStopWatch, &Start / Pause
    Gui, Add, Button, x+5 h30 wp gBtnRecordStopWatchInterval vUIbtnRecordInterval, &Record interval
    Gui, Add, Button, xs+0 y+5 hp wp gResetStopWatchCounter, &Reset all
    Gui, Add, Button, x+5 hp wp gCloseWindow, &Cancel

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Stopwatch: %appName%
}

PanelCalendarWindow() {
    If reactWinOpened(A_ThisFunc, 10)
       Return

    GenericPanelGUI(0)
    LastWinOpened := A_ThisFunc
    AnyWindowOpen := 10
    INIaction(1, "LastWinOpened", "SavedSettings")
    btnWid := 100
    txtWid := 360
    Global btn1, editF1, editF2, editF4
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
    }

    doResetGuiFont()
    Global uiCalendarL1C1, uiCalendarL1C2, uiCalendarL1C3, uiCalendarL1C4, uiCalendarL1C5, uiCalendarL1C6, uiCalendarL1C7
    Global uiCalendarL2C1, uiCalendarL2C2, uiCalendarL2C3, uiCalendarL2C4, uiCalendarL2C5, uiCalendarL2C6, uiCalendarL2C7
    Global uiCalendarL3C1, uiCalendarL3C2, uiCalendarL3C3, uiCalendarL3C4, uiCalendarL3C5, uiCalendarL3C6, uiCalendarL3C7
    Global uiCalendarL4C1, uiCalendarL4C2, uiCalendarL4C3, uiCalendarL4C4, uiCalendarL4C5, uiCalendarL4C6, uiCalendarL4C7
    Global uiCalendarL5C1, uiCalendarL5C2, uiCalendarL5C3, uiCalendarL5C4, uiCalendarL5C5, uiCalendarL5C6, uiCalendarL5C7
    Global uiCalendarL6C1, uiCalendarL6C2, uiCalendarL6C3, uiCalendarL6C4, uiCalendarL6C5, uiCalendarL6C6, uiCalendarL6C7
    Global uiCalendarWeek1, uiCalendarWeek2, uiCalendarWeek3, uiCalendarWeek4, uiCalendarWeek5, uiCalendarWeek6, uiCalendarYearLabel
    Global uiCalendarDatumLabel, UIcalendarEventsEditu, UIcalendarSelectedDatum, UIcalendarNewEventEdit, uiCalendarNewAllYears

    kw := (PrefsLargeFonts=1) ? 50 : 40
    kz := kw//2
    kwd := (kz*2.5)
    pkr := (PrefsLargeFonts=1) ? 6 : 8
    ka := Ceil(kw*6.32) - kwd - pkr
    kh := (PrefsLargeFonts=1) ? 36 : 31
    hza := (PrefsLargeFonts=1) ? 32 : 24
    ColorPickerHandles := ""
    lastCalendarClickedDate := uiUserFullDateUTC := A_Now
    GuiAddButton("xm ym w" kz " h" hza " gBtnChangeDateCalendar", "<", "Previous month ( , )")
    GuiAddButton("x+0 wp hp gBtnChangeDateCalendar", ">", "Next month ( . )")
    Gui, Add, Text, x+5 w%ka% hp +0x200 -wrap vuiCalendarDatumLabel ginvokeCalendarMonthsMenu +hwndhTemp, Month, 2024
    ColorPickerHandles .= hTemp ","
    ToolTip2ctrl(hTemp, "Choose month")
    GuiAddButton("x+1 w" kz " hp gBtnChangeDateCalendar", "◀", "Previous year ( Page up )")
    Gui, Add, Button, x+1 w%kwd% hp -wrap vuiCalendarYearLabel gBtnChangeDateCalendar +hwndhTemp, 1054
    GuiAddButton("x+1 w" kz " hp gBtnChangeDateCalendar", "▶", "Next year ( Page down )")

    Gui, Add, Text, xs y+10 w%kw% h%hza% +0x200 Center +hwndhTemp ginvokeCalendarMonthsMenu, #
    ColorPickerHandles .= hTemp ","
    ToolTip2ctrl(hTemp, "Week number")
    kwdLEng := {1:"Monday", 2:"Tuesday", 3:"Wednesday", 4:"Thursday", 5:"Friday", 6:"Saturday", 7:"Sunday"}
    kwdEng := {1:"Mon", 2:"Tue", 3:"Wed", 4:"Thu", 5:"Fri", 6:"Sat", 7:"Sun"}
    KwdLocal := []
    Loop, 21
    {
       mon := (A_Index<10) ? 0 . A_Index : A_Index
       datum := "202501" mon "010101"
       FormatTime, OutputVar, % datum, dddd
       FormatTime, dkw, % datum, WDay
       If (dkw - 1 = 0)
          KwdLocal[7] := OutputVar
       Else
          KwdLocal[dkw - 1] := OutputVar
    }

    Loop, 7
    {
        pp := kwdEng[A_Index]
        Gui, Add, Text, x+2 wp h%hza% +0x200 Center +Border +hwndhTemp +gdummy, % pp
        tti := (kwdLEng[A_Index]!=KwdLocal[A_Index]) ? kwdLEng[A_Index] "`n" KwdLocal[A_Index] : kwdLEng[A_Index]
        ToolTip2ctrl(hTemp, tti)
    }

    Loop, 6
    {
        t := A_Index
        Gui, Add, Text, xs y+2 wp hp +0x200 Center vuiCalendarWeek%t% +hwndhTemp, % t
        WinSet, Transparent, 170, ahk_id %hTemp%
        Loop, 7
        {
            Gui, Add, Checkbox, x+2 w%kw% h%kh% +0x1000 gBTNcalendarDayAct vuiCalendarL%t%C%A_Index%, %t%.%A_Index%
            If (uiDarkMode!=1)
               Gui, Add, Text, xp yp wp hp +Border,
        }
    }

    ; Gui, Add, ComboBox, xs y+10 w250 vUserStopWatchListZeits, No records||
    btnW3 := (PrefsLargeFonts=1) ? 110 : 80
    btnW2 := (PrefsLargeFonts=1) ? 205 : 125
    btnW1 := (PrefsLargeFonts=1) ? 70 : 50
    Gui, Add, Button, xm y+20 h30 w%btnW3% gPanelTodayInfos, &Astronomy
    Gui, Add, Button, x+5 hp w%btnW2% gOpenListCelebrationsBtn, &Manage celebrations
    Gui, Add, Button, x+5 hp w%btnW1% Default gCloseWindow, &Close
    col := (PrefsLargeFonts=1) ? Round(kw*8.7) : Round(kw*8.6)
    Gui, Font, % (PrefsLargeFonts=1) ? "s16" : "s14"
    ka += (PrefsLargeFonts=1) ? Round(kwd*0.7) : Round(kwd*0.4)
    Gui, Add, Text, xm+%col% ym w%ka% h%hza% +0x200 Section gBtnChangeDateCalendar vUIcalendarSelectedDatum +hwndhTemp, Today date
    ToolTip2ctrl(hTemp, "Reset to current date ( \ )")
    ColorPickerHandles .= hTemp ","
    doResetGuiFont()
    pr := (PrefsLargeFonts=1) ? 7 : 10
    Gui, Add, Edit, xs y+10 wp +ReadOnly -Border r%pr% vUIcalendarEventsEditu, ---
    Gui, Add, Text, xs y+10 wp, New personal event to observe:
    GuiAddEdit("xs y+1 wp r1 limit90 -multi -wantReturn -wantTab -wrap vUIcalendarNewEventEdit", "", "Event name")
    Gui, Add, Button, xs y+2 w%kW% h%hza% gBTNcalendarSaveNewEntry +hwndhTemp, Set
    Gui, Add, Button, x+5 wp+10 hp gBTNcalendarClearEvent +hwndhTemp, Clear
    ToolTip2ctrl(hTemp, "Clear personal event for the selected date.")
    Gui, Add, Checkbox, x+5 hp Checked1 vuiCalendarNewAllYears +hwndhTemp, Observe every year
    ToolTip2ctrl(hTemp, "When this is checked, the newly defined event will be observed every year.")

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Calendar: %appName%
    uiPopulateCalendar()
    uiPopulateSelDate()
}

BTNcalendarClearEvent() {
   year := SubStr(lastCalendarClickedDate, 1, 4)
   newMonth := SubStr(lastCalendarClickedDate, 5, 2)
   newDay := SubStr(lastCalendarClickedDate, 7, 2)
   pDay := INIactionNonGlobal(0, newMonth "." newDay ".a", 0, "Celebrations")
   If (StrLen(pDay)>2)
      INIactionNonGlobal(1, newMonth "." newDay ".a", "-", "Celebrations")

   pDay := INIactionNonGlobal(0, newMonth "." newDay "." year, 0, "Celebrations")
   If (StrLen(pDay)>2)
      INIactionNonGlobal(1, newMonth "." newDay "." year, "-", "Celebrations")
   SoundBeep, 900, 100
   uiPopulateSelDate()
}

BTNcalendarSaveNewEntry() {
  Gui, SettingsGUIA: Default
  GuiControlGet, UIcalendarNewEventEdit
  GuiControlGet, uiCalendarNewAllYears
  If (StrLen(UIcalendarNewEventEdit)<4)
  {
     ToolTip, Event name too short.
     SoundBeep, 300, 300
     Sleep, 900
     ToolTip
  } Else
  {
     If (ObserveHolidays!=1)
     {
        ObserveHolidays := 1
        ObserveSecularDays := ObserveReligiousDays := 0
        INIaction(1, "ObserveHolidays", "SavedSettings")
        INIaction(1, "ObserveSecularDays", "SavedSettings")
        INIaction(1, "ObserveReligiousDays", "SavedSettings")
     }

     newMonth := SubStr(lastCalendarClickedDate, 5, 2)
     newDay := SubStr(lastCalendarClickedDate, 7, 2)
     yearu := (uiCalendarNewAllYears=1) ? "a" : SubStr(lastCalendarClickedDate, 1, 4)
     PersonalDay := INIactionNonGlobal(1, newMonth "." newDay "." yearu, UIcalendarNewEventEdit, "Celebrations")
     SoundBeep, 900, 100
     uiPopulateSelDate()
  }
}

BTNcalendarDayAct(a, b, c) {
   Gui, SettingsGUIA: Default
   ; ControlGetText, OutputVar,, ahk_id %a%
   GuiControlGet, WhatsFocused, SettingsGUIA: FocusV
   ; ToolTip, % a "|"  b "|" c "|" WhatsFocused  , , , 2
  od := lastCalendarClickedDate
  tDate := getUIcalendarDate()
  Loop, 6
  {
    t := A_Index
    Loop, 7
    {
        pp := "uiCalendarL" t "C" A_Index
        If (pp=WhatsFocused)
        {
           GuiControlGet, zz, SettingsGUIA:, % pp
           lastCalendarClickedDate := tDate
           GuiControl, SettingsGUIA:, % pp, % !zz
           ; ToolTip, % zz "|"  , , , 2
           Break
        } Else
        {
          tDate += 1, Days
        }
    }
  }
  If (od=lastCalendarClickedDate && SubStr(lastCalendarClickedDate, 1, 6)!=SubStr(uiUserFullDateUTC, 1, 6))
     uiUserFullDateUTC := lastCalendarClickedDate

  ; ToolTip, % tDate "|" lastCalendarClickedDate "|" weekday , , , 2
  uiPopulateCalendar()
  uiPopulateSelDate()
}

BtnChangeDateCalendar(a, b, c) {
   Gui, SettingsGUIA: Default
   If (b="given")
   {
      GuiControlGet, WhatsFocused, FocusV
      If (WhatsFocused="UIcalendarNewEventEdit")
      {
         SendInput, {%a%}
         Return
      }
   }

   ControlGetText, t,, ahk_id %a%
   t := (b="given") ? c : Trimmer(t)
   ; the months and the years are stepped on the calendar, not by 30 and 365 days: from a 31st,
   ; thirty days back landed on the 1st of the very same month, from the end of January thirty
   ; days on skipped February, and 365 days drifted by a day at every leap day crossed
   If InStr(t, "previous month")
      uiUserFullDateUTC := calendarShiftMonths(uiUserFullDateUTC, -1)
   Else If InStr(t, "next month")
      uiUserFullDateUTC := calendarShiftMonths(uiUserFullDateUTC, 1)
   Else If InStr(t, "previous year")
      uiUserFullDateUTC := calendarShiftYears(uiUserFullDateUTC, -1)
   Else If InStr(t, "next year")
      uiUserFullDateUTC := calendarShiftYears(uiUserFullDateUTC, 1)
   Else If InStr(t, "previous day")
      uiUserFullDateUTC += -1, Days
   Else If InStr(t, "next day")
      uiUserFullDateUTC += 1, Days
   Else
      uiUserFullDateUTC := A_Now

   lastCalendarClickedDate := uiUserFullDateUTC
   uiPopulateCalendar()
   uiPopulateSelDate()
   ; ToolTip, % a "|" t "|" uiUserFullDateUTC , , , 2
}

calendarDaysInMonth(yearu, monu) {
; How many days the given month of the given year has. The leap years are told by the
; Gregorian rule itself rather than by asking the system to format the 29th of February,
; which is what isLeapYear() does: this is called for every OSD with the month progress bar.
   Static dayz := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
   monu := monu + 0
   yearu := yearu + 0
   If (monu<1 || monu>12)
      Return 31

   If (monu=2 && ((Mod(yearu, 4)=0 && Mod(yearu, 100)!=0) || Mod(yearu, 400)=0))
      Return 29

   Return dayz[monu]
}

calendarBuildDate(yearu, monu, dayu, restu) {
; Puts a YYYYMMDDHH24MISS stamp together out of its parts. The day of the month is kept where
; the month has it and otherwise becomes the last day of that month; the years are held
; within what the date functions accept.
   yearu := clampInRange(yearu + 0, 1601, 9998)
   monu := clampInRange(monu + 0, 1, 12)
   dayu := clampInRange(dayu + 0, 1, calendarDaysInMonth(yearu, monu))
   Return Format("{:04}{:02}{:02}", yearu, monu, dayu) . restu
}

calendarShiftMonths(datum, months) {
; The time stamp moved by a number of calendar months, forwards or back, on the same day of
; the month - or on the last day of the month reached, when it is a shorter one.
   totalu := SubStr(datum, 1, 4)*12 + (SubStr(datum, 5, 2) - 1) + months
   Return calendarBuildDate(totalu//12, Mod(totalu, 12) + 1, SubStr(datum, 7, 2), SubStr(datum, 9))
}

calendarShiftYears(datum, years) {
; The time stamp moved by a number of calendar years, on the same month and day - the 29th of
; February becomes the 28th where the year reached is not a leap year.
   Return calendarBuildDate(SubStr(datum, 1, 4) + years, SubStr(datum, 5, 2), SubStr(datum, 7, 2), SubStr(datum, 9))
}

invokeCalendarMonthsMenu() {
     Try Menu, monthsMenu, Delete
     pp := []
     datum := 20250120010101
     thisMon := SubStr(uiUserFullDateUTC, 5, 2)
     Loop, 12
     {
        mon := (A_Index<10) ? 0 . A_Index : A_Index
        datum := "2025" . mon . "20010101"
        FormatTime, OutputVar, % datum, MMMM
        Menu, monthsMenu, Add,  % mon ". " OutputVar, MenuSetCalendarMonth
        If (mon=thisMon)
           Menu, monthsMenu, Check,  % mon ". " OutputVar
     }

     Menu, monthsMenu, Show
}

MenuSetCalendarMonth(a, b, c) {
    ; ToolTip, % a "|" b "|" c , , , 2
    thisMon := SubStr(a, 1, 2)
    thisMDay := SubStr(lastCalendarClickedDate, 7, 2)
    thisYear := SubStr(lastCalendarClickedDate, 1, 4)
    If (thisMDay>30 || thisMon="02" && thisMDay>=28)
       thisMDay := (thisMon="02") ? 28 : 30

    uiUserFullDateUTC := lastCalendarClickedDate := thisYear thisMon thisMDay 010101
    uiPopulateCalendar()
    uiPopulateSelDate()
}

givenDateTestCelebrations(givenDate) {
    FormatTime, thisYday, % givenDate, YDay
    FormatTime, WeDay, % givenDate, Wday
    thisMon := SubStr(givenDate, 5, 2)
    thisMDay := SubStr(givenDate, 7, 2)
    thisYear := SubStr(givenDate, 1, 4)
    listu := ""
    Loop, 3 ; for every type of celebration
    {
       obju := coretestCelebrationz(thisMon, thisMDay, thisYday, 1, A_Index, thisYear)
       If obju[2]
       {
          prefixu := (obju[1]=1) ? "✝ " : "▣ "
          If (obju[1]=3) ; personal
             prefixu := "▣ "
 
          listu .= prefixu obju[2] ".`n`n"
       }
    } 

    If (mEquiDay=thisYday)
       listu .= "▀ March Equinox.`n`n"
    Else If (jSolsDay=thisYday)
       listu .= "⬤ June Solstice.`n`n"
    Else If (sEquiDay=thisYday)
       listu .= "▃ September Equinox.`n`n"
    Else If (dSolsDay=thisYday)
       listu .= "◯ December Solstice.`n`n"

    shiftu := localTimeShift()
    zeitu := thisYear thisMon thisMDay "000000"   ; the top of the day, locally
    zeitu += -1*shiftu, Seconds                   ; ... as the moment it is in UTC
    zeitu += -1, Seconds   ; the DLL answers with what comes strictly after, and a phase
                           ; on the stroke of midnight belongs to the day it opens
    If getNextMoonPhases(zeitu, toNew, toFirstQ, toFull, toLastQ)
    {
       nameu := (toNew<toFull) ? "New moon" : "Full moon"
       secsu := (toNew<toFull) ? toNew : toFull
       If (secsu<=86400)   ; a day's worth of seconds
          listu .= "* " nameu ".`n`n"
    }

    alarmInfos := ""
    If (userMustDoAlarm=1 && isValidAlarmTime(userAlarmHours, userAlarmMins))
    {
       tipu := 0
       If InStr(listu, "✝")
          tipu := 1
       Else If InStr(listu, "▦")
          tipu := 3
       Else If InStr(listu, "▣")
          tipu := 2

       timeu := Format("{:02}:{:02}", userAlarmHours, userAlarmMins)
       If (userAlarmRepeated=1)
       {
          canDo := InStr(userAlarmWeekDays, WeDay) ? 1 : 0
          ; ToolTip, % canDo "=" ObserveHolidays "=" isHolidayToday , , , 2
          If (canDo && ObserveHolidays=1)
             canDo := (InStr(userAlarmWeekDays, "p") && tipu=3) || (InStr(userAlarmWeekDays, "s") && tipu=2 && ObserveSecularDays=1) || (InStr(userAlarmWeekDays, "r") && tipu=1 && ObserveReligiousDays=1) ? 0 : 1

          alarmInfos := canDo ? "`nRegular alarm set at: " timeu : "" ; "`nRegular alarm set: exception rule applies for today"
       } Else If (SubStr(givenDate, 1, 8)=SubStr(A_Now, 1, 8))
          alarmInfos := "`nAlarm set at: " timeu
    }

    If alarmInfos
       listu := Trimmer(alarmInfos) ".`n`n" listu

    Return listu
}

uiPopulateSelDate() {
  Gui, SettingsGUIA: Default
  FormatTime, k, % lastCalendarClickedDate, dddd`, d MMMM
  GuiControl, SettingsGUIA:, UIcalendarSelectedDatum, % k
  listu := givenDateTestCelebrations(lastCalendarClickedDate)
  actu := !listu ? "Disable" : "Enable"
  If !listu 
     listu := " - no events observed - "
  If InStr(listu, ". | ✝ ") 
     listu := StrReplace(listu, ". | ✝ ", ".`n`n✝ ")

  GuiControl, SettingsGUIA:, UIcalendarEventsEditu, % listu
  GuiControl, SettingsGUIA: %actu%, UIcalendarEventsEditu
}

getUIcalendarDate() {
  tDate := SubStr(uiUserFullDateUTC, 1, 6) . "01010101"
  FormatTime, weekday, % tDate, WDay
  weekday -= 2
  If (weekday=0)
     weekday := 7

  If (weekday=-1)
     tDate += -6, Days
  Else If (weekday<7)
     tDate += -weekday, Days

  Return tDate
}

uiPopulateCalendar() {
  Gui, SettingsGUIA: Default
  FormatTime, OutputVar, % uiUserFullDateUTC, MMMM
  GuiControl, SettingsGUIA:, uiCalendarDatumLabel, % A_Space SubStr(uiUserFullDateUTC, 5, 2) ". " OutputVar
  GuiControl, SettingsGUIA:, uiCalendarYearLabel, % SubStr(uiUserFullDateUTC, 1, 4)
  gMon := SubStr(uiUserFullDateUTC, 5, 2)
  tDate := getUIcalendarDate()
  GuiControlGet, hVar, SettingsGUIA: hwnd, uiCalendarL1C1
  WinGetPos, , , mW, mH, ahk_id %hVar%
  mW -= 2,     mH -= 2
  nW := mW -2, nH := mH - 2
  
  lDate := SubStr(lastCalendarClickedDate, 1, 8)
  Loop, 6
  {
    t := A_Index
    FormatTime, isoYWeek, % tDate, YWeek
    GuiControl, SettingsGUIA:, uiCalendarWeek%t%, % LTrim(SubStr(isoYWeek, 5), "0")
    Loop, 7
    {
        FormatTime, dayu, % tDate, d
        If (dayu=1)
           dayu .= "‎" ; invisible space

        GuiControlGet, hVar, SettingsGUIA: hwnd, uiCalendarL%t%C%A_Index%
        ; A day carries the marker when the phase itself lands on it, so no two days
        ; running can carry one - the new moon and the full are a fortnight apart..
        lista := givenDateTestCelebrations(tDate)
        tMon := SubStr(tDate, 5, 2)
        opp := (tMon=gMon) ? 255 : 123
        If (SubStr(tDate, 1, 8)=lDate)
        {
           opp := 253
           WinSet, Region,, ahk_id %hVar%
           WinSet, Style, +0x800000, ahk_id %hVar%
           If (tMon=gMon)
              WinSet, Style, +0x8000000, ahk_id %hVar%
        } Else
        {
           ; If (tMon=gMon)
           ;    WinSet, Region, 1-1 W%mW% H%mH%, ahk_id %hVar%
           ; Else
              WinSet, Region, 2-2 W%nW% H%nH%, ahk_id %hVar%
           WinSet, Style, -0x8000000, ahk_id %hVar%
           WinSet, Style, -0x800000, ahk_id %hVar%
        }

        WinSet, Transparent, % opp, ahk_id %hVar%
        tDate += 1, Days
        GuiControl, SettingsGUIA:, uiCalendarL%t%C%A_Index%, % dayu
        GuiControl, SettingsGUIA:, uiCalendarL%t%C%A_Index%, % (lista && opp!=253) ? 1 : 0
    }
  }
  ; ToolTip, % thisDate "`n" uiUserFullDateUTC , , , 2
}

ToggleAlwaysOnTopSettingsWindow() {
  Gui, SettingsGUIA: Default
  GuiControlGet, setAlwaysOnTop
  If (setAlwaysOnTop=1)
     WinSet, AlwaysOnTop, On, ahk_id %hSetWinGui%
  Else
     WinSet, AlwaysOnTop, Off, ahk_id %hSetWinGui%
}

ToggleStopWatchBeeps() {
  Gui, SettingsGUIA: Default
  GuiControlGet, stopWatchDoBeeps
  INIaction(1, "stopWatchDoBeeps", "SavedSettings")
}

BtnRecordStopWatchInterval() {
  If (AnyWindowOpen=5 && stopWatchBeginZeit && stopWatchPauseZeit)
  {
     Gui, SettingsGUIA: Default
     GuiControlGet, stopWatchDoBeeps
     GuiControl, SettingsGUIA:, UIstopWatchInterval, 00:00:00.0
     coreSecToHHMMSS((A_TickCount - stopWatchBeginZeit)/1000 + stopWatchPauseZeit/1000, hrs, mins, sec)
     Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), SubStr(Sec, 1, InStr(Sec, ".") - 1))
     SecB := SubStr(Sec, InStr(Sec, ".") + 1)
 
     coreSecToHHMMSS((A_TickCount - stopWatchRealStartZeit)/1000, hrs, mins, sec, 0)
     HrzA := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), Sec)
     valuePushable := (A_TickCount - stopWatchLapBeginZeit)/1000 + stopWatchLapPauseZeit/1000
     coreSecToHHMMSS(valuePushable, hrs, mins, sec)
     HrzB := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), SubStr(Sec, 1, InStr(Sec, ".") - 1))
     SecC := SubStr(Sec, InStr(Sec, ".") + 1)
     finalu := HrzB "." SecC " / " Hrz "." SecB " / " HrzA
     If (stopWatchIntervalInfos[3]=0)
        stopWatchIntervalInfos[1] := (A_TickCount - stopWatchRealStartZeit)/1000 + 1

     countu := stopWatchIntervalInfos[3] + 1
     stopWatchRecordsInterval[countu] := valuePushable
     Gui, ListView, LViewStopWatch
     FormatTime, sysTime, , HH:mm:ss
     LV_Add(1, countu, HrzB "." SecC, Hrz "." SecB, HrzA, sysTime)
     If (countu=1)
     {
        Loop, 5
           LV_ModifyCol(A_Index, "AutoHdr Center")
     }

     stopWatchIntervalInfos[1] := min(valuePushable, stopWatchIntervalInfos[1])
     stopWatchIntervalInfos[2] := max(valuePushable, stopWatchIntervalInfos[2])
     stopWatchIntervalInfos[3] := countu
     stopWatchIntervalInfos.Push(valuePushable)
     stopWatchLapPauseZeit := 0.001
     stopWatchLapBeginZeit := A_TickCount
  } Else If (AnyWindowOpen=5 && stopWatchPauseZeit)
  {
     Gui, SettingsGUIA: Default
     Gui, ListView, LViewStopWatch
     total := LV_GetCount()
     If !total
     {
        ToolTip, There are no recorded lap intervals.
        SetTimer, removeTooltip, -1500
        Return
     }

     listu := "#|Lap duration|Laps total|Total|System time`n"
     Loop, % total
     {
        row := A_Index
        Loop, 5
        {
            LV_GetText(z, row, A_Index)
            listu .= z "|"
        }
        listu .= "`n"
     }

     Try Clipboard := listu
     Catch wasError
           Sleep, 1

     If wasError
        ToolTip, Failed to copy to clipboard.
     Else
        ToolTip, The recorded lap intervals were copied to clipboard.
     SetTimer, removeTooltip, -1500
  }
}

ResetStopWatchCounter() {
   stopWatchIntervalInfos[1] := 9876543210
   stopWatchIntervalInfos[2] := 0
   stopWatchIntervalInfos[3] := 0
   stopWatchRecordsInterval := []
   If (AnyWindowOpen=5)
   {
      Gui, SettingsGUIA: Default
      GuiControlGet, stopWatchDoBeeps
      Gui, ListView, LViewStopWatch
      LV_Delete()
      ; GuiControl, SettingsGUIA:, UserStopWatchListZeits, |No records||
   }

   stopWatchBeginZeit := 0
   stopWatchPauseZeit := 0.001
   stopWatchLapBeginZeit := 0
   stopWatchLapPauseZeit := 0.001
   stopWatchRealStartZeit := 0
   SetTimer, uiStopWatchUpdater, Off
   SetTimer, uiStopWatchPausedUpdater, Off
   If (AnyWindowOpen=5)
   {
      GuiControl, SettingsGUIA: Disable, UIbtnRecordInterval
      GuiControl, SettingsGUIA:, UIbtnStartStopWatch, &Start
      GuiControl, SettingsGUIA:, UIstopWatchInfos, 00:00:00 - 00:00:00
      GuiControl, SettingsGUIA:, UIstopWatchLabel, 00:00:00.0
      GuiControl, SettingsGUIA:, UIstopWatchInterval, 00:00:00.0
      GuiControl, SettingsGUIA:, UIstopWatchAvgInterval, 00:00:00.0
   }
}

startStopWatchCounter() {
   If (AnyWindowOpen=5)
   {
      Gui, SettingsGUIA: Default
      GuiControlGet, stopWatchDoBeeps
   }

   GuiControl, SettingsGUIA: Enable, UIbtnRecordInterval
   If stopWatchBeginZeit
   {
      SetTimer, uiStopWatchUpdater, Off
      stopWatchPauseZeit += A_TickCount - stopWatchBeginZeit
      stopWatchBeginZeit := 0
      stopWatchLapPauseZeit += A_TickCount - stopWatchLapBeginZeit
      stopWatchLapBeginZeit := 0
      If stopWatchRealStartZeit
      {
         GuiControl, SettingsGUIA:, UIbtnRecordInterval, &Copy intervals
         GuiControl, SettingsGUIA:, UIbtnStartStopWatch, &Resume
         SetTimer, uiStopWatchPausedUpdater, 50
      } Else
         GuiControl, SettingsGUIA:, UIbtnStartStopWatch, &Start
      Return
   }

   SetTimer, uiStopWatchPausedUpdater, Off
   stopWatchBeginZeit := A_TickCount
   stopWatchLapBeginZeit := A_TickCount
   If (stopWatchPauseZeit<2)
   {
      FormatTime, CurrentTime,, H:mm:ss
      stopWatchHumanStartTime := CurrentTime
      stopWatchRealStartZeit := A_TickCount
   }
   GuiControl, SettingsGUIA:, UIbtnRecordInterval, &Record interval
   GuiControl, SettingsGUIA:, UIbtnStartStopWatch, &Pause
   SetTimer, uiStopWatchUpdater, 50
}

uiStopWatchUpdater() {
  Static lastBeeped := 1
  If (AnyWindowOpen!=5)
  {
     ResetStopWatchCounter()
     Return
  }

  Gui, SettingsGUIA: Default
  GuiControlGet, stopWatchDoBeeps
  coreSecToHHMMSS((A_TickCount - stopWatchBeginZeit)/1000 + stopWatchPauseZeit/1000, hrs, mins, sec)
  Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), SubStr(Sec, 1, InStr(Sec, ".") - 1))
  SecB := SubStr(Sec, InStr(Sec, ".") + 1)
  GuiControl, SettingsGUIA:, UIstopWatchLabel, %hrz%.%SecB% ; :%mins%:%sec%

  coreSecToHHMMSS((A_TickCount - stopWatchRealStartZeit)/1000, hrs, mins, sec, 0)
  Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), Sec)
  ; Mins := Format("{:02}", Mins)
  GuiControl, SettingsGUIA:, UIstopWatchInfos, %stopWatchHumanStartTime% - %hrz% ; :%mins%:%sec%
  
  ; ToolTip, % stopWatchLapBeginZeit "`n" stopWatchLapPauseZeit , , , 2
  thisLap := (A_TickCount - stopWatchLapBeginZeit)/1000 + stopWatchLapPauseZeit/1000

  coreSecToHHMMSS(thisLap, hrs, mins, sec)
  Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), SubStr(Sec, 1, InStr(Sec, ".") - 1))
  SecB := SubStr(Sec, InStr(Sec, ".") + 1)
  If !isInRange(thisLap, stopWatchIntervalInfos[1], stopWatchIntervalInfos[2])
     labelu := (thisLap<stopWatchIntervalInfos[1]) ? "shortest" : "longest"
  Else
     labelu := "current"

  If (labelu="longest" && stopWatchDoBeeps=1 && stopWatchIntervalInfos[3]>0 && (A_TickCount - lastBeeped>950))
  {
     stopAdditionalStrikez := stopStrikesNow := 0
     MCXI_Play(SNDmedia_beep)
     lastBeeped := A_TickCount
  }

  GuiControl, SettingsGUIA:, UIstopWatchInterval, %hrz%.%SecB%
  GuiControl, SettingsGUIA:, UIstopWatchDetailsInterval, (%labelu% lap)
  If (stopWatchIntervalInfos[3]>0)
  {
     allLapsZeit := thisLap
     Loop, % stopWatchIntervalInfos[3]
         allLapsZeit += stopWatchRecordsInterval[A_Index]

     allLapsZeit := allLapsZeit/(stopWatchIntervalInfos[3] + 1)
     coreSecToHHMMSS(allLapsZeit, hrs, mins, sec)
     Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), SubStr(Sec, 1, InStr(Sec, ".") - 1))
     SecB := SubStr(Sec, InStr(Sec, ".") + 1)
     GuiControl, SettingsGUIA:, UIstopWatchAvgInterval, %hrz%.%SecB%
  }
}

isInRange(value, inputA, inputB) {
    If (value=inputA || value=inputB)
       Return 1

    Return (value>=min(inputA, inputB) && value<=max(inputA, inputB)) ? 1 : 0
}

hourInDefinedInterval(hu, startu, endu) {
   If (startu<=endu)
      Return (hu>=startu && hu<=endu) ? 1 : 0

   Return (hu>=startu || hu<=endu) ? 1 : 0
}

uiStopWatchPausedUpdater() {
  If (AnyWindowOpen!=5)
  {
     ResetStopWatchCounter()
     Return
  }

  Gui, SettingsGUIA: Default
  GuiControlGet, stopWatchDoBeeps
  coreSecToHHMMSS((A_TickCount - stopWatchRealStartZeit)/1000, hrs, mins, sec, 0)
  Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), Sec)
  ; Mins := Format("{:02}", Mins)
  GuiControl, SettingsGUIA:, UIstopWatchInfos, %stopWatchHumanStartTime% - %hrz% ; :%mins%:%sec%
}

coreSecToHHMMSS(Seco, ByRef Hrs, ByRef Min, ByRef Sec, decimals:=1) {
; Splits a count of seconds into hours, minutes and seconds, the seconds rounded to the given
; number of decimals. The total is rounded before it is split, so that 59.96 s comes out as
; one minute rather than as «0 minutes and 60.0 seconds»: rounding the remainder on its own,
; as this used to, had the stopwatch read :60 at every minute boundary.
  Seco := Round(Seco, decimals)
  OldFormat := A_FormatFloat
  SetFormat, Float, 2.00
  Hrs := Seco//3600/1
  Min := Mod(Seco//60, 60)/1
  SetFormat, Float, %OldFormat%
  Sec := Round(Mod(Seco, 60), decimals)
}

updateUIalarmsPanel() {
  Gui, SettingsGUIA: Default
  GuiControlGet, OutputVarA, SettingsGUIA:, userMustDoTimer
  GuiControlGet, OutputVarB, SettingsGUIA:, userMustDoAlarm
  GuiControlGet, doRepeat, SettingsGUIA:, userAlarmRepeated
  GuiControlGet, doTimer, SettingsGUIA:, userMustDoTimer
  GuiControlGet, TimerH, SettingsGUIA:, userTimerHours
  GuiControlGet, TimerM, SettingsGUIA:, userTimerMins
  GuiControlGet, TimerAlH, SettingsGUIA:, userAlarmHours
  GuiControlGet, TimerAlM, SettingsGUIA:, userAlarmMins

  If (TimerM=60)
  {
     timerM := 0
     TimerH := clampInRange(TimerH + 1, 0, 12, 1)
     GuiControl, SettingsGUIA:, userTimerMins, 0
     GuiControl, SettingsGUIA:, userTimerHours, % TimerH
  } Else If (TimerM=-1)
  {
     timerM := 59
     TimerH := clampInRange(TimerH - 1, 0, 12, 1)
     GuiControl, SettingsGUIA:, userTimerMins, 59
     GuiControl, SettingsGUIA:, userTimerHours, % TimerH
  }

  If (TimerAlM=60)
  { 
     timerAlM := 0
     TimerAlH := clampInRange(TimerAlH + 1, 0, 23, 1)
     GuiControl, SettingsGUIA:, userAlarmMins, 0
     GuiControl, SettingsGUIA:, userAlarmHours, % TimerAlH
  } Else If (TimerAlM=-1)
  {
     timerAlM := 59
     TimerAlH := clampInRange(TimerAlH - 1, 0, 23, 1)
     GuiControl, SettingsGUIA:, userAlarmMins, 59
     GuiControl, SettingsGUIA:, userAlarmHours, % TimerAlH
  }

  If (doTimer=1 && (TimerH || TimerM))
  {
     Timea := A_Now
     Timea += TimerH, Hours
     Timea += TimerM, Minutes
     expire := SubStr(timea, 9, 4)
     expire := ST_Insert(":", expire, 3)
     GuiControl, SettingsGUIA:, userTimerInfos, % expire
  } Else
     GuiControl, SettingsGUIA:, userTimerInfos, --:--

  act := (OutputVarB=1) ? "Enable" : "Disable"
  GuiControl, % act, userAlarmHours
  GuiControl, % act, userAlarmMins
  GuiControl, % act, userAlarmMsg
  GuiControl, % act, userAlarmSound
  GuiControl, % act, userAlarmSnooze
  GuiControl, % act, editF3
  GuiControl, % act, editF4
  GuiControl, % act, editF5
  GuiControl, % act, userAlarmRepeated
  GuiControl, % act, userAlarmFreq
  GuiControl, % act, editF6
  GuiControl, % act, btn2

  act := (OutputVarB=1 && doRepeat=1) ? "SettingsGUIA: Enable" : "SettingsGUIA: Disable"
  GuiControl, % act, txt1
  GuiControl, % act, userAlarmExceptSeculu
  GuiControl, % act, userAlarmExceptPerso
  GuiControl, % act, userAlarmExceptRelu
  GuiControl, % act, userAlarmWday1
  GuiControl, % act, userAlarmWday2
  GuiControl, % act, userAlarmWday3
  GuiControl, % act, userAlarmWday4
  GuiControl, % act, userAlarmWday5
  GuiControl, % act, userAlarmWday6
  GuiControl, % act, userAlarmWday7
  GuiControl, % act, userAlarmWday7

  act := (OutputVarA=1) ? "SettingsGUIA: Enable" : "SettingsGUIA: Disable"
  GuiControl, % act, userTimerHours
  GuiControl, % act, userTimerMins
  GuiControl, % act, userTimerMsg
  GuiControl, % act, userTimerSound
  GuiControl, % act, userTimerInfos
  GuiControl, % act, userTimerFreq
  GuiControl, % act, btn1
  GuiControl, % act, editF10
  GuiControl, % act, editF1
  GuiControl, % act, editF2
  GuiControl, % act, UItimerInfoz
}

BtnApplyAlarms() {
  Gui, SettingsGUIA: Default
  Gui, SettingsGUIA: Submit, NoHide
  userTimerMsg := Trim(userTimerMsg)
  userAlarmMsg := Trim(userAlarmMsg)
  userAlarmWeekDays := ""
  GuiControlGet, userAlarmExceptRelu
  GuiControlGet, userAlarmExceptSeculu
  GuiControlGet, userAlarmExceptPerso
  If userAlarmExceptRelu
     userAlarmWeekDays .= "r|"
  If userAlarmExceptSeculu
     userAlarmWeekDays .= "s|"
  If userAlarmExceptPerso
     userAlarmWeekDays .= "p|"

  Loop, 7
  {
     GuiControlGet, userAlarmWday%A_Index%
     If userAlarmWday%A_Index%
        userAlarmWeekDays .= A_Index "|"
  }

  INIaction(1, "userMustDoAlarm", "SavedSettings")
  INIaction(1, "AlarmersDarkScreen", "SavedSettings")
  INIaction(1, "userTimerSound", "SavedSettings")
  INIaction(1, "userAlarmSound", "SavedSettings")
  INIaction(1, "userAlarmMsg", "SavedSettings")
  INIaction(1, "userAlarmHours", "SavedSettings")
  INIaction(1, "userAlarmMins", "SavedSettings")
  INIaction(1, "userAlarmRepeated", "SavedSettings")
  INIaction(1, "userAlarmSnooze", "SavedSettings")
  INIaction(1, "userAlarmFreq", "SavedSettings")
  INIaction(1, "userTimerFreq", "SavedSettings")
  INIaction(1, "userAlarmWeekDays", "SavedSettings")
  INIaction(1, "userTimerMins", "SavedSettings")
  INIaction(1, "userTimerHours", "SavedSettings")
  INIaction(1, "userTimerMsg", "SavedSettings")
  If (userMustDoTimer=1 && (userTimerHours || userTimerMins))
  {
     coreInitUserTimer()
  } Else 
  {
     userTimerExpire := userMustDoTimer := 0
     SetTimer, doUserTimerAlert, Off
  }

  If (userMustDoAlarm=1 && isValidAlarmTime(userAlarmHours, userAlarmMins))
  {
     SetTimer, doUserAlarmAlert, Off
     userAlarmIsSnoozed := 0
     startAlarmTimer("rr")
     Sleep, 1
     startAlarmTimer()
  } Else
  {
     startAlarmTimer("rr")
     Sleep, 1
     userAlarmIsSnoozed := userMustDoAlarm := 0
     INIaction(1, "userMustDoAlarm", "SavedSettings")
     SetTimer, doUserAlarmAlert, Off
     SetTimer, PlayAlarmedBell, Off
  }

  CloseWindow()
}

doUserTimerAlert() {
  userMustDoTimer := 0
  stopStrikesNow := stopAdditionalStrikez := 0
  thisMsg := Trim(userTimerMsg) ? "`n" Trim(userTimerMsg) : ""
  If (AlarmersDarkScreen=1)
     ScreenBlocker(0, 1, 1, 1)

  ; WinSet, AlwaysOnTop, Off, ScreenShader
  PlayTimerBell(1)
  showTimeNow()
  If (userTimerSound!=6)
     SetTimer, PlayTimerBell, % userTimerFreq * 1000

  th := (userTimerHours<10) ? "0" . userTimerHours : userTimerHours
  tm := (userTimerMins<10) ? "0" . userTimerMins : userTimerMins
  If !thisMsg
  {
     userTimerExpire := 0
     Sleep, 350
  } Else
  {
     MsgBox, % 4096+4, Timer: %appName%, % "Timer message: " thisMsg "`n`nPress Yes to repeat this alert in " th ":" tm "."
     IfMsgBox, Yes
     {
        userMustDoTimer := 1
        coreInitUserTimer()
     } Else userTimerExpire := 0
  }

  SetTimer, PlayTimerBell, Off
  ScreenBlocker(1)
}

coreInitUserTimer(rz:=0) {
     Static lk := []
     If (rz="last")
        Return lk

     delayu := MCI_ToMilliseconds(userTimerHours, userTimerMins, 0) + 350
     lmin := (userTimerMins + userTimerHours*60) * 60
     lk := [A_Now, lmin]
     Timea := A_Now
     Timea += userTimerHours, Hours
     Timea += userTimerMins, Minutes
     userTimerExpire := SubStr(timea, 9, 4)
     userTimerExpire := ST_Insert(":", userTimerExpire, 3)
     SetTimer, doUserTimerAlert, % -delayu
}

doUserAlarmAlert() {
  stopStrikesNow := stopAdditionalStrikez := 0
  thisMsg := Trim(userAlarmMsg) ? "`n" Trim(userAlarmMsg) : "NONE"
  If (AlarmersDarkScreen=1)
     ScreenBlocker(0, 1, 1, 1)

  showTimeNow()
  PlayAlarmedBell(1)
  If (userAlarmSound!=6)
     SetTimer, PlayAlarmedBell, % userAlarmFreq * 1000

  friendly := (userAlarmIsSnoozed=1) ? " (snoozed)" : ""
  friendly2 := (userAlarmIsSnoozed=1) ? " again" : ""
  MsgBox, % 4096+4, Alarm%friendly%: %appName%, % "Alarm message: " thisMsg "`n`nPress Yes to snooze" friendly2 " for " userAlarmSnooze " minutes."
  IfMsgBox, Yes
  {
     startAlarmTimer("rr")
     userMustDoAlarm := 1
     userAlarmIsSnoozed := 1
     SetTimer, doUserAlarmAlert, % -(userAlarmSnooze * 60000)
  } Else If (userAlarmRepeated=1)
  {
     startAlarmTimer("rr")
     SetTimer, doUserAlarmAlert, Off
     userAlarmIsSnoozed := 0
     userMustDoAlarm := 1
     startAlarmTimer()
  } Else
  {
     SetTimer, doUserAlarmAlert, Off
     userAlarmIsSnoozed := 0
     userMustDoAlarm := 0
     startAlarmTimer("rr")
  }
  SetTimer, PlayAlarmedBell, Off
  ScreenBlocker(1)
  INIaction(1, "userMustDoAlarm", "SavedSettings")
}

isValidAlarmTime(hours, minutes) {
; Whether the two make up a time of day: both numbers, the hour within 0-23 and the minute
; within 0-59. The callers used to test the two for being non-zero instead, which threw the
; midnight alarm, 00:00, away - a time of day like any other.
   If (hours="" || minutes="" || !isNumber(hours) || !isNumber(minutes))
      Return 0

   Return (hours>=0 && hours<=23 && minutes>=0 && minutes<=59) ? 1 : 0
}

startAlarmTimer(kpl:=0) {
  Static lastzz := 9871
  If (userAlarmIsSnoozed=1 || kpl="rr")
  {
     lastzz := 9871
     Return
  }

  canDo := (userMustDoAlarm=1 && isValidAlarmTime(userAlarmHours, userAlarmMins)) ? 1 : 0
  If (canDo && userAlarmRepeated=1)
     canDo := InStr(userAlarmWeekDays, A_WDay) ? 1 : 0

  If (canDo && userAlarmRepeated=1 && ObserveHolidays=1 && StrLen(isHolidayToday)>2)
     canDo := (InStr(userAlarmWeekDays, "p") && TypeHolidayOccured=3) || (InStr(userAlarmWeekDays, "s") && TypeHolidayOccured=2 && ObserveSecularDays=1) || (InStr(userAlarmWeekDays, "r") && TypeHolidayOccured=1 && ObserveReligiousDays=1) ? 0 : 1

  If !canDo
  {
     lastzz := 9871
     SetTimer, doUserAlarmAlert, Off
     Return
  }

  nowu := A_Now
  tH := (StrLen(userAlarmHours)!=2) ? "0" . userAlarmHours : userAlarmHours
  tM := (StrLen(userAlarmMins)!=2) ? "0" . userAlarmMins : userAlarmMins
  newu := A_Year A_Mon A_DD tH tM . "00"
  If (nowu>=newu)
  {
     newu += 1, Days
     isAlarmTmrw := (userAlarmRepeated=1) ? 0 : 1
  } Else
     isAlarmTmrw := 0

  nss := newu
  nss -= nowu, Seconds
  If (lastzz<18)
     Return

  lastzz := nss
  nsd := nss*1000
  ; ToolTip, % nowu "`n" newu "`n" nss "`n" nsd , , , 2
  SetTimer, doUserAlarmAlert, % -nsd
}

getPercentOfAstroSeason(z:=0) {
   ; Static t := 0
   td := isLeapYear() ? 366 : 365
   t := (z>0) ? z : A_YDay
   ; t += 5
   ; If (t>366)
   ;    t := 0

   If (t>dSolsDay)
   {
      c := 4
      dayz := td - dSolsDay + mEquiDay
      passedDayz := td - t + mEquiDay
   } Else If (t<=mEquiDay)
   {
      c := 5
      dayz := td - dSolsDay + mEquiDay
      passedDayz := t + (td - dSolsDay)
   } Else If (t>sEquiDay)
   {
      c := 3
      dayz := dSolsDay - sEquiDay
      passedDayz := dSolsDay - t
   } Else If (t>jSolsDay)
   {
      c := 2
      dayz := sEquiDay - jSolsDay
      passedDayz := sEquiDay - t
   } Else If (t>mEquiDay)
   {
      c := 1
      dayz := jSolsDay - mEquiDay
      passedDayz := jSolsDay - t
   }
   If (c!=5)
      passedDayz := dayz - passedDayz

   r := passedDayz / dayz
   ; ToolTip, % "td=" td " | " t "=" c "`n" passedDayz "//" dayz "=" r , , , 2
   Return r
}

getPercentOfToday(ByRef minsPassed:=0) {
   FormatTime, CurrentDateTime,, yyyyMMddHHmm
   FormatTime, CurrentDay,, yyyyMMdd
   FirstMinOfDay := CurrentDay "0000"
   EnvSub, CurrentDateTime, %FirstMinOfDay%, Minutes
   minsPassed := CurrentDateTime + 1    ; the minute of the day being lived, from 1 to 1440
   Return minsPassed/1440
}

fnOutputDebug(msg, forced:=0) {
   If (debugMode=1 || forced=1)
      OutputDebug, % "QPV: " Trim(msg)
}

isLeapYear(thisYear:=0) {
   PersonalDate := (thisYear>0) ? thisYear 0229010101 : A_Year 0229010101
   FormatTime, PersonalDate, %PersonalDate%, LongDate
   r := (StrLen(PersonalDate)>3) ? 1 : 0
   Return r
}

PanelAboutWindow() {
    If reactWinOpened(A_ThisFunc, 1)
       Return

    GenericPanelGUI(0)
    LastWinOpened := A_ThisFunc
    AnyWindowOpen := 1
    INIaction(1, "LastWinOpened", "SavedSettings")
    btnWid := 100
    txtWid := 360
    Global btn1
    Gui, Font, c%AboutTitleColor% s20 Bold, Arial, -wrap
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section gTollExtraNoon hwndhBellIcon, %A_ScriptDir%\resources\bell-image.png
    Gui, Add, Text, x+7 y10, %appName%
    Gui, Font, s12 Bold, Arial, -wrap
    Gui, Add, Link, y+4 hwndhLink0, Developed by <a href="https://marius.sucan.ro">Marius Şucan</a>.
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
    }

    btnW1 := (PrefsLargeFonts=1) ? 105 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    nW := (PrefsLargeFonts=1) ? 65 : 60
    nH := (PrefsLargeFonts=1) ? 35 : 30

    Gui, Add, Text, x15 y+5 w1 h1 Section, .
    If (A_OSVersion="WIN_XP")
    {
       Gui, Font,, Arial ; only as backup, doesn't have all characters on XP
       Gui, Font,, Symbola
       Gui, Font,, Segoe UI Symbol
       Gui, Font,, DejaVu Sans
       Gui, Font,, DejaVu LGC Sans
    }

    If (A_OSVersion="WIN_XP")
       doResetGuiFont()

    Gui, Add, Tab3, xm+5 Section Choose1 AltSubmit, About|Features|Change log

    Gui, Tab, 1
    Gui, Add, Text, x+1 y+15 w%txtWid% Section, Dedicated to Christians, church-goers and bell lovers.
    Gui, Add, Text, xs y+15 Section w%txtWid%, This application contains code and sounds from various entities. You can find more details in the source code.
    compiled := (A_IsCompiled=1) ? "Compiled. " : "Uncompiled. "
    compiled .= (A_PtrSize=8) ? "x64. " : "x32. "
    Gui, Add, Text, xs y+15 w%txtWid%, Current version: v%version% from %ReleaseDate%.`nInternal AHK version: %A_AhkVersion%. %compiled%`nOS: %A_OSVersion%. Elevated=%A_IsAdmin%.
    If (storeSettingsREG=1)
       Gui, Add, Link, xs y+10 w%txtWid% hwndhLink2, This application was downloaded through <a href="ms-windows-store://pdp/?productid=9PFQBHN18H4K">Windows Store</a>.
    Else      
       Gui, Add, Link, xs y+10 w%txtWid% hwndhLink2, The development page is <a href="https://github.com/marius-sucan/ChurchBellsTower">on GitHub</a>.

    Gui, Font, Bold
    Gui, Add, Link, xp+30 y+10 hwndhLink1, To keep the development going, `n<a href="https://www.paypal.me/MariusSucan/15">please donate</a> or <a href="mailto:marius.sucan@gmail.com">send me feedback</a>.
    Gui, Add, Picture, x+10 yp+0 gDonateNow hp w-1 +0xE hwndhDonateBTN, %A_ScriptDir%\resources\paypal.png
    doResetGuiFont()

    Gui, Tab, 2
    FileRead, cnt, *t *P65001 %A_ScriptDir%\readme-features.txt
    GuiAddEdit("x+1 y+15 ReadOnly r12 w" txtWid, cnt, "Features list")

    Gui, Tab, 3
    FileRead, cnt, *t *P65001 %A_ScriptDir%\bells-tower-change-log.txt
    cnt := SubStr(cnt, 319)
    GuiAddEdit("x+1 y+15 ReadOnly r12 w" txtWid, cnt, "Application change log")

    Gui, Tab

    btnW1 := (PrefsLargeFonts=1) ? 110 : 80
    btnW2 := (PrefsLargeFonts=1) ? 80 : 55
    btnW3 := (PrefsLargeFonts=1) ? 110 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    Gui, Add, Button, xm+0 y+25 Section h%btnH% w%btnW1% Default gCloseWindowAbout, &Deus lux est
    Gui, Add, Button, x+5 hp wp-15 gPanelTodayInfos, &Today
    Gui, Add, Button, x+5 hp w%btnW3% gPanelIncomingCelebrations, &Celebrations
    Gui, Add, Button, x+5 hp w%btnW2% gPanelShowSettings, &Settings
    Gui, Add, Button, x+1 hp w30 ginvokeSettingsContextMenu +hwndhTemp, ▼
    ToolTip2ctrl(hTemp, "More options (context menu)")

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, About: %appName%
}

PanelSunYearGraphTable() {
    If reactWinOpened(A_ThisFunc, 7)
       Return

    GenericPanelGUI(0)
    ; LastWinOpened := A_ThisFunc
    AnyWindowOpen := 7
    INIaction(0, "SolarYearGraphMode", "SavedSettings")
    btnWid := 100
    txtWid := 360
    lstWid := 435
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
       lstWid := lstWid + 245
    }
    If !listedCountries
       loadGeoData()

    graphW := lstWid - 15
    graphH := (PrefsLargeFonts=1) ? 280 : 190
    Global LViewSets, LViewRises, uiInfoGeoYear, LViewMuna, LViewSunCombined, GraphInfoLine
    Gui, Add, Tab3, x+5 y+15 AltSubmit Choose%tabChoice% vCurrentTabLV, Summary|Rise|Set|Durations|Graph
    Gui, Tab, 1
    GuiAddListView("x+5 y+10 w" lstWid " r15 -multi +ReadOnly Grid vLViewSunCombined", "Day|Date|Dawn|Sunrise|Noon|Altitude|Sunset|Dusk|Sunlight", "Entire year sun events")
    Gui, Tab, 2
    GuiAddListView("x+5 y+10 w" lstWid " r15 -multi +ReadOnly Grid vLViewRises", "Day|Dawn|Rise|Civil twilight length", "Entire year sun rises")
    Gui, Tab, 3
    GuiAddListView("x+5 y+10 w" lstWid " r15 -multi +ReadOnly Grid vLViewSets", "Day|Sunset|Dusk|Civil twilight length", "Entire year sunsets")
    Gui, Tab, 4
    GuiAddListView("x+5 y+10 w" lstWid " r15 -multi +ReadOnly Grid vLViewOthers", "Day|Date|Sunlight|Diff|Twilight|Diff|Total light|Difference", "Daylight time differences")
    Gui, Tab, 5
    Gui, Add, Text, x+10 y+10 Section +0x200 +hwndhTemp, Location:
    widu := (PrefsLargeFonts=1) ? 190 : 120
    GuiAddDropDownList("x+5 w" widu " AltSubmit gUIcountryGraphChooser Choose" uiUserCountry " vuiUserCountry", countriesList, [hTemp, 0, "Country"])
    GuiAddDropDownList("x+5 wp AltSubmit gUIcityGraphChooser Choose" uiUserCity " vuiUserCity", getCitiesList(uiUserCountry), "City")
    Gui, Add, Button, x+5 hp gSearchOpenPanelEarthMap, &Search
    Gui, Add, Button, x+5 hp gbtnUIremoveUserGeoLocation vUIbtnRemGeoLoc, &Remove
    Gui, Add, Text, xs y+10 w%graphW% -wrap vGraphInfoLine, Hover graph for more information.`n-
    Gui, Add, Text, xs y+10 w1 h1, Sunlight duration graph for entire year
    Gui, Add, Text, xp yp w%graphW% h%graphH% Section +0x8 +0xE +hwndhSolarGraphPic gBtnToggleYearGraphMode, Preview area

    Gui, Tab
    btnW := (PrefsLargeFonts=1) ? 80 : 55
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    If (A_PtrSize!=8)
       Gui, Add, Text, xm+0 y+10, WARNING: The astronomy features are not available on the 32 bits edition.
    Else
       Gui, Add, Text, xm+0 y+10 wp Section -wrap vuiInfoGeoData, Please wait...

    Gui, Add, Text, xp y+5 wp -wrap vUIastroInfoAnnum, -
    Gui, Add, Button, xp y+20 h%btnH% w%btnW% gPanelTodayInfos, &Back
    Gui, Add, Button, x+5 hp wp gbtnCopySolarData, &Copy
    Gui, Add, Button, x+5 hp wp gbtnHelpYearSolarGraph, &Help
    widu := (PrefsLargeFonts=1) ? 40 : 32
    GuiAddButton("x+5 hp w" widu " guiPrevSolarDataYear", "<", "Previous year")
    Gui, Add, Button, x+1 hp wp+15 guiThisSolarDataYear vuiInfoGeoYear +hwndhTemp, % SubStr(uiUserFullDateUTC, 1, 4)
    ToolTip2ctrl(hTemp, "Reset to current year")
    GuiAddButton("x+1 hp wp-15 guiNextSolarDataYear", ">", "Next year")
    Gui, Add, Button, x+5 w%btnW% hp Default gCloseWindow, &Close

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Year graph and table (sun): %appName%
    uiPopulateTableYearSolarData()
}

PanelMoonYearGraphTable() {
    If reactWinOpened(A_ThisFunc, 9)
       Return

    GenericPanelGUI(0)
    ; LastWinOpened := A_ThisFunc
    AnyWindowOpen := 9
    INIaction(0, "SolarYearGraphMode", "SavedSettings")
    btnWid := 100
    txtWid := 360
    lstWid := 435
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
       lstWid := lstWid + 245
    }
    If !listedCountries
       loadGeoData()

    graphW := lstWid - 15
    graphH := (PrefsLargeFonts=1) ? 280 : 190
    Global LViewSets, LViewRises, uiInfoGeoYear, LViewMuna, LViewSunCombined, GraphInfoLine
    Gui, Add, Tab3, x+5 y+15 AltSubmit Choose%tabChoice% vCurrentTabLV, Summary|Graph|Moon phases
    Gui, Tab, 1
    GuiAddListView("x+5 y+10 w" lstWid " r15 -multi +ReadOnly Grid vLViewSunCombined", "Day|Date|Rise|Culminant|Altitude|Set|Moonlight|Diff", "Entire year moon events")
    Gui, Tab, 2
    widu := (PrefsLargeFonts=1) ? 190 : 120
    Gui, Add, Text, x+10 y+10 Section +0x200 +hwndhTemp, Location:
    GuiAddDropDownList("x+5 w" widu " AltSubmit gUIcountryGraphChooser Choose" uiUserCountry " vuiUserCountry", countriesList, [hTemp, 0, "Country"])
    GuiAddDropDownList("x+5 wp AltSubmit gUIcityGraphChooser Choose" uiUserCity " vuiUserCity", getCitiesList(uiUserCountry), "City")
    Gui, Add, Button, x+5 hp gPanelEarthMap, &Map
    Gui, Add, Button, x+5 hp gbtnUIremoveUserGeoLocation vUIbtnRemGeoLoc, &Remove
    Gui, Add, Text, xs y+10 w%graphW% -wrap vGraphInfoLine, Hover graph for more information.`n-
    Gui, Add, Text, xs y+10 w1 h1, Moonlight duration graph for entire year
    Gui, Add, Text, xp yp w%graphW% h%graphH% Section +0x8 +0xE +hwndhSolarGraphPic gBtnToggleYearGraphMode, Preview area

    Gui, Tab, 3
    GuiAddListView("x+5 y+10 w" lstWid " r15 -multi +ReadOnly Grid vLViewMuna", "Day|Date|Lunar phase|Age|Constellation", "Entire year moon phases")

    Gui, Tab
    btnW := (PrefsLargeFonts=1) ? 80 : 55
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    If (A_PtrSize!=8)
       Gui, Add, Text, xm+0 y+10, WARNING: The astronomy features are not available on the 32 bits edition.
    Else
       Gui, Add, Text, xm+0 y+10 wp Section -wrap vuiInfoGeoData, Please wait...

    Gui, Add, Text, xp y+5 wp -wrap vUIastroInfoAnnum, -
    Gui, Add, Button, xp y+20 h%btnH% w%btnW% gPanelTodayInfos, &Back
    Gui, Add, Button, x+5 hp wp gbtnCopySolarData, &Copy
    Gui, Add, Button, x+5 hp wp gbtnHelpYearMoonGraph, &Help
    widu := (PrefsLargeFonts=1) ? 40 : 32
    GuiAddButton("x+5 hp w" widu " guiPrevSolarDataYear", "<", "Previous year")
    Gui, Add, Button, x+1 hp wp+15 guiThisSolarDataYear vuiInfoGeoYear +hwndhTemp, % SubStr(uiUserFullDateUTC, 1, 4)
    ToolTip2ctrl(hTemp, "Reset to current year")
    GuiAddButton("x+1 hp wp-15 guiNextSolarDataYear", ">", "Next year")
    Gui, Add, Button, x+5 w%btnW% hp Default gCloseWindow, &Close

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Year graph and table (moon): %appName%
    uiPopulateTableYearMoonData()
}

btnHelpYearSolarGraph() {
  simpleMsgBoxWrapper(appName, "The graph has two modes, switchable by clicking it:`n `n1. Sunlight and civil twilight duration per day. The X axis shows the days of the year (1–365). Y axis shows hours (00:00 – 23:59). Taller yellow bars indicate longer sunlight duration. The darker yellow at the top represents civil twilight. Bar shading reflects the solar-noon angle: the higher the sun is at noon, the brighter the shade.`n `n2. Sunrise and sunset events. The X axis shows the days of the year. Y axis shows time, with 00:00 at the top and 23:59 at the bottom. The events are shown as dots: brighter dots indicate sunrise and sunset, darker dots indicate dawn and dusk, and bright blueish dots between sunrise and sunset represent solar noon.")
}

btnHelpYearMoonGraph() {
  simpleMsgBoxWrapper(appName, "The graph has two modes, switchable by clicking it.`n `n1. Moonlight duration per day: The X axis shows days 1–365. Y axis shows hours from 00:00 to 23:59. Taller yellow bars indicate longer moonlight duration. Bar shading is based on the day’s culminant angle: the higher the Moon rises, the brighter the bar.`n `n2. Moon rises and sets: The X axis shows days of the year. Y axis shows hours with 00:00 at the top and 23:59 at the bottom. Moonrise and moonset times are shown as dots. The brighter dots represent rises and darker dots represent sets.`n `nThe background uses a wave pattern calculated from the Moon’s illumination fraction.")
}

buildNoDiacriticsMap() {
; builds the character map used by getNoDiacriticsStr(); it covers every accented Latin
; letter found in the geo-locations lists, and the usual variants a user might type
   charru := []
   charru.a := "àáâãäåāăąǎạảấầẩẫậắằẳẵặəÀÁÂÃÄÅĀĂĄǍẠẢẤẦẨẪẬẮẰẲẴẶƏ"
   charru.c := "çćĉċčÇĆĈĊČ"
   charru.d := "ďđðḑḏḍĎĐÐḐḎḌ"
   charru.e := "èéêëēĕėęěẹẻẽếềểễệÈÉÊËĒĔĖĘĚẸẺẼẾỀỂỄỆ"
   charru.g := "ĝğġģǧĜĞĠĢǦ"
   charru.h := "ĥħḥḩẖĤĦḤḨ"
   charru.i := "ìíîïĩīĭįıịỉḯÌÍÎÏĨĪĬĮİỊỈḮ"
   charru.j := "ĵĴ"
   charru.k := "ķḵĶḴ"
   charru.l := "ĺļľŀłĹĻĽĿŁ"
   charru.n := "ñńņňŉṅÑŃŅŇṄ"
   charru.o := "òóôõöøōŏőơǒọỏốồổỗộớờởỡợÒÓÔÕÖØŌŎŐƠǑỌỎỐỒỔỖỘỚỜỞỠỢ"
   charru.r := "ŕŗřṛṟŔŖŘṚṞ"
   charru.s := "śŝşšșṣŚŜŞŠȘṢ"
   charru.t := "ţťŧțṭṯŢŤŦȚṬṮ"
   charru.u := "ùúûüũūŭůűųưǔụủứừửữựÙÚÛÜŨŪŬŮŰŲƯǓỤỦỨỪỬỮỰ"
   charru.w := "ŵẁẃẅŴẀẂẄ"
   charru.y := "ýÿỳỵỷỹÝŸỲỴỶỸ"
   charru.z := "źżžẑẓẕŹŻŽẐẒẔ"
   charru.ae := "æÆ"
   charru.oe := "œŒ"
   charru.ss := "ß"
   charru.th := "þÞ"

   foldu := []
   For basu, listu in charru
   {
       Loop, Parse, listu
          foldu[A_LoopField] := basu
   }

   listu := "'’‘‛ʻʼ´" Chr(96)          ; apostrophes and their lookalikes vanish
   Loop, Parse, listu
      foldu[A_LoopField] := ""
   listu := "-–—‐,./\()[]" Chr(0xA0)   ; separators become plain spaces
   Loop, Parse, listu
      foldu[A_LoopField] := A_Space
   Loop, 112                           ; combining accents, U+0300 to U+036F;
      foldu[Chr(0x2FF + A_Index)] := ""    ; some geonames entries come decomposed
   Return foldu
}

getNoDiacriticsStr(str) {
; folds a string for the location search: letters lose their diacritics and cedillas,
; apostrophes are dropped, separators and whitespace runs become single spaces; the
; result serves only the scorify* comparisons, what the user sees stays untouched
   Static foldedChars := ""
   If !IsObject(foldedChars)
      foldedChars := buildNoDiacriticsMap()

   If !RegExMatch(str, "[^0-9A-Za-z ]|  |^ | $")
      Return str

   nStr := ""
   Loop, Parse, str
      nStr .= foldedChars.HasKey(A_LoopField) ? foldedChars[A_LoopField] : A_LoopField
   Return Trim(RegExReplace(nStr, "\s+", A_Space))
}

scorifyCompareWords(thisUserWord, siti) {
   score := 0
   If (siti=thisUserWord)
      score += 15
   If (n := InStr(siti, thisUserWord))
      score += StrLen(thisUserWord)
   If (n=1)
      score += 10
   Else If (n=2)
      score += 5
   Else If (n=3)
      score += 2

   ls := StrLen(siti)
   lw := StrLen(thisUserWord)
   If (ls=lw && score)
      score += 2
   ; Else If (ls=lw)
   ;    score += 1

   score *= 2
   If (SubStr(siti, 1, 1)=SubStr(thisUserWord, 1, 1))
      score += 1
   If (SubStr(siti, 1, 2)=SubStr(thisUserWord, 1, 2))
      score += 2

   If (ls>2 && lw>2)
   {
      If (SubStr(siti, 2, 2)=SubStr(thisUserWord, 2, 2))
         score += 1
      If (SubStr(siti, 1, 3)=SubStr(thisUserWord, 1, 3))
         score += 3
   }
   Return score
}

scorifyStrictCompareWords(thisUserWord, siti) {
   score := 0
   If (siti=thisUserWord)
      score += 32
   n := InStr(siti, thisUserWord)
   If (n=1)
      score += 29
   Else If (n=2)
      score += 1

   ls := StrLen(siti)
   lw := StrLen(thisUserWord)
   If (ls=lw && score)
      score += 3

   Return score*2
}

PerformGeoDataSearch() {
    If (AnyWindowOpen!=8)
       Return

    Gui, SettingsGUIA: Default
    GuiControlGet, GeoDataSearchField
    Gui, SettingsGUIA: ListView, LViewOthers
    LV_Delete()

    Static normCache := []   ; city names folded once, reused across searches; keyed by name, so entries never go stale
    wuserQuery := getNoDiacriticsStr(GeoDataSearchField)
    If (StrLen(wuserQuery)<2)
       Return

    userQuery := []
    Loop, Parse, wuserQuery, %A_Space%
    {
        If StrLen(A_LoopField)>1
           userQuery.Push(A_LoopField)   ; a single letter cannot influence the score; keeping it would only raise the threshold
    }

    userCountWords := userQuery.Count()
    If !userCountWords
       Return

    multiWords := (userCountWords>1) ? 1 : 0
    minScore := 13*userCountWords
    GuiControl, -Redraw, LViewOthers
    cntryScore := 0
    prevCntry := Chr(1)
    Loop, % listedExtendedLocations
    {
        k := extendedGeoData[A_Index]
        cauntri := k[1]
        If (cauntri!=prevCntry)   ; the list is grouped by country, so the country score carries over between rows
        {
           prevCntry := cauntri
           ncauntri := (k[8]="") ? cauntri : k[8]
           cntryScore := multiWords ? scorifyStrictCompareWords(wuserQuery, ncauntri) : 0
           Loop, % userCountWords
               cntryScore += scorifyCompareWords(userQuery[A_Index], ncauntri)
        }

        nsiti := (k[9]="") ? k[2] : k[9]
        score := cntryScore
        Loop, % userCountWords
            score += scorifyCompareWords(userQuery[A_Index], nsiti) + 5

        If (multiWords)
           score += scorifyStrictCompareWords(wuserQuery, nsiti) + 5

        If (score<minScore)
           Continue

        LV_Add("", cauntri, k[2], k[3], k[4], k[5], k[7], score, A_Index)
    }

    ctr := countriesArrayList.Count()
    Loop, % ctr
    {
         ctrIndex := A_Index
         cities := geoData[ctrIndex "|-1"]
         cauntri := countriesArrayList[ctrIndex]
         ncauntri := getNoDiacriticsStr(cauntri)
         cntryScore := multiWords ? scorifyStrictCompareWords(wuserQuery, ncauntri) : 0
         Loop, % userCountWords
             cntryScore += scorifyCompareWords(userQuery[A_Index], ncauntri)

         Loop, % cities
         {
             thisu := geoData[ctrIndex "|" A_Index]
             If !thisu
                Continue

             elemu := StrSplit(thisu, "|")
             siti := LTrim(elemu[1], "*")   ; the star marks a capital in the lists; it is no part of the name
             nsiti := normCache[siti]
             If (nsiti="")
                normCache[siti] := nsiti := getNoDiacriticsStr(siti)

             score := cntryScore
             Loop, % userCountWords
                score += scorifyCompareWords(userQuery[A_Index], nsiti) + 5

             If (multiWords)
                score += scorifyStrictCompareWords(wuserQuery, nsiti) + 5

             If (score<minScore)
                Continue

             LV_Add("", cauntri, elemu[1], elemu[2], elemu[3], elemu[4], elemu[6], score, ctrIndex "|" A_Index)
         }
    }

    LV_ModifyCol(3, "Float")
    LV_ModifyCol(4, "Float")
    LV_ModifyCol(5, "Float")
    LV_ModifyCol(6, "Integer")
    LV_ModifyCol(7, "Integer SortDesc")
    Loop, 8
        LV_ModifyCol(A_Index, "AutoHdr Left")
    GuiControl, +Redraw, LViewOthers
}

btnUIremoveUserGeoLocation() {
   Gui, SettingsGUIA: Default
   GuiControlGet, uiUserCountry
   GuiControlGet, uiUserCity
   cities := geoData["1|-1"]
   If (uiUserCountry!=1)
      Return

   If (cities<2)
   {
      ToolTip, The last custom location cannot be removed.
      SetTimer, removeTooltip, -2000
      Return
   }

   thisu := []
   thisIndex := 0
   Loop, % cities
   {
       If (A_Index!=uiUserCity)
       {
          thisIndex++
          thisu[thisIndex] := geoData["1|" A_Index]
       }
   }

   Loop, % cities - 1
      geoData["1|" A_Index] := thisu[A_Index]

   geoData["1|-1"] := cities - 1
   FileRead, userlist, %WinStorePath%\resources\geo-locations-userlist.txt
   newu := "", thisIndex := 0
   Loop, Parse, userlist, `n, `r
   {
       If StrLen(A_LoopField)<3
          Continue

       thisIndex++
       If (thisIndex!=uiUserCity)
          newu .= "`n" A_LoopField "`n"
   }

   Sleep, 50
   FileDelete, %WinStorePath%\resources\geo-locations-userlist.txt
   Sleep, 50
   FileAppend, % "`n" Trim(newu, "`n`r") "`n" , %WinStorePath%\resources\geo-locations-userlist.txt, UTF-8
   uiSelectUserGeoLocation(uiUserCity - 1)   ; the entry that took the place of the one just removed
}

btnUIupdateUserGeoLocation(idu, strA, str) {
; Rewrites in the custom locations file the entry whose line carries idu - the name it goes by,
; with the country and the pipe on either side of it - and puts strA in its place in the loaded
; index. It gives back the position that entry holds in the list, or 0 when the file has no such
; line, which leaves the caller free to say so rather than to assume the change went through.

   FileRead, userlist, %WinStorePath%\resources\geo-locations-userlist.txt
   newu := "",  thisIndex := 0, thisIDu := 0
   Loop, Parse, userlist, `n, `r
   {
       If StrLen(A_LoopField)<3
          Continue

       thisIndex++
       If InStr(A_LoopField, idu)
       {
          thisIDu := thisIndex
          newu .= "`n" str "`n"
       } Else
          newu .= "`n" A_LoopField "`n"
   }

   If !thisIDu
      Return 0

   geoData["1|" thisIDu] := strA
   Sleep, 50
   FileDelete, %WinStorePath%\resources\geo-locations-userlist.txt
   Sleep, 50
   FileAppend, % "`n" Trim(newu, "`n`r") "`n" , %WinStorePath%\resources\geo-locations-userlist.txt, UTF-8
   SoundBeep , 900, 100
   Return thisIDu
}

uiSelectUserGeoLocation(cityIdx) {
; Brings the custom locations list up to date wherever it is on display and picks one of its
; entries out. The country and the city lists stand on the Today panel and on the two year graph
; panels alike, and whichever of them is open, its own chooser has to run afterwards: everything
; that hangs off the selection - the panel readings, the graphs, the tables, the Add and the
; Remove buttons and the location written down in the settings - is settled there and nowhere else.

   cities := geoData["1|-1"]
   If (!cities || !isVarEqualTo(AnyWindowOpen, 6, 7, 9))
      Return

   cityIdx := clampInRange(Round(cityIdx), 1, cities)
   Gui, SettingsGUIA: Default
   uiUserCountry := 1   ; the custom locations always stand first in the countries list
   uiUserCity := cityIdx
   GuiControl, SettingsGUIA: Choose, uiUserCountry, 1
   GuiControl, SettingsGUIA:, uiUserCity, % "|" getCitiesList(1)
   GuiControl, SettingsGUIA: Choose, uiUserCity, % cityIdx
   INIaction(1, "uiUserCountry", "SavedSettings")
   INIaction(1, "uiUserCity", "SavedSettings")
   If (AnyWindowOpen=6)
      UIcityChooser()
   Else
      UIcityGraphChooser()
}

simpleMsgBoxWrapper(winTitle, msg, buttonz:=0, defaultBTN:=1, iconz:=0, modality:=0, optionz:=0, guiu:="SettingsGUIA") {
   ; Buttonz options:
   ; 0 = OK (that is, only an OK button is displayed)
   ; 1 = OK/Cancel
   ; 2 = Abort/Retry/Ignore
   ; 3 - Yes/No/Cancel
   ; 4 = Yes/No
   ; 5 = Retry/Cancel
   ; 6 = Cancel/Try Again/Continue

   ; Iconz options:
   ; 16 = Icon Hand (stop/error)
   ; 32 = Icon Question
   ; 48 = Icon Exclamation
   ; 64 = Icon Asterisk (info)

   ; Modality options:
   ; 4096 = System Modal (always on top)
   ; 8192 = Task Modal
   ; 262144 = Always-on-top (style WS_EX_TOPMOST - like System Modal but omits title bar icon)


    If (defaultBTN=2)
       defaultBTN := 256
    Else If (defaultBTN=3)
       defaultBTN := 512
    Else
       defaultBTN := 0

    If (iconz=1 || iconz=16 || iconz="hand" || iconz="error" || iconz="stop")
       iconz := 16
    Else If (iconz=2 || iconz=32 || iconz="question")
       iconz := 32
    Else If (iconz=3 || iconz=48 || iconz="exclamation")
       iconz := 48
    Else If (iconz=4 || iconz=64 || iconz="info")
       iconz := 64
    Else
       iconz := 0

    theseOptionz := buttonz + iconz + defaultBTN + modality
    If optionz
       theseOptionz := optionz

    If AnyWindowOpen
       Gui, %guiu%: +OwnDialogs

    MsgBox, % theseOptionz, % winTitle, % msg
    IfMsgBox, Yes
         r := "Yes"
    IfMsgBox, No
         r := "No"
    IfMsgBox, OK
         r := "OK"
    IfMsgBox, Cancel
         r := "Cancel"
    IfMsgBox, Abort
         r := "Abort"
    IfMsgBox, Ignore
         r := "Ignore"
    IfMsgBox, Retry
         r := "Retry"
    IfMsgBox, Continue
         r := "Continue"
    IfMsgBox, TryAgain
         r := "TryAgain"

   Return r
}

btnUIaddNewGeoLocation() {
   Gui, SettingsGUIA: Default
   GuiControlGet, newGeoDataLocationUserEdit
   k := StrSplit(newGeoDataLocationUserEdit, "|")
   If (k.Count()<6)
   {
      simpleMsgBoxWrapper(appName, "This field needs to be at least six sections long to be valid, each separated by a pipe symbol: |. The sections are:`n`nLocation name|Latitude|Longitude|GMT offset on the 1st of January|GMT offset on the 1st of July|Altitude (in meters)", 0, 1, 48)
      Return
   }

   If (StrLen(k[1])<2)
   {
      simpleMsgBoxWrapper(appName, "Please define a name for the custom location to be added.", 0, 1, 48)
      Return
   }

   If (!isInRange(k[3], -180, 180) || !isNumber(k[3]))
   {
      simpleMsgBoxWrapper(appName, "Please define a correct longitude coordinate for the custom location. Longitude ranges from -180° to 180°.", 0, 1, 48)
      Return
   }

   If (!isInRange(k[2], -90, 90) || !isNumber(k[2]))
   {
      simpleMsgBoxWrapper(appName, "Please define a correct latitude coordinate for the custom location. Latitude ranges from -90° [south pole] to 90° [north pole].", 0, 1, 48)
      Return
   }

   If (!isInRange(k[4], -14, 14) || !isNumber(k[4]))
   {
      simpleMsgBoxWrapper(appName, "Please define a correct GMT time offset for the custom location, the one it keeps on the 1st of January. This can range from -14 to 14 hours.", 0, 1, 48)
      Return
   }

   If (!isInRange(k[5], -14, 14) || !isNumber(k[5]))
   {
      simpleMsgBoxWrapper(appName, "Please define a correct GMT time offset for the custom location, the one it keeps on the 1st of July. This can range from -14 to 14 hours.`n`nThe two offsets are the ones in force in January and in July, which covers the daylight saving time of either hemisphere: north of the equator the July offset is the daylight saving one, south of it the January offset is. If no daylight saving time is to be observed, use the same value for both.", 0, 1, 48)
      Return
   }

   If (!isInRange(k[6], -5000, 13000) || !isNumber(k[6]))
   {
      simpleMsgBoxWrapper(appName, "Please define a correct altitude for the custom location. Allowed range, in meters, is between -5000 and 13000.", 0, 1, 48)
      Return
   }

   strA := k[1] "|" k[2] "|" k[3] "|" k[4] "|" k[5] "|" k[6]
   str := "Custom locations|" strA
   FileRead, userlist, %WinStorePath%\resources\geo-locations-userlist.txt
   idu := "`nCustom locations|" k[1] "|"
   If InStr(userlist, idu)
   {
      msgResult := simpleMsgBoxWrapper(appName, "The custom locations list already contains " k[1] ". Do you want it updated?", 4, 1, 32)
      If (msgResult="yes")
         btnUIupdateUserGeoLocation(Trim(idu, "`n"), strA, str)
      Return
   }

   If !InStr(userlist, str)
   {
      FileAppend, % "`n" str "`n", %WinStorePath%\resources\geo-locations-userlist.txt, UTF-8
      cities := geoData["1|-1"] + 1
      geoData["1|" cities] := strA
      geoData["1|-1"] := cities 
      uiUserCountry := 1
      uiUserCity := cities
      lastUsedGeoLocation := strA
      INIaction(1, "uiUserCity", "SavedSettings")
      INIaction(1, "uiUserCountry", "SavedSettings")
      INIaction(1, "lastUsedGeoLocation", "SavedSettings")
      SoundBeep 900, 100
   }
}

nameGeoLocation2add(countryIndex, geoDataEntry) {
; builds the name a location gets when added to the custom locations list
; it matches the naming scheme used by PanelEarthMap(), that is: Country:City

   z := InStr(geoDataEntry, "|")
   If (z<2 || countryIndex=1)
      Return ""

   ; the star that marks a capital in the lists is not part of the name
   Return countriesArrayList[countryIndex] ":" LTrim(SubStr(geoDataEntry, 1, z - 1), "*")
}

geoLocationAlreadyInUserList(nameu) {
; verifies in memory (no file access) if a location name is already part of the custom locations list

   cities := geoData["1|-1"]
   If (StrLen(nameu)<2 || !cities)
      Return 0

   Loop, % cities
   {
       p := geoData["1|" A_Index]
       z := InStr(p, "|")
       If (z>1 && SubStr(p, 1, z - 1)=nameu)
          Return A_Index
   }

   Return 0
}

btnUIaddTodayGeoLocation(modus:=0, strExtern:=0) {
; the PanelTodayInfos() counterpart of btnUIaddNewGeoLocation()
; it adds the location currently selected in the uiUserCountry / uiUserCity lists to the custom locations list,
; or the entry handed over in strExtern, and gives back the position it holds in that list; 0 says nothing
; was added
   isExtern := (modus="given" && InStr(strExtern, "|")) ? 1 : 0
   If !isExtern
   {
      Gui, SettingsGUIA: Default
      GuiControlGet, uiUserCountry
      GuiControlGet, uiUserCity
      If (uiUserCountry=1) ; already a custom location, nothing to add
         Return
 
      p := geoData[uiUserCountry "|" uiUserCity]
   }

   dstr := isExtern ? strExtern : countriesArrayList[uiUserCountry] ":" LTrim(p, "*")   ; the star marks a capital in the lists; it is no part of the name
   k := StrSplit(dstr, "|") ; the very same format used by PanelEarthMap()
   If (k.Count()<6 || StrLen(k[1])<4
      || !isNumber(k[2]) || !isInRange(k[2], -90, 90)
      || !isNumber(k[3]) || !isInRange(k[3], -180, 180)
      || !isNumber(k[4]) || !isInRange(k[4], -14, 14)
      || !isNumber(k[5]) || !isInRange(k[5], -14, 14)
      || !isNumber(k[6]) || !isInRange(k[6], -5000, 13000))
   {
      simpleMsgBoxWrapper(appName, "The selected location does not provide all the data required by a custom location entry:`n`nLocation name|Latitude|Longitude|GMT offset on the 1st of January|GMT offset on the 1st of July|Altitude (in meters)", 0, 1, 48)
      Return
   }

   strA := k[1] "|" k[2] "|" k[3] "|" k[4] "|" k[5] "|" k[6]
   str := "Custom locations|" strA
   FileRead, userlist, %WinStorePath%\resources\geo-locations-userlist.txt
   If (geoLocationAlreadyInUserList(k[1]) || InStr(userlist, "`nCustom locations|" k[1] "|"))
   {
      If isExtern
      {
         msgResult := simpleMsgBoxWrapper(appName, "The custom locations list already contains " k[1] ". Do you want it updated?", 4, 1, 32)
         If (msgResult!="Yes")
            Return 0

         thisIDu := btnUIupdateUserGeoLocation("Custom locations|" k[1] "|", strA, str)
         If !thisIDu
            simpleMsgBoxWrapper(appName, "The custom locations list could not be updated. " k[1] " was not found in the list.", 0, 1, 16)
         Return thisIDu
      }

      GuiControl, SettingsGUIA: Disable, UIbtnAddGeoLoc
      simpleMsgBoxWrapper(appName, "The custom locations list already contains " k[1] ".", 0, 1, 64)
      Return 0
   }

   FileAppend, % "`n" str "`n", %WinStorePath%\resources\geo-locations-userlist.txt, UTF-8
   If ErrorLevel
   {
      simpleMsgBoxWrapper(appName, "The custom locations list could not be updated. Failed to write to:`n`n" WinStorePath "\resources\geo-locations-userlist.txt", 0, 1, 16)
      Return
   }

   cities := geoData["1|-1"] + 1
   geoData["1|" cities] := strA
   geoData["1|-1"] := cities
   GuiControl, SettingsGUIA: Disable, UIbtnAddGeoLoc ; prevents adding the very same location twice
   SoundBeep 900, 100
   Return cities
}

UiLVgeoSearch() {
   Gui, SettingsGUIA: Default
   Gui, SettingsGUIA: ListView, LViewOthers
   RowNumber := LV_GetNext(0, "F")
   LV_GetText(OutputVar, RowNumber, 8)
   If InStr(OutputVar, "|")
   {
      p := Substr(OutputVar, 1, InStr(OutputVar, "|") -  1)
      j := countriesArrayList[p]
      k := j "|" LTrim(geoData[OutputVar], "*")   ; the star marks a capital in the lists; it is no part of the name
      k := StrSplit(k, "|")
   } Else k := extendedGeoData[OutputVar]

   If IsObject(k)
   {
      stringu := k[1] ":" k[2] "|" k[3] "|" k[4] "|" k[5] "|" k[6] "|" k[7]
      GuiControl, SettingsGUIA:, newGeoDataLocationUserEdit, % stringu
   }
}

SearchOpenPanelEarthMap() {
    PanelEarthMap("search")
}

PanelEarthMap(modus:=0) {
    If reactWinOpened(A_ThisFunc, 8)
       Return

    GenericPanelGUI(0)
    ; LastWinOpened := A_ThisFunc
    AnyWindowOpen := 8
    btnWid := 100
    lstWid := 435
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       lstWid := lstWid + 245
    }
    If !listedCountries
       loadGeoData()

    If !listedExtendedLocations
       loadExtendedGeoData()

    txtW := (PrefsLargeFonts=1) ? lstWid - 95 : lstWid - 90
    graphW := lstWid - 10  ; (PrefsLargeFonts=1) ? 640 : 380
    graphH := (PrefsLargeFonts=1) ? 310 : 195
    If (modus="search")
       tabChoice := 2

    Global GeoDataSearchField, newGeoDataLocationUserEdit, btn5, btn6
    Gui, Add, Tab3, x+5 y+15 AltSubmit Choose%tabChoice% vCurrentTabLV, Earth map|Search location
    Gui, Tab, 1
    Gui, Add, Text, x+10 y+10 w%txtW% Section -wrap gInfosDummy vGraphInfoLine, Click on the map for a new location and then add it to the custom list.
    widu := (PrefsLargeFonts=1) ? 190 : 120
    GuiAddDropDownList("xp y+5 w" widu " -wrap AltSubmit Choose" showEarthSunMapModus " gUIsetEarthSunMapMode vshowEarthSunMapModus", "Show indexed cities|Show sunlight map|Show moonlight map", "Earth map data")
    Gui, Add, Button, x+5 w%btnWid% hp gBtnDetectUserLocation vbtn6 +hwndhTemp, &Detect location
    ToolTip2ctrl(hTemp, "The identified location will be put in the field below.`nClick «Add to list» to store it.")
    widu := (PrefsLargeFonts=1) ? 40 : 32
    GuiAddButton("x+5 w" widu " hp gPrevTodayBTN vbtn1", "<", "Previous 2 hours")
    Gui, Add, Button, x+5 wp+10 hp gUItodayPanelResetDate vbtn5 +hwndhTemp, &Now
    ToolTip2ctrl(hTemp, "Reset to current time and date")
    GuiAddButton("x+5 wp-10 hp gNextTodayBTN vbtn2", ">", "Next 2 hours")

    ; Gui, -DPIScale
    Gui, Add, Text, xs y+10 w1 h1, Earth map illustration
    Gui, Add, Text, xp yp w%graphW% h%graphH% Section glocateClickOnEarthMap +0x8 +0xE +hwndhSolarGraphPic, Preview area
    ; Gui, +DPIScale
    Gui, Tab, 2
    ww := (PrefsLargeFonts=1) ? lstWid - 70 : lstWid - 48
    GuiAddEdit("x+10 y+10 Section gUIeditSearchLocation w" ww " -multi vGeoDataSearchField", "", "Search location")
    Gui, Add, Button, x+5 hp Default gPerformGeoDataSearch, &Search
    GuiAddListView("xs y+10 w" lstWid " r12 Grid AltSubmit gUiLVgeoSearch vLViewOthers", "Country|City|Latitude|Longitude|GMT|Altitude|Score|Index", "Search results. Locations.")

    Gui, Tab
    btnW := (PrefsLargeFonts=1) ? 80 : 55
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    thisu := StrReplace(countriesArrayList[uiUserCountry] ":" LTrim(geoData[uiUserCountry "|" uiUserCity], "*"), "Custom locations:")   ; the star marks a capital in the lists; it is no part of the name
    GuiAddEdit("xm+0 y+10 w" ww " -wrap vnewGeoDataLocationUserEdit", thisu, "Custom location to be added format:`nName|Latitude (N)|Longitude (E)|GMT offset on 1 January|GMT offset on 1 July|Altitude (meters)|0")
    Gui, Add, Button, x+5 hp vbtn4 gbtnUIaddNewGeoLocation +hwndhTemp, &Add to list
    ToolTip2ctrl(hTemp, "Add selected location to the list of custom user-defined locations.")

    Gui, Add, Button, xm+0 y+20 h%btnH% w%btnW% gPanelTodayInfos, &Back
    If !storeSettingsREG
        Gui, Add, Button, x+5 hp guiBTNupdateExtendedGeoData vbtn3, &Update index
    txtW := (PrefsLargeFonts=1) ? lstWid - 245 : lstWid - 210
    Gui, Add, Button, x+5 h%btnH% w%btnW% gCloseWindow, &Close
    Gui, Add, Text, x+5 hp w%txtW% +0x200 -wrap vUIastroInfoSet, Please wait...

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Earth map: %appName%
    generateEarthMap()
}

UIsetEarthSunMapMode() {
  Gui, SettingsGUIA: Default
  GuiControlGet, showEarthSunMapModus
  generateEarthMap()
}

UIeditSearchLocation() {
  SetTimer, PerformGeoDataSearch, -400
}

loadGeoData() {
   FileRead, userlist, %WinStorePath%\resources\geo-locations-userlist.txt
   FileRead, content, %A_ScriptDir%\resources\geo-locations-final.txt
   If (StrLen(userlist)<30)
   {
      If (ST_Count(userlist, "|")<6)
      {
         userlist .= "`nCustom locations|User defined default|-30.1914|30.1939|2.0|2.0|" A_Year "`n"
         FileAppend, % userlist , %WinStorePath%\resources\geo-locations-userlist.txt, UTF-8
      }
   }

   content := userlist "`n" content
   newu := ""
   m := new hashtable()
   listedCities := listedCountries := p := 0
   countriesList := ""
   countriesArrayList := []
   Loop, Parse, content, `n, `r
   {
      p++
      k := StrSplit(A_LoopField, "|")
      If StrLen(k[1])<2
        Continue

      testu := Format("{:L}", k[1])
      If !m[testu]
      {
         geoData[listedCountries "|-1"] := listedCities
         listedCountries++
         m[testu] := listedCountries
         countriesList .= k[1] "|"
         countriesArrayList[listedCountries] := k[1]
         listedCities := 1
      } Else
      {
         listedCities++
      } 

      city := k[2], la := k[3], lo := k[4], gmt := k[5], dst := k[6], elevation := k[7]
      c := (k[8]="pplc") ? 1 : 0
      sc := (k[8]="pplc") ? "*" : ""
      geoData[listedCountries "|" listedCities] := sc city "|" la "|" lo "|" gmt "|" dst "|" elevation "|" c
   }
   geoData[listedCountries "|-1"] := listedCities
   m := ""
   ; ToolTip, % p "=l=" listedCountries , , , 2
}

loadExtendedGeoData() {
; fields 8 and 9 hold the country and the city stripped of diacritics, for PerformGeoDataSearch();
; they are set only when the folded name differs from the displayed one
   FileRead, content, %A_ScriptDir%\resources\geo-locations-extended.txt
   listedExtendedLocations := 0
   extendedGeoData := []
   ncauntri := ""
   prevCntry := Chr(1)
   Loop, Parse, content, `n, `r
   {
      k := StrSplit(A_LoopField, "|")
      If StrLen(k[1])<2
        Continue

      cauntri := Trim(k[1])
      siti := Trim(k[2])
      If (cauntri!=prevCntry)
      {
         prevCntry := cauntri
         ncauntri := getNoDiacriticsStr(cauntri)
      }

      listedExtendedLocations++
      extendedGeoData[listedExtendedLocations] := [cauntri, siti, k[3], k[4], k[5], k[6], k[7]]
      If (ncauntri!=cauntri)
         extendedGeoData[listedExtendedLocations, 8] := ncauntri
      nsiti := getNoDiacriticsStr(siti)
      If (nsiti!=siti)
         extendedGeoData[listedExtendedLocations, 9] := nsiti
   }

   ; ToolTip, % p "=l=" listedCountries , , , 2
}

extractExtendedDataFromText(minPplLocation) {
; source of cities5000.txt: https://download.geonames.org/export/dump/
; the function converts the data to a different format for geo-locations-extended.txt

   FileRead, content, *P65001 %A_ScriptDir%\resources\cities5000.txt
   If ErrorLevel
      Return "file-err-main-list"

   If FileExist(A_ScriptDir "\resources\new-timezones.txt")
      FileRead, tmz, *P65001 %A_ScriptDir%\resources\new-timezones.txt

   tmz := StrReplace(tmz, "`t", "|")
   If (!tmz || !InStr(tmz, "CountryCode|TimeZoneId|GMT offset"))
   {
      failt := 0
      FileRead, tmz, *P65001 %A_ScriptDir%\resources\timezones.txt
      If (!tmz || !InStr(tmz, "CountryCode|TimeZoneId|GMT offset"))
         failt := 1
   } Else
   {
      failt := 0
      FileDelete, %A_ScriptDir%\resources\timezones.txt
      Sleep, 1
      If !ErrorLevel
         FileAppend, % tmz, %A_ScriptDir%\resources\timezones.txt, UTF-8
   }

   If failt
      Return "file-err-time-zones-list"

   FileRead, countries, *P65001 %A_ScriptDir%\resources\country-codes.txt
   If ErrorLevel
      Return "file-err-countries-list"

   newu := "`n"
   m := new hashtable()
   ee := p := counter := 0
   Loop, Parse, content, `n, `r
   {
      k := StrSplit(A_LoopField, "`t")
      If (k[15]<minPplLocation || !k[15])
         Continue

      testuA := Format("{:L}", k[9] . k[2])
      If (m[testuA]!=1)
      {
         counter++
         m[testuA] := 1
         elevu := k[16] ? k[16] : k[17]
         If (elevu<-395)
            elevu := -197 + Round(k[6])
         Else If (elevu>7000)
            elevu := 7019

         newu .= k[9] "|" k[2] "|" Round(k[5], 4) "|" Round(k[6], 4) "|" k[18] "|" elevu "|" k[8] "`n"
      } else p++
   }

   Loop, Parse, tmz, `n, `r
   {
      If (A_Index=1 || !InStr(A_LoopField, "|"))
         Continue

      k := StrSplit(A_LoopField, "|")
      newu := StrReplace(newu, "|" k[2] "|", "|" k[3] "|" k[4] "|")
   }

   Loop, Parse, countries, `n, `r
   {
      If !InStr(A_LoopField, "|")
         Continue

      k := StrSplit(A_LoopField, "|")
      newu := StrReplace(newu, "`n" k[1] "|", "`n" k[2] "|")
      ; c := k[1], d := k[2]
      ; m[c] := d
   }
   
   m := ""
   If (counter<1000)
      Return "list-malformed?"

   FileDelete, %A_ScriptDir%\resources\geo-locations-extended.txt
   Sleep, 2
   If !ErrorLevel
   {
      FileAppend, % newu, %A_ScriptDir%\resources\geo-locations-extended.txt, UTF-8
      If ErrorLevel
         Return "file-permission-severe-error. Locations list was lost."
   } Else
      Return "file-permission-error"
   ; fnOutputDebug(minpop " | " maxpop "|" ee "|" p)
}

uiBTNupdateExtendedGeoData() {
    Gui, SettingsGUIA: +OwnDialogs
    InputBox, UserInput, Update indexed locations, The locations to be indexed by Church Bells Tower are filtered by population count. Please enter a number higher than 7000. The locations with people fewer than the entered number will be filtered out.,,,,,,,,10100
    If ErrorLevel
    {
       Return
    } Else
    {
       UserInput := StrReplace(UserInput, ".")
       UserInput := StrReplace(UserInput, ",")
       UserInput := StrReplace(UserInput, " ")
       UserInput := Trim(UserInput)
       If !isNumber(UserInput)
       {
          simpleMsgBoxWrapper(appName, "Invalid number given. Update procedure abandoned.", 0, 1, 16)
          Return
       }
       UserInput := clampInRange(UserInput, 7000, 950100)
    }
    ; MsgBox, 52, %appName%, Please confirm you want to update the list of indexed locations by choosing Yes. Cities with fewer than 10000 people will be left out.
    ; IfMsgBox, Yes
    ;    allGood := 1
    ; If !allGood
    ;    Return

    FileDelete, %A_ScriptDir%\resources\cities5000.zip
    ; FileDelete, resources\new-country-codes.txt
    FileDelete, %A_ScriptDir%\resources\new-timezones.txt
    ctr := countriesArrayList.Count()
    cachedImg := A_ScriptDir "\resources\earth-surface-map-cached-countries-" ctr "-" listedExtendedLocations "-" A_Year ".jpg"
    FileDelete, % cachedImg
    Sleep, 50
    ToolTip, Please wait`, downloading...
    Try UrlDownloadToFile, https://download.geonames.org/export/dump/cities5000.zip, %A_ScriptDir%\resources\cities5000.zip
    Sleep, 1000
    Try UrlDownloadToFile, https://download.geonames.org/export/dump/timeZones.txt, %A_ScriptDir%\resources\new-timezones.txt
    ; Try UrlDownloadToFile, https://download.geonames.org/export/dump/countryInfo.txt, resources\new-country-codes.txt

    Loop, 9
    {
      ToolTip, Downloading... %A_Index%/10
      d := (AnyWindowOpen!=8) ? 200 : 800
      Sleep, % d
      If FileExist(A_ScriptDir "\resources\cities5000.zip")
         Break
    }

    Sleep, 250
    FileGetSize, sizeCity, %A_ScriptDir%\resources\cities5000.zip, K
    FileGetSize, sizeTmz, %A_ScriptDir%\resources\new-timezones.txt, K
    ; FileGetSize, sizeCountry, resources\new-country-codes.txt, K
    Sleep, 50
    If (sizeTmz<3)
       FileDelete, %A_ScriptDir%\resources\new-timezones.txt
    ; If (sizeCountry<5)
    ;    FileDelete, resources\new-country-codes.txt

    Tooltip
    If ((sizeCity<250 || !FileExist(A_ScriptDir "\resources\cities5000.zip")) && AnyWindowOpen=8)
       simpleMsgBoxWrapper(appName, "Update failed! Error downloading locations list file from`nhttps://download.geonames.org/export/dump.", 0, 1, 16)
    Else If (AnyWindowOpen=8)
       updateExtendedGeoData(UserInput)
}

updateExtendedGeoData(minPplLocation) {
   Tooltip, Please wait - processing update data...
   UnZipExtract2Folder(A_ScriptDir "\resources\cities5000.zip" , A_ScriptDir "\resources")

   ; the shell's CopyHere() comes back before the extraction is over, and the file used to be
   ; looked for at once - and missed; it is waited for instead, until its size holds still
   ; between two looks, but for two seconds at the most
   startZeit := A_TickCount
   prevSize := -1
   Loop
   {
      FileGetSize, thisSize, %A_ScriptDir%\resources\cities5000.txt
      If (!ErrorLevel && thisSize>0 && thisSize=prevSize)
         Break

      prevSize := ErrorLevel ? -1 : thisSize
      If (A_TickCount - startZeit>2000)
         Break
      Sleep, 100
   }

   If FileExist(A_ScriptDir "\resources\cities5000.txt")
   {
      r := extractExtendedDataFromText(minPplLocation)
      If !r
      {
         loadExtendedGeoData()
         Tooltip
         CloseWindow()
         PanelEarthMap()
         MsgBox, , %appName%, Locations list succesfully updated. There are now %listedExtendedLocations% indexed cities with a population higher than %minPplLocation%.
      } Else
      {
         Tooltip
         MsgBox, , %appName%, An error occured updating the locations list. Error code: %r%.
      }
   } Else
   {
      Tooltip
      MsgBox, , %appName%, An error occured updating the locations list. The downloaded archive could not be extracted.
   }

   FileDelete, %A_ScriptDir%\resources\cities5000.zip
   ; FileDelete, resources\new-country-codes.txt
   FileDelete, %A_ScriptDir%\resources\new-timezones.txt
}

UnZipExtract2Folder(Zip, Dest="", Filename="") {
; Function by Jess Harpur [2013] based on code by shajul (backup by Drugwash)
; https://autohotkey.com/board/topic/60706-native-zip-and-unzip-xpvista7-ahk-l/page-2

    SplitPath, Zip,, SourceFolder
    If !SourceFolder
       Zip := A_WorkingDir . "\" . Zip
    
    If !Dest
    {
       SplitPath, Zip,, DestFolder,, Dest
       Dest := DestFolder . "\" . Dest . "\"
    }
    If (SubStr(Dest, 0, 1) <> "\")
       Dest .= "\"

    SplitPath, Dest,,,,,DestDrive
    If !DestDrive
       Dest := A_WorkingDir . "\" . Dest
    StringTrimRight, MoveDest, Dest, 1
    StringSplit, d, MoveDest, \
    dName := d%d0%

    fso := ComObjCreate("Scripting.FileSystemObject")
    If !fso.FolderExists(Dest)   ;  http://www.autohotkey.com/forum/viewtopic.php?p=402574
       fso.CreateFolder(Dest)

    AppObj := ComObjCreate("Shell.Application")
    FolderObj := AppObj.Namespace(Zip)
    If Filename
    {
       FileObj := FolderObj.ParseName(Filename)
       AppObj.Namespace(Dest).CopyHere(FileObj, 4|16)
    } Else
    {
       FolderItemsObj := FolderObj.Items()
       AppObj.Namespace(Dest).CopyHere(FolderItemsObj, 4|16)
    }
}

coreWrapSunInfos(yd, trz, tmr, xtmr, latu, longu, gmtOffset, Altitude, prevufkob:=0, simplifiedMode:=0, dstInfo:=0) {
   If IsObject(prevufkob)
   {
      prevDuration := prevufkob.pvdur
      possibleSR := prevufkob.psr
      moreBonus := prevufkob.mbx
      ; testus := getTwilightDuration(trz, latu, longu, gmtOffset, 6.1)
      ; fnOutputDebug("signetica twilight duration=" Round((testus)/60,1))
   }

   ref := SubStr(trz, 1, 8)
   tref := SubStr(tmr, 1, 8)
   xtref := SubStr(xtmr, 1, 8)
   yref := SubStr(yd, 1, 8)
   altitudeBonus := (Altitude>100) ? Round(Altitude/1453, 2) : 0  ; in minutes

   otherz := [],    fkob := []
   fkob.RawR := 0,  fkob.RawS := 1

   ; calculate sunrise and sunset times for yesterday, today and tomorrow 
   ; I chose to do this because the results returned can be missing or exceed the given date
   kob := SolarCalculator(trz, latu, longu, gmtOffset, altitudeBonus)
   If (simplifiedMode=1 && (InStr(kob.RawDa, ref)!=1 || InStr(kob.RawR, ref)!=1 || InStr(kob.RawN, ref)!=1
   || InStr(kob.RawS, ref)!=1 || InStr(kob.RawDu, ref)!=1))
   {
      ; the simplified mode only holds while every moment of the day lands on the day itself;
      ; it does not where the zone offset sits far from the longitude - Apia [Samoa] at GMT +13
      ; has its sunrise on the next date - nor wherever a twilight goes missing
      simplifiedMode := 0
   }

   If (simplifiedMode=0)
   {
      ; gmtOffset is the one in effect on trz; yesterday and tomorrow can sit on the other
      ; side of a daylight saving switch, so their own offset is resolved for them
      kobyd := SolarCalculator(yd, latu, longu, resolveGmtOffset(yd, dstInfo, gmtOffset), altitudeBonus)
      kobtmr := SolarCalculator(tmr, latu, longu, resolveGmtOffset(tmr, dstInfo, gmtOffset), altitudeBonus)
   }

   If ((!kob.r || !kob.s) && simplifiedMode=0)
   {
      ofu := SubStr(trz, 1, 8) . "000001"
      ; if no sunrise, sunset returned by Solar Calculator, use the SunRise class;
      ; calculateSunMoonRiseSet() wants an UTC instant to search around, so local noon is
      ; converted back to UTC; searching around local noon also keeps both events of the
      ; local day well inside the +/- 24 hours search window of the SunRise class
      qtz := SubStr(trz, 1, 8) . "120000"
      qtz += -1*gmtOffset, Hours
      bkob := calculateSunMoonRiseSet(qtz, ofu, latu, longu, gmtOffset, 1, altitudeBonus)
      ; If (!bkob.r || !bkob.s)
      If (!bkob.r && !bkob.s)
      {
         fnOutputDebug("2nd bkob")
         qtz += 30, Minutes
         bkob := calculateSunMoonRiseSet(qtz, ofu, latu, longu, gmtOffset, 1, altitudeBonus)
         ; If ((bbkob.r && bbkob.s) || (!bkob.r && !bkob.s))
         ; {
         ;    fnOutputDebug("2nd bbkob yay")
         ;    bkob := bbkob.Clone()
         ; }
      }

      fnOutputDebug(trz "=bkob.r=" bkob.r)
      fnOutputDebug(trz "=bkob.s=" bkob.s)
   }

   ; fnOutputDebug(trz "= kobyd.r=" kobyd.r)
   ; fnOutputDebug("kob.r=" kob.r)
   ; fnOutputDebug("kobtmr.r=" kobtmr.r)
   ; fnOutputDebug("kobyd.s=" kobyd.s)
   ; fnOutputDebug("kob.s=" kob.s)
   ; fnOutputDebug("kobtmr.s=" kobtmr.s)
   ; fnOutputDebug(trz "= civil kobyd.twR=" kobyd.twR)
   ; fnOutputDebug("kob.twR=" kob.twR)
   ; fnOutputDebug("kobtmr.twR=" kobtmr.twR)
   ; fnOutputDebug("kobyd.twS=" kobyd.twS)
   ; fnOutputDebug("kob.twS=" kob.twS)
   ; fnOutputDebug("kobtmr.twS=" kobtmr.twS)

   If (kobyd.RawDa && kob.RawDa)
      diffDawnA := timeSpanInSeconds(ref . SubStr(kobyd.RawDa, 9), kob.RawDa)
   If (kobtmr.RawDa && kob.RawDa)
      diffDawnB := timeSpanInSeconds(ref . SubStr(kobtmr.RawDa, 9), kob.RawDa)

   If (diffDawnA && diffDawnB)
      fkob.diffuDawn := (diffDawnA + diffDawnB)//2
   Else
      fkob.diffuDawn := diffDawnA ? diffDawnA : diffDawnB

   If (kobyd.RawDu && kob.RawDu)
      diffDuskA := timeSpanInSeconds(ref . SubStr(kobyd.RawDu, 9), kob.RawDu)
   If (kobtmr.RawDu && kob.RawDu)
      diffDuskB := timeSpanInSeconds(ref . SubStr(kobtmr.RawDu, 9), kob.RawDu)

   If (diffDuskA && diffDuskB)
      fkob.diffuDusk := (diffDuskA + diffDuskB)//2
   Else
      fkob.diffuDusk := diffDuskA ? diffDuskA : diffDuskB

   ; decide which sunrise and sunset are closest to the date chosen by user
   If (InStr(kob.RawR, tref)=1 && InStr(kob.RawN, tref)=1 && InStr(kob.RawS, tref)=1
   && InStr(kobyd.RawR, ref)=1 && InStr(kobyd.RawN, ref)=1 && InStr(kobyd.RawS, ref)=1)
   {
      ; this fixes locations such as Apia [Samoa], where GMT is +13
      kobtmr := kob.Clone()
      kob := kobyd.Clone()
      kobyd := ""
      fkob.accuracy .= "^"
   }

   If (!kob.RawR && !InStr(bkob.RawR, tref) && !InStr(bkob.RawR, xtref))
   {
      fkob.RawR := bkob.RawR
      fkob.r := bkob.r
      If bkob.RawR   ; the marker means «taken from the SunRise class», not «nothing found»
         fkob.accuracy .= "."
   } Else
   {
      fkob.RawR := kob.RawR
      fkob.r := kob.r
   }

   If (!kob.RawS && !InStr(bkob.RawS, yref) && !InStr(bkob.RawS, xtref))
   {
      fkob.RawS := bkob.RawS
      fkob.s := bkob.s
      If bkob.RawS   ; the marker means «taken from the SunRise class», not «nothing found»
         fkob.accuracy .= "."
   } Else
   {
      fkob.RawS := kob.RawS
      fkob.s := kob.s
   }

   fkob.twR := kob.twR
   fkob.RawDa := kob.RawDa
   fkob.twS := kob.twS
   fkob.RawDu := kob.RawDu
   If (InStr(fkob.RawS, yref)=1 || !fkob.RawS)
   {
      ; we do not need a sunset from yesterday 
      fkob.s := ""
      fkob.RawS := ""
   }

   ; ToolTip, % fkob.RawR "==" tref "==" ref , , , 2
   If (InStr(fkob.RawR, tref)=1 || !fkob.RawR)
   {
      ; we do not need a sunrise from tomorrow  
      fkob.r := ""
      fkob.RawR := ""
   }

   fkob.n := kob.n        ; noon time
   fkob.RawN := kob.RawN
   getSunAzimuthElevation(kob.RawN, latu, longu, gmtOffset, azii, elevu)
   fkob.elev := elevu

   ; otherz[] object holds yesterday's dawn, sunrise and tomorrow's sunset, dawn;
   If (InStr(kobyd.RawR, yref)=1 && !InStr(fkob.RawR, yref))
   {
      otherz.r := kobyd.r
      otherz.RawR := kobyd.RawR
   }

   If (InStr(kobtmr.RawS, tref)=1 && !InStr(fkob.RawS, tref))
   {
      otherz.s := kobtmr.s
      otherz.RawS := kobtmr.RawS
   }

   If (InStr(kobyd.RawDa, yref)=1 && !InStr(fkob.RawDa, yref))
   {
      otherz.twR := kobyd.twR
      otherz.RawDa := kobyd.RawDa
   }

   If (InStr(kobtmr.RawDu, tref)=1 && !InStr(fkob.RawDu, tref))
   {
      otherz.twS := kobtmr.twS
      otherz.RawDu := kobtmr.RawDu
   }

   ; now we decide to use some of yesterday's dates , or tomorrow's dates
   If (!InStr(fkob.RawR, ref) && InStr(otherz.RawR, yref)=1 && otherz.RawR<fkob.RawS)
   {
      fkob.r := otherz.r
      fkob.RawR := otherz.RawR
   }

   If (!InStr(fkob.RawDa, ref) && InStr(otherz.RawDa, yref)=1)
   {
      fkob.RawDa := otherz.RawDa
      fkob.twR := otherz.twR
   }

   If (!InStr(fkob.RawDu, ref) && InStr(otherz.RawDu, tref)=1)
   {
      fkob.RawDu := otherz.RawDu
      fkob.twS := otherz.twS
   }

   ; the bonus holds today's sunset that occured before the sunrise; we display the next sunset, even if it is tomorrow 
   ; the bonus is required to calculate sunlight total time
   specialBonus := (InStr(fkob.RawS, ref)=1 && InStr(otherz.RawS, tref)=1 && fkob.RawR>fkob.RawS && fkob.r && fkob.s) ? 1 : 0
   If (!InStr(fkob.RawS, ref) && InStr(otherz.RawS, tref)=1 && otherz.RawS>fkob.RawR) || (specialBonus=1)
   {
      If (specialBonus=1)
         bonus := fkob.RawS

      fkob.s := otherz.s
      fkob.RawS := otherz.RawS
      ; fkob.RawDu := otherz.RawDu
      ; fkob.twS := otherz.twS
   }

   If (!bonus && InStr(kobyd.RawS, ref)=1 && InStr(fkob.RawS, tref)=1)
      bonus := kobyd.RawS

   ; ToolTip, % bonus "=" moreBonus "=" ref "=" , , , 2
   ; from the previous call of this function, if the sunset corresponds to today,
   ; it is passed as moreBonus;
   ; we set it as the sunset time in this call, if somehow in this call,
   ; there is no sunset defined
   If (!fkob.RawS && moreBonus)
   {
      fnOutputDebug("add moreBonus= " moreBonus)
      FormatTime, s, % moreBonus, yyyy/MM/dd HH:mm
      fkob.RawS := moreBonus
      fkob.s := s
      fkob.accuracy .= ","
      If (possibleSR && !fkob.RawR)
      {
         ; in the wrapper of this function, a possible sunrise is calculated
         ; based on the sunlight duration and the sunset time, moreBonus, both 
         ; determined from a previous call to this function
         fnOutputDebug("add possibleSR= " possibleSR)
         FormatTime, prx, % possibleSR, yyyy/MM/dd HH:mm
         fkob.RawR := possibleSR
         fkob.r := prx
         fkob.accuracy .= "/"
      }
   }

   ; if there is bonus set in this call, we use moreBonus under specific circumstances as bonus,
   ; to ensure total sunlight time is correct
   If (!bonus && InStr(moreBonus, ref)=1 && moreBonus && SubStr(moreBonus, 1, 10)!=SubStr(fkob.RawS, 1, 10) && moreBonus<fkob.RawR)
      bonus := moreBonus

   If (!bonus && prevDuration=86400 && InStr(fkob.RawR, ref)=1 && (InStr(fkob.RawS, tref)=1 || InStr(fkob.RawS, xtref)=1))
   {
      ; We have no "sunset bonus" from yesterday, because yesterday was a polar day [no sunset],
      ; but we do have a sunrise today and a sunset defined for tomorrow, then...
      ; it means we must have a sunset before the sunrise of today;
      ; a polar day cannot end with a sunrise, but with a sunset; it is obvious that
      ; once you have a sunrise, a sunset must preceed it

      sp := timeSpanInSeconds(SubStr(fkob.RawR, 1, 8) "000001", fkob.RawR)
      If kobtmr.RawR
         zp := timeSpanInSeconds(fkob.RawR, SubStr(fkob.RawR, 1, 8) . SubStr(kobtmr.RawR, 9))

      bonus := fkob.RawR
      If zp
      {
         zp := clampInRange(zp, 10, sp//1.15)
         bonus += -zp, Seconds
      } Else
         bonus += -1*(sp//2), Seconds

      fnOutputDebug("sp=" sp "; zp=" zp "; bonus=" bonus)
      FormatTime, sx, % bonus, yyyy/MM/dd HH:mm
      fkob.RawXS := bonus         ; only used when listing sunsets and sunrises
      fkob.XS := sx
      fkob.accuracy .= "\"
   }

   FormatTime, dayum, % trz, Yday
   twDurA := max(Round(fkob.diffuDusk), Round(fkob.diffuDawn))
   twDurB := max(Round(prevufkob.diffuDusk), Round(prevufkob.diffuDawn))
   twDurC := max(twDurA, twDurB)

   If (InStr(fkob.RawDa, yref)=1 && otherz.RawDa=fkob.RawDa && prevufkob.RawDa=fkob.RawDa && fkob.RawR)
   {
       ; if the dawn occured yesterday and it is the same with the one identified «today»
       ; and we have a sunrise specific for today...
       ; we estimate a new dawn for today's sunrise
       fnOutputDebug("new dawn is needed: " twDurC "|"  fkob.diffuDusk "|" fkob.diffuDawn "|" prevufkob.diffuDusk "|" prevufkob.diffuDawn)
       ; twDurD := getTwilightDuration(trz, latu, longu)
       ; twDur := max(Round(twDurD), Round(twDurC))
       ; method A
       z := timeSpanInSeconds(kobyd.RawR, kobyd.RawDa)
       giu := trz 
       giu += -2, Days
       kobxyd := SolarCalculator(giu, latu, longu, resolveGmtOffset(giu, dstInfo, gmtOffset), altitudeBonus)
       y := timeSpanInSeconds(SubStr(kobyd.RawDa, 1, 8) . SubStr(kobxyd.RawDa, 9), kobyd.RawDa)
       z += y + 24
       gj := fkob.RawR
       gj += -z, Seconds

       ; method B 'n C'
       wa := timeSpanInSeconds(prevufkob.RawS, prevufkob.RawDu)
       wb := timeSpanInSeconds(prevufkob.RawR, prevufkob.RawDa)
       w := (wa + wb)//2
       wza := prevufkob.RawDa ? w//2.05 : Round(w*1.1)
       wzb := prevufkob.RawDa ? w//1.55 : Round(w*1.1)
       wz := (wza + wzb)//2
       blo := SubStr(fkob.RawR, 1, 8) . SubStr(prevufkob.RawDa, 9) 
       iu := prevufkob.RawDa ? blo : fkob.RawR
       fnOutputDebug("wz=" wz ", w=" w ", iu=" iu ", r=" prevufkob.RawR ", dawn=" prevufkob.RawDa  ", dusk=" prevufkob.RawDu)
       iu += -wz, Seconds
       If (iu<prevufkob.RawDu || iu<prevufkob.RawS || !prevufkob.accuracy)
       {
          ; accuracy is an accumulated string of markers, so it can only be probed with InStr();
          ; Dusk=2 is the flag set together with the «}» marker and it is dropped again once
          ; the substituted dusk gets replaced by an estimated one, which is what matters here
          iu := (prevufkob.Dusk=2) ? prevufkob.RawS : prevufkob.RawDu
          If (StrLen(iu)!=14)
          {
             ; yesterday offers neither reference; adding to a blank timestamp would hand
             ; back the current date and time and pass it off as a dawn
             iu := ""
          } Else If (iu=prevufkob.RawS)
          {
             iu += (190 - dayum)*2, Seconds
          } Else
          {
             fkob.accuracy .= "#"
             iu += wz*0.45, Seconds
          }
       }

       zvr := iu ? min(iu, gj) : gj ; choose from A or B 'n C'
       fkob.RawDa := zvr
       FormatTime, tw, % zvr, yyyy/MM/dd HH:mm
       fkob.twR := tw
       fkob.accuracy .= "<"
       fnOutputDebug("new dawn twilight: iu=" iu "; gj =" gj "; twR=" tw)
       fnOutputDebug("new dawn twilight: twDur=" twDur "; twDurD =" twDurD "; twDurC =" twDurC "; twR=" tw)
      ; SoundBeep , 900, 100
   }

   If (fkob.RawS<kobtmr.RawDa && kobtmr.RawDa<fkob.RawDu && fkob.RawS<kobtmr.RawS && kobtmr.RawS>kobtmr.RawDa && kobtmr.RawS
   && fkob.RawS && kobtmr.RawDa && InStr(fkob.RawDu, tref)=1 && InStr(fkob.RawS, ref)=1 && InStr(kobtmr.RawDa, tref)=1 && !kob.RawDu)
   {
      ; if the dusk landed on tomorrow and we have a sunset specific for today...
      ; we estimate a new dusk for today's sunset
      fnOutputDebug("new dusk twilight: " twDurC "|"  fkob.diffuDusk "|" fkob.diffuDawn "|" prevufkob.diffuDusk "|" prevufkob.diffuDawn)
      twDurD := getTwilightDuration(trz, latu, longu, gmtOffset)
      ; twDurC is built out of the day to day change of the dawn/dusk times, not out of a
      ; twilight duration; near the poles that change grows to hours and would win a max()
      ; against the real duration, so it only serves as a fallback
      twDur := Round(twDurD) ? Round(twDurD) : Round(twDurC)
      If twDur
      {
         iu := fkob.RawS
         iu += twDur, Seconds
         If (iu>kobtmr.RawDa && kobtmr.RawDa>1)
         {
            iu := fkob.RawS
            iu += twDur//1.5, Seconds
         }
         newu := 1
      } Else If (InStr(fkob.RawS, ref)=1 && InStr(kobtmr.RawDa, tref)=1)
      {
         wdu := timeSpanInSeconds(SubStr(fkob.RawS, 1, 8) "235959", fkob.RawS)
         wdu += timeSpanInSeconds(SubStr(kobtmr.RawDa, 1, 8) "000001", kobtmr.RawDa)
         iu := fkob.RawS
         iu += wdu//1.25, Seconds
         newu := 1
      }

      If (newu=1)
      {
         fkob.RawDu := iu
         FormatTime, tw, % iu, yyyy/MM/dd HH:mm
         fkob.twS := tw
         fkob.accuracy .= wdu ? "~>" : ">"
         If (InStr(fkob.RawDu, tref)=1)
            g := timeSpanInSeconds(SubStr(fkob.RawDu, 1, 8) "000001", fkob.RawDu)
      }
      fnOutputDebug("new dusk twilight: twDur=" twDur "; twDurD =" twDurD "; twDurC =" twDurC "; twS=" tw)
      ; SoundBeep , 990, 100
   }

   If InStr(kobyd.RawDu, ref)
      cbonus := kobyd.RawDu

   If (isInRange(dayum, mEquiDay - 2, sEquiDay + 2) && latu>0 && (!fkob.RawDa || !fkob.RawDu))
   || (!isInRange(dayum, mEquiDay - 2, sEquiDay + 2) && latu<0 && (!fkob.RawDa || !fkob.RawDu))
   {
      ; when the sun does not pass below the 6 degrees of the horizon line, we have undefined civil twilight times
      ; here we use the next sunrise as the end of civil twilight and the previous sunset as the beginning
      ; it is meant to help with calculating the civil twilight duration 
      ; this only applies between the March equinox and the September equinox, if it is the north pole,
      ; however ... it is the opposite for the south pole.

      If (!fkob.RawDa && kobyd.s && fkob.r)
      {
         fkob.accuracy .= "{"
         fkob.RawDa := kobyd.RawS
         fkob.twR := kobyd.s
         fkob.Dawn := 2
      }

      If (!fkob.RawDa && fkob.XS && fkob.r)
      {
         fkob.accuracy .= "{"
         fkob.RawDa := fkob.RawXS
         fkob.twR := fkob.XS
         fkob.Dawn := 2
      }

      If (!fkob.RawDu && kobtmr.r && fkob.s)
      {
         fkob.accuracy .= "}"
         fkob.RawDu := kobtmr.RawR
         fkob.twS := kobtmr.r
         fkob.Dusk := 2
      }

      If (fkob.RawDu && fkob.Dusk=2 && kobtmr.twR && kobtmr.RawDa<fkob.RawDu)
      {
         ; here we try to guess a dusk time because we have a sunset followed by a dawn
         ; in-between the two moments of the day

         z := timeSpanInSeconds(kobtmr.RawS, kobtmr.RawDu)
         kobxtmr := SolarCalculator(xtmr, latu, longu, resolveGmtOffset(xtmr, dstInfo, gmtOffset), altitudeBonus)
         y := timeSpanInSeconds(SubStr(kobtmr.RawDu, 1, 8) . SubStr(kobxtmr.RawDu, 9), kobtmr.RawDu)
         z += y
         j := fkob.RawS
         j += z+39, Seconds

         fkob.RawDu := j
         FormatTime, tw, % j, yyyy/MM/dd HH:mm
         ; MsgBox, % tw "`n" msgu "=" zx "==" z//1.85
         fkob.twS := tw
         fkob.accuracy .= "@"
         fkob.Dusk := 1
         fnOutputDebug(y "=y; today=" ref " = new dusk=" j "; sunset="  fkob.RawS "; dawnTmr=" kobtmr.RawDa)
         If (InStr(fkob.RawDu, tref)=1)
         {
            g := timeSpanInSeconds(SubStr(fkob.RawDu, 1, 8) "000001", fkob.RawDu)
            fnOutputDebug("lul=" g)
         }
      }

      If (fkob.Dawn=2 && InStr(fkob.RawDa, ref)=1)
         p := timeSpanInSeconds(SubStr(fkob.RawDa, 1, 8) "000001", fkob.RawDa)
      ; Else If (prevufkob.Dusk=2 && InStr(prevufkob.RawDu, ref))
      ; {
      ;    p := timeSpanInSeconds(SubStr(prevufkob.RawDu, 1, 8) "000001", prevufkob.RawDu)
      ;    fkob.accuracy .= "^"
      ; }
   }

   fkob.sunbonux := bonus
   fkob.civilbonux := cbonus
   fkob.civilextra := p
   fkob.civilestra := g
   ; If prevDuration
   ;    fnOutputDebug("bonus=" bonus "; civil bonus=" cbonus "; civil extra p=" p)
   Return fkob
}

wrapCalcSunInfos(t, latu, longu, gmtOffset:=0, Altitude:=0, simplifiedMode:=0, dstInfo:=0) {
   ; this function tries to make sensical the values displayed by Church Bells Tower 
   ; tomorrow or yesterday are relative to the given date;
   ; the time for rise can be yesterday, if not available for today;
   ; the time for set can be tomorrow, if not available for today;
   ; after these «adjustments», calculate day length;
   ; if no rise or set, assume it is a polar day if the given date is
   ; between the march equinox and september equinox
   ; otherwise, assume it is a polar night;

   ; coreWrapSunInfos() and coreCalculateLightDuration() are called twice
   ; the first time is for yesterday and the 2nd time is for today, but with
   ; additional details derived from the previous call.

; Tested on:

    ;/ Canada|Inuvik|68.361|-133.729|-7.0|PPLA|-6.0|15                 [ polar night ]
    ;/ Canada|Naujaat [Kivalliq]|66.522|-86.235|-6.0|PPL|-5.0|25       [ polar day ]
    ;/ Canada|Qikiqtarjuaq (Nunavut)|67.554|-64.028|-5.0|PPLA|-4.0|19  [ polar day ]
    ;  05/29 -  R=00:19  S=00:07  -- missing sun rise/set

    ;/ Greenland|Sisimiut|66.939|-53.672|-3.0|PPLA|-2.0|21  [ polar day ]
    ;  06/02 -  R=01:50  S=01:14  -- missing sun rise/set

    ; Russia|Severnyy|76.421|67.304|3.0|PPLA|3.0|234       [ polar deep night ]
    ; Norway|Svalbard-Jan Mayen|78.223|15.647|1.0|PPLC|2.0 [ polar deep night ]
    ; Sweden|Luleå|65.584|22.155|1.0|PPLA|2.0|17
    ; Iceland|Akureyri|65.684|-18.088|0.0|PPLA|0.0|6
    ; USA|Fairbanks|64.843|-147.723|-9.0|PPLA2|-8.0|132
    ; USA|Anchorage|61.218|-149.900|-9.0|PPLA2|-8.0|31
    ; 06/06 - tR=02:11 tS=01:44  -- missing civil twilights

    ;/ Finland|Kemi|65.736|24.564|2.0|PPLA3|3.0|16        [ polar day ]
    ;/ Finland|Kuusamo|65.964|29.189|2.0|PPLA3|3.0|261    [ polar day ]
    ;/ Finland|Rovaniemi|66.500|25.717|2.0|PPLA|3.0|92    [ polar day ]
    ;/ Finland|Sevettijärvi|69.505|28.591|2.0|PPLA|3.0|95 [ polar night ]
    ;/ Norway|Bardufoss|69.064|18.515|1.0|PPLA|2.0|70     [ polar night ]
    ;/ Norway|Bodø|67.280|14.405|1.0|PPLA|2.0|22          [ polar day ]
    ;/ Norway|Harstad|68.798|16.542|1.0|PPLA2|2.0|1       [ polar night ]
    ;/ Norway|Lakselv|70.051|24.971|1.0|PPLA|2.0|50       [ polar night ]
    ;/ Norway|Kiberg|70.285|30.998|1.0|PPLA|2.0|18        [ polar night ]
    ;/ Norway|Tromsø|69.649|18.955|1.0|PPLA|2.0|10        [ polar night ]
    ;/ Russia|Murmansk|68.979|33.093|3.0|PPLA|3.0|96      [ polar night ]
    ;/ Russia|Norilsk|69.354|88.203|7.0|PPL|7.0|76        [ polar night ]
    ;/ Sweden|Boden|65.825|21.689|1.0|PPLA2|2.0|10        [ polar day ]
    ;/ Sweden|Kiruna|67.856|20.225|1.0|PPLA2|2.0|579      [ polar night ]

; Locations picked to «stress test» corner cases, where daylights are longer than 24 hours or inexistent, in winter.
; Results compared with results from https://www.timeanddate.com/sun/

   trz := t
   If gmtOffset
      trz += gmtOffset, Hours

   yd := tmr := xtmr := trz
   tmr += 1, Days
   xtmr += 2, Days
   yd += -1, Days
   ref := SubStr(trz, 1, 8)
   tref := SubStr(tmr, 1, 8)
   xtref := SubStr(xtmr, 1, 8)
   yref := SubStr(yd, 1, 8)
   If (simplifiedMode=0)
   {
      byd := btmr := bxtmr := btrz := yd
      btmr += 1, Days
      bxtmr += 2, Days
      byd += -1, Days
      bref := SubStr(btrz, 1, 8)
      btref := SubStr(btmr, 1, 8)
      bxtref := SubStr(bxtmr, 1, 8)
      bydref := SubStr(byd, 1, 8)
 
      bfkob := coreWrapSunInfos(byd, btrz, btmr, bxtmr, latu, longu, resolveGmtOffset(btrz, dstInfo, gmtOffset), Altitude, 0, simplifiedMode, dstInfo)
      bduration := coreCalculateLightDuration(bfkob.sunbonux, bfkob.r, bfkob.s, bfkob.RawR, bfkob.RawS, bydref, bref, btref, btrz, "Sun", latu)
      moreBonus := InStr(bfkob.RawS, ref) ? bfkob.RawS : 0
      FormatTime, dayum, % trz, Yday
      If (isInRange(dayum, mEquiDay + 15, sEquiDay - 15) && latu>0 && moreBonus && bfkob.RawS)
      || (!isInRange(dayum, mEquiDay + 15, sEquiDay - 15) && latu<0 && moreBonus && bfkob.RawS)
      {
         ; a possible sunrise is calculated based on the sunlight duration and the sunset time of the previous call to coreWrapSunInfos();
         ; this applies only between the march equinox and september equinox in the northern
         ; hemisphere and only outside of that interval in the southern one;
         ; the next call to coreWrapSunInfos() will determine if this is going to be used or not
         ; sp := timeSpanInSeconds(SubStr(moreBonus, 1, 8) "000001", moreBonus)
         k := (bduration[2]<86400) ? 86400 - bduration[2] : 0 ; - sp
         If (k>0)
         {
            ; a day longer than 24 hours leaves no room for a sunrise to be placed
            possibleSR := bfkob.RawS
            possibleSR += k//2, Seconds
            fnOutputDebug("maybe possibleSR=" possibleSR "; bdur[2]=" bduration[2] "; sp=" sp)
         }
      }
 
      bfkob.psr := possibleSR
      bfkob.mbx := moreBonus
      bfkob.pvdur := bduration[2]
 
      ; fnOutputDebug("first run duration=" bduration[1] "; moreBonus=" moreBonus)
   }

   fkob := coreWrapSunInfos(yd, trz, tmr, xtmr, latu, longu, gmtOffset, Altitude, bfkob, simplifiedMode, dstInfo)
   duration := coreCalculateLightDuration(fkob.sunbonux, fkob.r, fkob.s, fkob.RawR, fkob.RawS, yref, ref, tref, trz, "Sun", latu)
   If (isInRange(dayum, mEquiDay - 2, jSolsDay - 1) && latu>0 && fkob.r=bfkob.r && fkob.s=bfkob.s && duration[2]<bduration[2] && simplifiedMode=0)
   || (isInRange(dayum, sEquiDay - 2, dSolsDay - 1) && latu<0 && fkob.r=bfkob.r && fkob.s=bfkob.s && duration[2]<bduration[2] && simplifiedMode=0)
   {
      ; guesstimate a new sunrise if yesteday and today have the same sunrise and sunset times
      ; and the sunlight duration of today is shorter compared to yesterday;
      ; this can never be the case between the march equinox and June's solstice in the northern
      ; hemisphere, nor between the september equinox and December's solstice in the southern one;
      ; the sunrise is calculated based on the sunlight duration and the sunset time of the first call to coreWrapSunInfos();
      possibleSR := max(bfkob.RawS, bfkob.RawR)
      k := (bduration[2]<86400) ? 86400 - bduration[2] : 0 ; - sp
      If (StrLen(possibleSR)=14 && k>0)
      {
         ; a blank base or a day longer than 24 hours cannot yield a sunrise; adding to a
         ; blank timestamp would silently produce one out of the current date and time
         possibleSR += k//2, Seconds
         fkob.RawR := possibleSR
         FormatTime, rx, % possibleSR, yyyy/MM/dd HH:mm
         fkob.r := rx
         fkob.accuracy .= "!"

         ; recalculate sunlight duration
         duration := coreCalculateLightDuration(fkob.sunbonux, fkob.r, fkob.s, fkob.RawR, fkob.RawS, yref, ref, tref, trz, "Sun", latu)
      }
      ; fnOutputDebug("deep fuck up")
      ; SoundBeep 300, 100
   }

   ; fkob.v := (trz>fkob.RawR && trz<fkob.RawS) ? "Yes" : "No"
   If (bfkob.civilestra>85000 && bfkob.civilestra>duration[2])
      bfkob.civilestra := 0

   civilSecondsExtra := Round(fkob.civilextra) + Round(bfkob.civilestra)
   ; fnOutputDebug("sunDur=" duration[2])
   ; fnOutputDebug("civilSecondsExtra=" fkob.civilextra "; " bfkob.civilestra)
   civilrest := (fkob.dawn=2 && fkob.dusk=2) ? 1 : 0
   civilduration := coreCalculateLightDuration(fkob.civilbonux, fkob.twR, fkob.twS, fkob.RawDa, fkob.RawDu, yref, ref, tref, trz, "Civil", latu, duration[2], civilSecondsExtra, civilrest)
   If (civilrest=1)
      fkob.accuracy .= "&"

   fkob.dur := duration[1]
   fkob.cdur := civilduration[1]
   fkob.durRaw := duration[2]
   fkob.cdurRaw := civilduration[2]
   ; fnOutputDebug("twilight duration=" Round(civilduration[2]/60, 1))
   ; getMoonElevation(t, trz, latu, longu)
   Return fkob
}

coreCalculateLightDuration(bonus, dcR, dcS, dRraw, dSraw, yref, ref, tref, trz, obju, latu:=0, sunlight:=0, civilExtra:=0, civilrest:=0) {
; The sun and the civil twilight hand over a date stamp in bonus - an extra span to be added
; to the day, or 0 when there is none - whereas the moon hands over the getMoonNoonZeit()
; object that its own fallback needs further below. The moon simply has no bonus span.
   moonNoon := 0
   If IsObject(bonus)
   {
      moonNoon := bonus
      bonus := 0
   }

   forceType := 0
   If (civilrest=1 && obju="civil")
   {
      ; both the dawn and the dusk were substituted, so everything outside the sunlight is
      ; twilight; a sunlight span of 24 hours or more leaves no twilight at all
      rawP := (sunlight<86400) ? 86400 - sunlight : 1
      duration := (rawP>1) ? transformSecondsReadable(rawP) : "00:00"
   } Else If ((dcR && dcS) || (!dcR && InStr(dSraw, ref)=1) || (!dcS && InStr(dRraw, ref)=1))
   {
      If (dcR && dcS)
      {
         g := (!bonus && InStr(dSraw, tref)=1) ? ref "235959" : dSraw
         cr := (InStr(dRraw, yref)=1) ? ref "000001" : dRraw
         cs := (bonus && InStr(dSraw, tref)=1) ? SubStr(cr, 1, 8) "235959" : g
         p := timeSpanInSeconds(cr, cs)
         b := (bonus<cr && cs<cr && InStr(dSraw, ref)=1 && InStr(dRraw, ref)=1) ? 0 : 1
         If (bonus && b=1)
            p += timeSpanInSeconds(SubStr(bonus, 1, 8) "000001", bonus)

         ; fnOutputDebug(obju "\" b " bonus=" bonus)
         ; fnOutputDebug("g=" g)
         ; fnOutputDebug("cr=" cr)
         ; fnOutputDebug("cs=" cs)
         ; fnOutputDebug("p=" p " /" obju)
         If (dSraw<dRraw && (InStr(dSraw, ref)=1 || InStr(dSraw, tref)=1))
         {
            ; if the sunset occured before the sunrise, we must substract
            ; the time span from that of an entire day: 86400 seconds
            ; fnOutputDebug("substract: 86400 - " p)
            p := 86400 - p
         }
      } Else If (!dcR && InStr(dSraw, ref)=1)
         p := timeSpanInSeconds(SubStr(dSraw, 1, 8) "000001", dSraw)
      Else If (!dcS && InStr(dRraw, ref)=1)
         p := timeSpanInSeconds(SubStr(dRraw, 1, 8) "235959", dRraw)

      If (obju="Civil")
      {
         ; fnOutputDebug("civil p=" p "; sl=" sunlight "; extra=" civilExtra)
         p += civilExtra
         ; the dawn to dusk span always contains the sunrise to sunset span; when it does not,
         ; the two contradict each other and reflecting the difference would only invent a
         ; plausible looking twilight out of inconsistent input
         p := (p>sunlight) ? p - sunlight : 0
      }

      rawP := p
      duration := p ? transformSecondsReadable(p) : "00:00"
      ; If (obju="sun")
      ; ToolTip, % duration "=" Round(p/60, 1) "=" Mod(p, 60) , , , 2
   } Else If (obju="Sun")
   {
      ; if no sunrise and sunset, then we can assume it is either a polar day or a polar night 
      ; based on the day of the year; if it is somewhere 
      ; between the March equinox and the September equinox it is likely a polar day, 
      ; otherwise, it is a polar night
      FormatTime, dayum, % trz, Yday
      If (latu>0)
         duration := isInRange(dayum, mEquiDay - 2, sEquiDay + 2) ? "24:00" : "00:00"
      Else
         duration := isInRange(dayum, mEquiDay - 2, sEquiDay + 2) ? "00:00" : "24:00"
      rawP := InStr(duration, "24:") ? 86400 : 1 ; in seconds
   } Else If (obju="Civil")
   {
      ; if no dawn and dusk, then we can assume it is all civil twilight
      ; only if sunlight time is over 20 hours and the day of the year is
      ; between the March equinox and the September equinox, if it is the north pole,
      ; however ... it is the opposite for the south pole.
      forceType := 0
      FormatTime, dayum, % trz, Yday
      If (isInRange(dayum, mEquiDay + 2, sEquiDay - 2) && latu>0 && sunlight>72150)
      || (!isInRange(dayum, mEquiDay + 2, sEquiDay - 2) && latu<0 && sunlight>72150)
      {
         forceType := 1
         rawP := (sunlight<86400) ? 86400 - sunlight : 1
         duration := (rawP>1) ? transformSecondsReadable(rawP) : "00:00"
      } Else
      {
         rawP := 1
         duration := "00:00"
      }
   } Else If (obju="Moon")
   {
      ; if no rise/set for the moon, use the data from getMoonNoonZeit()
      ; we have min and max elevation of the moon and make assumptions based on these
      forceType := 0
      FormatTime, dayum, % trz, Yday
      If (moonNoon.maxu>0 && moonNoon.minu>-0.1)
      {
         rawP := 86400
         duration := transformSecondsReadable(rawP)
      } Else If (moonNoon.maxu<=0.1)
      {
         rawP := 1
         duration := "00:00"
      } Else
      {
         ; the moon does cross the horizon, yet neither event could be matched to this day;
         ; its elevation follows a sinusoid between minu and maxu, so the share of the day
         ; spent above the horizon is acos(-midpoint/amplitude)/pi ; this joins continuously
         ; with the two cases above, which are its clamped extremes
         amplu := (moonNoon.maxu - moonNoon.minu)/2
         midu := (moonNoon.maxu + moonNoon.minu)/2
         rawP := amplu ? Round(86400 * ACos(clampInRange(-1*midu/amplu, -1, 1))/3.14159265358979) : 1
         rawP := clampInRange(rawP, 1, 86400)
         duration := (rawP>1) ? transformSecondsReadable(rawP) : "00:00"
      }
   }
   ; If (obju="Civil")
   ;    fnOutputDebug("civil=" duration " / " rawP)

   Return [duration, rawP, forceType]
}

transformSecondsReadable(p, friendly:=0) {
  If (abs(p)<60)
     Return p "s"

  If (friendly=2)
  {
     coreSecToHHMMSS(p, Hrs, Min, Sec, 0)
     If (hrs>0)
        Return format("{1:02}", Trim(hrs)) ":" format("{1:02}", Trim(min))
     Else If (Trim(min)>0)
        Return Trim(min) "m " round(sec) "s"
     Else
        Return (round(sec)=0) ? "" : round(sec) "s"
  }

  p := p/60  ; from seconds to minutes
  d := (Floor(p/1441)>=1) ? Floor(p/1440) "d " : ""
  ; t := (Floor(p/60)>24) ? p - (60*24) : p
  y := Round(Mod(p, 60))
  If (y=60)
     y -= 1

  duration := d format("{1:02}", Floor(p/60)) ":" format("{1:02}", y)
  If (InStr(duration, "00:0") && friendly=1)
  {
     ; ToolTip, % p , , , 2
     g := Round((p - Floor(p)) * 60)
     duration := y "m " g "s"
     If (y=0 && g=0)
        duration := "0s"
  }

  Return duration
}

wrapCalcMoonRiseSet(t, latu, longu, gmtOffset:=0, Altitude:=0) {
   ; this function tries to make sensical the values displayed by Church Bells Tower 
   ; just show the rise/set on the given day, not tomorrow or yesterday [relative to the given date]
   ; the time for rise can be yesterday, if not available for today
   ; the time for set can be tomorrow, if not available for today
   ;
   ; The DLL answers for a named day now, so the three days this can want are three
   ; calls. It used to be asked for a 24 hour window instead, which meant walking the
   ; window forward an hour at a time and watching for an event to fall on the right
   ; date: 48 calls a day, and the answer only ever as good as the hour it landed in.

   trz := t
   If gmtOffset
      trz += gmtOffset, Hours

   tmr := yd := trz
   tmr += 1, Days
   yd += -1, Days
   ref := SubStr(trz, 1, 8)
   tref := SubStr(tmr, 1, 8)
   yref := SubStr(yd, 1, 8)

   fkob := []
   fkob.RawR := 0
   fkob.RawS := 1

   kob := calculateMoonRiseSetDay(ref, latu, longu, gmtOffset, Altitude)
   If kob.RawR
   {
      fkob.r := kob.r
      fkob.RawR := kob.RawR
      fkob.riseAz := kob.riseAz
   } Else
   {
      ; no rise today, so the one before it is the last there was
      otherz := calculateMoonRiseSetDay(yref, latu, longu, gmtOffset, Altitude)
      If otherz.RawR
      {
         fkob.r := otherz.r
         fkob.RawR := otherz.RawR
         fkob.riseAz := otherz.riseAz
      }
   }

   If kob.RawS
   {
      fkob.s := kob.s
      fkob.RawS := kob.RawS
      fkob.setAz := kob.setAz
   } Else
   {
      ; ... and with no set today, the next one is tomorrow's
      otherz := calculateMoonRiseSetDay(tref, latu, longu, gmtOffset, Altitude)
      If otherz.RawS
      {
         fkob.s := otherz.s
         fkob.RawS := otherz.RawS
         fkob.setAz := otherz.setAz
      }
   }

   ; RawR/RawS still carry their 0/1 «nothing found» markers when no event was matched, and
   ; 1 is lower than any date stamp: a missing moonset must not read as a set before the rise
   fkob.reverse := (fkob.RawR>1 && fkob.RawS>1 && fkob.RawS<fkob.RawR) ? 1 : 0
   fkob.ref := ref
   fkob.yref := yref
   fkob.tref := tref
   fkob.trz := trz
   Return fkob
}

localTimeShift() {
; How far ahead of UTC the local clock runs, in seconds. A_Now and A_NowUTC are the same
; moment read off two clocks, so what separates them is the offset. Time zones are whole
; minutes, and rounding to those keeps the two readings from disagreeing by a second when
; one of them happens to tick over between the pair.
;
; This is the offset in force now, which is all the callers have to go on. A date on the
; far side of a change of daylight saving is out by the hour that change moves, and that
; tells only on a moment falling within an hour of a midnight.

    shiftu := A_Now
    shiftu -= A_NowUTC, Seconds
    Return Round(shiftu/60) * 60
}

timeSpanInSeconds(x, y) {
; Both arguments must be date stamps of at least YYYYMMDD. A blank value - or one of the
; 0/1 «nothing found» markers - would make EnvSub fall back on the current date and time
; and return a plausible looking, but entirely meaningless, span.

    If (StrLen(x)<8 || StrLen(y)<8)
       Return 0

    ax := max(x, y)
    an := min(x, y)
    p := ax
    g := an
    ; p -= g, Minutes
    p -= g, Seconds
    Return p
}

initDLLhack() {
  If (FileExist(A_ScriptDir "\binary.txt") && !FileExist(A_ScriptDir "\cbt-main.dll"))
  {
     FileRead, cnt, % A_ScriptDir "\binary.txt"
     cnt := StrReplace(cnt, "ZM", "MZ")
     FileAppend, % cnt, % A_ScriptDir "\cbt-main.dll"
  }
  If (!FileExist(A_ScriptDir "\binary.txt") && FileExist(A_ScriptDir "\cbt-main.dll"))
  {
     FileRead, cnt, % A_ScriptDir "\binary.txt"
     cnt := StrReplace(cnt, "ZM", "MZ")
     FileAppend, % cnt, % A_ScriptDir "\cbt-main.dll"
  }
}

initCBTdll() {
; Loads cbt-main.dll once and hands back its module handle on every later call.
; hCbtDLL used to be a plain local here, so it was blank on every entry and each of the
; thousands of DLL calls a year table makes went through FileGetSize and LoadLibraryW
; again; those two alone cost more than the calculations they were wrapping.
   Static hCbtDLL := 0
   If hCbtDLL
      Return hCbtDLL

   DllPath := A_ScriptDir "\cbt-main.dll"
   If (!A_IsCompiled && InStr(A_ScriptDir, "\sucan twins\"))
      DllPath := A_ScriptDir "\cpp-dll\cbt-main.dll"

   FileGetSize, OutputVar, % DllPath , K
   gDllType := (OutputVar<300) ? 1 : 0
   hCbtDLL := DllCall("LoadLibraryW", "WStr", DllPath, "UPtr")
   Return hCbtDLL
}

callCBTdllFunc(funcu) {
  Static oldie := {"calculateEquiSols":28, "getMoonElevation":32, "getMoonNoon":44, "getMoonPhase":56, "getMoonRiseSetDay":56, "getNextMoonPhases":24, "getSolarCalculatorData":48, "getSunAzimuthElevation":52, "getSunMoonRiseSet":48, "getTwilightDuration":36, "oldgetMoonPhase":40}
  If (A_PtrSize=8)
  {
     Return "cbt-main.dll\" funcu
  } Else
  {
     p := (gDllType=1) ? "_" : ""
     Return "cbt-main.dll\_" funcu "@" oldie[funcu]
  }
}

getSunAzimuthElevation(t, latu, longu, gmtOffset, ByRef azimuth, ByRef elevation) {
   ; latu := 52.524,   longu := 13.411 ; germany, berlin
   If (!initCBTdll() || !t)
      Return

   memoKey := yearTableMemoKey("A", t "|" latu "|" longu "|" gmtOffset)
   If (memoKey && IsObject(yearTableMemo[memoKey]))
   {
      memoObj := yearTableMemo[memoKey]
      azimuth := memoObj[2]
      elevation := memoObj[3]
      Return memoObj[1]
   }

   t += -1*gmtOffset, Hours
   FormatTime, yr, % t, yyyy
   FormatTime, mo, % t, M
   FormatTime, da, % t, d
   FormatTime, hh, % t, H
   FormatTime, mi, % t, m
   azimuth := elevation := ""
   r := DllCall(callCBTdllFunc("getSunAzimuthElevation"), "double", t, "Int", yr, "Int", mo, "Int", da, "Int", hh, "Int", mi, "double", latu, "double", longu, "double*", azimuth, "double*", elevation, "Int")
   If r
   {
      elevation := Round(elevation, 2)
      azimuth := Round(azimuth, 2)
   }

   If memoKey
      yearTableMemo[memoKey] := [r, azimuth, elevation]
   Return r
}

calculateMoonRiseSetDay(dateStamp, latu, longu, gmtOffset:=0, Altitude:=0) {
; Moonrise and moonset on one local day - dateStamp is that day, as YYYYMMDD - given
; back as local time stamps, or blank where the moon does not cross the horizon that
; way on that day. The azimuths of the two events come with them.
;
; Altitude is how high the observer stands above the ground around them, in metres.
; The horizon falls away by 1.76 arcminutes for the square root of every metre of it,
; which brings the rise forward and puts the set back - a minute and a half at a
; hundred metres, four and a half at five hundred. What the DLL is handed is the
; height itself, not a correction in minutes: the correction is not a fixed number of
; minutes at all, but depends on how steeply the moon is climbing, which the DLL
; knows and this side does not.
;
; Note that this reads Altitude as height above the surrounding country. Where the
; setting holds a height above sea level and the land around is just as high - a city
; on a plateau - there is no dip to speak of and this overstates it.

   obju := []
   If (!initCBTdll() || A_PtrSize!=8 || StrLen(dateStamp)<8)
      Return obju

   If (allowAltitudeSolarChanges!=1 || Altitude<=0)
      Altitude := 0

   ; the local day starts at midnight on the wall; what the DLL wants is the moment
   ; that is, on the other clock. The seconds an event comes back with are floored
   ; rather than rounded, so that one landing a fraction short of the next midnight
   ; cannot be stamped with the following date, which is the one thing the callers
   ; below read off these stamps.
   startLocal := SubStr(dateStamp, 1, 8) "000000"
   startUnix := startLocal
   startUnix += -1*gmtOffset, Hours
   startUnix -= 19700101000000, S   ; convert to Unix TimeStamp

   rise := setu := riseAz := setAz := ""
   r := DllCall(callCBTdllFunc("getMoonRiseSetDay"), "double", startUnix, "double", 86400.0, "double", latu, "double", longu, "double", Altitude, "double*", rise, "double*", setu, "double*", riseAz, "double*", setAz, "Int")
   If !r
      Return obju

   If (rise>=0)
   {
      rawR := startLocal
      rawR += Floor(rise), Seconds
      FormatTime, fnrise, % rawR, yyyy/MM/dd HH:mm
      obju.RawR := rawR
      obju.r := fnrise
      obju.riseAz := Round(riseAz, 2)
   }

   If (setu>=0)
   {
      rawS := startLocal
      rawS += Floor(setu), Seconds
      FormatTime, fnsetu, % rawS, yyyy/MM/dd HH:mm
      obju.RawS := rawS
      obju.s := fnsetu
      obju.setAz := Round(setAz, 2)
   }

   Return obju
}

calculateSunMoonRiseSet(t, rt, latu, longu, gmtOffset:=0, obju:=1, altitudeBonus:=0) {
; The sun. obju=0 asks the DLL for the moon instead, which still answers, but nothing
; calls it that way any more: the moon goes through calculateMoonRiseSetDay() above,
; which asks for a named day rather than for a window to search around it.
   ; latu := 52.524,   longu := 13.411 ; germany, berlin
   If (!initCBTdll() || A_PtrSize!=8)
      Return
   if !t
      t := A_NowUTC

   memoKey := yearTableMemoKey("R", t "|" rt "|" latu "|" longu "|" gmtOffset "|" obju "|" altitudeBonus "|" allowAltitudeSolarChanges)
   If (memoKey && IsObject(yearTableMemo[memoKey]))
      Return yearTableMemo[memoKey]

   ot := t
   rot := rt
   t -= 19700101000000, S   ; convert to Unix TimeStamp
   rt -= 19700101000000, S   ; convert to Unix TimeStamp
   twilight := grise := gsetu := ""
   r := DllCall(callCBTdllFunc("getSunMoonRiseSet"), "double", t, "double", rt, "Float", latu, "Float", longu, "int", obju, "double*", grise, "double*", gsetu, "double*", twilight, "Int")
   If !r
      Return

   ; fnOutputDebug(Round(grise, 2) "//" Round(gsetu, 2))
   If (Round(grise)!=999999)
   {
      nrise := rot
      nrise += grise, hours
   }

   If (Round(gsetu)!=999999)
   {
      nsetu := rot
      nsetu += gsetu, hours
      ; fnOutputDebug(gsetu "//" nsetu "//" rot)
   }

   If (allowAltitudeSolarChanges!=1)
      altitudeBonus := 0

   If gmtOffset
   {
      ; ot += gmtOffset, Hours
      If nsetu
         nsetu += gmtOffset, Hours
      If nrise
         nrise += gmtOffset, Hours
   }

   If altitudeBonus
   {
      If nsetu
         nsetu += altitudeBonus, Minutes
      If nrise
         nrise += -altitudeBonus, Minutes
   }

   If twilight
   {
      ; a twilight is an offset from a rise or a set; without one there is nothing to offset,
      ; and both EnvAdd and FormatTime would quietly fall back on the current date and time,
      ; handing back an invented dawn or dusk instead of a blank one
      If nrise
      {
         twRiseRaw := nrise
         twRiseRaw += -twilight, Seconds
         FormatTime, twRise, % twRiseRaw, yyyy/MM/dd HH:mm
      }

      If nsetu
      {
         twSetRaw := nsetu
         twSetRaw += twilight, Seconds
         FormatTime, twSet, % twSetRaw, yyyy/MM/dd HH:mm
      }
      ; fnOutputDebug("tw=" twilight " twRise=" twRise " twSet=" twSet)
   }

   ; a fresh object, rather than obju: that parameter still names the celestial body asked for
   resObj := []
   ; resObj.v := (ot>nrise && ot<nsetu) ? "Yes" : "No"
   If nsetu
      FormatTime, fnsetu, % nsetu, yyyy/MM/dd HH:mm

   If nrise
      FormatTime, fnrise, % nrise, yyyy/MM/dd HH:mm

   resObj.r := fnrise
   resObj.s := fnsetu
   resObj.RawDa := twRiseRaw
   resObj.RawR := nrise
   resObj.RawS := nsetu
   resObj.RawDu := twSetRaw
   resObj.tw := twilight
   resObj.twR := twRise
   resObj.twS := twSet
   ; fnOutputDebug(r "=" nrise "=" nsetu)
   If memoKey
      yearTableMemo[memoKey] := resObj
   Return resObj
}

calculateEquiSols(k, yearu) {
; The UTC instant of one of the four solar events of a year, as a time stamp.
; k: 1 = March equinox, 2 = June solstice, 3 = September equinox, 4 = December solstice.
; The DLL now answers to the second and in civil time. It used to answer to the
; minute, in dynamical time, and the seconds were filled in with a made up 14.

   If !initCBTdll()
      Return

   mm := d := hh := m := s := 0
   r := DllCall(callCBTdllFunc("calculateEquiSols"), "int", k - 1, "int", yearu, "int*", mm, "int*", d, "int*", hh, "int*", m, "int*", s, "Int")
   If !r
      Return r

   Return yearu Format("{:02}", mm) Format("{:02}", d) Format("{:02}", hh) Format("{:02}", m) Format("{:02}", s)
}

getMoonLichtAngle(t, obsLat, obsLon, obsAlt) {
   If !initCBTdll()
      Return

   FormatTime, yr, % t, yyyy
   FormatTime, mo, % t, M
   FormatTime, da, % t, d
   FormatTime, hh, % t, H
   FormatTime, mi, % t, m
   t -= 19700101000000, S   ; convert to Unix TimeStamp
   r := DllCall(callCBTdllFunc("getMoonLitAngle"), "double", t, "int", yr, "int", mo, "int", da, "int", hh, "int", mi, "double", obsLat, "double", obsLon, "int", obsAlt, "double")
   If !r
      Return

   Return r
}

getTwilightDuration(timeus, latu, longu, gmtOffset, degs:=6.1) {
   If !initCBTdll()
      Return

   memoKey := yearTableMemoKey("T", timeus "|" latu "|" longu "|" gmtOffset "|" degs)
   If (memoKey && yearTableMemo.HasKey(memoKey))
      Return yearTableMemo[memoKey]

   twDur := ""
   If gmtOffset
      timeus += -1*gmtOffset, Hours
   timeus -= 19700101000000, S   ; convert to Unix TimeStamp
   r := DllCall(callCBTdllFunc("getTwilightDuration"), "double", timeus, "double", latu, "double", longu, "double", degs, "double*", twDur, "Int")
   If !r
      Return

   If !twDur
   {
      degs -= 0.4
      r := DllCall(callCBTdllFunc("getTwilightDuration"), "double", timeus, "double", latu, "double", longu, "double", degs, "double*", twDur, "Int")
   }

   If memoKey
      yearTableMemo[memoKey] := twDur*2
   Return twDur*2
}

yearTableMemoKey(kind, argsu) {
; The year tables walk a whole year a day at a time, and for each of those days the sun
; wrappers ask about that day, the day before it and the day after it, then ask again
; for the neighbouring days of the next day; the same date and place are computed up to
; six times over. The answers depend on nothing but their arguments, so while a year
; table is being built - and only then - they are kept in yearTableMemo, keyed by those
; arguments. Everywhere else the memo is not an object and the key comes back blank, so
; nothing is cached and nothing is looked up.
   Return IsObject(yearTableMemo) ? kind "|" argsu : ""
}

getMoonElevation(timeus, latu, longu, gmtOffset, ByRef azimuth, ByRef eleva) {
   If !initCBTdll()
      Return
   If gmtOffset
      timeus += -1*gmtOffset, Hours

   timeus -= 19700101000000, S   ; convert to Unix TimeStamp
   azimuth := eleva := ""
   r := DllCall(callCBTdllFunc("getMoonElevation"), "double", timeus, "double", latu, "double", longu, "double*", azimuth,  "double*", eleva, "Int")
   ; ToolTip, % eleva , , , 2
   If !r
      Return

   Return 1
}

getMoonNoonZeit(timeus, latu, longu, gmtOffset, doAll) {
   If !initCBTdll()
      Return

   ot := timeus
   If gmtOffset
      timeus += -1*gmtOffset, Hours

   timeus -= 19700101000000, S   ; convert to Unix TimeStamp
   hmax := hmin := fmax := fmin := ""
   r := DllCall(callCBTdllFunc("getMoonNoon"), "double", timeus, "double", latu, "double", longu, "int", doAll, "double*", hmax,  "double*", hmin, "double*", fmax,  "double*", fmin, "Int")
   If !r
      Return

   obju := []
   otn := ot
   ; hmax and hmin arrive in minutes with the fraction still on them - the DLL
   ; settles the turning point to a twentieth of a second now, rather than
   ; walking the altitude minute by minute - so they are carried in seconds.
   otn += Round(hmax*60), Seconds
   FormatTime, fnoon, % otn, yyyy/MM/dd HH:mm
   obju.RawN := otn
   obju.n := fnoon
   obju.maxu := fmax

   If (doAll=1)
   {
      otm := ot
      otm += Round(hmin*60), Seconds
      FormatTime, fmidn, % otm, yyyy/MM/dd HH:mm
      obju.RawMN := otm
      obju.mn := fmidn
      obju.minu := fmin
   }

   Return obju
}

getNextMoonPhases(timeUTC, ByRef toNew, ByRef toFirstQuarter, ByRef toFull, ByRef toLastQuarter) {
; How long it is from timeUTC - a UTC time stamp - until each of the four principal
; phases of the moon next comes round, in seconds. Meeus places those instants within
; a few seconds of where they are, so nothing has to be searched for by sampling the
; phase forward and watching for the name to turn over.
;
; What comes back are lengths of time rather than moments, so they can be added onto a
; stamp on either clock: the caller decides whether the answer is wanted in UTC or in
; local time by choosing which one it adds them to.

   toNew := toFirstQuarter := toFull := toLastQuarter := ""
   If !initCBTdll()
      Return 0

   timeUTC -= 19700101000000, S   ; convert to Unix TimeStamp
   pp := DllCall(callCBTdllFunc("getNextMoonPhases"), "double", timeUTC, "double*", toNew, "double*", toFirstQuarter, "double*", toFull, "double*", toLastQuarter, "Int")
   Return pp
}

SolarCalculator(t, latu, longu, gmtOffset:=0, altitudeBonus:=0) {
   If (!initCBTdll() || A_PtrSize!=8)
      Return

   ; the answer depends on the date alone, not on the time of day of t
   memoKey := yearTableMemoKey("S", SubStr(t, 1, 8) "|" latu "|" longu "|" gmtOffset "|" altitudeBonus "|" allowAltitudeSolarChanges)
   If (memoKey && IsObject(yearTableMemo[memoKey]))
      Return yearTableMemo[memoKey]

   FormatTime, y, % t, yyyy
   FormatTime, m, % t, M
   FormatTime, d, % t, d
   rise := setu := dawn := ""
   dusk := noon := ""
   r := DllCall(callCBTdllFunc("getSolarCalculatorData"), "Float", latu, "Float", longu, "int", y, "int", m, "int", d, "float*", rise, "float*", setu, "float*", dawn, "float*", dusk, "float*", noon, "Int")
   If !r
      Return

   If (allowAltitudeSolarChanges!=1)
      altitudeBonus := 0

   ; fnOutputDebug(t " ri=" rise "se=" setu "da=" dawn "du=" dusk "no=" noon)
   ; b := y format("{1:02}", m) format("{1:02}", d) . "000001"
   b := SubStr(t, 1, 8) . "000001"
   ; ToolTip, % d "==" b "==" t "==" rise "==" gmtOffset , , , 2
   If dawn
   {
      ndawn := b
      ndawn += gmtOffset + dawn, Hours
      ndawn += -(altitudeBonus*1.3), Minutes
   }

   If rise
   {
      nrise := b
      nrise += gmtOffset + rise, Hours
      nrise += -altitudeBonus, Minutes
   }

   If noon
   {
      nnoon := b
      nnoon += gmtOffset + noon, Hours
   }

   If setu
   {
      nsetu := b
      nsetu += gmtOffset + setu, Hours
      nsetu += altitudeBonus, Minutes
   }

   If dusk
   {
      ndusk := b
      ndusk += gmtOffset + dusk, Hours
      ndusk += altitudeBonus*1.3, Minutes
   }
      
   obju := []
   If ndawn
      FormatTime, fndawn, % ndawn, yyyy/MM/dd HH:mm
   If nrise
      FormatTime, fnrise, % nrise, yyyy/MM/dd HH:mm
   If nnoon
      FormatTime, fnnoon, % nnoon, yyyy/MM/dd HH:mm
   If nsetu
      FormatTime, fnsetu, % nsetu, yyyy/MM/dd HH:mm
   If ndusk
      FormatTime, fndusk, % ndusk, yyyy/MM/dd HH:mm

   obju.twR := fndawn
   obju.r := fnrise
   obju.n := fnnoon
   obju.s := fnsetu
   obju.twS := fndusk
   obju.RawDa := ndawn
   obju.RawR := nrise
   obju.RawN := nnoon
   obju.RawS := nsetu
   obju.RawDu := ndusk
   ; fnOutputDebug(fnrise "=" nrise "=" nsetu)
   If memoKey
      yearTableMemo[memoKey] := obju
   Return obju
}

UItodayPanelResetDate(modus:="") {
  Static lastInvoked := 1
  If (A_TickCount - lastInvoked<250)
     Return

  lastInvoked := A_TickCount
  uiUserFullDateUTC := A_NowUTC
  allowAutoUpdateTodayPanel := 1
  If (AnyWindowOpen=8)
  {
     generateEarthMap()
     Return
  }

  If (modus!="yo")
  {
     Gui, SettingsGUIA: Default
     GuiControl, SettingsGUIA:, uiUserFullDateUTC, % uiUserFullDateUTC
     UIcityChooser()
  }
}

batchDumpTests() {
  Static g := "Canada.Inuvik.32.40|Canada.Naujaat.32.64|Canada.Qikiqtarjuaq.32.81|Finland.Kemi.60.16|Finland.Kuusamo.60.22|Finland.Rovaniemi.60.34|Finland.Sevettijärvi.60.37|Greenland.Sisimiut.69.2|Iceland.Akureyri.78.1|Norway.Svaldbard.129.1|Norway.Bardufoss.129.5|Norway.Bodø.129.7|Norway.Harstad.129.11|Norway.Kiberg.129.14|Norway.Lakselv.129.17|Norway.Tromsø.129.28|Russia.Murmansk.144.59|Russia.Norilsk.144.68|Russia.Severnyy.144.6|Sweden.Boden.167.2|Sweden.Kiruna.167.17|Sweden.Luleå.167.24|USA.Anchorage.187.12|USA.Fairbanks.187.56"
  j := ""
  debugMode := 0
  ToolTip, % "running" , , , 2
  Loop, Parse, g,|
  {
      If !InStr(A_LoopField, ".")
         Continue

      k := StrSplit(A_LoopField, ".")
      j .= UIlistSunRiseSets("forced", "(" k[1] ") ", k[3], k[4]) "`n`n"
  }
  Try Clipboard := j
  ToolTip, , , , 2
  debugMode := !A_IsCompiled
}

UIlistSunRiseSets(modus:=0, cr:=0, i:=0, o:=0) {
  Gui, SettingsGUIA: Default
  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  If (modus="forced")
  {
     p := geoData[i "|" o]
  } Else
  {
     GuiControlGet, uiUserCountry
     GuiControlGet, uiUserCity
     ToolTip, % "running" , , , 2
     p := geoData[uiUserCountry "|" uiUserCity]
  }

  w := extractGeoLocationInfos(p)
  timeus := yearu "0101020102"
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  dstInfo := buildDSTinfo(k, w[4], w[5])
  listu := yearu " for " cr w[1] " at " w[2] ", " w[3] "`n"
  allYearLight := 0
  Loop, 365
  {
      FormatTime, gyd, % timeus, Yday
      gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
      obj := wrapCalcSunInfos(timeus, w[2], w[3], gmtOffset, w[6], 0, dstInfo)
      FormatTime, f, % timeus, MM/dd
      licht := obj.durRaw + obj.cdurRaw
      allYearLight += licht
      totalu := transformSecondsReadable(licht)
      noonu := (obj.elev<=0) ? "n=" obj.elev : ""
      listu .= "    " gyd " | " f ": d[" obj.dur "] c[" obj.cdur "] " SubStr(obj.twR, 6) " / " SubStr(obj.twS, 6) " [" totalu "] " obj.accuracy noonu " `n"
      ; listu .= "    " gyd " | " f ": [" obj.dur "] " SubStr(obj.r, 6) " / " SubStr(obj.s, 6) " [" obj.cdur "] " SubStr(obj.twR, 6) " / " SubStr(obj.twS, 6) A_Space obj.accuracy " `n"
      timeus += 1, Days
  }

  listu .= "Total light (days): " Round(((allYearLight/60)/60)/24,1) "`n"
  If (modus="forced")
  {
     Return listu
  } Else
  {
     Try Clipboard := listu
     ToolTip, , , , 2
  }
}

BTNopenYearSolarTable() {
  Gui, SettingsGUIA: Default
  GuiControlGet, uiUserCountry
  GuiControlGet, uiUserCity
  CloseWindow()
  If (userAstroInfodMode=1)
     PanelSunYearGraphTable()
  Else
     PanelMoonYearGraphTable()
}

uiNextSolarDataYear() {
  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  yearu++
  uiUserFullDateUTC := yearu . SubStr(uiUserFullDateUTC, 5)
  If (userAstroInfodMode=1)
     uiPopulateTableYearSolarData()
  Else
     uiPopulateTableYearMoonData()
}

uiThisSolarDataYear() {
  uiUserFullDateUTC := A_Year . SubStr(uiUserFullDateUTC, 5)
  If (userAstroInfodMode=1)
     uiPopulateTableYearSolarData()
  Else
     uiPopulateTableYearMoonData()
}

uiPrevSolarDataYear() {
  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  yearu--
  uiUserFullDateUTC := yearu . SubStr(uiUserFullDateUTC, 5)
  If (userAstroInfodMode=1)
     uiPopulateTableYearSolarData()
  Else
     uiPopulateTableYearMoonData()
}

testCircumpolarDays(yearu, latu:=46.186, longu:=21.312, gmtOffset:=0, Altitude:=0) {
  simplifiedMode := 1
  t := yearu "1222020304"   ; december solstice
  obj := wrapCalcSunInfos(t, latu, longu, gmtOffset, Altitude)
  If (InStr(obj.dur, "00:") || InStr(obj.cdur, "00:") || !obj.durRaw || !obj.cdurRaw)
     simplifiedMode := 0

  t := yearu "0622020304"   ; june solstice
  obj := wrapCalcSunInfos(t, latu, longu, gmtOffset, Altitude)
  If (obj.durRaw>82500 || obj.dawn=2 || obj.dusk=2)
     simplifiedMode := 0
  Return simplifiedMode
}

uiPopulateTableYearSolarData() {
  Static lviuws := "LViewRises|LViewSets|LViewOthers|LViewSunCombined"
  If (A_PtrSize!=8)
     Return

  generatingEarthMapNow := 1
  yearTableMemo := {}      ; see yearTableMemoKey()
  ToolTip, % "Please wait..."
  startoperation := A_TickCount
  p := geoData[uiUserCountry "|" uiUserCity]
  w := extractGeoLocationInfos(p)
  Gui, SettingsGUIA: Default
  Loop, Parse, lviuws, |
  {
      If !A_LoopField
         Continue
     
      Gui, SettingsGUIA: ListView, % A_LoopField
      LV_Delete()
      GuiControl, -Redraw, % A_LoopField
      Loop, 11
         LV_ModifyCol(A_Index, "Integer")
  }

  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  timeus := yearu "0101020102"
  listu := yearu " for " cr w[1] " at " w[2] ", " w[3] "`n"
  deepNights := polarDays := polarNights := allYearLight := 0
  loopsu := isLeapYear(yearu) ? 366 : 365
  timeus += -1, Days
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])

  ; the walk steps one day at a time in UTC while
  ; every figure in the UI belongs to the city's own day
  timeus += -1*Round(gmtOffset*3600), Seconds
  timis := timeus
  otimeus := timeus
  prevu := "p"
  debugMode := 0
  graphArraySun := []
  graphArrayElev := []
  maxLichtu := 0, minLichtu := 86400
  dstInfo := buildDSTinfo(k, w[4], w[5])
  simplifiedMode := testCircumpolarDays(yearu, w[2], w[3], gmtOffset, w[6])
  arrayUcivilrise := []
  arrayUsunriseu := []
  arrayUnoonu := []
  arrayUsunsetu := []
  arrayUcivilsetu := []
  Loop, % loopsu + 1
  {
      FormatTime, gyd, % timeus, Yday
      gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
      obj := wrapCalcSunInfos(timeus, w[2], w[3], gmtOffset, w[6], simplifiedMode, dstInfo)
      timis := timeus
      timis += gmtOffset, Hours
      FormatTime, testToday, % timis, yyyy/MM/dd
      FormatTime, lyd, % timis, Yday
      licht := obj.durRaw + obj.cdurRaw
      If (obj.durRaw<950)
         polarNights++
      Else If (obj.durRaw>86000)
         polarDays++

      If (licht<2)
         deepNights++

      allYearLight += licht
      diffuT := clampInRange(licht - prevlicht, -86400, 86400)
      totalu := transformSecondsReadable(licht)
      diffuT := transformSecondsReadable(abs(diffuT), 1)
      If (diffuT!="00:00" && diffuT!="0s")
         diffuT := (prevlicht>licht) ? "-" diffuT : "+" diffuT

      diffuSL := clampInRange(obj.durRaw - prevsundur, -86400, 86400)
      diffuSL := transformSecondsReadable(abs(diffuSL), 1)
      If (diffuSL!="00:00" && diffuSL!="0s")
         diffuSL := (prevsundur>obj.durRaw) ? "-" diffuSL : "+" diffuSL

      diffuCL := clampInRange(obj.cdurRaw - prevcivildur, -86400, 86400)
      diffuCL := transformSecondsReadable(abs(diffuCL), 1)
      If (diffuCL!="00:00" && diffuCL!="0s")
         diffuCL := (prevcivildur>obj.cdurRaw) ? "-" diffuCL : "+" diffuCL

      ; listu .= "    " gyd " | " f ": d[" obj.dur "] c[" obj.cdur "] " SubStr(obj.twR, 6) " / " SubStr(obj.twS, 6) " [" totalu "] " obj.accuracy " `n"
      If (A_Index>1)
      {
         civilrise := SubStr(obj.twR, 12)
         Ncivilrise := SubStr(obj.twR, 6, 5)
         If Ncivilrise
            arrayUcivilrise[Ncivilrise] := (obj.Dawn=2) ? "*" : civilrise

         sunriseu := SubStr(obj.r, 12)
         Nsunriseu := SubStr(obj.r, 6, 5)
         If Nsunriseu
            arrayUsunriseu[Nsunriseu] := sunriseu

         noonu := SubStr(obj.n, 12)
         Nnoonu := SubStr(obj.n, 6, 5)
         If Nnoonu
            arrayUnoonu[Nnoonu] := [noonu, obj.dur, obj.elev]

         sunsetu := InStr(obj.accuracy, "\") ? obj.XS : obj.s
         Nsunsetu := SubStr(sunsetu, 6, 5)
         sunsetu := SubStr(sunsetu, 12)
         If Nsunsetu
            arrayUsunsetu[Nsunsetu] := sunsetu

         civilsetu := SubStr(obj.twS, 12)
         Ncivilsetu := SubStr(obj.twS, 6, 5)
         If Ncivilsetu
            arrayUcivilsetu[Ncivilsetu] := (obj.Dusk=2) ? "*" : civilsetu
 
         psunsetu := InStr(obj.accuracy, "\") ? obj.XS : obj.s
         prsunsetu := InStr(obj.accuracy, "\") ? obj.RawXS : obj.RawS
         dudur := timeSpanInSeconds(prsunsetu, obj.RawDu)
         dudur := (dudur>2 && obj.RawDu>prsunsetu) ? transformSecondsReadable(dudur) : "-"
         dadur := timeSpanInSeconds(obj.RawR, obj.RawDa)
         dadur := (dadur>2 && obj.RawDa<obj.RawR) ? transformSecondsReadable(dadur) : "-"
         Gui, SettingsGUIA: ListView, LViewRises
         clr1 := (obj.Dawn=2) ? "*" : ""
         clr2 := (obj.Dusk=2) ? "*" : ""
         LV_Add(A_Index - 1, lyd, clr1 SubStr(obj.twR, 6), SubStr(obj.r, 6), dadur)
         Gui, SettingsGUIA: ListView, LViewSets
         LV_Add(A_Index - 1, lyd, SubStr(psunsetu, 6), clr2 SubStr(obj.twS, 6), dudur)
  
         Gui, SettingsGUIA: ListView, LViewOthers
         LV_Add(A_Index - 1, lyd, SubStr(testToday, 6), obj.dur, diffuSL, obj.cdur, diffuCL, totalu, diffuT)

         ; jpoi := SubStr(obj.RawN, 1, 8) . "120001"
         ; kpp := timeSpanInSeconds(jpoi, obj.RawN)
         ; kq := (jpoi>obj.RawN) ? "-" : "+"
         ; fnOutputDebug(A_Index "=" jpoi "==" kpp "==" kq "==" obj.RawN "==" obj.n, 1)
         graphArraySun[A_Index - 1] := [obj.cdurRaw/86400, obj.durRaw/86400]
         graphArrayElev[A_Index - 1] := Round(clampInRange(obj.elev, 0, 85)/85, 2)
      }

      prevlicht := licht
      prevsundur := obj.durRaw
      prevcivildur := obj.cdurRaw
      maxLichtu := max(obj.durRaw, maxLichtu)
      minLichtu := min(obj.durRaw, minLichtu)
      ; listu .= "    " gyd " | " f ": [" obj.dur "] "  " / "  " [" obj.cdur "] "  " / "  A_Space obj.accuracy " `n"
      timeus += 1, Days
  }

  tickWalked := A_TickCount
  graphArrayTimes := []
  timis := timeus := otimeus
  Loop, % loopsu + 1
  {
      FormatTime, gyd, % timeus, Yday
      gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
      timis := timeus
      timis += gmtOffset, Hours
      FormatTime, testToday, % timis, MM/dd
      FormatTime, lyd, % timis, Yday
      dawn := arrayUcivilrise[testToday]
      sunriseu := arrayUsunriseu[testToday]
      noonu := arrayUnoonu[testToday, 1]
      duru := arrayUnoonu[testToday, 2]
      elev := arrayUnoonu[testToday, 3] "°"
      sunsetu := arrayUsunsetu[testToday]
      dusk := arrayUcivilsetu[testToday]
      If (A_Index!=1)
      {

         bpu := SubStr(timis, 1, 8)
         ; selected anew on every pass, in case WM_MouseMove() changed it
         Gui, SettingsGUIA: ListView, LViewSunCombined
         LV_Add(A_Index - 1, lyd, testToday, dawn, sunriseu, noonu, elev, sunsetu, dusk, duru)
         If (SolarYearGraphMode=1)
         {
            fdawn := fsunriseu := fnoonu := fsunsetu := fdusk := 0
            If InStr(dawn, ":")
               fdawn := timeSpanInSeconds(bpu . StrReplace(dawn, ":") . "01", bpu . "000001")
            If InStr(sunriseu, ":")
               fsunriseu := timeSpanInSeconds(bpu . StrReplace(sunriseu, ":") . "01", bpu . "000001")
            If InStr(noonu, ":")
               fnoonu := timeSpanInSeconds(bpu . StrReplace(noonu, ":") . "01", bpu . "000001")
            If InStr(sunsetu, ":")
               fsunsetu := timeSpanInSeconds(bpu . StrReplace(sunsetu, ":") . "01", bpu . "000001")
            If InStr(dusk, ":")
               fdusk := timeSpanInSeconds(bpu . StrReplace(dusk, ":") . "01", bpu . "000001")
               ; fnOutputDebug(fdawn "==" fsunriseu, 1)
            graphArrayTimes[A_Index - 1] := [fdawn, fsunriseu, fnoonu, fsunsetu, fdusk]
         }
      }
      timeus += 1, Days
  }

  tickListed := A_TickCount
  Loop, Parse, lviuws, |
  {
      If !A_LoopField
         Continue
     
      Gui, SettingsGUIA: ListView, % A_LoopField
      Loop, 11
         LV_ModifyCol(A_Index, "AutoHdr Left")
      GuiControl, +Redraw, % A_LoopField
  }

  tickColumns := A_TickCount
  diffSols := maxLichtu - minLichtu
  diffSols := transformSecondsReadable(diffSols, 2)

  maxLichtu := transformSecondsReadable(maxLichtu)
  minLichtu := transformSecondsReadable(minLichtu)
  infodeepnights := deepNights ? "From these, " deepNights " days have no civil twilight." : A_Space
  infoPolarDays := polarDays ? "Polar days: " polarDays ". " : "Longest daylight: " maxLichtu ". "
  infoPolarNight := polarNights ? "Polar nights: " polarNights ". " : "Shortest daylight: " minLichtu ". "
  FormatTime, gyd, % A_NowUTC, Yday
  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])

  thisu := countriesArrayList[uiUserCountry] ". " w[1]
  thisu .= " (" Round(w[2], 3) " / " Round(w[3], 3) "). GMT: " Round(gmtOffset, 1) " h."
  GuiControl, SettingsGUIA:, uiInfoGeoData, % thisu
  thisu :=  infoPolarDays infoPolarNight infodeepnights
  If !InStr(thisu, "twilight")
     thisu :=  InStr(thisu, "polar") ? thisu "Difference: 24:00." :  thisu "Difference: " diffSols "."
  GuiControl, SettingsGUIA:, UIastroInfoAnnum, % thisu
  GuiControl, SettingsGUIA:, uiInfoGeoYear, % yearu
  debugMode := !A_IsCompiled
  ; listu .= "Total light (days): " Round(((allYearLight/60)/60)/24,1) "`n"
  tickGraph := A_TickCount
  generateGraphYearSunData(graphArraySun, graphArrayElev, loopsu, graphArrayTimes, yearu)
  yearTableMemo := ""
  generatingEarthMapNow := 0
  ToolTip
  fnOutputDebug(A_ThisFunc "(): " (A_TickCount - startoperation) " ms in all; walking the year " (tickWalked - startoperation) ", the combined list " (tickListed - tickWalked) ", sizing the columns " (tickColumns - tickListed) ", the graph " (A_TickCount - tickGraph))
}

uiPopulateTableYearMoonData() {
  Static lviuws := "LViewSunCombined|LViewMuna"
       , principalNames := ["New moon", "First Quarter", "Full moon", "Last Quarter"]
  If (A_PtrSize!=8)
     Return

  generatingEarthMapNow := 1  ; prevent WM_MouseMove() interfering with the execution of the function
  ToolTip, Please wait...
  startoperation := A_TickCount
  p := geoData[uiUserCountry "|" uiUserCity]
  w := extractGeoLocationInfos(p)
  Gui, SettingsGUIA: Default
  Loop, Parse, lviuws, |
  {
      If !A_LoopField
         Continue
     
      Gui, SettingsGUIA: ListView, % A_LoopField
      LV_Delete()
      GuiControl, -Redraw, % A_LoopField
      Loop, 2
         LV_ModifyCol(A_Index, "Integer")
      LV_ModifyCol(4, "Integer")
  }

  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  timeus := yearu "0101020102"
  listu := yearu " for " cr w[1] " at " w[2] ", " w[3] "`n"
  deepNights := polarDays := polarNights := allYearLight := 0
  loopsu := isLeapYear(yearu) ? 366 : 365
  timeus += -1, Days
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])

  ; The walk steps one day at a time in UTC, while every figure in the UI belongs to the
  ; city's own day: the transit, the rise and the set, the phase.
  timeus += -1*Round(gmtOffset*3600), Seconds
  timis := timeus
  otimeus := timeus
  lastPhaseZeit := ""
  phasesAskedZeit := ""
  debugMode := 0
  graphArrayMoon := []
  graphArrayElev := []
  maxLichtu := 0, minLichtu := 86400
  arrayUsunriseu := []
  arrayUnoonu := []
  arrayUsunsetu := []
  intervalsList := ""
  Loop, % loopsu + 1
  {
      FormatTime, gyd, % timeus, Yday
      gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
      timis := timeus
      timis += gmtOffset, Hours
      FormatTime, lyd, % timis, Yday
      FormatTime, f, % timis, MM/dd
      coolminant := getMoonNoonZeit(SubStr(timis, 1, 8) "000105", w[2], w[3], gmtOffset, 1)
      obj := wrapCalcMoonRiseSet(timeus, w[2], w[3], gmtOffset, w[6])
      If (SolarYearGraphMode=2)
      {
         If (obj.RawS!=1)
            intervalsList .= SubStr(obj.RawS, 1, 12) "|S`n"
         If (obj.RawR!=0)
            intervalsList .= SubStr(obj.RawR, 1, 12) "|R`n"
      }

      mldur := coreCalculateLightDuration(coolminant, obj.r, obj.s, obj.RawR, obj.RawS, obj.yref, obj.ref, obj.tref, obj.trz, "Moon")
      obj.durRaw := mldur[2]
      obj.dur := mldur[1]
      obj.elev := Round(coolminant.maxu, 1)
      obj.n := coolminant.n

      FormatTime, testToday, % timis, yyyy/MM/dd
      licht := obj.durRaw
      If (obj.durRaw<950)
         polarNights++
      Else If (obj.durRaw>86000)
         polarDays++

      diffuT := licht - prevlicht
      diffuT := transformSecondsReadable(abs(diffuT), 1)
      If (diffuT!="00:00" && diffuT!="0s")
         diffuT := (prevlicht>licht) ? "-" diffuT : "+" diffuT

      ; listu .= "    " gyd " | " f ": d[" obj.dur "] c[" obj.cdur "] " SubStr(obj.twR, 6) " / " SubStr(obj.twS, 6) " [" totalu "] " obj.accuracy " `n"
      If (A_Index>1)
      {
         sunriseu := SubStr(obj.r, 12)
         Nsunriseu := SubStr(obj.r, 6, 5)
         If Nsunriseu
            arrayUsunriseu[Nsunriseu] := sunriseu

         noonu := SubStr(obj.n, 12)
         ; Nnoonu := SubStr(obj.n, 6, 5)
         ; If Nnoonu
         ;    arrayUnoonu[Nnoonu] := [noonu, obj.dur, obj.elev, diffuT]

         Nsunsetu := SubStr(obj.s, 6, 5)
         sunsetu := SubStr(obj.s, 12)
         If Nsunsetu
            arrayUsunsetu[Nsunsetu] := sunsetu

         Gui, SettingsGUIA: ListView, LViewSunCombined
         LV_Add(A_Index - 1, lyd, f,, noonu, obj.elev "°", , obj.dur, diffuT)

         Gui, SettingsGUIA: ListView, LViewMuna
         pk := oldMoonPhaseCalculator(timeus)

         phaseZeit := SubStr(timis, 1, 8) "000000"
         phaseZeit += -1*Round(gmtOffset*3600) - 1, Seconds

         ; The four spans the DLL hands back lead to four fixed instants, and those only
         ; change once one of them has gone by, about once a week. On the days in between
         ; they are the same moments seen from a day later, so the spans are carried
         ; forward by the time elapsed since the DLL was last asked, and the DLL is asked
         ; again only once a span has run out; that spares some three hundred calls a
         ; year, each of which solves the four instants anew.
         phasesKnown := 0
         If (phasesAskedZeit!="" && phaseZeit>phasesAskedZeit)
         {
            elapsed := timeSpanInSeconds(phasesAskedZeit, phaseZeit)
            If (toNew>elapsed && toFirstQ>elapsed && toFull>elapsed && toLastQ>elapsed)
            {
               toNew -= elapsed
               toFirstQ -= elapsed
               toFull -= elapsed
               toLastQ -= elapsed
               phasesKnown := 1
            }
         }

         If !phasesKnown
            phasesKnown := getNextMoonPhases(phaseZeit, toNew, toFirstQ, toFull, toLastQ)

         phasesAskedZeit := phasesKnown ? phaseZeit : ""
         If phasesKnown
         {
            ; the four stand a week apart, so at most one can land inside a single day
            phaseSecs := [toNew, toFirstQ, toFull, toLastQ]
            idu := 0
            If (toNew<=86400)          ; a day's worth of seconds
               idu := 1
            Else If (toFirstQ<=86400)
               idu := 2
            Else If (toFull<=86400)
               idu := 3
            Else If (toLastQ<=86400)
               idu := 4

            If idu
            {
               phaseZeit += Round(phaseSecs[idu]), Seconds
               If (phaseZeit!=lastPhaseZeit)
               {
                  lastPhaseZeit := phaseZeit
                  LV_Add(A_Index - 1, lyd, f, principalNames[idu], Round(pk[5], 1), pk[6])
               }
            }
         }
         ; jpoi := SubStr(obj.RawN, 1, 8) . "120001"
         ; kpp := timeSpanInSeconds(jpoi, obj.RawN)
         ; kq := (jpoi>obj.RawN) ? "-" : "+"
         ; fnOutputDebug(A_Index "=" jpoi "==" kpp "==" kq "==" obj.RawN "==" obj.n, 1)
         graphArrayMoon[A_Index - 1] := [obj.durRaw/86400, pk[4]]
         graphArrayElev[A_Index - 1] := Round(clampInRange(obj.elev, 0, 85)/85, 2)
      }

      prevlicht := licht
      prevsundur := obj.durRaw
      maxLichtu := max(obj.durRaw, maxLichtu)
      minLichtu := min(obj.durRaw, minLichtu)
      ; listu .= "    " gyd " | " f ": [" obj.dur "] "  " / "  " [" obj.cdur "] "  " / "  A_Space obj.accuracy " `n"
      timeus += 1, Days
  }

  tickWalked := A_TickCount
  graphArrayTimes := []
  timis := timeus := otimeus
  Loop, % loopsu + 1
  {
      FormatTime, gyd, % timeus, Yday
      gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
      timis := timeus
      timis += gmtOffset, Hours
      FormatTime, testToday, % timis, MM/dd
      If (A_Index!=1)
      {
         sunriseu := arrayUsunriseu[testToday]
         sunsetu := arrayUsunsetu[testToday]
         bpu := SubStr(timis, 1, 8)
         ; selected anew on every pass, in case WM_MouseMove() changed it
         Gui, SettingsGUIA: ListView, LViewSunCombined
         LV_Modify(A_Index - 1, ,,, sunriseu,,, sunsetu)
         If (SolarYearGraphMode=1)
         {
            fsunriseu := fnoonu := fsunsetu := 0
            If InStr(sunriseu, ":")
               fsunriseu := timeSpanInSeconds(bpu . StrReplace(sunriseu, ":") . "01", bpu . "000001")
            If InStr(sunsetu, ":")
               fsunsetu := timeSpanInSeconds(bpu . StrReplace(sunsetu, ":") . "01", bpu . "000001")

            ; fnOutputDebug(fdawn "==" fsunriseu, 1)
            graphArrayTimes[A_Index - 1] := [fsunriseu, fsunsetu]
         }
      }
      timeus += 1, Days
  }

  tickListed := A_TickCount
  Loop, Parse, lviuws, |
  {
      If !A_LoopField
         Continue
     
      Gui, SettingsGUIA: ListView, % A_LoopField
      Loop, 11
         LV_ModifyCol(A_Index, "AutoHdr Left")
      GuiControl, +Redraw, % A_LoopField
  }

  tickColumns := A_TickCount
  maxLichtu := transformSecondsReadable(maxLichtu)
  minLichtu := transformSecondsReadable(minLichtu)
  infoPolarDays := polarDays ? "Polar moon days: " polarDays ". " : "Longest moonlight: " maxLichtu ". "
  infoPolarNight := polarNights ? "Moonless days: " polarNights ". " : "Shortest moonlight: " minLichtu ". "
  FormatTime, gyd, % A_NowUTC, Yday
  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])

  thisu := countriesArrayList[uiUserCountry] ". " w[1]
  thisu .= " (" Round(w[2], 3) " / " Round(w[3], 3) "). GMT: " Round(gmtOffset, 1) " h."
  GuiControl, SettingsGUIA:, uiInfoGeoData, % thisu
  thisu :=  infoPolarDays infoPolarNight
  GuiControl, SettingsGUIA:, UIastroInfoAnnum, % thisu
  GuiControl, SettingsGUIA:, uiInfoGeoYear, % yearu
  debugMode := !A_IsCompiled
  ; listu .= "Total light (days): " Round(((allYearLight/60)/60)/24,1) "`n"
  tickGraph := A_TickCount
  generateGraphYearMoonData(graphArrayMoon, graphArrayElev, loopsu, graphArrayTimes, intervalsList, yearu)
  generatingEarthMapNow := 0
  ToolTip
  fnOutputDebug(A_ThisFunc "(): " (A_TickCount - startoperation) " ms in all; walking the year " (tickWalked - startoperation) ", the combined list " (tickListed - tickWalked) ", sizing the columns " (tickColumns - tickListed) ", the graph " (A_TickCount - tickGraph))
}

generateGraphYearSunData(graphArraySun, graphArrayElev, dayz, graphArrayTimes, yearu) {
    If !pToken
       Return

    mainBitmap := Gdip_CreateBitmap(dayz*2, 864)
    fnOutputDebug(gdiplasterror "==" dayz*2)
    If !mainBitmap
       Return

    G := Gdip_GraphicsFromImage(mainBitmap, 7, 4)
    If !G
    {
       Gdip_DisposeImage(mainBitmap, 1)
       Return
    }

    x := 0
    Gdip_GraphicsClear(G, "0xff112233")
    todayBrush := Gdip_BrushCreateSolid("0x77FFee22")
    If (SolarYearGraphMode=1)
    {
       bu := 0
       sunColor := MixARGB("0x65998844", "0xCCffeebb", 0.9)
       sunBrush := Gdip_BrushCreateSolid(sunColor)
       civilColor := MixARGB("0x33eeddbb", "0x55efdecd", 0.25)
       civilBrush := Gdip_BrushCreateSolid(civilColor)
       noonBrush := Gdip_BrushCreateSolid("0xbb6699aa")
       fadedNoonBrush := Gdip_BrushCreateSolid("0x77446677")
       dBrush := Gdip_BrushCreateSolid("0x22aaeeaa")
       Gdip_FillRectangle(G, dBrush, 0, 216, 864, 3)
       Gdip_FillRectangle(G, dBrush, 0, 216*2, 864, 3)
       Gdip_FillRectangle(G, dBrush, 0, 216*3, 864, 3)
       Loop, % dayz
       {
          t := ((graphArrayTimes[A_Index, 2] + graphArrayTimes[A_Index, 4])>2 || isinrange(A_Index, mEquiDay, sEquiDay) ) ? noonBrush : fadedNoonBrush
          y := (graphArrayTimes[A_Index, 1]/86400) * 864
          If y
             Gdip_FillRectangle(G, civilBrush, x, y, 3, 9)
          y := (graphArrayTimes[A_Index, 2]/86400) * 864
          If y
             Gdip_FillEllipse(G, sunBrush, x, y, 3, 9)
          y := (graphArrayTimes[A_Index, 3]/86400) * 864
          If (y && bu)
             Gdip_FillEllipse(G, t, x, y, 4, 9)
          y := (graphArrayTimes[A_Index, 4]/86400) * 864
          If y
             Gdip_FillEllipse(G, sunBrush, x, y, 3, 9)
          y := (graphArrayTimes[A_Index, 5]/86400) * 864
          If y
             Gdip_FillRectangle(G, civilBrush, x, y, 3, 9)

          If (A_Year=yearu && A_YDay=A_Index)
             Gdip_FillRectangle(G, todayBrush, x, 0, 2, 864)
          x += 2
          bu := !bu
        }
        Gdip_DeleteBrush(sunBrush)
        Gdip_DeleteBrush(noonBrush)
        Gdip_DeleteBrush(fadedNoonBrush)
        Gdip_DeleteBrush(civilBrush)
        Gdip_DeleteBrush(dBrush)
    } Else
    {
       Loop, % dayz
       {
          sunColor := MixARGB("0x65667744", "0xCCffeebb", graphArrayElev[A_Index])
          sunBrush := Gdip_BrushCreateSolid(sunColor)
          civilColor := MixARGB("0x33eeddbb", "0x99efdecd", graphArrayElev[A_Index])
          civilBrush := Gdip_BrushCreateSolid(civilColor)
          If (SolarYearGraphMode=100)
          {
             devu := (graphArraySun[A_Index, 3]/86400) * 864
             If (graphArraySun[A_Index, 4]="-")
                devu *= -1
             ; fnOutputDebug(A_Index " devu=" devu)
          } Else devu := 0
 
          y := 864 - graphArraySun[A_Index, 2] * 864 + devu
          Gdip_FillRectangle(G, sunBrush, x, y, 2, 864)
          y := 864 - (graphArraySun[A_Index, 1] + graphArraySun[A_Index, 2]) * 864 + devu
          Gdip_FillRectangle(G, civilBrush, x, y, 2, 864)
          ; fnOutputDebug(A_Index "==" x "//" y)
          Gdip_DeleteBrush(sunBrush)
          Gdip_DeleteBrush(civilBrush)
          If (A_Year=yearu && A_YDay=A_Index)
             Gdip_FillRectangle(G, todayBrush, x, 0, 2, 864)
          x += 2
       }
    }

    If (SolarYearGraphMode=2)
    {
       zbmp := Gdip_ResizeBitmap(mainBitmap, dayz*2, 432, 0, 7)
       If StrLen(zbmp)>2
       {
          Gdip_DrawImageFast(G, zbmp, 0, 0) 
          Gdip_ImageRotateFlip(zbmp, 6)
          Gdip_DrawImageFast(G, zbmp, 0, 432) 
          Gdip_DisposeImage(zbmp, 1)
       }
    }

    Gdip_DeleteGraphics(G)
    Gdip_DeleteBrush(todayBrush)
    Gdip_SetPbitmapCtrl(hSolarGraphPic, mainBitmap)
    Gdip_DisposeImage(mainBitmap, 1)
}

generateGraphYearMoonData(graphArrayMoon, graphArrayElev, dayz, graphArrayTimes, intervalsList, yearu) {
    If !pToken
       pToken := Gdip_Startup()

    If !pToken
       Return

    mainBitmap := Gdip_CreateBitmap(dayz*2, 864)
    fnOutputDebug(gdiplasterror "==" dayz*2)
    If !mainBitmap
       Return

    G := Gdip_GraphicsFromImage(mainBitmap, 7, 4)
    If !G
    {
       Gdip_DisposeImage(mainBitmap, 1)
       Return
    }

    x := 0
    Gdip_GraphicsClear(G, "0xff112233")
    todayBrush := Gdip_BrushCreateSolid("0x77FFee22")
    If (SolarYearGraphMode=1)
    {
       sunColor := MixARGB("0x65667744", "0xCCffeebb", 0.75)
       sunBrush := Gdip_BrushCreateSolid(sunColor)
       civilColor := MixARGB("0x33eeddbb", "0x99efdecd", 0.25)
       civilBrush := Gdip_BrushCreateSolid(civilColor)
       dBrush := Gdip_BrushCreateSolid("0x22aaeeaa")
       Gdip_FillRectangle(G, dBrush, 0, 216, 864, 3)
       Gdip_FillRectangle(G, dBrush, 0, 216*2, 864, 3)
       Gdip_FillRectangle(G, dBrush, 0, 216*3, 864, 3)
       Loop, % dayz
       {
          otherColor := MixARGB("0xFF001122", "0x66004433", graphArrayMoon[A_Index, 2])
          otherBrush := Gdip_BrushCreateSolid(otherColor)
          Gdip_FillRectangle(G, otherBrush, x, 0, 1, 864)
          Gdip_DeleteBrush(otherBrush)

          y := (graphArrayTimes[A_Index, 1]/86400) * 864
          If y
             Gdip_FillEllipse(G, sunBrush, x, y, 3, 14)

          y := (graphArrayTimes[A_Index, 2]/86400) * 864
          If y
             Gdip_FillEllipse(G, civilBrush, x, y, 3, 14)

          If (A_Year=yearu && A_YDay=A_Index)
             Gdip_FillRectangle(G, todayBrush, x, 0, 2, 864)
          x += 2
        }
        Gdip_DeleteBrush(sunBrush)
        Gdip_DeleteBrush(civilBrush)
        Gdip_DeleteBrush(dBrush)
    } Else If (SolarYearGraphMode=2)
    {
       Sort, intervalsList, UND`n
       arrayIntervals := StrSplit(intervalsList, "`n")
       fIntervals := []
       thisIndex := fIndex := 0
       t := arrayIntervals.Count()
       minP := 2678400, maxuP := 0
       maxuP := 86400*2
       Loop, % arrayIntervals.Count()
       {
            thisIndex++
            x := arrayIntervals[thisIndex]
            thisIndex++
            y := arrayIntervals[thisIndex]
            If (thisIndex>t)
               Break

            x := SubStr(x, 1, 12) . "00"
            y := SubStr(y, 1, 12) . "00"
            p := timeSpanInSeconds(x, y)
            If !p
               Continue

            s := InStr(x, "S") ? 1 : 0
            if (p>maxuP)
               p := maxuP - 1
            ; maxuP := max(maxuP, p)
            ; minP := min(minP, p)
            findex++
            fIntervals[fIndex] := [p, s]
            fnOutputDebug(s " | " x " / " y "=" p)
            ; fnOutputDebug(p "/" s, 1)
       }

       pxd := (dayz*2)/fIntervals.Count()
       Loop, % fIntervals.Count()
       {
          If (fIntervals[A_Index, 2]=1)
             sunColor := MixARGB("0x65217744", "0xCC22eebb", graphArrayElev[A_Index])
          Else
             sunColor := MixARGB("0x65667744", "0xCCffeebb", graphArrayElev[A_Index])
          sunBrush := Gdip_BrushCreateSolid(sunColor)
          c := Round(fIntervals[A_Index, 1] / maxuP, 3)
          y := 864 - c * 864
          ; fnOutputDebug("c / y =" c " / " y " m" maxuP " i" fIntervals[A_Index, 1], 1 )
          Gdip_FillRectangle(G, sunBrush, x, y, pxd, 864)
          ; fnOutputDebug(A_Index "==" x "//" y)
          Gdip_DeleteBrush(sunBrush)
          x += pxd
       }
    } Else
    {
       Loop, % dayz
       {
          sunColor := MixARGB("0xFF001122", "0x66004433", graphArrayMoon[A_Index, 2])
          sunBrush := Gdip_BrushCreateSolid(sunColor)
          Gdip_FillRectangle(G, sunBrush, x, 0, 1, 864)
          Gdip_DeleteBrush(sunBrush)

          sunColor := MixARGB("0x65667744", "0xCCffeebb", graphArrayElev[A_Index])
          sunBrush := Gdip_BrushCreateSolid(sunColor)
          If (SolarYearGraphMode=3)
          {
             devu := (graphArrayMoon[A_Index, 1]/86400) * 864
             If (graphArrayMoon[A_Index]="-")
                devu *= -1
             ; fnOutputDebug(A_Index " devu=" devu)
          } Else devu := 0

          y := 864 - graphArrayMoon[A_Index, 1] * 864 + devu
          Gdip_FillRectangle(G, sunBrush, x, y, 2, 864)
          ; fnOutputDebug(A_Index "==" x "//" y)
          Gdip_DeleteBrush(sunBrush)
          If (A_Year=yearu && A_YDay=A_Index)
             Gdip_FillRectangle(G, todayBrush, x, 0, 2, 864)

          x += 2
       }
    }

    If (SolarYearGraphMode=3)
    {
       zbmp := Gdip_ResizeBitmap(mainBitmap, dayz*2, 432, 0, 7)
       If StrLen(zbmp)>2
       {
          Gdip_DrawImageFast(G, zbmp, 0, 0) 
          Gdip_ImageRotateFlip(zbmp, 6)
          Gdip_DrawImageFast(G, zbmp, 0, 432) 
          Gdip_DisposeImage(zbmp, 1)
       }
    }

    Gdip_DeleteGraphics(G)
    Gdip_DeleteBrush(todayBrush)
    Gdip_SetPbitmapCtrl(hSolarGraphPic, mainBitmap)
    Gdip_DisposeImage(mainBitmap, 1)
}

ToggleAstroInfosModa() {
   Static lastInvoked := 1
   If (A_TickCount - lastInvoked<250)
      Return

   lastInvoked := A_TickCount
   userAstroInfodMode := !userAstroInfodMode
   todaySunMoonGraphMode := !userAstroInfodMode
   INIaction(1, "userAstroInfodMode", "SavedSettings")
   UIcityChooser()
}

generateGraphTodaySolar(timi, lat, lon, gmtOffset) {
     If !pToken
        pToken := Gdip_Startup()
 
     If !pToken
        Return
 
     Static w := 360, h := 180
     ; to-do, transform all sizes relative to main dimensions (w, h)
     mainBitmap := Gdip_CreateBitmap(w, h)
     If !mainBitmap
        Return
 
     G := Gdip_GraphicsFromImage(mainBitmap, 7, 4)
     If !G
     {
        Gdip_DisposeImage(mainBitmap, 1)
        Return
     }
 
     clru := (todaySunMoonGraphMode=1) ? "0xff112222" : "0xff112233"
     Gdip_GraphicsClear(G, clru)
     If (todaySunMoonGraphMode=1)
     {
        moonZeit := timi   ; timi is local to the mapped place; the moon is asked in UTC
        moonZeit += -1*gmtOffset, Hours
        moonPicBMP := OSDmoonColorBitmap("224466", moonZeit)
        pPath := Gdip_CreatePath()
        Gdip_AddPathEllipse(pPath, w - 44, 11, 34, 34)
        Gdip_SetClipPath(G, pPath)
        Gdip_DrawImage(G, moonPicBMP, w - 44, 11, 34, 34)
        Gdip_DisposeImage(moonPicBMP, 1)
        Gdip_DeletePath(pPath)
        Gdip_ResetClip(G)
     }

     bu := hasDrawn := 0
     lineBrush := Gdip_BrushCreateSolid("0xAAeeEEee")

     clru := (todaySunMoonGraphMode=1) ? "0xeeEEffff" : "0xeeffee00"
     sunBrush := Gdip_BrushCreateSolid(clru)

     clru := (todaySunMoonGraphMode=1) ? "0x77AAeeff" : "0x77ffee00"
     lightBrush := Gdip_BrushCreateSolid(clru)

     twilightBrush := Gdip_BrushCreateSolid("0x88aabb88")
     darkBrush := Gdip_BrushCreateSolid("0xff001122")
     dBrush := Gdip_BrushCreateSolid("0x44aaeeaa")
     startZeit := SubStr(timi, 1, 8) . "000001"
     pu := (timeSpanInSeconds(timi, startZeit) / 86400) * 360
     If (pu<3.1)
        pu := 3.1

     If gmtOffset
        startZeit += -1*gmtOffset, Hours

     x := 3
     m := (PrefsLargeFonts=1) ? 30 : 20
     Gdip_FillRectangle(G, darkBrush, w/2, 0, 3, h)
     pPath := Gdip_CreatePath()
     hc := (PrefsLargeFonts=1) ? 10 : 8
     Loop, 48
     {
        If (todaySunMoonGraphMode=1)
           getMoonElevation(startZeit, lat, lon, 0, azii, elevu)
        Else
           getSunAzimuthElevation(startZeit, lat, lon, 0, azii, elevu)

        y := m + (h - m*2) - Round(((elevu + 90)/180) * (h - m*2), 3)
        dh := y - h/2 - 1.5, lh := h/2 - y
        If (y<h/2 && lh>0.02)
           Gdip_FillRectangle(G, lightBrush, x - 4, y, 8, lh)
        Else If (dh>0)
           Gdip_FillRectangle(G, darkBrush, x - 4, h/2, 8, dh)

        brushu := (y<h/2) ? lineBrush : dBrush
        diam := (elevu<-12.1) ? 2.5 : 3.1
        diam := (elevu<-18.5) ? 2 : diam
        If y
           Gdip_FillEllipseC(G, brushu, x, y, diam)
        If (y && isInRange(elevu, 0, -7))
           Gdip_FillEllipseC(G, brushu, x, y, 3)

        If (IsInRange(pu, x, x + 7.5) && hasDrawn!=1)
        {
           hasDrawn := 1
           Gdip_FillEllipseC(G, sunBrush, x, y, 10, hc)
           Gdip_AddPathEllipseC(pPath, x, y, 10, hc)
           Gdip_SetClipPath(G, pPath, 4)
        }

        x += 7.5
        startZeit += 30, Minutes
      }
      Gdip_FillRectangle(G, dBrush, 0, h/2, w, 3)

      ; azimuth indicator
      timeus := uiUserFullDateUTC
      If (todaySunMoonGraphMode=1)
         getMoonElevation(timeus, lat, lon, 0, azii, elevu)
      Else
         getSunAzimuthElevation(timeus, lat, lon, 0, azii, elevu)
      cardinal := defineAzimuthCardinal(azii)
      Gdip_DeletePath(pPath)
      pPath := Gdip_CreatePath()
      GdipCreateSimpleShapes(24, 9, 7.5, 32, 4, 0, pPath)
      Gdip_RotatePathAtCenter(pPath, 180)
      Gdip_RotatePathAtCenter(pPath, azii)
      Gdip_FillEllipse(G, twilightBrush, 15, 10, 30, 30)
      Gdip_FillEllipse(G, darkBrush, 17, 12, 26, 26)
      thisBrush := instr(cardinal, "north") ? lightBrush : darkBrush 
      Gdip_FillEllipse(G, thisBrush, 27, 7, 6, 6)
      thisBrush := instr(cardinal, "south") ? lightBrush : darkBrush 
      Gdip_FillEllipse(G, thisBrush, 27, 36, 6, 6)
      thisBrush := instr(cardinal, "west") ? lightBrush : darkBrush 
      Gdip_FillEllipse(G, thisBrush, 12, 22, 6, 6)
      thisBrush := instr(cardinal, "east") ? lightBrush : darkBrush 
      Gdip_FillEllipse(G, thisBrush, 42, 22, 6, 6)
      Loop, 4
          Gdip_FillPath(G, twilightBrush, pPath)

      Gdip_FillEllipse(G, darkBrush, 19, 14, 22, 22)
      Gdip_FillEllipse(G, twilightBrush, 27, 22, 6, 6)

      Gdip_DeleteBrush(sunBrush)
      Gdip_DeleteBrush(lightBrush)
      Gdip_DeleteBrush(lineBrush)
      Gdip_DeleteBrush(darkBrush)
      Gdip_DeleteBrush(twilightBrush)
      Gdip_DeleteBrush(dBrush)
      Gdip_DeletePath(pPath)

      Gdip_DeleteGraphics(G)
      Gdip_SetPbitmapCtrl(hSolarGraphPic, mainBitmap)
      Gdip_DisposeImage(mainBitmap, 1)
}

GdipCreateSimpleShapes(imgSelPx, imgSelPy, imgSelW, imgSelH, shape, roundness, pPath) {
    If (shape=1 && !roundness) ; rect
    {
       Gdip_AddPathRectangle(pPath, imgSelPx, imgSelPy, imgSelW, imgSelH)
    } Else If (shape=2 && roundness) ; rounded rect
    {
       radius := clampInRange(min(imgSelW, imgSelH)*(roundness/200) + 1, 2, min(imgSelW, imgSelH)*0.9)
       Gdip_AddPathRoundedRectangle(pPath, imgSelPx, imgSelPy, imgSelW, imgSelH, radius)
    } Else If (shape=3) ; ellipse
    {
       Gdip_AddPathEllipse(pPath, imgSelPx, imgSelPy, imgSelW, imgSelH)
    } Else If (shape=4) ; triangle
    {
       cX1 := imgSelPx + imgSelW//2
       cY1 := imgSelPy
       cX2 := imgSelPx
       cY2 := imgSelPy + imgSelH
       cX3 := imgSelPx + imgSelW
       cY3 := imgSelPy + imgSelH
       Gdip_AddPathPolygon(pPath, [cX1, cY1, cX2, cY2, cX3, cY3])
    } Else If (shape=5) ; right triangle
    {
       cX1 := imgSelPx
       cY1 := imgSelPy
       cX2 := imgSelPx
       cY2 := imgSelPy + imgSelH
       cX3 := imgSelPx + imgSelW
       cY3 := imgSelPy + imgSelH
       Gdip_AddPathPolygon(pPath, [cX1, cY1, cX2, cY2, cX3, cY3])
    } Else If (shape=6) ; rhombus
    {
       cX1 := imgSelPx + imgSelW//2
       cY1 := imgSelPy
       cX2 := imgSelPx
       cY2 := imgSelPy + imgSelH//2
       cX3 := imgSelPx + imgSelW//2
       cY3 := imgSelPy + imgSelH
       cX4 := imgSelPx + imgSelW
       cY4 := imgSelPy + imgSelH//2
       Gdip_AddPathPolygon(pPath, [cX1, cY1, cX2, cY2, cX3, cY3, cX4, cY4])
    }
}


locateClickOnEarthMap() {
    Static prevk, clicks := 0
    If !getGraphMousePos(hSolarGraphPic, px, py)
       Return

    py := 1 - py
    zx := Round(px*360 - 180)
    zy := Round(py*180 - 90)
    ; ToolTip, % zx "=" zy , , , 2

    foundy := whatever := nwhatever := nprecise := precise := 0
    Loop, % listedExtendedLocations
    {
         dx := Round(extendedGeoData[A_Index, 4])
         dy := Round(extendedGeoData[A_Index, 3])
         ; fnOutputDebug(dx "==" dy)
         If (dx=zx && dy=zy)
         {
            foundy := 1
            whatever := A_Index
            If !nwhatever
               nwhatever := A_Index
         }
    }

    If (foundy!=1)
    {
        ctr := countriesArrayList.Count()
        Loop, % ctr
        {
             ctrIndex := A_Index
             cities := geoData[A_Index "|-1"]
             Loop, % cities
             {
                 thisu := geoData[ctrIndex "|" A_Index]
                 elemu := StrSplit(thisu, "|")
                 x := Round(elemu[3]), y := Round(elemu[2])
                 If (x=zx && y=zy)
                 {
                    foundy := 1
                    whatever := ctrIndex "|" A_Index
                    If !nwhatever
                       nwhatever := ctrIndex "|" A_Index
                 }
             }
        }
    }

    k := nwhatever
    k := (prevk=k) ? whatever : nwhatever
    ; ToolTip, % k "=====" whatever "==" nwhatever , , , 2
    prevk := k
    gmtu := Round(24 * px - 12)
    If InStr(k, "|")
    {
       p := Substr(k, 1, InStr(k, "|") -  1)
       j := countriesArrayList[p]
       k := j "|" LTrim(geoData[k], "*")   ; the star marks a capital in the lists; it is no part of the name
       k := StrSplit(k, "|")
    } Else k := extendedGeoData[k]

    If IsObject(k)
    {
       stringu := k[1] ":" k[2] "|" k[3] "|" k[4] "|" k[5] "|" k[6] "|" k[7]
    } Else
    {
       clicks++
       zx := Round(px*360 - 180, 4)
       zy := Round(py*180 - 90, 4)
       stringu := "User defined N" clicks "|" zy "|" zx "|" gmtu ".0|" gmtu ".0|135"
    }

    GuiControl, SettingsGUIA:, newGeoDataLocationUserEdit, % stringu
}

MenuRenameUserLocation() {
   If !isVarEqualTo(AnyWindowOpen, 6, 7, 9)   ; the panels carrying the country and the city lists
      Return

   Gui, SettingsGUIA: Default
   GuiControlGet, uiUserCountry
   GuiControlGet, uiUserCity
   If (uiUserCountry!=1)   ; the indexed locations are not the user's to rename
      Return

   p := geoData["1|" uiUserCity]
   w := StrSplit(p, "|")
   oldName := LTrim(w[1], "*")
   If (w.Count()<6 || StrLen(oldName)<2)
   {
      simpleMsgBoxWrapper(appName, "The selected custom location is incomplete and cannot be renamed.", 0, 1, 48)
      Return
   }

   Gui, SettingsGUIA: +OwnDialogs
   InputBox, newName, % appName, % "Type the new name for this custom location:`n`n" oldName, , , , , , , , % oldName
   If ErrorLevel   ; the box was cancelled or closed
      Return

   ; the pipe parts one field of an entry from the next and the star marks a capital in the loaded
   ; index; neither may stand in a name that has to survive a trip through the list on the disk
   newName := LTrim(Trim(StrReplace(newName, "|", " ")), "* ")
   If (newName==oldName)
      Return

   If (StrLen(newName)<2)
   {
      simpleMsgBoxWrapper(appName, "Please define a name at least two characters long for the custom location.", 0, 1, 48)
      SetTimer, MenuRenameUserLocation, -250
      Return
   }

   thisIDu := geoLocationAlreadyInUserList(newName)
   If (thisIDu && thisIDu!=uiUserCity)   ; an entry may still be renamed to another casing of its own name
   {
      simpleMsgBoxWrapper(appName, "The custom locations list already contains " newName ".", 0, 1, 64)
      SetTimer, MenuRenameUserLocation, -250
      Return
   }

   strA := newName "|" w[2] "|" w[3] "|" w[4] "|" w[5] "|" w[6]
   thisIDu := btnUIupdateUserGeoLocation("Custom locations|" oldName "|", strA, "Custom locations|" strA)
   If !thisIDu
   {
      simpleMsgBoxWrapper(appName, "The custom locations list could not be updated. " oldName " was not found in the list.", 0, 1, 16)
      Return
   }

   uiSelectUserGeoLocation(thisIDu)
}

MenuDetectDeviceLocation() {
   If !isVarEqualTo(AnyWindowOpen, 6, 7, 9)   ; the panels carrying the country and the city lists
      Return

   ToolTip, Detecting device location...
   Sleep, 5
   stringu := detectThisComputerLocation(sourceu, faultu)
   ToolTip
   If !stringu
   {
      simpleMsgBoxWrapper(appName, faultu, 0, 1, 48)
      Return
   }

   idu := btnUIaddTodayGeoLocation("given", stringu)
   If !idu   ; whatever stood in the way has already been put in front of the user
      Return

   uiSelectUserGeoLocation(idu)
   If sourceu
   {
      ToolTip, % sourceu
      SetTimer, removeTooltip, -4000
   }
}

BtnDetectUserLocation() {
   Gui, SettingsGUIA: Default
   GuiControl, SettingsGUIA: Disable, btn6
   ToolTip, Detecting device location...
   Sleep, 5
   stringu := detectThisComputerLocation(sourceu, faultu)
   GuiControl, SettingsGUIA: Enable, btn6
   If !stringu
   {
      ToolTip
      simpleMsgBoxWrapper(appName, faultu, 0, 1, 48)
      Return
   }

   ToolTip
   GuiControl, SettingsGUIA:, newGeoDataLocationUserEdit, % stringu
   GuiControl, SettingsGUIA:, GraphInfoLine, % sourceu
   SoundBeep 900, 100
}

detectThisComputerLocation(ByRef sourceu, ByRef faultu) {
; Where this computer is, written the way a custom location entry is written:
;    Name|latitude|longitude|GMT offset on 1 January|GMT offset on 1 July|altitude
;
; The Windows location service is used first to identify the location.
; When the service cannot answer or is switched off, denied to desktop programs,
; or absent altogether, the fallback works from the user's Windows settings:
; Region setting, keyboard layout, OS language, and the time zone of the clock.

   sourceu := faultu := ""
   If !listedCountries
      loadGeoData()

   If WinGeoRuntimeReady()   ; on Windows 7 there is no location service to ask, so no failure worth a message stands between here and the fallback
   {
      If WinGeoPosition(latu, longu, accu, altu, faultu)
      {
         latu := Round(latu, 4)
         longu := Round(longu, 4)
         If !WinGeoTimeZoneOffsets(gmtu, dstu)   ; the offsets of the 1st of January and of the 1st of July
         {
            gmtu := Round(longu/15) ".0"   ; the same guess the map makes of a click
            dstu := gmtu
         }

         altu := (isNumber(altu) && isInRange(altu, -500, 9000)) ? Round(altu) : 0
         withinu := (isNumber(accu) && accu>0) ? ", to within " Round(accu) " m" : ""
         sourceu := "Windows places this PC at " Round(latu, 1) " / " Round(longu ,1) withinu "."
         Return "Detected location|" latu "|" longu "|" gmtu "|" dstu "|" altu
      }

      If faultu
         simpleMsgBoxWrapper(appName, "Microsoft Windows failed to detect the location of the device.`n `n"  faultu "`n`nA fallback detection method will be used." , 0, 1, 16)

      faultu := ""
   }

   If !WinGeoTimeZoneOffsets(tzJan, tzJul)
      tzJan := tzJul := ""

   hintList := [[WinGeoRegionCountry(), "the country set in the system Control Panel"]
              , [WinGeoKeyboardCountry(), "the keyboard layout"]
              , [WinGeoUILanguageCountry(), "the language of Windows"]]
   ctrIdx := cityIdx := exactu := 0
   triedu := viau := ""
   For i, hintu in hintList
   {
      isou := hintu[1]
      If (!isou || InStr(triedu, "[" isou "]"))
         Continue

      triedu .= "[" isou "]"
      If !geoNearestCityOfCountryCode(isou, tzJan, tzJul, thisCtr, thisCity, thisExact)
         Continue

      If (thisExact=1 || !ctrIdx)
      {
         ctrIdx := thisCtr, cityIdx := thisCity, viau := hintu[2], exactu := thisExact
         If (thisExact=1)   ; a country holding a city that keeps this computer's clock settles it
            Break
      }
   }

   If !ctrIdx
   {
      faultu := (triedu="") ? "Failed to detect any possible location." : "Failed to detect a location matching hint: " StrReplace(Trim(triedu, "[]"), "][", ", ") "."
      Return ""
   }

   p := geoData[ctrIdx "|" cityIdx]
   cityu := LTrim(SubStr(p, 1, InStr(p, "|") - 1), "*")
   clocku := (tzJan="") ? "" : "UTC" ((tzJan<0) ? "" : "+") tzJan "/" ((tzJul<0) ? "" : "+") tzJul
   If (clocku="")
      sourceu := cityu " was picked from " viau "."
   Else If exactu
      sourceu := cityu " was picked from " viau " and this computer's " clocku " clock."
   Else
      sourceu := cityu " was picked from " viau ", although no city listed there keeps this computer's " clocku " clock."

   k := StrSplit(countriesArrayList[ctrIdx] ":" LTrim(p, "*"), "|")   ; the very same format used by PanelEarthMap(); the star of a capital is no part of the name
   Return k[1] "|" k[2] "|" k[3] "|" k[4] "|" k[5] "|" k[6]
}

geoNearestCityOfCountryCode(isou, tzJan, tzJul, ByRef ctrIdx, ByRef cityIdx, ByRef exactu) {
; The city of the location index that best answers an ISO 3166-1 alpha-2
; country code and the clock this computer keeps - tzJan and tzJul being the
; UTC offsets in force on the 1st of January and on the 1st of July, written
; the way the index writes them, or empty when the time zone could not be
; read. Gives back 1 with the two indices filled in and exactu saying whether
; the city's clock agrees with the computer's, or 0 for a code the index has
; nothing for.
;
; The city is settled in passes, each held only among cities keeping the
; computer's clock: the capital first, so that a country of one time zone
; answers with its capital exactly as this always has; then the city the IANA
; time zone of that clock is named after, which is what places a Pacific
; machine at Los Angeles rather than at Washington; then any city of the
; country proper, and then any of its bracketed overseas dependencies - a
; Spanish machine keeping UTC+0/+1 lands on the Canary Islands this way, and
; an Australian one keeping UTC+7 on Christmas Island. When no city keeps the
; clock, the nearest clock wins, capitals ahead of the rest, and when the
; time zone is unknown the capital alone decides, which is the old behaviour.
;
; A code the index holds no country under may still name a dependency filed
; in brackets beneath its parent - (Bermuda) Hamilton stands under United
; Kingdom, (French Guiana) Cayenne under France (others) - or a city bearing
; the territory's own name, as Hong Kong does under China; both are found by
; searching the whole of the index, so such a code no longer comes back
; empty-handed as it used to.

   ctrIdx := cityIdx := exactu := 0
   nameu := geoCountryNameOfCode(isou)
   If !nameu
      Return 0

   poolu := []
   Loop, % countriesArrayList.Count()
   {
      If (countriesArrayList[A_Index]=nameu || countriesArrayList[A_Index]=nameu . " (others)")   ; France (others) is where the overseas France stands
         geoPoolCountryCities(poolu, A_Index)
   }

   If !poolu.Count()
   {
      Loop, % countriesArrayList.Count()   ; a dependency rather than a country: comb the whole index for it
      {
         c := A_Index
         Loop, % geoData[c "|-1"]
         {
            p := geoData[c "|" A_Index]
            If !p
               Continue

            k := StrSplit(p, "|")
            town := LTrim(k[1], "*")
            If (SubStr(town, 1, 1)="(")
            {
               z := InStr(town, ")")
               If (z>3 && geoTerritoryAlike(SubStr(town, 2, z - 2), nameu))
                  poolu.Push([c, A_Index, town, k[4], k[5], k[7], 1])
            } Else If WinGeoNamesAlike(town, nameu)   ; Hong Kong and Gibraltar are cities carrying their territory's name
               poolu.Push([c, A_Index, town, k[4], k[5], k[7], 1])
         }
      }
   }

   If !poolu.Count()
      Return 0

   bestu := 0
   If (tzJan!="")
   {
      For i, r in poolu   ; the capital, keeping the computer's clock
      {
         If (r[6]=1 && !r[7] && geoSameOffset(r[4], tzJan) && geoSameOffset(r[5], tzJul))
         {
            bestu := i
            Break
         }
      }

      If !bestu
      {
         tokens := geoZoneCityTokens(isou, tzJan, tzJul)
         For j, tok in tokens   ; the city the time zone is named after
         {
            For i, r in poolu
            {
               If (geoSameOffset(r[4], tzJan) && geoSameOffset(r[5], tzJul) && geoCityCalled(r[3], tok))
               {
                  bestu := i
                  Break
               }
            }
            If bestu
               Break
         }
      }

      If !bestu
      {
         For i, r in poolu   ; any city of the country proper
         {
            If (!r[7] && geoSameOffset(r[4], tzJan) && geoSameOffset(r[5], tzJul))
            {
               bestu := i
               Break
            }
         }
      }

      If !bestu
      {
         For i, r in poolu   ; any bracketed overseas dependency
         {
            If (r[7] && geoSameOffset(r[4], tzJan) && geoSameOffset(r[5], tzJul))
            {
               bestu := i
               Break
            }
         }
      }
   }

   If bestu
   {
      exactu := 1
   } Else
   {
      scoreBest := 100000
      For i, r in poolu   ; the nearest clock or, the time zone unknown, the capital ahead of the rest
      {
         scoru := (tzJan!="") ? Abs(r[4] - tzJan) + Abs(r[5] - tzJul) : 0
         scoru += ((r[6]=1) ? 0 : 0.001) + (r[7] ? 0.002 : 0)
         If (scoru<scoreBest)
         {
            scoreBest := scoru
            bestu := i
         }
      }
   }

   ctrIdx := poolu[bestu][1]
   cityIdx := poolu[bestu][2]
   Return 1
}

geoPoolCountryCities(poolu, c) {
; Every city the index files under country c, poured into the pool as
; [country index, city index, name, January offset, July offset, capital,
; bracketed] - the bracketed ones being the overseas dependencies whose names
; open on a parenthesis and which never stand in for the country proper.

   Loop, % geoData[c "|-1"]
   {
      p := geoData[c "|" A_Index]
      If !p
         Continue

      k := StrSplit(p, "|")
      town := LTrim(k[1], "*")
      poolu.Push([c, A_Index, town, k[4], k[5], k[7], (SubStr(town, 1, 1)="(") ? 1 : 0])
   }
}

geoSameOffset(a, b) {
; Whether two UTC offsets are the same clock. They are compared as numbers
; rather than text, so that 2 answers for 2.0, and anything within a minute
; of each other is the same.

   Return (b!="" && Abs(a - b)<0.02) ? 1 : 0
}

geoZoneCityTokens(isou, tzJan, tzJul) {
; The cities the IANA time zones of a country are named after, kept to the
; zones whose offsets are the two asked for: US and -8.0/-7.0 give only Los
; Angeles. Read from resources\timezones.txt, which states every zone's
; offsets on the 1st of January and on the 1st of July, the same convention
; the location index keeps. The name is what stands after the last slash,
; its underscores turned to spaces: America/Indiana/Indianapolis is
; Indianapolis.

   Static content := ""
   If (content="")
      FileRead, content, %A_ScriptDir%\resources\timezones.txt

   tokens := []
   Loop, Parse, content, `n, `r
   {
      k := StrSplit(A_LoopField, "|")
      If (k.Count()<4 || k[1]!=isou)
         Continue

      If (geoSameOffset(k[3], tzJan) && geoSameOffset(k[4], tzJul))
         tokens.Push(StrReplace(SubStr(k[2], InStr(k[2], "/", 0, 0) + 1), "_", " "))
   }
   Return tokens
}

geoCityCalled(town, tok) {
; Whether a city of the index answers to the name a time zone carries. The
; bracketed dependency a name may open on is no part of it, the comparing
; forgives case and accents - Sao Paulo answers for São Paulo - and a name
; may carry words beyond the token, New York City for New York, but never
; mere letters: Knox does not answer for Knoxville.

   If (SubStr(town, 1, 1)="(")
      town := Trim(SubStr(town, InStr(town, ")") + 1))

   If WinGeoNamesAlike(town, tok)
      Return 1

   lenu := StrLen(tok)
   If (StrLen(town)>lenu + 1 && SubStr(town, lenu + 1, 1)=" " && WinGeoNamesAlike(SubStr(town, 1, lenu), tok))
      Return 1

   Return 0
}

geoTerritoryAlike(heldu, nameu) {
; Whether the territory a bracketed city is filed under answers a country
; name: Bermuda for Bermuda outright, Bailiwick Jersey for Jersey and Saint
; Helena for Saint Helena, Ascension and Tristan da Cunha by the one name
; containing the other, with the shorter asked to carry at least five letters
; so that no scrap of a word matches.

   If WinGeoNamesAlike(heldu, nameu)
      Return 1

   Return (StrLen(heldu)>4 && StrLen(nameu)>4 && (InStr(nameu, heldu) || InStr(heldu, nameu))) ? 1 : 0
}

geoCountryNameOfCode(isou) {
; The country name resources\country-codes.txt gives for an ISO code, put right
; where the location index spells the country its own way. The index hyphenates
; the names joined by an "and", and it files the British Isles under their
; constituent countries - what stands under United Kingdom there is the overseas
; territories, whose first capital is Anguilla's rather than London. Svalbard
; and the Northern Marianas are spelled the way their bracketed cities are
; filed, so that the dependency search of geoNearestCityOfCountryCode() finds
; them.

   Static codes := 0
        , spelled := {"AG":"Antigua-Barbuda", "BA":"Bosnia-Herzegovina", "ST":"São Tomé-Principe", "TT":"Trinidad-Tobago", "GB":"England (UK)", "SJ":"Svalbard-Jan Mayen", "MP":"N. Mariana Islands"}

   If !IsObject(codes)
   {
      codes := {}
      FileRead, content, %A_ScriptDir%\resources\country-codes.txt
      Loop, Parse, content, `n, `r
      {
         p := Trim(A_LoopField, Chr(65279) . " `t")   ; a byte order mark may lead the first line
         z := InStr(p, "|")
         If (z=3)
            codes[SubStr(p, 1, 2)] := SubStr(p, z + 1)
      }
   }

   isou := Trim(isou)
   If spelled.HasKey(isou)
      Return spelled[isou]

   Return codes.HasKey(isou) ? codes[isou] : ""
}

generateSunlightEarthMap(modus) {
; The earth map with the sunlight (modus=2) or the moonlight (modus=3) at
; uiUserFullDateUTC laid over it, for PanelEarthMap(): the night side darkened and
; the day side let in over two steps. The light itself is painted by
; earthMapLightLayer(); the untouched map is then laid back over the whole at 35%
; opacity, to soften it.
    If !pToken
       pToken := Gdip_Startup()

    If !pToken
       Return

    mainBitmap := Gdip_CreateBitmapFromFileSimplified(A_ScriptDir "\resources\earth-surface-map.jpg")
    If !mainBitmap
       Return

    cbmp := Gdip_CloneBitmap(mainBitmap)
    Gdip_GetImageDimensions(mainBitmap, imgW, imgH)
    G := Gdip_GraphicsFromImage(mainBitmap, 5, 3)
    If !G
    {
       Gdip_DisposeImage(mainBitmap, 1)
       Gdip_DisposeImage(cbmp, 1)
       Return
    }

    pLight := earthMapLightLayer(modus, uiUserFullDateUTC, imgW, imgH)
    If pLight
    {
       Gdip_DrawImage(G, pLight, 0, 0, imgW, imgH)
       Gdip_DisposeImage(pLight, 1)
    }
    Gdip_DrawImage(G, cbmp, ,,,,,,,, 0.35)
    Gdip_SetPbitmapCtrl(hSolarGraphPic, mainBitmap)
    Gdip_DeleteGraphics(G)
    Gdip_DisposeImage(mainBitmap, 1)
    Gdip_DisposeImage(cbmp, 1)
}

earthMapLightLayer(modus, timeus, imgW, imgH) {
; The sunlight (modus=2) or the moonlight (modus=3) at timeus, a UTC time stamp,
; painted as a 32-ARGB bitmap of imgW by imgH - the size of the earth map that
; generateSunlightEarthMap() lays it over. Four bands of apparent elevation,
; refraction included, as the DLL reports it: the map is darkened below the lowest
; threshold and the light comes in over two steps. The thresholds are the ones the
; map has always drawn: -12° for the sun, where nautical twilight ends, and -0.5°
; for the moon, where its disk is entirely under the horizon, then 7.5° and 27° for
; both. Returns 0 when the DLL could not say where the body stands.
;
; Where the body stands over the earth is all that the time decides, so that is
; established once, and the bands are then drawn one row of pixels at a time. Along
; a parallel the elevation falls away evenly either side of the longitude the body
; stands over, so on one row each band is one interval of longitude, whose
; half-width is a single acos() away. The thresholds are first taken back to the
; geocentric elevation the acos() works in, which is what keeps the refraction, and
; the moon's parallax, without computing either for every pixel. This used to ask
; the DLL for the elevation at every second pixel - 32768 calls - and took seconds.
   If !earthMapBodySubpoint(modus, timeus, decl, lonSub, sinPar)
      Return 0

   pBitmap := Gdip_CreateBitmap(imgW, imgH)
   If !pBitmap
      Return 0

   G := Gdip_GraphicsFromImage(pBitmap)
   If !G
   {
      Gdip_DisposeImage(pBitmap, 1)
      Return 0
   }

   ; The bands are nested, each inside the one below it, and they are painted from the
   ; outermost in. With the compositing set to overwrite, each pixel is left with the
   ; one colour of its band, to be blended onto the map only once.
   Gdip_SetCompositingMode(G, 1)
   Gdip_GraphicsClear(G, "0xaa001100")
   brushes := [Gdip_BrushCreateSolid("0x33001100"), Gdip_BrushCreateSolid("0x33ffeeff"), Gdip_BrushCreateSolid("0xaaffeeff")]
   thresholds := (modus=3) ? [-0.5, 7.5, 27] : [-12, 7.5, 27]
   rad := 0.017453292519943295, deg := 57.29577951308232
   sinT := []
   Loop, 3
       sinT[A_Index] := Sin(earthMapGeoElevation(thresholds[A_Index], sinPar)*rad)

   sd := Sin(decl*rad), cd := Cos(decl*rad)
   xSub := (lonSub + 180)*imgW/360   ; the column the body stands over, fractional
   Loop, % imgH
   {
      y := A_Index - 1
      lat := (90 - (y + 0.5)*180/imgH)*rad   ; the parallel through the middle of the row
      sl := Sin(lat), cl := Cos(lat)
      Loop, 3
      {
         k := A_Index
         ; the cosine of the hour angle at which the elevation crosses this threshold
         ; along this parallel: sin(h) = sin(lat)*sin(decl) + cos(lat)*cos(decl)*cos(H)
         c := (sinT[k] - sl*sd)/(cl*cd)
         If (c>=1)    ; the body never gets this high along this parallel, let alone higher
            Break

         If (c<=-1)   ; it stays above the threshold all the way round
         {
            Gdip_FillRectangle(G, brushes[k], 0, y, imgW, 1)
            Continue
         }

         half := ACos(c)*deg*imgW/360     ; half the width of the band, in pixels
         x1 := Ceil(xSub - half - 0.5)    ; the first and the last pixel whose centre falls inside it
         x2 := Ceil(xSub + half - 0.5) - 1
         n := x2 - x1 + 1
         If (n<1)
            Break

         If (n>=imgW)
         {
            Gdip_FillRectangle(G, brushes[k], 0, y, imgW, 1)
            Continue
         }

         x1 := Mod(x1, imgW)
         If (x1<0)
            x1 += imgW

         If (x1 + n<=imgW)
         {
            Gdip_FillRectangle(G, brushes[k], x1, y, n, 1)
         } Else   ; the band runs off the right edge and comes back in on the left
         {
            Gdip_FillRectangle(G, brushes[k], x1, y, imgW - x1, 1)
            Gdip_FillRectangle(G, brushes[k], 0, y, x1 + n - imgW, 1)
         }
      }
   }

   Loop, 3
       Gdip_DeleteBrush(brushes[A_Index])
   Gdip_DeleteGraphics(G)
   Return pBitmap
}

earthMapBodySubpoint(modus, timeus, ByRef decl, ByRef lonSub, ByRef sinPar) {
; Where the sun (modus=2) or the moon (modus=3) stands over the earth at timeus, a UTC
; time stamp: the latitude right under it, which is its declination, and the longitude
; under it, both in degrees, and for the moon the sine of its horizontal parallax, 0
; for the sun. Returns 0 when the DLL does not answer.
;
; These are read back out of the DLL's own elevation function, probed at the poles and
; on the equator, rather than computed here afresh, so that the map agrees with every
; other reading in the app whatever ephemeris the DLL runs on, now or later. At a pole
; the sun stands exactly as high as its declination. The moon stands a little lower
; than that at either pole, by its parallax, and the two poles between them give away
; both the declination and the parallax. On the equator, at 0° and at 90° east, the
; two elevations are the cosine and the sine of the hour angle at Greenwich, up to a
; common factor, and that hour angle is the longitude the body stands over with the
; sign turned. The refraction the DLL adds is taken off each probe first.
   decl := lonSub := sinPar := ""
   rad := 0.017453292519943295, deg := 57.29577951308232
   If (modus=3)
   {
      If !(getMoonElevation(timeus, 90, 0, 0, azi, hN) && getMoonElevation(timeus, -90, 0, 0, azi, hS)
        && getMoonElevation(timeus, 0, 0, 0, azi, h0) && getMoonElevation(timeus, 0, 90, 0, azi, h90))
         Return 0

      ; At the poles the DLL's observer stands on the axis, 0.99664719 earth radii out,
      ; and sees the moon at atan((sin(decl) - 0.99664719*sinPar)/cos(decl)) from the
      ; north pole, and at the same with the parallax added, and upside down, from the
      ; south pole.
      a := Tan(earthMapGeoElevation(hN, 0)*rad)
      b := Tan(-earthMapGeoElevation(hS, 0)*rad)
      decl := ATan((a + b)/2)*deg
      sinPar := (b - a)*Cos(decl*rad)/2/0.99664719

      ; On the equator the observer stands one radius out and sees the moon lower than
      ; it is from the centre by the parallax in altitude, whose sine is sinPar times
      ; the sine of the zenith distance it is seen at.
      z := (90 - earthMapGeoElevation(h0, 0))*rad
      s0 := Cos(z - ASin(sinPar*Sin(z)))
      z := (90 - earthMapGeoElevation(h90, 0))*rad
      s90 := Cos(z - ASin(sinPar*Sin(z)))
   } Else
   {
      If !(getSunAzimuthElevation(timeus, 90, 0, 0, azi, hN) && getSunAzimuthElevation(timeus, 0, 0, 0, azi, h0)
        && getSunAzimuthElevation(timeus, 0, 90, 0, azi, h90))
         Return 0

      decl := earthMapGeoElevation(hN, 0)
      sinPar := 0
      s0 := Sin(earthMapGeoElevation(h0, 0)*rad)
      s90 := Sin(earthMapGeoElevation(h90, 0)*rad)
   }

   ; On the equator sin(h) = cos(decl)*cos(H), and the hour angle is 90° further on at
   ; 90° east, so s0 and s90 are cos(decl)*cos(H) and -cos(decl)*sin(H) for the hour
   ; angle H at Greenwich. The body stands over the longitude where the hour angle is
   ; nought, which is -H, brought into the half turn either side of Greenwich.
   lonSub := -atan2(-s90, s0)*deg
   lonSub := Mod(lonSub + 540, 360) - 180
   Return 1
}

earthMapApparentElevation(hGeo, sinPar) {
; The apparent elevation the DLL reports for a body that stands hGeo degrees above
; the horizon of a place as reckoned from the centre of the earth. For the moon -
; sinPar being the sine of its horizontal parallax - the observer on the surface sees
; it lower by the parallax: with the observer one earth radius out and the moon
; 1/sinPar out, the zenith distance seen is atan2(sin(z), cos(z) - sinPar) for the
; geocentric z. The refraction then lifts whatever is left. sinPar=0 is the sun, whose
; parallax the DLL does not reckon either.
   h := hGeo
   If sinPar
   {
      z := (90 - hGeo)*0.017453292519943295
      h := 90 - atan2(Sin(z), Cos(z) - sinPar)*57.29577951308232
   }
   Return h + calcRefractionDegs(h)
}

earthMapGeoElevation(hApp, sinPar) {
; The geocentric elevation at which the body is seen hApp degrees high: the inverse
; of earthMapApparentElevation(), which only ever grows with its elevation, found by
; bisection to well under a millionth of a degree.
   lo := -90, hi := 90
   Loop, 40
   {
      mid := (lo + hi)/2
      If (earthMapApparentElevation(mid, sinPar)<hApp)
         lo := mid
      Else
         hi := mid
   }
   Return (lo + hi)/2
}

calcRefractionDegs(elev) {
; Atmospheric refraction in degrees for a geometric elevation in degrees: the same two
; formulas the DLL adds to every elevation it gives back - Zimmerman (1981) below
; -0.575°, Sæmundsson (1986) from there up - and to be kept in step with
; calcRefraction() in cpp-dll\SolarCalculator.cpp, so that the DLL's answers can be
; taken back to the geometry here.
   If (elev<-0.575)
      Return -20.774/Tan(elev*0.017453292519943295)/3600
   Return 1.02/Tan((elev + 10.3/(elev + 5.11))*0.017453292519943295)/60
}

atan2(y, x) {
; The full-circle arc tangent AutoHotkey v1 lacks: the angle of the point (x, y) from
; the positive x axis, in radians, like the C function of the same name.
   If (x>0)
      Return ATan(y/x)
   If (x<0)
      Return (y<0) ? ATan(y/x) - 3.141592653589793 : ATan(y/x) + 3.141592653589793
   Return (y>0) ? 1.5707963267948966 : (y<0) ? -1.5707963267948966 : 0
}

generateEarthMap() {
   Gui, SettingsGUIA: Default
   GuiControl, SettingsGUIA:, UIastroInfoSet, Please wait, generating earth map...
   GuiControl, SettingsGUIA: Disable, showEarthSunMapModus
   GuiControl, SettingsGUIA: Disable, newGeoDataLocationUserEdit
   Loop, 6
       GuiControl, SettingsGUIA: Disable, btn%A_Index%

   generatingEarthMapNow := 1
   If (showEarthSunMapModus>1)
      generateSunlightEarthMap(showEarthSunMapModus)
   Else
      citiesGenerateEarthMap()

   generatingEarthMapNow := 0
   ctr := countriesArrayList.Count()
   GuiControl, SettingsGUIA: Enable, showEarthSunMapModus
   actu := (showEarthSunMapModus>1) ? "SettingsGUIA: Enable" : "SettingsGUIA: Disable"
   GuiControl, % actu, btn1
   GuiControl, % actu, btn2
   GuiControl, % actu, btn5
   GuiControl, SettingsGUIA: Enable, btn3
   GuiControl, SettingsGUIA: Enable, btn4
   GuiControl, SettingsGUIA: Enable, btn6
   GuiControl, SettingsGUIA: Enable, newGeoDataLocationUserEdit
   FormatTime, brr, % uiUserFullDateUTC, yyyy/MM/dd, HH:mm
   p := geoData.Count()- countriesArrayList.Count() + listedExtendedLocations
   If (showEarthSunMapModus=1)
      GuiControl, SettingsGUIA:, UIastroInfoSet, Countries: %ctr%. Cities: %p%.
   Else
      GuiControl, SettingsGUIA:, UIastroInfoSet, % brr ". Indexed locations: " p "."
   Sleep, 2
   GuiControl, SettingsGUIA:Focus, showEarthSunMapModus
}

citiesGenerateEarthMap() {
    If !pToken
       pToken := Gdip_Startup()

    If !pToken
       Return

    wasCached := 1
    ctr := countriesArrayList.Count()
    cached := A_ScriptDir "\resources\earth-surface-map-cached-countries-" ctr "-" listedExtendedLocations ".jpg"
    If FileExist(cached)
       mainBitmap := Gdip_CreateBitmapFromFileSimplified(cached)

    If !mainBitmap
    {
       mainBitmap := Gdip_CreateBitmapFromFileSimplified(A_ScriptDir "\resources\earth-surface-map.jpg")
       wasCached := 0
    }

    If !mainBitmap
    {
       fnOutputDebug(gdiplasterror "==" mainBitmap)
       Return
    }

    Gdip_GetImageDimensions(mainBitmap, imgW, imgH)
    G := Gdip_GraphicsFromImage(mainBitmap)
    If !G
    {
       Gdip_DisposeImage(mainBitmap, 1)
       Return
    }

    x := 0
    dotBrush := Gdip_BrushCreateSolid("0xAA88ff66")
    broBrush := Gdip_BrushCreateSolid("0xddffee00")
    bgrBrush := Gdip_BrushCreateSolid("0x99001100")
    If (wasCached=0)
    {
        Gdip_FillRectangle(G, bgrBrush, 0, 0, imgW, imgH)
        mm := new hashtable()
        Loop, % listedExtendedLocations
        {
             dx := extendedGeoData[A_Index, 4] + 180
             dy := extendedGeoData[A_Index, 3] + 90
             x := (dx/360)*imgW
             y := ImgH - (dy/180)*imgH
             testu := Round(x,1) . Round(y,1)
             If (mm[testu]!=1)
             {
                Gdip_FillEllipseC(G, dotBrush, x, y, 1.5)
                mm[testu] := 1
             }
        }

        Loop, % ctr
        {
             ctrIndex := A_Index
             cities := geoData[A_Index "|-1"]
             Loop, % cities
             {
                 thisu := geoData[ctrIndex "|" A_Index]
                 elemu := StrSplit(thisu, "|")
                 dx := elemu[3] + 180
                 x := (dx/360)*imgW
                 dy := elemu[2] + 90
                 y := ImgH - (dy/180)*imgH
                 ; fnOutputDebug(dx "==" x "|" dy "==" y)
                 testu := Round(x) . Round(y)
                 If (mm[testu]!=1)
                 {
                    Gdip_FillEllipseC(G, broBrush, x, y, 1.5)
                    mm[testu] := 1
                 }
             }
        }

        Gdip_SaveBitmapToFile(mainBitmap, cached, 95)
    }

    mm := ""
    Gdip_SetPbitmapCtrl(hSolarGraphPic, mainBitmap)
    Gdip_DeleteGraphics(G)
    Gdip_DeleteBrush(bgrBrush)
    Gdip_DeleteBrush(dotBrush)
    Gdip_DeleteBrush(broBrush)
    Gdip_DisposeImage(mainBitmap, 1)
}

decideJijiReadable(timeus, elevu, lat, lon, noonu:="a") {
   dtimi := timeus 
   dtimi += 1, Hours
   getSunAzimuthElevation(dtimi, lat, lon, 0, azii, delev)
   zd := (delev>elevu) ? "Dawn" : "Dusk"
   zdu := (delev>elevu) ? "Sunrise" : "Sunset"

   ; the bands below are tested in order and inclusive at both ends, so each one has to pick
   ; up where the one that claimed the boundary left off; the sunrise band used to start at
   ; -0.61 while the civil twilight ended at -0.611, and the sliver left between the two fell
   ; all the way through the chain to «Night», in the middle of the brightest moment of dawn
   If (isInRange(elevu, -6.1, -0.611))
      j := "Civil twilight. " zd
   Else If (isInRange(elevu, -12, -6.1))
      j := "Nautical twilight. " zd
   Else If (isInRange(elevu, -17.9, -12))
      j := "Astronomical twilight. " zd
   Else If (isInRange(elevu, 0.15, -0.611))
      j := "Daylight. " zdu
   Else If (isInRange(elevu, -0.61, 5.9))
      j := "Daylight. Warm sunlight"
   Else If (elevu>5.9)
      j := "Daylight"
   Else
      j := "Night"

   If (isInRange(elevu, noonu - 0.35, noonu + 0.35) && isNumber(noonu))
      j .= ". Solar noon"
   Return j
}

extractGeoLocationInfos(p) {
  w := StrSplit(p, "|")
  If (allowDSTchanges!=1)
     w[5] := w[4]
  Return w
}

UItodayPanelNoDateInfos(NextYear) {
; The year and the day of the panel have nothing to show for a date the system cannot format.
   ; GuiControl, SettingsGUIA:, UIastroInfoProgressMoon, % "New {" CalcTextHorizPrev(1, 1009, 0, 24) "} Full"
   GuiControl, SettingsGUIA:, UIastroInfoProgressAnnum, % "|" CalcTextHorizPrev(1, 366) "| " NextYear
   GuiControl, SettingsGUIA:, UIastroInfoProgressDayu, % "|" CalcTextHorizPrev(1, 1442, 0, 25) "| 24h "
   ; GuiControl, SettingsGUIA:, UIastroInfoMphase, ---
   ; GuiControl, SettingsGUIA:, UIastroInfoMoon, ---
   GuiControl, SettingsGUIA:, UIastroInfoAnnum, ---
   GuiControl, SettingsGUIA:, UIastroInfoDayu, ---
   GuiControl, SettingsGUIA:, UIastroInfoTotalLight, ---
   GuiControl, SettingsGUIA:, UIastroInfoTotalDiffLight, ---
}

nextMoonPhaseZeit(timeUTC, ByRef phaseName) {
; The UTC time stamp, to the minute, of the next new or full moon - whichever comes first -
; after the minute that timeUTC falls in; blank where there is no DLL to ask. phaseName is
; handed which of the two it is. Chapter 49 of Meeus places the principal phases within a few
; seconds of where they are, so there is nothing to search for: the DLL is asked outright.
;
; A phase falling inside that very minute does not count as «next». When the panel jumps to
; a phase it lands on it to the minute, and from there the phase to be named next is the one
; after it; this is what lets a click on «Next phase» walk from phase to phase.
   phaseName := ""
   If (StrLen(timeUTC)!=14)
      Return ""

   FormatTime, testValid, % timeUTC, yyyy/MM/dd
   If !testValid
      Return ""

   fromZeit := SubStr(timeUTC, 1, 12) "59"   ; the last second of the minute in hand
   If !getNextMoonPhases(fromZeit, toNew, toFirstQ, toFull, toLastQ)
      Return ""

   ; only these two are named on this panel, as the New-to-Full bar beside it implies;
   ; the quarters come back from the DLL just the same, should they be wanted here
   If (toNew<toFull)
   {
      secsu := toNew
      phaseName := "New moon"
   } Else
   {
      secsu := toFull
      phaseName := "Full moon"
   }

   ; the DLL counts from the moment it was asked about; the half minute on the end and the
   ; seconds cut off afterwards leave the stamp on the nearer of the two minutes
   zeit := fromZeit
   zeit += Round(secsu + 30), Seconds
   Return SubStr(zeit, 1, 12) "00"
}

findNextMoonPhaseZeit(timeUTC, gmtOffset, ByRef phaseName) {
; When the next new or full moon falls, written the way the panel shows it: in the local time
; of the place, to the minute. The instant itself is settled by nextMoonPhaseZeit(), which is
; also what a click on the «Next phase» label jumps the panel to.
   zeit := nextMoonPhaseZeit(timeUTC, phaseName)
   If !zeit
      Return ""

   ; the shift into local time is made in seconds, for the sake of the half hour time zones
   zeit += Round(gmtOffset*3600), Seconds
   FormatTime, hitZeit, % zeit, MM/dd HH:mm
   Return hitZeit
}

UIcityChooser() {
  Static lastSavedGeoState := ""
  If (AnyWindowOpen!=6)
     Return

  Gui, SettingsGUIA: Default
  GuiControlGet, uiUserCountry
  GuiControlGet, uiUserCity
  GuiControlGet, uiUserFullDateUTC
  ; ToolTip, % uiUserCountry "|" uiUserCity , , , 2
  p := geoData[uiUserCountry "|" uiUserCity]
  If (uiUserCountry=1)
  {
     GuiControl, SettingsGUIA: Hide, UIbtnAddGeoLoc
     GuiControl, SettingsGUIA: Enable, UIbtnRemGeoLoc
     GuiControl, SettingsGUIA: Show, UIbtnRemGeoLoc
  } Else
  {
     GuiControl, SettingsGUIA: Hide, UIbtnRemGeoLoc
     If (!p || geoLocationAlreadyInUserList(nameGeoLocation2add(uiUserCountry, p)))
        GuiControl, SettingsGUIA: Disable, UIbtnAddGeoLoc
     Else
        GuiControl, SettingsGUIA: Enable, UIbtnAddGeoLoc
     GuiControl, SettingsGUIA: Show, UIbtnAddGeoLoc
  }

  w := extractGeoLocationInfos(p)
  timeus := uiUserFullDateUTC
  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
  dstInfo := buildDSTinfo(k, w[4], w[5])
  timi := timeus
  timi += gmtOffset, Hours
  FormatTime, brr, % timi, yyyy/MM/dd HH:mm
  FormatTime, testValid, % timeus, yyyy/MM/dd
  brr := SubStr(brr, 6)
  If !brr
     brr := "--:--"

  astralObj := (userAstroInfodMode=1) ? "Sun" : "Moon"
  GuiControl, SettingsGUIA:, BtnAstroModa, % astralObj
  ; astralObj := (userAstroInfodMode=1) ? "Sun" : "Moon"
  If testValid
  {
     If (userAstroInfodMode=1)
     {
        getSunAzimuthElevation(timeus, w[2], w[3], 0, azii, elevu)
     } Else
     {
        moonPhase := MoonPhaseCalculator(timeus, 0, w[2], w[3])
        azii := moonPhase[6], elevu := moonPhase[7]
     }

     generateGraphTodaySolar(timi, w[2], w[3], gmtOffset)
  }

  eleva := isNumber(elevu) ? Round(elevu, 1) "°" : "--"
  azimu := isNumber(azii) ? Round(azii, 1) "°" : "--"
  thisu := (w[7]=1) ? "Capital. " : ""
  thisu .= "Lat / long: " Round(w[2], 3) " / " Round(w[3], 3) ". Elevation: " w[6] " meters."
  GuiControl, SettingsGUIA:, uiInfoGeoData, % thisu

  j := (gmtOffset>=0) ? "+" : ""
  GuiControl, SettingsGUIA:, UIastroInfoLtimeGMT, % "GMT " j Round(gmtOffset, 1) " h"
  GuiControl, SettingsGUIA:, UIastroInfoLtimeus, % brr
  GuiControl, SettingsGUIA:, UIastroInfoObjElev, % "Alt " eleva " / Az " azimu

  CurrentYear := testValid ? SubStr(timi, 1, 4) : yearu
  NextYear := CurrentYear + 1
  ; the dawn and the dusk hand their two controls over to the moon's fraction and age, so
  ; the tint the sun puts on them whenever a twilight had to be substituted has to be undone
  ; by whichever of the two branches runs next
  baseClr := (uiDarkMode=1) ? "+c" darkControlColor : "-c"
  If (userAstroInfodMode=1)
  {
      If testValid
      {
         obj := wrapCalcSunInfos(timeus, w[2], w[3], gmtOffset, w[6], 0, dstInfo)
         prevtimi := timeus
         prevtimi += -1, Days
         FormatTime, gyud, % prevtimi, Yday
         prevgmtOffset := pickSeasonalGmtOffset(gyud, k, w[4], w[5])
         prevobj := wrapCalcSunInfos(prevtimi, w[2], w[3], prevgmtOffset, w[6], 0, dstInfo)
         prevTduru := Round(prevobj.cdurRaw + prevobj.durRaw)
         thisTduru := Round(obj.cdurRaw + obj.durRaw)
         If InStr(obj.dur, "00:00")
            diffuZeit := prevobj.cdurRaw - obj.cdurRaw
         Else
            diffuZeit := prevobj.durRaw - obj.durRaw

         diffuZeit := clampInRange(diffuZeit, -86400, 86400)
         diffuTotalZeit := clampInRange(prevTduru - thisTduru, -86400, 86400)
         ; ToolTip, % diffuZeit "==" diffuTotalZeit , , , 2
         diffuZeit := transformSecondsReadable(abs(diffuZeit), 2)
         diffuTotalZeit := transformSecondsReadable(abs(diffuTotalZeit), 2)
         If (diffuTotalZeit!="00:00" && diffuTotalZeit!="0s" && diffuTotalZeit)
            diffuTotalZeit := (prevTduru>thisTduru) ? "-" diffuTotalZeit : "+" diffuTotalZeit
         Else
            diffuTotalZeit := ""

         If (diffuZeit!="00:00" && diffuZeit!="0s")
         {
            If InStr(obj.dur, "00:00")
            {
               ; diffuZeit := (prevobj.cdurRaw>obj.cdurRaw) ? "-" diffuZeit : "+" diffuZeit
               diffuZeit := Trim(diffuTotalZeit, " ()")
               diffuTotalZeit := ""
            } Else
               diffuZeit := (prevobj.durRaw>obj.durRaw) ? "-" diffuZeit : "+" diffuZeit
         }
      }

      pnu := (obj.elev!="") ? Round(obj.elev, 2) : "n"
      GuiControl, SettingsGUIA:, UIastroInfoObjInfo, % decideJijiReadable(timeus, elevu, w[2], w[3], pnu) "."
      GuiControl, SettingsGUIA:, UIastroInfoRise, % SubStr(obj.r, 6) ? SubStr(obj.r, 6) : "--:--"
      GuiControl, SettingsGUIA:, UIastroInfoSet, % SubStr(obj.s, 6) ? SubStr(obj.s, 6) : "--:--"
      GuiControl, SettingsGUIA:, UIastroInfoNoon, % SubStr(obj.n, 6) ? SubStr(obj.n, 6) : "--:--"
      GuiControl, SettingsGUIA:, UIastroInfoElevNoon, % SubStr(obj.n, 6) ? "Noon: " Round(obj.elev, 1) "°" : "Noon:"
      GuiControl, SettingsGUIA:, UIastroInfoDawn, % SubStr(obj.twR, 6) ? SubStr(obj.twR, 6) : "--:--"
      GuiControl, SettingsGUIA:, UIastroInfoDusk, % SubStr(obj.twS, 6) ? SubStr(obj.twS, 6) : "--:--"
      GuiControl, SettingsGUIA:, UIastroInfoDaylight, % obj.dur ? obj.dur : "--:--"
      GuiControl, SettingsGUIA:, UIastroInfoLightDiff, % (diffuZeit && diffuZeit!="0s") ? diffuZeit : "--"
      GuiControl, SettingsGUIA:, UIastroInfoLabelRise, Rise: 0°
      GuiControl, SettingsGUIA:, UIastroInfoLabelSetu, Set: 0°
      daLabel := (obj.Dawn=2) ? "Twilight:" : "Dawn: -6°"
      duLabel := (obj.Dusk=2) ? "Twilight:" : "Dusk: -6°"
      clr1 := (obj.Dawn=2) ? "+c998899" : baseClr
      clr2 := (obj.Dusk=2) ? "+c998899" : baseClr
      GuiControl, SettingsGUIA: %clr1%, UIastroInfoDawn
      GuiControl, SettingsGUIA: %clr2%, UIastroInfoDusk
      GuiControl, SettingsGUIA:, UIastroInfoLabelDawn, % daLabel
      GuiControl, SettingsGUIA:, UIastroInfoLabelDusk, % duLabel
      GuiControl, SettingsGUIA: +Redraw, UIastroInfoDawn
      GuiControl, SettingsGUIA: +Redraw, UIastroInfoDusk

      If InStr(obj.dur, "00:00")
      {
         GuiControl, SettingsGUIA:, UIastroInfoDaylight, % obj.cdur ? obj.cdur : "--:--"
         GuiControl, SettingsGUIA:, uiastroinfoLightMode, Civil twilight:
      } Else
         GuiControl, SettingsGUIA:, uiastroinfoLightMode, Sunlight:

      ; the moon leaves «Next phase:» behind in this label, so it has to be reclaimed before
      ; the bail-out below and not after it
      GuiControl, SettingsGUIA:, UIastroInfoLabelTotalLight, Total light:
      If !testValid
      {
         UItodayPanelNoDateInfos(NextYear)
         Return
      }

      totalu := clampInRange(obj.durRaw + obj.cdurRaw, -86400, 86400)
      totalu := transformSecondsReadable(totalu)
      GuiControl, SettingsGUIA:, UIastroInfoTotalLight, % totalu
      GuiControl, SettingsGUIA:, UIastroInfoTotalDiffLight, % diffuTotalZeit ? diffuTotalZeit : "--"
  } Else
  {
      If !testValid
      {
         GuiControl, SettingsGUIA:, UIastroInfoLabelRise, Rise: 0°
         GuiControl, SettingsGUIA:, UIastroInfoLabelSetu, Set: 0°
         GuiControl, SettingsGUIA:, UIastroInfoElevNoon, Peak:
         GuiControl, SettingsGUIA:, UIastroInfoRise, --:--
         GuiControl, SettingsGUIA:, UIastroInfoNoon, --:--
         GuiControl, SettingsGUIA:, UIastroInfoSet, --:--
         GuiControl, SettingsGUIA:, UIastroInfoLabelDawn, Fraction:
         GuiControl, SettingsGUIA:, UIastroInfoLabelDusk, Age:
         GuiControl, SettingsGUIA: %baseClr%, UIastroInfoDawn
         GuiControl, SettingsGUIA: %baseClr%, UIastroInfoDusk
         GuiControl, SettingsGUIA:, UIastroInfoDawn, --
         GuiControl, SettingsGUIA:, UIastroInfoDusk, --
         GuiControl, SettingsGUIA: +Redraw, UIastroInfoDawn
         GuiControl, SettingsGUIA: +Redraw, UIastroInfoDusk
         GuiControl, SettingsGUIA:, UIastroInfoObjInfo, ---
         GuiControl, SettingsGUIA:, UIastroInfoDaylight, --:--
         GuiControl, SettingsGUIA:, UIastroInfoLightDiff, --
         GuiControl, SettingsGUIA:, uiastroinfoLightMode, Moonlight:
         GuiControl, SettingsGUIA:, UIastroInfoLabelTotalLight, Next phase:
         UItodayPanelNoDateInfos(NextYear)
         Return
      }

      prevtimi := timeus
      prevtimi += -1, Days
      FormatTime, gyud, % prevtimi, Yday
      prevgmtOffset := pickSeasonalGmtOffset(gyud, k, w[4], w[5])
      prevobj := wrapCalcMoonRiseSet(prevtimi, w[2], w[3], prevgmtOffset, w[6])
      prevtimi := timi
      prevtimi += -1, Days
      prevminant := getMoonNoonZeit(SubStr(prevtimi, 1, 8) "000105", w[2], w[3], prevgmtOffset, 1)
      prevdur := coreCalculateLightDuration(prevminant, prevobj.r, prevobj.s, prevobj.RawR, prevobj.RawS, prevobj.yref, prevobj.ref, prevobj.tref, prevobj.trz, "Moon")
      coolminant := getMoonNoonZeit(SubStr(timi, 1, 8) "000105", w[2], w[3], gmtOffset, 1)

      mobj := wrapCalcMoonRiseSet(timeus, w[2], w[3], gmtOffset, w[6])
      duration := coreCalculateLightDuration(coolminant, mobj.r, mobj.s, mobj.RawR, mobj.RawS, mobj.yref, mobj.ref, mobj.tref, mobj.trz, "Moon")

      moonPhaseC := Round(moonPhase[3] * 100, 1)
      au := SubStr(mobj.r, 6) ? SubStr(mobj.r, 6) : "--:--"
      sau := SubStr(mobj.s, 6) ? SubStr(mobj.s, 6) : "--:--"
      mduru := duration[1] ? duration[1] : "--:--"
      ; moonu := mobj.v ". Rises: " au ". Sets: " sau ". " mobj.dur
      ; oldmoonPhase := oldMoonPhaseCalculator(timeus)
      ; fnOutputDebug("o=" Round(oldmoonPhase[4],3) " | n=" Round(moonPhase[4],3))
      moonPhaseN := moonPhase[1]
      moonPhaseL := Round(moonPhase[4] * 100, 1)
      moonPhaseA := Round(moonPhase[5], 1)
      noonLabel := SubStr(coolminant.n, 6) ? "Peak: " Round(coolminant.maxu, 1) "°" : "Peak:"
      noonValue := SubStr(coolminant.n, 6) ? SubStr(coolminant.n, 6) : "--:--"
      ; GuiControl, SettingsGUIA:, UIastroInfoProgressMoon, % "New {" CalcTextHorizPrev(Round(moonPhase[4] * 1000), 1009, 0, 24) "} Full"
      ; the azimuths come from the DLL, which found them at the very moment of each event;
      ; RawR/RawS still carry their 0/1 «nothing found» markers where there was no event, and
      ; then no azimuth is printed - asking the moon's position anew for such a marker used to
      ; put the azimuth of the present moment next to a «--:--»
      rizeAzim := (StrLen(mobj.RawR)=14 && mobj.riseAz!="") ? ": " Round(mobj.riseAz) "°" : ":"
      setAzim := (StrLen(mobj.RawS)=14 && mobj.setAz!="") ? ": " Round(mobj.setAz) "°" : ":"
      if (mobj.reverse=1)
      {
         If (coolminant.RawN<mobj.RawS)
         {
            GuiControl, SettingsGUIA:, UIastroInfoLabelSetu, Rise%rizeAzim%
            GuiControl, SettingsGUIA:, UIastroInfoSet, % au
            GuiControl, SettingsGUIA:, UIastroInfoLabelRise, % noonLabel
            GuiControl, SettingsGUIA:, UIastroInfoRise, % noonValue
            GuiControl, SettingsGUIA:, UIastroInfoElevNoon, Set%setAzim%
            GuiControl, SettingsGUIA:, UIastroInfoNoon, % sau
         } Else
         {
            GuiControl, SettingsGUIA:, UIastroInfoSet, % noonValue
            GuiControl, SettingsGUIA:, UIastroInfoLabelSetu, % noonLabel
            GuiControl, SettingsGUIA:, UIastroInfoRise, % sau
            GuiControl, SettingsGUIA:, UIastroInfoNoon, % au
            GuiControl, SettingsGUIA:, UIastroInfoLabelRise, Set%setAzim%
            GuiControl, SettingsGUIA:, UIastroInfoElevNoon, Rise%rizeAzim%
         }
      } Else
      {
         GuiControl, SettingsGUIA:, UIastroInfoNoon, % noonValue
         GuiControl, SettingsGUIA:, UIastroInfoElevNoon, % noonLabel
         GuiControl, SettingsGUIA:, UIastroInfoLabelRise, Rise%rizeAzim%
         GuiControl, SettingsGUIA:, UIastroInfoLabelSetu, Set%setAzim%
         GuiControl, SettingsGUIA:, UIastroInfoRise, % au
         GuiControl, SettingsGUIA:, UIastroInfoSet, % sau
      }
      GuiControl, SettingsGUIA:, UIastroInfoLabelTotalLight, Next phase:
      GuiControl, SettingsGUIA:, UIastroInfoObjInfo, %moonPhaseN%
      GuiControl, SettingsGUIA:, UIastroInfoLabelDusk, Age: %moonPhaseC%`%
      GuiControl, SettingsGUIA:, UIastroInfoDusk, %moonPhaseA%d
      GuiControl, SettingsGUIA:, UIastroInfoLabelDawn, Fraction:
      GuiControl, SettingsGUIA:, UIastroInfoDawn, %moonPhaseL%`%
      ; these two controls are the sun's dawn and dusk, which tints them whenever a twilight
      ; had to be substituted; the fraction and the age of the moon are no such thing
      GuiControl, SettingsGUIA: %baseClr%, UIastroInfoDawn
      GuiControl, SettingsGUIA: %baseClr%, UIastroInfoDusk
      GuiControl, SettingsGUIA: +Redraw, UIastroInfoDawn
      GuiControl, SettingsGUIA: +Redraw, UIastroInfoDusk
      GuiControl, SettingsGUIA:, UIastroInfoDaylight, % mduru
      GuiControl, SettingsGUIA:, uiastroinfoLightMode, Moonlight:

      diffuZeit := clampInRange(prevdur[2] - duration[2], -86400, 86400)
      diffuZeit := transformSecondsReadable(abs(diffuZeit), 2)
      ; two days of equal moonlight - a run of them is the rule at high latitudes - leave no
      ; difference to sign; the sun says «--» there and so must the moon, never «-0s»
      If (diffuZeit!="00:00" && diffuZeit!="0s" && diffuZeit)
         diffuZeit := (prevdur[2]<duration[2]) ? "+" diffuZeit : "-" diffuZeit
      Else
         diffuZeit := ""

      GuiControl, SettingsGUIA:, UIastroInfoLightDiff, % diffuZeit ? diffuZeit : "--"

      nextPhaseZeit := findNextMoonPhaseZeit(uiUserFullDateUTC, gmtOffset, nextPhaseName)
      pu := nextPhaseZeit ? nextPhaseZeit : "--"
      GuiControl, SettingsGUIA:, UIastroInfoTotalLight, % pu
      pu := nextPhaseZeit ? nextPhaseName : "-"
      GuiControl, SettingsGUIA:, UIastroInfoTotalDiffLight, % pu
       ; GuiControl, SettingsGUIA:, UIastroInfoMoonZodia, % moonZ
  }

  CurrentDateTime := timi
  CurrentDay := SubStr(CurrentDateTime, 1, 8)
  FirstMinOfDay := CurrentDay "000000"
  ; ToolTip, % CurrentDateTime "`n" FirstMinOfDay , , , 2
  EnvSub, CurrentDateTime, %FirstMinOfDay%, Minutes
  minsPassed := CurrentDateTime + 1    ; the minute of the day being lived, from 1 to 1440
  strA := w[1] "|" w[2] "|" w[3] "|" w[4] "|" w[5] "|" w[6]

  FormatTime, brrYD, % timi, YDay
  ylength := isLeapYear(CurrentYear) ? 527040 : 525600   ; minutes in the year
  percentileYear := clampInRange(Round(((brrYD - 1)*1440 + minsPassed)/ylength*100, 1), 0, 99.9) "%"
  daysPlural := (brrYD>1) ? "days" : "day"
  percentileDay := Round((minsPassed/1440) * 100, 1) "%"
  GuiControl, SettingsGUIA:, UIastroInfoAnnum, %brrYD% %daysPlural% (%percentileYear%) of %CurrentYear% ; %daysPlural2% elapsed.
  GuiControl, SettingsGUIA:, UIastroInfoDayu, %minsPassed% minutes (%percentileDay%) of today ; have elapsed.
  GuiControl, SettingsGUIA:, UIastroInfoProgressAnnum, % "|" CalcTextHorizPrev(brrYD, 366) "| " NextYear
  GuiControl, SettingsGUIA:, UIastroInfoProgressDayu, % "|" CalcTextHorizPrev(minsPassed, 1442, 0, 25) "| 24h "
  lastUsedGeoLocation := countriesArrayList[uiUserCountry] . ":" . strA
  thisGeoState := uiUserCountry "|" uiUserCity "|" lastUsedGeoLocation
  If (thisGeoState!=lastSavedGeoState)
  {
     lastSavedGeoState := thisGeoState
     INIaction(1, "uiUserCountry", "SavedSettings")
     INIaction(1, "uiUserCity", "SavedSettings")
     INIaction(1, "lastUsedGeoLocation", "SavedSettings")
  }
  lastTodayPanelZeitUpdate := A_Mon A_Hour A_Min
}

UIcountryChooser() {
   If (AnyWindowOpen!=6)
      Return

   Gui, SettingsGUIA: Default
   GuiControlGet, uiUserCountry
   listu := getCitiesList(uiUserCountry)
   GuiControl, SettingsGUIA:, uiUserCity, % "|" listu
   GuiControl, SettingsGUIA: Choose, uiUserCity, 1
   UIcityChooser()
}

UIcountryGraphChooser() {
   Gui, SettingsGUIA: Default
   GuiControlGet, uiUserCountry
   listu := getCitiesList(uiUserCountry)
   GuiControl, SettingsGUIA:, uiUserCity, % "|" listu
   GuiControl, SettingsGUIA: Choose, uiUserCity, 1
   UIcityGraphChooser()
}

UIcityGraphChooser() {
  Gui, SettingsGUIA: Default
  GuiControlGet, uiUserCountry
  GuiControlGet, uiUserCity

  p := geoData[uiUserCountry "|" uiUserCity]
  w := extractGeoLocationInfos(p)
  INIaction(1, "uiUserCountry", "SavedSettings")
  INIaction(1, "uiUserCity", "SavedSettings")
  strA := w[1] "|" w[2] "|" w[3] "|" w[4] "|" w[5] "|" w[6]
  lastUsedGeoLocation := countriesArrayList[uiUserCountry] ":" strA
  INIaction(1, "lastUsedGeoLocation", "SavedSettings")
  If (uiUserCountry=1)
     GuiControl, SettingsGUIA: Enable, UIbtnRemGeoLoc
  Else
     GuiControl, SettingsGUIA: Disable, UIbtnRemGeoLoc

  If (AnyWindowOpen=9)
     uiPopulateTableYearMoonData()
  Else
     uiPopulateTableYearSolarData()
}

getCitiesList(whichCountry) {
   listu := ""
   counter := geoData[whichCountry "|-1"]
   Loop, % counter
   {
      p := geoData[whichCountry "|" A_Index]
      If p
         listu .= SubStr(p, 1, InStr(p, "|") - 1) "|"
   }

   ; ToolTip, % counter "|" listu , , , 2
   listu := Trim(listu, "|")
   Return listu
}

BtnToggleYearGraphMode() {
   SolarYearGraphMode := !SolarYearGraphMode
   ; SolarYearGraphMode++
   ; If (SolarYearGraphMode>2)
   ;    SolarYearGraphMode := 0

   INIaction(1, "SolarYearGraphMode", "SavedSettings")
   If (AnyWindowOpen=9)
      uiPopulateTableYearMoonData()
   Else
      uiPopulateTableYearSolarData()
}

helpPanelTodayTotalLight() {
; The click on the «Total light» controls of the Today panel. With the sun on the panel they
; explain themselves; with the moon on it they read «Next phase» and name the next new or
; full moon, and the click takes the panel there.
  mouseTurnOFFtooltip()
  If (userAstroInfodMode!=1)
  {
     UItodayPanelJumpNextMoonPhase()
     Return
  }

  mouseCreateOSDinfoLine("Total light is sunlight plus civil twilight")
  ; SetTimer, removeTooltip, -2000
}

UItodayPanelJumpNextMoonPhase() {
; Moves the panel onto the next new or full moon, the one named next to «Next phase». It is
; the phase after the minute the panel is on - the very one the label names - so that every
; click walks on to the phase that follows.
  If (AnyWindowOpen!=6 || A_PtrSize!=8)
     Return

  Gui, SettingsGUIA: Default
  GuiControlGet, uiUserFullDateUTC
  p := nextMoonPhaseZeit(uiUserFullDateUTC, phaseName)
  UItodayPanelJumpTo(p, 0)   ; the stamp is already in UTC, there is nothing to shift
}

helpTodayElevationNow() {
  ; msgu := "INFO: The azimuth angle describes the angle between the north and the " astralObj " projected on the imaginary horizontal plane we are standing on, as observers.`n`nThe elevation is the angular distance between the aforementioned imaginary horizontal plane, and the " astralObj " in the sky. When the " astralObj " rises or sets, it is low in the sky, near the horizon line, which is at 0°. Solar noon is when the elevation angle is at its highest during the day.`n`nBoth angles are relative to our position on the planet."
  mouseTurnOFFtooltip()
  thisu := toggleTodayGraphMODE("quickie")
  ; thisu := msgu "Click on the graph found in the bottom left corner`nfor details about the moon and the sun positions."
  ; Gui, SettingsGUIA: +OwnDialogs
  mouseCreateOSDinfoLine(thisu)
  ; MsgBox, , % appName, % thisu
}

helpPanelTodayNoon() {
  Gui, SettingsGUIA: Default
  GuiControlGet, UIastroInfoElevNoon
  mouseTurnOFFtooltip()
  If (userAstroInfodMode=1)
     mouseCreateOSDinfoLine("Sun's altitude at solar noon, at the meridian passage.")
  Else If InStr(UIastroInfoElevNoon, "peak")
     mouseCreateOSDinfoLine("The meridian passage (the culminant of the moon).`nIt is the peak altitude of the moon on the sky during the given day.")
}

helpPanelTodayMoonFrac() {
  mouseTurnOFFtooltip()
  If (userAstroInfodMode!=1)
     mouseCreateOSDinfoLine("The illumination fraction, from 0% (new moon) to 100% (full moon).")
}

toggleTodayGraphMODE(modus:=0) {
  mouseTurnOFFtooltip()
  ; If (modus!="quickie")
  ;    todaySunMoonGraphMode := !todaySunMoonGraphMode

  ; userAstroInfodMode := !todaySunMoonGraphMode
  ; INIaction(1, "userAstroInfodMode", "SavedSettings")
  Gui, SettingsGUIA: Default
  GuiControlGet, uiUserCountry
  GuiControlGet, uiUserCity
  GuiControlGet, uiUserFullDateUTC
  ; ToolTip, % uiUserCountry "|" uiUserCity , , , 2
  p := geoData[uiUserCountry "|" uiUserCity]
  w := extractGeoLocationInfos(p)
  timeus := uiUserFullDateUTC
  yearu := SubStr(timeus, 1, 4)
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
  dstInfo := buildDSTinfo(k, w[4], w[5])
  timi := timeus
  timi += gmtOffset, Hours
  If (todaySunMoonGraphMode=1)
  {
     If (A_PtrSize=8)
        coolminant := getMoonNoonZeit(SubStr(timi, 1, 8) "000105", w[2], w[3], gmtOffset, 1)
     fmax := Round(coolminant.maxu, 1)
     fmin := Round(coolminant.minu, 1)
     getMoonElevation(timeus, w[2], w[3], 0, azii, elevu)
  } Else
  {
     getSunAzimuthElevation(timeus, w[2], w[3], 0, azii, elevu)
     If (A_PtrSize=8)
     {
        obj := wrapCalcSunInfos(timeus, w[2], w[3], gmtOffset, w[6], 0, dstInfo)
        fmax := obj.elev
        cobj := wrapCalcSunInfos(timeus, w[2], w[3] - 180, gmtOffset, w[6], 0, dstInfo)
        getSunAzimuthElevation(cobj.RawN, w[2], w[3], gmtOffset, brr, fmin)
        fmax := Round(fmax, 1)
        fmin := Round(fmin, 1)
     }
     ; fmin := cobj.elev
     ; ToolTip, % cobj.n , , , 2
  }
  getCtrlCoords(hSolarGraphPic, x1, y1, x2, y2)
  f := (todaySunMoonGraphMode=1) ? "MOON" : "SUN"
  ; ToolTip, % x "\" y , , , 2
  cardinal := defineAzimuthCardinal(azii)
  If cardinal
     cardinal := " (" cardinal ")"

  msgu := "Current " f " position on the sky:`nAzimuth: " Round(azii, 1) "°" cardinal "`nAltitude: " Round(elevu, 1) "°"
  If (A_PtrSize=8)
     msgu .= "`n`nAltitude graph max / min:`n" fmax "° / " fmin "°"

  If (modus="quickie")
     Return msgu
 
  mouseCreateOSDinfoLine(msgu, 0, x1, y2)
  ; SetTimer, removeTooltip, -2000
  UIcityChooser()
}

defineAzimuthCardinal(azii) {
  Static rm := 22.5

  If (isInRange(azii, 360 - rm, 360.1) || isInRange(azii, 0, rm)) ; 0
     cardinal := "North"
  Else If isInRange(azii, 45 - rm, 45 + rm)  ; 45
     cardinal := "NE"
  Else If isInRange(azii, 90 - rm, 90 + rm) ; 90
     cardinal := "East"
  Else If isInRange(azii, 135 - rm, 135 + rm) ; 135
     cardinal := "SE"
  Else If isInRange(azii, 180 - rm, 180 + rm) ; 180
     cardinal := "South"
  Else If isInRange(azii, 225 - rm, 225 + rm) ; 225
     cardinal := "SW"
  Else If isInRange(azii, 270 - rm, 270 + rm) ; 270
     cardinal := "West"
  Else If isInRange(azii, 315 - rm, 315 + rm) ; 315
     cardinal := "NW"
  Return cardinal
}

JEE_ClientToScreen(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2) {
; function by jeeswg found on:
; https://autohotkey.com/boards/viewtopic.php?t=38472

  VarSetCapacity(POINT, 8)
  NumPut(vPosX, &POINT, 0, "Int")
  NumPut(vPosY, &POINT, 4, "Int")
  DllCall("user32\ClientToScreen", "Ptr", hWnd, "Ptr", &POINT)
  vPosX2 := NumGet(&POINT, 0, "Int")
  vPosY2 := NumGet(&POINT, 4, "Int")
}


getCtrlCoords(thisHwnd, byRef x1, byRef y1, byRef x2, byRef y2) {
; Returns the screen rectangle of the control itself. The former version asked
; ControlGetFocus() for a class name, which cannot succeed when the handle given
; already is the control, so the width and the height stayed empty and the two
; corners collapsed onto each other.
   x1 := y1 := x2 := y2 := 0
   If !thisHwnd
      Return 0

   GetWinClientSize(w, h, thisHwnd, 0)
   JEE_ClientToScreen(thisHwnd, 0, 0, x1, y1)
   JEE_ClientToScreen(thisHwnd, w, h, x2, y2)
   Return 1
}

WM_MOUSEWHEEL(wParam, lParam, msg, hwnd) {
  If (AnyWindowOpen!=6)
     Return

  If (hwnd=hDatTime)
  {
     mouseData := (wParam >> 16)      ; return the HIWORD -  high-order word 
     ; TulTip(1, " == ", result, resultA, resultB, resultC, resultD, resultE)
     stepping := Round(Abs(mouseData) / 120)
     ; ToolTip, % msg , , , 2
     If (msg=526) ; horizontal mouse wheel
        direction := (mouseData>0 && mouseData<51234) ? "Right" : "Left"
     Else
        direction := (mouseData>0 && mouseData<51234) ? "Up" : "Down"
     SendInput, {%direction%}
  }
  ; ToolTip, % hwnd , , , 2
}

NextTodayBTN(diru:=0, luping:=0, kbdMode:=0,stepu:=0,modus:=0) {
   Static tz := 0, lastInvoked := 1, lastLooped := 1
   If ((A_TickCount - lastLooped<250) && luping!=1)
      Return

   If (A_TickCount - lastInvoked<450 && AnyWindowOpen!=8)
      tz++
   Else tz := 0

   f := 1
   If (tz>50)
      f := 24
   Else If (tz>32)
      f := 12
   Else If (tz>18)
      f := 6
   Else If (tz>6)
      f := 2

   If (AnyWindowOpen=8)
      f *= 2

   If (diru=-1)
      f *= -1

   If (luping=1)
      lastLooped := A_TickCount

   If (luping=1 && Abs(f)>2)
      f := (f<0) ? -2 : 2

   If (kbdMode=1)
   {
      If (A_TickCount - lastInvoked < 70)
         Return

      f := (diru=-1) ? -1* stepu : stepu
      If (modus="hours")
         uiUserFullDateUTC += f, Hours
      Else If (modus="minutes")
         uiUserFullDateUTC += f, Minutes
      Else If (modus="Days")
         uiUserFullDateUTC += f, Days
   } Else
   {
      uiUserFullDateUTC += f, Hours
   }

   lastInvoked := A_TickCount
   allowAutoUpdateTodayPanel := 0
   If (AnyWindowOpen=8)
   {
      generateEarthMap()
      Return
   }
   GuiControl, SettingsGUIA:, uiUserFullDateUTC, % uiUserFullDateUTC
   UIcityChooser()
}

PrevTodayBTN() {
   NextTodayBTN(-1)
}

WM_LBUTTONDOWN(a, b, c) {
  GuiControlGet, WhatsFocused, SettingsGUIA: FocusV
  MouseGetPos, , , , OutputVarControl, 2
  ; ToolTip, % OutputVarControl " | " A_GuiControl , , , 2
  If (OutputVarControl=hBtnTodayNext || OutputVarControl=hBtnTodayPrev)
  && (AnyWindowOpen=6 && InStr(A_GuiControl, "UIbtnToday") && InStr(WhatsFocused, "UIbtnToday"))
  {
     SetTimer, prolongNextTodayBTN, -10
  }
}

prolongNextTodayBTN() {
     If (AnyWindowOpen!=6)
        Return

     Gui, SettingsGUIA: Default
     MouseGetPos, , , , OutputVarControl, 2
     ControlFocus,, ahk_id %OutputVarControl%
        ; GuiControl, SettingsGUIA: Focus, % OutputVarControl
     Sleep, 10
     GuiControlGet, WhatsFocused, SettingsGUIA: FocusV
     Sleep, 10
     startZeit := A_TickCount
     hasLooped := 0
     While, GetKeyState("LButton", "P")
     {
         If (A_TickCount - startZeit<400)
            Continue
         ; ToolTip, % A_GuiControl "=" AnyWindowOpen , , , 2
         If InStr(WhatsFocused, "UIbtnTodayPrev")
            NextTodayBTN(-1, 1)
         Else If InStr(WhatsFocused, "UIbtnTodayNext")
            NextTodayBTN(1, 1)
         Sleep, 150
         hasLooped := 1
     }
     ; If (InStr(WhatsFocused, "UIbtnTodayPrev") && hasLooped=1)
     ;    NextTodayBTN(1, 1)
     ; Else If (InStr(WhatsFocused, "UIbtnTodayNext") && hasLooped=1)
     ;    NextTodayBTN(-1, 1)
}

UItodayPanelJumpDawn() {
  If (userAstroInfodMode!=1)
  {
     helpPanelTodayMoonFrac()
     Return
  }

  cobj := coreJumpSolarEventsToday()
  p := cobj.RawDa
  UItodayPanelJumpTo(p, cobj.lgmt)
}


UItodayPanelJumpT1() {
    Gui, SettingsGUIA: Default
    GuiControlGet, l, , UIastroInfoLabelRise
    If (userAstroInfodMode=1)
       UItodayPanelJumpRise()
    Else
       UItodayPanelJumpTcore(l)
}

UItodayPanelJumpT2() {
    Gui, SettingsGUIA: Default
    GuiControlGet, l, , UIastroInfoElevNoon
    If (userAstroInfodMode=1)
       UItodayPanelJumpNoon()
    Else
       UItodayPanelJumpTcore(l)
}

UItodayPanelJumpT3() {
    Gui, SettingsGUIA: Default
    GuiControlGet, l, , UIastroInfoLabelSetu
    If (userAstroInfodMode=1)
       UItodayPanelJumpSet()
    Else
       UItodayPanelJumpTcore(l)
}

UItodayPanelJumpTcore(l) {
    If InStr(l, "rise")
       UItodayPanelJumpRise()
    Else If InStr(l, "peak")
       UItodayPanelJumpNoon()
    Else If InStr(l, "set")
       UItodayPanelJumpSet()
}

UItodayPanelJumpRise() {
  cobj := coreJumpSolarEventsToday()
  If (userAstroInfodMode=1)
  {
     p := cobj.RawR
  } Else
  {
     mobj := wrapCalcMoonRiseSet(cobj.timeus, cobj.latu, cobj.longu, cobj.lgmt, cobj.altitude)
     p := mobj.RawR
  }

  UItodayPanelJumpTo(p, cobj.lgmt)
}

UItodayPanelJumpNoon() {
  cobj := coreJumpSolarEventsToday()
  t := cobj.timeus
  t += cobj.lgmt, Hours
  If (userAstroInfodMode=1)
  {
     p := cobj.RawN
  } Else
  {
     mobj := getMoonNoonZeit(SubStr(t, 1, 8) "000105", cobj.latu, cobj.longu, cobj.lgmt, 1)
     p := mobj.RawN
  }

  UItodayPanelJumpTo(p, cobj.lgmt)
}

UItodayPanelJumpSet() {
  cobj := coreJumpSolarEventsToday()
  If (userAstroInfodMode=1)
  {
     p := cobj.RawS
  } Else
  {
     mobj := wrapCalcMoonRiseSet(cobj.timeus, cobj.latu, cobj.longu, cobj.lgmt, cobj.altitude)
     p := mobj.RawS
  }

  UItodayPanelJumpTo(p, cobj.lgmt)
}

UItodayPanelJumpDusk() {
  If (userAstroInfodMode!=1)
     Return

  cobj := coreJumpSolarEventsToday()
  p := cobj.RawDu
  UItodayPanelJumpTo(p, cobj.lgmt)
}

UItodayPanelJumpTo(p, lgmt) {
; Moves the panel onto p, the local time stamp of a sun or moon event, by writing it into the
; date control in UTC. Where the event does not exist, p is blank or one of the 0/1 markers
; the wrappers leave behind, and nothing must happen: adding hours to a blank stamp would
; silently produce one out of the current date and time, and a click on a «--:--» used to
; send the panel there.
  If (StrLen(p)!=14)
     Return

  p += -1*lgmt, Hours
  If (StrLen(p)!=14)
     Return

  ; the moment jumped to is the user's choice, as the one set on the date control or with the
  ; Prev / Next buttons is; regularUpdaterTodayPanel() would otherwise move the panel back to
  ; the present moment at the next turn of the minute, undoing the jump
  allowAutoUpdateTodayPanel := 0
  GuiControl, SettingsGUIA:, uiUserFullDateUTC, % p
  UIcityChooser()
}

coreJumpSolarEventsToday() {
  Gui, SettingsGUIA: Default
  GuiControlGet, uiUserCountry
  GuiControlGet, uiUserCity
  GuiControlGet, uiUserFullDateUTC
  ; ToolTip, % uiUserCountry "|" uiUserCity , , , 2
  p := geoData[uiUserCountry "|" uiUserCity]
  w := extractGeoLocationInfos(p)
  timeus := uiUserFullDateUTC
  yearu := SubStr(timeus, 1, 4)
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
  dstInfo := buildDSTinfo(k, w[4], w[5])
  timi := timeus
  timi += gmtOffset, Hours
  cobj := wrapCalcSunInfos(timeus, w[2], w[3], gmtOffset, w[6], 0, dstInfo)
  ; the callers pair sday/eday with the two seasonal offsets kept in gmt/dst, so they must
  ; be the normalised summer half - never the raw transition days of the host machine
  summerHalfYdays(k, sYday, eYday)
  cobj.sday := sYday
  cobj.eday := eYday
  cobj.lgmt := gmtOffset
  cobj.gmt := w[4]
  cobj.dst := w[5]
  cobj.altitude := w[6]
  cobj.latu := w[2]
  cobj.longu := w[3]
  cobj.y := yearu
  cobj.timeus := timeus
  Return cobj
}

UItodayInfosYear() {
  Static islamicMonths := {1:"Al-Muḥarram", 2:"Ṣafar", 3:"Rabī' al-'Awwal", 4:"Rabī' ath-Thānī", 5:"Jumādā al-'Ūlā", 6:"Jumādā ath-Thāniyah", 7:"Rajab", 8:"Sha'bān", 9:"Ramaḍān", 10:"Shawwāl", 11:"Ḏū al-Qa'dah", 12:"Ḏū al-Ḥijjah"}
  Static persianMonths := {1:"Farvardīn", 2:"Ordībehešt", 3:"Khordād", 4:"Tīr", 5:"Amordād", 6:"Shahrīvar", 7:"Mehr", 8:"Ābān", 9:"Āzar", 10:"Dey", 11:"Bahman", 12:"Esfand"}
  Static HebrewMonths := {1:"Nissan", 10:"Tevet", 11:"Shevat", 12:"Adar", 13:"Veadar", 2:"Iyar", 3:"Sivan", 4:"Tammuz", 5:"Av", 6:"Elul", 7:"Tishrei", 8:"Cheshvan", 9:"Kislev"}

  p := geoData[uiUserCountry "|" uiUserCity]
  w := extractGeoLocationInfos(p)
  timeus := uiUserFullDateUTC
  yearu := SubStr(uiUserFullDateUTC, 1, 4)
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])

  timi := uiUserFullDateUTC
  timi += gmtOffset, Hours
  FormatTime, testValid, % timeus, yyyy/MM/dd

  yearu := testValid ? SubStr(timi, 1, 4) : SubStr(uiUserFullDateUTC, 1, 4)
  yearu := SubStr(yearu, 1, 4)

  thisTime := testValid ? timi : uiUserFullDateUTC
  FormatTime, longu, % thisTime, LongDate
  FormatTime, isoYWeek, % thisTime, YWeek
  isoYWeek := SubStr(isoYWeek, 5)
  FormatTime, gyd, % thisTime, Yday
  d := isLeapYear(yearu) ? 366 : 365
  dx := Round(gyd/d * 100, 1)
  f := isLeapYear(yearu) ? yearu " is a leap year." : yearu " is not a leap year."
  rd := d - gyd
  dayum := LTrim(SubStr(thisTime, 7, 2), 0)
  montum := LTrim(SubStr(thisTime, 5, 2), 0)
  jd := gregorian_to_jd(yearu, montum, dayum)

  ; code for hebrew, persian and islamic dates converted from JS to AHK, source: https://calcuworld.com/calendar-calculators/hebrew-calendar-converter/

  ; obju := jd_to_hebrew(jd) ; it does not work; recursion limit exceeded
  ; HebrewYear := "`nHebrew date: " obju[1] " / " Format("{:02}", obju[2]) ":" HebrewMonths[obju[2]] " / " Format("{:02}", obju[3])
  obju := jd_to_persian(jd)
  ; persianYear := (gyd<mEquiDay) ? yearu - 622 : yearu - 621 ; simple mode
  persianYear := "`nPersian date: " obju[1] " / " Format("{:02}", obju[2]) ":" persianMonths[obju[2]] " / " Format("{:02}", obju[3])
  obju := jd_to_islamic(jd)
  islamicYear := "`n`nIslamic date: " obju[1] " / " Format("{:02}", obju[2]) ":" islamicMonths[obju[2]] " / " Format("{:02}", obju[3])

  ; kz := abs(yearu - 3761)//4 ; leap years since the year 3761
  ; hebrewYear := mod(yearu, 19)
  ; If isVarEqualTo(hebrewYear, 0, 3, 6, 8, 11, 14, 17)
  ;    hebrewYear += 1
  ; Else
  ;    hebrewYear += 2

  ; hebrewYear := yearu + hebrewYear + 3760
  msgu := longu "`nCurrent week: " isoYWeek " (ISO 8601)`nDays elapsed: " gyd " / " d " ( " dx "% )`nRemaining days: " rd "`n" f hebrewYear islamicYear persianYear
  mouseCreateOSDinfoLine(msgu)
}

btnUItodayInfosLocations() {
; lists the custom user locations (country index 1) with their local date and time,
; the GMT offset in use, the solar time of the day and the current Sun altitude

  mouseTurnOFFtooltip()
  If (A_PtrSize!=8)
     Return

  cities := geoData["1|-1"]
  If (cities<1)
     Return

  Gui, SettingsGUIA: Default
  GuiControlGet, uiUserCountry
  GuiControlGet, uiUserCity
  GuiControlGet, uiUserFullDateUTC
  timeus := uiUserFullDateUTC
  FormatTime, testValid, % timeus, yyyy/MM/dd
  If !testValid
     Return

  yearu := SubStr(timeus, 1, 4)
  FormatTime, gyd, % timeus, Yday
  k := TZI_GetTimeZoneInformation(yearu, gyd)
  FormatTime, utcu, % timeus, dd/MM/yyyy, HH:mm
  msgu := ""
  Loop, % cities
  {
      p := geoData["1|" A_Index]
      If !p
         Continue

      w := extractGeoLocationInfos(p)
      If (w[1]="" || w[2]="" || w[3]="")
         Continue

      gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
      timi := timeus
      timi += gmtOffset, Hours
      FormatTime, brr, % timi, dd/MM/yyyy, HH:mm
      getSunAzimuthElevation(timeus, w[2], w[3], 0, azii, elevu)
      noonu := "a"
      nobj := SolarCalculator(timeus, w[2], w[3])
      If nobj.RawN
      {
         getSunAzimuthElevation(nobj.RawN, w[2], w[3], 0, nazii, nelev)
         If (nelev!="")
            noonu := Round(nelev, 2)
      }

      jiji := decideJijiReadable(timeus, elevu, w[2], w[3], noonu)
      j := (gmtOffset>=0) ? "+" : ""
      eleva := (elevu!="") ? Round(elevu, 1) "°" : "--"
      marker := (uiUserCountry=1 && uiUserCity=A_Index) ? "»" : ""
      msgu .= marker w[1] " - " brr " (GMT " j Round(gmtOffset, 1) "h) - " jiji ", alt " eleva "`n"
  }

  mouseCreateOSDinfoLine(Trim(msgu, "`n"))
  If (StrLen(msgu)>270)
     SetTimer, mouseTurnOFFtooltip, -20000
}

UIpanelTodayLightDiffSolstices() {
  If (userAstroInfodMode!=1 || A_PtrSize!=8)
     Return

  cobj := coreJumpSolarEventsToday()
  kjune := calculateEquiSols(2, cobj.y)
  kdec := calculateEquiSols(4, cobj.y)
  dstInfo := {dstStartYday: cobj.sday, dstEndYday: cobj.eday, stdOffset: cobj.gmt, dstOffset: cobj.dst}
  ; ToolTip, % kjune "`n" kdec , , , 2
  FormatTime, gyd, % kjune, Yday
  gmtOffset := isInDSTperiod(gyd, cobj.sday, cobj.eday) ? cobj.dst : cobj.gmt
  jobj := wrapCalcSunInfos(kjune, cobj.latu, cobj.longu, gmtOffset, cobj.altitude, 0, dstInfo)

  FormatTime, gyd, % kdec, Yday
  gmtOffset := isInDSTperiod(gyd, cobj.sday, cobj.eday) ? cobj.dst : cobj.gmt
  dobj := wrapCalcSunInfos(kdec, cobj.latu, cobj.longu, gmtOffset, cobj.altitude, 0, dstInfo)

  diffSols := (jobj.durRaw >= dobj.durRaw) ? jobj.durRaw - dobj.durRaw : dobj.durRaw - jobj.durRaw
  diffSols := transformSecondsReadable(diffSols, 2)
  durJune := jobj.durRaw - cobj.durRaw
  durDec := dobj.durRaw - cobj.durRaw

  diffuJ := transformSecondsReadable(abs(durJune), 2)
  If (diffuJ!="00:00" && diffuJ!="0s")
     diffuJ := (jobj.durRaw > cobj.durRaw) ? "-" diffuJ : "+" diffuJ

  diffuD := transformSecondsReadable(abs(durDec), 2)
  If (diffud!="00:00" && diffuD!="0s")
     diffuD := (dobj.durRaw > cobj.durRaw) ? "-" diffuD : "+" diffuD

  GuiControlGet, UIastroInfoLightDiff
  GuiControlGet, OutputVar, , uiastroinfoLightMode
  If InStr(OutputVar, "civil")
     OutputVar := "0s"
  Else
     GuiControlGet, OutputVar, , UIastroInfoLightDiff

  mouseCreateOSDinfoLine("Today's sunlight duration:`nYesterday: " OutputVar "`nJune solstice: " diffuJ "`nDecember solstice: " diffuD "`nDifference between solstices: " diffSols)
}

PanelTodayInfos() {
    If reactWinOpened(A_ThisFunc, 6)
       Return

    Global UIastroInfoDaylight, UIastroInfoDawn, UIastroInfoRise, UIastroInfoNoon, UIastroInfoSet, UIastroInfoDusk, UIastroInfoMphase, UIastroInfoMoon
         , UIastroInfoProgressAnnum, UIastroInfoAnnum, UIastroInfoProgressDayu, UIastroInfoDayu, UIastroInfoProgressMoon, UIastroInfoMoonlight
         , uiastroinfoLightMode, UIastroInfoLtimeGMT, UIastroInfoObjElev, UIastroInfoLtimeus, UIastroInfoObjInfo, UIastroInfoObjVisibility, UItodayEventsEditu
         , UIastroInfoTotalLight, UIastroInfoElevNoon, UIastroInfoLabelDawn, UIastroInfoLabelDusk, UIastroInfoLightDiff, UIbtnRemGeoLoc, UIbtnAddGeoLoc, UIastroInfoTotalDiffLight
         , BtnAstroModa, UIastroInfoLabelTotalLight, UIastroInfoLtimeDate, UIbtnTodayPrev, UIbtnTodayNext, UIastroInfoLabelRise, UIastroInfoLabelSetu

    GenericPanelGUI(0)
    LastWinOpened := A_ThisFunc
    AnyWindowOpen := 6
    INIaction(1, "LastWinOpened", "SavedSettings")
    If (A_PtrSize!=8)
       userAstroInfodMode := 0

    todaySunMoonGraphMode := !userAstroInfodMode
    btnWid := 100
    txtWid := 375
    ; Gui, Add, Text, x10 y10 h2 w2, -
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 225
    }

    btnW1 := (PrefsLargeFonts=1) ? 105 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    nW := (PrefsLargeFonts=1) ? 65 : 60
    nH := (PrefsLargeFonts=1) ? 35 : 30
    userAlarmWday1 := InStr(userAlarmWeekDays, "1") ? 1 : 0
    userAlarmWday2 := InStr(userAlarmWeekDays, "2") ? 1 : 0
    userAlarmWday3 := InStr(userAlarmWeekDays, "3") ? 1 : 0
    userAlarmWday4 := InStr(userAlarmWeekDays, "4") ? 1 : 0
    userAlarmWday5 := InStr(userAlarmWeekDays, "5") ? 1 : 0
    userAlarmWday6 := InStr(userAlarmWeekDays, "6") ? 1 : 0
    userAlarmWday7 := InStr(userAlarmWeekDays, "7") ? 1 : 0
    userAlarmExceptPerso := InStr(userAlarmWeekDays, "p") ? 1 : 0
    userAlarmExceptRelu := InStr(userAlarmWeekDays, "r") ? 1 : 0
    userAlarmExceptSeculu := InStr(userAlarmWeekDays, "s") ? 1 : 0
    If !userAlarmWeekDays
       userAlarmWday7 := userAlarmWday1 := 1

    testCelebrations(1)
    zx := wrapCalculateEquiSolsDates(A_YDay)
    If (InStr(zx.msg, "now") && zx.r=1)
       thisSeason := "(" OSDsuffix " ) March equinox is today. The day and night are everywhere on Earth of approximately equal length."
    Else If (InStr(zx.msg, "now") && zx.r=2)
       thisSeason := "(" OSDsuffix " ) June solstice. Today is one of the longest days of the year."
    Else If (InStr(zx.msg, "now") && zx.r=3)
       thisSeason := "(" OSDsuffix " ) September equinox is today. The day and night are everywhere on Earth of approximately equal length."
    Else If (InStr(zx.msg, "now") && zx.r=4)
       thisSeason := "(" OSDsuffix " ) December solstice. Today is one of the shortest days of the year."
    Else
       thisSeason := zx.msg

    Global editF1, editF2, editF3, editF4, editF5, uiInfoGeoData, AstroTabsWin
    If !listedCountries
       loadGeoData()

    percentileYear := Round(A_YDay/366*100, 1) "%"
    CurrentYear := A_Year
    NextYear := CurrentYear + 1
    percentileDay := Round(getPercentOfToday(minsPassed) * 100, 1) "%"
    Gui, Add, Tab3, xm+5 Section Choose2 AltSubmit vAstroTabsWin +hwndhTabs, Events|Astronomy

    Gui, Tab, 1
    Gui, Add, Text, xs+12 y+5 w1 h1 Section, .
    extras := decideSysTrayTooltip("about")
    If (thisSeason ~= "i)(two|week|since|today|until|here|tomorrow|yesterday)")
       extras .= "`n`n" thisSeason

    ; south of the equator the days lengthen towards the December solstice and shorten
    ; towards the one of June, so the place shown on the Astronomy tab decides the wording
    w := extractGeoLocationInfos(geoData[uiUserCountry "|" uiUserCity])
    southern := (isNumber(w[2]) && w[2]<0) ? 1 : 0
    If isInRange(A_YDay, jSolsDay + 1, dSolsDay - 1)
       extras .= "`n`nThe days are getting " (southern ? "longer" : "shorter") " until the December solstice."
    Else If (A_YDay>dSolsDay || A_YDay<jSolsDay)
       extras .= "`n`nThe days are getting " (southern ? "shorter" : "longer") " until the June solstice."

    If (A_YDay>354 && ObserveHolidays=1)
       extras .= "`n`nSeason's greetings! Enjoy the holidays! 😊"

    testFeast := A_Mon "." A_MDay
    If (isLeapYear() && testFeast="01.01")
       extras .= "`n`n" A_Year " is a leap year."

    showThis := (ObserveHolidays=1 && ObserveSecularDays=1) ? 0 : 1
    If (testFeast="02.29" && showThis=1)
       extras .= "`n`nToday is the 29th of February - a leap year day."

    If (testFeast="01.01" && showThis=1)
       extras .= "`n`nHappy new year! All the best to you and your family."

    If (ObserveHolidays=1)
       listu := coreUpcomingEvents(2, 14, 4)
    If listu
       extras .= "`n`nCALENDAR EVENTS: `n" Trim(listu, "`n")

    listu := "SOLAR SEASONS:`n"
    friendlyInitDating(ereday, yesterday, tudayDate, tmrwDate, mtmrwDate)
    szn := listSolarSeasons(ereday, yesterday, tudayDate, tmrwDate, mtmrwDate, 1, 0)
    listu .= StrReplace(szn, "`n`n", "`n")
    If InStr(listu, ". | ✝ ") 
       listu := StrReplace(listu, ". | ✝ ", ".`n`n✝ ")
    If InStr(extras, ". | ✝ ") 
       extras := StrReplace(extras, ". | ✝ ", ".`n`n✝ ")

    rzz := (PrefsLargeFonts=1) ? 17 : 20
    txtWid2 := (PrefsLargeFonts=1) ? txtWid + 40 : txtWid + 25
    Gui, Add, Edit, y+15 w%txtWid2% +ReadOnly -Border r%rzz% vUItodayEventsEditu, % Trim(extras, "`n") "`n`n" listu

    Gui, Tab, 2
    UItodayPanelResetDate("yo")
    sml := (PrefsLargeFonts=1) ? 70 : 40
    ; Gui, Add, Text, xs y+15 Section +0x200 w1 -wrap, Location:
    widu := (PrefsLargeFonts=1) ? 190 : 120
    GuiAddDropDownList("xs y+15 Section w" widu " AltSubmit gUIcountryChooser Choose" uiUserCountry " vuiUserCountry", countriesList, "Country")
    ; GuiAddDropDownList("x+5 w" widu " AltSubmit gUIcountryChooser Choose" uiUserCountry " vuiUserCountry", countriesList, [hTemp, 0, "Country"])
    GuiAddDropDownList("x+5 w" widu " AltSubmit gUIcityChooser Choose" uiUserCity " vuiUserCity", getCitiesList(uiUserCountry), "City")
    Gui, Add, Button, x+5 hp gSearchOpenPanelEarthMap +hwndhTemp, &Search
    ToolTip2ctrl(hTemp, "Search location")
    Gui, Add, Button, x+5 hp gPanelEarthMap +hwndhTemp, &Map
    ToolTip2ctrl(hTemp, "Find a location on Earth's map.")
    ; the Remove and the Add buttons share the same spot; only one of them is visible at any given time
    thisu := (uiUserCountry=1) ? "" : " Hidden"
    Gui, Add, Button, % "x+5 hp gbtnUIremoveUserGeoLocation vUIbtnRemGeoLoc +hwndhTemp" thisu, &Remove
    ToolTip2ctrl(hTemp, "Remove selected custom location")
    thisu := (uiUserCountry=1) ? " Hidden" : ""
    Gui, Add, Button, % "xp yp wp hp gbtnUIaddTodayGeoLocation vUIbtnAddGeoLoc +hwndhTemp" thisu, Ad&d
    ToolTip2ctrl(hTemp, "Add to custom locations list")
    Gui, Add, Text, xs y+10 , Time and date to observe
    Gui, Add, DateTime, xs yp Choose%uiUserFullDateUTC% Right gUItodayDateCtrl vuiUserFullDateUTC +hwndhDatTime, dddd, d MMMM, yyyy; HH:mm (UTC)
    widu := (PrefsLargeFonts=1) ? 40 : 32
    hBtnTodayPrev := GuiAddButton("x+5 w" widu " hp gPrevTodayBTN vUIbtnTodayPrev", "<", "Previous hour (,)")
    Gui, Add, Button, x+5 wp+10 hp gUItodayPanelResetDate +hwndhTemp, &Now
    ToolTip2ctrl(hTemp, "Reset to current time and date (\)")
    hBtnTodayNext := GuiAddButton("x+5 wp-10 hp gNextTodayBTN vUIbtnTodayNext", ">", "Next hour (.)")
    sml := (PrefsLargeFonts=1) ? 500 : 370
    Gui, Add, Text, xs y+5 w%sml% Section hp +0x200 vuiInfoGeoData -wrap, Geo data.
    sml := (PrefsLargeFonts=1) ? 100 : 60
    zml := (PrefsLargeFonts=1) ? 240 : 150
    Gui, Add, Text, xs y+10 w%sml% Section -wrap +hwndhCL16 gUItodayInfosYear, Local time:
    Gui, Add, Text, x+5 wp -wrap vUIastroInfoLtimeus gUItodayInfosYear +hwndhCL15, --:--
    lza := (PrefsLargeFonts=1) ? 10 :5
    Gui, Add, Text, x+1 hp wp-%lza% -wrap,
    Gui, Add, Button, x+1 hp+7 gToggleAstroInfosModa vBtnAstroModa +hwndhTemp, Moona
    ToolTip2ctrl(hTemp, "Toggle between Sun and Moon details (/)")

    Gui, Add, Text, xs y+0 w%sml% -wrap,
    Gui, Add, Text, x+5 wp hp -wrap vUIastroInfoLtimeGMT, GMT
    Gui, Add, Text, x+5 hp wp -wrap,

    Gui, Add, Text, xs y+7 w%sml% -wrap gUIpanelTodayLightDiffSolstices vuiastroinfoLightMode +hwndhCL2, Sunlight:
    Gui, Add, Text, x+5 wp hp ghelpPanelTodayTotalLight vUIastroInfoLabelTotalLight +hwndhCL12, Total light:
    Gui, Add, Text, x+5 hp w%zml% Center vUIastroInfoObjElev ghelpTodayElevationNow +hwndhCL1, Moon elevation: 92.4° 
    Gui, Add, Text, xs y+7 w%sml% -wrap vUIastroInfoDaylight gUIpanelTodayLightDiffSolstices +hwndhCL5, --:--
    ; sml := (PrefsLargeFonts=1) ? 320 : 230
    Gui, Add, Text, x+5 hp wp -wrap vUIastroInfoTotalLight ghelpPanelTodayTotalLight +hwndhCL13, --:--
    Gui, Add, Text, x+5 hp w%zml% Center vUIastroInfoObjInfo, ---
    Gui, Add, Text, xs y+7 w%sml% -wrap vUIastroInfoLightDiff gUIpanelTodayLightDiffSolstices +hwndhCL11, --:--
    Gui, Add, Text, x+5 hp wp -wrap vUIastroInfoTotalDiffLight ghelpPanelTodayTotalLight +hwndhCL18, --:--
    plm := (PrefsLargeFonts=1) ? 450 : 280
    Gui, Add, Text, xs+%plm% ys Section hp wp -wrap vUIastroInfoLabelDawn ghelpPanelTodayMoonFrac +hwndhCL3, Dawn:
    Gui, Add, Text, x+5 yp hp wp -wrap vUIastroInfoDawn gUItodayPanelJumpDawn +hwndhCL6, --:--
    Gui, Add, Text, xs y+7 hp wp -wrap vUIastroInfoLabelRise, Rise: 0°
    Gui, Add, Text, x+5 yp hp wp -wrap vUIastroInfoRise gUItodayPanelJumpT1 +hwndhCL7, --:--
    Gui, Add, Text, xs y+7 hp wp -wrap vUIastroInfoElevNoon ghelpPanelTodayNoon +hwndhCL4, Noon: --.-°
    Gui, Add, Text, x+5 yp hp wp -wrap vUIastroInfoNoon gUItodayPanelJumpT2 +hwndhCL8, --:--
    Gui, Add, Text, xs y+7 hp wp -wrap vUIastroInfoLabelSetu, Set: 0°
    Gui, Add, Text, x+5 yp hp wp -wrap vUIastroInfoSet gUItodayPanelJumpT3 +hwndhCL9, --:--
    Gui, Add, Text, xs y+7 hp wp -wrap vUIastroInfoLabelDusk, Dusk:
    Gui, Add, Text, x+5 yp hp wp -wrap vUIastroInfoDusk gUItodayPanelJumpDusk +hwndhCL10, --:--

    If (A_OSVersion="WIN_XP")
    {
       Gui, Font,, Arial ; only as backup, doesn't have all characters on XP
       Gui, Font,, Symbola
       Gui, Font,, Segoe UI Symbol
       Gui, Font,, DejaVu Sans
       Gui, Font,, DejaVu LGC Sans
    }

    weeksPassed := Floor(A_YDay/7)
    weeksPlural := "weeks"
    weeksPlural2 := "have"
    graphW := (PrefsLargeFonts=1) ? 220 : 135
    graphH := (PrefsLargeFonts=1) ? 110 : 75
    Gui, Add, Text, xm+15 y+15 Section w1 h2 -wrap, .
    Gui, Add, Text, xs y+5 w1 h1, Sun and moon position on the sky illustration.
    Gui, Add, Text, xp yp w%graphW% h%graphH% +0x8 +0xE gtoggleTodayGraphMODE +hwndhSolarGraphPic, Solar illustration area
    graphW := (PrefsLargeFonts=1) ? 260 : 150
    Gui, Add, Text, x+8 yp Section vUIastroInfoProgressAnnum, % CurrentYear " {" CalcTextHorizPrev(A_YDay, 366) "} " NextYear
    Gui, Add, Text, y+5 wp vUIastroInfoAnnum gUItodayInfosYear +hwndhCL14, %weeksPassed% %weeksPlural% (%percentileYear%) of %CurrentYear% %weeksPlural2% elapsed.
    ; Gui, Add, Text, xp+15 y+10 wp vUIastroInfoProgressMoon, % "New {" CalcTextHorizPrev(Round(moonPhase[4] * 1000), 1009, 0, 24) "} Full"
    ; Gui, Add, Text, y+10 wp vUIastroInfoMoon, %moonPhaseC%`% of the cycle, %moonPhaseL%`% illuminated.`n-
    Gui, Add, Text, y+10 wp vUIastroInfoProgressDayu gbtnUItodayInfosLocations +hwndhCL17, % "0h {" CalcTextHorizPrev(minsPassed, 1442, 0, 25) "} 24h "
    ToolTip2ctrl(hCL17, "Local times for the custom locations")
    Gui, Add, Text, y+5 wp vUIastroInfoDayu +hwndhTemp gdummy, %minsPassed% minutes (%percentileDay%) of today have elapsed.
    ToolTip2ctrl(hTemp, "Total minutes in 24 hours: 1440.")
    If (A_OSVersion="WIN_XP")
       doResetGuiFont()

    btnW1 := (PrefsLargeFonts=1) ? 110 : 80
    btnW2 := (PrefsLargeFonts=1) ? 80 : 55
    btnW3 := (PrefsLargeFonts=1) ? 110 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    Gui, Tab
    If (A_PtrSize!=8)
       Gui, Add, Text, xm+0 y+10, WARNING: The astronomy features are not available on the 32 bits edition.
    Gui, Add, Button, xm+0 y+20 Section h%btnH% w%btnW3% gPanelIncomingCelebrations, &Celebrations
    Gui, Add, Button, x+5 hp w%btnW3% gPanelCalendarWindow, C&alendar
    ; Gui, Add, Button, x+5 hp w%btnW1% gUIlistSunRiseSets , &Table
    Gui, Add, Button, x+5 hp w%btnW1% gBTNopenYearSolarTable, &Year graph
    Gui, Add, Button, x+5 hp wp-20 gCloseWindow, C&lose
    Gui, Add, Button, x+1 hp w30 ginvokeSettingsContextMenu +hwndhTemp, ▼
    ToolTip2ctrl(hTemp, "More options (context menu)")
    ; Gui, Add, Button, x+5 hp w%btnW1% gbatchDumpTests , &Test all

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    ColorPickerHandles := ""
    Loop, 18
        ColorPickerHandles .= hCL%A_Index% ","

    Gui, Show, AutoSize, About today: %appName%
    UIcityChooser()
    Settimer, regularUpdaterTodayPanel, 2500
}

regularUpdaterTodayPanel() {
   ; Static lastInvoked := 1
   If (AnyWindowOpen!=6)
   {
      Settimer, regularUpdaterTodayPanel, Off
      Return
   }

   Gui, SettingsGUIA: Default
   GuiControlGet, AstroTabsWin
   If (AstroTabsWin!=2)
      Return

   thisu := A_Mon A_Hour A_Min
   If (allowAutoUpdateTodayPanel=1 && AnyWindowOpen=6 && thisu!=lastTodayPanelZeitUpdate)
   {
      lastTodayPanelZeitUpdate := thisu
      UItodayPanelResetDate()
   }
}

UItodayDateCtrl() {
   allowAutoUpdateTodayPanel := 0
   UIcityChooser()
}

CloseWindowAbout() {
    ToolTip, :-)
    SetTimer, CloseWindow, -250
    SetTimer, removeTooltip, -600
}

removeTooltip() {
  ToolTip
}

setMenusTheme(modus) {
   uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
   SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
   global AllowDarkModeForWindow := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 133, "ptr")
   FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
   DllCall(SetPreferredAppMode, "int", modus) ; Dark
   DllCall(FlushMenuThemes)
}

setDarkWinAttribs(hwndGUI, modus:=2) {
   If (A_OSVersion="WIN_7" || A_OSVersion="WIN_XP")
      Return

   if (A_OSVersion >= "10.0.17763" && SubStr(A_OSVersion, 1, 4)>=10)
   {
       DWMWA_USE_IMMERSIVE_DARK_MODE := 19
       if (A_OSVersion >= "10.0.18985")
          DWMWA_USE_IMMERSIVE_DARK_MODE := 20
       DllCall("dwmapi\DwmSetWindowAttribute", "UPtr", hwndGUI, "int", DWMWA_USE_IMMERSIVE_DARK_MODE, "int*", modus, "int", 4)
   }
   DllCall(AllowDarkModeForWindow, "UPtr", hwndGUI, "int", modus) ; Dark
}


OpenChangeLog() {
  Try Run, "%A_ScriptDir%\bells-tower-change-log.txt"
}

;================================================================
; - Load, verify and save settings functions
;================================================================

INIaction(act, var, section) {
  varValue := %var%
  If (storeSettingsREG=0)
  {
     If (act=1)
     {
        IniWrite, %varValue%, %IniFile%, %section%, %var%
     } Else
     {
        IniRead, loaded, %IniFile%, %section%, %var%, %varValue%
        If !ErrorLevel
           %var% := loaded
     }
  } Else
  {
     If (act=1)
     {
        RegWrite, REG_SZ, %APPregEntry%, %var%, %varValue%
     } Else
     {
        RegRead, loaded, %APPregEntry%, %var%
        If !ErrorLevel
           %var% := loaded
     }
  }
}

INIactionNonGlobal(act, var, varValue:=0, section:=0) {
  If (storeSettingsREG=0)
  {
     If (act=1)
        IniWrite, %varValue%, %IniFile%, %section%, %var%
     Else
        IniRead, varOutput, %IniFile%, %section%, %var%, %varValue%
  } Else
  {
     If (act=1)
        RegWrite, REG_SZ, %APPregEntry%\%section%, %var%, %varValue%
     Else
        RegRead, varOutput, %APPregEntry%\%section%, %var%
  }
  Return varOutput
}

INIdumpSection(section) {
; Returns an entire settings section as a list of key=value lines.
; Reading the section in one go avoids thousands of individual IniRead / RegRead
; calls when the whole set of stored keys has to be walked.

  listu := ""
  If (storeSettingsREG=0)
  {
     IniRead, listu, %IniFile%, %section%
     Return listu
  }

  Loop, Reg, % APPregEntry "\" section, V
  {
     RegRead, thisValue
     listu .= A_LoopRegName "=" thisValue "`n"
  }

  Return Trim(listu, "`n`r")
}

listUserDefinedCelebrations() {
; Extracts the user defined events out of the Celebrations section.
; Keys look like MM.DD.a (observed every year) or MM.DD.YYYY (a single year);
; MM.DD.r and MM.DD.s mark disabled built-in celebrations and are not user events.

  listum := ""
  countu := 0
  Loop, Parse, % INIdumpSection("Celebrations"), `n, `r
  {
      thisLine := Trim(A_LoopField)
      p := InStr(thisLine, "=")
      If (p<2)
         Continue

      thisKey := SubStr(thisLine, 1, p - 1)
      thisValue := SubStr(thisLine, p + 1)
      If (StrLen(thisValue)<3)
         Continue

      zz := StrSplit(thisKey, ".")
      If (zz.Count()!=3) || (StrLen(zz[1])!=2 || StrLen(zz[2])!=2)
         Continue

      If (zz[3]!="a" && StrLen(zz[3])!=4)   ; skips the .r and .s disabling markers
         Continue

      If (zz[3]!="a" && !isNumber(zz[3]))
         Continue

      listum .= thisKey CSmid thisValue "`n"
      countu++
  }

  Return [listum, countu]
}

INIsettings(a) {
  FirstRun := 0
  If (a=1) ; a=1 means save into INI
  {
     INIaction(1, "FirstRun", "SavedSettings")
     INIaction(1, "ReleaseDate", "SavedSettings")
     INIaction(1, "Version", "SavedSettings")
  } Else
  {
     INIaction(0, "EquiSolsCache", "SavedSettings")
  }

  INIaction(a, "PrefsLargeFonts", "SavedSettings")
  INIaction(a, "LastWinOpened", "SavedSettings")
  INIaction(a, "LargeUIfontValue", "SavedSettings")
  INIaction(a, "uiDarkMode", "SavedSettings")
  INIaction(a, "tollQuarters", "SavedSettings")
  INIaction(a, "tollQuartersException", "SavedSettings")
  INIaction(a, "tollNoon", "SavedSettings")
  INIaction(a, "tollHours", "SavedSettings")
  INIaction(a, "tollHoursAmount", "SavedSettings")
  INIaction(a, "displayClock", "SavedSettings")
  INIaction(a, "analogMoonPhases", "SavedSettings")
  INIaction(a, "showAnalogHourLabels", "SavedSettings")
  INIaction(a, "silentHours", "SavedSettings")
  INIaction(a, "silentHoursA", "SavedSettings")
  INIaction(a, "userAstroInfodMode", "SavedSettings")
  INIaction(a, "silentHoursB", "SavedSettings")
  INIaction(a, "showTimeIdleAfter", "SavedSettings")
  INIaction(a, "BeepsVolume", "SavedSettings")
  INIaction(a, "DynamicVolume", "SavedSettings")
  INIaction(a, "AutoUnmute", "SavedSettings")
  INIaction(a, "hasHowledDay", "SavedSettings")
  INIaction(a, "userAlarmSound", "SavedSettings")
  INIaction(a, "userTimerSound", "SavedSettings")
  INIaction(a, "userMuteAllSounds", "SavedSettings")
  INIaction(a, "tickTockNoise", "SavedSettings")
  INIaction(a, "stopWatchDoBeeps", "SavedSettings")
  INIaction(a, "strikeInterval", "SavedSettings")
  INIaction(a, "LastNoonAudio", "SavedSettings")
  INIaction(a, "AdditionalStrikes", "SavedSettings")
  INIaction(a, "strikeEveryMin", "SavedSettings")
  INIaction(a, "QuotesAlreadySeen", "SavedSettings")
  INIaction(a, "showBibleQuotes", "SavedSettings")
  INIaction(a, "BibleQuotesLang", "SavedSettings")
  INIaction(a, "noBibleQuoteMhidden", "SavedSettings")
  INIaction(a, "BibleQuotesInterval", "SavedSettings")
  INIaction(a, "userBibleStartPoint", "SavedSettings")
  INIaction(a, "gongAudioVerseDisplay", "SavedSettings")
  INIaction(a, "orderedBibleQuotes", "SavedSettings")
  INIaction(a, "SemantronHoliday", "SavedSettings")
  INIaction(a, "ObserveHolidays", "SavedSettings")
  INIaction(a, "ObserveSecularDays", "SavedSettings")
  INIaction(a, "ObserveReligiousDays", "SavedSettings")
  INIaction(a, "PreferSecularDays", "SavedSettings")
  INIaction(a, "UserReligion", "SavedSettings")
  INIaction(a, "noTollingWhenMhidden", "SavedSettings")
  INIaction(a, "noTollingWhenLocked", "SavedSettings")
  INIaction(a, "noTollingBgrSounds", "SavedSettings")
  INIaction(a, "NoWelcomePopupInfo", "SavedSettings")
  INIaction(a, "userMustDoAlarm", "SavedSettings")
  INIaction(a, "userAlarmMsg", "SavedSettings")
  INIaction(a, "userAlarmHours", "SavedSettings")
  INIaction(a, "userAlarmMins", "SavedSettings")
  INIaction(a, "userAlarmSnooze", "SavedSettings")
  INIaction(a, "AlarmersDarkScreen", "SavedSettings")
  INIaction(a, "userAlarmRepeated", "SavedSettings")
  INIaction(a, "userAlarmWeekDays", "SavedSettings")
  INIaction(a, "userAlarmFreq", "SavedSettings")
  INIaction(a, "userTimerFreq", "SavedSettings")
  INIaction(0, "uiUserCountry", "SavedSettings")
  INIaction(0, "uiUserCity", "SavedSettings")
  INIaction(0, "allowDSTchanges", "SavedSettings")
  INIaction(0, "allowAltitudeSolarChanges", "SavedSettings")
  INIaction(0, "lastUsedGeoLocation", "SavedSettings")

; OSD settings
  INIaction(a, "DisplayTimeUser", "OSDprefs")
  INIaction(a, "constantAnalogClock", "OSDprefs")
  INIaction(a, "constantOSDvisible", "OSDprefs")
  INIaction(a, "analogClockScale", "OSDprefs")
  INIaction(a, "showMoonPhaseOSD", "OSDprefs")
  INIaction(a, "roundedClock", "OSDprefs")
  INIaction(a, "FontName", "OSDprefs")
  INIaction(a, "FontSize", "OSDprefs")
  INIaction(a, "FontSizeQuotes", "OSDprefs")
  INIaction(a, "GuiX", "OSDprefs")
  INIaction(a, "GuiY", "OSDprefs")
  INIaction(a, "ClockGuiX", "OSDprefs")
  INIaction(a, "ClockGuiY", "OSDprefs")
  INIaction(a, "OSDalpha", "OSDprefs")
  INIaction(a, "OSDbgrColor", "OSDprefs")
  INIaction(a, "OSDtextColor", "OSDprefs")
  INIaction(a, "OSDastroALTcolor", "OSDprefs")
  INIaction(a, "OSDastroALTOcolor", "OSDprefs")
  INIaction(a, "OSDastralMode", "OSDprefs")
  INIaction(a, "OSDmarginTop", "OSDprefs")
  INIaction(a, "OSDmarginBottom", "OSDprefs")
  INIaction(a, "OSDmarginSides", "OSDprefs")
  INIaction(a, "OSDroundCorners", "OSDprefs")
  INIaction(a, "OverrideOSDcolorsAstro", "OSDprefs")
  INIaction(a, "showOSDprogressBar", "OSDprefs")
  INIaction(a, "makeScreenDark", "SavedSettings")
  INIaction(a, "maxBibleLength", "OSDprefs")
  INIaction(a, "clockFgrColor", "OSDprefs")
  INIaction(a, "clockBgrColor", "OSDprefs")
  INIaction(a, "clockOutColor", "OSDprefs")
  INIaction(a, "transparentAnalogClock", "OSDprefs")
  INIaction(a, "coloredAnalogClockBgr", "OSDprefs")
  INIaction(a, "lockAnalogClockPosition", "OSDprefs")
  INIaction(a, "constantOSDlockPosition", "OSDprefs")
  INIaction(a, "useArabNumeralsAnalogClock", "OSDprefs")
  INIaction(a, "swapColorAnalogClock", "OSDprefs")
  INIaction(a, "analogClockOpacity", "OSDprefs")
  INIaction(a, "OSDalwaysDateShow", "OSDprefs")
  INIaction(a, "OSDlongDateFormat", "OSDprefs")
  INIaction(a, "showTimeWhenIdle", "OSDprefs")
  INIaction(a, "displayTimeFormat", "OSDprefs")
  INIaction(a, "markFullMoonHowls", "OSDprefs")
  If (a=0) ; a=0 means to load from INI
     CheckSettings()
}

BinaryVar(ByRef givenVar, defy) {
    givenVar := (Round(givenVar)=0 || Round(givenVar)=1) ? Round(givenVar) : defy
}

HexyVar(ByRef givenVar, defy) {
   If (givenVar ~= "[^[:xdigit:]]") || (StrLen(givenVar)!=6)
      givenVar := defy
}

MinMaxVar(ByRef givenVar, miny, maxy, defy) {
    testNumber := givenVar
    If (testNumber ~= "i)^(\-[\p{N}])")
       StringReplace, testNumber, testNumber, -

    If testNumber is not digit
    {
       givenVar := defy
       Return
    }

    givenVar := (Round(givenVar) < miny) ? miny : Round(givenVar)
    givenVar := (Round(givenVar) > maxy) ? maxy : Round(givenVar)
}

CheckSettings() {
    if !isNumber(uiUserCountry)
       uiUserCountry := 1
    if !isNumber(uiUserCity)
       uiUserCity := 1

; verify check boxes
    BinaryVar(constantOSDvisible, 0)
    BinaryVar(showMoonPhaseOSD, 0)
    BinaryVar(NoWelcomePopupInfo, 0)
    BinaryVar(userAstroInfodMode, 1)
    BinaryVar(OverrideOSDcolorsAstro, 0)
    BinaryVar(constantAnalogClock, 0)
    BinaryVar(roundedClock, 0)
    BinaryVar(PrefsLargeFonts, 0)
    BinaryVar(allowDSTchanges, 1)
    BinaryVar(allowAltitudeSolarChanges, 1)
    BinaryVar(tollQuartersException, 0)
    BinaryVar(tollQuarters, 1)
    BinaryVar(tollNoon, 1)
    BinaryVar(tollHours, 1)
    BinaryVar(tollHoursAmount, 1)
    BinaryVar(userAlarmRepeated, 0)
    BinaryVar(displayClock, 1)
    BinaryVar(AutoUnmute, 1)
    BinaryVar(tickTockNoise, 0)
    BinaryVar(DynamicVolume, 1)
    BinaryVar(AdditionalStrikes, 0)
    BinaryVar(showBibleQuotes, 0)
    BinaryVar(makeScreenDark, 1)
    BinaryVar(noTollingWhenMhidden, 0)
    BinaryVar(noTollingWhenLocked, 0)
    BinaryVar(noBibleQuoteMhidden, 1)
    BinaryVar(markFullMoonHowls, 0)
    BinaryVar(SemantronHoliday, 0)
    BinaryVar(ObserveHolidays, 0)
    BinaryVar(ObserveReligiousDays, 1)
    BinaryVar(ObserveSecularDays, 1)
    BinaryVar(PreferSecularDays, 0)
    BinaryVar(showTimeWhenIdle, 0)
    BinaryVar(OSDroundCorners, 1)
    BinaryVar(userMuteAllSounds, 0)
    BinaryVar(userMustDoAlarm, 0)
    BinaryVar(userMustDoTimer, 0)
    BinaryVar(stopWatchDoBeeps, 0)
    BinaryVar(orderedBibleQuotes, 0)
    BinaryVar(AlarmersDarkScreen, 1)
    BinaryVar(showAnalogHourLabels, 1)
    BinaryVar(gongAudioVerseDisplay, 1)
    BinaryVar(swapColorAnalogClock, 0)
    BinaryVar(transparentAnalogClock, 0)
    BinaryVar(coloredAnalogClockBgr, 1)
    BinaryVar(lockAnalogClockPosition, 0)
    BinaryVar(constantOSDlockPosition, 0)
    BinaryVar(useArabNumeralsAnalogClock, 0)
    BinaryVar(OSDalwaysDateShow, 0)
    BinaryVar(OSDlongDateFormat, 1)

; verify numeric values: min, max and default values
    analogClockScale := nearestAnalogClockScale(analogClockScale)

    MinMaxVar(DisplayTimeUser, 1, 99, 3)
    MinMaxVar(FontSize, 12, 300, 26)
    MinMaxVar(FontSizeQuotes, 10, 201, 20)
    MinMaxVar(GuiX, -9999, 9999, 40)
    MinMaxVar(GuiY, -9999, 9999, 250)
    MinMaxVar(ClockGuiX, -9999, 9999, 40)
    MinMaxVar(ClockGuiY, -9999, 9999, 250)
    MinMaxVar(OSDmarginTop, 1, 900, 20)
    MinMaxVar(OSDmarginBottom, 1, 900, 20)
    MinMaxVar(OSDmarginSides, 10, 900, 25)
    MinMaxVar(BeepsVolume, 0, 99, 45)
    MinMaxVar(strikeEveryMin, 1, 720, 5)
    MinMaxVar(silentHours, 1, 3, 1)
    MinMaxVar(silentHoursA, 0, 23, 12)
    MinMaxVar(silentHoursB, 0, 23, 14)
    MinMaxVar(LastNoonAudio, 1, 4, 2)
    MinMaxVar(showTimeIdleAfter, 1, 950, 5)
    MinMaxVar(LargeUIfontValue, 10, 18, 13)
    MinMaxVar(UserReligion, 1, 2, 1)
    MinMaxVar(strikeInterval, 900, 5500, 2000)
    MinMaxVar(BibleQuotesInterval, 1, 12, 5)
    MinMaxVar(maxBibleLength, 20, 130, 55)
    MinMaxVar(noTollingBgrSounds, 1, 3, 1)
    MinMaxVar(OSDalpha, 75, 255, 230)
    MinMaxVar(userAlarmSnooze, 1, 59, 5)
    MinMaxVar(userAlarmSound, 1, 6, 5)
    MinMaxVar(userTimerSound, 1, 6, 5)
    MinMaxVar(userAlarmMins, 0, 59, 30)
    MinMaxVar(userAlarmHours, 0, 23, 12)
    MinMaxVar(userTimerMins, 0, 59, 2)
    MinMaxVar(userTimerFreq, 1, 99, 2)
    MinMaxVar(userAlarmFreq, 1, 99, 4)
    MinMaxVar(showOSDprogressBar, 1, 6, 2)
    MinMaxVar(OSDastralMode, 1, 4, 1)
    MinMaxVar(analogMoonPhases, 0, 2, 0)
    MinMaxVar(analogClockOpacity, 70, 254, 230)
    If (ObserveHolidays=0)
       SemantronHoliday := 0

; verify HEX values
   HexyVar(OSDbgrColor, "131209")
   HexyVar(OSDtextColor, "FFFEFA")
   HexyVar(OSDastroALTcolor, "106699")
   HexyVar(OSDastroALTOcolor, "006612")
   HexyVar(clockBgrColor, "eeEEee")
   HexyVar(clockFgrColor, "111111")
   HexyVar(clockOutColor, "222222")

; verify other values
   FontName := (StrLen(FontName)>2) ? FontName
             : (A_OSVersion="WIN_XP") ? "Lucida Sans Unicode" : "Arial"
}

;================================================================
; Functions not written by Marius Sucan.
; Here, I placed only the functions I was unable to decide
; where to place within the code structure. Yet, they had 
; one thing in common: written by other people.
;
; Please note, some of the functions borrowed may or may not
; be modified/adapted/transformed by Marius Șucan or other people.
;================================================================
; Functions by Drugwash. Direct contribuitor to this script. Many thanks!
; ===============================================================

Cleanup() {
    sillySoundHack()
    OnMessage(0x4a, "")
    OnMessage(0x200, "")
    OnMessage(0x102, "")
    OnMessage(0x103, "")
    DllCall("wtsapi32\WTSUnRegisterSessionNotification", "Ptr", A_ScriptHwnd)
    DllCall("kernel32\FreeLibrary", "Ptr", hWinMM)
    Fnt_DeleteFont(hFont)
    Sleep, 5
}
; ------------------------------------------------------------- ; from Drugwash

;================================================================
; The following functions were extracted from Font Library 3.0 for AHK
; ===============================================================

Fnt_SetFont(hControl,hFont:="",p_Redraw:=False) {
    Static Dummy30050039
          ,DEFAULT_GUI_FONT:= 17
          ,OBJ_FONT        := 6
          ,WM_SETFONT      := 0x30

    ;-- If needed, get the handle to the default GUI font
    If (DllCall("gdi32\GetObjectType","Ptr",hFont)<>OBJ_FONT)
        hFont:=DllCall("gdi32\GetStockObject","Int",DEFAULT_GUI_FONT)

    ;-- Set font
    SendMessage WM_SETFONT,hFont,p_Redraw,,ahk_id %hControl%
}

Fnt_CreateFont(p_Name:="",p_Options:="") {
    Static Dummy34361446

          ;-- Misc. font constants
          ,LOGPIXELSY:=90
          ,CLIP_DEFAULT_PRECIS:=0
          ,DEFAULT_CHARSET    :=1
          ,DEFAULT_GUI_FONT   :=17
          ,OUT_TT_PRECIS      :=4

          ;-- Font family
          ,FF_DONTCARE  :=0x0
          ,FF_ROMAN     :=0x1
          ,FF_SWISS     :=0x2
          ,FF_MODERN    :=0x3
          ,FF_SCRIPT    :=0x4
          ,FF_DECORATIVE:=0x5

          ;-- Font pitch
          ,DEFAULT_PITCH :=0
          ,FIXED_PITCH   :=1
          ,VARIABLE_PITCH:=2

          ;-- Font quality
          ,DEFAULT_QUALITY       :=0
          ,DRAFT_QUALITY         :=1
          ,PROOF_QUALITY         :=2  ;-- AutoHotkey default
          ,NONANTIALIASED_QUALITY:=3
          ,ANTIALIASED_QUALITY   :=4
          ,CLEARTYPE_QUALITY     :=5

          ;-- Font weight
          ,FW_DONTCARE:=0
          ,FW_NORMAL  :=400
          ,FW_BOLD    :=700

    ;-- Parameters
    ;   Remove all leading/trailing white space
    p_Name   :=Trim(p_Name," `f`n`r`t`v")
    p_Options:=Trim(p_Options," `f`n`r`t`v")

    ;-- If both parameters are null or unspecified, return the handle to the
    ;   default GUI font.
    If (p_Name="" and p_Options="")
    {
       Result := DllCall("gdi32\GetStockObject","Int",DEFAULT_GUI_FONT)
       Return Result
    }
    ;-- Initialize options
    o_Height   :=""             ;-- Undefined
    o_Italic   :=False
    o_Quality  :=PROOF_QUALITY  ;-- AutoHotkey default
    o_Size     :=""             ;-- Undefined
    o_Strikeout:=False
    o_Underline:=False
    o_Weight   :=FW_DONTCARE

    ;-- Extract options (if any) from p_Options
    Loop Parse,p_Options,%A_Space%
        {
        If A_LoopField is Space
            Continue

        If (SubStr(A_LoopField,1,4)="bold")
            o_Weight:=FW_BOLD
        Else If (SubStr(A_LoopField,1,6)="italic")
            o_Italic:=True
        Else If (SubStr(A_LoopField,1,4)="norm")
            {
            o_Italic   :=False
            o_Strikeout:=False
            o_Underline:=False
            o_Weight   :=FW_DONTCARE
            }
        Else If (A_LoopField="-s")
            o_Size:=0
        Else If (SubStr(A_LoopField,1,6)="strike")
            o_Strikeout:=True
        Else If (SubStr(A_LoopField,1,9)="underline")
            o_Underline:=True
        Else If (SubStr(A_LoopField,1,1)="h")
            {
            o_Height:=SubStr(A_LoopField,2)
            o_Size  :=""  ;-- Undefined
            }
        Else If (SubStr(A_LoopField,1,1)="q")
            o_Quality:=SubStr(A_LoopField,2)
        Else If (SubStr(A_LoopField,1,1)="s")
            {
            o_Size  :=SubStr(A_LoopField,2)
            o_Height:=""  ;-- Undefined
            }
        Else If (SubStr(A_LoopField,1,1)="w")
            o_Weight:=SubStr(A_LoopField,2)
        }

    ;-- Convert/Fix invalid or
    ;-- unspecified parameters/options
    If p_Name is Space
        p_Name:=Fnt_GetFontName()   ;-- Font name of the default GUI font

    If o_Height is not Integer
        o_Height:=""                ;-- Undefined

    If o_Quality is not Integer
        o_Quality:=PROOF_QUALITY    ;-- AutoHotkey default

    If o_Size is Space              ;-- Undefined
        o_Size:=Fnt_GetFontSize()   ;-- Font size of the default GUI font
     Else
        If o_Size is not Integer
            o_Size:=""              ;-- Undefined
         Else
            If (o_Size=0)
                o_Size:=""          ;-- Undefined

    If o_Weight is not Integer
        o_Weight:=FW_DONTCARE       ;-- A font with a default weight is created

    ;-- If needed, convert point size to em height
    If o_Height is Space        ;-- Undefined
        If o_Size is Integer    ;-- Allows for a negative size (emulates AutoHotkey)
            {
            hDC:=DllCall("gdi32\CreateDCW","Str","DISPLAY","Ptr",0,"Ptr",0,"Ptr",0)
            o_Height:=-Round(o_Size*DllCall("gdi32\GetDeviceCaps","Ptr",hDC,"Int",LOGPIXELSY)/72)
            DllCall("gdi32\DeleteDC","Ptr",hDC)
            }

    If o_Height is not Integer
        o_Height:=0                 ;-- A font with a default height is created

    ;-- Create font
    hFont:=DllCall("gdi32\CreateFontW"
        ,"Int",o_Height                                 ;-- nHeight
        ,"Int",0                                        ;-- nWidth
        ,"Int",0                                        ;-- nEscapement (0=normal horizontal)
        ,"Int",0                                        ;-- nOrientation
        ,"Int",o_Weight                                 ;-- fnWeight
        ,"UInt",o_Italic                                ;-- fdwItalic
        ,"UInt",o_Underline                             ;-- fdwUnderline
        ,"UInt",o_Strikeout                             ;-- fdwStrikeOut
        ,"UInt",DEFAULT_CHARSET                         ;-- fdwCharSet
        ,"UInt",OUT_TT_PRECIS                           ;-- fdwOutputPrecision
        ,"UInt",CLIP_DEFAULT_PRECIS                     ;-- fdwClipPrecision
        ,"UInt",o_Quality                               ;-- fdwQuality
        ,"UInt",(FF_DONTCARE<<4)|DEFAULT_PITCH          ;-- fdwPitchAndFamily
        ,"Str",SubStr(p_Name,1,31))                     ;-- lpszFace

    Return hFont
}

Fnt_DeleteFont(hFont) {
    If !hFont  ;-- Zero or null
       Return 1

    Result := DllCall("gdi32\DeleteObject","Ptr",hFont) ? 1 : 1
    Return Result
}

Fnt_GetFontName(hFont:="") {
    Static Dummy87890484
          ,DEFAULT_GUI_FONT    :=17
          ,HWND_DESKTOP        :=0
          ,OBJ_FONT            :=6
          ,MAX_FONT_NAME_LENGTH:=32     ;-- In TCHARS

    ;-- If needed, get the handle to the default GUI font
    If (DllCall("gdi32\GetObjectType","Ptr",hFont)<>OBJ_FONT)
        hFont:=DllCall("gdi32\GetStockObject","Int",DEFAULT_GUI_FONT)

    ;-- Select the font into the device context for the desktop
    hDC      :=DllCall("user32\GetDC","Ptr",HWND_DESKTOP)
    old_hFont:=DllCall("gdi32\SelectObject","Ptr",hDC,"Ptr",hFont)

    ;-- Get the font name
    VarSetCapacity(l_FontName,MAX_FONT_NAME_LENGTH*(A_IsUnicode ? 2:1))
    DllCall("gdi32\GetTextFaceW","Ptr",hDC,"Int",MAX_FONT_NAME_LENGTH,"Str",l_FontName)

    ;-- Release the objects needed by the GetTextFace function
    DllCall("gdi32\SelectObject","Ptr",hDC,"Ptr",old_hFont)
        ;-- Necessary to avoid memory leak

    DllCall("user32\ReleaseDC","Ptr",HWND_DESKTOP,"Ptr",hDC)
    Return l_FontName
}

Fnt_GetFontSize(hFont:="") {
    Static Dummy64998752

          ;-- Device constants
          ,HWND_DESKTOP:=0
          ,LOGPIXELSY  :=90

          ;-- Misc.
          ,DEFAULT_GUI_FONT:=17
          ,OBJ_FONT        :=6

    ;-- If needed, get the handle to the default GUI font
    If (DllCall("gdi32\GetObjectType","Ptr",hFont)<>OBJ_FONT)
        hFont:=DllCall("gdi32\GetStockObject","Int",DEFAULT_GUI_FONT)

    ;-- Select the font into the device context for the desktop
    hDC      :=DllCall("user32\GetDC","Ptr",HWND_DESKTOP)
    old_hFont:=DllCall("gdi32\SelectObject","Ptr",hDC,"Ptr",hFont)

    ;-- Collect the number of pixels per logical inch along the screen height
    l_LogPixelsY:=DllCall("gdi32\GetDeviceCaps","Ptr",hDC,"Int",LOGPIXELSY)

    ;-- Get text metrics for the font
    VarSetCapacity(TEXTMETRIC,A_IsUnicode ? 60:56,0)
    DllCall("gdi32\GetTextMetricsW","Ptr",hDC,"Ptr",&TEXTMETRIC)

    ;-- Convert em height to point size
    l_Size:=Round((NumGet(TEXTMETRIC,0,"Int")-NumGet(TEXTMETRIC,12,"Int"))*72/l_LogPixelsY)
        ;-- (Height - Internal Leading) * 72 / LogPixelsY

    ;-- Release the objects needed by the GetTextMetrics function
    DllCall("gdi32\SelectObject","Ptr",hDC,"Ptr",old_hFont)
        ;-- Necessary to avoid memory leak

    DllCall("user32\ReleaseDC","Ptr",HWND_DESKTOP,"Ptr",hDC)
    Return l_Size
}

Fnt_GetListOfFonts() {
; function stripped down from Font Library 3.0 by jballi
; from https://autohotkey.com/boards/viewtopic.php?t=4379

    Static Dummy65612414
          ,HWND_DESKTOP := 0  ;-- Device constants
          ,LF_FACESIZE := 32  ;-- In TCHARS - LOGFONT constants

    ;-- Initialize and populate LOGFONT structure
    Fnt_EnumFontFamExProc_List := ""
    p_CharSet := 1
    p_Flags := 0x800
    VarSetCapacity(LOGFONT,A_IsUnicode ? 92:60,0)
    NumPut(p_CharSet,LOGFONT,23,"UChar")                ;-- lfCharSet

    ;-- Enumerate fonts
    EFFEP := RegisterCallback("Fnt_EnumFontFamExProc","F")
    hDC := DllCall("user32\GetDC","Ptr",HWND_DESKTOP)
    DllCall("gdi32\EnumFontFamiliesExW"
        ,"Ptr", hDC                                      ;-- hdc
        ,"Ptr", &LOGFONT                                 ;-- lpLogfont
        ,"Ptr", EFFEP                                    ;-- lpEnumFontFamExProc
        ,"Ptr", p_Flags                                  ;-- lParam
        ,"UInt", 0)                                      ;-- dwFlags (must be 0)

    DllCall("user32\ReleaseDC","Ptr",HWND_DESKTOP,"Ptr",hDC)
    DllCall("GlobalFree", "Ptr", EFFEP)
    Return Fnt_EnumFontFamExProc_List
}

Fnt_EnumFontFamExProc(lpelfe,lpntme,FontType,p_Flags) {
    Fnt_EnumFontFamExProc_List := 0
    Static Dummy62479817
           ,LF_FACESIZE := 32  ;-- In TCHARS - LOGFONT constants

    l_FaceName := StrGet(lpelfe+28,LF_FACESIZE)
    FontList.Push(l_FaceName)    ;-- Append the font name to the list
    Return 1  ;-- Continue enumeration
}
; ------------------------------------------------------------- ; Font Library

SoundLoop(File := "") {
; from https://autohotkey.com/boards/viewtopic.php?t=680
; by just me

   ; http://msdn.microsoft.com/en-us/library/dd743680(v=vs.85).aspx
   ; SND_ASYNC       0x00000001  /* play asynchronously */
   ; SND_NODEFAULT   0x00000002  /* silence (!default) if sound not found */
   ; SND_LOOP        0x00000008  /* loop the sound until next sndPlaySound */
   ; SND_NOWAIT      0x00002000  /* don't wait if the driver is busy */
   ; SND_FILENAME    0x00020000  /* name is file name */
   ; --------------- 0x0002200B
   Static AW := A_IsUnicode ? "W" : "A"
   Result := DllCall("Winmm.dll\PlaySound" . AW, "Ptr", File = "" ? 0 : &File, "Ptr", 0, "UInt", 0x0002200B)
   Return Result 
}

dummy() {
  Sleep, 1
}

sillySoundHack() {   ; this helps mitigate issues caused by apps like Team Viewer
     Sleep, 2
     SoundPlay, non-existent.lol
     SoundBeep, 0, 1
     Result := DllCall("winmm\PlaySoundW", "Ptr", 0, "Ptr", 0, "Uint", 0x46) ; SND_PURGE|SND_MEMORY|SND_NODEFAULT
     Return Result
}

wrapGetLockedState() {
   Static lastState := 0, lastInvoked := 1

   if (A_TickCount - lastInvoked>9500)
   {
      lastInvoked := A_TickCount
      lastState := isSystemLocked()
      ; ToolTip, % "s=" lastState , , , 2
   }

   return lastState
}

isSystemLocked() {
   hDesk := DllCall("User32\OpenInputDesktop","int",0,"int",0,"int",0x0001L)
   if !hDesk
      return 1 

   VarSetCapacity(name, 2048, 0)
   zk := DllCall("User32\GetUserObjectInformation","uptr", hDesk, "int", 2, "uptr", &name, "uint", 2048, "uint*", needed)
   pn := StrGet(&name, "utf-16")
   ck := DllCall("User32\CloseDesktop","uptr", hDesk)
   If (pn!="default")
      return 1

   ; ToolTip, % hdesk "|" ck "|" zk "|" needed "|" pn , , , 2
   name := ""
   MouseGetPos, , , winu, OutputVarControl, 1
   WinGetTitle, titlu, ahk_id %winu%
   ; WinGet, procName, ProcessName, ahk_id %winu%
   WinGet, procPath, ProcessPath, ahk_id %winu%
   ; fnOutputDebug(A_ComputerName "|" A_UserName "|" WinActive("A") "|" winu "|" titlu "|" classu "|" procName "|" procPath)
   If (InStr(procPath, "Microsoft.LockApp") || titlu="Backstop window")
      return 1

   return 0
}

checkMcursorState() {
; thanks to Drugwash
; modified a lot by Marius Șucan

    Static lastCalc := 1
    If (A_TickCount-lastCalc<1000) || (PrefOpen=1) || A_IsSuspended || (noTollingWhenMhidden=0 && noBibleQuoteMhidden=0 && showTimeWhenIdle=0)
       Return

    mouseVisState := 0
    VarSetCapacity(CI, sz:=16+A_PtrSize, 0)
    z := NumPut(sz, CI, 0, "UInt")
    r := DllCall("user32\GetCursorInfo", "Ptr", &CI) ; get cursor info
    mouseVisState := NumGet(CI, 4, "UInt")
    hpCursor := NumGet(CI, 8, "Ptr")
    If (StrLen(hpCursor)>8 || hpCursor<100 || !InStr(hpCursor, "655"))
       mouseVisState := 0

    mouseVisState := !mouseVisState
    If (strikingBellsNow=1 && mouseVisState=1)
       stopStrikesNow := 1

    ; ToolTip, %mouseVisState% - %hpCursor% - %r% - %z%
    lastCalc := A_TickCount
    Return mouseVisState
}

isSoundPlayingNow(looped:=0) {
; source: https://autohotkey.com/board/topic/21984-vista-audio-control-functions/
  If (A_OSVersion="WIN_XP" || A_OSVersion="WIN_2000")
     Return

  If (tickTockNoise=1)
     SoundLoop("")

  cutVolumeHalf := 0
  audioMeter := VA_GetAudioMeter()
  VA_IAudioMeterInformation_GetMeteringChannelCount(audioMeter, channelCount)

  ; "The peak value for each channel is recorded over one device
  ;  period and made available during the subsequent device period."
  VA_GetDevicePeriod("capture", devicePeriod)
  c := 0
  Loop, 5
  {
      ; Get the peak value across all channels.
      VA_IAudioMeterInformation_GetPeakValue(audioMeter, peakValue)    
            
      ; Get the peak values of all channels.
      VarSetCapacity(peakValues, channelCount*4)
      VA_IAudioMeterInformation_GetChannelsPeakValues(audioMeter, channelCount, &peakValues)
      a := b := 0
      Loop, %channelCount%
      {
          a := NumGet(peakValues, A_Index*4-4, "float") * 50
          b := Round(a, 2) + b
      }
      c := Round(b + c, 2)
      Sleep, % devicePeriod * 10
  }

  ; If (looped=0 && c>0 && ScriptInitialized=1)
  ;    SetTimer, dummyDoLoopisSoundPlayingNow, -1500

  If (c>1 && noTollingBgrSounds=2)
     cutVolumeHalf := 1
  Else If (c>1 && noTollingBgrSounds=3)
     stopAdditionalStrikez := 1
  
  If (tickTockNoise=1 && userMuteAllSounds!=1)
     SoundLoop(tickTockSound)
  ; ToolTip, %b% - %c%
  If (c>1)
     Return 1
  Else
     Return 0
}

dummyDoLoopisSoundPlayingNow() {
   isSoundPlayingNow(1)
}

TZI_GetTimeZoneInformation(y:=0, gyd:=0) {
   ; source https://gist.github.com/hoppfrosch/6882628
   ; and  https://www.autohotkey.com/board/topic/68856-sample-dealing-with-time-zones-ahk-l/

   ; GetTimeZoneInformationForYear -> msdn.microsoft.com/en-us/library/bb540851(v=vs.85).aspx (Win Vista+)
   ; cmd.exe w32tm /tz

   Year := y ? y : A_Year
   gyd := gyd ? gyd : A_YDay
   VarSetCapacity(TZI, 172, 0)
   If !DllCall("GetTimeZoneInformationForYear", "UShort", Year, "Ptr", 0, "Ptr", &TZI, "Int")
   {
      TZI := ""
      Return 0
   }

   R := []
   R.Bias := NumGet(TZI, "Int")
   R.StandardName := StrGet(&TZI + 4, 32, "UTF-16")
   ST := New TZI_SYSTEMTIME(&TZI + 68) ; Calculate StandardDate TimeStamp
   ; If ST.Year is not zero the date is fix. Otherwise, the date is variable and must be calculated.
   ; ST.WDay contains the weekday and ST.Day the occurrence within ST.Month (5 = last) in this case.
   If (ST.Year = 0) { 
      ST.Year := Year
      ST.Day := TZI_GetWDayInMonth(ST.Year, ST.Month, ST.WDay, ST.Day)
   }

   R.StandardDate := ST.TimeStamp
   FormatTime, yd, % ST.TimeStamp, Yday
   R.StandardDateYday := yd
   R.StandardBias := NumGet(TZI, 84, "Int")
   R.DaylightName := StrGet(&TZI + 88, 32, "UTF-16")
   ST := New TZI_SYSTEMTIME(&TZI + 152)  ; Calculate DaylightDate TimeStamp
   If (ST.Year = 0) {
      ST.Year := Year
      ST.Day := TZI_GetWDayInMonth(ST.Year, ST.Month, ST.WDay, ST.Day)
   }
   R.DaylightDate := ST.TimeStamp
   FormatTime, yd, % ST.TimeStamp, Yday
   R.DaylightDateYday := yd
   R.DaylightBias := NumGet(TZI, 168, "Int")
   ; Calculate the UTC values for StandardDate and DaylightDate
   UTCBias := R.Bias + R.DaylightBias ; StandardDate
   UTCDate := R.StandardDate
   UTCDate += UTCBias, M
   R.StandardDateUTC := UTCDate
   UTCBias := R.Bias + R.StandardBias ; DaylightDate
   UTCDate := R.DaylightDate
   UTCDate += UTCBias, M
   R.DaylightDateUTC := UTCDate
   R.isDST := isInDSTperiod(gyd, R.DaylightDateYday, R.StandardDateYday) ? 1 : 0
   R.TotalCurrentBias := (R.isDST) ? R.Bias + R.DaylightBias + R.StandardBias : R.Bias + R.StandardBias
   ; ToolTip, % R.TotalCurrentBias "`n" R.StandardDateYday "==" R.StandardDate "`n" R.DaylightDateYday "==" R.DaylightDateUTC "`n" R.StandardName "=" NumGet(TZI, 84, "Int") "==" NumGet(TZI, 168, "Int") , , , 2
   Return R
}

TZI_GetWDayInMonth(Year, Month, WDay, Occurence) {
   YearMonth := Format("{:04}{:02}01", Year, Month) ; bugfix
   If YearMonth Is Not Date
      Return 0
   If WDay Not Between 1 And 7
      Return 0
   If Occurence Not Between 1 And 5 ; 5 = last occurence
      Return 0
   FormatTime, WD, %YearMonth%, WDay
   While (WD <> WDay) {
      YearMonth += 1, D
      FormatTime, WD, %YearMonth%, WDay
   }
   While (A_Index <= Occurence) && (SubStr(YearMonth, 5, 2) = Month) {
      Day := SubStr(YearMonth, 7, 2)
      YearMonth += 7, D
   }
   Return Day
}
; ----------------------------------------------------------------------------------------------------------------------------------
Class TZI_SYSTEMTIME {
   __New(Pointer) { ; a pointer to a SYSTEMTIME structure
      This.Year  := NumGet(Pointer + 0, "Short")
      This.Month := NumGet(Pointer + 2, "Short")
      This.WDay  := NumGet(Pointer + 4, "Short") + 1 ; DayOfWeek is 0 (Sunday) thru 6 (Saturday) in the SYSTEMTIME structure
      This.Day   := NumGet(Pointer + 6, "Short")
      This.Hour  := NumGet(Pointer + 8, "Short")
      This.Min   := NumGet(Pointer + 10, "Short")
      This.Sec   := NumGet(Pointer + 12, "Short")
      This.MSec  := NumGet(Pointer + 14, "Short")
   }
   TimeStamp[] { ; TimeStamp YYYYMMDDHH24MISS
      Get {
         Return Format("{:04}{:02}{:02}{:02}{:02}{:02}", This.Year, This.Month, This.Day, This.Hour, This.Min, This.Sec)
      }
      Set {
         Return ""
      }
   }
}

MoonPhaseCalculator(t:=0, gmtOffset:=0, latu:=0, longu:=0) {
  Static phaseNames := {1:"New moon", 2:"Waxing Crescent", 3:"First Quarter"
           , 4: "Waxing Gibbous", 5:"Full moon", 6:"Waning Gibbous"
           , 7:"Last Quarter", 8:"Waning Crescent"}

  If !initCBTdll()
     Return

  If !t
     t := A_NowUTC

  ot := t
  If gmtOffset
     t += -1*gmtOffset, Hours

  t -= 19700101000000, S   ; convert to Unix TimeStamp
  IDphase := azimuth := eleva := latitude := longitude := age := phase := fraction := ""
  r := DllCall(callCBTdllFunc("getMoonPhase"), "double", t, "double", latu, "double", longu, "double*", phase, "int*", IDphase, "double*", age, "double*", fraction, "double*", latitude, "double*", longitude, "double*", azimuth, "double*", eleva, "Int")
  If !r 
  {
     fnOutputDebug("dll failed - calculating moon phase with ahk")
     Return r
  }

  ; The DLL names the phase off the true elongation of the moon from the sun now,
  ; which is what defines new moon, the quarters and full moon in the first place.
  IDphase++
  phaseName := phaseNames[IDphase]
  ; ToolTip, % fraction "|" IDphase "|" age , , , 2
  ; fnOutputDebug(IDphase "|" phaseName "|" fraction, 1)
  Return [phaseName, IDphase, phase, fraction/100, age, azimuth, eleva]
}

oldMoonPhaseCalculator(t:=0, gmtOffset:=0, calcDetails:=0) {
; Calculate the phase and position of the moon for a given date.
; The algorithm is simple and adequate for many purposes.
;
; This software was originally adapted to Javascript by Stephen R. Schmitt
; from a BASIC program from the 'Astronomical Computing' column of Sky & Telescope,
; April 1994, page 86, written by Bradley E. Schaefer.
;
; Subsequently adapted from Stephen R. Schmitt's Javascript to C++ for the Arduino
; by Cyrus Rahman.
;
; This work is/was subjected to Stephen Schmitt's copyright:
; Copyright 2004 Stephen R. Schmitt
; You may use or modify this source code in any way you find useful, provided
; that you agree that the author(s) have no warranty, obligations or liability.  You
; must determine the suitability of this source code for your use.
;
; source https://github.com/signetica/MoonPhase

  Static phaseNames := {1:"New moon", 2:"Waxing Crescent", 3:"First Quarter"
           , 4: "Waxing Gibbous", 5:"Full moon", 6:"Waning Gibbous"
           , 7:"Last Quarter", 8:"Waning Crescent"}
       , zodiacNames := {0:"Pisces", 1:"Pisces", 2:"Aries", 3:"Taurus", 4:"Gemini", 5:"Cancer", 6:"Leo"
                       , 7:"Virgo", 8:"Libra", 9:"Scorpio", 10:"Sagittarius", 11:"Capricorn", 12:"Aquarius"}

  If !initCBTdll()
     Return

  If (t="now" || !t)
     t := A_NowUTC

  ot := t
  If gmtOffset
     t += gmtOffset, Hours

  t -= 19700101000000, S   ; convert to Unix TimeStamp
  zdc := latitude := longitude := age := phase := fraction := ""
  r := DllCall(callCBTdllFunc("oldgetMoonPhase"), "double", t, "Int", 1, "double*", phase, "int*", IDphase, "double*", age, "double*", fraction, "double*", latitude, "double*", longitude, "int*", zdc, "Int")
  If !r 
  {
     fnOutputDebug("DLL failed - calculating moon phase with ahk")
     Return r
  }

  zodiac := zodiacNames[zdc + 1]
  If !zodiac
     zodiac := zodiacNames[0]

  IDphase++
  phaseName := phaseNames[IDphase]
  Return [phaseName, IDphase, phase, fraction, age, zodiac, latitude, longitude]
}

MixARGB(color1, color2, t := 0.5, gamma := 1) {
   rgamma := 1/gamma
   a1 := (color1 >> 24) & 0xff,  r1 := (color1 >> 16) & 0xff,  g1 := (color1 >>  8) & 0xff,  b1 := (color1 >>  0) & 0xff
   a2 := (color2 >> 24) & 0xff,  r2 := (color2 >> 16) & 0xff,  g2 := (color2 >>  8) & 0xff,  b2 := (color2 >>  0) & 0xff
   
   ga1 := (a1 / 255) ** gamma,   gr1 := (r1 / 255) ** gamma,   gg1 := (g1 / 255) ** gamma,   gb1 := (b1 / 255) ** gamma
   ga2 := (a2 / 255) ** gamma,   gr2 := (r2 / 255) ** gamma,   gg2 := (g2 / 255) ** gamma,   gb2 := (b2 / 255) ** gamma
   
   ma := ga1 * (1-t) + ga2 * t,  mr := gr1 * (1-t) + gr2 * t,  mg := gg1 * (1-t) + gg2 * t,  mb := gb1 * (1-t) + gb2 * t
   mga := 255 * (ma ** rgamma),  mgr := 255 * (mr ** rgamma),  mgg := 255 * (mg ** rgamma),  mgb := 255 * (mb ** rgamma)

   thisColor := Gdip_ToARGB(mga, mgr, mgg, mgb)
   Return thisColor := Format("{1:#x}", thisColor)
}

decideFadeColor(coloru) {
  newColor := MixRGB(coloru, OSDtextColor, 0.5)
  Return newColor
}

mouseTurnOFFtooltip() {
   Gui, mouseToolTipGuia: Destroy
   mouseToolTipWinCreated := 0
}

EM_SETCUEBANNER(handle, string, option := true) {
; ===============================================================================================================================
; Message ..................:  EM_SETCUEBANNER
; Minimum supported client .:  Windows Vista
; Minimum supported server .:  Windows Server 2003
; Links ....................:  https://docs.microsoft.com/en-us/windows/win32/controls/em-setcuebanner
; Description ..............:  Sets the textual cue, or tip, that is displayed by the edit control to prompt the user for information.
; Options ..................:  True  -> if the cue banner should show even when the edit control has focus
;                              False -> if the cue banner disappears when the user clicks in the control
; ===============================================================================================================================
   static ECM_FIRST       := 0x1500 
        , EM_SETCUEBANNER := ECM_FIRST + 1
   if (DllCall("user32\SendMessage", "ptr", handle, "uint", EM_SETCUEBANNER, "int", option, "str", string, "int"))
      return 1
   return 0
}

GuiAddButton(options, uiLabel, readerLabel, ttipu:=0, guiu:="SettingsGUIA") {
    Gui, %guiu%: Add, Button, % options " +0x8000 +hwndhTemp", % readerLabel
    SetImgButtonStyle(hTemp, uiLabel)
    p := ttipu ? ttipu : readerLabel
    ToolTip2ctrl(hTemp, p)
    Return hTemp
}

GuiAddColor(options, colorReference, labelu:=0, guiu:="SettingsGUIA") {
    realColor := %colorReference%
    p := labelu ? labelu : "Color."
    If (isWinXP=1)
       Gui, %guiu%: Add, Text, % options " v" colorReference A_Space " +hwndhTemp gInvokeSetNewColor +TabStop +0xE", %p% Invoke color picker.
    Else
       Gui, %guiu%: Add, Button, % options " +0x8000 v" colorReference A_Space " +hwndhTemp gInvokeSetNewColor", %p% Invoke color picker.

    updateColoredRectCtrl(realColor, colorReference, guiu, hTemp)
    p := labelu ? labelu : "Define color"
    ToolTip2ctrl(hTemp, p)
    Return hTemp
}

updateColoredRectCtrl(coloru, varu, guiu:="SettingsGUIA", clrHwnd:=0) {
    If !clrHwnd
       GuiControlGet, clrHwnd, %guiu%: hwnd, %varu%
    If !clrHwnd
       Return 0

    If (isWinXP=1)
       Return oldupdateColoredRectCtrl(coloru, clrHwnd)

    copt1 := [0, "0xFF" coloru, "0xFF" coloru,,,, "0xFF999999", 1, 0] ; normal
    copt2 := [0, "0xFF" coloru, "0xFF" coloru,,,, "0xffaaAAaa", 3, 0] ; hover
    copt3 := [0, "0xFF" coloru, "0xFF" coloru,,,, "0xFF777777", 4, 0] ; clicked
    copt4 := [0, "0xFF" coloru, "0xFF" coloru,,,, "0xFF999999", 2, 0] ; disabled
    copt5 := [0, "0xFF" coloru, "0xFF" coloru,,,, "0xff999999", 4, 0] ; active/focused
    r := ImageButton.Create(clrHwnd, copt1, copt2, copt3, copt4, copt5)
    If (r!="")
       trackImageListButtons("record", r)

    ; ToolTip, % r "|" coloru "|" hwnd  , , , 2
    Return r
}


GuiAddCheckBox(options, readerLabel, uiLabel, guiu:="SettingsGUIA", ttip:=0) {
    Gui, %guiu%: Add, Checkbox, % options " +hwndhTemp +0x1000 +0x8000", % readerLabel
    SetImgButtonStyle(hTemp, uiLabel, 1)
    thisu := ttip ? ttip : readerLabel
    ToolTip2ctrl(hTemp, thisu)
}

oldupdateColoredRectCtrl(coloru, clrHwnd) {
    If !clrHwnd
       Return 0

    z := GetWindowPlacement(clrHwnd)
    If (z=0)
       Return 0

    pBitmap := Gdip_CreateBitmap(z.w, z.h)
    G := Gdip_GraphicsFromImage(pBitmap)
    Gdip_GraphicsClear(G, "0xff" coloru)
    Gdip_SetPbitmapCtrl(clrHwnd, pBitmap)
    Gdip_DeleteGraphics(G)
    Gdip_DisposeImage(pBitmap)
    ; ToolTip, % z.w "|" z.h "|" coloru "|" hwnd  , , , 2
    Return 1
}

GuiAddEdit(options, defaultu, labelu:="", guiu:="SettingsGUIA") {
    If labelu
    {
       posu := ""
       nopt := A_Space options
       Loop, Parse, % "xywh"
       {
          px := A_LoopField ? InStr(" " options, " " A_LoopField) : 0
          k := InStr(options, " ", 0, px + 1) - px
          If (px && k)
          {
             t := SubStr(options, px, k)
             posu .= t " "
             nopt := StrReplace(nopt, A_Space t A_Space, A_Space)
          }
          ; fnOutputDebug(A_LoopField "|" posu "|" px "|" k "|" t "|" nopt)
       }

       Gui, %guiu%: Add, Text, % posu " +BackgroundTrans +hide -wrap", % labelu
       Gui, %guiu%: Add, Edit, % " xp yp wp " nopt " +hwndhTemp", % defaultu
       EM_SETCUEBANNER(hTemp, labelu, 1)
       ToolTip2ctrl(hTemp, labelu)
    } Else
       Gui, %guiu%: Add, Edit, % options " +hwndhTemp", % defaultu

    Return hTemp
}

GuiAddListView(options, headeru, labelu, guiu:="SettingsGUIA") {
    posu := ""
    nopt := options
    Loop, Parse, % "xy"
    {
       px := A_LoopField ? InStr(" " options, " " A_LoopField) : 0
       k := InStr(options, " ", 0, px + 1) - px
       If (px && k)
       {
          t := SubStr(options, px, k)
          posu .= t " "
          nopt := StrReplace(nopt, t)
       }
    }

    Gui, %guiu%: Add, Text, % posu " w1 h1 +BackgroundTrans +hide -wrap", % labelu
    Gui, %guiu%: Add, ListView, % " xp yp " nopt " +hwndhTemp", % headeru
    Return hTemp
}

GuiAddDropDownList(options, listu, labelu:="", tipu:="", guiu:="SettingsGUIA") {
    If (labelu && !IsObject(labelu))
    {
       posu := ""
       nopt := A_Space options
       Loop, Parse, % "xywh"
       {
          px := A_LoopField ? InStr(" " options, " " A_LoopField) : 0
          k := InStr(options, " ", 0, px + 1) - px
          If (px && k)
          {
             t := SubStr(options, px, k)
             posu .= t " "
             nopt := StrReplace(nopt, A_Space t A_Space, A_Space)
          }
          ; fnOutputDebug(A_LoopField "|" posu "|" px "|" k "|" t "|" nopt)
       }

       Gui, %guiu%: Add, Text, % posu " +BackgroundTrans +hide +hwndhTmp -wrap", % labelu
       ; SetWindowRegion(hTmp, 1, 1, 1, 1, 0)
       Gui, %guiu%: Add, DropDownList, % combosDarkModus " xp yp wp " nopt " +hwndhTemp" , % listu
    } Else
    {
       Gui, %guiu%: Add, DropDownList, % combosDarkModus A_Space options " +hwndhTemp" , % listu
       If IsObject(labelu)
       {
          ; WinGetPos, , , w, h, ahk_id %hTemp%
          ; GetWinClientSize(w, h, hTemp, 2)
          z := GetWindowPlacement(labelu[1])
          If (labelu[2])
          {
             g := GetWindowPlacement(labelu[2])
             z.w := g.w
          }

          r := GetWindowPlacement(hTemp)
          SetWindowPlacement(labelu[1], z.x, z.y, z.w, r.h, 1)
          If (labelu[2] && labelu[3])
          {
             p := GetWindowPlacement(labelu[3])
             SetWindowPlacement(hTemp, p.x, r.y, r.w, r.h, 1)
          }

          ; GuiControl, %guiu%: MoveDraw, %tipu%, w%w% h%h%
          If labelu[3]
             labelu := labelu[3]
          Else
             labelu := tipu := ""
       }
    }

    tipu := tipu ? tipu : labelu
    If tipu
       ToolTip2ctrl(hTemp, tipu)
    Return hTemp
}

SetImgButtonStyle(hwnd, newLabel:="", checkMode:=0) {
   Static dopt1 := [0, "0xFF373737","0xFF373737", "0xFFffFFff",,,"0xff778877", 2] ; normal
   , dopt2 := [0, "0xFF656565","0xFF656565", "0xFFffFFff",,,"0xffaaAAaa", 2] ; hover
   , dopt3 := [0, "0xFF000000","0xFF000000", "0xFFeeEEee",,,"0xFF454545", 4] ; clicked
   , doptc := [0, "0xFF1E98A6","0xFF1E98A6", "0xFFeeEEee",,,"0xFF454545", 4] ; clicked
   , dopt4 := [0, "0xFF212121","0xFF212121", "0xFF999999",,,"0xFF454545", 4] ; disabled
   , dopt5 := [0, "0xFF606060","0xFF606060", "0xFFffFFff",,,"0xffaaAAaa", 3] ; active/focused
   , lopt1 := [0, "0xFFddDDdd","0xFFddDDdd", "0xFF111111",,,"0xffbbBBbb", 2] ; normal
   , lopt2 := [0, "0xFFC1DCE6","0xFFC1DCE6", "0xFF000000",,,"0xff8899EE", 2] ; hover
   , lopt3 := [0, "0xFFffffff","0xFFffffff", "0xFF000000",,,"0xFF0099ff", 4] ; clicked
   , loptc := [0, "0xFF83D2F1","0xFF83D2F1", "0xFF000000",,,"0xFF0099ff", 4] ; clicked
   , lopt4 := [0, "0xFFE1E1E1","0xFFE1E1E1", "0xFF666666",,,"0xFFaaaaaa", 1] ; disabled
   , lopt5 := [0, "0xFF83D2F1","0xFF83D2F1", "0xFF000000",,,"0xff000099", 4] ; active/focused

   If (newLabel!="")
   {
      Loop, 5
      {
         pi := (A_Index=3 && checkMode=1) ? "c" : A_Index
         If (uiDarkMode=1)
            dopt%pi%[10] := newLabel
         Else
            lopt%pi%[10] := newLabel
      }
   }

   pi := (checkMode=1) ? "c" : 3
   If (uiDarkMode=1)
      r := ImageButton.Create(hwnd, dopt1, dopt2, dopt%pi%, dopt4, dopt5)
   Else
      r := ImageButton.Create(hwnd, lopt1, lopt2, lopt%pi%, lopt4, lopt5)
      ; ToolTip, % "r=" r.lasterror , , , 2
   If (r!="")
      trackImageListButtons("record", r, protectedHwnd)
   Return r
}

trackImageListButtons(actu, r:=0, hwnd:="") {
    Critical, on
    Static HILs := []
    Static counteru := 0
    If (actu="record")
    {
       ; SoundBeep , 300, 100
       counteru++
       HILs[counteru] := [r, hwnd]
       Return
    }

    listu := new hashtable()
    Loop, % counteru
    {
       If (StrLen(HILs[A_Index, 2])>1)
       {
          ; fnOutputDebug(A_ThisFunc ": skip= " HILs[A_Index, 2])
          Continue
       }

       x := HILs[A_Index, 1]
       If (x!="" && listu[x]!=1)
       {
          ; SoundBeep , 900, 100
          ; fnOutputDebug(A_ThisFunc ": " HILs[A_Index, 1] "=" HILs[A_Index, 2])
          DllCall("Comctl32.dll\ImageList_Destroy", "uptr", x)
          HILs[A_Index, 1] := ""
          listu[x] := 1
       }
    }
    listu := ""
    counteru := 0
}


mouseCreateOSDinfoLine(msg:=0, largus:=0, gX:=0, gY:=0) {
    Critical, On
    Static prevMsg, lastInvoked := 1
    Global TippyMsg

    thisHwnd := hSetWinGui 
    If (!thisHwnd && hCelebsMan && windowManageCeleb=1)
       thisHwnd := hCelebsMan

    If ((StrLen(msg)<3) || (prevMsg=msg && mouseToolTipWinCreated=1) || (A_TickCount - lastInvoked<100) || !thisHwnd)
       Return

    lastInvoked := A_TickCount
    Gui, mouseToolTipGuia: Destroy
    thisFntSize := (largus=1) ? Round(LargeUIfontValue*1.55) : LargeUIfontValue
    If (thisFntSize<12)
       thisFntSize := 12

    bgrColor := OSDbgrColor
    txtColor := OSDtextColor
    Sleep, 25

    Gui, mouseToolTipGuia: -DPIScale -Caption +Owner%thisHwnd% +ToolWindow +hwndhGuiTip
    Gui, mouseToolTipGuia: Margin, % thisFntSize, % thisFntSize
    Gui, mouseToolTipGuia: Color, c%bgrColor%
    Gui, mouseToolTipGuia: Font, s%thisFntSize% Bold Q5, %FontName%
    Gui, mouseToolTipGuia: Add, Text, 0x80 c%txtColor% gmouseTurnOFFtooltip vTippyMsg, %msg%
    Gui, mouseToolTipGuia: Show, NoActivate AutoSize Hide x1 y1, QPVOguiTipsWin
    If (gX=0 && gY=0)
    {
      GetLogicalCursorPos(mX, mY)
      tipX := mX + 15
      tipY := mY + 15
      ResWidth := adjustWin2MonLimits(hGuiTip, tipX, tipY, Final_x, Final_y, Wid, Heig)
      MaxWidth := Floor(ResWidth*0.85)
      If (MaxWidth<Wid && MaxWidth>10)
      {
         GuiControl, mouseToolTipGuia: Move, TippyMsg, w1 h1
         GuiControl, mouseToolTipGuia:, TippyMsg,
         Gui, mouseToolTipGuia: Add, Text, 0x80 xp yp c%txtColor% gmouseTurnOFFtooltip w%MaxWidth%, %msg%
         Gui, mouseToolTipGuia: Show, NoActivate AutoSize Hide x1 y1, QPVguiTipsWin
         ResWidth := adjustWin2MonLimits(hGuiTip, tipX, tipY, Final_x, Final_y, Wid, Heig)
      }
    } Else 
    {
      Final_x := gX
      Final_y := gY
    }

    prevMsg := msg
    mouseToolTipWinCreated := 1
    WinSet, AlwaysOnTop, On, ahk_id %hGuiTip%
    WinSet, Transparent, 225, ahk_id %hGuiTip%
    Gui, mouseToolTipGuia: Show, NoActivate AutoSize x%Final_x% y%Final_y%, QPVguiTipsWin
    delayu := StrLen(msg) * 70 + 900
    If (delayu<msgDisplayTime/2)
       delayu := msgDisplayTime//2 + 1
    SetTimer, mouseTurnOFFtooltip, % -delayu
}

adjustWin2MonLimits(winHwnd, winX, winY, ByRef rX, ByRef rY, ByRef Wid, ByRef Heig) {
   GetWinClientSize(Wid, Heig, winHwnd, 1)
   ActiveMon := MWAGetMonitorMouseIsIn(winX, winY)
   If ActiveMon
   {
      SysGet, bCoord, Monitor, %ActiveMon%
      rX := max(bCoordLeft, min(winX, bCoordRight - Wid))
      rY := max(bCoordTop, min(winY, bCoordBottom - Heig*1.2))
      ResWidth := Abs(max(bCoordRight, bCoordLeft) - min(bCoordRight, bCoordLeft))
      ; ResHeight := Abs(max(bCoordTop, bCoordBottom) - min(bCoordTop, bCoordBottom))
   } Else
   {
      rX := winX
      rY := winY
   }

   Return ResWidth
}

GetPhysicalCursorPos(ByRef mX, ByRef mY) {
; function from: https://github.com/jNizM/AHK_DllCall_WinAPI/blob/master/src/Cursor%20Functions/GetPhysicalCursorPos.ahk
; by jNizM, modified by Marius Șucan
    Static lastMx, lastMy, lastInvoked := 1
    If (A_TickCount - lastInvoked<70)
    {
       mX := lastMx
       mY := lastMy
       Return
    }

    lastInvoked := A_TickCount
    Static POINT
         , init := VarSetCapacity(POINT, 8, 0) && NumPut(8, POINT, "Int")
    GPC := DllCall("user32.dll\GetPhysicalCursorPos", "Ptr", &POINT)
    If (!GPC || A_OSVersion="WIN_XP")
    {
       MouseGetPos, mX, mY
       lastMx := mX
       lastMy := mY
       Return
     ; Return DllCall("kernel32.dll\GetLastError")
    }

    lastMx := mX := NumGet(POINT, 0, "Int")
    lastMy := mY := NumGet(POINT, 4, "Int")
    Return
}

WM_RBUTTONUP() {
    ; unused function - see GuiContextMenu() functions 
    ; Tooltip, %A_GuiControl%
    thisWin := WinActive("A")
    If (mouseToolTipWinCreated=1)
       mouseTurnOFFtooltip()
    Else If (HfaceClock=thisWin)
       ClockGuiGuiContextMenu(thisWin, "lol", "N", 1, 2, 3)
    Else If ((AnyWindowOpen || PrefOpen=1 || windowManageCeleb=1) && !InStr(A_GuiControl, "lview") && !InStr(A_GuiControl, "UItodayEventsEdit"))
       SettingsToolTips("rclick")
}

SettingsToolTips(modus:=0) {
   ActiveWin := WinActive("A")
   If (ActiveWin!=hSetWinGui && ActiveWin!=hCelebsMan)
      Return

   If (mouseToolTipWinCreated=1)
      mouseTurnOFFtooltip()
 
   If (ActiveWin=hCelebsMan && windowManageCeleb=1)
      Gui, CelebrationsGuia: Default
   Else
      Gui, SettingsGUIA: Default

   GuiControlGet, WhatsFocused, FocusV
   GuiControlGet, value, , %A_GuiControl%
   If (isVarEqualTo(A_GuiControl, "holiListu", "UIcalendarEventsEditu", "UIcalendarNewEventEdit", "GeoDataSearchField", "newGeoDataLocationUserEdit", "UItodayEventsEditu")
   || isVarEqualTo(WhatsFocused, "holiListu", "UIcalendarEventsEditu", "UIcalendarNewEventEdit", "GeoDataSearchField", "newGeoDataLocationUserEdit", "UItodayEventsEditu") && modus!="rclick")
      Return

   ; MouseGetPos, , , , hwnd, 1 ; |2|3]
   GuiControlGet, hwnd, hwnd, %A_GuiControl%
   ControlGetText, info,, ahk_id %hwnd%
   ControlGet, listBoxOptions, List,,, ahk_id %hwnd%
   ControlGet, ctrlActiveState, Enabled,,, ahk_id %hwnd%
   If (info=value)
      info := ""

   If StrLen(info)>0
      info .= "`n"

   If (posuk := InStr(value, "&"))
      hotkeyu := "`nAlt+" SubStr(value, posuk + 1, 1)
   Else If (posuk := InStr(A_GuiControl, "&"))
      hotkeyu := "`nAlt+" SubStr(A_GuiControl, posuk + 1, 1)
   
   StringUpper, hotkeyu, hotkeyu
   value := StrReplace(value, "&")
   ctrlu := StrReplace(A_GuiControl, "&")
   If (ctrlu=value)
      value := ""

   ; btnType := GetButtonType(hwnd)
   If StrLen(value)>0
   {
      thisValueNumber := isNumber(Trim(value))
      value .= " = "
   }

   MouseGetPos, , , id, controla, 2
   If !hwnd
      ControlGetText, info, , ahk_id %controla%

   If !hotkeyu
   {
      If (posuk := InStr(info, "&"))
         hotkeyu := "`nAlt+" SubStr(info, posuk + 1, 1)
   }

   info := StrReplace(info, "&")
   WinGetClass, OutputVar, ahk_id %hwnd%
   If OutputVar
   {
      If InStr(OutputVar, "_trackbar")
      {
         SendMessage, 0x0401,,,, ahk_id %hwnd%   ; TBM_GETRANGEMIN
         minu := ErrorLevel
         SendMessage, 0x0402,,,, ahk_id %hwnd%   ; TBM_GETRANGEMAX
         maxu := ErrorLevel
         OutputVar := "Slider: " minu "; " maxu
      } Else If (InStr(OutputVar, "Button") && thisValueNumber=1 && InStr(value, "="))
         OutputVar := "Checkbox"
      Else If InStr(OutputVar, "_updown")
      {
         SendMessage, 0x0400+102,,,, ahk_id %hwnd%   ; UDM_GETRANGE
         UDM_GETRANGE := ErrorLevel
         minu := UDM_GETRANGE >> 16
         maxu := UDM_GETRANGE & 0xFFFF
         OutputVar := "Up/Down range: " minu "; " maxu
      } Else If InStr(OutputVar, "edit")
      {
         OutputVar := "Edit field"
      } Else If (InStr(OutputVar, "static") && value)
      {
         OutputVar := "Clickable" ; value  " - " ctrlu
         controlType := "`n[" OutputVar "]"
      }
      If !InStr(OutputVar, "static")
         controlType := "`n[" OutputVar "]"
   }

   msg2show := info value ctrlu controlType hotkeyu
   ; ToolTip, % A_DefaultGUI "===" msg2show , , , 2
   ; If (ctrlActiveState!=1 && StrLen(msg2show)>2 && btnType)
   ;    msg2show .= "`n[CONTROL DISABLED]"
   If StrLen(listBoxOptions)>3
   {
      countListBoxOptions := ST_Count(listBoxOptions, "`n") + 1
      If (countListBoxOptions>10)
         listBoxOptions := "[too many to list]"
      msg2show .= "`n`nLIST OPTIONS: " countListBoxOptions "`n" listBoxOptions
   }

   ; If (!value && btnType)
   ;    msg2show .= "`n`nCONTROL TYPE:`n" btnType
   If InStr(msg2show, "lib\") || InStr(msg2show, "a href=")
      Return

   mouseCreateOSDinfoLine(msg2show, PrefsLargeFonts)
   Return msg2show
}

cRound(n, j:=0) {
   Return Round(n)
   k := Round(n, 1)
   d := Floor(n)
   If IsInRange(k, d + 0.4, d + 0.6)
      Return d + 0.5
   Else
      Return d
}

AddTooltip2Ctrl(p1, p2:="", p3="", darkMode:=0, largeFont:=0) {
; Description: AddTooltip v2.0
;   Add/Update tooltips to GUI controls.
;
; Parameters:
;   p1 - Handle to a GUI control.  Alternatively, set to "Activate" to enable
;       the tooltip control, "AutoPopDelay" to set the autopop delay time,
;       "Deactivate" to disable the tooltip control, or "Title" to set the
;       tooltip title.
;
;   p2 - If p1 contains the handle to a GUI control, this parameter should
;       contain the tooltip text.  Ex: "My tooltip".  Set to null to delete the
;       tooltip attached to the control.  If p1="AutoPopDelay", set to the
;       desired autopop delay time, in seconds.  Ex: 10.  Note: The maximum
;       autopop delay time is ~32 seconds.  If p1="Title", set to the title of
;       the tooltip.  Ex: "Bob's Tooltips".  Set to null to remove the tooltip
;       title.  See the *Title & Icon* section for more information.
;
;   p3 - Tooltip icon.  See the *Title & Icon* section for more information.
;
; RETURNS: The handle to the tooltip control.
; REQUIREMENTS: AutoHotkey v1.1+ (all versions).
;
; TITLE AND ICON:
;   To set the tooltip title, set the p1 parameter to "Title" and the p2
;   parameter to the desired tooltip title.  Ex: AddTooltip("Title","Bob's
;   Tooltips"). To remove the tooltip title, set the p2 parameter to null.  Ex:
;   AddTooltip("Title","").
;
;   The p3 parameter determines the icon to be displayed along with the title,
;   if any.  If not specified or if set to 0, no icon is shown.  To show a
;   standard icon, specify one of the standard icon identifiers.  See the
;   function's static variables for a list of possible values.  Ex:
;   AddTooltip("Title","My Title",4).  To show a custom icon, specify a handle
;   to an image (bitmap, cursor, or icon).  When a custom icon is specified, a
;   copy of the icon is created by the tooltip window so if needed, the original
;   icon can be destroyed any time after the title and icon are set.
;
;   Setting a tooltip title may not produce a desirable result in many cases.
;   The title (and icon if specified) will be shown on every tooltip that is
;   added by this function.
;
; REMARKS:
;   The tooltip control is enabled by default.  There is no need to "Activate"
;   the tooltip control unless it has been previously "Deactivated".
;
;   This function returns the handle to the tooltip control so that, if needed,
;   additional actions can be performed on the Tooltip control outside of this
;   function.  Once created, this function reuses the same tooltip control.
;   If the tooltip control is destroyed outside of this function, subsequent
;   calls to this function will fail.
;
; CREDIT AND HISTORY:
;   Original author: Superfraggle
;   * Post: <http://www.autohotkey.com/board/topic/27670-add-tooltips-to-controls/>
;
;   Updated to support Unicode: art
;   * Post: <http://www.autohotkey.com/board/topic/27670-add-tooltips-to-controls/page-2#entry431059>
;
;   Additional: jballi.
;   Bug fixes.  Added support for x64.  Removed Modify parameter.  Added
;   additional functionality, constants, and documentation.

    Static hTT
          ;-- Misc. constants
          ,CW_USEDEFAULT:=0x80000000
          ,HWND_DESKTOP :=0

          ;-- Tooltip delay time constants
          ,TTDT_AUTOPOP:=2
                ;-- Set the amount of time a tooltip window remains visible if
                ;   the pointer is stationary within a tool's bounding
                ;   rectangle.

          ;-- Tooltip styles
          ,TTS_ALWAYSTIP:=0x1
                ;-- Indicates that the tooltip control appears when the cursor
                ;   is on a tool, even if the tooltip control's owner window is
                ;   inactive.  Without this style, the tooltip appears only when
                ;   the tool's owner window is active.

          ,TTS_NOPREFIX:=0x2
                ;-- Prevents the system from stripping ampersand characters from
                ;   a string or terminating a string at a tab character.
                ;   Without this style, the system automatically strips
                ;   ampersand characters and terminates a string at the first
                ;   tab character.  This allows an application to use the same
                ;   string as both a menu item and as text in a tooltip control.

          ;-- TOOLINFO uFlags
          ,TTF_IDISHWND:=0x1
                ;-- Indicates that the uId member is the window handle to the
                ;   tool.  If this flag is not set, uId is the identifier of the
                ;   tool.

          ,TTF_SUBCLASS:=0x10
                ;-- Indicates that the tooltip control should subclass the
                ;   window for the tool in order to intercept messages, such
                ;   as WM_MOUSEMOVE.  If this flag is not used, use the
                ;   TTM_RELAYEVENT message to forward messages to the tooltip
                ;   control.  For a list of messages that a tooltip control
                ;   processes, see TTM_RELAYEVENT.

          ;-- Tooltip icons
          ,TTI_NONE         :=0
          ,TTI_INFO         :=1
          ,TTI_WARNING      :=2
          ,TTI_ERROR        :=3
          ,TTI_INFO_LARGE   :=4
          ,TTI_WARNING_LARGE:=5
          ,TTI_ERROR_LARGE  :=6

          ;-- Extended styles
          ,WS_EX_TOPMOST:=0x8

          ;-- Messages
          ,TTM_ACTIVATE      :=0x401                    ;-- WM_USER + 1
          ,TTM_ADDTOOLA      :=0x404                    ;-- WM_USER + 4
          ,TTM_ADDTOOLW      :=0x432                    ;-- WM_USER + 50
          ,TTM_DELTOOLA      :=0x405                    ;-- WM_USER + 5
          ,TTM_DELTOOLW      :=0x433                    ;-- WM_USER + 51
          ,TTM_GETTOOLINFOA  :=0x408                    ;-- WM_USER + 8
          ,TTM_GETTOOLINFOW  :=0x435                    ;-- WM_USER + 53
          ,TTM_SETDELAYTIME  :=0x403                    ;-- WM_USER + 3
          ,TTM_SETMAXTIPWIDTH:=0x418                    ;-- WM_USER + 24
          ,TTM_SETTITLEA     :=0x420                    ;-- WM_USER + 32
          ,TTM_SETTITLEW     :=0x421                    ;-- WM_USER + 33
          ,TTM_UPDATETIPTEXTA:=0x40C                    ;-- WM_USER + 12
          ,TTM_UPDATETIPTEXTW:=0x439                    ;-- WM_USER + 57

    If (p1="reset")
    {
       If hTT
          DllCall("DestroyWindow", "Ptr", hTT)
       hTT := ""
       Return
    }

    if (DisableTooltips=1)
       return 

    ;-- Save/Set DetectHiddenWindows
    l_DetectHiddenWindows:=A_DetectHiddenWindows
    DetectHiddenWindows On

    ;-- Tooltip control exists?
    if !hTT
    {
        ;-- Create Tooltip window
        hTT:=DllCall("CreateWindowEx"
            ,"UInt",WS_EX_TOPMOST                       ;-- dwExStyle
            ,"Str","TOOLTIPS_CLASS32"                   ;-- lpClassName
            ,"Ptr",0                                    ;-- lpWindowName
            ,"UInt",TTS_ALWAYSTIP|TTS_NOPREFIX          ;-- dwStyle
            ,"UInt",CW_USEDEFAULT                       ;-- x
            ,"UInt",CW_USEDEFAULT                       ;-- y
            ,"UInt",CW_USEDEFAULT                       ;-- nWidth
            ,"UInt",CW_USEDEFAULT                       ;-- nHeight
            ,"Ptr",HWND_DESKTOP                         ;-- hWndParent
            ,"Ptr",0                                    ;-- hMenu
            ,"Ptr",0                                    ;-- hInstance
            ,"Ptr",0                                    ;-- lpParam
            ,"Ptr")                                     ;-- Return type

        ;-- Disable visual style
        ;   Note: Uncomment the following to disable the visual style, i.e.
        ;   remove the window theme, from the tooltip control.  Since this
        ;   function only uses one tooltip control, all tooltips created by this
        ;   function will be affected.
        ;   DllCall("uxtheme\SetWindowTheme","Ptr",hTT,"Ptr",0,"UIntP",0)

        If (darkMode=1)
           DllCall("uxtheme\SetWindowTheme", "ptr", HTT, "str", "DarkMode_Explorer", "ptr", 0)
        ;-- Set the maximum width for the tooltip window
        ;   Note: This message makes multi-line tooltips possible
        SendMessage, TTM_SETMAXTIPWIDTH, 0, A_ScreenWidth,, ahk_id %hTT%
        If (largeFont=1)
        {
           hFont := Gdi_CreateFontByName("MS Shell Dlg 2", 20, 400, 0, 0, 0, 4)
           SendMessage, 0x30, hFont, 1,,ahk_id %hTT% ; WM_SETFONT
        }
    }

    ;-- Other commands
    if p1 is not Integer
    {
        if (p1="Activate")
            SendMessage, TTM_ACTIVATE, True, 0,, ahk_id %hTT%

        if (p1="Deactivate")
            SendMessage, TTM_ACTIVATE, False, 0,, ahk_id %hTT%

        if (InStr(p1,"AutoPop")=1)  ;-- Starts with "AutoPop"
            SendMessage, TTM_SETDELAYTIME, TTDT_AUTOPOP, p2*1000,, ahk_id %hTT%

        if (p1="Title")
        {
            ;-- If needed, truncate the title
            if (StrLen(p2)>99)
                p2 := SubStr(p2,1,99)

            ;-- Icon
            if p3 is not Integer
                p3 := TTI_NONE

            ;-- Set title
            SendMessage A_IsUnicode ? TTM_SETTITLEW : TTM_SETTITLEA, p3, &p2,, ahk_id %hTT%
        }

        ;-- Restore DetectHiddenWindows
        DetectHiddenWindows %l_DetectHiddenWindows%
    
        ;-- Return the handle to the tooltip control
        Return hTT
    }

    ;-- Create/Populate the TOOLINFO structure
    uFlags := TTF_IDISHWND | TTF_SUBCLASS
    cbSize := VarSetCapacity(TOOLINFO,(A_PtrSize=8) ? 64:44,0)
    NumPut(cbSize,      TOOLINFO,0,"UInt")              ;-- cbSize
    NumPut(uFlags,      TOOLINFO,4,"UInt")              ;-- uFlags
    NumPut(HWND_DESKTOP,TOOLINFO,8,"Ptr")               ;-- hwnd
    NumPut(p1,          TOOLINFO,(A_PtrSize=8) ? 16:12,"Ptr")
        ;-- uId

    ;-- Check to see if tool has already been registered for the control
    SendMessage, A_IsUnicode ? TTM_GETTOOLINFOW : TTM_GETTOOLINFOA
               , 0, &TOOLINFO,, ahk_id %hTT%

    l_RegisteredTool := ErrorLevel

    ;-- Update the TOOLTIP structure
    NumPut(&p2, TOOLINFO, (A_PtrSize=8) ? 48 : 36,"Ptr")
        ;-- lpszText

    ;-- Add, Update, or Delete tool
    if l_RegisteredTool
    {
        if StrLen(p2)
            SendMessage, A_IsUnicode ? TTM_UPDATETIPTEXTW : TTM_UPDATETIPTEXTA, 0, &TOOLINFO,, ahk_id %hTT%
        else
            SendMessage, A_IsUnicode ? TTM_DELTOOLW : TTM_DELTOOLA, 0, &TOOLINFO,, ahk_id %hTT%
    } else if StrLen(p2)
    {
        SendMessage, A_IsUnicode ? TTM_ADDTOOLW : TTM_ADDTOOLA, 0, &TOOLINFO,, ahk_id %hTT%
    }

    ;-- Restore DetectHiddenWindows
    DetectHiddenWindows %l_DetectHiddenWindows%
    ;-- Return the handle to the tooltip control
    Return hTT
}

ToolTip2ctrl(hwnd, msg) {
    Return AddTooltip2Ctrl(hwnd, msg,, uiDarkMode, PrefsLargeFonts)
}

parseBibleXML() {
   pp := "E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\resources\bible-quotes-eng.txt"
   FileRead, contentu, % pp
   obju := []
   listu := ""
   Loop, Parse, contentu, `n,`r
   {
      If A_LoopField
      {
         pk := StrSplit(A_LoopField, " | ")
         j := InStr(pk[1], A_Space, 0, -1)
         a := SubStr(pk[1], 1, j - 1)
         a := Format("{:L}", a)

         b := SubStr(pk[1], j + 1)
         b := LTrim(b, "0")
         b := StrReplace(b, ":0", ":")
         obju[a "|" b] := 1
         listu .= a "|" b "`n"
      }
   }

   ; Try Clipboard := listu
   ; coreParseBibleXML("SF_2009-01-20_GRC_GREEKM_(MODERN GREEK).xml", "grk", obju)
   ; coreParseBibleXML("SF_2004-11-13_FRE_DEJER_(LA BIBLE DE JÉRUSALEM).xml", "fre", obju)
   ; coreParseBibleXML("SF_2009-01-20_LAT_CLVUL_(CLEMENTINE VULGATE).xml", "lat", obju)
   ; coreParseBibleXML("SF_2009-01-20_RUS_RST_(RUSSIAN SYNODAL TRANSLATION).xml", "rus", obju)
   ; coreParseBibleXML("SF_2006-12-20_GER_LUTH1912AP_(LUTHER 1912 - MIT APOKRYPHEN).xml", "ger", obju)
   ; coreParseBibleXML("SF_2009-01-20_SPA_RVA_(REINA VALERA 1989).xml", "spanr", obju)
   ; coreParseBibleXML("SF_2021-11-29_SPA_SPAPLATENSE_(Biblia Platense (Straubinger)).xml", "spans", obju)
}

coreParseBibleXML(fileu, langu, obju:=0) {
; bibles sourced from: https://app.box.com/s/et4h5qhkcf2itcp8nv22/folder/1889748955

   Static listuENG := {1:"Genesis", 2:"Exodus", 3:"Leviticus", 4:"Numbers", 5:"Deuteronomy", 6:"Joshua", 7:"Judges", 8:"Ruth", 9:"1 Samuel", 10:"2 Samuel", 11:"1 Kings", 12:"2 Kings", 13:"1 Chronicles", 14:"2 Chronicles", 15:"Ezra", 16:"Nehemiah", 17:"Esther", 18:"Job", 19:"Psalm", 20:"Proverbs", 21:"Ecclesiastes", 22:"Song of Songs", 23:"Isaiah", 24:"Jeremiah", 25:"Lamentations", 26:"Ezekiel", 27:"Daniel", 28:"Hosea", 29:"Joel", 30:"Amos", 31:"Obadiah", 32:"Jonah", 33:"Micah", 34:"Nahum", 35:"Habakkuk", 36:"Zephaniah", 37:"Haggai", 38:"Zechariah", 39:"Malachi", 40:"Matthew", 41:"Mark", 42:"Luke", 43:"John", 44:"Acts", 45:"Romans", 46:"1 Corinthians", 47:"2 Corinthians", 48:"Galatians", 49:"Ephesians", 50:"Philippians", 51:"Colossians", 52:"1 Thessalonians", 53:"2 Thessalonians", 54:"1 Timothy", 55:"2 Timothy", 56:"Titus", 57:"Philemon", 58:"Hebrews", 59:"James", 60:"1 Peter", 61:"2 Peter", 62:"1 John", 63:"2 John", 64:"3 John", 65:"Jude", 66:"Revelation", 67:"Judith", 68:"Wisdom of Solomon", 69:"Tobit", 70:"Wisdom of Sirach", 71:"Baruch", 72:"1 Maccabees", 73:"2 Maccabees", 74:"3 Maccabees", 75:"1 Esdras", 76:"Prayer of Manasses", 77:"Song of Solomon"}
   Static listuLAT := {1:"Genesis", 2:"Exodus", 3:"Leviticus", 4:"Numeri", 5:"Deuteronomium", 6:"Iosue", 7:"Iudicum", 8:"Ruth", 9:"1 Samuelis", 10:"2 Samuelis", 11:"1 Regum", 12:"2 Regum", 13:"1 Chronicorum", 14:"2 Chronicorum", 15:"Esdrae", 16:"Nehemiae", 17:"Esther", 18:"Iob", 19:"Psalmi", 20:"Proverbia", 21:"Ecclesiastes", 22:"Canticum Canticorum", 23:"Isaias", 24:"Ieremias", 25:"Lamentationes Ieremiae", 26:"Ezechiel", 27:"Daniel", 28:"Osee", 29:"Ioel", 30:"Amos", 31:"Abdias", 32:"Ionas", 33:"Michaeas", 34:"Nahum", 35:"Habacuc", 36:"Sophonias", 37:"Aggaeus", 38:"Zacharias", 39:"Malachias", 40:"Matthaeus", 41:"Marcus", 42:"Lucas", 43:"Ioannes", 44:"Actus Apostolorum", 45:"Romanos", 46:"1 Corinthios", 47:"2 Corinthios", 48:"Galatas", 49:"Ephesios", 50:"Philippenses", 51:"Colossenses", 52:"1 Thessalonicenses", 53:"2 Thessalonicenses", 54:"1 Timotheum", 55:"2 Timotheum", 56:"Titus", 57:"Philemonem", 58:"Hebraeos", 59:"Iacobi", 60:"1 Petri", 61:"2 Petri", 62:"1 Ioannis", 63:"2 Ioannis", 64:"3 Ioannis", 65:"Iudae", 66:"Apocalypsis", 67:"Judith", 68:"Sapienta", 69:"Tobiae", 70:"Sirach / Ecclesiasticus", 71:"Baruch", 72:"I Machabaeorum", 73:"II Machabaeorum", 74:"III Machabaeorum"}
   Static listuGRK := {1:"Γένεσις", 2:"Ἔξοδος", 3:"Λευιτικόν", 4:"Ἀριθμοί", 5:"Δευτερονόμιον", 6:"Ἰησοῦς Ναυῆ", 7:"Κριταί", 8:"Ῥούθ", 9:"Βασιλειῶν Αʹ", 10:"Βασιλειῶν Βʹ", 11:"Βασιλειῶν Γʹ", 12:"Βασιλειῶν Δʹ", 13:"Παραλειπομένων Αʹ", 14:"Παραλειπομένων Βʹ", 15:"Ἔσδρας Αʹ", 16:"Ἔσδρας Βʹ", 17:"Εσθήρ", 18:"Ἰώβ", 19:"Ψαλμοί", 20:"Παροιμίαι", 21:"Ἐκκλησιαστής", 22:"ᾎσμα ᾎσμάτων", 23:"Ἠσαΐας", 24:"Ἱερεμίας", 25:"Θρῆνοι Ἱερεμίου", 26:"Ἰεζεκιήλ", 27:"Δανιήλ", 28:"Ὀσηέ", 29:"Ἰωήλ", 30:"Ἀμώς", 31:"Ὀβδίας", 32:"Ἰωνᾶς", 33:"Μιχαίας", 34:"Ναούμ", 35:"Ἀβακούμ", 36:"Σοφονίας", 37:"Ἀγγαῖος", 38:"Ζαχαρίας", 39:"Μαλαχίας", 40:"Κατά Ματθαῖον", 41:"Κατά Μάρκον", 42:"Κατά Λουκᾶν", 43:"Κατά Ἰωάννην", 44:"Πράξεις Ἀποστόλων", 45:"Πρὸς Ῥωμαίους", 46:"Πρὸς Κορινθίους Αʹ", 47:"Πρὸς Κορινθίους Βʹ", 48:"Πρὸς Γαλάτας", 49:"Πρὸς Ἐφεσίους", 50:"Πρὸς Φιλιππησίους", 51:"Πρὸς Κολοσσαεῖς", 52:"Πρὸς Θεσσαλονικεῖς Αʹ", 53:"Πρὸς Θεσσαλονικεῖς Βʹ", 54:"Πρὸς Τιμόθεον Αʹ", 55:"Πρὸς Τιμόθεον Βʹ", 56:"Πρὸς Τίτον", 57:"Πρὸς Φιλήμονα", 58:"Πρὸς Ἑβραίους", 59:"Ἰακώβου", 60:"Πέτρου Αʹ", 61:"Πέτρου Βʹ", 62:"Ἰωάννου Αʹ", 63:"Ἰωάννου Βʹ", 64:"Ἰωάννου Γʹ", 65:"Ἰούδα", 66:"Ἀποκάλυψις Ἰωάννου", 67:"Ἰουδίθ", 68:"Σοφία Σολομώντος", 69:"Τωβίτ", 70:"Σιράχ", 71:"Βαρούχ", 72:"Μακκαβαίων Αʹ", 73:"Μακκαβαίων Βʹ", 74:"Μακκαβαίων Γʹ", 75:"Ἔσδρας Αʹ"}
   Static listuFRE := {1:"Genèse", 2:"Exode", 3:"Lévitique", 4:"Nombres", 5:"Deutéronome", 6:"Josué", 7:"Juges", 8:"Ruth", 9:"1 Samuel", 10:"2 Samuel", 11:"1 Rois", 12:"2 Rois", 13:"1 Chroniques", 14:"2 Chroniques", 15:"Esdras", 16:"Néhémie", 17:"Esther", 18:"Job", 19:"Psaume", 20:"Proverbes", 21:"Ecclésiaste", 22:"Cantique", 23:"Isaïe", 24:"Jérémie", 25:"Lamentations", 71:"Baruch", 26:"Ezéchiel", 27:"Daniel", 28:"Osée", 29:"Joël", 30:"Amos", 31:"Abdias", 32:"Jonas", 33:"Michée", 34:"Nahum", 35:"Habaquq", 36:"Sophonie", 37:"Aggée", 38:"Zacharie", 39:"Malachie", 40:"Matthieu", 41:"Marc", 42:"Luc", 43:"Jean", 44:"Actes", 45:"Romains", 46:"1 Corinthiens", 47:"2 Corinthiens", 48:"Galates", 49:"Ephésiens", 50:"Philippiens", 51:"Colossiens", 52:"1 Théssaloniciens", 53:"2 Théssaloniciens", 54:"1 Thimothées", 55:"2 Thimothées", 56:"Tite", 57:"Philémon", 58:"Hébreux", 59:"Jacques", 60:"1 Pierre", 61:"2 Pierre", 62:"1 Jean", 63:"2 Jean", 64:"3 Jean", 65:"Jude", 66:"Apocalypse", 67:"Judith", 68:"Sagesse", 69:"Tobie", 70:"Sirach / Ecclésiastique", 71:"Baruch", 72:"1 Maccabées", 73:"2 Maccabées", 74:"3 Maccabées", 75:"1 Esdras"}
   Static listuGER := {1:"Genesis", 2:"Exodus", 3:"Levitikus", 4:"Numeri", 5:"Deuteronomium", 6:"Josua", 7:"Richter", 8:"Rut", 9:"1 Samuel", 10:"2 Samuel", 11:"1 Könige", 12:"2 Könige", 13:"1 Chronik", 14:"2 Chronik", 15:"Esra", 16:"Nehemia", 17:"Ester", 18:"Hiob", 19:"Psalmen", 20:"Sprüche", 21:"Prediger", 22:"Hohelied", 23:"Jesaja", 24:"Jeremia", 25:"Klagelieder", 26:"Hesekiel", 27:"Daniel", 28:"Hosea", 29:"Joel", 30:"Amos", 31:"Obadja", 32:"Jona", 33:"Micha", 34:"Nahum", 35:"Habakuk", 36:"Zefanja", 37:"Haggai", 38:"Sacharja", 39:"Maleachi", 40:"Matthäus", 41:"Markus", 42:"Lukas", 43:"Johannes", 44:"Apostelgeschichte", 45:"Römer", 46:"1 Korinther", 47:"2 Korinther", 48:"Galater", 49:"Epheser", 50:"Philipper", 51:"Kolosser", 52:"1 Thessalonicher", 53:"2 Thessalonicher", 54:"1 Timotheus", 55:"2 Timotheus", 56:"Titus", 57:"Philemon", 58:"Hebräer", 59:"Jakobus", 60:"1 Petrus", 61:"2 Petrus", 62:"1 Johannes", 63:"2 Johannes", 64:"3 Johannes", 65:"Judas", 66:"Offenbarung", 67:"Judit", 68:"Weisheit", 69:"Tobia", 70:"Sirach", 71:"Baruch", 72:"1 Makkabäer", 73:"2 Makkabäer", 74:"3 Makkabäer", 75:"1 Esdras"}
   Static listuRUS := {1:"Бытие", 2:"Исход", 3:"Левит", 4:"Числа", 5:"Второзаконие", 6:"Иисус Навин", 7:"Книга Судей", 8:"Руфь", 9:"1-я Царств", 10:"2-я Царств", 11:"3-я Царств", 12:"4-я Царств", 13:"1-я Паралипоменон", 14:"2-я Паралипоменон", 15:"Ездра", 16:"Неемия", 17:"Есфирь", 18:"Иов", 19:"Псалтирь", 20:"Притчи", 21:"Екклесиаст", 22:"Песни Песней", 23:"Исаия", 24:"Иеремия", 25:"Плач Иеремии", 26:"Иезекииль", 27:"Даниил", 28:"Осия", 29:"Иоиль", 30:"Амос", 31:"Авдия", 32:"Иона", 33:"Михей", 34:"Наум", 35:"Аввакум", 36:"Софония", 37:"Аггей", 38:"Захария", 39:"Малахия", 40:"От Матфея", 41:"От Марка", 42:"От Луки", 43:"От Иоанна", 44:"Деяния", 45:"К Римлянам", 46:"1-е Коринфянам", 47:"2-е Коринфянам", 48:"К Галатам", 49:"К Ефесянам", 50:"К Филиппийцам", 51:"К Колоссянам", 52:"1-е Фессалоникийцам", 53:"2-е Фессалоникийцам", 54:"1-е Тимофею", 55:"2-е Тимофею", 56:"К Титу", 57:"К Филимону", 58:"К Евреям", 59:"Иакова", 60:"1-e Петра", 61:"2-e Петра", 62:"1-e Иоанна", 63:"2-e Иоанна", 64:"3-e Иоанна", 65:"Иуда", 66:"Откровение", 67:"Иудифь", 68:"Премудрость Соломона", 69:"Товит", 70:"Сирах", 71:"Варух", 72:"1 Маккавеев", 73:"2 Маккавеев", 74:"3 Маккавеев", 75:"1 Ездры"}
   Static listuSPANR := {1:"Génesis", 2:"Éxodo", 3:"Levítico", 4:"Números", 5:"Deuteronomio", 6:"Josué", 7:"Jueces", 8:"Rut", 9:"1 Samuel", 10:"2 Samuel", 11:"1 Reyes", 12:"2 Reyes", 13:"1 Crónicas", 14:"2 Crónicas", 15:"Esdras", 16:"Nehemías", 17:"Ester", 18:"Job", 19:"Salmos", 20:"Proverbios", 21:"Eclesiastés", 22:"Cantares", 23:"Isaías", 24:"Jeremías", 25:"Lamentaciones", 26:"Ezequiel", 27:"Daniel", 28:"Oseas", 29:"Joel", 30:"Amós", 31:"Abdías", 32:"Jonás", 33:"Miqueas", 34:"Nahúm", 35:"Habacuc", 36:"Sofonías", 37:"Hageo", 38:"Zacarías", 39:"Malaquías", 40:"Mateo", 41:"Marcos", 42:"Lucas", 43:"Juan", 44:"Hechos", 45:"Romanos", 46:"1 Corintios", 47:"2 Corintios", 48:"Gálatas", 49:"Efesios", 50:"Filipenses", 51:"Colosenses", 52:"1 Tesalonicenses", 53:"2 Tesalonicenses", 54:"1 Timoteo", 55:"2 Timoteo", 56:"Tito", 57:"Filemón", 58:"Hebreos", 59:"Santiago", 60:"1 Pedro", 61:"2 Pedro", 62:"1 Juan", 63:"2 Juan", 64:"3 Juan", 65:"Judas", 66:"Apocalipsis", 67:"Judit", 68:"Sabiduría de Salomón", 69:"Tobit", 70:"Sirach / Eclesiástico", 71:"Baruc", 72:"1 Macabeos", 73:"2 Macabeos", 74:"3 Macabeos", 75:"1 Esdras"}
   Static listuSPANS := {1:"Génesis", 2:"Éxodo", 3:"Levítico", 4:"Números", 5:"Deuteronomio", 6:"Josué", 7:"Jueces", 8:"Rut", 9:"1 Samuel", 10:"2 Samuel", 11:"1 Reyes", 12:"2 Reyes", 13:"1 Crónicas", 14:"2 Crónicas", 15:"Esdras", 16:"Nehemías", 17:"Ester", 18:"Job", 19:"Salmos", 20:"Proverbios", 21:"Eclesiastés", 22:"Cantares", 23:"Isaías", 24:"Jeremías", 25:"Lamentaciones", 26:"Ezequiel", 27:"Daniel", 28:"Oseas", 29:"Joel", 30:"Amós", 31:"Abdías", 32:"Jonás", 33:"Miqueas", 34:"Nahúm", 35:"Habacuc", 36:"Sofonías", 37:"Hageo", 38:"Zacarías", 39:"Malaquías", 40:"Mateo", 41:"Marcos", 42:"Lucas", 43:"Juan", 44:"Hechos", 45:"Romanos", 46:"1 Corintios", 47:"2 Corintios", 48:"Gálatas", 49:"Efesios", 50:"Filipenses", 51:"Colosenses", 52:"1 Tesalonicenses", 53:"2 Tesalonicenses", 54:"1 Timoteo", 55:"2 Timoteo", 56:"Tito", 57:"Filemón", 58:"Hebreos", 59:"Santiago", 60:"1 Pedro", 61:"2 Pedro", 62:"1 Juan", 63:"2 Juan", 64:"3 Juan", 65:"Judas", 66:"Apocalipsis", 67:"Judit", 68:"Sabiduría de Salomón", 69:"Tobit", 70:"Sirach / Eclesiástico", 71:"Baruc", 72:"1 Macabeos", 73:"2 Macabeos", 74:"3 Macabeos", 75:"1 Esdras"}

   pp := "E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\_other-files\bibles\" fileu
   FileRead, contentu, % pp
   ; ToolTip, % contentu "|" ErrorLevel , , , 2
   nID := chapterID := verseID := bookID := 0
   remu := booku := ""
   Loop, Parse, contentu, `n,`r
   {
      If InStr(A_LoopField, "<BIBLEBOOK bnumber=")
      {
         bookID := StrReplace(A_LoopField, "<BIBLEBOOK")
         bookID := StrReplace(bookID, "bnumber=", "id=")
         bookID := SubStr(Trimmer(bookID), 5)
         bookID := SubStr(bookID, 1, InStr(bookID, """") - 1)
         nID := bookID
         bookID := listu%langu%[bookID]
      }

      If InStr(A_LoopField, "<CHAPTER cnumber=")
      {
         chapter := StrReplace(A_LoopField, "<CHAPTER cnumber=""")
         chapterID := Trimmer(StrReplace(chapter, """>"))
      }

      If (p := InStr(A_LoopField, "<VERS vnumber="))
      {
         k := SubStr(A_LoopField, p + 15)
         verseID := SubStr(k, 1, InStr(k, ">") - 2)
         verse := SubStr(k, InStr(k, ">") + 1)
         verse := StrReplace(verse, "</vers>")
         a := Format("{:L}", listuENG[nID]) "|" chapterID ":" verseID
         If obju[a]
            booku .= nID "#" bookID sillySeparator chapterID ":" verseID " | " verse "`n"
         Else
            remu .= nID "#" bookID sillySeparator chapterID ":" verseID " | " verse "`n"
      }
   }

   outu := "E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\resources\bible-quotes-" langu ".txt"
   FileDelete, % outu
   Sleep, 10
   FileAppend, % booku, % outu, UTF-8

   ; outu := "E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\resources\bible-quotes-" langu "-remu.txt"
   ; FileDelete, % outu
   ; Sleep, 10
   ; FileAppend, % remu, % outu, UTF-8
   ; SoundBeep 900, 100
}

InfosDummy() {
  Static lastInvoked := 1
  If (A_Year!=2023 || A_Mon!=4)
     Return

      x := A_AppData "\ChurchBellsTower"
      WinStoreDataPath := "\Local\Packages\13644TabletPro.ChurchBellsTower_3wyk1bs4amrq4\AppData"
      WinStorePath := StrReplace(x, "\Roaming\ChurchBellsTower", WinStoreDataPath)
      If !FileExist(WinStorePath)
      {
         hasCreated := 1
      } Else
         hasCreated := 0

      If FileExist(WinStorePath "\resources")
         hasCreated := 2

   If (A_TickCount - lastInvoked<500)
      Try Run, % WinStorePath

   lastInvoked := A_TickCount
   ToolTip, % A_AppData "`n" A_ScriptDir "`n" x "`n" hasCreated " | " WinStorePath
   SetTimer, removeTooltip, -2000
}

DetermineWindowsStorePath() {
   If (storeSettingsREG=1)
   {
      SetWorkingDir, %A_AppData%
      x := A_AppData "\ChurchBellsTower"
      WinStoreDataPath := "\Local\Packages\13644TabletPro.ChurchBellsTower_3wyk1bs4amrq4\AppData"
      WinStorePath := StrReplace(x, "\Roaming\ChurchBellsTower", WinStoreDataPath)
      If !FileExist(WinStorePath "\resources")
         FileCreateDir, % WinStorePath "\resources"

      SetWorkingDir, %A_ScriptDir%
   } Else WinStorePath := A_ScriptDir 
}

Trimmer(string, whatTrim:="") {
   If (whatTrim!="")
      string := Trim(string, whatTrim)
   Else
      string := Trim(string, "`r`n `t`f`v`b")
   Return string
}


GetWindowPlacement(hWnd) {
    Local WINDOWPLACEMENT, Result := {}
    NumPut(VarSetCapacity(WINDOWPLACEMENT, 44, 0), WINDOWPLACEMENT, 0, "UInt")
    r := DllCall("GetWindowPlacement", "UPtr", hWnd, "UPtr", &WINDOWPLACEMENT)
    If (r=0)
    {
       WINDOWPLACEMENT := ""
       Return 0
    }
    Result.x := NumGet(WINDOWPLACEMENT, 28, "Int")
    Result.y := NumGet(WINDOWPLACEMENT, 32, "Int")
    Result.w := NumGet(WINDOWPLACEMENT, 36, "Int") - Result.x
    Result.h := NumGet(WINDOWPLACEMENT, 40, "Int") - Result.y
    Result.flags := NumGet(WINDOWPLACEMENT, 4, "UInt") ; 2 = WPF_RESTORETOMAXIMIZED
    Result.showCmd := NumGet(WINDOWPLACEMENT, 8, "UInt") ; 1 = normal, 2 = minimized, 3 = maximized
    WINDOWPLACEMENT := ""
    Return Result
}

SetWindowPlacement(hWnd, x, y, w, h, showCmd:=1) {
    ; showCmd: 1 = normal, 2 = minimized, 3 = maximized
    Local WINDOWPLACEMENT
    NumPut(VarSetCapacity(WINDOWPLACEMENT, 44, 0), WINDOWPLACEMENT, 0, "UInt")
    NumPut(x, WINDOWPLACEMENT, 28, "Int")
    NumPut(y, WINDOWPLACEMENT, 32, "Int")
    NumPut(w + x, WINDOWPLACEMENT, 36, "Int")
    NumPut(h + y, WINDOWPLACEMENT, 40, "Int")
    NumPut(showCmd, WINDOWPLACEMENT, 8, "UInt")
    r := DllCall("SetWindowPlacement", "UPtr", hWnd, "UPtr", &WINDOWPLACEMENT)
    WINDOWPLACEMENT := ""
    Return r
}

gregorian_to_jd(year, month, day) {
    static GREGORIAN_EPOCH := 1721425.5
    y := year - 1
    a := (GREGORIAN_EPOCH - 1)
    b := (365 * y)
    c := floor(y / 4)
    d := (-floor(y / 100))
    e := floor(y / 400)
    f := floor((((367 * month) - 362) / 12))
    g := isLeapYear(year) ? -1 : -2
    If (month<3)
       g := 0
    ; fnOutputDebug(a "|" b "|" c "|" d "|" e "|" f "|" g "|" day)
    return a + b + c + d + e + f + g + day
}

isLeap_persianYear(year) {
    return (mod((((mod((year - ((year > 0) ? 474 : 473)), 2820) + 474) + 38) * 682), 2816) < 682)
}

persian_to_jd(year, month, day) {
    static PERSIAN_EPOCH := 1948320.5
    zz := (year >= 0) ? 474 : 473
    epbase := year - zz
    epyear := 474 + mod(epbase, 2820)
    mm := (month <= 7) ? (month - 1) * 31 : (month - 1) * 30 + 6
    r := day + mm + floor(((epyear * 682) - 110) / 2816) + (epyear - 1) * 365 + floor(epbase / 2820) * 1029983 + (PERSIAN_EPOCH - 1)
    return r
}

jd_to_persian(jd) {
    jd := floor(jd) + 0.5
    depoch := jd - persian_to_jd(475, 1, 1)
    cycle := depoch // 1029983
    cyear := mod(depoch, 1029983)
    ; ToolTip, % jd "`n" depoch "`n" cycle "`n" cyear , , , 2
    if (cyear = 1029982)
    {
        ycycle := 2820
    } else
    {
        aux1 := cyear // 366
        aux2 := mod(cyear, 366)
        ycycle := floor(((2134 * aux1) + (2816 * aux2) + 2815) / 1028522) + aux1 + 1
    }

    year := ycycle + 2820 * cycle + 474
    if (year <= 0)
       year--

    yday := (jd - persian_to_jd(year, 1, 1)) + 1
    month := (yday <= 186) ? ceil(yday / 31) : ceil((yday - 6) / 30)
    day := (jd - persian_to_jd(year, month, 1)) + 1
    return [Round(year), Round(month), Round(day)]
}

isLeap_islamicYear(year) {
    return (mod(((year * 11) + 14), 30) < 11)
}

islamic_to_jd(year, month, day) {
    Static ISLAMIC_EPOCH := 1948439.5
    return (day + ceil(29.5 * (month - 1)) + (year - 1) * 354 + floor((3 + (11 * year)) / 30) + ISLAMIC_EPOCH) - 1
}

jd_to_islamic(jd) {
    Static ISLAMIC_EPOCH := 1948439.5
    jd := floor(jd) + 0.5
    year := floor(((30 * (jd - ISLAMIC_EPOCH)) + 10646) / 10631)
    month := min(12, ceil((jd - (29 + islamic_to_jd(year, 1, 1))) / 29.5) + 1)
    day := (jd - islamic_to_jd(year, month, 1)) + 1
    return [Round(year), Round(month), Round(day)]
}


hebrew_leap(year) {
    return (mod(((year * 7) + 1), 19) < 7)
}

hebrew_year_months(year, isLeap) {
    return isLeap ? 13 : 12
}

hebrew_delay_1(year) {
; Test for delay of start of new year and to avoid
; Sunday, Wednesday, and Friday as start of the new year.
    months := floor(((235 * year) - 234) / 19)
    parts := 12084 + (13753 * months)
    day := (months * 29) + floor(parts / 25920)
    if (mod((3 * (day + 1)), 7) < 3)
       day++

    return day
}

hebrew_delay_2(year) {
; Check for delay in start of new year due to length of adjacent years
    last := hebrew_delay_1(year - 1)
    present := hebrew_delay_1(year)
    next := hebrew_delay_1(year + 1)
    zz := ((present - last) = 382) ? 1 : 0
    if ((next - present) = 356)
       zz := 2

    return zz
}

hebrew_year_days(year) {
; How many days are in a Hebrew year ?
    return hebrew_to_jd(year + 1, 7, 1) - hebrew_to_jd(year, 7, 1)
}

hebrew_month_days(year, month) {
; How many days are in a given month of a given year
; First of all, dispose of fixed-length 29 day months

    if (month=2 || month=4 || month=6 || month=10 || month=13)
       return 29

    ; If it is not a leap year, Adar has 29 days
    isLeap := hebrew_leap(year)
    if (month=12 && !isLeap)
       return 29

    zz := mod(hebrew_year_days(year), 10)
    ; If it's Heshvan, days depend on length of year
    if (month=8 && zz!=5)
       return 29

    ; Similarly, Kislev varies with the length of year
    if (month=9 && zz=3)
       return 29

    ; Nope, it's a 30 day month
    return 30
}

hebrew_to_jd(year, month, day) {
    Static HEBREW_EPOCH := 347995.5
    isLeap := hebrew_leap(year)
    months := hebrew_year_months(year, isLeap)
    jd := HEBREW_EPOCH + hebrew_delay_1(year) + hebrew_delay_2(year) + day + 1

    mon := 7
    While, (mon<=months) {
        jd += hebrew_month_days(year, mon)
        mon++
    }

    if (month < 7) {
        mon := 1
        While, (mon<=months) {
            jd += hebrew_month_days(year, mon)
            mon++
        }
    }

    return jd
}

jd_to_hebrew(jd) {
    Static HEBREW_EPOCH := 347995.5

    jd := floor(jd) + 0.5
    count := floor(((jd - HEBREW_EPOCH) * 98496.0) / 35975351.0)
    year := i := count - 1
    Loop
    {
        zjd := hebrew_to_jd(i, 7, 1)
        If (jd >= zjd)
           Break

        i++
        year++
    }

    first := (jd < hebrew_to_jd(year, 1, 1)) ? 7 : 1
    month := i := first
    Loop
    {
        dayum := hebrew_month_days(year, i)
        zjd := hebrew_to_jd(year, i, dayum)
        If (jd > zjd)
           Break

        i++
        month++
    }

    day := (jd - hebrew_to_jd(year, month, 1)) + 1
    return [year, month, day]
}

FolderExist(filePath) {
   If (StrLen(filePath)<3)
      Return
   Else
      Return InStr(FileExist(filePath), "D")
}


#If, ((WinActive( "ahk_id " hSetWinGui) && isInRange(AnyWindowOpen, 1, 10)) || (WinActive( "ahk_id " hCelebsMan) && windowManageCeleb=1))
    AppsKey::
      coreSettingsContextMenu()
    Return 
#If 

#If, (WinActive( "ahk_id " hSetWinGui) && AnyWindowOpen=10)
    AppsKey::
      coreSettingsContextMenu()
    Return 

    vkBC::     ; ,
      BtnChangeDateCalendar(A_ThisHotkey, "given", "previous month")
    Return 

    vkBE::     ; .
      BtnChangeDateCalendar(A_ThisHotkey, "given", "next month")
    Return 

    PgUp::
      BtnChangeDateCalendar(A_ThisHotkey, "given", "previous year")
    Return 

    PgDn::
      BtnChangeDateCalendar(A_ThisHotkey, "given", "next year")
    Return 

    vkDB::     ; [
      BtnChangeDateCalendar(A_ThisHotkey, "given", "previous day")
    Return 

    vkDD::     ; ]
      BtnChangeDateCalendar(A_ThisHotkey, "given", "next day")
    Return 

    vkDC::      ; \
      BtnChangeDateCalendar(A_ThisHotkey, "given", "reset")
    Return 
#If 

#If, (WinActive( "ahk_id " hSetWinGui) && AnyWindowOpen=6)
    vkDC::      ; \
      UItodayPanelResetDate()
    Return 

    vkBF::      ; /
      ToggleAstroInfosModa()
    Return 

    vkBC::     ; ,
      NextTodayBTN(-1, 0, 1, 1, "hours")
    Return 

    vkBE::     ; .
      NextTodayBTN(1, 0, 1, 1, "hours")
    Return 

    +vkBC::    ; Shift + ,
      NextTodayBTN(-1, 0, 1, 2, "hours")
    Return 

    +vkBE::    ; Shift + .
      NextTodayBTN(1, 0, 1, 2, "hours")
    Return 

    vkDB::     ; [
      NextTodayBTN(-1, 0, 1, 1, "days")
    Return 

    vkDD::     ; ]
      NextTodayBTN(1, 0, 1, 1, "days")
    Return 

    +vkDB::   ; Shift + [
      NextTodayBTN(-1, 0, 1, 2, "days")
    Return 

    +vkDD::   ; Shift + ]
      NextTodayBTN(1, 0, 1, 2, "days")
    Return 

    vkBD::     ; -   (VK_OEM_MINUS)
      NextTodayBTN(-1, 0, 1, 5, "minutes")
    Return 

    vkBB::     ; =   (VK_OEM_PLUS)
      NextTodayBTN(1, 0, 1, 5, "minutes")
    Return 

    +vkBD::    ; Shift + -
      NextTodayBTN(-1, 0, 1, 10, "minutes")
    Return 

    +vkBB::    ; Shift + =
      NextTodayBTN(1, 0, 1, 10, "minutes")
    Return 
#If 

#If, (WinActive( "ahk_id " hFaceClock) && constantAnalogClock=1 && hFaceClock)
    Escape::
      hideAnalogClock()
      SetTimer, showAnalogClock, -150
    Return

    AppsKey::
      ClockGuiGuiContextMenu(34788, 0, 238990, 1, 32, 90)
    Return 

    Space::
      analogMoonPhases := clampInRange(analogMoonPhases + 1, 0, 2, 1)
      INIaction(1, "analogMoonPhases", "SavedSettings")
    Return

    Tab::
      toggleHourLabelsAnalog()
    Return
#If
