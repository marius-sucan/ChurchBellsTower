; bells-tower.ahk - main file
;
; Charset for this file must be UTF 8 with BOM.
; it may not function properly otherwise.
;
; Sounds copied from various «random» online sources.
; All audios were edited and processed to fit the needs
; of this application.
;
; Script written for AHK_H v1.1.28 Unicode.
; AHK_H available at:
; https://hotkeyit.github.io/v2/
; or https://github.com/HotKeyIt/ahkdll-v1-release
;
; Disclaimer: this script is provided "as is", without any kind of warranty.
; The author(s) shall not be liable for any damage caused by using
; this script or its derivatives,  et cetera.
;
; Compilation directives; include files in binary and set file properties
; ===========================================================
;
;@Ahk2Exe-SetName Church Bells Tower
;@Ahk2Exe-SetCopyright Marius Şucan (2017-2022)
;@Ahk2Exe-SetCompanyName http://marius.sucan.ro
;@Ahk2Exe-SetDescription Church Bells Tower
;@Ahk2Exe-SetVersion 3.1.7
;@Ahk2Exe-SetOrigFilename bells-tower.ahk
;@Ahk2Exe-SetMainIcon bells-tower.ico

;================================================================
; Section. Auto-exec.
;================================================================

; Script Initialization

 #SingleInstance Force
 #NoEnv
 #MaxMem 256
 #Include, Lib\va.ahk                   ; vista audio APIs wrapper by Lexikos
 #Include, Lib\mci.ahk
 #Include, Lib\gdip_all.ahk
 #Include, Lib\analog-clock-display.ahk
 #Include, Lib\Class_CtlColors.ahk
 #Include, Lib\Maths.ahk

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
 , AutoUnmute           := 1
 , tickTockNoise        := 0
 , strikeInterval       := 2000
 , AdditionalStrikes    := 0
 , strikeEveryMin       := 5
 , showBibleQuotes      := 0
 , BibleQuotesLang      := 1
 , makeScreenDark       := 1
 , BibleQuotesInterval  := 5
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
 , noTollingBgrSounds   := 0
 , NoWelcomePopupInfo   := 0
 , showTimeWhenIdle     := 0
 , showTimeIdleAfter    := 5 ; [in minutes]
 , markFullMoonHowls    := 0

; OSD settings
Global displayTimeFormat  := 1
 , DisplayTimeUser        := 3     ; in seconds
 , displayClock           := 1
 , analogDisplay          := 0
 , analogDisplayScale     := 0.3
 , analogMoonPhases       := 1
 , constantAnalogClock    := 0
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
 , OSDbgrColor            := "131209"
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
 , faceBgrColor  := "eeEEee"
 , faceElements  := "001100"
 , mainOSDopacity:= 230
 , faceOpacity   := 254
 , faceOpacityBgr:= Round(faceOpacity/1.25)
 , ClockPosX     := 30
 , ClockPosY     := 90
 , ClockDiameter := 480
 , ClockWinSize  := ClockDiameter + 2
 , ClockCenter   := Round(ClockWinSize/2)
 , roundedCsize  := Round(ClockDiameter/4)
 , EquiSolsCache := 0

; Release info
 , ThisFile               := A_ScriptName
 , Version                := "3.1.7"
 , ReleaseDate            := "2022 / 09 / 08"
 , storeSettingsREG := FileExist("win-store-mode.ini") && A_IsCompiled && InStr(A_ScriptFullPath, "WindowsApps") ? 1 : 0
 , ScriptInitialized, FirstRun := 1
 , QuotesAlreadySeen := "", LastWinOpened, hasHowledDay := 0
 , LastNoonAudio := 0, appName := "Church Bells Tower"
 , APPregEntry := "HKEY_CURRENT_USER\SOFTWARE\" appName "\v1-1"

   If !A_IsCompiled
      Menu, Tray, Icon, bells-tower.ico

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

Global CSthin      := "░"   ; light gray 
 , CSmid       := "▒"   ; gray 
 , CSdrk       := "▓"   ; dark gray
 , CSblk       := "█"   ; full block
 , DisplayTime := DisplayTimeUser*1000
 , BibleGuiVisible := 0
 , bibleQuoteVisible := 0
 , DoNotRepeatTimer := 0
 , PrefOpen := 0
 , FontList := []
 , userIdleAfter := showTimeIdleAfter * 60000
 , AdditionalStrikeFreq := strikeEveryMin * 60000  ; minutes
 , bibleQuoteFreq := BibleQuotesInterval * 3600000 ; hours
 , ShowPreview := 0
 , ShowPreviewDate := 0
 , LastNoonZeitSound := 1
 , OSDprefix, OSDsuffix
 , windowManageCeleb := 0
 , stopStrikesNow := 0, mouseToolTipWinCreated := 0
 , ClockVisibility := 0, quoteDisplayTime := 100
 , stopAdditionalStrikes := 0
 , strikingBellsNow := 0
 , DoGuiFader := 1
 , lastFaded := 1
 , cutVolumeHalf := 0
 , defAnalogClockPosChanged := 0
 , FontChangedTimes := 0, AnyWindowOpen := 0, CurrentPrefWindow := 0
 , mEquiDay := 79, jSolsDay := 172, sEquiDay := 266, dSolsDay := 356
 , mEquiDate := A_Year "0320010203", jSolsDaTe := A_Year "0621010203", sEquiDate := A_Year "0923010203", dSolsDaTe := A_Year "1222010203"
 , LastBibleQuoteDisplay := 1
 , LastBibleQuoteDisplay2 := 1
 , LastBibleMsg := "", AllowDarkModeForWindow := ""
 , celebYear := A_Year, userAlarmIsSnoozed := 0
 , isHolidayToday := 0, stopWatchRecordsInterval := []
 , TypeHolidayOccured := 0, userTimerExpire := 0
 , hMain := A_ScriptHwnd, stopWatchIntervalInfos := []
 , lastOSDredraw := 1, stopWatchHumanStartTime := 0
 , semtr2play := 0, stopWatchRealStartZeit := 0
 , stopWatchBeginZeit := 0, stopWatchLapBeginZeit := 0
 , stopWatchPauseZeit := 0.001, stopWatchLapPauseZeit := 0.001
 , aboutTheme, GUIAbgrColor, AboutTitleColor, hoverBtnColor, BtnTxtColor, GUIAtxtColor
 , attempts2Quit := 0, OSDfadedColor := ""
 , roundCornerSize := Round(FontSize/2) + Round(OSDmarginSides/5)
 , StartRegPath := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
 , tickTockSound := A_ScriptDir "\sounds\ticktock.wav"
 , hBibleTxt, hBibleOSD, hSetWinGui, ColorPickerHandles
 , CCLVO := "-E0x200 +Border -Hdr -Multi +ReadOnly Report AltSubmit gsetColors"
 , hWinMM := DllCall("kernel32\LoadLibraryW", "Str", "winmm.dll", "Ptr")
 , SNDmedia_ticktok, quartersTotalTime := 0, hoursTotalTime := 0
 , SNDmedia_auxil_bell, SNDmedia_japan_bell, SNDmedia_christmas
 , SNDmedia_evening, SNDmedia_midnight, SNDmedia_morning, SNDmedia_beep
 , SNDmedia_noon1, SNDmedia_noon2, SNDmedia_noon3, SNDmedia_noon4
 , SNDmedia_orthodox_chimes1, SNDmedia_orthodox_chimes2, SNDmedia_Howl
 , SNDmedia_semantron1, SNDmedia_semantron2, SNDmedia_hours12, SNDmedia_hours11
 , SNDmedia_quarters1, SNDmedia_quarters2, SNDmedia_quarters3, SNDmedia_quarters4
 , SNDmedia_hours1, SNDmedia_hours2, SNDmedia_hours3, SNDmedia_hours4, SNDmedia_hours5
 , SNDmedia_hours6, SNDmedia_hours7, SNDmedia_hours8, SNDmedia_hours9, SNDmedia_hours10
 , hFaceClock, lastShowTime := 1, pToken, scriptStartZeit := A_TickCount
 , globalG, globalhbm, globalhdc, globalobm
 , moduleAnalogClockInit := 0, darkWindowColor := 0x202020, darkControlColor := 0xEDedED

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
InitializeTray()
InitSoundChannels()
decideFadeColor()

hCursM := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32646, "Ptr")  ; IDC_SIZEALL
hCursH := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32649, "Ptr")  ; IDC_HAND
OnMessage(0x205, "WM_RBUTTONUP")
OnMessage(0x200, "WM_MouseMove")
OnMessage(0x404, "AHK_NOTIFYICON")
Sleep, 1
theChimer()
Sleep, 1
testCelebrations()
ScriptInitialized := 1      ; the end of the autoexec section and INIT
If (tickTockNoise=1)
   SoundLoop(tickTockSound)

If StrLen(isHolidayToday)<3
   CreateBibleGUI(generateDateTimeTxt())

If (AdditionalStrikes=1)
   SetTimer, AdditionalStrikerPerformer, %AdditionalStrikeFreq%

If (showBibleQuotes=1)
   SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%

If (analogDisplay=1 || constantAnalogClock=1)
   InitClockFace()

If (constantAnalogClock=1)
   SetTimer, analogClockStarter, -1000

If (NoWelcomePopupInfo!=1)
   ShowWelcomeWindow()

startAlarmTimer()
If (showTimeWhenIdle=1)
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
  SNDfile_ticktok := A_ScriptDir "\sounds\ticktock.wav"
  SNDfile_beep := A_ScriptDir "\sounds\beep.wav"

  Loop, 12
    SNDmedia_hours%A_Index% := MCI_Open(SNDfile_hours)
  Loop, 4
    SNDmedia_quarters%A_Index% := MCI_Open(SNDfile_quarters)

  SNDmedia_auxil_bell := MCI_Open(SNDfile_auxil_bell)
  SNDmedia_christmas := MCI_Open(SNDfile_christmas)
  SNDmedia_beep := MCI_Open(SNDfile_beep)
  SNDmedia_evening := MCI_Open(SNDfile_evening)
  SNDmedia_japan_bell := MCI_Open(SNDfile_japan_bell)
  SNDmedia_midnight := MCI_Open(SNDfile_midnight)
  SNDmedia_morning := MCI_Open(SNDfile_morning)
  SNDmedia_noon1 := MCI_Open(SNDfile_noon1)
  SNDmedia_noon2 := MCI_Open(SNDfile_noon2)
  SNDmedia_noon3 := MCI_Open(SNDfile_noon3)
  SNDmedia_noon4 := MCI_Open(SNDfile_noon4)
  SNDmedia_orthodox_chimes1 := MCI_Open(SNDfile_chimes1)
  SNDmedia_orthodox_chimes2 := MCI_Open(SNDfile_chimes2)
  SNDmedia_Howl := MCI_Open(SNDfile_howl)
  SNDmedia_semantron1 := MCI_Open(SNDfile_semantron1)
  SNDmedia_semantron2 := MCI_Open(SNDfile_semantron2)
  SNDmedia_ticktok := MCI_Open(SNDfile_ticktok)
}

TimerShowOSDidle() {
     Static isThisIdle := 0, lastFullMoonZeitTest := -9020
     If (constantAnalogClock=1) || (analogDisplay=1 && ClockVisibility=1) || (PrefOpen=1) || (A_IsSuspended)
        Return

     If !A_IsSuspended
        mouseHidden := checkMcursorState()

     If (showTimeWhenIdle=1 && (A_TimeIdle > userIdleAfter) && mouseHidden!=1)
     {
        FormatTime, HoursIntervalTest,, H ; 0-23 format
        If (markFullMoonHowls=1 && hasHowledDay!=A_YDay && userMuteAllSounds!=1 && lastFullMoonZeitTest!=HoursIntervalTest)
        {
           lastFullMoonZeitTest := HoursIntervalTest
           pk := MoonPhaseCalculator()
           If InStr(pk[1], "full moon (peak)")
           {
              hasHowledDay := A_YDay
              INIaction(1, "hasHowledDay", "SavedSettings")
              volumeAction := SetMyVolume()
              MCXI_Play(SNDmedia_Howl)
           }
        }
        isThisIdle := 1
        DoGuiFader := 0
        If (BibleGuiVisible!=1)
           CreateBibleGUI(generateDateTimeTxt(0, 1) "-", 0, 0, 1)

        GuiControl, BibleGui:, BibleGuiTXT, % generateDateTimeTxt(0, 1)
        SetTimer, DestroyBibleGui, Delete
        DoGuiFader := 1
     } Else If (showTimeWhenIdle=1 && BibleGuiVisible=1 && isThisIdle=1)
     {
        isThisIdle := 0
        SetTimer, DestroyBibleGui, -500
     } Else isThisIdle := 0
}

ShowWelcomeWindow() {
    If reactWinOpened(A_ThisFunc, 2)
       Return

    Global BtnSilly0, BtnSilly1, BtnSilly2
    GenericPanelGUI()
    AnyWindowOpen := 2
    Gui, Font, s20 Bold, Arial, -wrap
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section hwndhIcon, bell-image.png
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
    Gui, Add, Button, xs y+15 w%btnWid% h%sm% gShowSettings, &Settings panel
    Gui, Add, Checkbox, x+5 w%btnWid% hp +0x1000 gToggleLargeFonts Checked%PrefsLargeFonts% vPrefsLargeFonts, Large UI font sizes
    Gui, Add, Button, xs y+10 w%btnWid% hp gPanelAboutWindow, &About today
    Gui, Add, Checkbox, x+5 w%btnWid% hp +0x1000 gToggleAnalogClock Checked%constantAnalogClock% vconstantAnalogClock, &Analog clock display
    Gui, Add, Checkbox, xs y+10 hp gToggleWelcomeInfos Checked%NoWelcomePopupInfo% vNoWelcomePopupInfo, &Never show this window
    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Welcome to %appName% v%Version%
}

ToggleWelcomeInfos() {
  Gui, SettingsGUIA: Default
  GuiControlGet, NoWelcomePopupInfo
;  NoWelcomePopupInfo := !NoWelcomePopupInfo
  INIaction(1, "NoWelcomePopupInfo", "SavedSettings")
  CloseWindow()
  Sleep, 10
  If (NoWelcomePopupInfo=1)
  {
     MsgBox, 52, %appName%, Do you want to keep the welcome window open for now?
     IfMsgBox, Yes
       ShowWelcomeWindow()
  } Else ShowWelcomeWindow()
}

analogClockStarter() {
  If (constantAnalogClock=1)
  {
     If (moduleAnalogClockInit!=1)
        InitClockFace()
     ; ClockVisibility := 1
     ; DestroyBibleGui(A_ThisFunc)
     showAnalogClock()
  }
}

decideSysTrayTooltip() {
    Static lastInvoked := 1, lastMsg
    If (A_TickCount - lastInvoked<450)
       Return lastMsg

    RunType := A_IsCompiled ? "" : " [script]"
    If A_IsSuspended
       RunType := " [DEACTIVATED]"
    If (userMustDoTimer=1 && userTimerExpire)
       timerInfos := "`nTimer set to expire at: " userTimerExpire

    If (userMustDoAlarm=1 && (userAlarmMins || userAlarmHours))
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

          alarmInfos := canDo ? "`nDaily alarm set at: " timeu : "`nDaily alarm set: exception rule applies"
       } Else
          alarmInfos := "`nAlarm set at: " timeu
    }

    If (stopWatchRealStartZeit || stopWatchBeginZeit)
       stopwInfos := "`nStopwatch is running"
    If (userMuteAllSounds=1 || BeepsVolume<2)
       soundsInfos := "`nAll sounds are muted"

    thisHoli := (TypeHolidayOccured=3) ? "personal" : "religious"
    If (TypeHolidayOccured=2) ; secular
       thisHoli := "secular"

    thisHoli := (StrLen(isHolidayToday)>2) ? "`nToday a " thisHoli " event is observed" : ""
    testu := wrapCalculateEquiSolsDates()
    If (testu.r=1)
       resu := "`nMarch equinox"
    Else If (testu.r=2)
       resu := "`nJune solstice"
    Else If (testu.r=3)
       resu := "`nSeptember equinox"
    Else If (testu.r=4)
       resu := "`nDecember solstice"

    Menu, Tray, Tip, % appName " v" Version RunType timerInfos alarmInfos stopwInfos  thisHoli resu soundsInfos
    lastInvoked := A_TickCount
    lastMsg :=  timerInfos alarmInfos stopwInfos  thisHoli resu soundsInfos
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
        CreateBibleGUI(generateDateTimeTxt() extras, 0, 0, 1)
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
        CreateBibleGUI(generateDateTimeTxt() extras, 0, 0, 1)
     If (tollQuarters=1)
        strikeQuarters(1)
     If (tollHours=1 || tollHoursAmount=1)
        strikeHours(1)
     DoGuiFader := 1
  } Else If (BibleGuiVisible=0 && strikingBellsNow=0)
    && (A_TickCount-lastInvoked>2000) && (A_TickCount-lastFaded>1500)
  {
     LastInvoked := A_TickCount
     DoGuiFader := 0
     ; If (ClockVisibility=0 || defAnalogClockPosChanged=1 && ClockVisibility=1) && (ScriptInitialized=1)
     If (ScriptInitialized=1)
        CreateBibleGUI(generateDateTimeTxt(0))
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
  
  If (PrefOpen=0 && A_IsSuspended) || (stopAdditionalStrikes=1 && PrefOpen=0)
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
     If (BibleQuotesLang=2)
        lang := "fra"
     Else If (BibleQuotesLang=3)
        lang := "esp"
     Else
        lang := "eng"
     Try FileRead, bibleQuotesFile, bible-quotes-%lang%.txt
     lastLoaded := A_TickCount
     If ErrorLevel
     {
        bibleQuotesFile := ""
        Return
     }
  }

  If (orderedBibleQuotes=1)
  {
     Line2Read := (userBibleStartPoint + 1, 1, countLines, 1)
     userBibleStartPoint := Line2Read
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
  If InStr(bibleQuote, " || ")
  {
     lineArr := StrSplit(bibleQuote, " || ")
     bibleQuote := lineArr[2]
  }

  If (ST_Count(bibleQuote, """")=1)
     StringReplace, bibleQuote, bibleQuote, "

  If (BibleQuotesLang=1)
  {
     bibleQuote := RegExReplace(bibleQuote, "i)(\ssaying.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\ssaid.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\sand.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\sbut)$")
  }

  bibleQuote := RegExReplace(bibleQuote, "i)(\;|\,|\:)$")
  If (StrLen(bibleQuote)>6)
  {
     LastBibleMsg := bibleQuote
     QuotesAlreadySeen .= "a" Line2Read "a"
     StringReplace, QuotesAlreadySeen, QuotesAlreadySeen, aa, a
     StringRight, QuotesAlreadySeen, QuotesAlreadySeen, 91550
     LastBibleQuoteDisplay := LastBibleQuoteDisplay2 := A_TickCount
     Sleep, 2
     CreateBibleGUI(bibleQuote, 1, 1)

     If (PrefOpen!=1)
     {
        SetMyVolume(1)
        INIaction(1, "QuotesAlreadySeen", "SavedSettings")
        If (mouseHidden!=1)
           strikeJapanBell()
     } Else strikeJapanBell()
 
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

DestroyBibleGui(funcu:=0, forced:=0) {
  Critical, On
  If (forced=1 || PrefOpen=1)
     LastBibleQuoteDisplay := 1

  If (A_TickCount - LastBibleQuoteDisplay<quoteDisplayTime) && (PrefOpen=0)
  {
     SetTimer, DestroyBibleGui, -50
     Return
  }
  ; SoundBeep
  ; ToolTip, % funcu , , , 2
  GuiFader("ChurchTowerBibleWin","hide", OSDalpha)
  Gui, BibleGui: Destroy
  GuiFader("ScreenShader","hide", 130)
  Gui, ScreenBl: Destroy
  GuiFader("BibleShareBtn","hide", OSDalpha)
  Gui, ShareBtnGui: Destroy
  BibleGuiVisible := 0
}

ShowLastBibleMsg() {
  If (StrLen(LastBibleMsg)>6 && PrefOpen!=1)
  {
     DoGuiFader := 1
     LastBibleQuoteDisplay := A_TickCount
     CreateBibleGUI(LastBibleMsg, 1, 1)
     strikeJapanBell()
     quoteDisplayTime := 1500 + StrLen(LastBibleMsg) * 123
     SetTimer, DestroyBibleGui, % -quoteDisplayTime
  } Else
     CreateBibleGUI("No Bible quote previously displayed", 0, 0, 1)
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
     SetVolume(BeepsVolume)
     Return
  }

  If (BeepsVolume<2)
  {
     SetVolume(0)
     Return
  }

  If (A_TickCount - LastNoonZeitSound<150000) && (PrefOpen=0 && noTollingBgrSounds=2)
     Return

  If (ScriptInitialized=1 && AutoUnmute=1 && BeepsVolume>3 && userMuteAllSounds=0
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
     If (Round(master_vol)<2)
     {
        SoundSet, 3
        mustRestoreVol := (mustRestoreVol=1) ? 3 : 2
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

volSlider() {
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
  quartersTotalTime := 0
  Loop, %beats%
  {
      randomDelay := RandomNumberCalc()
      fn := Func("MCXI_Play").Bind(SNDmedia_quarters%A_Index%)
      thisDelay := strikeInterval * (A_Index - 1) + randomDelay//2 + delayu
      quartersTotalTime := thisDelay + 2500
      SetTimer, % fn, % -thisDelay
  }
}

strikeHours(beats, delayu:=0) {
  hoursTotalTime := 0
  Loop, %beats%
  {
      randomDelay := RandomNumberCalc()
      fn := Func("MCXI_Play").Bind(SNDmedia_hours%A_Index%)
      thisDelay := strikeInterval * (A_Index - 1) + randomDelay//2 + delayu
      ; If (A_Index>1)
      ;    thisDelay += 4000

      hoursTotalTime := thisDelay + 5500
      SetTimer, % fn, % -thisDelay
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
  If (noTollingBgrSounds>=2)
     isSoundPlayingNow()

  If (noTollingWhenMhidden=1)
     mouseHidden := checkMcursorState()

  If (mouseHidden=1 || A_IsSuspended || strikingBellsNow=1)
     Return

  SetMyVolume(1)
  MCXI_Play(SNDmedia_auxil_bell)
}

PlayAlarmedBell() {
   Static indexu := 0, bu := 0
   SetMyVolume(1)
   If (userAlarmSound=1)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_auxil_bell)
   } Else If (userAlarmSound=2)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_quarters%indexu%)
   } Else If (userAlarmSound=3)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_hours%indexu%)
   } Else If (userAlarmSound=4)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_japan_bell)
   } Else If (userAlarmSound=5)
   {
      MCXI_Play(SNDmedia_beep)
   }
}

PlayTimerBell() {
   Static indexu := 0, bu := 0
   SetMyVolume(1)
   If (userTimerSound=1)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_auxil_bell)
   } Else If (userTimerSound=2)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_quarters%indexu%)
   } Else If (userTimerSound=3)
   {
      indexu := clampInRange(indexu + 1, 1, 4, 1)
      MCXI_Play(SNDmedia_hours%indexu%)
   } Else If (userTimerSound=4)
   {
      bu := !bu
      If bu
         MCXI_Play(SNDmedia_japan_bell)
   } Else If (userTimerSound=5)
   {
      MCXI_Play(SNDmedia_beep)
   }
}

MCXI_Play(hSND) {
    If (stopAdditionalStrikes=1 || stopStrikesNow=1 || userMuteAllSounds=1 || BeepsVolume<2)
       Return

    MCI_SendString("seek " hSND " to 1 wait")
    MCI_Play(hSND)
}

readjustBibleTimer() {
  SetTimer, InvokeBibleQuoteNow, Off
  Sleep, 5
  SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%
}

theChimer() {
  Critical, on
  Static lastChimed, todayTest, lastFullMoonZeitTest := -9000

  FormatTime, CurrentTime,, hh:mm
  If (lastChimed=CurrentTime || A_IsSuspended || PrefOpen=1)
     mustEndNow := 1

  FormatTime, exactTime,, HH:mm
  FormatTime, HoursIntervalTest,, H ; 0-23 format
  If (noTollingBgrSounds>=2)
  { 
     testBgrNoise := isSoundPlayingNow()
     If (testBgrNoise=1 && noTollingBgrSounds=3)
        mustEndNow := stopAdditionalStrikes := 1
  }

  If (noTollingWhenMhidden=1)
     mouseHidden := checkMcursorState()

  If (todayTest!=A_YDay && ScriptInitialized=1)
  {
     Sleep, 10
     testCelebrations()
  }

  If (markFullMoonHowls=1 && hasHowledDay!=A_YDay && mouseHidden!=1 && mustEndNow!=1 && userMuteAllSounds!=1 && lastFullMoonZeitTest!=HoursIntervalTest)
  {
     lastFullMoonZeitTest := HoursIntervalTest
     pk := MoonPhaseCalculator()
     If InStr(pk[1], "full moon (peak)")
     {
        hasHowledDay := A_YDay
        INIaction(1, "hasHowledDay", "SavedSettings")
        volumeAction := SetMyVolume()
        MCXI_Play(SNDmedia_Howl)
     }
  }

  todayTest := A_YDay
  If (isInRange(HoursIntervalTest, silentHoursA, silentHoursB) && silentHours=2)
     soundBells := 1

  If (isInRange(HoursIntervalTest, silentHoursA, silentHoursB) && silentHours=3)
  || (soundBells!=1 && silentHours=2) || (mustEndNow=1) || (mouseHidden=1)
  {
     If (mustEndNow!=1)
        stopAdditionalStrikes := 1
     SetTimer, theChimer, % calcNextQuarter()
     Return
  }

  If (A_TickCount - LastBibleQuoteDisplay2<95000) && (showBibleQuotes=1)
     SetTimer, readjustBibleTimer, -265100, 900

  SoundGet, master_vol
  DoGuiFader := 1
  stopStrikesNow := stopAdditionalStrikes := 0
  startAlarmTimer()
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
     If (BeepsVolume>1)
        MCXI_Play(SNDmedia_evening)

     If (StrLen(isHolidayToday)>2 && SemantronHoliday=0 && TypeHolidayOccured>1)
        tollGivenNoon(0, 51000 + delayRandNoon + NoonTollQuartersDelay)
  } Else If (InStr(exactTime, "00:00") && tollNoon=1)
  {
     NoonTollQuartersDelay := 6500
     volumeAction := SetMyVolume()
     showTimeNow()
     If (BeepsVolume>1)
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
        strikeHours(countHours2beat, delayRand//2 + quartersTotalTime)
     } Else If (tollHours=1)
     {
        volumeAction := SetMyVolume()
        showTimeNow()
        strikeHours(1, delayRand//2 + quartersTotalTime)
     }

     If (InStr(exactTime, "12:0") && tollNoon=1)
     {
        Random, delayRand2, 2000, 8500
        volumeAction := SetMyVolume()
        If (tollHours=0)
           showTimeNow()

        If (stopStrikesNow=0 && BeepsVolume>1)
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

  ; If (AutoUnmute=1 && volumeAction>0)
  ; {
  ;    If (volumeAction=1 || volumeAction=3)
  ;       SoundSet, 1, , mute
  ;    If (volumeAction=2 || volumeAction=3)
  ;       SoundSet, %master_vol%
  ; }

  strikingBellsNow := 0
  lastChimed := CurrentTime
  SetTimer, theChimer, % calcNextQuarter()
}

showTimeNow() {
  If (displayClock=0) || (A_TickCount - scriptStartZeit<1500)
     Return

  If (analogDisplay=1)
  {
     ClockPosX := GuiX
     ClockPosY := GuiY
     If (moduleAnalogClockInit!=1)
        InitClockFace()
     showAnalogClock()
     ; DestroyBibleGui(A_ThisFunc)
  } Else If (BibleGuiVisible!=1)
  {
     CreateBibleGUI(generateDateTimeTxt(1,1))
     SetTimer, DestroyBibleGui, % - (DisplayTime + 50)
  }
}

calcNextQuarter() {
  result := ((15 - Mod(A_Min, 15)) * 60 - A_Sec) * 1000 - A_MSec + 50
  ; formula provided by Bon [AHK forums]
  Return result
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

CreateBibleGUI(msg2Display, isBibleQuote:=0, centerMsg:=0, noAdds:=0) {
    Critical, On
    lastOSDredraw := A_TickCount
    bibleQuoteVisible := (isBibleQuote=1) ? 1 : 0
    FontSizeMin := (isBibleQuote=1) ? FontSizeQuotes : FontSize
    If (isBibleQuote!=1 && noAdds=1 && InStr(msg2Display, "`n"))
       FontSizeMin := Round(FontSize*0.7)

    GuiFader("ChurchTowerBibleWin","hide", OSDalpha)
    Sleep, 2
    Gui, BibleGui: Destroy
    Sleep, 25
    Global BibleGuiTXT
    If (isBibleQuote=1)
       msg2Display := ST_wordWrap(msg2Display, maxBibleLength)
    Else If (noAdds=0)
       msg2Display := OSDprefix msg2Display OSDsuffix

    HorizontalMargins := (isBibleQuote=1) ? OSDmarginSides : 1
    Gui, BibleGui: -DPIScale -Caption +Owner +ToolWindow +HwndhBibleOSD
    Gui, BibleGui: Margin, %OSDmarginSides%, %HorizontalMargins%
    Gui, BibleGui: Color, %OSDbgrColor%

    If (FontChangedTimes>190)
       Gui, BibleGui: Font, c%OSDtextColor% s%FontSizeMin% Q4 Bold,
    Else
       Gui, BibleGui: Font, c%OSDtextColor% s%FontSizeMin% Q4 Bold, %FontName%

    Gui, BibleGui: Font, s1
    If (isBibleQuote=0)
    {
       Gui, BibleGui: Add, Text, w2 h%OSDmarginTop% BackgroundTrans, .
       dontWrap := " -wrap"
    }
    Gui, BibleGui: Font, s%FontSizeMin% Q4
    Gui, BibleGui: Add, Text, y+%HorizontalMargins% hwndhBibleTxt vBibleGuiTXT %dontWrap%, %msg2Display%
    Gui, BibleGui: Font, s1
    If (isBibleQuote=0)
       Gui, BibleGui: Add, Text, w2 y+0 h%OSDmarginBottom% BackgroundTrans, .

    Gui, BibleGui: Show, NoActivate AutoSize Hide x%GuiX% y%GuiY%, ChurchTowerBibleWin
    WinSet, Transparent, 1, ChurchTowerBibleWin
    WinGetPos,,, mainWid, mainHeig, ahk_id %hBibleOSD%

    If (isBibleQuote=0 && InStr(msg2Display, ":") && !InStr(msg2Display, "`n") && showOSDprogressBar>1)
    {
       If (showOSDprogressBar=2)
       {
          percu := Round(getPercentOfToday() * 100)
       } Else If (showOSDprogressBar=3)
       {
          moonPhase := MoonPhaseCalculator()
          percu := Round(moonPhase[3] * 100)
       } Else If (showOSDprogressBar=4)
       {
          percu := Round((A_MDay/31) * 100)
       } Else If (showOSDprogressBar=5)
       {
          percu := Round(getPercentOfAstroSeason() * 100)
       } Else If (showOSDprogressBar=6)
       {
          percu := Round((A_YDay/366) * 100)
       }

       hu := Ceil(mainHeig*0.04 + 1)
       coloru := (percu=25 || percu=49 || percu=50 || percu=51 || percu=75) ? OSDtextColor : OSDfadedColor
       Gui, BibleGui: Add, Progress, x0 y0 w%mainWid% h%hu% c%coloru% background%OSDbgrColor%, % percu "%"
    }

    If (centerMsg=1)
    {
       If (makeScreenDark=1)
          ScreenBlocker(0,1)

       ActiveMon := MWAGetMonitorMouseIsIn()
       If ActiveMon
       {
          SysGet, mCoord, MonitorWorkArea, %ActiveMon%
          semiFinal_x := semiFinal_y := mCoordLeft + 20
          Gui, BibleGui: Show, NoActivate Hide AutoSize x%semiFinal_x% y%semiFinal_y%
          Sleep, 25
          WinGetPos,,, mainWid, mainHeig, ahk_id %hBibleOSD%
          dummyA := min(mCoordRight, mCoordLeft) + max(mCoordRight, mCoordLeft)
          dummyB := min(mCoordTop, mCoordBottom) + max(mCoordTop, mCoordBottom)
          bGuiX := Round(dummyA/2 - mainWid/2)
          bGuiY := Round(dummyB/2 - mainHeig/2)
          Final_x := max(mCoordLeft, min(bGuiX, mCoordRight - mainWid))
          Final_y := max(mCoordTop, min(bGuiY, mCoordBottom - mainHeig))
       } Else
       {
          Final_x := GuiX
          Final_y := GuiY
       }

       Gui, BibleGui: Show, NoActivate AutoSize x%Final_x% y%Final_y%, ChurchTowerBibleWin
       If (isBibleQuote=1)
          CreateShareButton()
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

       Gui, BibleGui: Show, NoActivate x%Final_x% y%Final_y%, ChurchTowerBibleWin
    }

    WinSet, Transparent, 1, ChurchTowerBibleWin
    WinSet, AlwaysOnTop, On, ChurchTowerBibleWin
    BibleGuiVisible := 1

    If (isBibleQuote=0 && PrefOpen!=1)
       SetTimer, DestroyBibleGui, % -DisplayTime

    If (OSDroundCorners=1)
    {
       WinSet, Region, 0-0 R%roundCornerSize%-%roundCornerSize% w%mainWid% h%mainHeig%, ChurchTowerBibleWin
       Try FrameShadow(hBibleOSD)     
    }

    GuiFader("ChurchTowerBibleWin","show", OSDalpha)
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
    marginz := Round(OSDmarginSides/2)
    If (marginz<FontSizeMin)
       marginz := FontSizeMin
    If (FontSizeMin<9)
       FontSizeMin := 9
    Gui, ShareBtnGui: Destroy
    Sleep, 25
    Gui, ShareBtnGui: -DPIScale -Caption +Owner +ToolWindow +hwndhShareBtn
    Gui, ShareBtnGui: Margin, %marginz%, %marginz%
    Gui, ShareBtnGui: Color, c%OSDtextColor%
    Gui, ShareBtnGui: Font, %OSDbgrColor% s%FontSizeMin% Bold,
    Gui, ShareBtnGui: Add, Text, c%OSDbgrColor% gCopyLastQuote, Copy and share quote
    ActiveMon := MWAGetMonitorMouseIsIn()
    If ActiveMon
    {
       SysGet, mCoord, MonitorWorkArea, %ActiveMon%
       Final_x := mCoordLeft + Round(OSDmarginSides/2)
       Final_y := mCoordTop + Round(OSDmarginSides/2)
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
   If (constantAnalogClock!=1)
      Return

   ClockPosX := ClockPosY := 1
   Gui, ClockGui: Show, NoActivate x%ClockPosX% y%ClockPosY%
   saveAnalogClockPosition("no")
   If (constantAnalogClock!=1)
      Gui, ClockGui: Hide
}

WM_MouseMove(wP, lP, msg, hwnd) {
; Function by Drugwash
  Global
  MouseGetPos, , , OutputVarWin
  Local A
  SetFormat, Integer, H
  hwnd+=0, A := OutputVarWin, hwnd .= "", A .= ""
  SetFormat, Integer, D
  HideDelay := (PrefOpen=1) ? 600 : 2050
  If (A_TickCount - LastBibleQuoteDisplay<HideDelay+100) || (A_TickCount - lastOSDredraw<1000)
     Return

  If ((constantAnalogClock=1 || PrefOpen=1) && A=hFaceClock)
  {
     If (wP&0x1)
     {
        PostMessage, 0xA1, 2,,, ahk_id %hFaceClock%
        SetTimer, trackMouseAnalogClockDragging, -25
     }
     DllCall("user32\SetCursor", "Ptr", hCursM)
  ; } Else If (constantAnalogClock=0 || PrefOpen=1 && (wP&0x1)) && (A_TickCount - lastShowTime>950)
  ; {
  ;    hideAnalogClock()
  ;    SetTimer, showAnalogClock, -900
  } Else If InStr(hBibleOSD, hwnd)
  {
     If (PrefOpen=0)
        DestroyBibleGui(A_ThisFunc, 1)
     DllCall("user32\SetCursor", "Ptr", hCursM)
     If !(wP&0x13)    ; no LMR mouse button is down, we hover
     {
        If A not in %hBibleOSD%
           hAWin := A
     } Else If (wP&0x1) && (bibleQuoteVisible=0) ; L mouse button is down, we're dragging
     {
        SetTimer, DestroyBibleGui, Off
        PostMessage, 0xA1, 2,,, ahk_id %hBibleOSD%
        DllCall("user32\SetCursor", "Ptr", hCursM)
        SetTimer, trackMouseDragging, -50
        Sleep, 2
     } Else If ((wP&0x2) || (wP&0x10) || bibleQuoteVisible=1)
        DestroyBibleGui(A_ThisFunc)
  } Else If ColorPickerHandles
  {
     If hwnd in %ColorPickerHandles%
        DllCall("user32\SetCursor", "Ptr", hCursH)
  } Else If (InStr(hwnd, hBibleOSD) && (A_TickCount - LastBibleQuoteDisplay>HideDelay))
        DestroyBibleGui(A_ThisFunc, 1)
}


trackMouseAnalogClockDragging() {
     defAnalogClockPosChanged := 1
     WinGetPos, ClockPosX, ClockPosY,,, ahk_id %hFaceClock%
     ; SetTimer, trackMouseDragging, -150
     SetTimer, saveAnalogClockPosition, -150
}

trackMouseDragging() {
  Global

  If (PrefOpen!=1)
     Return

  WinGetPos, NewX, NewY,,, ahk_id %hBibleOSD%
  GuiX := !NewX ? "2" : NewX
  GuiY := !NewY ? "2" : NewY
  If (PrefOpen=1)
     lastOSDredraw := 1

  If hAWin
  {
     If hAWin not in %hBibleOSD%
        WinActivate, ahk_id %hAWin%
  }
  If (bibleQuoteVisible=0)
     SetTimer, saveGuiPositions, -150
 
  If (GetKeyState("LButton", "P") && PrefOpen=0)
     SetTimer, trackMouseDragging, -150
}

saveGuiPositions() {
; function called after dragging the OSD to a new position

  If (PrefOpen=0)
  {
     Sleep, 300
     SetTimer, DestroyBibleGui, -1500
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
  If (PrefOpen=1)
  {
     GuiX := ClockPosX, GuiY := ClockPosY
     GuiControl, SettingsGUIA:, GuiX, %GuiX%
     GuiControl, SettingsGUIA:, GuiY, %GuiY%
  } Else
  {
    INIaction(1, "ClockGuiX", "OSDprefs")
    INIaction(1, "ClockGuiY", "OSDprefs")
    Sleep, 10
   }
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
     Menu, Tray, Check, Start at boot
     CreateBibleGUI("Enabled Start at Boot",,,1)
  } Else
  {
     RegDelete, %StartRegPath%, %appName%
     Menu, Tray, Uncheck, Start at boot
     CreateBibleGUI("Disabled Start at Boot",,,1)
  }
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
   GuiFader("ChurchTowerBibleWin","hide", OSDalpha)
   If !A_IsSuspended
   {
      stopStrikesNow := 1
      DoGuiFader := 0
      SetTimer, theChimer, Off
      Menu, Tray, Uncheck, &%appName% activated
      SoundLoop("")
      If (constantAnalogClock=1)
         hideAnalogClock()
   } Else
   {
      If (partially=1)
         Gui, BibleGui: Destroy
      stopStrikesNow := 0
      Menu, Tray, Check, &%appName% activated
      theChimer()
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
         CreateBibleGUI(appName friendlyName,,,1)
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

InitializeTray() {
    Menu, Tray, NoStandard
    Menu, Tray, Add, &Customize, ShowSettings
    Menu, Tray, Add, Large UI &fonts, ToggleLargeFonts
    If (storeSettingsREG=0)
       Menu, Tray, Add, Start at boot, SetStartUp

    Menu, Tray, Add, Dar&k mode UI, ToggleDarkMode
    If (uiDarkMode=1)
       Menu, Tray, Check, Dar&k mode UI

    RegRead, currentReg, %StartRegPath%, %appName%
    If (StrLen(currentReg)>5 && storeSettingsREG=0)
       Menu, Tray, Check, Start at boot

    If (PrefsLargeFonts=1)
       Menu, Tray, Check, Large UI &fonts

    Menu, Tray, Add
    If FileExist(tickTockSound)
    {
       Menu, Tray, Add, Tick/Toc&k sound, ToggleTickTock
       If (tickTockNoise=1)
          Menu, Tray, Check, Tick/Toc&k sound
    }

    Menu, Tray, Add, Analo&g clock display, toggleAnalogClock
    Menu, Tray, Add, Reset analog clock position, ResetAnalogClickPosition
    Menu, Tray, Add, Set &alarm or timer, PanelSetAlarm
    Menu, Tray, Add, Stop&watch, PanelStopWatch
    If (ObserveHolidays=1)
    {
       Menu, Tray, Add, Celebrations / &holidays, PanelIncomingCelebrations
       ; Menu, Tray, Add, Mana&ge celebrations, OpenListCelebrationsBtn
    }

    If (ShowBibleQuotes=1)
       Menu, Tray, Add, Show pre&vious Bible quote, ShowLastBibleMsg
    Menu, Tray, Add, Show a Bible &quote now, InvokeBibleQuoteNow
    Menu, Tray, Add
    Menu, Tray, Add, &%appName% activated, SuspendScriptNow
    Menu, Tray, Check, &%appName% activated
    Menu, Tray, Add, &Mute all sounds, ToggleAllMuteSounds
    If (userMuteAllSounds=1)
       Menu, Tray, Check, &Mute all sounds
    Menu, Tray, Add, &Restart, ReloadScriptNow
    Menu, Tray, Add
    Menu, Tray, Add, Abou&t, PanelAboutWindow
    Menu, Tray, Add
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
    ReloadScript()
}

ToggleLargeFonts() {
    PrefsLargeFonts := !PrefsLargeFonts
    LargeUIfontValue := 13
    INIaction(1, "PrefsLargeFonts", "SavedSettings")
    INIaction(1, "LargeUIfontValue", "SavedSettings")
    Menu, Tray, % (PrefsLargeFonts=0 ? "Uncheck" : "Check"), Large UI &fonts
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
    Menu, Tray, % (userMuteAllSounds=0 ? "Uncheck" : "Check"), &Mute all sounds
    If (tickTockNoise=1)
       ToggleTickTock()
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
    Menu, Tray, % (tickTockNoise=0 ? "Uncheck" : "Check"), Tick/Toc&k sound

    If (tickTockNoise=1)
       SoundLoop(tickTockSound)
    Else
       SoundLoop("")

    If (constantAnalogClock=1)
       SynchSecTimer()

    If (noTollingBgrSounds>=2)
       isSoundPlayingNow()

    SetMyVolume(1)
}

toggleMoonPhasesAnalog() {
    analogMoonPhases := !analogMoonPhases
    INIaction(1, "analogMoonPhases", "SavedSettings")
}

ChangeClockSize(newSize) {
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
      If (PrefOpen=1)
         WinActivate, ahk_id %hSetWinGui%
      Return
   }

   analogDisplayScale := newSize
   INIaction(1, "analogDisplayScale", "OSDprefs")
   reInitializeAnalogClock()
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
   If (o_constantAnalogClock && hFaceClock)
      saveAnalogClockPosition()

   If (constantAnalogClock=1 && moduleAnalogClockInit!=1)
      InitClockFace()

   LastWinOpened := A_ThisFunc
   INIaction(1, "LastWinOpened", "SavedSettings")
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
    DoGuiFader := 1
    DestroyBibleGui(A_ThisFunc)
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
       MsgBox,, %appName%, FATAL ERROR: Main file missing. Execution terminated.
       ExitApp
    }
}

DeleteSettings() {
    Gui, SettingsGUIA: +OwnDialogs
    MsgBox, 4, %appName%, Are you sure you want to delete the stored settings?
    IfMsgBox, Yes
    {
       If (storeSettingsREG=0)
       {
          FileSetAttrib, -R, %IniFile%
          FileDelete, %IniFile%
       } Else RegWrite, REG_SZ, %APPregEntry%, FirstRun, 1  
       Cleanup()
       Try Reload
       Sleep, 70
       ExitApp
    }
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
   DoGuiFader := 1
   PrefOpen := 0
   DestroyBibleGui(A_ThisFunc)
   Sleep, 50
   If (FileExist(ThisFile) && showMSG)
   {
      INIsettings(1)
      CreateBibleGUI("Bye byeee :-)",,,1)
      Sleep, 350
   } Else If showMSG
   {
      CreateBibleGUI("Adiiooosss :-(((",,,1)
      Sleep, 950
   }
   DestroyBibleGui(A_ThisFunc)
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
   applyDarkMode2guiPre(hSetWinGui)
}

applyDarkMode2guiPre(hThisWin) {
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

determineUIcolors() {
   aboutTheme := (A_Hour<9) || (A_Hour>22) ? "night" : "day"
   If (aboutTheme="day")
   {
      GUIAbgrColor := "faf7f2"
      GUIAtxtColor := "111100"
      AboutTitleColor := "1166AA"
      hoverBtnColor := "448855"
      BtnTxtColor := "ffffff"
   } Else
   {
      GUIAbgrColor := "222010"
      GUIAtxtColor := "ffeedd"
      AboutTitleColor := "eebb22"
      hoverBtnColor := "ffeedd"
      BtnTxtColor := "000000"
   }
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
    Static BS_CHECKBOX := 0x2, BS_RADIOBUTTON := 0x8
    If (uiDarkMode=1)
    {
       if !whichGui
          whichGui := "SettingsGUIA"
       if !hwndGUI
          hwndGUI := hSetWinGui

       setDarkWinAttribs(hwndGUI)
       WinGet,strControlList, ControlList, ahk_id %hwndGUI%
       Gui, %whichGUI%: Color, %intWindowColor%, %intControlColor%
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
            IF (CtrlStyle & BS_RADIOBUTTON) || (CtrlStyle & BS_CHECKBOX)
               doAttachCtlColor := 2
            IF (CtrlStyle & 0x1000)
               doAttachCtlColor := 1
         } Else If InStr(CtrlClass, "ComboBox")
            doAttachCtlColor := 1
         Else If InStr(CtrlClass, "Edit")
            doAttachCtlColor := -1
         Else If (InStr(CtrlClass, "Static") || InStr(CtrlClass, "syslink"))
            doAttachCtlColor := -2 

         If InStr(CtrlClass, "syslink")
            LinkUseDefaultColor(strControlHwnd, 1, whichGui)

         If (doAttachCtlColor=1)
            CtlColors.Attach(strControlHwnd, SubStr(darkWindowColor, 3), SubStr(darkControlColor, 3))

         If (doAttachCtlColor!=2 && doAttachCtlColor!=-2)
            DllCall("uxtheme\SetWindowTheme", "ptr", strControlHwnd, "str", "DarkMode_Explorer", "ptr", 0)
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
    ShowSettings()
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
    ResetStopWatchCounter()
    If (tickTockNoise!=1)
       SoundLoop("")

    Gui, SettingsGUIA: Destroy
    hSetWinGui := ""
}

CloseSettings() {
   Gui, SettingsGUIA: Default
   GuiControlGet, ApplySettingsBTN, Enabled
   PrefOpen := 0
   CloseWindow()
   If (ApplySettingsBTN=0)
   {
      ShowPreview := 1
      OSDpreview()
      Sleep, 25
      SuspendScript()
      ShowPreview := 0
      Return
   }
   Sleep, 100
   ReloadScript()
}

SettingsGUIAGuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y) {
    Static lastInvoked := 1
    Menu, ContextMenu, UseErrorLevel
    Menu, ContextMenu, Delete
    Sleep, 25
    If (CtrlHwnd && IsRightClick=1) || (mouseToolTipWinCreated=1)
    || ((A_TickCount-lastInvoked>250) && IsRightClick=0)
    {
       lastInvoked := A_TickCount
       Return
    }

    Menu, ContextMenu, Add, L&arge UI fonts, ToggleLargeFonts
    If (PrefOpen=0)
    {
       Menu, ContextMenu, Add, Dar&k mode UI, ToggleDarkMode
       If (uiDarkMode=1)
          Menu, ContextMenu, Check, Dar&k mode UI

       Menu, ContextMenu, Add, &Mute all sounds, ToggleAllMuteSounds
       If FileExist(tickTockSound)
       {
          Menu, ContextMenu, Add, Tick/Toc&k sound, ToggleTickTock
          If (tickTockNoise=1)
             Menu, ContextMenu, Check, Tick/Toc&k sound
       }
       Menu, ContextMenu, Add, Analo&g clock display, toggleAnalogClock
       If (constantAnalogClock=1)
          Menu, ContextMenu, Check, Analo&g clock display

       If (userMuteAllSounds=1)
          Menu, ContextMenu, Check, &Mute all sounds

       Menu, ContextMenu, Add
       If (ObserveHolidays=1)
          Menu, ContextMenu, Add, Celebrations / &holidays, PanelIncomingCelebrations
       Menu, ContextMenu, Add, Set &alarm or timer, PanelSetAlarm
       Menu, ContextMenu, Add, Stop&watch, PanelStopWatch
       Menu, ContextMenu, Add, Abou&t, PanelAboutWindow
    }

    Menu, ContextMenu, Add, 
    If (PrefsLargeFonts=1)
       Menu, ContextMenu, Check, L&arge UI fonts

    If (PrefOpen=0)
       Menu, ContextMenu, Add, &Settings, ShowSettings
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Donate now, DonateNow
    Menu, ContextMenu, Add, &Restart %appName%, ReloadScriptNow
    Menu, ContextMenu, Show
    lastInvoked := A_TickCount
    Return
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

Dlg_Color(Color,hwnd) {
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

setColors(hC, event, c, err=0) {
; Function by Drugwash
; Critical MUST be disabled below! If that's not done, script will enter a deadlock !
  Static
  oc := A_IsCritical
  Critical, Off
  If (event != "Normal")
     Return
  g := A_Gui, ctrl := A_GuiControl
  r := %ctrl% := hexRGB(Dlg_Color(%ctrl%, hC))
  Critical, %oc%
  GuiControl, %g%:+Background%r%, %ctrl%
  GuiControl, %g%:Enable, ApplySettingsBTN
  Sleep, 100
  OSDpreview()
}

UpdateFntNow() {
  Global
  Fnt_DeleteFont(hfont)
  fntOptions := "s" FontSize " Bold Q5"
  hFont := Fnt_CreateFont(FontName,fntOptions)
  Fnt_SetFont(hBibleTxt,hfont,true)
}

OSDpreview() {
    Static lastInvoked := 1, LastBorderState, lastFnt := FontName
    Gui, SettingsGUIA: Submit, NoHide
    SetTimer, DestroyBibleGui, Off
    If (ShowPreview=0 || PrefOpen=0)
    {
       DoGuiFader := 1
       If (ClockVisibility=1)
          hideAnalogClock()
       DestroyBibleGui(A_ThisFunc)
       Return
    }

    If (analogDisplay=0 || ShowPreviewDate=1)
    {
       If (ClockVisibility=1)
          hideAnalogClock()
       CreateBibleGUI(generateDateTimeTxt(1, !ShowPreviewDate))
    } Else If (A_TickCount - lastInvoked > 200) && (PrefOpen=1 && !GetKeyState("LButton", "P"))
    {
       reInitializeAnalogClock()
       lastInvoked := A_TickCount
       Sleep, 25
    }

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
   DestroyBibleGui(A_ThisFunc)
   Sleep, 2
   showAnalogClock()
}

generateDateTimeTxt(LongD:=1, noDate:=0) {
    If (displayTimeFormat=1)
    {
       FormatTime, CurrentTime,, H:mm
    } Else
    {
       timeSuffix := (A_Hour<12) ? " AM" : " PM"
       FormatTime, CurrentTime,, h:mm
    }

    If (LongD=1)
       FormatTime, CurrentDate,, LongDate
    Else
       FormatTime, CurrentDate,, ShortDate

    txtReturn := CurrentTime timeSuffix
    If (noDate!=1)
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

ShowSettings() {
    doNotOpen := initSettingsWindow()
    If (doNotOpen=1)
    {
       WinActivate, ahk_id %hSetWinGui%
       Return
    }

    Global CurrentPrefWindow := 5
    Global DoNotRepeatTimer := A_TickCount
    Global editF1, editF2, editF3, editF4, editF5, editF6, Btn1, volLevel, editF40, editF60, editF73, Btn2, txt4, Btn3, editF99, txt100
         , editF7, editF8, editF9, editF10, editF11, editF13, editF35, editF36, editF37, editF38, txt1, txt2, txt3, txt10, Btn4, Btn5
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
    Gui, Add, Tab3, +hwndhTabs, Bells|Extras|Restrictions|OSD options
    LastWinOpened := A_ThisFunc
    INIaction(1, "LastWinOpened", "SavedSettings")

    Gui, Tab, 1 ; general
    Gui, Add, Text, x+15 y+15 Section +0x200 vvolLevel, % "Audio volume: " BeepsVolume " % "
    Gui, Add, Slider, x+5 hp ToolTip NoTicks gVolSlider w200 vBeepsVolume Range0-99, %BeepsVolume%
    Gui, Add, Checkbox, gVerifyTheOptions xs y+7 Checked%DynamicVolume% vDynamicVolume, Dynamic volume (adjusted relative to the master volume)
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%AutoUnmute% vAutoUnmute, Automatically unmute master volume [when required]
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%userMuteAllSounds% vuserMuteAllSounds, Mute all sounds
    Gui, Add, Checkbox, y+20 gVerifyTheOptions Checked%tollNoon% vtollNoon, Toll distinctively every six hours [eg., noon, midnight]
    Gui, Add, Checkbox, y+10 gcheckBoxStrikeQuarter Checked%tollQuarters% vtollQuarters, Strike quarter-hours
    Gui, Add, Checkbox, x+10 gVerifyTheOptions Checked%tollQuartersException% vtollQuartersException, ... except on the hour
    Gui, Add, Checkbox, xs y+10 gcheckBoxStrikeHours Checked%tollHours% vtollHours, Strike on the hour
    Gui, Add, Checkbox, x+10 gVerifyTheOptions Checked%tollHoursAmount% vtollHoursAmount, ... and the number of hours
    Gui, Add, Checkbox, xs y+10 gcheckBoxStrikeAdditional Checked%AdditionalStrikes% vAdditionalStrikes, Additional strike every (in minutes)
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF38, %strikeEveryMin%
    Gui, Add, UpDown, gVerifyTheOptions vstrikeEveryMin Range1-720, %strikeEveryMin%
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%markFullMoonHowls% vmarkFullMoonHowls, Mark full moon by wolves howling
    Gui, Add, Text, xs y+10, Interval between tower strikes (in miliseconds):
    Gui, Add, Edit, x+5 w70 geditsOSDwin r1 limit5 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF37, %strikeInterval%
    Gui, Add, UpDown, gVerifyTheOptions vstrikeInterval Range900-5500, %strikeInterval%

    wu := (PrefsLargeFonts=1) ? 125 : 95
    vu := (PrefsLargeFonts=1) ? 55 : 45
    mf := (PrefsLargeFonts=1) ? 260 : 193
    Gui, Tab, 2 ; extras
    Gui, Add, Checkbox, x+15 y+15 Section gVerifyTheOptions Checked%showBibleQuotes% vshowBibleQuotes, Show a Bible verse every (in hours)
    Gui, Add, Edit, x+10 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF40, %BibleQuotesInterval%
    Gui, Add, UpDown, gVerifyTheOptions vBibleQuotesInterval Range1-12, %BibleQuotesInterval%
    Gui, Add, DropDownList, xs+15 y+7 w%mf% gVerifyTheOptions AltSubmit Choose%BibleQuotesLang% vBibleQuotesLang, World English Bible (2000)|Français: Louis Segond (1910)|Español: Reina Valera (1909)
    Gui, Add, Checkbox, x+5 hp gVerifyTheOptions Checked%orderedBibleQuotes% vorderedBibleQuotes, Define the start point
    Gui, Add, Text, xs+15 y+10 vTxt10, Font size
    Gui, Add, Edit, x+10 w%vu% geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF73, %FontSizeQuotes%
    Gui, Add, UpDown, gVerifyTheOptions vFontSizeQuotes Range10-200, %FontSizeQuotes%
    Gui, Add, Button, x+10 hp w%wu% gInvokeBibleQuoteNow vBtn2, Preview verse
    Gui, Add, Edit, x+10 w%vu% r1 limit5 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF4, % userBibleStartPoint
    Gui, Add, UpDown, gVerifyTheOptions vuserBibleStartPoint Range1-27400, % userBibleStartPoint
    Gui, Add, Button, x+5 hp w40 gBtnHelpOrderedDisplay vBtn5, ?
    Gui, Add, Text, xs+15 y+10 vTxt4, Maximum line length (in characters)
    Gui, Add, Edit, x+10 w%vu% geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF60, %maxBibleLength%
    Gui, Add, UpDown, vmaxBibleLength gVerifyTheOptions Range20-130, %maxBibleLength%
    Gui, Add, Checkbox, xs+15 y+10 gVerifyTheOptions Checked%makeScreenDark% vmakeScreenDark, Dim the screen when displaying Bible verses
    Gui, Add, Checkbox, y+10 gVerifyTheOptions Checked%noBibleQuoteMhidden% vnoBibleQuoteMhidden, Do not show Bible verses when the mouse cursor is hidden`n(e.g., when watching videos on full-screen)

    Gui, Add, Checkbox, xs y+20 gVerifyTheOptions Checked%ObserveHolidays% vObserveHolidays, Observe Christian and/or secular holidays
    Gui, Add, Checkbox, xs y+7 gVerifyTheOptions Checked%SemantronHoliday% vSemantronHoliday, Mark days of feast by regular semantron drumming
    Gui, Add, Button, xs+15 y+7 h30 gOpenListCelebrationsBtn vBtn3, Manage list of holidays

    Gui, Tab, 3 ; restrictions
    Gui, Add, Text, x+15 y+15 Section, When other sounds are playing (e.g., music or movies)
    Gui, Add, DropDownList, xs+15 y+7 w270 gVerifyTheOptions AltSubmit Choose%noTollingBgrSounds% vnoTollingBgrSounds, Ignore|Strike the bells at half the volume|Do not strike the bells
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%noTollingWhenMhidden% vnoTollingWhenMhidden, Do not toll bells when mouse cursor is hidden`neven if no sounds are playing (e.g., when watching`na video or an image slideshow on full-screen)
    Gui, Add, DropDownList, xs y+25 w270 gVerifyTheOptions AltSubmit Choose%silentHours% vsilentHours, Limit chimes to specific periods...|Play chimes only...|Keep silence...
    Gui, Add, Text, xp+15 y+6 hp +0x200 vtxt1, from
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF35, %silentHoursA%
    Gui, Add, UpDown, gVerifyTheOptions vsilentHoursA Range0-23, %silentHoursA%
    Gui, Add, Text, x+2 hp +0x200 vtxt2, :00   to
    Gui, Add, Edit, x+10 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF36, %silentHoursB%
    Gui, Add, UpDown, gVerifyTheOptions vsilentHoursB Range0-23, %silentHoursB%
    Gui, Add, Text, x+1 hp +0x200 vtxt3, :59

    Gui, Tab, 4 ; style
    Gui, Add, Text, x+15 y+15 Section, OSD position (x, y)
    Gui, Add, Edit, xs+%columnBpos2% ys w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF1, %GuiX%
    Gui, Add, UpDown, vGuiX gVerifyTheOptions 0x80 Range-9995-9998, %GuiX%
    Gui, Add, Edit, x+5 w70 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF2, %GuiY%
    Gui, Add, UpDown, vGuiY gVerifyTheOptions 0x80 Range-9995-9998, %GuiY%
    Gui, Add, Button, x+5 w60 hp gLocatePositionA vBtn4, Locate

    Gui, Add, Text, xm+15 ys+30 Section, Margins (top, bottom, sides)
    Gui, Add, Edit, xs+%columnBpos2% ys+0 Section w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF11, %OSDmarginTop%
    Gui, Add, UpDown, gVerifyTheOptions vOSDmarginTop Range1-900, %OSDmarginTop%
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF9 , %OSDmarginBottom%
    Gui, Add, UpDown, gVerifyTheOptions vOSDmarginBottom Range1-900, %OSDmarginBottom%
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF13, %OSDmarginSides%
    Gui, Add, UpDown, gVerifyTheOptions vOSDmarginSides Range10-900, %OSDmarginSides%

    Gui, Add, Text, xm+15 y+10 Section, Font name
    Gui, Add, Text, xs yp+30, OSD colors and opacity
    Gui, Add, Text, xs yp+30, Font size
    Gui, Add, Checkbox, xs yp+30 hp gVerifyTheOptions Checked%showTimeWhenIdle% vshowTimeWhenIdle, Display time when idle
    Gui, Add, Text, xs yp+30, Display time (in sec.)
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%displayClock% vdisplayClock, Display time on screen when bells toll
    Gui, Add, Checkbox, xs+16 y+10 gVerifyTheOptions Checked%analogDisplay% vanalogDisplay, Analog clock display
    Gui, Add, Checkbox, x+10 gVerifyTheOptions Checked%displayTimeFormat% vdisplayTimeFormat, 24 hours format
    Gui, Add, Checkbox, xs y+15 h25 +0x1000 gVerifyTheOptions Checked%ShowPreview% vShowPreview, Show preview window
    Gui, Add, Checkbox, x+5 hp gVerifyTheOptions Checked%ShowPreviewDate% vShowPreviewDate, Include current date

    mf := (PrefsLargeFonts=1) ? 170 : 143
    Gui, Add, DropDownList, xs+%columnBpos2% ys+0 section w205 gVerifyTheOptions Sort Choose1 vFontName, %FontName%
    Gui, Add, ListView, xp+0 yp+30 w55 h25 %CCLVO% Background%OSDtextColor% vOSDtextColor hwndhLV1,
    Gui, Add, ListView, x+5 yp w55 h25 %CCLVO% Background%OSDbgrColor% vOSDbgrColor hwndhLV2,
    Gui, Add, Edit, x+5 yp+0 w55 hp geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF10, %OSDalpha%
    Gui, Add, UpDown, vOSDalpha gVerifyTheOptions Range75-250, %OSDalpha%
    Gui, Add, Edit, xp-120 yp+30 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF5, %FontSize%
    Gui, Add, UpDown, gVerifyTheOptions vFontSize Range12-295, %FontSize%
    Gui, Add, DropDownList, x+5 w%mf% gVerifyTheOptions AltSubmit Choose%showOSDprogressBar% vshowOSDprogressBar, No progress bar|Current day|Moon`'s synodic period|Current month|Astronomical seasons|Current year
    Gui, Add, Edit, xp-60 yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF99, %showTimeIdleAfter%
    Gui, Add, UpDown, vshowTimeIdleAfter gVerifyTheOptions Range1-950, %showTimeIdleAfter%
    Gui, Add, Text, x+5 vtxt100, idle time (in min.)
    Gui, Add, Edit,  xs yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF6, %DisplayTimeUser%
    Gui, Add, UpDown, vDisplayTimeUser gVerifyTheOptions Range1-99, %DisplayTimeUser%
    Gui, Add, Checkbox, x+5 hp gVerifyTheOptions Checked%OSDroundCorners% vOSDroundCorners, Round corners
    If !FontList._NewEnum()[k, v]
    {
        Fnt_GetListOfFonts()
        FontList := trimArray(FontList)
    }

    Loop, % FontList.MaxIndex() {
        fontNameInstalled := FontList[A_Index]
        If (fontNameInstalled ~= "i)(@|oem|extb|symbol|marlett|wst_|glyph|reference specialty|system|terminal|mt extra|small fonts|cambria math|this font is not|fixedsys|emoji|hksc| mdl|wingdings|webdings)") || (fontNameInstalled=FontName)
           Continue
        GuiControl, SettingsGUIA:, FontName, %fontNameInstalled%
    }

    Gui, Tab
    Gui, Add, Button, xm+0 y+10 w70 h30 Default gApplySettings vApplySettingsBTN, A&pply
    Gui, Add, Button, x+8 wp hp gCloseSettings, C&ancel
    Gui, Add, Button, x+8 w%btnWid% hp gDeleteSettings, R&estore defaults
    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Customize: %appName%
    VerifyTheOptions(0)
    ColorPickerHandles := hLV1 "," hLV2 "," hLV3 "," hLV5 "," hTXT
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
    GuiControlGet, showOSDprogressBar
    GuiControlGet, analogDisplay
    GuiControlGet, showTimeIdleAfter
    GuiControlGet, showTimeWhenIdle
    GuiControlGet, userBibleStartPoint
    GuiControlGet, orderedBibleQuotes
    GuiControlGet, userMuteAllSounds

    GuiControl, % (EnableApply=0 ? "Disable" : "Enable"), ApplySettingsBTN
    GuiControl, % (AdditionalStrikes=0 ? "Disable" : "Enable"), editF38
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF40
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF60
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF73
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Btn2
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Txt4
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), makeScreenDark
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), BibleQuotesLang
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Btn5
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), noBibleQuoteMhidden
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), orderedBibleQuotes
    GuiControl, % (showBibleQuotes=0 || orderedBibleQuotes-1) ? "Disable" : "Enable", userBibleStartPoint
    GuiControl, % (showBibleQuotes=0 || orderedBibleQuotes-1) ? "Disable" : "Enable", editF4
    GuiControl, % (displayClock=0 ? "Disable" : "Enable"), analogDisplay
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursA
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursB
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF35
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF36
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt1
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt2
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt3
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), BeepsVolume
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), AutoUnmute
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), dynamicVolume
    GuiControl, % (userMuteAllSounds=1 ? "Disable" : "Enable"), volLevel
    GuiControl, % (tollHours=0 ? "Disable" : "Enable"), tollHoursAmount
    GuiControl, % (tollQuarters=0 ? "Disable" : "Enable"), tollQuartersException
    GuiControl, % (ShowPreview=0 || analogDisplay=1) ? "Disable" : "Enable", ShowPreviewDate
    GuiControl, % ((ObserveHolidays=0) ? "Disable" : "Enable"), btn3
    GuiControl, % ((ObserveHolidays=0) ? "Disable" : "Enable"), SemantronHoliday

    roundCornerSize := Round(FontSize/2) + Round(OSDmarginSides/5)
    If (roundCornerSize<20)
       roundCornerSize := 20

    Static LastInvoked := 1
    If (forceNoPreview=1)
       Return

    If (A_TickCount - LastInvoked>250) || (BibleGuiVisible=0 && ShowPreview=1)
    || (BibleGuiVisible=1 && ShowPreview=0)
    {
       If (A_TickCount - LastInvoked>9500)
          DoGuiFader := 1
       LastInvoked := A_TickCount
       OSDpreview()
    } Else SetTimer, OSDpreview, -350
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

CalcTextHorizPrev(txtCenter, txtTotal, addYearMarkers:=1, Barlength:=20) {
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
      horizProgress := ST_Insert("▀", horizProgress, 5)
      horizProgress := ST_Insert("⬤", horizProgress, 11)
      horizProgress := ST_Insert("▃", horizProgress, 17)
      horizProgress := ST_Insert("◯", horizProgress, 23)
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

calcEasterDate(ByRef aisHolidayToday, thisYDay) {
  If (UserReligion=1)
     result := CatholicEaster(celebYear)
  Else
     result := OrthodoxEaster(celebYear)

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

ashwednesday(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, -46, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=1)
     aisHolidayToday := "Ash Wednesday - first day of Lent; a reminder we were made from dust and we will return to dust"

  return result
}

palmSunday(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, -7, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Flowery/Palm Sunday - Jesus' triumphal entry into Jerusalem"

  return result
}

goodFriday(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, -2, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
  {
     aisHolidayToday := (UserReligion=1) ? "Good Friday" : "The Great and Holy Friday"
     aisHolidayToday .= " - the crucifixion and death of Jesus Christ"
  }

  return result
}

MaundyT(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, -3, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Maundy Thursday - the washing of the disciples' feet and Last Supper of Jesus Christ"

  return result
}

HolySaturday(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, -1, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Holy Saturday - the day that Jesus' body lay in the tomb"

  return result
}

SecondDayEaster(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 1, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := (UserReligion=1) ? "Catholic Easter Monday" : "Orthodox Easter Monday"

  return result
}

DivineMercy(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 7, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=1)
     aisHolidayToday := "Divine Mercy Sunday - related to His Merciful Divinity and Faustina Kowalska, a Polish Catholic nun"

  return result
}

ascensionday(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 39, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Ascension of the Lord Jesus Christ into Heaven"

  return result
}

pentecost(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 49, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := "Pentecost - the descent of the Holy Spirit upon the Apostles"

  return result
}

holyTrinityOrthdox(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 50, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=2)
     aisHolidayToday := "The Holy Trinity - celebrates the Christian doctrine of the Trinity, the three Persons of God: the Father, the Son, and the Holy Spirit"

  return result
}

TrinitySunday(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 56, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay)
     aisHolidayToday := (UserReligion=1) ? "Holy Trinity Sunday -  celebrates the Christian doctrine of the Trinity, the three Persons of God: the Father, the Son, and the Holy Spirit" : "All saints day"

  return result
}

corpuschristi(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 60, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=1)
     aisHolidayToday := "Corpus Cristi - the real presence of the Body and Blood of Jesus"

  return result
}

lifeGivingSpring(ByRef aisHolidayToday, thisYDay) {
  result := calcEasterDate(isHoliday, thisYDay)
  EnvAdd, result, 5, days

  FormatTime, lola, %result%, yday
  If (lola=thisYDay && UserReligion=2)
     aisHolidayToday := "The Life-Giving Spring - when Blessed Mary healed a blind man by having him drink water from a spring"

  return result
}

testCelebrations() {
   obju := coreTestCelebrations(A_Mon, A_MDay, A_YDay, 0)
   TypeHolidayOccured := obju[1]
   isHolidayToday := obju[2]
}

coreTestCelebrations(thisMon, thisMDay, thisYDay, isListMode) {
  Critical, On
  testEquiSols()
  If (ObserveHolidays=0 && SemantronHoliday=0)
     Return [0, 0]

  aTypeHolidayOccured := aisHolidayToday := 0
  testFeast := thisMon "." thisMDay
  If (ObserveReligiousDays=1)
  {
     calcEasterDate(aisHolidayToday, thisYDay)
     SecondDayEaster(aisHolidayToday, thisYDay)
     DivineMercy(aisHolidayToday, thisYDay)
     palmSunday(aisHolidayToday, thisYDay)
     MaundyT(aisHolidayToday, thisYDay)
     HolySaturday(aisHolidayToday, thisYDay)
     goodFriday(aisHolidayToday, thisYDay)
     ashwednesday(aisHolidayToday, thisYDay)
     ascensionday(aisHolidayToday, thisYDay)
     pentecost(aisHolidayToday, thisYDay)
     TrinitySunday(aisHolidayToday, thisYDay)
     corpuschristi(aisHolidayToday, thisYDay)
     lifeGivingSpring(aisHolidayToday, thisYDay)
     holyTrinityOrthdox(aisHolidayToday, thisYDay)

     If (testFeast="01.06")
        q := (UserReligion=1) ? "Epiphany - the revelation of God incarnate as Jesus Christ" : "Theophany - the baptism of Jesus in the Jordan River"
     Else If (testFeast="01.07" && UserReligion=2)
        q := "Synaxis of Saint John the Baptist - a Jewish itinerant preacher, and a prophet"
     Else If (testFeast="01.30" && UserReligion=2)
        q := "The Three Holy Hierarchs - Basil the Great, John Chrysostom and Gregory the Theologian"
     Else If (testFeast="02.02")
        q := "Presentation of the Lord Jesus Christ - at the Temple in Jerusalem to induct Him into Judaism, episode described in the 2nd chapter of the Gospel of Luke"
     Else If (testFeast="03.25" && !aisHolidayToday)
        q := "Annunciation of the Lord Jesus Christ - when the Blessed Virgin Mary was told she would conceive and become the mother of Jesus of Nazareth"
     Else If (testFeast="04.23" && !aisHolidayToday)
        q := "Saint George - a Roman soldier of Greek origin under the Roman emperor Diocletian, sentenced to death for refusing to recant his Christian faith, venerated as a military saint since the Crusades."
     Else If (testFeast="06.24")
        q := "Birth of Saint John the Baptist - a Jewish itinerant preacher, and a prophet known for having anticipated a messianic figure greater than himself"
     Else If (testFeast="08.06")
        aisHolidayToday := "Feast of the Transfiguration of the Lord Jesus Christ - when He becomes radiant in glory upon Mount Tabor"
     Else If (testFeast="08.15")
        q := (UserReligion=1) ? "Assumption of the Blessed Virgin Mary - her body and soul assumed into heavenly glory after her death" : "Dormition of the Blessed Virgin Mary"
     Else If (testFeast="08.29")
        q := "Beheading of Saint John the Baptist - killed on the orders of Herod Antipas through the vengeful request of his step-daughter Salomé and her mother Herodias"
     Else If (testFeast="09.08")
        q := "Birth of the Blessed Virgin Mary - according to an apocryphal writing, her parents are known as Saint Anne and Saint Joachim"
     Else If (testFeast="09.14")
        q := "Exaltation of the Holy Cross - the recovery of the cross on which Jesus Christ was crucified by the Roman government on the order of Pontius Pilate"
     Else If (testFeast="10.04" && UserReligion=1)
        q := "Saint Francis of Assisi - an Italian friar, deacon, preacher and founder of the Friar Minors (OFM) within the Catholic church who lived between 1182 and 1226"
     Else If (testFeast="10.14" && UserReligion=2)
        q := "Saint Paraskeva of the Balkans - an ascetic female saint of the 10th century of half Serbian and half Greek origins"
     Else If (testFeast="10.31" && UserReligion=1)
        q := "All Hallows' Eve - the eve of the Solemnity of All Saints"
     Else If (testFeast="11.01" && UserReligion=1)
        q := "All Saints' day - a commemoration day for all Christian saints"
     Else If (testFeast="11.02" && UserReligion=1)
        q := "All souls' day - a commemoration day of all the faithful departed"
     Else If (testFeast="11.21")
        q := "Presentation of the Blessed Virgin Mary - when she was brought, as a child, to the Temple in Jerusalem to be consecrated to God"
     Else If (testFeast="12.06")
        q := "Saint Nicholas' Day - an early Christian bishop of Greek origins from 270 - 342 AD, known as the bringer of gifts for the poor"
     Else If (testFeast="12.08" && UserReligion=1)
        q := "Immaculate Conception of the Blessed Virgin Mary"
     Else If (testFeast="12.24")
        q := "Christmas Eve"
     Else If (testFeast="12.25")
        q := "Christmas day - the birth of Jesus Christ in Nazareth"
     Else If (testFeast="12.26")
        q := "Saint Stephen's Day - a deacon honoured as the first Christian martyr who was stoned to death in 36 AD (Acts 7:55-60). Second day of Christmastide"
     Else If (testFeast="12.28" && UserReligion=1)
        q := "Feast of the Holy Innocents - in remembrance of the young children killed in Bethlehem by King Herod the Great in his attempt to kill the infant Jesus of Nazareth"

     aisHolidayToday := q ? q : aisHolidayToday
     If (StrLen(isHolidayToday)>2)
        aTypeHolidayOccured := 1
  }

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
        . "International Friendship Day|08.02`n"
        . "International Youth Day|08.12`n"
        . "International Day for the Remembrance of the Slave Trade and its Abolition|08.23`n"
        . "International Literacy Day|09.08`n"
        . "International Day of Peace|09.21`n"
        . "International Day for the Universal Access to Information [for people with disabilities]|09.28`n"
        . "Armistice Day (also Remembrance Day or Veterans Day) - recalling the victims of World War I|11.11`n"
        . "International Day for Tolerance|11.16`n"
        . "International Day for the Elimination of Violence against Women|11.25`n"
        . "International Day of Disabled Persons - the largest minority of the world|12.03`n"
        . "Human Rights Day|12.10`n"
        . "World Arabic Language Day|12.18"

     Loop, Parse, theList, `n
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

  PersonalDay := INIactionNonGlobal(0, testFeast, 0, "Celebrations")
  If InStr(PersonalDay, "default disabled")
  {
     aisHolidayToday := PersonalDay := aTypeHolidayOccured := 0
  } Else If (StrLen(PersonalDay)>2)
  {
     aisHolidayToday := PersonalDay
     aTypeHolidayOccured := 3
  }

  If (isListMode=0)
     OSDprefix := ""

  If (StrLen(aisHolidayToday)>2 && ObserveHolidays=1 && isListMode=0)
  {
     OSDprefix := (aTypeHolidayOccured=3) ? "▦ " : "✝ "
     If (aTypeHolidayOccured=2) ; secular
        OSDprefix := "▣ "

     ; ToolTip, % OSDprefix "== lol" , , , 2
     If (AnyWindowOpen!=1 && windowManageCeleb!=1)
     {
        Gui, ShareBtnGui: Destroy
        CreateBibleGUI(generateDateTimeTxt() " || " aisHolidayToday, 1, 1)
        Gui, ShareBtnGui: Destroy
        quoteDisplayTime := StrLen(aisHolidayToday) * 140
        If InStr(aisHolidayToday, "Christmas")
           MCXI_Play(SNDmedia_christmas)
        Else
           strikeJapanBell()
        Sleep, 100
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

PanelManageCelebrations(tabChoice:=1) {

  Global LViewEaster, LViewOthers, LViewSecular, LViewPersonal, CurrentTabLV, ResetYearBTN
  If (AnyWindowOpen && PrefOpen!=1)
     CloseWindow()

  Gui, CelebrationsGuia: Destroy
  Sleep, 15
  Gui, CelebrationsGuia: Default
  Gui, CelebrationsGuia: -MaximizeBox -MinimizeBox +hwndhThisWin
  Gui, CelebrationsGuia: Margin, 15, 15
  applyDarkMode2guiPre(hThisWin)
  relName := (UserReligion=1) ? "Catholic" : "Orthodox"
  lstWid := 435
  If (PrefsLargeFonts=1)
  {
     lstWid := lstWid + 245
     Gui, Font, s%LargeUIfontValue%
  }

  windowManageCeleb := 1
  Gui, Add, Checkbox, x15 y10 gupdateOptionsLVsGui Checked%ObserveReligiousDays% vObserveReligiousDays, Observe religious feasts / holidays
  Gui, Add, DropDownList, x+2 w100 gupdateOptionsLVsGui AltSubmit Choose%UserReligion% vUserReligion, Catholic|Orthodox
  btnWid := (PrefsLargeFonts=1) ? 70 : 50
  lstWid2 := lstWid - btnWid
  Gui, Add, Button, xs+%lstWid2% yp+0 gPaneladdNewEntryWindow w%btnWid% h30, &Add
  Gui, Add, Tab3, xs+0 y+0 AltSubmit Choose%tabChoice% vCurrentTabLV, Christian|Easter related|Secular|Personal

  Gui, Tab, 1
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r8 Grid NoSort -Hdr vLViewOthers, Index|Date|Detailz
  Gui, Tab, 2
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r8 Grid NoSort -Hdr vLViewEaster, Index|Date|Detailz
  Gui, Tab, 3
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r8 Grid NoSort -Hdr vLViewSecular, Index|Date|Detailz
  Gui, Tab, 4
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r8 Grid NoSort -Hdr vLViewPersonal, Index|Date|Detailz

  Gui, Tab
  Gui, Add, Checkbox, y+15 Section gupdateOptionsLVsGui Checked%ObserveSecularDays% vObserveSecularDays, Observe secular holidays
  Gui, Add, Checkbox, x+5 gupdateOptionsLVsGui Checked%PreferSecularDays% vPreferSecularDays, Prefer these holidays over religious ones

  btnWid := (PrefsLargeFonts=1) ? 145 : 90
  Gui, Add, Button, xs y+15 w%btnWid% h30 gPrevYearList , &Previous year
  Gui, Add, Button, x+1 w55 hp gResetYearList vResetYearBTN, %celebYear%
  Gui, Add, Button, x+1 w%btnWid% hp gNextYearList , &Next year
  Gui, Add, Button, x+20 wp-25 hp gCloseCelebListWin, &Close list
  applyDarkMode2winPost("CelebrationsGuia", hThisWin)
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
  updateHolidaysLVs()
}

updateHolidaysLVs() {
  Static Epiphany := "01.06"
  , SynaxisSaintJohnBaptist := "01.07"
  , ThreeHolyHierarchs := "01.30"
  , PresentationLord := "02.02"
  , AnnunciationLord := "03.25"
  , SaintGeorge := "04.23"
  , BirthJohnBaptist := "06.24"
  , FeastTransfiguration := "08.06"
  , AssumptionVirginMary := "08.15"
  , BeheadingJohnBaptist := "08.29"
  , BirthVirginMary := "09.08"
  , ExaltationHolyCross := "09.14"
  , SaintFrancisAssisi := "10.04"
  , SaintParaskeva := "10.14"
  , HalloweenDay := "10.31"
  , Allsaintsday := "11.01"
  , Allsoulsday := "11.02"
  , PresentationVirginMary := "11.21"
  , ImmaculateConception := "12.08"
  , SaintNicola := "12.06"
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
     theList := "Ash Wednesday|" ashwednesdaydate "`n"
        . "Palm Sunday|" palmdaydate "`n"
        . "Maundy Thursday|" maundydate "`n"
        . "Good Friday|" goodFridaydate "`n"
        . "Holy Saturday|" HolySaturdaydate "`n"
        . "Catholic Easter|" easterdate "`n"
        . "Catholic Easter - 2nd day|" 2ndeasterdate "`n"
        . "Divine Mercy|" divineMercyDate "`n"
        . "Ascension of Jesus|" ascensiondaydate "`n"
        . "Pentecost|" pentecostdate "`n"
        . "Trinity Sunday|" TrinitySundaydate "`n"
        . "Corpus Christi|" corpuschristidate

     Gui, ListView, LViewEaster
     processHolidaysList(theList)

     Static theList2 := "Epiphany|" Epiphany "`n"
        . "Presentation of the Lord Jesus Christ|" PresentationLord "`n"
        . "Annunciation of the Blessed Virgin Mary|" AnnunciationLord "`n"
        . "Saint George|" SaintGeorge "`n"
        . "Birth of Saint John the Baptist|" BirthJohnBaptist "`n"
        . "Transfiguration of the Lord Jesus Christ|" FeastTransfiguration "`n"
        . "Assumption of the Blessed Virgin Mary|" AssumptionVirginMary "`n"
        . "Beheading of Saint John the Baptist|" BeheadingJohnBaptist "`n"
        . "Birth of the Blessed Virgin Mary|" BirthVirginMary "`n"
        . "Exaltation of the Holy Cross|" ExaltationHolyCross "`n"
        . "Saint Francis of Assisi|" SaintFrancisAssisi "`n"
        . "All Hallows' Eve [Hallowe'en]|" HalloweenDay "`n"
        . "All Saints' day|" Allsaintsday "`n"
        . "All souls' day|" Allsoulsday "`n"
        . "Presentation of the Blessed Virgin Mary|" PresentationVirginMary "`n"
        . "Immaculate Conception of the Blessed Virgin Mary|" ImmaculateConception "`n"
        . "Saint Nicholas Day|" SaintNicola "`n"
        . "Christmas Eve|" ChristmasEve "`n"
        . "Christmas|" Christmasday "`n"
        . "Saint Stephen's Day|" Christmas2nday "`n"
        . "Feast of the Holy Innocents|" FeastHolyInnocents

     Gui, ListView, LViewOthers
     processHolidaysList(theList2)
  } Else If (UserReligion=2 && ObserveReligiousDays=1)
  {
     theList3 := "Flowery Sunday|" palmdaydate "`n"
        . "Maundy Thursday|" maundydate "`n"
        . "Holy Friday|" goodFridaydate "`n"
        . "Holy Saturday|" HolySaturdaydate "`n"
        . "Orthodox Easter|" easterdate "`n"
        . "Orthodox Easter - 2nd day|" 2ndeasterdate "`n"
        . "Life-Giving Spring|" lifeSpringDate "`n"
        . "Ascension of Jesus|" ascensiondaydate "`n"
        . "Pentecost|" pentecostdate "`n"
        . "Holy Trinity|" holyTrinityOrthdoxDate "`n"
        . "All Saints' day|" TrinitySundaydate

     Gui, ListView, LViewEaster
     processHolidaysList(theList3)

     Static theList4 := "Theophany|" Epiphany "`n"
        . "Synaxis of Saint John the Baptist|" SynaxisSaintJohnBaptist "`n"
        . "The Three Holy Hierarchs|" ThreeHolyHierarchs "`n"
        . "Presentation of the Lord Jesus Christ|" PresentationLord "`n"
        . "Annunciation of the Blessed Virgin Mary|" AnnunciationLord "`n"
        . "Saint George|" SaintGeorge "`n"
        . "Birth of Saint John the Baptist|" BirthJohnBaptist "`n"
        . "Transfiguration of the Lord Jesus Christ|" FeastTransfiguration "`n"
        . "Dormition of the Blessed Virgin Mary|" AssumptionVirginMary "`n"
        . "Beheading of Saint John the Baptist|" BeheadingJohnBaptist "`n"
        . "Birth of the Blessed Virgin Mary|" BirthVirginMary "`n"
        . "Exaltation of the Holy Cross|" ExaltationHolyCross "`n"
        . "Saint Paraskeva of the Balkans|" SaintParaskeva "`n"
        . "Presentation of the Blessed Virgin Mary|" PresentationVirginMary "`n"
        . "Saint Nicholas Day|" SaintNicola "`n"
        . "Christmas Eve|" ChristmasEve "`n"
        . "Christmas|" Christmasday "`n"
        . "Christmas - 2nd day|" Christmas2nday

     Gui, ListView, LViewOthers
     processHolidaysList(theList4)
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
       . "Friendship Day|08.02`n"
       . "International Youth Day|08.12`n"
       . "Remembrance of the Slave Trade and its Abolition|08.23`n"
       . "Literacy Day|09.08`n"
       . "International Day of Peace|09.21`n"
       . "Day for the Universal Access to Information|09.28`n"
       . "Armistice Day / Remembrance Day / Veterans Day|11.11`n"
       . "Tolerance Day|11.16`n"
       . "Elimination of Violence Against Women|11.25`n"
       . "International Day of Disabled Persons|12.03`n"
       . "Human Rights Day|12.10`n"
       . "World Arabic Language Day|12.18"
     processHolidaysList(theListS)
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
     testFeast := CheckMonth "." CheckDay
     PersonalDay := INIactionNonGlobal(0, testFeast, 0, "Celebrations")
     If (StrLen(PersonalDay)>2)
     {
        PersonalDate := celebYear CheckMonth CheckDay 010101
        FormatTime, PersonalDate, %PersonalDate%, LongDate
        If (StrLen(PersonalDate)<3) || InStr(PersonalDay, "default disabled")
           Continue

        LV_Add(A_Index, testFeast, PersonalDate, PersonalDay)
        loopsOccured++
     }
  }
  If (loopsOccured<1)
     LV_Add(1,"-- { no personal entries added } --")

  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (loopsOccured>0)
     LV_ModifyCol(1, 1)

  Gui, ListView, LViewEaster
  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (ObserveReligiousDays=1)
     LV_ModifyCol(1, 1)
  Gui, ListView, LViewOthers
  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (ObserveReligiousDays=1)
     LV_ModifyCol(1, 1)

  Gui, ListView, LViewSecular
  Loop, 3
     LV_ModifyCol(A_Index, "AutoHdr Left")
  If (ObserveSecularDays=1)
     LV_ModifyCol(1, 1)
  GuiControl, CelebrationsGuia:, ResetYearBTN, %celebYear%
}

PaneladdNewEntryWindow() {

  Global newDay, newMonth, newEvent
  Gui, CelebrationsGuia: Destroy
  Sleep, 15
  Gui, CelebrationsGuia: Default
  Gui, CelebrationsGuia: -MaximizeBox -MinimizeBox
  Gui, CelebrationsGuia: Margin, 15, 15
  If (PrefsLargeFonts=1)
     Gui, Font, s%LargeUIfontValue%

  btnWid := (PrefsLargeFonts=1) ? 125 : 90
  drpWid := (PrefsLargeFonts=1) ? 75 : 50
  drpWid2 := (PrefsLargeFonts=1) ? 125 : 100
  windowManageCeleb := 2
  Gui, Add, Text, x15 y10 Section, Please enter the day month, and event name.
  Gui, Add, DropDownList, y+10 Choose%A_MDay% w%drpWid% vnewDay, 01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31
  Gui, Add, DropDownList, x+5 Choose%A_Mon% w%drpWid2% vnewMonth, 01 January|02 February|03 March|04 April|05 May|06 June|07 July|08 August|09 September|10 October|11 November|12 December
  Gui, Add, Edit, xs y+7 w400 r1 limit90 -multi -wantReturn -wantTab -wrap vnewEvent, 
  Gui, Add, Button, xs y+15 w%btnWid% h30 Default gSaveNewEntryBtn , &Add entry
  Gui, Add, Button, x+5 wp-25 hp gCancelNewEntryBtn, &Cancel
  Gui, Show, AutoSize, Add new celebration: %appName%
  If (PrefOpen=1 && hSetWinGui)
     SetTimer, AutoDestroyCelebList, 200
}

SaveNewEntryBtn() {
  Gui, CelebrationsGuia: Default
  GuiControlGet, newDay
  GuiControlGet, newMonth
  GuiControlGet, newEvent

  If (StrLen(newEvent)<4)
     wrongThis := 1

  newMonth := SubStr(newMonth, 1,2)
  testDate := A_Year newMonth newDay "010101"
  FormatTime, LongaData, %testDate%, LongDate
  If (StrLen(LongaData)<3)
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
     PersonalDay := INIactionNonGlobal(1, newMonth "." newDay, newEvent, "Celebrations")
     Sleep, 200
     PanelManageCelebrations(4)
  }
}

processHolidaysList(theList) {
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

      PersonalDay := INIactionNonGlobal(0, miniDate, 0, "Celebrations")
      byeFlag := (StrLen(PersonalDay)>2) ? "(*) " : ""
      LV_Add(A_Index, miniDate, byeFlag LongaData, lineArr[1])
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

     LV_GetText(dateSelected, A_EventInfo, 1)
     LV_GetText(eventusName, A_EventInfo, 3)
     If (eventusName="Detailz") || StrLen(dateSelected)>5
        Return
     DisableMsg := "default disabled"
     If (CurrentTabLV<4)
     {
        PersonalDay := INIactionNonGlobal(0, dateSelected, 0, "Celebrations")
        If (StrLen(PersonalDay)>2 && !InStr(PersonalDay, DisableMsg))
        {
           reactivate := 1
           questionMsg := eventusName " is overridden by a custom celebration entry: " PersonalDay ".`n`nDo you want to observe again the default celebration ? `n`nBy answering Yes, the personal entry will be removed."
        } Else If (StrLen(PersonalDay)>2 && InStr(PersonalDay, DisableMsg))
        {
           reactivate := 1
           questionMsg := "Do you want to begin observing again " eventusName " ?"
        } Else
        {
           reactivate := 2
           questionMsg := "Do you want to no longer observe " eventusName " ?"
        }
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
        If InStr(eventusName, DisableMsg)
           questionMsg := "Do you want to begin observing again the default celebration ?"
        Else
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
      testCelebrations()
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

wrapCalculateEquiSolsDates() {
  Critical, on
  Static lastInvoked := 1, prevYear := 0, prevBias := -1, prevDay := 0, TZI := [], z := []

  startZeit := A_TickCount
  If (prevDay!=A_YDay || prevBias=-1)
  {
     TZI := TZI_GetTimeZoneInformation()
     prevBias := -1 * TZI.TotalCurrentBias
     prevDay := A_YDay
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
     Loop, 4
     {
         k := calculateEquiSols(A_Index, A_Year, 0)
         FormatTime, OutputVar, % k, Yday
         thisBias := isinRange(OutputVar, TZI.DaylightDateYday, TZI.StandardDateYday) ? TZI.Bias + TZI.DaylightBias + TZI.StandardBias : TZI.Bias + TZI.StandardBias
         thisBias := -1*thisBias
         k += thisBias, M
         FormatTime, OutputVar, % k, Yday
         If (A_Index=1 && OutputVar>70)
         {
            mEquiDay := OutputVar
            mEquiDate := k
         } Else If (A_Index=2 && OutputVar>165)
         {
            jSolsDay := OutputVar
            jSolsDate := k
         } Else If (A_Index=3 && OutputVar>260)
         {
            sEquiDay := OutputVar
            sEquiDate := k
         } Else If (A_Index=4 && OutputVar>350)
         {
            dSolsDay := OutputVar
            dSolsDate := k
         }
         ; fnOutputDebug(A_Index "=" k "==" OutputVar)
     }

     EquiSolsCache := mEquiDay "|" mEquiDate "|" jSolsDay "|" jSolsDate "|" sEquiDay "|" sEquiDate "|" dSolsDay "|" dSolsDate "|" A_Year "|" prevBias
     INIaction(1, "EquiSolsCache", "SavedSettings")
     prevYear := A_Year
  }

  If (A_TickCount - lastInvoked<9500)
     Return z

    z := []
    z.MarchEquinox := giveYearDayProximity(mEquiDay, A_YDay) . "March equinox."      ; 03 / 20
    z.JuneSolstice := giveYearDayProximity(jSolsDay, A_YDay) . "June solstice."      ; 06 / 21
    z.SepEquinox   := giveYearDayProximity(sEquiDay, A_YDay) . "September equinox."  ; 09 / 22
    z.DecSolstice  := giveYearDayProximity(dSolsDay, A_YDay) . "December solstice."  ; 12 / 21
    If InStr(z.MarchEquinox, "now")
       z.r := 1
    Else If InStr(z.JuneSolstice, "now")
       z.r := 2
    Else If InStr(z.SepEquinox, "now")
       z.r := 3
    Else If InStr(z.DecSolstice, "now")
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
      If (passedDays<2)
         Result := "now"
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
     If (DaysUntil<2)
        Result := "now"
  }
  If (Floor(Weeksz)>=4)
     Result := "hide"

  Return Result
}

testEquiSols() {
  OSDsuffix := ""
  testu := wrapCalculateEquiSolsDates()
  If (testu.r=1)
     OSDsuffix := " ▀"
  Else If (testu.r=2)
     OSDsuffix := " ⬤"
  Else If (testu.r=3)
     OSDsuffix := " ▃"
  Else If (testu.r=4)
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
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section gTollExtraNoon hwndhBellIcon, bell-image.png
    Gui, Add, Text, x+7 y10, %appName%
    Gui, Font, s12 Bold, Arial, -wrap
    Gui, Add, Text, y+4 vtxtLine, Celebrations in the next 30 days.
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
    }

    If (tickTockNoise!=1)
       SoundLoop(tickTockSound)

    btnW1 := (PrefsLargeFonts=1) ? 105 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    Gui, Add, Button, xs+1 y+15 w1 h1, L
    Gui, Add, Edit, xp+1 yp+1 ReadOnly r15 w%txtWid% vholiListu, % listu
    Gui, Font, Normal
    Gui, Add, Button, xs+0 y+20 h%btnH% w%btnW1% Default gOpenListCelebrationsBtn hwndhBtn1, &Manage
    Gui, Add, Button, x+5 hp wp+15 gShowSettings hwndhBtn2, &Settings
    Gui, Add, Button, x+5 hp wp-15 gCloseWindow hwndhBtn3, &Close
    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Celebrations list: %appName%
    PopulateIncomingCelebs()
}

PopulateIncomingCelebs() {

    startDate := ""
    listu := ""
    If (StrLen(isHolidayToday)>2 && ObserveHolidays=1)
    {
       relName := (UserReligion=1) ? "Catholic" : "Orthodox"
       holidayMsg := relName " Christians celebrate today: " isHolidayToday "."
       If (TypeHolidayOccured>1)
          holidayMsg := "Today's event: " isHolidayToday "."
       FormatTime, PersonalDate, , yyyy/MM/dd
       listu .= PersonalDate " = " holidayMsg "`n `n"
    }

    startYday := A_YDay
    totalYDays := isLeapYear() ? 366 : 365
    Loop, 30
    {
        startDate += 1, Days
        thisMon := SubStr(startDate, 5, 2)
        thisMDay := SubStr(startDate, 7, 2)
        thisYear := SubStr(startDate, 1, 4)
        startYday++
        thisYday := (startYday>totalYDays) ? startYday - totalYDays : startYday
        obju := coretestCelebrations(thisMon, thisMDay, thisYday, 1)
        ; ToolTip, % thisYear "/" thisMon "/" thisMDay " = " thisYday "[" totalYDays "]"  , , , 2
        ; Sleep, 950
        If obju[2]
           listu .= thisYear "/" thisMon "/" thisMDay " = " obju[2] "`n`n"
    }

    listu .= "Astronomic events:`n`n"
    FormatTime, OutputVar, % mEquiDate, yyyy/MM/dd
    If isinRange(mEquiDay, A_YDay, A_YDay + 30)
       listu .= OutputVar " = March Equinox`n`n"
 
    FormatTime, OutputVar, % jSolsDate, yyyy/MM/dd
    If isinRange(jSolsDay, A_YDay, A_YDay + 30)
       listu .= OutputVar " = June Solstice`n`n"
  
    FormatTime, OutputVar, % sEquiDate, yyyy/MM/dd
    If isinRange(sEquiDay, A_YDay, A_YDay + 30)
       listu .= OutputVar " = September Equinox`n`n"
  
    FormatTime, OutputVar, % dSolsDate, yyyy/MM/dd
    If isinRange(dSolsDay, A_YDay, A_YDay + 30)
       listu .= OutputVar " = December Solstice`n`n"

    startDate := A_Year A_Mon A_MDay 010101
    ; startDate := 2022 01 01 010101
    listuA := listuB := ""
    Loop, 30
    {
        startDate += 1, Days
        pk := MoonPhaseCalculator(startDate)
        If (prevu!=pk[1] && !InStr(pk[1], "peak") && (InStr(pk[1], "full") || InStr(pk[1], "new")))
        {
           prevu := pk[1]
           FormatTime, OutputVar, % startDate, yyyy/MM/dd
           listu .= OutputVar " = " pk[1] "`n`n"
           ; listu .= OutputVar " = " pk[1] "`n p=" pk[3] "; f=" pk[4] "; a=" pk[5] " `n"
        }
    }
 
    GuiControl, SettingsGUIA:, holiListu, % listu listuB listuA
}

reactWinOpened(funcu, idu) {
    If (PrefOpen=1 || AnyWindowOpen=idu)
    {
       If (PrefOpen=1)
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

SetPresetTimers(a, b, c) {
   Static lastInvoked := 1, prevu := 0
   ControlGetText, info, , ahk_id %a%
   info := StrReplace(info, "&")
   info := info := Trim(StrReplace(info, "m"))
   If (A_TickCount - lastInvoked<450) && (prevu=info)
      info := info*3

   Gui, SettingsGUIA: Default
   GuiControl, SettingsGUIA: , userMustDoTimer, 1
   GuiControl, SettingsGUIA: , userTimerHours, 0
   GuiControl, SettingsGUIA: , userTimerMins, % info
   prevu := info
   updateUIalarmsPanel()
   lastInvoked := A_TickCount
   ; ToolTip, % a "=" b "=" c "=" info , , , 2
}

PanelSetAlarm() {
    If reactWinOpened(A_ThisFunc, 4)
       Return

    INIaction(0, "userTimerMins", "SavedSettings")
    INIaction(0, "userTimerHours", "SavedSettings")
    INIaction(0, "userTimerMsg", "SavedSettings")
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
         , userAlarmWday5, userAlarmWday6, userAlarmWday7, txt1
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

    Gui, Add, Tab3,, Timer|Alarm
    Gui, Tab, 1
    Gui, Add, Button, x+15 y+15 Section gSetPresetTimers, &1m
    Gui, Add, Button, x+2 wp+2 gSetPresetTimers, &2m
    Gui, Add, Button, x+2 wp+2 gSetPresetTimers, &3m
    Gui, Add, Button, x+2 wp+2 gSetPresetTimers, &5m
    Gui, Add, Button, x+2 wp+3 gSetPresetTimers, &10m
    Gui, Add, Button, x+2 wp+3 gSetPresetTimers, &15m
    Gui, Add, Button, x+2 wp+3 gSetPresetTimers, &30m
    Gui, Add, Checkbox, xs y+10 Section gupdateUIalarmsPanel Checked%userMustDoTimer% vuserMustDoTimer, Set timer duration (in hours`, mins):
    Gui, Font, % (PrefsLargeFonts=1) ? "s18" : "s16"
    Gui, Add, Edit, xs+15 y+10 w%nW% h%nH% Center number -multi limit2 gupdateUIalarmsPanel veditF1, % userTimerHours
    Gui, Add, UpDown, vuserTimerHours Range0-12 gupdateUIalarmsPanel, % userTimerHours
    Gui, Add, Edit, x+5 w%nW% h%nH% Center number -multi limit2 veditF2 gupdateUIalarmsPanel, % userTimerMins
    Gui, Add, UpDown, vuserTimerMins Range-1-60 gupdateUIalarmsPanel, % userTimerMins
    Gui, Add, Text, x+10 hp +0x200 vuserTimerInfos, 00:00.
    doResetGuiFont()
    Gui, Add, Edit, xs+15 y+10 w255 -multi limit512 vuserTimerMsg, % userTimerMsg
    timerDetails := (userTimerExpire && userMustDoTimer=1) ? "Current timer expires at: " userTimerExpire "." : "Press Apply to start the timer."
    Gui, Add, Text, xs+15 y+10 wp vUItimerInfoz, % timerDetails
    ml := (PrefsLargeFonts=1) ? 180 : 95
    zl := (PrefsLargeFonts=1) ? 55 : 45
    Gui, Add, DropDownList, xs+15 y+10 w%ml% AltSubmit Choose%userTimerSound% vuserTimerSound, Auxilliary bell|Quarters bell|Hours bell|Gong|Beep|No sound alert
    Gui, Add, Edit, x+5 w%zl% hp Center number -multi limit2 veditF10 gupdateUIalarmsPanel, % userTimerFreq
    Gui, Add, UpDown, vuserTimerFreq Range1-99 gupdateUIalarmsPanel, % userTimerFreq
    Gui, Add, Button, x+5 hp gBtnTestTimerAudio vbtn1, Test

    Gui, Tab, 2
    Gui, Add, Checkbox, x+15 y+15 Section gupdateUIalarmsPanel Checked%userMustDoAlarm% vuserMustDoAlarm, Set alarm at (hours`, mins`, snooze mins.):
    Gui, Font, % (PrefsLargeFonts=1) ? "s18" : "s16"
    Gui, Add, Edit, xs+15 y+10 w%nW% h%nH% Center number -multi limit2 veditF3 hwndhEdit, % userAlarmHours
    Gui, Add, UpDown, vuserAlarmHours Range0-23, % userAlarmHours
    Gui, Add, Edit, x+5 w%nW% h%nH% gupdateUIalarmsPanel Center number -multi limit2 veditF4, % userAlarmMins
    Gui, Add, UpDown, vuserAlarmMins gupdateUIalarmsPanel Range-1-60, % userAlarmMins
    Gui, Add, Edit, x+35 w%nW% h%nH% Center number -multi limit2 veditF5, % userAlarmSnooze
    Gui, Add, UpDown, vuserAlarmSnooze Range1-59, % userAlarmSnooze
    doResetGuiFont()

    Gui, Add, Edit, xs+15 y+10 w255 -multi limit512 vuserAlarmMsg, % userAlarmMsg
    Gui, Add, Checkbox, xs y+10 gupdateUIalarmsPanel Checked%userAlarmRepeated% vuserAlarmRepeated, &Repeat alarm on...
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
    Gui, Add, DropDownList, xs+15 y+10 w%ml% AltSubmit Choose%userAlarmSound% vuserAlarmSound, Auxilliary bell|Quarters bell|Hours bell|Gong|Beep|No sound alert
    Gui, Add, Edit, x+5 w%zl% hp Center number -multi limit2 veditF6 gupdateUIalarmsPanel, % userAlarmFreq
    Gui, Add, UpDown, vuserAlarmFreq Range1-99 gupdateUIalarmsPanel, % userAlarmFreq
    Gui, Add, Button, x+5 hp gBtnTestAlarmAudio vBtn2, Test

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
    PlayTimerBell()
}

BtnTestAlarmAudio() {
    GuiControlGet, userAlarmSound
    stopStrikesNow := 0
    PlayAlarmedBell()
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
    Gui, Add, Text, x+15 y+15 Section, Time is here and there...
    Gui, Add, Text, y+5 vUIstopWatchInfos gstartStopWatchCounter, 00:00:00 - 00:00:00
    Gui, Add, Text, x+5 gstartStopWatchCounter, (total time)
    Gui, Font, s22
    Gui, Add, Text, xs y+10 vUIstopWatchLabel gstartStopWatchCounter, 00:00:00.00
    doResetGuiFont()
    Gui, Add, Text, x+5 hp +0x200 gstartStopWatchCounter, (laps total time)
    Gui, Font, s18
    Gui, Add, Text, xs y+5 vUIstopWatchInterval gRecordStopWatchInterval, 00:00:00.00
    doResetGuiFont()
    Gui, Add, Text, x+5 hp +0x200 vUIstopWatchDetailsInterval gRecordStopWatchInterval, (current lap details)
    Gui, Add, Text, xs y+5 vUIstopWatchAvgInterval gRecordStopWatchInterval, 00:00:00.00
    Gui, Add, Text, x+5 gRecordStopWatchInterval, (average time per lap)
    Gui, Add, Checkbox, xs y+15 Checked%stopWatchDoBeeps% vstopWatchDoBeeps, Beep when the current lap`nis the longest
    ; Gui, Add, ComboBox, xs y+10 w250 vUserStopWatchListZeits, No records||
    
    Gui, Tab, 2
    nW := (PrefsLargeFonts=1) ? 265 : 240
    Gui, Add, ListView, x+15 y+15 Section w%nW% r8 Grid vLViewStopWatch, Index|Lap|Laps total|Total

    Gui, Tab
    Gui, Add, Checkbox, xm+0 y+15 gToggleAlwaysOnTopSettingsWindow  Checked%setAlwaysOnTop% vsetAlwaysOnTop, Always on top
    Gui, Add, Button, xm+0 y+5 h30 wp Section Default gstartStopWatchCounter, &Start / Pause
    Gui, Add, Button, x+5 h30 wp gRecordStopWatchInterval, &Record interval
    Gui, Add, Button, xs+0 y+5 hp wp gResetStopWatchCounter, &Reset
    Gui, Add, Button, x+5 hp wp gCloseWindow, &Cancel

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, Stopwatch: %appName%
}

ToggleAlwaysOnTopSettingsWindow() {
  Gui, SettingsGUIA: Default
  GuiControlGet, setAlwaysOnTop
  If (setAlwaysOnTop=1)
     WinSet, AlwaysOnTop, On, ahk_id %hSetWinGui%
  Else
     WinSet, AlwaysOnTop, Off, ahk_id %hSetWinGui%
}

RecordStopWatchInterval() {
  If (AnyWindowOpen=5 && stopWatchBeginZeit && stopWatchPauseZeit)
  {
     Gui, SettingsGUIA: Default
     GuiControlGet, stopWatchDoBeeps
     GuiControl, SettingsGUIA:, UIstopWatchInterval, 00:00:00.0
     coreSecToHHMMSS((A_TickCount - stopWatchBeginZeit)/1000 + stopWatchPauseZeit/1000, hrs, mins, sec)
     Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), SubStr(Sec, 1, InStr(Sec, ".") - 1))
     SecB := SubStr(Sec, InStr(Sec, ".") + 1)
 
     coreSecToHHMMSS((A_TickCount - stopWatchRealStartZeit)/1000, hrs, mins, sec)
     HrzA := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), Round(Sec))
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
     LV_Add(1, countu, HrzB "." SecC, Hrz "." SecB, HrzA)
     If (countu=1)
     {
        Loop, 4
           LV_ModifyCol(A_Index, "AutoHdr Center")
     }

     stopWatchIntervalInfos[1] := min(valuePushable, stopWatchIntervalInfos[1])
     stopWatchIntervalInfos[2] := max(valuePushable, stopWatchIntervalInfos[2])
     stopWatchIntervalInfos[3] := countu
     stopWatchIntervalInfos.Push(valuePushable)
     stopWatchLapPauseZeit := 0.001
     stopWatchLapBeginZeit := A_TickCount
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
      GuiControl, SettingsGUIA:, UIstopWatchInfos, 00:00:00 - 00:00:00
      GuiControl, SettingsGUIA:, UIstopWatchLabel, 00:00:00.0
      GuiControl, SettingsGUIA:, UIstopWatchInterval, 00:00:00.0
      GuiControl, SettingsGUIA:, UIstopWatchAvgInterval, 00:00:00.0
   }
}

startStopWatchCounter() {
   If (AnyWindowOpen-5)
   {
      Gui, SettingsGUIA: Default
      GuiControlGet, stopWatchDoBeeps
   }

   If stopWatchBeginZeit
   {
      SetTimer, uiStopWatchUpdater, Off
      stopWatchPauseZeit += A_TickCount - stopWatchBeginZeit
      stopWatchBeginZeit := 0
      stopWatchLapPauseZeit += A_TickCount - stopWatchLapBeginZeit
      stopWatchLapBeginZeit := 0
      If stopWatchRealStartZeit
         SetTimer, uiStopWatchPausedUpdater, 50
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

  coreSecToHHMMSS((A_TickCount - stopWatchRealStartZeit)/1000, hrs, mins, sec)
  Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), Round(Sec))
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
     stopAdditionalStrikes := stopStrikesNow := 0
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

uiStopWatchPausedUpdater() {
  If (AnyWindowOpen!=5)
  {
     ResetStopWatchCounter()
     Return
  }

  Gui, SettingsGUIA: Default
  GuiControlGet, stopWatchDoBeeps
  coreSecToHHMMSS((A_TickCount - stopWatchRealStartZeit)/1000, hrs, mins, sec)
  Hrz := Format("{:02}:{:02}:{:02}", Trim(Hrs), Trim(Mins), Round(Sec))
  ; Mins := Format("{:02}", Mins)
  GuiControl, SettingsGUIA:, UIstopWatchInfos, %stopWatchHumanStartTime% - %hrz% ; :%mins%:%sec%
}

coreSecToHHMMSS(Seco, ByRef Hrs, ByRef Min, ByRef Sec) {
  OldFormat := A_FormatFloat
  SetFormat, Float, 2.00
  Hrs := Seco//3600/1
  Min := Mod(Seco//60, 60)/1
  SetFormat, Float, %OldFormat%
  Sec := Round(Mod(Seco, 60), 1)
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
  If userAlarmExceptRelu
     userAlarmWeekDays .= "r"
  If userAlarmExceptSeculu
     userAlarmWeekDays .= "s"
  If userAlarmExceptPerso
     userAlarmWeekDays .= "p"
  If userAlarmWday1
     userAlarmWeekDays .= 1
  If userAlarmWday2
     userAlarmWeekDays .= 2
  If userAlarmWday3
     userAlarmWeekDays .= 3
  If userAlarmWday4
     userAlarmWeekDays .= 4
  If userAlarmWday5
     userAlarmWeekDays .= 5
  If userAlarmWday6
     userAlarmWeekDays .= 6
  If userAlarmWday7
     userAlarmWeekDays .= 7

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
     delayu := MCI_ToMilliseconds(userTimerHours, userTimerMins, 0)
     Timea := A_Now
     Timea += userTimerHours, Hours
     Timea += userTimerMins, Minutes
     userTimerExpire := SubStr(timea, 9, 4)
     userTimerExpire := ST_Insert(":", userTimerExpire, 3)
     ; ToolTip, % userTimerExpire
     SetTimer, doUserTimerAlert, % -delayu
  } Else 
  {
     userTimerExpire := userMustDoTimer := 0
     SetTimer, doUserTimerAlert, Off
  }

  If (userMustDoAlarm=1 && (userAlarmMins || userAlarmHours))
  {
     startAlarmTimer()
  } Else
  {
     userAlarmIsSnoozed := userMustDoAlarm := 0
     INIaction(1, "userMustDoAlarm", "SavedSettings")
     SetTimer, doUserAlarmAlert, Off
     SetTimer, PlayAlarmedBell, Off
  }

  CloseWindow()
}

doUserTimerAlert() {
  userMustDoTimer := 0
  stopStrikesNow := stopAdditionalStrikes := 0
  thisMsg := Trim(userTimerMsg) ? "`n" Trim(userTimerMsg) : "NONE"
  If (AlarmersDarkScreen=1)
     ScreenBlocker(0, 1, 0, 1)

  WinSet, AlwaysOnTop, Off, ScreenShader
  PlayTimerBell()
  showTimeNow()
  If (userAlarmSound!=6)
     SetTimer, PlayTimerBell, % userTimerFreq * 1000

  th := (userTimerHours<10) ? "0" . userTimerHours : userTimerHours
  tm := (userTimerMins<10) ? "0" . userTimerMins : userTimerMins
  MsgBox, 4, Timer: %appName%, % "Timer message: " thisMsg "`n`nPress Yes to repeat this alert in " th ":" tm "."
  IfMsgBox, Yes
  {
     userMustDoTimer := 1
     delayu := MCI_ToMilliseconds(userTimerHours, userTimerMins, 0)
     Timea := A_Now
     Timea += userTimerHours, Hours
     Timea += userTimerMins, Minutes
     userTimerExpire := SubStr(timea, 9, 4)
     userTimerExpire := ST_Insert(":", userTimerExpire, 3)
     SetTimer, doUserTimerAlert, % -delayu
  } Else userTimerExpire := 0
  SetTimer, PlayTimerBell, Off
}

doUserAlarmAlert() {
  stopStrikesNow := stopAdditionalStrikes := 0
  thisMsg := Trim(userAlarmMsg) ? "`n" Trim(userAlarmMsg) : "NONE"
  If (AlarmersDarkScreen=1)
     ScreenBlocker(0, 1, 0, 1)

  showTimeNow()
  PlayAlarmedBell()
  If (userAlarmSound!=6)
     SetTimer, PlayAlarmedBell, % userAlarmFreq * 1000

  friendly := (userAlarmIsSnoozed=1) ? " (snoozed)" : ""
  friendly2 := (userAlarmIsSnoozed=1) ? " again" : ""
  MsgBox, 4, Alarm%friendly%: %appName%, % "Alarm message: " thisMsg "`n`nPress Yes to snooze" friendly2 " for " userAlarmSnooze " minutes."
  IfMsgBox, Yes
  {
     userMustDoAlarm := 1
     userAlarmIsSnoozed := 1
     SetTimer, doUserAlarmAlert, % -(userAlarmSnooze * 60000)
  } Else If (userAlarmRepeated=1)
  {
     userAlarmIsSnoozed := 0
     userMustDoAlarm := 1
     startAlarmTimer()
     SetTimer, doUserAlarmAlert, Off
  } Else
  {
     userAlarmIsSnoozed := 0
     userMustDoAlarm := 0
     SetTimer, doUserAlarmAlert, Off
  }
  SetTimer, PlayAlarmedBell, Off
  INIaction(1, "userMustDoAlarm", "SavedSettings")
}

startAlarmTimer() {
  If (userAlarmIsSnoozed=1)
     Return

  canDo := (userMustDoAlarm=1 && (userAlarmMins || userAlarmHours)) ? 1 : 0
  If (canDo && userAlarmRepeated=1)
     canDo := InStr(userAlarmWeekDays, A_WDay) ? 1 : 0

  If (canDo && userAlarmRepeated=1 && ObserveHolidays=1 && StrLen(isHolidayToday)>2)
     canDo := (InStr(userAlarmWeekDays, "p") && TypeHolidayOccured=3) || (InStr(userAlarmWeekDays, "s") && TypeHolidayOccured=2 && ObserveSecularDays=1) || (InStr(userAlarmWeekDays, "r") && TypeHolidayOccured=1 && ObserveReligiousDays=1) ? 0 : 1

  If !canDo
  {
     SetTimer, doUserAlarmAlert, Off
     Return
  }

  nowu := SubStr(A_Now, 1, 12)
  tH := StrLen(userAlarmHours)!=2 ? "0" . userAlarmHours : userAlarmHours
  tM := StrLen(userAlarmMins)!=2 ? "0" . userAlarmMins : userAlarmMins
  newu := A_Year A_Mon A_DD tH tM
  If (nowu>=newu)
     newu += 1, Days

  ; ToolTip, % nowu "`n" newu , , , 2
  newu -= nowu, SS
  SetTimer, doUserAlarmAlert, % -newu*1000
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
   FirstMinOfDay := CurrentDay "0001"
   EnvSub, CurrentDateTime, %FirstMinOfDay%, Minutes
   minsPassed := CurrentDateTime + 1
   Return minsPassed/1445
}

fnOutputDebug(msg) {
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
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section gTollExtraNoon hwndhBellIcon, bell-image.png
    Gui, Add, Text, x+7 y10, %appName%
    Gui, Font, s12 Bold, Arial, -wrap
    Gui, Add, Link, y+4 hwndhLink0, Developed by <a href="http://marius.sucan.ro">Marius Şucan</a>.
    doResetGuiFont()
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
    }

    If (tickTockNoise!=1)
       SoundLoop(tickTockSound)

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

    Gui, Add, Tab3,xm+1, Today|Application details
    Gui, Tab, 1
    testCelebrations()
    zx := wrapCalculateEquiSolsDates()
    MarchEquinox := !InStr(zx.MarchEquinox, "now") ? zx.MarchEquinox : "(" OSDsuffix " ) March equinox. The day and night are everywhere on Earth of approximately equal length."
    JuneSolstice := !InStr(zx.JuneSolstice, "now") ? zx.JuneSolstice : "(" OSDsuffix " ) June solstice. Today is one of the longest days of the year."
    SepEquinox := !InStr(zx.SepEquinox, "now") ? zx.SepEquinox : "(" OSDsuffix " ) September equinox. The day and night are everywhere on Earth of approximately equal length."
    DecSolstice := !InStr(zx.DecSolstice, "now") ? zx.DecSolstice : "(" OSDsuffix " ) December solstice. Today is one of the shortest days of the year."

    percentileYear := Round(A_YDay/366*100) "%"
    FormatTime, CurrentYear,, yyyy
    NextYear := CurrentYear + 1

    percentileDay := Round(getPercentOfToday(minsPassed) * 100) "%"
    Gui, Add, Text, x+15 y+7 w1 h1 Section, .
    If (MarchEquinox ~= "until|here")
       Gui, Font, Bold
    If !InStr(MarchEquinox, "hide")
       Gui, Add, Text, y+7 w%txtWid%, %MarchEquinox%
    Gui, Font, Normal
    If (JuneSolstice ~= "until|here")
       Gui, Font, Bold
    If !InStr(JuneSolstice, "hide")
       Gui, Add, Text, y+7 w%txtWid%, %JuneSolstice%
    Gui, Font, Normal
    If (SepEquinox ~= "until|here")
       Gui, Font, Bold
    If !InStr(SepEquinox, "hide")
       Gui, Add, Text, y+7 w%txtWid%, %SepEquinox%
    Gui, Font, Normal
    If (DecSolstice ~= "until|here")
       Gui, Font, Bold
    If !InStr(DecSolstice, "hide")
       Gui, Add, Text, y+7 w%txtWid%, %DecSolstice%
    Gui, Font, Normal

    extras := decideSysTrayTooltip()
    If extras
       Gui, Add, Text, y+7 w%txtWid%, % Trim(extras, "`n")

    weeksPassed := Floor(A_YDay/7)
    weeksPlural := (weeksPassed>1) ? "weeks" : "week"
    weeksPlural2 := (weeksPassed>1) ? "have" : "has"
    If (weeksPassed<1)
    {
       weeksPassed := A_YDay - 1
       weeksPlural := (weeksPassed>1) ? "days" : "day"
       weeksPlural2 := (weeksPassed>1) ? "have" : "has"
       If (weeksPassed=0)
       {
          weeksPassed := "No"
          weeksPlural := "day"
          weeksPlural2 := "has"
       }
    }

    Gui, Font, Bold
    If (A_YDay>354)
       Gui, Add, Text, y+7 w%txtWid%, Season's greetings! Enjoy the holidays! 😊

    If (StrLen(isHolidayToday)>2 && ObserveHolidays=1)
    {
       relName := (UserReligion=1) ? "Catholic" : "Orthodox"
       holidayMsg := relName " Christians celebrate today: " isHolidayToday "."
       If (TypeHolidayOccured>1)
          holidayMsg := "Today's event: " isHolidayToday "."
       Gui, Add, Text, y+7 w%txtWid%, %holidayMsg%
    }

    testFeast := A_Mon "." A_MDay
    If (testFeast="01.01") || (testFeast="02.01")
    {
       If isLeapYear()
          Gui, Add, Text, y+7 w%txtWid%, %A_Year% is a leap year.
    } Else If (testFeast="02.29")
       Gui, Add, Text, y+7 w%txtWid%, Today is the 29th of February - a leap year day.

    Gui, Font, Normal
    If (A_YDay>172 && A_YDay<352)
       Gui, Add, Text, y+7, The days are getting shorter until the December solstice.
    Else If (A_YDay>356 || A_YDay<167)
       Gui, Add, Text, y+7, The days are getting longer until the June solstice.

    If (A_OSVersion="WIN_XP")
    {
       Gui, Font,, Arial ; only as backup, doesn't have all characters on XP
       Gui, Font,, Symbola
       Gui, Font,, Segoe UI Symbol
       Gui, Font,, DejaVu Sans
       Gui, Font,, DejaVu LGC Sans
    }

    ; fnOutputDebug("booooooooooooooooooooom")
    moonPhase := MoonPhaseCalculator()
    moonPhaseN := moonPhase[1]
    moonPhaseI := moonPhase[2]
    moonPhaseC := Round(moonPhase[3] * 100)
    moonPhaseL := Round(moonPhase[4] * 100)

    ; startDate := 2022 01 01 010101
    ; Loop, 983
    ; {
    ;     startDate += 1, Hours
    ;     pk := MoonPhaseCalculator(startDate)
    ;        FormatTime, OutputVar, % startDate, yyyy/MM/dd
    ;        ; listu .= OutputVar " = " pk[1] "`n`n"
    ;        ; If InStr(pk[1], "new")
    ;        fnOutputDebug(OutputVar " = " pk[1] "; p=" pk[3] "; f=" pk[4] "; a=" pk[5])
    ; }

    Gui, Add, Text, xp+30 y+15 Section, % CurrentYear " {" CalcTextHorizPrev(A_YDay, 366) "} " NextYear
    Gui, Add, Text, xp+15 y+5, %weeksPassed% %weeksPlural% (%percentileYear%) of %CurrentYear% %weeksPlural2% elapsed.
    Gui, Add, Text, xs y+10, Moon phase: %moonPhaseN% (%moonPhaseI% / 8)
    Gui, Add, Text, xp+15 y+10, %moonPhaseC%`% of the cycle, %moonPhaseL%`% illuminated.
    Gui, Add, Text, xs y+10, % "0h {" CalcTextHorizPrev(minsPassed, 1440, 0, 22) "} 24h "
    Gui, Add, Text, xp+15 y+5, %minsPassed% minutes (%percentileDay%) of today have elapsed.
    If (A_OSVersion="WIN_XP")
       doResetGuiFont()

    Gui, Tab, 2
    Gui, Add, Text, x+15 y+15 w%txtWid% Section, Dedicated to Christians, church-goers and bell lovers.
    Gui, Add, Text, xs y+15 Section w%txtWid%, This application contains code and sounds from various entities.%newLine%You can find more details in the source code.
    compiled := (A_IsCompiled=1) ? "Compiled. " : "Uncompiled. "
    compiled .= (A_PtrSize=8) ? "x64. " : "x32. "
    Gui, Add, Text, xs y+15 w%txtWid%, Current version: v%version% from %ReleaseDate%. Internal AHK version: %A_AhkVersion%. %compiled%OS: %A_OSVersion%.
    Gui, Add, Text, y+15 +Border gOpenChangeLog, Click here to view the change log / version history.
    If (storeSettingsREG=1)
       Gui, Add, Link, xs y+10 w%txtWid% hwndhLink2, This application was downloaded through <a href="ms-windows-store://pdp/?productid=9PFQBHN18H4K">Windows Store</a>.
    Else      
       Gui, Add, Link, xs y+10 w%txtWid% hwndhLink2, The development page is <a href="https://github.com/marius-sucan/ChurchBellsTower">on GitHub</a>.
    Gui, Font, Bold
    Gui, Add, Link, xp+30 y+10 hwndhLink1, To keep the development going, `n<a href="https://www.paypal.me/MariusSucan/15">please donate</a> or <a href="mailto:marius.sucan@gmail.com?subject=%appName% v%Version%">send me feedback</a>.
    Gui, Add, Picture, x+10 yp+0 gDonateNow hp w-1 +0xE hwndhDonateBTN, paypal.png
    doResetGuiFont()

    Gui, Tab
    btnW1 := (PrefsLargeFonts=1) ? 110 : 80
    btnW2 := (PrefsLargeFonts=1) ? 80 : 55
    btnW3 := (PrefsLargeFonts=1) ? 110 : 80
    btnH := (PrefsLargeFonts=1) ? 35 : 28
    Gui, Add, Button, xm+0 y+10 Section h%btnH% w%btnW1% Default gCloseWindowAbout hwndhBtn1, &Deus lux est
    Gui, Add, Button, x+5 hp w%btnW2% gShowSettings hwndhBtn2, &Settings
    If (ObserveHolidays=1)
      Gui, Add, Button, x+5 hp w%btnW3% gPanelIncomingCelebrations hwndhBtn3, &Celebrations

    applyDarkMode2winPost("SettingsGUIA", hSetWinGui)
    Gui, Show, AutoSize, About: %appName%
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
   interfaceThread.ahkPostFunction("setMenusTheme", modus)
}

setDarkWinAttribs(hwndGUI, modus:=1) {
   if (A_OSVersion >= "10.0.17763" && SubStr(A_OSVersion, 1, 3) = "10.")
   {
       attr := 19
       if (A_OSVersion >= "10.0.18985") {
           attr := 20
       }
       DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwndGUI, "int", attr, "int*", modus, "int", 4)
   }
   DllCall(AllowDarkModeForWindow, "UPtr", hwndGUI, "int", modus) ; Dark
}

OpenChangeLog() {
  Try Run, bells-tower-change-log.txt
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
  INIaction(a, "silentHours", "SavedSettings")
  INIaction(a, "silentHoursA", "SavedSettings")
  INIaction(a, "silentHoursB", "SavedSettings")
  INIaction(a, "showTimeIdleAfter", "SavedSettings")
  INIaction(a, "showTimeWhenIdle", "SavedSettings")
  INIaction(a, "displayTimeFormat", "SavedSettings")
  INIaction(a, "markFullMoonHowls", "SavedSettings")
  INIaction(a, "BeepsVolume", "SavedSettings")
  INIaction(a, "DynamicVolume", "SavedSettings")
  INIaction(a, "AutoUnmute", "SavedSettings")
  INIaction(a, "hasHowledDay", "SavedSettings")
  INIaction(a, "userAlarmSound", "SavedSettings")
  INIaction(a, "userTimerSound", "SavedSettings")
  INIaction(a, "userMuteAllSounds", "SavedSettings")
  INIaction(a, "tickTockNoise", "SavedSettings")
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
  INIaction(a, "orderedBibleQuotes", "SavedSettings")
  INIaction(a, "SemantronHoliday", "SavedSettings")
  INIaction(a, "ObserveHolidays", "SavedSettings")
  INIaction(a, "ObserveSecularDays", "SavedSettings")
  INIaction(a, "ObserveReligiousDays", "SavedSettings")
  INIaction(a, "PreferSecularDays", "SavedSettings")
  INIaction(a, "UserReligion", "SavedSettings")
  INIaction(a, "noTollingWhenMhidden", "SavedSettings")
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
  ; INIaction(a, "userAlarmExceptPerso", "SavedSettings")
  ; INIaction(a, "userAlarmExceptRelu", "SavedSettings")
  ; INIaction(a, "userAlarmExceptSeculu", "SavedSettings")

; OSD settings
  INIaction(a, "DisplayTimeUser", "OSDprefs")
  INIaction(a, "constantAnalogClock", "OSDprefs")
  INIaction(a, "analogDisplay", "OSDprefs")
  INIaction(a, "analogDisplayScale", "OSDprefs")
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
  INIaction(a, "OSDmarginTop", "OSDprefs")
  INIaction(a, "OSDmarginBottom", "OSDprefs")
  INIaction(a, "OSDmarginSides", "OSDprefs")
  INIaction(a, "OSDroundCorners", "OSDprefs")
  INIaction(a, "showOSDprogressBar", "OSDprefs")
  INIaction(a, "makeScreenDark", "SavedSettings")
  INIaction(a, "maxBibleLength", "OSDprefs")

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

; verify check boxes
    BinaryVar(analogDisplay, 0)
    BinaryVar(NoWelcomePopupInfo, 0)
    BinaryVar(constantAnalogClock, 0)
    BinaryVar(PrefsLargeFonts, 0)
    BinaryVar(tollQuartersException, 0)
    BinaryVar(tollQuarters, 1)
    BinaryVar(tollNoon, 1)
    BinaryVar(tollHours, 1)
    BinaryVar(tollHoursAmount, 1)
    BinaryVar(userAlarmRepeated, 0)
    BinaryVar(userAlarmExceptSeculu, 0)
    BinaryVar(userAlarmExceptRelu, 0)
    BinaryVar(userAlarmExceptPerso, 0)
    BinaryVar(displayClock, 1)
    BinaryVar(AutoUnmute, 1)
    BinaryVar(tickTockNoise, 0)
    BinaryVar(DynamicVolume, 1)
    BinaryVar(AdditionalStrikes, 0)
    BinaryVar(showBibleQuotes, 0)
    BinaryVar(makeScreenDark, 1)
    BinaryVar(noTollingWhenMhidden, 0)
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
    BinaryVar(orderedBibleQuotes, 0)
    BinaryVar(AlarmersDarkScreen, 1)
    BinaryVar(analogMoonPhases, 1)

; verify numeric values: min, max and default values
    If (InStr(analogDisplayScale, "err") || !analogDisplayScale)
       analogDisplayScale := 1
    Else If (analogDisplayScale<0.3)
       analogDisplayScale := 0.25
    Else If (analogDisplayScale>4)
       analogDisplayScale := 4

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
    MinMaxVar(OSDalpha, 75, 252, 230)
    MinMaxVar(userAlarmSnooze, 1, 59, 5)
    MinMaxVar(userAlarmSound, 1, 6, 5)
    MinMaxVar(userTimerSound, 1, 6, 5)
    MinMaxVar(userAlarmMins, 0, 59, 30)
    MinMaxVar(userAlarmHours, 0, 23, 12)
    MinMaxVar(userTimerMins, 0, 59, 2)
    MinMaxVar(userTimerFreq, 1, 99, 2)
    MinMaxVar(userAlarmFreq, 1, 99, 4)
    MinMaxVar(showOSDprogressBar, 1, 6, 2)

    If (silentHoursB<silentHoursA)
       silentHoursB := silentHoursA
    If (ObserveHolidays=0)
       SemantronHoliday := 0

; verify HEX values
   HexyVar(OSDbgrColor, "131209")
   HexyVar(OSDtextColor, "FFFEFA")

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
  Sleep, 0
  Return
}

sillySoundHack() {   ; this helps mitigate issues caused by apps like Team Viewer
     Sleep, 2
     SoundPlay, non-existent.lol
     SoundBeep, 0, 1
     Result := DllCall("winmm\PlaySoundW", "Ptr", 0, "Ptr", 0, "Uint", 0x46) ; SND_PURGE|SND_MEMORY|SND_NODEFAULT
     Return Result
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
     stopAdditionalStrikes := 1
  
  If (tickTockNoise=1)
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

calculateEquiSols(i, year, localTime:=0) {
; Calculate and Display a single event for a single year (Either a Equiniox or Solstice)
; Meeus Astronomical Algorithms Chapter 27
; 4 events for param i: 1=AE, 2=SS, 3-VE, 4=WS

   k := i - 1
   JDEzero := calcInitialEquiSols(k, year)           ; Initial estimate of date of event
   ; fnOutputDebug("JDE0=" JDEzero)
   ; T := (JDEzero - 2451545.0) / 36525
   T := SM_Divide(JDEzero - 2451545, 36525)
   W := SM_Add(SM_Multiply(35999.373, T), "-2.47")
   ; W := 35999.373*T - 2.47
   dL := SM_Add( 1,  SM_Add( SM_Multiply(0.0334, COSdeg(W)), SM_Multiply(0.0007, COSdeg(SM_Multiply(2, W) ) ) ) )
   ; dL := 1 + 0.0334*COSdeg(W) + 0.0007*COSdeg(2*W)
   ; fnOutputDebug("dL=" dL)
   S := periodic24(T)
   ; fnOutputDebug("S=" S)
   JDE := SM_Add( JDEzero,  SM_Divide( SM_Multiply(0.00001, S), dL ) )  ; This is the answer in Julian Emphemeris Days
   ; JDE := JDEzero + ( (0.00001*S) / dL )   ; This is the answer in Julian Emphemeris Days
   TDT := fromJDtoUTC(JDE)                   ; Convert Julian Days to TDT in a Date Object
   If (localTime=1)
      Return convertUTCtoLocalTime(TDT)
   Else
      Return TDT
}

convertUTCtoLocalTime(givenTime) {
  ; convert Unix date to local AHK date (based on current time zone) (alternative)
  Static vSec := 1560516182
  vDate := 1970
  EnvAdd, vDate, % vSec, Seconds
  ; MsgBox, % vDate

  VarSetCapacity(SYSTEMTIME, 16, 0)
  vDate := RegExReplace(vDate, "(....)(..)(..)(..)(..)(..)", "$1 $2 $3 $4 $5 $6")
  Loop, Parse, vDate, % " "
       NumPut(A_LoopField, &SYSTEMTIME, A_Index*2 - 2, "UShort")

  vIntervalsUTC := vIntervalsLocal := 0
  DllCall("kernel32\SystemTimeToFileTime", "UPtr", &SYSTEMTIME, "Int64*", vIntervalsUTC)
  DllCall("kernel32\FileTimeToLocalFileTime", "Int64*", vIntervalsUTC, "Int64*", vIntervalsLocal)
  vDate := givenTime
  EnvAdd, vDate, % vIntervalsLocal//10000000, Seconds
  SYSTEMTIME := 0
  return vDate
}

calcInitialEquiSols(k, year) {
; Equinox & Solstice Calculator
;  The algorithms and correction tables for this computation come directly from the book Astronomical
;  Algorithms Second Edition by Jean Meeus, ©1998, published by Willmann-Bell, Inc., Richmond, VA, 
;  ISBN 0-943396-61-1. They were coded in JavaScript and built into the 
;  https://stellafane.org/misc/equinox.html web page by its author, Ken Slater.
; JS code converted to AHK by Marius Șucan

; Function valid for years between 1000 and 3000.
; Calculate an initial guess as the JD of the Equinox or Solstice of a Given Year.
; Meeus Astronomical Algorithms Chapter 27.

   JDEzero := 0
   Y := SM_Divide(year - 2000, 1000)
   ; fnOutputDebug("y=" Y)
    ; a := SM_Multiply(365242.37404, Y)
    ; b := SM_Multiply(0.05169, POW(Y, 2))
    ; fnOutputDebug("a=" a)
    ; fnOutputDebug("b=" b)
   If (k=0)
      JDEzero := SM_Add( SM_Add( 2451623.80984, SM_Multiply(365242.37404, Y) ), SM_Multiply(0.05169, POW(Y, 2) ) ) - SM_Multiply(0.00411, POW(Y, 3)) - SM_Multiply(0.00057, POW(Y, 4))
      ; JDEzero := 2451623.80984 + 365242.37404*Y + 0.05169*POW(Y, 2) - 0.00411*POW(Y, 3) - 0.00057*POW(Y, 4)
   Else If (k=1)
      JDEzero := SM_Add( SM_Add( 2451716.56767, SM_Multiply(365241.62603, Y) ), SM_Multiply(0.00325, POW(Y, 2) ) ) + SM_Multiply(0.00888, POW(Y, 3)) - SM_Multiply(0.00030, POW(Y, 4))
      ; JDEzero := 2451716.56767 + 365241.62603*Y + 0.00325*POW(Y, 2) + 0.00888*POW(Y, 3) - 0.00030*POW(Y, 4)
   Else If (k=2)
      JDEzero := SM_Add( 2451810.21715, SM_Multiply(365242.01767, Y)) - SM_Add( SM_Add( SM_Multiply(0.11575, POW(Y, 2) ) , SM_Multiply(0.00337, POW(Y, 3) ) ) , SM_Multiply(0.00078, POW(Y, 4) ) )
      ; JDEzero := 2451810.21715 + 365242.01767*Y - 0.11575*POW(Y, 2) + 0.00337*POW(Y, 3) + 0.00078*POW(Y, 4)
   Else If (k=3)
      JDEzero := SM_Add( 2451900.05952, SM_Multiply(365242.74049, Y)) - SM_Multiply(0.06223, POW(Y, 2)) - SM_Multiply(0.00823, POW(Y, 3)) + SM_Multiply(0.00032, POW(Y, 4))
      ; JDEzero := 2451900.05952 + 365242.74049*Y - 0.06223*POW(Y, 2) - 0.00823*POW(Y, 3) + 0.00032*POW(Y, 4)

   return JDEzero
}

COSdeg(deg) {
   Static PI := 3.14159265358979323846
   Return cos( SM_Divide(SM_Multiply(deg, PI), 180) )
   ; Return cos( deg * PI/180 )
}

POW(x, y) {
  return SM_POW(x, y)
  ; return x^y
}

periodic24(T) {
; Calculate 24 Periodic Terms.
; Meeus Astronomical Algorithms Chapter 27.
   static A := {1:485,2:203,3:199,4:182,5:156,6:136,7:77,8:74,9:70,10:58,11:52,12:50,13:45,14:44,15:29,16:18,17:17,18:16,19:14,20:12,21:12,22:12,23:9,24:8}
   static B := {1:324.96,2:337.23,3:342.08,4:27.85,5:73.14,6:171.52,7:222.54,8:296.72,9:243.58,10:119.81,11:297.17,12:21.02,13:247.54,14:325.15,15:60.93,16:155.12,17:288.79,18:198.04,19:199.76,20:95.39,21:287.11,22:320.81,23:227.73,24:15.45}
   static C := {1:1934.136,2:32964.467,3:20.186,4:445267.112,5:45036.886,6:22518.443,7:65928.934,8:3034.906,9:9037.513,10:33718.147,11:150.678,12:2281.226,13:29929.562,14:31555.956,15:4443.417,16:67555.328,17:4562.452,18:62894.029,19:31436.921,20:14577.848,21:31931.756,22:34777.259,23:1222.114,24:16859.074}

   S := 0
   Loop, 24
   {
      i := A_Index
      ; S += A[i] * COSdeg( B[i] + (C[i]*T) )
      S := SM_Add(S, SM_Multiply(A[i], COSdeg( SM_Add(B[i], SM_Multiply(C[i], T) ) )  ) )
   }
   return S
} 

fromJDtoUTC( JD ) {
; Julian Date to UTC date
; Meeus Astronomical Algorithms Chapter 7 
    Z := SM_Floor( SM_Add(JD, 0.5) )  ; Integer JD's
    F := SM_Add( SM_Add(JD, 0.5), -Z)     ; Fractional JD's
    if (Z < 2299161)
    {
       A := Z
    } else
    {
       alpha := SM_Floor( SM_Divide( SM_Add(Z, "-1867216.25"), 36524.25) )
       A := SM_Add( SM_Add( SM_Add(Z, 1), alpha), - SM_Floor( SM_Divide(alpha, 4, 90) )  )
    }

    B := SM_Add(A, 1524)
    C := SM_Floor( SM_Divide(SM_Add(B, "-122.1"), 365.25, 90) )
    ; C := Floor( (B-122.1) / 365.25 )
    D := SM_Floor( SM_Multiply(365.25, C) )
    ; D := Floor( 365.25*C )
    E := SM_Floor( SM_Divide(SM_Add(B, -D), 30.6001) )
    ; E := Floor( ( B-D )/30.6001 )
    DT := SM_Add( SM_Add( SM_Add(B, -D), - SM_Floor( SM_Multiply(30.6001, E) )  ),  F )   ; Day of Month with decimals for time
    ; DT := B - D - Floor(30.6001*E) + F   ; Day of Month with decimals for time

    G := (E < 13.5) ? 1 : 13
    Mon :=  SM_Add(E, -G)                     ; Month
    G := (Mon > 2.5) ? 4716 : 4715
    Yr := SM_Add(C, -G)                       ; Year
    Day := SM_Floor( DT )                     ; Day of Month without decimals for time
    H := SM_Multiply(24, SM_Add(DT, -Day) )   ; Hours and fractional hours 
    Hr := SM_Floor( H )                       ; Integer Hours
    M := SM_Multiply(60, SM_Add(H, -Hr) )    ; Minutes and fractional minutes
    Min := SM_Floor( M )                      ; Integer Minutes
    Sec := SM_Floor( 60 * (M - Min) )         ; Integer Seconds (Milliseconds discarded)

    ; theDate := Yr "-" Mon "-" Day "-" Hr "-" Min "-" Sec
    theDate := Yr Format("{:02}", Mon) Format("{:02}", Day) Format("{:02}", Hr) Format("{:02}", Min) Format("{:02}", Sec)
    return theDate
}

TZI_GetTimeZoneInformation() {
   ; source https://gist.github.com/hoppfrosch/6882628
   ; and  https://www.autohotkey.com/board/topic/68856-sample-dealing-with-time-zones-ahk-l/

   ; GetTimeZoneInformationForYear -> msdn.microsoft.com/en-us/library/bb540851(v=vs.85).aspx (Win Vista+)
   ; cmd.exe w32tm /tz

   Year := A_Year
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
   R.TotalCurrentBias := isinRange(A_YDay, R.DaylightDateYday, R.StandardDateYday) ? R.Bias + R.DaylightBias + R.StandardBias : R.Bias + R.StandardBias
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

MoonPhaseCalculator(t:=0, calcDetails:=0) {
; Calculate the phase and position of the moon for a given date.
; The algorithm is simple and adequate for many purposes.
;
; This software was originally adapted to Javascript by Stephen R. Schmitt
; from a BASIC program from the 'Astronomical Computing' column of Sky & Telescope,
; April 1994, page 86, written by Bradley E. Schaefer.
;
; Subsequently adapted from Stephen R. Schmitt's Javascript to C++ for the Arduino
; by Cyrus Rahman. And further down the timeline, the C++ code was converted to AHK
; by Marius Șucan in September 2022.
;
; This work is/was subjected to Stephen Schmitt's copyright:
; Copyright 2004 Stephen R. Schmitt
; You may use or modify this source code in any way you find useful, provided
; that you agree that the author(s) have no warranty, obligations or liability.  You
; must determine the suitability of this source code for your use.
;
; source https://github.com/signetica/MoonPhase

  Static MOON_SYNODIC_PERIOD := 29.530588853     ; Period of moon cycle in days.
       , MOON_SYNODIC_OFFSET := 2451550.26       ; Reference cycle offset in days. From number of days since new moon on Julian date MOON_SYNODIC_OFFSET (18:15 UTC January 6, 2000), determine remainder of incomplete cycle.
       , MOON_DISTANCE_PERIOD := 27.55454988     ; Period of distance oscillation
       , MOON_DISTANCE_OFFSET := 2451562.2
       , MOON_LATITUDE_PERIOD := 27.212220817    ; Latitude oscillation
       , MOON_LATITUDE_OFFSET := 2451565.2
       , MOON_LONGITUDE_PERIOD := 27.321582241   ; Longitude oscillation
       , MOON_LONGITUDE_OFFSET := 2451555.8
       , JULIAN_UNIX_EPOCH := 2440587.5          ; The Unix epoch (zero-point) is January 1, 1970 GMT as Julian daye
       , SECONDS_PER_DAY := 86400.0
       , LEAP_SECONDS := 27                      ; since 1972 until 2022
       , M_PI := 3.14159265358979
       , phaseNames := {1:"New moon", 2:"Waxing Crescent", 3:"First Quarter"
           , 4: "Waxing Gibbous", 5:"Full moon", 6:"Waning Gibbous"
           , 7:"Last Quarter", 8:"Waning Crescent"}

  If (t="now" || !t)
     t := A_NowUTC

  ; MsgBox, % NowUTC
  t -= 19700101000000, S

  ; jDate := getJulianDate(t)
  ; jDate := (t - LEAP_SECONDS) / SECONDS_PER_DAY + JULIAN_UNIX_EPOCH ; Julian day from Unix time
  jDate := SM_Add(SM_Divide(SM_Add(t, -LEAP_SECONDS), SECONDS_PER_DAY), JULIAN_UNIX_EPOCH) ; Julian day from Unix time

  ; Calculate illumination (synodic) phase
  phase := SM_Divide(SM_Add(jDate, -MOON_SYNODIC_OFFSET), MOON_SYNODIC_PERIOD)
  ; phase := (jDate - MOON_SYNODIC_OFFSET) / MOON_SYNODIC_PERIOD
  ; phase := phase - floor(phase)
  phase := SM_Add(phase, - SM_Floor(phase))

  ; Calculate age and illumination fraction.
  age := phase * MOON_SYNODIC_PERIOD
  ; age := SM_Multiply(phase, MOON_SYNODIC_PERIOD)
  fraction := (1.0 - cos(2 * M_PI * phase)) * 0.5
  ; fraction := SM_Multiply(SM_Add(1.0, -cos(SM_Multiply(2, SM_Multiply(M_PI, phase) ) ) ), 0.5)
  ; phaseID := mod(round(floor(phase * 8) + 0.51), 8) + 1

  If (age<1.307)
    phaseID := 1
  Else If (age<6.382)
    phaseID := 2
  Else If (age<8.382)
    phaseID := 3
  Else If (age<13.565)
    phaseID := 4
  Else If (age<15.965)
    phaseID := 5
  Else If (age<21.148)
    phaseID := 6
  Else If (age<23.148)
    phaseID := 7
  Else If (age<28.215)
    phaseID := 8
  Else
    phaseID := 1

  phaseName := phaseNames[phaseID]
  If (fraction>0.994 && phaseID=5)
     phaseName .= " (peak)"
  Else if (fraction<0.006 && phaseID=1)
     phaseName .= " (peak)"

  If (calcDetails=1)
  {
     ; Calculate distance from anomalistic phase.
     distancePhase := (jDate - MOON_DISTANCE_OFFSET) / MOON_DISTANCE_PERIOD
     distancePhase := distancePhase - floor(distancePhase)
     distance := 60.4 - 3.3 * cos(2 * M_PI * distancePhase) - 0.6 * cos(2 * 2 * M_PI * phase - 2 * M_PI * distancePhase) - 0.5 * cos(2 * 2 * M_PI * phase)
 
     ; Calculate ecliptic latitude from nodal (draconic) phase.
     latPhase := (jDate - MOON_LATITUDE_OFFSET) / MOON_LATITUDE_PERIOD
     latPhase := latPhase - floor(latPhase)
     latitude := 5.1 * sin(2 * M_PI * latPhase)
 
     ; Calculate ecliptic longitude from sidereal motion.
     longPhase := (jDate - MOON_LONGITUDE_OFFSET) / MOON_LONGITUDE_PERIOD
     longPhase := longPhase - floor(longPhase)
     longitude := longitude - 360 * longPhase + 6.3 * sin(2 * M_PI * distancePhase) + 1.3 * sin(2 * 2 * M_PI * phase - 2 * M_PI * distancePhase) + 0.7 * sin(2 * 2 * M_PI * phase)
     if (longitude > 360)
        longitude := longitude - 360
  }
  ; fnOutputDebug("jd=" jDate "; phase=" phase "; fraction=" fraction "; " phaseName)
  Return [phaseName, phaseID, phase, fraction, age, distance, latitude, longitude]
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

decideFadeColor() {
  newColor := MixARGB("0xFF" OSDbgrColor, "0xFF" OSDtextColor)
  OSDfadedColor := SubStr(newColor, 5)
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
   ; ToolTip, % r.w " --- " r.h , , , 2
   Return r
}

GetWinClientSize(ByRef w, ByRef h, hwnd, mode) {
; by Lexikos http://www.autohotkey.com/forum/post-170475.html
; modified by Marius Șucan
    Static prevW, prevH, prevHwnd, lastInvoked := 1
    If (A_TickCount - lastInvoked<95) && (prevHwnd=hwnd)
    {
       W := prevW, H := prevH
       Return
    }

    prevHwnd := hwnd
    VarSetCapacity(rc, 16, 0)
    If (mode=1)
    {
       r := GetWindowBounds(hwnd)
       prevW := W := r.w
       prevH := H := r.h
       lastInvoked := A_TickCount
       Return
    } Else DllCall("GetClientRect", "uint", hwnd, "uint", &rc)

    prevW := W := NumGet(rc, 8, "int")
    prevH := H := NumGet(rc, 12, "int")
    lastInvoked := A_TickCount
} 

mouseTurnOFFtooltip() {
   Gui, mouseToolTipGuia: Destroy
   mouseToolTipWinCreated := 0
}

mouseCreateOSDinfoLine(msg:=0, largus:=0) {
    Critical, On
    Static prevMsg, lastInvoked := 1
    Global TippyMsg

    thisHwnd := hSetWinGui
    If (StrLen(msg)<3) || (prevMsg=msg && mouseToolTipWinCreated=1) || (A_TickCount - lastInvoked<100) || !thisHwnd
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

    GetPhysicalCursorPos(mX, mY)
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
    Else If ((AnyWindowOpen || PrefOpen=1) && !InStr(A_GuiControl, "lview"))
       SettingsToolTips()
}

SettingsToolTips() {
   ActiveWin := WinActive("A")
   If (ActiveWin!=hSetWinGui)
      Return

   If (mouseToolTipWinCreated=1)
      mouseTurnOFFtooltip()
 
   Gui, SettingsGUIA: Default
   GuiControlGet, value, , %A_GuiControl%
   If (A_GuiControl="holiListu")
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

#If, (WinActive( "ahk_id " hFaceClock) && constantAnalogClock=1 && hFaceClock)
    Escape::
      hideAnalogClock()
      SetTimer, showAnalogClock, -150
    Return

    AppsKey::
      ClockGuiGuiContextMenu(34788, 0, 238990, 1, 32, 90)
    Return 

    Space::
      toggleMoonPhasesAnalog()
    Return
#If
