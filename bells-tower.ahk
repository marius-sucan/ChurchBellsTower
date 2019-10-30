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
;@Ahk2Exe-AddResource LIB analog-clock-display.ahk
;@Ahk2Exe-SetName Church Bells Tower
;@Ahk2Exe-SetCopyright Marius Şucan (2017-2018)
;@Ahk2Exe-SetCompanyName http://marius.sucan.ro
;@Ahk2Exe-SetDescription Church Bells Tower
;@Ahk2Exe-SetVersion 2.8.1
;@Ahk2Exe-SetOrigFilename bells-tower.ahk
;@Ahk2Exe-SetMainIcon bells-tower.ico

;================================================================
; Section. Auto-exec.
;================================================================

; Script Initialization

 #SingleInstance Force
 #NoEnv
 #MaxMem 256
 #Include, Class_ImageButton.ahk
 #Include, va.ahk                   ; vista audio APIs wrapper by Lexikos

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
 , tollQuarters         := 1 
 , tollQuartersException := 0 
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
 , UserReligion         := 1
 , SemantronHoliday     := 0
 , ObserveHolidays      := 0
 , ObserveSecularDays   := 1
 , ObserveReligiousDays := 1
 , PreferSecularDays    := 0
 , noTollingWhenMhidden := 0
 , noTollingBgrSounds   := 0
 , NoWelcomePopupInfo   := 0
 , showTimeWhenIdle     := 0
 , showTimeIdleAfter    := 5 ; [in minutes]

; OSD settings
 , displayTimeFormat      := 1
 , DisplayTimeUser        := 3     ; in seconds
 , displayClock           := 1
 , analogDisplay          := 0
 , analogDisplayScale     := 0.3
 , constantAnalogClock    := 0
 , GuiX                   := 40
 , GuiY                   := 250
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

; Release info
 , ThisFile               := A_ScriptName
 , Version                := "2.8.1"
 , ReleaseDate            := "2019 / 10 / 30"
 , storeSettingsREG := FileExist("win-store-mode.ini") && A_IsCompiled && InStr(A_ScriptFullPath, "WindowsApps") ? 1 : 0
 , ScriptInitialized, FirstRun := 1
 , QuotesAlreadySeen := ""
 , LastNoon := 0, appName := "Church Bells Tower"
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
 , LastNoonSound := 1
 , OSDprefix, OSDsuffix
 , stopStrikesNow := 0
 , ClockVisibility := 0
 , stopAdditionalStrikes := 0
 , strikingBellsNow := 0
 , DoGuiFader := 1
 , lastFaded := 1
 , cutVolumeHalf := 0
 , defAnalogClockPosChanged := 0
 , FontChangedTimes := 0
 , AnyWindowOpen := 0
 , LastBibleQuoteDisplay := 1
 , LastBibleQuoteDisplay2 := 1
 , LastBibleMsg := ""
 , CurrentPrefWindow := 0
 , celebYear := A_Year
 , isHolidayToday := 0
 , TypeHolidayOccured := 0
 , hMain := A_ScriptHwnd
 , lastOSDredraw := 1
 , semtr2play := 0
 , aboutTheme, GUIAbgrColor, AboutTitleColor, hoverBtnColor, BtnTxtColor, GUIAtxtColor
 , attempts2Quit := 0
 , roundCornerSize := Round(FontSize/2) + Round(OSDmarginSides/5)
 , StartRegPath := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
 , tickTockSound := A_ScriptDir "\sounds\ticktock.wav"
 , hBibleTxt, hBibleOSD, hSetWinGui, ColorPickerHandles
 , CCLVO := "-E0x200 +Border -Hdr -Multi +ReadOnly Report AltSubmit gsetColors"
 , hWinMM := DllCall("kernel32\LoadLibraryW", "Str", "winmm.dll", "Ptr")
 , sndChanQ, sndChanH, sndChanA, sndChanJ, sndChanN, sndChanS
 , analogClockThread, isAnalogClockFile

If (roundCornerSize<20)
   roundCornerSize := 20

; Initializations of the core components and functionality

If (A_IsCompiled && storeSettingsREG=0)
   VerifyFiles()

Sleep, 5
InitAHKhThreads()
Sleep, 5
SetMyVolume(1)
InitializeTray()

hCursM := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32646, "Ptr")  ; IDC_SIZEALL
hCursH := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32649, "Ptr")  ; IDC_HAND
OnMessage(0x200, "WM_MouseMove")
OnMessage(0x404, "AHK_NOTIFYICON")
Sleep, 5
theChimer()
Sleep, 30
testCelebrations()
ScriptInitialized := 1      ; the end of the autoexec section and INIT
If (tickTockNoise=1)
   SoundLoop(tickTockSound)

If !isHolidayToday
   CreateBibleGUI(generateDateTimeTxt())

If (AdditionalStrikes=1)
   SetTimer, AdditionalStriker, %AdditionalStrikeFreq%
If (showBibleQuotes=1)
   SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%

SetTimer, analogClockStarter, % -DisplayTime + 2000

If (NoWelcomePopupInfo!=1)
   ShowWelcomeWindow()

If (showTimeWhenIdle=1)
   SetTimer, TimerShowOSDidle, 1500

Return    ; the end of auto-exec section

TimerShowOSDidle() {
     If (constantAnalogClock=1) || (analogDisplay=1 && ClockVisibility=1) || (PrefOpen=1) || (A_IsSuspended)
        Return

     If !A_IsSuspended
        mouseHidden := checkMcursorState()

     If (showTimeWhenIdle=1 && (A_TimeIdle > userIdleAfter)  && mouseHidden!=1)
     {
        DoGuiFader := 0
        If (BibleGuiVisible!=1)
           CreateBibleGUI(generateDateTimeTxt(0, 1))
        Else
           GuiControl, BibleGui:, BibleGuiTXT, % generateDateTimeTxt(0, 1)
        SetTimer, DestroyBibleGui, Delete
        DoGuiFader := 1
     } Else If (showTimeWhenIdle=1 && BibleGuiVisible=1)
        SetTimer, DestroyBibleGui, -500
}

ShowWelcomeWindow() {
    If (PrefOpen=1 || AnyWindowOpen=1)
       Return

    Global BtnSilly0, BtnSilly1, BtnSilly2
    SettingsGUI()
    AnyWindowOpen := 2
    Gui, Font, s20 Bold, Arial, -wrap
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section hwndhIcon, bell-image.png
    Gui, Add, Text, x+7 y10, %appName%
    Gui, Font, s12 Bold, Arial, -wrap
    Gui, Add, Text, y+5, Quick start window - read me
    Gui, Font
    btnWid := 150
    txtWid := 310
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 100
       txtWid := txtWid + 170
       Gui, Font, s%LargeUIfontValue%
    }

    Gui, Add, Text, xs y+10 w%txtWid%, %appName% is currently running in background. To configure it or exit, please locate its icon in the system tray area, next to the system clock in the taskbar. To access the settings double click or right click on the bell icon.
    Gui, Add, Button, xs y+10 w%btnWid% gShowSettings, &Settings panel
    Gui, Add, Checkbox, x+5 w%btnWid% hp +0x1000 gToggleLargeFonts Checked%PrefsLargeFonts% vPrefsLargeFonts, Large UI font sizes
    Gui, Add, Button, xs y+10 w%btnWid% gAboutWindow, &About today
    Gui, Add, Checkbox, x+5 w%btnWid% hp +0x1000 gToggleAnalogClock Checked%constantAnalogClock% vconstantAnalogClock, &Analog clock display
    Gui, Add, Checkbox, xs y+10 gToggleWelcomeInfos Checked%NoWelcomePopupInfo% vNoWelcomePopupInfo, &Never show this window
    Gui, Show, AutoSize, Welcome to %appName% v%Version%
}

ToggleWelcomeInfos() {
  GuiControlGet, NoWelcomePopupInfo
;  NoWelcomePopupInfo := !NoWelcomePopupInfo
  INIaction(1, "NoWelcomePopupInfo", "SavedSettings")
  CloseWindow()
  Sleep, 50
  If (NoWelcomePopupInfo=1)
  {
     MsgBox, 52, %appName%, Do you want to keep the welcome window open for now?
     IfMsgBox, Yes
       ShowWelcomeWindow()
  } Else ShowWelcomeWindow()
}

analogClockStarter() {
  If (constantAnalogClock=1 && isAnalogClockFile)
  {
     ClockVisibility := 1
     DestroyBibleGui()
     analogClockThread.ahkFunction["showClock"]
  }
}

VerifyFiles() {
  Loop, Files, sounds\*.wav
        countFiles++
  Loop, Files, sounds\*.mp3
        countFiles++
  Sleep, 50
  FileCreateDir, sounds
  FileInstall, bell-image.png, bell-image.png
  FileInstall, bells-tower-change-log.txt, bells-tower-change-log.txt
  FileInstall, bible-quotes-eng.txt, bible-quotes-eng.txt
  FileInstall, bible-quotes-fra.txt, bible-quotes-fra.txt
  FileInstall, bible-quotes-esp.txt, bible-quotes-esp.txt
  FileInstall, paypal.png, paypal.png
  FileInstall, sounds\auxilliary-bell.mp3, sounds\auxilliary-bell.mp3
  FileInstall, sounds\christmas.mp3, sounds\christmas.mp3
  FileInstall, sounds\evening.mp3, sounds\evening.mp3
  FileInstall, sounds\hours.mp3, sounds\hours.mp3
  FileInstall, sounds\japanese-bell.mp3, sounds\japanese-bell.mp3
  FileInstall, sounds\midnight.mp3, sounds\midnight.mp3
  FileInstall, sounds\morning.mp3, sounds\morning.mp3
  FileInstall, sounds\noon1.mp3, sounds\noon1.mp3
  FileInstall, sounds\noon2.mp3, sounds\noon2.mp3
  FileInstall, sounds\noon3.mp3, sounds\noon3.mp3
  FileInstall, sounds\noon4.mp3, sounds\noon4.mp3
  FileInstall, sounds\orthodox-chimes1.mp3, sounds\orthodox-chimes1.mp3
  FileInstall, sounds\orthodox-chimes2.mp3, sounds\orthodox-chimes2.mp3
  FileInstall, sounds\quarters.mp3, sounds\quarters.mp3
  FileInstall, sounds\semantron1.mp3, sounds\semantron1.mp3
  FileInstall, sounds\semantron2.mp3, sounds\semantron2.mp3
  FileInstall, sounds\ticktock.wav, sounds\ticktock.wav
  Sleep, 300
}

AHK_NOTIFYICON(wParam, lParam, uMsg, hWnd) {
  If (PrefOpen=1 || A_IsSuspended)
     Return

  Static LastInvoked := 1, LastInvoked2 := 1
  If (lParam = 0x201) || (lParam = 0x204)
  {
     stopStrikesNow := 1
     strikingBellsNow := 0
     DoGuiFader := 0
     If (ClockVisibility=0 || defAnalogClockPosChanged=1 && ClockVisibility=1) && (lParam=0x201 && ScriptInitialized=1)         ; left click
        CreateBibleGUI(generateDateTimeTxt())
     DoGuiFader := 1
     If (A_TickCount-lastInvoked2>7000)
        FreeAhkResources(1)
     LastInvoked2 := A_TickCount
  } Else If (lParam = 0x207) && (strikingBellsNow=0)   ; middle click
  {
     If (A_TickCount-lastInvoked2>7000)
        FreeAhkResources(1)
     LastInvoked2 := A_TickCount
     If (AnyWindowOpen=1)
        stopStrikesNow := 0
     SetMyVolume(1)
     DoGuiFader := 0
     If (ClockVisibility=0 || defAnalogClockPosChanged=1 && ClockVisibility=1)
        CreateBibleGUI(generateDateTimeTxt())
     If (tollQuarters=1)
        strikeQuarters()
     If (tollHours=1 || tollHoursAmount=1)
        strikeHours()
     DoGuiFader := 1
  } Else If (BibleGuiVisible=0 && strikingBellsNow=0)
    && (A_TickCount-lastInvoked>2000) && (A_TickCount-lastFaded>1500)
  {
     LastInvoked := A_TickCount
     DoGuiFader := 1
     If (ClockVisibility=0 || defAnalogClockPosChanged=1 && ClockVisibility=1) && (ScriptInitialized=1)
        CreateBibleGUI(generateDateTimeTxt(0))
  }
}

strikeJapanBell() {
  If (noTollingBgrSounds>=2)
     isSoundPlayingNow()

  If (stopAdditionalStrikes=1)
     Return
  SetMyVolume(1)
  If !sndChanJ
     sndChanJ := AhkThread("#NoTrayIcon`nSoundPlay, sounds\japanese-bell.mp3, 1")
  Else
     sndChanJ.ahkReload[]
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

  If (PrefOpen!=1)
  {
     If !countLines
        countLines := st_count(bibleQuotesFile, "`n") + 1
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

  If st_count(bibleQuote, """")=1
     StringReplace, bibleQuote, bibleQuote, "

  If (BibleQuotesLang=1)
  {
     bibleQuote := RegExReplace(bibleQuote, "i)(\ssaying.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\ssaid.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\sand.?)$")
     bibleQuote := RegExReplace(bibleQuote, "i)(\sbut)$")
  }
  bibleQuote := RegExReplace(bibleQuote, "i)(\;|\,|\:)$")
  LastBibleMsg := bibleQuote

  QuotesAlreadySeen .= "a" Line2Read "a"
  StringReplace, QuotesAlreadySeen, QuotesAlreadySeen, aa, a
  StringRight, QuotesAlreadySeen, QuotesAlreadySeen, 91550
  If (StrLen(bibleQuote)>6)
  {
     LastBibleQuoteDisplay := LastBibleQuoteDisplay2 := A_TickCount
     Sleep, 2
     CreateBibleGUI(bibleQuote, 1, 1)
  }

  If (PrefOpen!=1)
  {
     If (menuAdded!=1)
     {
        menuAdded := 1
        Menu, Tray, Enable, Show previous Bible &quote
     }
     SetMyVolume(1)
     INIaction(1, "QuotesAlreadySeen", "SavedSettings")
     If (mouseHidden!=1)
        strikeJapanBell()
  } Else SoundPlay, sounds\japanese-bell.mp3

  quoteDisplayTime := 1500 + StrLen(bibleQuote) * 123
  If (quoteDisplayTime>120100)
     quoteDisplayTime := 120100
  Else If (PrefOpen=1)
     quoteDisplayTime := quoteDisplayTime/2 + DisplayTime

  SetTimer, DestroyBibleGui, % -quoteDisplayTime
  SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%
}

DestroyBibleGui() {
  Critical, On
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
  }
}

SetMyVolume(noRestore:=0) {
  Static mustRestoreVol, LastInvoked := 1

  If (PrefOpen=1)
     GuiControlGet, DynamicVolume
  Else If (AnyWindowOpen>0)
     CloseWindow()

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

  If (A_TickCount - LastNoonSound<150000) && (PrefOpen=0 && noTollingBgrSounds=2)
     Return

  If (ScriptInitialized=1 && AutoUnmute=1 && BeepsVolume>3
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
    GuiControlGet, result , , BeepsVolume, 
    GuiControlGet, tollQuarters
    GuiControlGet, tollHours
    GuiControlGet, tollHoursAmount
    GuiControlGet, strikeInterval

    stopStrikesNow := 0
    BeepsVolume := result
    SetMyVolume(1)
    VerifyTheOptions()
    GuiControl, , volLevel, % (result<2) ? "Audio: [ MUTE ]" : "Audio volume: " result " % "
    If (tollQuarters=1)
       strikeQuarters()

    If (tollHours=1 || tollHoursAmount=1)
       strikeHours()
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

strikeQuarters() {
  If (stopStrikesNow=1)
     Return

  sleepDelay := RandomNumberCalc()
  sndChanQ := AhkThread("#NoTrayIcon`nSoundPlay, sounds\quarters.mp3, 1")

  If (PrefOpen!=1)
     Sleep, % strikeInterval + sleepDelay
  Else
     Sleep, 600
}

strikeHours() {
  If (stopStrikesNow=1)
     Return

  sleepDelay := RandomNumberCalc()
  sndChanH := AhkThread("#NoTrayIcon`nSoundPlay, sounds\hours.mp3, 1") 
  If (PrefOpen!=1)
     Sleep, % strikeInterval + sleepDelay
}

playSemantronDummy() {
  playSemantron()
}

playSemantron(snd:=1) {
  If (stopStrikesNow=1)
     Return

  If (snd=1)
     semtr2play := "semantron1"
  Else If (snd=2)
     semtr2play := "semantron2"
  Else If (snd=3)
     semtr2play := "orthodox-chimes2"
  Else If (snd=4)
     semtr2play := "orthodox-chimes1"

  sleepDelay := RandomNumberCalc() * 2
  Sleep, %sleepDelay%

  If !sndChanS
     sndChanS := AhkThread("#NoTrayIcon`nMEx:=AhkExported()`nsmd:=MEx.ahkgetvar.semtr2play`nSoundPlay, sounds\%smd%.mp3, 1")
  Else
     sndChanS.ahkReload[]

  Global LastNoonSound := A_TickCount
}

TollExtraNoon() {
  Static lastToll := 1
  If (noTollingBgrSounds>=2)
     isSoundPlayingNow()

  If (AnyWindowOpen=1)
     stopStrikesNow := 0

  If (stopStrikesNow=1 || PrefOpen=1)
  || ((A_TickCount - lastToll<100000) && (AnyWindowOpen=1))
     Return

  Global LastNoonSound := A_TickCount
  Sleep, 50
  If (noTollingBgrSounds=2)
     SetMyVolume(1)
  If !sndChanN
     sndChanN := AhkThread("#NoTrayIcon`nRandom, choice, 1, 4`nSoundPlay, sounds\noon%choice%.mp3, 1")
  Else
     sndChanN.ahkReload[]

  lastToll := A_TickCount
}

AdditionalStriker() {
  If (noTollingBgrSounds>=2)
     isSoundPlayingNow()

  If (noTollingWhenMhidden=1)
     mouseHidden := checkMcursorState()

  If (stopAdditionalStrikes=1 || mouseHidden=1 || A_IsSuspended || PrefOpen=1 || strikingBellsNow=1)
     Return
  SetMyVolume(1)
  If !sndChanA
     sndChanA := AhkThread("#NoTrayIcon`nSoundPlay, sounds\auxilliary-bell.mp3, 1")
  Else
     sndChanA.ahkReload[]
}

readjustBibleTimer() {
  SetTimer, InvokeBibleQuoteNow, Off
  Sleep, 25
  SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%
}

theChimer() {
  Critical, on
  Static lastChimed, todayTest
  FormatTime, CurrentTime,, hh:mm
  SetTimer, FreeAhkResources, Off
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

  If (todayTest!=A_MDay) && (ScriptInitialized=1)
  {
     If (A_WDay=2 || A_WDay=5)
        FreeAhkResources(1,1)
     Sleep, 100
     testCelebrations()
  }

  If (noTollingWhenMhidden=1)
     mouseHidden := checkMcursorState()

  todayTest := A_MDay
  If (HoursIntervalTest>=silentHoursA && HoursIntervalTest<=silentHoursB && silentHours=2)
     soundBells := 1

  If (HoursIntervalTest>=silentHoursA && HoursIntervalTest<=silentHoursB && silentHours=3)
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
  strikingBellsNow := 1
  Random, delayRandNoon, 950, 5050

  If (InStr(exactTime, "06:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     SoundPlay, sounds\morning.mp3, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
  } Else If (InStr(exactTime, "18:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     If (BeepsVolume>1)
        SoundPlay, sounds\evening.mp3, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
     If (StrLen(isHolidayToday)>3 && SemantronHoliday=0 && TypeHolidayOccured>1)
        SetTimer, TollExtraNoon, -51000
  } Else If (InStr(exactTime, "00:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     If (BeepsVolume>1)
        SoundPlay, sounds\midnight.mp3, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
  }

  If (InStr(CurrentTime, ":15") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     strikeQuarters()
  } Else If (InStr(CurrentTime, ":30") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     Loop, 2
        strikeQuarters()
  } Else If (InStr(CurrentTime, ":45") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     showTimeNow()
     Loop, 3
     {
        strikeQuarters()
        If (stopStrikesNow=0)
           Sleep, % A_Index * 160
     }
  } Else If InStr(CurrentTime, ":00")
  {
     FormatTime, countHours2beat,, h   ; 0-12 format
     If (tollQuarters=1 && tollQuartersException=0)
     {
        volumeAction := SetMyVolume()
        showTimeNow()
        Loop, 4
        {
           strikeQuarters()
           If (stopStrikesNow=0)
              Sleep, % A_Index * 140
        }
     }
     Random, delayRand, 900, 1600
     If (stopStrikesNow=0)
        Sleep, %delayRand%
     If (countHours2beat="00") || (countHours2beat=0)
        countHours2beat := 12
     If (tollHoursAmount=1 && tollHours=1)
     {
        volumeAction := SetMyVolume()
        showTimeNow()
        Loop, %countHours2beat%
        {
           strikeHours()
           If (stopStrikesNow=0)
              Sleep, % A_Index * 85
        }
     } Else If (tollHours=1)
     {
        volumeAction := SetMyVolume()
        showTimeNow()
        strikeHours()
     }

     If (InStr(exactTime, "12:0") && tollNoon=1)
     {
        Random, delayRand, 2000, 8500
        If (stopStrikesNow=0)
           Sleep, %delayRand%
        volumeAction := SetMyVolume()
        choice := (LastNoon=4) ? 1 : LastNoon + 1
        If (storeSettingsREG=0)
           IniWrite, %choice%, %IniFile%, SavedSettings, LastNoon
        Else
           RegWrite, REG_SZ, %APPregEntry%, LastNoon, %choice%

        If (tollHours=0)
           showTimeNow()

        If (stopStrikesNow=0 && ScriptInitialized=1 && volumeAction>0 && BeepsVolume>1)
        {
           Global LastNoonSound := A_TickCount
           SoundPlay, sounds\noon%choice%.mp3, 1
           Global LastNoonSound := A_TickCount
        } Else If (stopStrikesNow=0 && BeepsVolume>1)
        {
           Random, newDelay, 49000, 99000
           Global LastNoonSound := A_TickCount
           SoundPlay, sounds\noon%choice%.mp3
           Global LastNoonSound := A_TickCount
           If (A_WDay=1 || StrLen(isHolidayToday)>3)  ; on Sundays or holidays
              SetTimer, TollExtraNoon, % -newDelay
        }
     }
  }

  If (SemantronHoliday=1 && StrLen(isHolidayToday)>3)
  {
     If InStr(exactTime, "09:45")
        playSemantron(1)
     Else If InStr(exactTime, "17:45")
        playSemantron(2)
     Else If InStr(exactTime, "22:45")
        playSemantron(3)

     If (InStr(exactTime, "11:45") && (A_WDay=1 || A_WDay=7))
     {
        SetTimer, playSemantronDummy, -60000
        playSemantron(4)
     }
  } Else If (StrLen(isHolidayToday)>3 && TypeHolidayOccured=1) && (tollNoon=1 || tollQuarters=1)
  {
     Random, newDelay, 39000, 89000
     If (InStr(exactTime, "09:45") || InStr(exactTime, "17:45"))
        SetTimer, TollExtraNoon, % -newDelay
  }

  If (AutoUnmute=1 && volumeAction>0)
  {
     If (volumeAction=1 || volumeAction=3)
        SoundSet, 1, , mute
     If (volumeAction=2 || volumeAction=3)
        SoundSet, %master_vol%
  }
  strikingBellsNow := 0
  lastChimed := CurrentTime
  SetTimer, theChimer, % calcNextQuarter()
  SetTimer, FreeAhkResources, -350100, 950
}

showTimeNow() {
  If (displayClock=0)
     Return

  If (analogDisplay=1 && isAnalogClockFile)
  {
     analogClockThread.ahkPostFunction["showClock"]
     DestroyBibleGui()
  } Else CreateBibleGUI(generateDateTimeTxt(1,1))
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

CreateBibleGUI(msg2Display, isBibleQuote:=0, centerMsg:=0,noAdds:=0) {
    Critical, On
    lastOSDredraw := A_TickCount
    bibleQuoteVisible := (isBibleQuote=1) ? 1 : 0
    FontSizeMin := (isBibleQuote=1) ? FontSizeQuotes : FontSize
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
    Gui, ShareBtnGui: Add, Text, c%OSDbgrColor% gCopyLastQuote, Copy && share quote
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
  Sleep, 500
  GuiFader("BibleShareBtn","hide", OSDalpha)
  Sleep, 150
  Gui, ShareBtnGui: Destroy
  ToolTip
}

WM_MouseMove(wP, lP, msg, hwnd) {
; Function by Drugwash
  Global
  Local A
  SetFormat, Integer, H
  hwnd+=0, A := WinExist("A"), hwnd .= "", A .= ""
  SetFormat, Integer, D
  HideDelay := (PrefOpen=1) ? 600 : 2550
  If (A_TickCount - LastBibleQuoteDisplay<HideDelay+100) || (A_TickCount - lastOSDredraw<1000)
     Return

  If InStr(hBibleOSD, hwnd)
  {
     If (PrefOpen=0)
        DestroyBibleGui()
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
        DestroyBibleGui()
  } Else If ColorPickerHandles
  {
     If hwnd in %ColorPickerHandles%
        DllCall("user32\SetCursor", "Ptr", hCursH)
  } Else If (InStr(hwnd, hBibleOSD) && (A_TickCount - LastBibleQuoteDisplay>HideDelay))
        DestroyBibleGui()
}

trackMouseDragging() {
; Function by Drugwash
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
     saveGuiPositions()
}

saveGuiPositions() {
; function called after dragging the OSD to a new position

  If (PrefOpen=0)
  {
     Sleep, 700
     SetTimer, DestroyBibleGui, -1500
     INIaction(1, "GuiX", "OSDprefs")
     INIaction(1, "GuiY", "OSDprefs")
  } Else If (PrefOpen=1)
  {
     GuiControl, SettingsGUIA:, GuiX, %GuiX%
     GuiControl, SettingsGUIA:, GuiY, %GuiY%
  }
}

SetStartUp() {
  If (A_IsSuspended || PrefOpen=1)
  {
     SoundBeep, 300, 900
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
     Menu, Tray, Check, Sta&rt at boot
     CreateBibleGUI("Enabled Start at Boot",,,1)
  } Else
  {
     RegDelete, %StartRegPath%, %appName%
     Menu, Tray, Uncheck, Sta&rt at boot
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
   FreeAhkResources(1)
   If !A_IsSuspended
   {
      stopStrikesNow := 1
      DoGuiFader := 0
      SetTimer, theChimer, Off
      Menu, Tray, Uncheck, &%appName% activated
      SoundLoop("")
      If (constantAnalogClock=1 && isAnalogClockFile)
         analogClockThread.ahkFunction["hideClock"]
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
    If (ShowBibleQuotes=1)
    {
       Menu, Tray, Add, Show previous Bible &quote, ShowLastBibleMsg
       Menu, Tray, Disable, Show previous Bible &quote
    }
    Menu, Tray, Add, &Customize, ShowSettings
    Menu, Tray, Add, L&arge UI fonts, ToggleLargeFonts
    If (storeSettingsREG=0)
       Menu, Tray, Add, Sta&rt at boot, SetStartUp

    Menu, Tray, Add

    RegRead, currentReg, %StartRegPath%, %appName%
    If (StrLen(currentReg)>5 && storeSettingsREG=0)
       Menu, Tray, Check, Sta&rt at boot

    If (PrefsLargeFonts=1)
       Menu, Tray, Check, L&arge UI fonts

    RunType := A_IsCompiled ? "" : " [script]"
    If FileExist(tickTockSound)
       Menu, Tray, Add, Tick/Toc&k sound, ToggleTickTock
    If isAnalogClockFile
       Menu, Tray, Add, Analo&g clock display (constantly), toggleAnalogClock
    Menu, Tray, Add
    Menu, Tray, Add, &%appName% activated, SuspendScriptNow
    Menu, Tray, Check, &%appName% activated
    Menu, Tray, Add, &Restart, ReloadScriptNow
    Menu, Tray, Add
    Menu, Tray, Add, &About, AboutWindow
    Menu, Tray, Add
    Menu, Tray, Add, E&xit, KillScript, P50
    Menu, Tray, Tip, %appName% v%Version%%RunType%
    Menu, Tray, Default, &About
    Menu, Tray, % (constantAnalogClock=0 ? "Uncheck" : "Check"), Analo&g clock display (constantly)
    If (tickTockNoise=1)
       Menu, Tray, Check, Tick/Toc&k sound
}

ToggleLargeFonts() {
    PrefsLargeFonts := !PrefsLargeFonts
    LargeUIfontValue := 13
    INIaction(1, "PrefsLargeFonts", "SavedSettings")
    INIaction(1, "LargeUIfontValue", "SavedSettings")
    Menu, Tray, % (PrefsLargeFonts=0 ? "Uncheck" : "Check"), L&arge UI fonts
    If (PrefOpen=1)
    {
       SwitchPreferences(1)
    } Else If (AnyWindowOpen=1)
    {
       CloseWindow()
       AboutWindow()
    } Else If (AnyWindowOpen=2)
    {
       CloseWindow()
       ShowWelcomeWindow()
    }
}

ToggleTickTock() {
    If (A_IsSuspended || PrefOpen=1)
    {
       SoundBeep, 300, 900
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
    {
       analogClockThread.ahkassign("tickTockNoise", tickTockNoise)
       analogClockThread.ahkPostFunction("SynchSecTimer")
    }

    If (noTollingBgrSounds>=2)
       isSoundPlayingNow()
    SetMyVolume(1)
}

ChangeClockSize(newSize) {
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
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
       Return
    }

   constantAnalogClock := !constantAnalogClock
   INIaction(1, "constantAnalogClock", "OSDprefs")
   Menu, Tray, % (constantAnalogClock=0 ? "Uncheck" : "Check"), Analo&g clock display (constantly)
   If (constantAnalogClock=1)
      analogClockThread.ahkPostFunction["showClock"]
   Else
      analogClockThread.ahkPostFunction["hideClock"]
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
    If (PrefOpen=1)
    {
       CloseSettings()
       Return
    }
    DestroyBibleGui()
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
   DestroyBibleGui()
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
   DestroyBibleGui()
   Sleep, 50
   Cleanup()
   ExitApp
}

;================================================================
;  Settings window.
;   various functions used in the UI.
;================================================================

SettingsGUI(themed:=0) {
   Global
   If (themed=1)
      determineUIcolors()
   Gui, SettingsGUIA: Destroy
   Sleep, 15
   Gui, SettingsGUIA: Default
   Gui, SettingsGUIA: -MaximizeBox -MinimizeBox hwndhSetWinGui
   Gui, SettingsGUIA: Margin, 15, 15
   If (themed=1)
      Gui, SettingsGUIA: Color, %GUIAbgrColor%
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
    SettingsGUI()
}

verifySettingsWindowSize(noCheckLargeUI:=0) {
    Static lastAsked := 1
    SysGet, MonitorCount, 80
    ActiveMon := MWAGetMonitorMouseIsIn()
    If !ActiveMon
       Return
    SysGet, mCoord, MonitorWorkArea, %ActiveMon%
    ResolutionWidth := Abs(max(mCoordRight, mCoordLeft) - min(mCoordRight, mCoordLeft))
    ResolutionHeight := Abs(max(mCoordTop, mCoordBottom) - min(mCoordTop, mCoordBottom))
    If (MonitorCount>1)
    {
       semiFinal_x := semiFinal_y := mCoordLeft + 20
       Gui, SettingsGUIA: Show, Hide AutoSize x%semiFinal_x% y%semiFinal_y%
       Sleep, 25
       WinGetPos,,, setWid, setHeig, ahk_id %hSetWinGui%
       dummyA := min(mCoordRight, mCoordLeft) + max(mCoordRight, mCoordLeft)
       dummyB := min(mCoordTop, mCoordBottom) + max(mCoordTop, mCoordBottom)
       mGuiX := Round(dummyA/2 - setWid/2)
       mGuiY := Round(dummyB/2 - setHeig/2)
       Final_x := max(mCoordLeft, min(mGuiX, mCoordRight - setWid))
       Final_y := max(mCoordTop, min(mGuiY, mCoordBottom - setHeig))
       Gui, SettingsGUIA: Show, x%Final_x% y%Final_y%
    } Else
    {
       WinGetPos,,, setWid, setHeig, ahk_id %hSetWinGui%
    }

    If (setHeig>ResolutionHeight*0.95) || (setWid>ResolutionWidth*0.95)
    {
       If (LargeUIfontValue>11)
       {
          LargeUIfontValue := LargeUIfontValue - 1
          INIaction(1, "LargeUIfontValue", "SavedSettings")
       }
    }

    If (PrefsLargeFonts=0) || (A_TickCount-lastAsked<30000) || (noCheckLargeUI=1)
       Return

    If (setHeig>ResolutionHeight-2) || (setWid>ResolutionWidth-2)
    {
       SoundBeep, 300, 900
       lastAsked := A_TickCount
       MsgBox, 52, %appName%: warning, The option "Large UI fonts" is enabled. The window seems to exceed your screen resolution. `n`nDo you want to disable Large UI fonts?
       IfMsgBox, Yes
         ToggleLargeFonts()
    }
}

SwitchPreferences(forceReopenSame:=0) {
    testPrefWind := (forceReopenSame=1) ? "lol" : CurrentPrefWindow
    GuiControlGet, CurrentPrefWindow
    If (testPrefWind=CurrentPrefWindow)
       Return

    PrefOpen := 0
    GuiControlGet, ApplySettingsBTN, Enabled
    Gui, Submit
    Gui, SettingsGUIA: Destroy
    Sleep, 25
    SettingsGUI()
    CheckSettings()
    If (CurrentPrefWindow=5)
    {
       ShowSettings()
       VerifyTheOptions(ApplySettingsBTN)
    }
}

ApplySettings() {
    Gui, SettingsGUIA: Submit, NoHide
    CheckSettings()
    PrefOpen := 0
    INIsettings(1)
    Sleep, 100
    ReloadScript()
}

CloseWindow() {
    AnyWindowOpen := 0
    If (tickTockNoise!=1)
       SoundLoop("")

    Gui, SettingsGUIA: Destroy
}

CloseSettings() {
   GuiControlGet, ApplySettingsBTN, Enabled
   PrefOpen := 0
   analogClockThread.ahkassign("PrefOpen", PrefOpen)
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
    If (CtrlHwnd && IsRightClick=1)
    || ((A_TickCount-lastInvoked>250) && IsRightClick=0)
    {
       lastInvoked := A_TickCount
       Return
    }
    Menu, ContextMenu, UseErrorLevel
    Menu, ContextMenu, Delete
    Sleep, 25
    Menu, ContextMenu, Add, L&arge UI fonts, ToggleLargeFonts
    Menu, ContextMenu, Add, 
    If (PrefsLargeFonts=1)
       Menu, ContextMenu, Check, L&arge UI fonts

    If (PrefOpen=0)
       Menu, ContextMenu, Add, &Settings, ShowSettings
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, &Restart %appName%, ReloadScriptNow
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Close menu, dummy
    Menu, ContextMenu, Show
    lastInvoked := A_TickCount
    Return
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
  GuiControl, Enable, ApplySettingsBTN
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
          analogClockThread.ahkPostFunction["hideClock"]
       DestroyBibleGui()
       Return
    }

    If (analogDisplay=0 || ShowPreviewDate=1)
    {
       If (ClockVisibility=1)
          analogClockThread.ahkPostFunction["hideClock"]
       CreateBibleGUI(generateDateTimeTxt(1, !ShowPreviewDate))
    } Else If (A_TickCount - lastInvoked > 200) && (PrefOpen=1)
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
   analogClockThread.ahkFunction["hideClock"]
   Sleep, 2
   analogClockThread.ahkFunction["OnHEXit"]
   Sleep, 2
   analogClockThread.ahkFunction["InitClockFace"]
   DestroyBibleGui()
   Sleep, 2
   analogClockThread.ahkFunction["showClock"]
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

    If (noDate=1)
       txtReturn := CurrentTime timeSuffix
    Else
       txtReturn := CurrentTime timeSuffix " | " CurrentDate
    Return txtReturn
}

editsOSDwin() {
  If (A_TickCount-DoNotRepeatTimer<1000)
     Return
  VerifyTheOptions()
}

checkBoxStrikeQuarter() {
  GuiControlGet, tollQuarters
  stopStrikesNow := 0
  VerifyTheOptions()
  If (tollQuarters=1)
     strikeQuarters()
}

checkBoxStrikeHours() {
  GuiControlGet, tollHours
  stopStrikesNow := 0
  VerifyTheOptions()
  If (tollHours=1)
     strikeHours()
}

checkBoxStrikeAdditional() {
  GuiControlGet, AdditionalStrikes
  stopStrikesNow := 0
  VerifyTheOptions()
  If (AdditionalStrikes=1)
     SoundPlay, sounds\auxilliary-bell.mp3
}

ShowSettings() {
    doNotOpen := initSettingsWindow()
    If (doNotOpen=1)
       Return

    Global CurrentPrefWindow := 5
    Global DoNotRepeatTimer := A_TickCount
    Global editF1, editF2, editF3, editF4, editF5, editF6, Btn1, volLevel, editF40, editF60, editF73, Btn2, txt4, Btn3, editF99, txt100
         , editF7, editF8, editF9, editF10, editF11, editF13, editF35, editF36, editF37, editF38, txt1, txt2, txt3, txt10, Btn4
    columnBpos1 := columnBpos2 := 160
    editFieldWid := 220
    btnWid := 90

    analogClockThread.ahkassign("PrefOpen", PrefOpen)
    If (PrefsLargeFonts=1)
    {
       Gui, Font, s%LargeUIfontValue%
       btnWid := btnWid + 45
       editFieldWid := editFieldWid + 65
       columnBpos1 := columnBpos2 := columnBpos2 + 90
    }
    columnBpos1b := columnBpos1 + 20

    Gui, Add, Tab3, -Background +hwndhTabs, Bells|Extras|Restrictions|OSD options

    Gui, Tab, 1 ; general
    Gui, Add, Text, x+15 y+15 Section +0x200 vvolLevel, % "Audio volume: " BeepsVolume " % "
    Gui, Add, Slider, x+5 hp ToolTip NoTicks gVolSlider w200 vBeepsVolume Range0-99, %BeepsVolume%
    Gui, Add, Checkbox, gVerifyTheOptions xs y+7 Checked%DynamicVolume% vDynamicVolume, Dynamic volume (adjusted relative to the master volume)
    Gui, Add, Checkbox, xs y+10 gVerifyTheOptions Checked%AutoUnmute% vAutoUnmute, Automatically unmute master volume [when required]
    Gui, Add, Checkbox, y+20 gVerifyTheOptions Checked%tollNoon% vtollNoon, Toll distinctively every six hours [eg., noon, midnight]
    Gui, Add, Checkbox, y+10 gcheckBoxStrikeQuarter Checked%tollQuarters% vtollQuarters, Strike quarter-hours
    Gui, Add, Checkbox, x+10 gVerifyTheOptions Checked%tollQuartersException% vtollQuartersException, ... except on the hour
    Gui, Add, Checkbox, xs y+10 gcheckBoxStrikeHours Checked%tollHours% vtollHours, Strike on the hour
    Gui, Add, Checkbox, x+10 gVerifyTheOptions Checked%tollHoursAmount% vtollHoursAmount, ... the number of hours
    Gui, Add, Checkbox, xs y+10 gcheckBoxStrikeAdditional Checked%AdditionalStrikes% vAdditionalStrikes, Additional strike every (in minutes)
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF38, %strikeEveryMin%
    Gui, Add, UpDown, gVerifyTheOptions vstrikeEveryMin Range1-720, %strikeEveryMin%
    Gui, Add, Text, xs y+10, Interval between tower strikes (in miliseconds):
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit5 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF37, %strikeInterval%
    Gui, Add, UpDown, gVerifyTheOptions vstrikeInterval Range900-5500, %strikeInterval%

    Gui, Tab, 2 ; extras
    Gui, Add, Checkbox, x+15 y+15 Section gVerifyTheOptions Checked%showBibleQuotes% vshowBibleQuotes, Show a Bible verse every (in hours)
    Gui, Add, Edit, x+10 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF40, %BibleQuotesInterval%
    Gui, Add, UpDown, gVerifyTheOptions vBibleQuotesInterval Range1-12, %BibleQuotesInterval%
    Gui, Add, DropDownList, xs+15 y+7 w270 gVerifyTheOptions AltSubmit Choose%BibleQuotesLang% vBibleQuotesLang, World English Bible (2000)|Français: Louis Segond (1910)|Español: Reina Valera (1909)
    Gui, Add, Text, xs+15 y+10 vTxt10, Font size
    Gui, Add, Edit, x+10 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF73, %FontSizeQuotes%
    Gui, Add, UpDown, gVerifyTheOptions vFontSizeQuotes Range10-200, %FontSizeQuotes%
    Gui, Add, Button, x+10 hp w120 gInvokeBibleQuoteNow vBtn2, Preview verse
    Gui, Add, Text, xs+15 y+10 vTxt4, Maximum line length (in characters)
    Gui, Add, Edit, x+10 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF60, %maxBibleLength%
    Gui, Add, UpDown, vmaxBibleLength gVerifyTheOptions Range20-130, %maxBibleLength%
    Gui, Add, Checkbox, xs+15 y+10 gVerifyTheOptions Checked%makeScreenDark% vmakeScreenDark, Dim the screen when displaying Bible verses
    Gui, Add, Checkbox, y+10 gVerifyTheOptions Checked%noBibleQuoteMhidden% vnoBibleQuoteMhidden, Do not show Bible verses when the mouse cursor is hidden`n(e.g., when watching videos on full-screen)

    Gui, Add, Checkbox, xs y+20 gVerifyTheOptions Checked%ObserveHolidays% vObserveHolidays, Observe Christian and/or secular holidays
    Gui, Add, Checkbox, xs y+7 gVerifyTheOptions Checked%SemantronHoliday% vSemantronHoliday, Mark days of feast by regular semantron drumming
    Gui, Add, Button, xs+15 y+7 h25 gListCelebrationsBtn vBtn3, Manage list of holidays

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

    Gui, Add, DropDownList, xs+%columnBpos2% ys+0 section w205 gVerifyTheOptions Sort Choose1 vFontName, %FontName%
    Gui, Add, ListView, xp+0 yp+30 w55 h25 %CCLVO% Background%OSDtextColor% vOSDtextColor hwndhLV1,
    Gui, Add, ListView, x+5 yp w55 h25 %CCLVO% Background%OSDbgrColor% vOSDbgrColor hwndhLV2,
    Gui, Add, Edit, x+5 yp+0 w55 hp geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF10, %OSDalpha%
    Gui, Add, UpDown, vOSDalpha gVerifyTheOptions Range75-250, %OSDalpha%
    Gui, Add, Edit, xp-120 yp+30 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF5, %FontSize%
    Gui, Add, UpDown, gVerifyTheOptions vFontSize Range12-295, %FontSize%
    Gui, Add, Edit, xp yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF99, %showTimeIdleAfter%
    Gui, Add, UpDown, vshowTimeIdleAfter gVerifyTheOptions Range1-950, %showTimeIdleAfter%
    Gui, Add, Text, x+5 vtxt100, idle after (in min.)
    Gui, Add, Edit,  xs yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF6, %DisplayTimeUser%
    Gui, Add, UpDown, vDisplayTimeUser gVerifyTheOptions Range1-99, %DisplayTimeUser%
    Gui, Add, Checkbox, x+10 hp gVerifyTheOptions Checked%OSDroundCorners% vOSDroundCorners, Round corners
    If !FontList._NewEnum()[k, v]
    {
        Fnt_GetListOfFonts()
        FontList := trimArray(FontList)
    }

    Loop, % FontList.MaxIndex() {
        fontNameInstalled := FontList[A_Index]
        If (fontNameInstalled ~= "i)(@|oem|extb|symbol|marlett|wst_|glyph|reference specialty|system|terminal|mt extra|small fonts|cambria math|this font is not|fixedsys|emoji|hksc| mdl|wingdings|webdings)") || (fontNameInstalled=FontName)
           Continue
        GuiControl, , FontName, %fontNameInstalled%
    }

    Gui, Tab
    Gui, Add, Button, xm+0 y+10 w70 h30 Default gApplySettings vApplySettingsBTN, A&pply
    Gui, Add, Button, x+8 wp hp gCloseSettings, C&ancel
    Gui, Add, Button, x+8 w%btnWid% hp gDeleteSettings, R&estore defaults
    Gui, Show, AutoSize, Customize: %appName%
    verifySettingsWindowSize()
    VerifyTheOptions(0)
    ColorPickerHandles := hLV1 "," hLV2 "," hLV3 "," hLV5 "," hTXT
}

VerifyTheOptions(EnableApply:=1,forceNoPreview:=0) {
    GuiControlGet, ShowPreview
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
    GuiControlGet, analogDisplay
    GuiControlGet, showTimeIdleAfter
    GuiControlGet, showTimeWhenIdle

    GuiControl, % (EnableApply=0 ? "Disable" : "Enable"), ApplySettingsBTN
    GuiControl, % (AdditionalStrikes=0 ? "Disable" : "Enable"), editF38
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF40
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF60
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF73
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Btn2
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Txt4
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), makeScreenDark
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), BibleQuotesLang
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), noBibleQuoteMhidden
    GuiControl, % (displayClock=0 ? "Disable" : "Enable"), analogDisplay
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursA
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursB
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF35
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF36
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt1
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt2
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt3
    GuiControl, % (tollHours=0 ? "Disable" : "Enable"), tollHoursAmount
    GuiControl, % (tollQuarters=0 ? "Disable" : "Enable"), tollQuartersException
    GuiControl, % (ShowPreview=0 ? "Disable" : "Enable"), ShowPreviewDate
    GuiControl, % ((ObserveHolidays=0 && SemantronHoliday=0) ? "Disable" : "Enable"), btn3

    roundCornerSize := Round(FontSize/2) + Round(OSDmarginSides/5)
    If (roundCornerSize<20)
       roundCornerSize := 20

    Static LastInvoked := 1
    If (forceNoPreview=1)
       Return

    If !isAnalogClockFile
    {
       analogDisplay := 0
       GuiControl, % (isAnalogClockFile!=1 ? "Disable" : "Enable"), analogDisplay
    }

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

ScreenBlocker(killNow:=0, darkner:=0) {
    Static
    If (killNow=1) || (darkner=1 && makeScreenDark=0)
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

calcEasterDate() {
  If (UserReligion=1)
     result := CatholicEaster(celebYear)
  Else
     result := OrthodoxEaster(celebYear)

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
  {
     isHolidayToday := (UserReligion=1) ? "Catholic Easter" : "Orthodox Easter"
     isHolidayToday .= " - the resurrection of Jesus"
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

ashwednesday() {
  result := calcEasterDate()
  EnvAdd, result, -46, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay && UserReligion=1)
     isHolidayToday := "Ash Wednesday - first day of Lent; a reminder we were made from dust and we will return to dust"

  return result
}

palmSunday() {
  result := calcEasterDate()
  EnvAdd, result, -7, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
     isHolidayToday := "Flowery/Palm Sunday - Jesus' triumphal entry into Jerusalem"

  return result
}

goodFriday() {
  result := calcEasterDate()
  EnvAdd, result, -2, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
  {
     isHolidayToday := (UserReligion=1) ? "Good Friday" : "The Great and Holy Friday"
     isHolidayToday .= " - the crucifixion of Jesus and His death"
  }

  return result
}

MaundyT() {
  result := calcEasterDate()
  EnvAdd, result, -3, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
     isHolidayToday := "Maundy Thursday - the foot washing and Last Supper of Jesus Christ"

  return result
}

HolySaturday() {
  result := calcEasterDate()
  EnvAdd, result, -1, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
     isHolidayToday := "Holy Saturday - the day that Jesus' body lay in the tomb"

  return result
}

SecondDayEaster() {
  result := calcEasterDate()
  EnvAdd, result, 1, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
     isHolidayToday := (UserReligion=1) ? "Catholic Easter - 2nd day" : "Orthodox Easter - 2nd day"

  return result
}

DivineMercy() {
  result := calcEasterDate()
  EnvAdd, result, 7, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay && UserReligion=1)
     isHolidayToday := "Divine Mercy Sunday - related to His Merciful Divinity and Faustina Kowalska, a Polish Catholic nun"

  return result
}

ascensionday() {
  result := calcEasterDate()
  EnvAdd, result, 39, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
     isHolidayToday := "Ascension of Jesus"

  return result
}

pentecost() {
  result := calcEasterDate()
  EnvAdd, result, 49, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
     isHolidayToday := "Pentecost - the descent of the Holy Spirit upon the Apostles"

  return result
}

holyTrinityOrthdox() {
  result := calcEasterDate()
  EnvAdd, result, 50, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay && UserReligion=2)
     isHolidayToday := "The Holy Trinity - celebrates the Christian doctrine of the Trinity, the three Persons of God: the Father, the Son, and the Holy Spirit"

  return result
}

TrinitySunday() {
  result := calcEasterDate()
  EnvAdd, result, 56, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay)
     isHolidayToday := (UserReligion=1) ? "Holy Trinity Sunday -  celebrates the Christian doctrine of the Trinity, the three Persons of God: the Father, the Son, and the Holy Spirit" : "All saints day"

  return result
}

corpuschristi() {
  result := calcEasterDate()
  EnvAdd, result, 60, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay && UserReligion=1)
     isHolidayToday := "Corpus Cristi - the real presence of the body and blood of Jesus"

  return result
}

lifeGivingSpring() {
  result := calcEasterDate()
  EnvAdd, result, 5, days

  FormatTime, lola, %result%, yday
  If (lola=A_YDay && UserReligion=2)
     isHolidayToday := "The Life-Giving Spring - when Blessed Mary healed a blind man by having him drink water from a spring"

  return result
}

testCelebrations() {
  Critical, On
  testEquiSols()
  If (ObserveHolidays=0 && SemantronHoliday=0)
     Return

  TypeHolidayOccured := isHolidayToday := 0
  testFeast := A_Mon "." A_MDay
  If (ObserveReligiousDays=1)
  {
     calcEasterDate()
     SecondDayEaster()
     DivineMercy()
     palmSunday()
     MaundyT()
     HolySaturday()
     goodFriday()
     ashwednesday()
     ascensionday()
     pentecost()
     TrinitySunday()
     corpuschristi()
     lifeGivingSpring()
     holyTrinityOrthdox()

     If (testFeast="01.06")
        q := (UserReligion=1) ? "Epiphany - the revelation of God incarnate as Jesus Christ" : "Theophany - the baptism of Jesus in the Jordan River"
     Else If (testFeast="01.07" && UserReligion=2)
        q := "The Synaxis of Saint John the Baptist - a Jewish itinerant preacher, and a prophet"
     Else If (testFeast="01.30" && UserReligion=2)
        q := "The Three Holy Hierarchs - Basil the Great, John Chrysostom and Gregory the Theologian"
     Else If (testFeast="02.02")
        q := "The Presentation of Lord Jesus - at the Temple in Jerusalem to induct Him into Judaism, episode described in the 2nd chapter of the Gospel of Luke"
     Else If (testFeast="03.25" && !isHolidayToday)
        q := "The Annunciation of the Lord - when the Blessed Virgin Mary was told she would conceive and become the mother of Jesus of Nazareth"
     Else If (testFeast="04.23" && !isHolidayToday)
        q := "Saint George - a Roman soldier of Greek origin under the Roman emperor Diocletian, sentenced to death for refusing to recant his Christian faith, venerated as a military saint since the Crusades."
     Else If (testFeast="06.24")
        q := "Birth of John the Baptist - a Jewish itinerant preacher, and a prophet known for having anticipated a messianic figure greater than himself"
     Else If (testFeast="08.06")
        isHolidayToday := "The Feast of the Transfiguration of Jesus - when He becomes radiant in glory upon a mountain"
     Else If (testFeast="08.15")
        q := (UserReligion=1) ? "Assumption of Virgin Mary - her body and soul assumed into heavenly glory after her death" : "Falling Asleep of the Blessed Virgin Mary"
     Else If (testFeast="08.29")
        q := "The Beheading of Saint John the Baptist - killed on the orders of Herod Antipas through the vengeful request of his step-daughter Salomé and her mother Herodias"
     Else If (testFeast="09.08")
        q := "The Birth of the Virgin Mary - according to an apocryphal writing, her parents are known as Saint Anne and Saint Joachim"
     Else If (testFeast="09.14")
        q := "The Exaltation of the Holy Cross - the recovery of the cross on which Jesus Christ was crucified by the Roman government on the order of Pontius Pilate"
     Else If (testFeast="10.04" && UserReligion=1)
        q := "Saint Francis of Assisi - an Italian friar, deacon, preacher and founder of different orders within the Catholic church who lived between 1182 and 1226"
     Else If (testFeast="10.14" && UserReligion=2)
        q := "Saint Paraskeva of the Balkans - an ascetic female saint of the 10th century of half Serbian and half Greek origins"
     Else If (testFeast="10.31" && UserReligion=1)
        q := "All Hallows' Eve - the eve of the Solemnity of All Saints"
     Else If (testFeast="11.01" && UserReligion=1)
        q := "All saints' day- a commemoration day for all Christian saints"
     Else If (testFeast="11.02" && UserReligion=1)
        q := "All souls' day - a commemoration day of all the faithful departed"
     Else If (testFeast="11.21")
        q := "The Presentation of the Blessed Virgin Mary - when she was brought, as a child, to the Temple in Jerusalem to be consecrated to God"
     Else If (testFeast="12.06")
        q := "Saint Nicholas' Day - an early Christian bishop of Greek origins from 270 - 342 AD, known as the bringer of gifts for the poor"
     Else If (testFeast="12.08" && UserReligion=1)
        q := "The Solemnity of Immaculate Conception of the Virgin Mary"
     Else If (testFeast="12.24")
        q := "Christmas Eve"
     Else If (testFeast="12.25")
        q := "Christmas day - the birth of Jesus Christ in Nazareth"
     Else If (testFeast="12.26")
        q := "Christmas 2nd day - the birth of Jesus Christ also known as Jesus of Nazareth"
     Else If (testFeast="12.28" && UserReligion=1)
        q := "Feast of the Holy Innocents - in remembrance of the young children killed in Bethlehem by King Herod the Great in his attempt to kill the infant Jesus of Nazareth"
     isHolidayToday := q ? q : isHolidayToday
     If (StrLen(isHolidayToday)>2)
        TypeHolidayOccured := 1
  }

  If (ObserveSecularDays=1)
  {
     theList := "New Year's Day - Happy New Year!|01.01`n"
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
        If (miniDate=testFeast && (PreferSecularDays=1 || !isHolidayToday))
        {
           TypeHolidayOccured := 2
           isHolidayToday := lineArr[1]
           Break
        }
     }
  }

  PersonalDay := INIactionNonGlobal(0, testFeast, 0, "Celebrations")
  If InStr(PersonalDay, "default disabled")
  {
     isHolidayToday := PersonalDay := TypeHolidayOccured := 0
  } Else If (StrLen(PersonalDay)>2)
  {
     isHolidayToday := PersonalDay
     TypeHolidayOccured := 3
  }

  OSDprefix := ""
  If (StrLen(isHolidayToday)>2 && ObserveHolidays=1)
  {
     OSDprefix := (StrLen(PersonalDay)>2) ? "▦ " : "✝ "
     If (TypeHolidayOccured=2) ; secular
        OSDprefix := "▣ "
     If (AnyWindowOpen!=1)
     {
        Gui, ShareBtnGui: Destroy
        CreateBibleGUI(generateDateTimeTxt() " || " isHolidayToday, 1, 1)
        Gui, ShareBtnGui: Destroy
        quoteDisplayTime := StrLen(isHolidayToday) * 140
        If InStr(isHolidayToday, "Christmas")
           sndChanQ := AhkThread("#NoTrayIcon`nSoundPlay, sounds\christmas.mp3, 1")
        Else
           strikeJapanBell()
        Sleep, 1000
        SetTimer, DestroyBibleGui, % -quoteDisplayTime
     }
  }
}

ListCelebrationsBtn() {
  celebYear := A_Year
  VerifyTheOptions()
  ListCelebrations()
}

ListCelebrations(tabChoice:=1) {

  Global LViewEaster, LViewOthers, LViewSecular, LViewPersonal, CurrentTabLV, ResetYearBTN
  Gui, CelebrationsGuia: Destroy
  Sleep, 15
  Gui, CelebrationsGuia: Default
  Gui, CelebrationsGuia: -MaximizeBox -MinimizeBox
  Gui, CelebrationsGuia: Margin, 15, 15
  relName := (UserReligion=1) ? "Catholic" : "Orthodox"
  lstWid := 435
  If (PrefsLargeFonts=1)
  {
     lstWid := lstWid + 245
     Gui, Font, s%LargeUIfontValue%
  }

  Gui, Add, Checkbox, x15 y10 gupdateOptionsLVsGui Checked%ObserveReligiousDays% vObserveReligiousDays, Observe religious feasts / holidays
  Gui, Add, DropDownList, x+2 w100 gupdateOptionsLVsGui AltSubmit Choose%UserReligion% vUserReligion, Catholic|Orthodox
  btnWid := (PrefsLargeFonts=1) ? 70 : 50
  lstWid2 := lstWid - btnWid
  Gui, Add, Button, xs+%lstWid2% yp+0 gaddNewEntryWindow w%btnWid% h30, &Add
  Gui, Add, Tab3, xs+0 y+0 AltSubmit Choose%tabChoice% vCurrentTabLV, Christian|Easter related|Secular|Personal

  Gui, Tab, 1
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r7 Grid NoSort -Hdr vLViewOthers, Index|Date|Detailz
  Gui, Tab, 2
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r7 Grid NoSort -Hdr vLViewEaster, Index|Date|Detailz
  Gui, Tab, 3
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r7 Grid NoSort -Hdr vLViewSecular, Index|Date|Detailz
  Gui, Tab, 4
  Gui, Add, ListView, y+10 w%lstWid% gActionListViewKBDs r7 Grid NoSort -Hdr vLViewPersonal, Index|Date|Detailz

  Gui, Tab
  Gui, Add, Checkbox, y+15 Section gupdateOptionsLVsGui Checked%ObserveSecularDays% vObserveSecularDays, Observe secular holidays
  Gui, Add, Checkbox, x+5 gupdateOptionsLVsGui Checked%PreferSecularDays% vPreferSecularDays, Prefer these holidays over religious ones

  btnWid := (PrefsLargeFonts=1) ? 145 : 90
  Gui, Add, Button, xs y+15 w%btnWid% h25 gPrevYearList , &Previous year
  Gui, Add, Button, x+1 w55 hp gResetYearList vResetYearBTN, %celebYear%
  Gui, Add, Button, x+1 w%btnWid% hp gNextYearList , &Next year
  Gui, Add, Button, x+20 w%btnWid% hp gCloseCelebListWin, &Close list
  Gui, Show, AutoSize, Celebrations list: %appName%
  updateOptionsLVsGui()
  SetTimer, AutoDestroyCelebList, 200
}

updateOptionsLVsGui() {
  GuiControlGet, ObserveSecularDays
  GuiControlGet, ObserveReligiousDays
  GuiControlGet, PreferSecularDays
  GuiControlGet, UserReligion

  GuiControl, % ((ObserveReligiousDays=0) ? "Disable" : "Enable"), UserReligion
  GuiControl, % ((ObserveSecularDays=0) ? "Disable" : "Enable"), PreferSecularDays
  updateHolidaysLVs()
}

updateHolidaysLVs() {

  Gui, CelebrationsGuia:ListView, LViewEaster
  LV_Delete()
  Gui, CelebrationsGuia:ListView, LViewOthers
  LV_Delete()
  Gui, CelebrationsGuia:ListView, LViewSecular
  LV_Delete()
  Gui, CelebrationsGuia:ListView, LViewPersonal
  LV_Delete()
  easterdate := calcEasterDate()
  2ndeasterdate := SecondDayEaster()
  divineMercyDate := DivineMercy()
  palmdaydate := palmSunday()
  maundydate := MaundyT()
  HolySaturdaydate := HolySaturday()
  goodFridaydate := goodFriday()
  ashwednesdaydate := ashwednesday()
  ascensiondaydate := ascensionday()
  pentecostdate := pentecost()
  TrinitySundaydate := TrinitySunday()
  corpuschristidate := corpuschristi()
  lifeSpringDate := lifeGivingSpring()
  holyTrinityOrthdoxDate := holyTrinityOrthdox()

  Epiphany := "01.06"
  SynaxisSaintJohnBaptist := "01.07"
  ThreeHolyHierarchs := "01.30"
  PresentationLord := "02.02"
  AnnunciationLord := "03.25"
  SaintGeorge := "04.23"
  BirthJohnBaptist := "06.24"
  FeastTransfiguration := "08.06"
  AssumptionVirginMary := "08.15"
  BeheadingJohnBaptist := "08.29"
  BirthVirginMary := "09.08"
  ExaltationHolyCross := "09.14"
  SaintFrancisAssisi := "10.04"
  SaintParaskeva := "10.14"
  HalloweenDay := "10.31"
  Allsaintsday := "11.01"
  Allsoulsday := "11.02"
  PresentationVirginMary := "11.21"
  ImmaculateConception := "12.08"
  SaintNicola := "12.06"
  ChristmasEve := "12.24"
  Christmasday := "12.25"
  Christmas2nday := "12.26"
  FeastHolyInnocents := "12.28"

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

     theList2 := "Epiphany|" Epiphany "`n"
        . "The Presentation of Lord Jesus|" PresentationLord "`n"
        . "The Annunciation of the Virgin Mary|" AnnunciationLord "`n"
        . "Saint George|" SaintGeorge "`n"
        . "Birth of John the Baptist|" BirthJohnBaptist "`n"
        . "Feast of Transfiguration|" FeastTransfiguration "`n"
        . "Assumption of Virgin Mary|" AssumptionVirginMary "`n"
        . "The Beheading of Saint John the Baptist|" BeheadingJohnBaptist "`n"
        . "Birth of Virgin Mary|" BirthVirginMary "`n"
        . "The Exaltation of the Holy Cross|" ExaltationHolyCross "`n"
        . "Saint Francis of Assisi|" SaintFrancisAssisi "`n"
        . "All Hallows' Eve [Hallowe'en]|" HalloweenDay "`n"
        . "All saints day|" Allsaintsday "`n"
        . "All souls' day|" Allsoulsday "`n"
        . "The Presentation of the Virgin Mary|" PresentationVirginMary "`n"
        . "The Solemnity of Immaculate Conception|" ImmaculateConception "`n"
        . "Saint Nicholas Day|" SaintNicola "`n"
        . "Christmas Eve|" ChristmasEve "`n"
        . "Christmas|" Christmasday "`n"
        . "Christmas - 2nd day|" Christmas2nday "`n"
        . "Feast of the Holy Innocents|" FeastHolyInnocents

     Gui, ListView, LViewOthers
     processHolidaysList(theList2)
  } Else If (UserReligion=2 && ObserveReligiousDays=1)
  {
     theList := "Flowery Sunday|" palmdaydate "`n"
        . "Maundy Thursday|" maundydate "`n"
        . "Holy Friday|" goodFridaydate "`n"
        . "Holy Saturday|" HolySaturdaydate "`n"
        . "Orthodox Easter|" easterdate "`n"
        . "Orthodox Easter - 2nd day|" 2ndeasterdate "`n"
        . "Life-Giving Spring|" lifeSpringDate "`n"
        . "Ascension of Jesus|" ascensiondaydate "`n"
        . "Pentecost|" pentecostdate "`n"
        . "Holy Trinity|" holyTrinityOrthdoxDate "`n"
        . "All saints day|" TrinitySundaydate

     Gui, ListView, LViewEaster
     processHolidaysList(theList)

     theList2 := "Theophany|" Epiphany "`n"
        . "The Synaxis of Saint John the Baptist|" SynaxisSaintJohnBaptist "`n"
        . "The Three Holy Hierarchs|" ThreeHolyHierarchs "`n"
        . "The Presentation of Lord Jesus|" PresentationLord "`n"
        . "The Annunciation of the Virgin Mary|" AnnunciationLord "`n"
        . "Saint George|" SaintGeorge "`n"
        . "Birth of John the Baptist|" BirthJohnBaptist "`n"
        . "Feast of Transfiguration|" FeastTransfiguration "`n"
        . "Falling Asleep of Virgin Mary|" AssumptionVirginMary "`n"
        . "The Beheading of Saint John the Baptist|" BeheadingJohnBaptist "`n"
        . "Birth of Virgin Mary|" BirthVirginMary "`n"
        . "The Exaltation of the Holy Cross|" ExaltationHolyCross "`n"
        . "Saint Paraskeva of the Balkans|" SaintParaskeva "`n"
        . "The Presentation of the Virgin Mary|" PresentationVirginMary "`n"
        . "Saint Nicholas Day|" SaintNicola "`n"
        . "Christmas Eve|" ChristmasEve "`n"
        . "Christmas|" Christmasday "`n"
        . "Christmas - 2nd day|" Christmas2nday

     Gui, ListView, LViewOthers
     processHolidaysList(theList2)
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
     theListS := "New Year's Day|01.01`n"
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
       . "Elimination of Violence against Women|11.25`n"
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

addNewEntryWindow() {

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
  Gui, Add, Text, x15 y10 Section, Please enter the day month, and event name.
  Gui, Add, DropDownList, y+10 Choose%A_MDay% w%drpWid% vnewDay, 01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31
  Gui, Add, DropDownList, x+5 Choose%A_Mon% w%drpWid2% vnewMonth, 01 January|02 February|03 March|04 April|05 May|06 June|07 July|08 August|09 September|10 October|11 November|12 December
  Gui, Add, Edit, xs y+7 w400 r1 limit90 -multi -wantReturn -wantTab -wrap vnewEvent, 
  Gui, Add, Button, xs y+15 w%btnWid% h25 Default gSaveNewEntryBtn , &Add entry
  Gui, Add, Button, x+5 w%btnWid% hp gCancelNewEntryBtn, &Cancel
  Gui, Show, AutoSize, Add new celebration: %appName%
  SetTimer, AutoDestroyCelebList, 200
}

SaveNewEntryBtn() {
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
     ListCelebrations(4)
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
  If (CurrWin=hSetWinGui)
     CloseCelebListWin()
}

CloseCelebListWin() {
   celebYear := A_Year
   SetTimer, AutoDestroyCelebList, Off
   Gui, CelebrationsGuia: Destroy
   Sleep, 50
   WinActivate, ahk_id %hSetWinGui%
}

CancelNewEntryBtn() {
   celebYear := A_Year
   WinActivate, ahk_id %hSetWinGui%
   Sleep, 50
   ListCelebrations(4)
}

compareYearDays(givenDay, CurrentDay) {
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
      If (passedDays<=2)
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
     If (DaysUntil<=2)
        Result := "now"
  }
  If (Floor(Weeksz)>=4)
     Result := "hide"

  Return Result
}

testEquiSols() {
  OSDsuffix := ""

  MarchEquinox := compareYearDays(78, A_YDay)
  If InStr(MarchEquinox, "now")
     OSDsuffix := " ▀"

  JuneSols := compareYearDays(170, A_YDay)
  If InStr(JuneSols, "now")
     OSDsuffix := " ⬤"

  SepEquinox := compareYearDays(263, A_YDay)
  If InStr(SepEquinox, "now")
     OSDsuffix := " ▃"

  DecSols := compareYearDays(354, A_YDay)
  If InStr(DecSols, "now")
     OSDsuffix := " ◯"

  testFeast := A_Mon "." A_MDay
  If (testFeast="02.29")
     OSDsuffix := " ▒"
}

AboutWindow() {
    If (PrefOpen=1)
    {
       SoundBeep, 300, 900
       Return
    }

    If (AnyWindowOpen=1)
    {
       CloseWindow()
       Return
    }

    SettingsGUI(1)
    AnyWindowOpen := 1
    btnWid := 100
    txtWid := 360
    Global btn1
    Gui, Font, c%AboutTitleColor% s20 Bold, Arial, -wrap
    Gui, Add, Picture, x15 y15 w55 h-1 +0x3 Section gTollExtraNoon hwndhBellIcon, bell-image.png
    Gui, Add, Text, x+7 y10, %appName%
    Gui, Font, c%GUIAtxtColor% s12 Bold, Arial, -wrap
    Gui, Add, Link, y+4 hwndhLink0, Developed by <a href="http://marius.sucan.ro">Marius Şucan</a>.
    Gui, Font
    Gui, Font, c%GUIAtxtColor%
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
       Gui, Font, s%LargeUIfontValue%
    }

    If (tickTockNoise!=1)
       SoundLoop(tickTockSound)

    testCelebrations()
    MarchEquinox := compareYearDays(78, A_YDay) "March equinox."   ; 03 / 20
    If InStr(MarchEquinox, "now")
       MarchEquinox := "(" OSDsuffix " ) The March equinox is here now."
    JuneSolstice := compareYearDays(170, A_YDay) "June solstice. The day and night are tightly balanced for a few days."  ; 06 / 21
    If InStr(JuneSolstice, "now")
       JuneSolstice := "(" OSDsuffix " ) The June solstice is here now. Today is one of the longest days of the year."
    SepEquinox := compareYearDays(263, A_YDay) "September equinox."  ; 09 / 22
    If InStr(SepEquinox, "now")
       SepEquinox := "(" OSDsuffix " ) The September equinox is here now. The day and night are tightly balanced for a few days."
    DecSolstice := compareYearDays(354, A_YDay) "December solstice."  ; 12 / 21
    If InStr(DecSolstice, "now")
       DecSolstice := "(" OSDsuffix " ) The December solstice is here now. Today is one of the shortest days of the year."

    percentileYear := Round(A_YDay/366*100) "%"
    FormatTime, CurrentYear,, yyyy
    NextYear := CurrentYear + 1

    FormatTime, CurrentDateTime,, yyyyMMddHHmm
    FormatTime, CurrentDay,, yyyyMMdd
    FirstMinOfDay := CurrentDay "0001"
    EnvSub, CurrentDateTime, %FirstMinOfDay%, Minutes
    minsPassed := CurrentDateTime + 1
    percentileDay := Round(minsPassed/1450*100) "%"

    Gui, Add, Text, x15 y+10 w%txtWid% Section, Dedicated to Christians, church-goers and bell lovers.
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
       PersonalDate := celebYear 0229010101
       FormatTime, PersonalDate, %PersonalDate%, LongDate
       If (StrLen(PersonalDate)>3)
          Gui, Add, Text, y+7 w%txtWid%, %celebYear% is a leap year.
    } Else If (testFeast="02.29")
       Gui, Add, Text, y+7 w%txtWid%, Today is 29th of February - a leap year day.

    Gui, Font, Normal
    If (A_YDay>172 && A_YDay<352)
       Gui, Add, Text, y+7, The days are getting shorter until the winter solstice, in December.
    Else If (A_YDay>356 || A_YDay<167)
       Gui, Add, Text, y+7, The days are getting longer until the summer solstice, in June.
    If (A_OSVersion="WIN_XP")
    {
       Gui, Font,, Arial ; only as backup, doesn't have all characters on XP
       Gui, Font,, Symbola
       Gui, Font,, Segoe UI Symbol
       Gui, Font,, DejaVu Sans
       Gui, Font,, DejaVu LGC Sans
    }

    Gui, Add, Text, xp+30 y+15 Section, % CurrentYear " {" CalcTextHorizPrev(A_YDay, 366) "} " NextYear
    Gui, Add, Text, xp+15 y+5, %weeksPassed% %weeksPlural% (%percentileYear%) of %CurrentYear% %weeksPlural2% elapsed.
    Gui, Add, Text, xs y+10, % "0h {" CalcTextHorizPrev(minsPassed, 1440, 0, 22) "} 24h "
    Gui, Add, Text, xp+15 y+5, %minsPassed% minutes (%percentileDay%) of today have elapsed.
    If (A_OSVersion="WIN_XP")
    {
       Gui, Font,
       If (PrefsLargeFonts=1)
          Gui, Font, s%LargeUIfontValue% c%GUIAtxtColor%
    }
    newLine := (PrefsLargeFonts=1) ? " " : "`n"
    Gui, Add, Text, xs-30 y+15 Section w%txtWid%, This application contains code and sounds from various entities.%newLine%You can find more details in the source code.
    If (storeSettingsREG=1)
       Gui, Add, Link, xs y+10 w%txtWid% hwndhLink2, This application was downloaded through <a href="ms-windows-store://pdp/?productid=9PFQBHN18H4K">Windows Store</a>.
    Else      
       Gui, Add, Link, xs y+10 w%txtWid% hwndhLink2, The development page is <a href="https://github.com/marius-sucan/ChurchBellsTower">on GitHub</a>.
    Gui, Font, Bold
    Gui, Add, Link, xp+30 y+10 hwndhLink1, To keep the development going, `n<a href="https://www.paypal.me/MariusSucan/15">please donate</a> or <a href="mailto:marius.sucan@gmail.com?subject=%appName% v%Version%">send me feedback</a>.
    Gui, Add, Picture, x+10 yp+0 gDonateNow hp w-1 +0xE hwndhDonateBTN, paypal.png

    Gui, Font, Normal
    Gui, Add, Button, xs+0 y+20 h30 w105 Default gCloseWindowAbout hwndhBtn1, Deus lux est
    Gui, Add, Button, x+5 hp w80 gShowSettings hwndhBtn2, Settings
    Gui, Add, Text, x+8 hp +0x200 gOpenChangeLog hwndhBtnLog, v%Version% (%ReleaseDate%)
    Gui, Show, AutoSize, About %appName% v%Version%
    ColorPickerHandles := hDonateBTN "," hBellIcon "," hBtnLog
    Sleep, 25

    Opt1 := [0, "0xff" AboutTitleColor, , "0xff" BtnTxtColor, 15, "0x" GUIAbgrColor, , 0]
    Opt2 := [ , "0xef" hoverBtnColor]
    Opt3 := [ , "0xff" BtnTxtColor, , "0xff" hoverBtnColor]
    ImageButton.Create(hBtn1, Opt1, Opt2, Opt3)
    ImageButton.Create(hBtn2, Opt1, Opt2, Opt3)
    LinkUseDefaultColor(hLink0)
    LinkUseDefaultColor(hLink1)
    LinkUseDefaultColor(hLink2)
    verifySettingsWindowSize()
    If InStr(isHolidayToday, "Christmas") && (stopAdditionalStrikes=0)
       sndChanQ := AhkThread("#NoTrayIcon`nSoundPlay, sounds\christmas.mp3, 1")
}

CloseWindowAbout() {
    ToolTip, :-)
    SetTimer, CloseWindow, -250
    SetTimer, removeTooltip, -600
}

removeTooltip() {
  ToolTip
}

LinkUseDefaultColor(hLink, Use := True) {
   VarSetCapacity(LITEM, 4278, 0)            ; 16 + (MAX_LINKID_TEXT * 2) + (L_MAX_URL_LENGTH * 2)
   NumPut(0x03, LITEM, "UInt")               ; LIF_ITEMINDEX (0x01) | LIF_STATE (0x02)
   NumPut(Use ? 0x10 : 0, LITEM, 8, "UInt")  ; ? LIS_DEFAULTCOLORS : 0
   NumPut(0x10, LITEM, 12, "UInt")           ; LIS_DEFAULTCOLORS
   While DllCall("SendMessage", "Ptr", hLink, "UInt", 0x0702, "Ptr", 0, "Ptr", &LITEM, "UInt") ; LM_SETITEM
      NumPut(A_Index, LITEM, 4, "Int")
   GuiControl, SettingsGUIA: +Redraw, %hLink%
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
        IniWrite, %varValue%, %IniFile%, %section%, %var%
     Else
        IniRead, %var%, %IniFile%, %section%, %var%, %varValue%
  } Else
  {
     If (act=1)
        RegWrite, REG_SZ, %APPregEntry%, %var%, %varValue%
     Else
        RegRead, %var%, %APPregEntry%, %var%
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
  }
  INIaction(a, "PrefsLargeFonts", "SavedSettings")
  INIaction(a, "LargeUIfontValue", "SavedSettings")
  INIaction(a, "tollQuarters", "SavedSettings")
  INIaction(a, "tollQuartersException", "SavedSettings")
  INIaction(a, "tollNoon", "SavedSettings")
  INIaction(a, "tollHours", "SavedSettings")
  INIaction(a, "tollHoursAmount", "SavedSettings")
  INIaction(a, "displayClock", "SavedSettings")
  INIaction(a, "silentHours", "SavedSettings")
  INIaction(a, "silentHoursA", "SavedSettings")
  INIaction(a, "silentHoursB", "SavedSettings")
  INIaction(a, "showTimeIdleAfter", "SavedSettings")
  INIaction(a, "showTimeWhenIdle", "SavedSettings")
  INIaction(a, "displayTimeFormat", "SavedSettings")
  INIaction(a, "BeepsVolume", "SavedSettings")
  INIaction(a, "DynamicVolume", "SavedSettings")
  INIaction(a, "AutoUnmute", "SavedSettings")
  INIaction(a, "tickTockNoise", "SavedSettings")
  INIaction(a, "strikeInterval", "SavedSettings")
  INIaction(a, "LastNoon", "SavedSettings")
  INIaction(a, "AdditionalStrikes", "SavedSettings")
  INIaction(a, "strikeEveryMin", "SavedSettings")
  INIaction(a, "QuotesAlreadySeen", "SavedSettings")
  INIaction(a, "showBibleQuotes", "SavedSettings")
  INIaction(a, "BibleQuotesLang", "SavedSettings")
  INIaction(a, "noBibleQuoteMhidden", "SavedSettings")
  INIaction(a, "BibleQuotesInterval", "SavedSettings")
  INIaction(a, "SemantronHoliday", "SavedSettings")
  INIaction(a, "ObserveHolidays", "SavedSettings")
  INIaction(a, "ObserveSecularDays", "SavedSettings")
  INIaction(a, "ObserveReligiousDays", "SavedSettings")
  INIaction(a, "PreferSecularDays", "SavedSettings")
  INIaction(a, "UserReligion", "SavedSettings")
  INIaction(a, "noTollingWhenMhidden", "SavedSettings")
  INIaction(a, "noTollingBgrSounds", "SavedSettings")
  INIaction(a, "NoWelcomePopupInfo", "SavedSettings")

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
  INIaction(a, "OSDalpha", "OSDprefs")
  INIaction(a, "OSDbgrColor", "OSDprefs")
  INIaction(a, "OSDtextColor", "OSDprefs")
  INIaction(a, "OSDmarginTop", "OSDprefs")
  INIaction(a, "OSDmarginBottom", "OSDprefs")
  INIaction(a, "OSDmarginSides", "OSDprefs")
  INIaction(a, "OSDroundCorners", "OSDprefs")
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
    BinaryVar(displayClock, 1)
    BinaryVar(AutoUnmute, 1)
    BinaryVar(tickTockNoise, 0)
    BinaryVar(DynamicVolume, 1)
    BinaryVar(AdditionalStrikes, 0)
    BinaryVar(showBibleQuotes, 0)
    BinaryVar(makeScreenDark, 1)
    BinaryVar(noTollingWhenMhidden, 0)
    BinaryVar(noBibleQuoteMhidden, 1)
    BinaryVar(SemantronHoliday, 0)
    BinaryVar(ObserveHolidays, 0)
    BinaryVar(ObserveReligiousDays, 1)
    BinaryVar(ObserveSecularDays, 1)
    BinaryVar(PreferSecularDays, 0)
    BinaryVar(showTimeWhenIdle, 0)
    BinaryVar(OSDroundCorners, 1)

; verify numeric values: min, max and default values
    If (InStr(analogDisplayScale, "err") || !analogDisplayScale)
       analogDisplayScale := 1
    Else If (analogDisplayScale<0.3)
       analogDisplayScale := 0.25
    Else If (analogDisplayScale>3)
       analogDisplayScale := 3

    MinMaxVar(DisplayTimeUser, 1, 99, 3)
    MinMaxVar(FontSize, 12, 300, 26)
    MinMaxVar(FontSizeQuotes, 10, 201, 20)
    MinMaxVar(GuiX, -9999, 9999, 40)
    MinMaxVar(GuiY, -9999, 9999, 250)
    MinMaxVar(OSDmarginTop, 1, 900, 20)
    MinMaxVar(OSDmarginBottom, 1, 900, 20)
    MinMaxVar(OSDmarginSides, 10, 900, 25)
    MinMaxVar(BeepsVolume, 0, 99, 45)
    MinMaxVar(strikeEveryMin, 1, 720, 5)
    MinMaxVar(silentHours, 1, 3, 1)
    MinMaxVar(silentHoursA, 0, 23, 12)
    MinMaxVar(silentHoursB, 0, 23, 14)
    MinMaxVar(LastNoon, 1, 4, 2)
    MinMaxVar(showTimeIdleAfter, 1, 950, 5)
    MinMaxVar(LargeUIfontValue, 10, 18, 13)
    MinMaxVar(UserReligion, 1, 2, 1)
    MinMaxVar(strikeInterval, 900, 5500, 2000)
    MinMaxVar(BibleQuotesInterval, 1, 12, 5)
    MinMaxVar(maxBibleLength, 20, 130, 55)
    MinMaxVar(noTollingBgrSounds, 1, 3, 1)
    MinMaxVar(OSDalpha, 75, 252, 230)
    If (silentHoursB<silentHoursA)
       silentHoursB := silentHoursA

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
    FreeAhkResources(1)
    Sleep, 50
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
    Return
}

FreeAhkResources(cleanAll:=0,bumpExec:=0) {
  Static lastExec := 1
       , timesExec := 0
       , timesCleaned := 0

  If (A_TickCount - lastExec<1900)
     Return

  Loop, 2
  {
    If (tollQuarters=1)
       ahkthread_free(sndChanQ), sndChanQ := ""
    If (tollHours=1)
       ahkthread_free(sndChanH), sndChanH := ""
    If (cleanAll=1 || timesCleaned>15)
    {
       If (tollNoon=1)
          ahkthread_free(sndChanN), sndChanN := ""
       If (SemantronHoliday=1)
          ahkthread_free(sndChanS), sndChanS := ""
       If (AdditionalStrikes=1)
          ahkthread_free(sndChanA), sndChanA := ""
       If (ShowBibleQuotes=1)
          ahkthread_free(sndChanJ), sndChanJ := ""
    }
    Sleep, 100
    timesCleaned++
  }
  lastExec := A_TickCount

  If (bumpExec=1)
     timesExec++
  If (timesExec>4)
     ReloadScript()
}

sillySoundHack() {   ; this helps mitigate issues caused by apps like Team Viewer
     Sleep, 2
     SoundPlay, non-existent.lol
     SoundBeep, 0, 1
     Result := DllCall("winmm\PlaySoundW", "Ptr", 0, "Ptr", 0, "Uint", 0x46) ; SND_PURGE|SND_MEMORY|SND_NODEFAULT
     Return Result
}

InitAHKhThreads() {
    Static func2exec := "ahkThread"
    If IsFunc(func2exec) && StrLen(A_GlobalStruct)>4
    {
      If A_IsCompiled
      {
         If GetRes(data, 0, "ANALOG-CLOCK-DISPLAY.AHK", "LIB")
         {
            analogClockThread := %func2exec%(StrGet(&data))
            While !isAnalogClockFile := analogClockThread.ahkgetvar.isAnalogClockFile
                  Sleep, 10
         }
         VarSetCapacity(data, 0)
      } Else
      {
          isAnalogClockFile := FileExist("analog-clock-display.ahk")
          If isAnalogClockFile
             analogClockThread := %func2exec%(" #Include *i analog-clock-display.ahk ")
      }
    } Else (NoAhkH := 1)
}

GetRes(ByRef bin, lib, res, type) {
  hL := 0
  If lib
     hM := DllCall("kernel32\GetModuleHandleW", "Str", lib, "Ptr")

  If !lib
  {
     hM := 0  ; current module
  } Else If !hM
  {
     If (!hL := hM := DllCall("kernel32\LoadLibraryW", "Str", lib, "Ptr"))
        Return
  }

  dt := (type+0 != "") ? "UInt" : "Str"
  hR := DllCall("kernel32\FindResourceW"
      , "Ptr" , hM
      , "Str" , res
      , dt , type
      , "Ptr")

  If !hR
  {
     OutputDebug, % FormatMessage(A_ThisFunc "(" lib ", " res ", " type ", " l ")", A_LastError)
     Return
  }

  hD := DllCall("kernel32\LoadResource"
      , "Ptr" , hM
      , "Ptr" , hR
      , "Ptr")
  hB := DllCall("kernel32\LockResource"
      , "Ptr" , hD
      , "Ptr")
  sz := DllCall("kernel32\SizeofResource"
      , "Ptr" , hM
      , "Ptr" , hR
      , "UInt")
  If !sz
  {
     OutputDebug, Error: resource size 0 in %A_ThisFunc%(%lib%, %res%, %type%)
     DllCall("kernel32\FreeResource", "Ptr" , hD)
     If hL
        DllCall("kernel32\FreeLibrary", "Ptr", hL)
     Return
  }

  VarSetCapacity(bin, 0), VarSetCapacity(bin, sz, 0)
  DllCall("ntdll\RtlMoveMemory", "Ptr", &bin, "Ptr", hB, "UInt", sz)
  DllCall("kernel32\FreeResource", "Ptr" , hD)

  If hL
     DllCall("kernel32\FreeLibrary", "Ptr", hL)

  Return sz
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

  If (looped=0 && c>0 && ScriptInitialized=1)
  {
     Sleep, 1500
     z := isSoundPlayingNow(1)
  }

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
