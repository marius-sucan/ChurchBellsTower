; bells-tower.ahk - main file
;
; Charset for this file must be UTF 8 with BOM.
; it may not function properly otherwise.
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
;@Ahk2Exe-SetCopyright Marius Şucan (2017-2018)
;@Ahk2Exe-SetCompanyName http://marius.sucan.ro
;@Ahk2Exe-SetDescription Church Bells Tower
;@Ahk2Exe-SetVersion 1.9.6.1
;@Ahk2Exe-SetOrigFilename bells-tower.ahk
;@Ahk2Exe-SetMainIcon bells-tower.ico

;================================================================
; Section. Auto-exec.
;================================================================

; Script Initialization

 #SingleInstance Force
 #NoEnv
 #MaxMem 128
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
 , displayClock         := 1
 , silentHours          := 1
 , silentHoursA         := 12
 , silentHoursB         := 14
 , AutoUnmute           := 1
 , tickTockNoise        := 0
 , strikeInterval       := 2000
 , AdditionalStrikes    := 0
 , strikeEveryMin       := 5
 , showBibleQuotes      := 0
 , makeScreenDark       := 0
 , BibleQuotesInterval  := 5
 , UserReligion         := 1
 , SemantronHoliday     := 0
 , ObserveHolidays      := 0

; OSD settings
 , displayTimeFormat      := 1
 , DisplayTimeUser        := 3     ; in seconds
 , GuiX                   := 40
 , GuiY                   := 250
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
 , Version                := "1.9.6.1"
 , ReleaseDate            := "2018 / 11 / 15"
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
 , Tickcount_start2 := A_TickCount    ; timer to keep track of OSD redraws
 , Tickcount_start := 0               ; timer to count repeated key presses
 , MousePosition := ""
 , DoNotRepeatTimer := 0
 , PrefOpen := 0
 , FontList := []
 , actualVolume := 0
 , AdditionalStrikeFreq := strikeEveryMin * 60000  ; minutes
 , bibleQuoteFreq := BibleQuotesInterval * 3600000 ; hours
 , msgboxID := 1
 , ShowPreview := 0
 , ShowPreviewDate := 0
 , OSDprefix, OSDsuffix
 , stopStrikesNow := 0
 , stopAdditionalStrikes := 0
 , strikingBellsNow := 0
 , FontChangedTimes := 0
 , AnyWindowOpen := 0
 , LastBibleQuoteDisplay := 1
 , LastBibleMsg := ""
 , CurrentPrefWindow := 0
 , celebYear := A_Year
 , isHolidayToday := 0
 , semtr2play := 0
 , StartRegPath := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
 , tickTockSound := A_ScriptDir "\sounds\ticktock.wav"
 , hBibleTxt, hBibleOSD, hSetWinGui, ColorPickerHandles
 , hMain := A_ScriptHwnd
 , CCLVO := "-E0x200 +Border -Hdr -Multi +ReadOnly Report AltSubmit gsetColors"
 , hWinMM := DllCall("kernel32\LoadLibraryW", "Str", "winmm.dll", "Ptr")
 , sndChanQ, sndChanH, sndChanA, sndChanJ, sndChanN, sndChanS

; Initializations of the core components and functionality

If (A_IsCompiled && storeSettingsREG=0)
   VerifyFiles()

Sleep, 5
SetMyVolume()
InitializeTray()

hCursM := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32646, "Ptr")  ; IDC_SIZEALL
hCursH := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32649, "Ptr")  ; IDC_HAND
OnMessage(0x200, "MouseMove")    ; WM_MOUSEMOVE
OnMessage(0x404, "AHK_NOTIFYICON")
If (storeSettingsREG=1)
{
   OnMessage(0x11, "WM_ENDSESSION")
   OnMessage(0x16, "WM_ENDSESSION")
}
Sleep, 5
If (tickTockNoise=1)
   SoundLoop(tickTockSound)
theChimer()
Sleep, 30
testCelebrations()
ScriptInitialized := 1      ; the end of the autoexec section and INIT
If !isHolidayToday
   CreateBibleGUI(generateDateTimeTxt())
If (AdditionalStrikes=1)
   SetTimer, AdditionalStriker, %AdditionalStrikeFreq%
If (showBibleQuotes=1)
   SetTimer, InvokeBibleQuoteNow, %bibleQuoteFreq%
Return

WM_ENDSESSION() {
  Sleep, 10
  Return 1
  ExitApp
}

VerifyFiles() {
  Loop, Files, sounds\*.wav
        countFiles++
  Loop, Files, sounds\*.mp3
        countFiles++
  If (countFiles<16)
     FileRemoveDir, sounds, 1
  Sleep, 50
  FileCreateDir, sounds

  FileInstall, bible-quotes.txt, bible-quotes.txt
  FileInstall, bell-image.png, bell-image.png
  FileInstall, paypal.png, paypal.png
  FileInstall, sounds\ticktock.wav, sounds\ticktock.wav
  FileInstall, sounds\auxilliary-bell.mp3, sounds\auxilliary-bell.mp3
  FileInstall, sounds\japanese-bell.mp3, sounds\japanese-bell.mp3
  FileInstall, sounds\quarters.mp3, sounds\quarters.mp3
  FileInstall, sounds\hours.mp3, sounds\hours.mp3
  FileInstall, sounds\evening.mp3, sounds\evening.mp3
  FileInstall, sounds\noon1.mp3, sounds\noon1.mp3
  FileInstall, sounds\noon2.mp3, sounds\noon2.mp3
  FileInstall, sounds\noon3.mp3, sounds\noon3.mp3
  FileInstall, sounds\noon4.mp3, sounds\noon4.mp3
  FileInstall, sounds\orthodox-chimes1.mp3, sounds\orthodox-chimes1.mp3
  FileInstall, sounds\orthodox-chimes2.mp3, sounds\orthodox-chimes2.mp3
  FileInstall, sounds\semantron1.mp3, sounds\semantron1.mp3
  FileInstall, sounds\semantron2.mp3, sounds\semantron2.mp3
  FileInstall, sounds\morning.mp3, sounds\morning.mp3
  FileInstall, sounds\midnight.mp3, sounds\midnight.mp3
  Sleep, 300
}

AHK_NOTIFYICON(wParam, lParam, uMsg, hWnd) {
  If (PrefOpen=1 || A_IsSuspended)
     Return
  If (lParam = 0x201) || (lParam = 0x204)
  {
     stopStrikesNow := 1
     strikingBellsNow := 0
     If (lParam=0x204)
        CreateBibleGUI(generateDateTimeTxt(1,1))
     Else
        CreateBibleGUI(generateDateTimeTxt())
  } Else If (lParam = 0x207) && (strikingBellsNow=0)
  {
     If (AnyWindowOpen=1)
        stopStrikesNow := 0
     SetMyVolume(1)
     CreateBibleGUI(generateDateTimeTxt())
     If (tollQuarters=1)
        strikeQuarters()
     If (tollHours=1 || tollHoursAmount=1)
        strikeHours()
  } Else If (BibleGuiVisible=0 && strikingBellsNow=0)
  {
     CreateBibleGUI(generateDateTimeTxt(0))
  }
}

strikeJapanBell() {
  If (stopAdditionalStrikes!=1)
     Return

  If !sndChanJ
     sndChanJ := AhkThread("#NoTrayIcon`nSoundPlay, sounds\japanese-bell.mp3, 1")
  Else
     sndChanJ.ahkReload[]
}

InvokeBibleQuoteNow() {
  Static bibleQuotesFile, countLines, menuAdded
  
  If (PrefOpen=0 && A_IsSuspended)
     Return

  If (PrefOpen=1)
  {
     GuiControlGet, maxBibleLength
     VerifyOsdOptions()
  }

  If !bibleQuotesFile
     Try FileRead, bibleQuotesFile, bible-quotes.txt

  If (PrefOpen!=1)
  {
     If !countLines
        countLines := st_count(bibleQuotesFile, "`n") + 1
     Loop
     {
       Random, Line2Read, 1, %countLines%
       If !InStr(QuotesAlreadySeen, "a" Line2Read "a")
          stopLoop := 1
     } Until (stopLoop=1 || A_Index>712)
  } Else Line2Read := "R"
  bibleQuote := ST_ReadLine(bibleQuotesFile, Line2Read)
  LastBibleMsg := bibleQuote
  QuotesAlreadySeen .= "a" Line2Read "a"
  StringReplace, QuotesAlreadySeen, QuotesAlreadySeen, aa, a
  StringRight, QuotesAlreadySeen, QuotesAlreadySeen, 155
  If (StrLen(bibleQuote)>6)
     CreateBibleGUI(bibleQuote, 1, 1)
  If (PrefOpen!=1)
  {
     If (menuAdded!=1)
     {
        menuAdded := 1
        Menu, Tray, Enable, Show previous Bible &quote
     }
     SetMyVolume(1)
     INIaction(1, "QuotesAlreadySeen", "SavedSettings")
     strikeJapanBell()
  } Else SoundPlay, sounds\japanese-bell.mp3
  quoteDisplayTime := 1500 + StrLen(bibleQuote) * 123
  If (quoteDisplayTime>120100)
     quoteDisplayTime := 120100
  Else If (PrefOpen=1)
     quoteDisplayTime := quoteDisplayTime/2 + DisplayTime
  SetTimer, DestroyBibleGui, % -quoteDisplayTime
}

DestroyBibleGui() {
  Gui, BibleGui: Destroy
  Gui, ScreenBl: Destroy
  BibleGuiVisible := 0
}

ShowLastBibleMsg() {
  If (StrLen(LastBibleMsg)>6 && PrefOpen!=1)
  {
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
     SetVolume(BeepsVolume)
     Return
  }

  If (BeepsVolume<2)
  {
     SetVolume(0)
     Return
  }

  If (ScriptInitialized=1 && AutoUnmute=1 && BeepsVolume>3)
  && (A_TickCount - LastInvoked > 290100) && (noRestore=0)
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
    VerifyOsdOptions()
    GuiControl, , volLevel, % (result<2) ? "Audio: [ MUTE ]" : "Audio volume: " result " % "
    If (tollQuarters=1)
       strikeQuarters()
    If (tollHours=1 || tollHoursAmount=1)
       strikeHours()
}

RandomNumberCalc(minVariation:=150,maxVariation:=350) {
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
}

TollExtraNoon() {
  Static lastToll := 1
  If (AnyWindowOpen=1)
     stopStrikesNow := 0
  If (stopStrikesNow=1 || PrefOpen=1)
  || ((A_TickCount - lastToll<100000) && (AnyWindowOpen=1))
     Return
  If !sndChanN
     sndChanN := AhkThread("#NoTrayIcon`nRandom, choice, 1, 4`nSoundPlay, sounds\noon%choice%.mp3, 1")
  Else
     sndChanN.ahkReload[]
  lastToll := A_TickCount
}

AdditionalStriker() {
  If (stopAdditionalStrikes=1 || A_IsSuspended || PrefOpen=1 || strikingBellsNow=1)
     Return
  SetMyVolume(1)
  If !sndChanA
     sndChanA := AhkThread("#NoTrayIcon`nSoundPlay, sounds\auxilliary-bell.mp3, 1")
  Else
     sndChanA.ahkReload[]
}

theChimer() {
  Critical, on
  Static lastChimed
  FormatTime, CurrentTime,, hh:mm
  SetTimer, FreeAhkResources, Off
  If (lastChimed=CurrentTime || A_IsSuspended || PrefOpen=1)
     mustEndNow := 1
  FormatTime, exactTime,, HH:mm
  FormatTime, HoursIntervalTest,, H ; 0-23 format

  If (HoursIntervalTest>=silentHoursA && HoursIntervalTest<=silentHoursB && silentHours=2)
     soundBells := 1
  If (HoursIntervalTest>=silentHoursA && HoursIntervalTest<=silentHoursB && silentHours=3)
  || (soundBells!=1 && silentHours=2) || (mustEndNow=1)
  {
     If (mustEndNow!=1)
        stopAdditionalStrikes := 1
     SetTimer, theChimer, % calcNextQuarter()
     Return
  }

  SoundGet, master_vol
  stopStrikesNow := stopAdditionalStrikes := 0
  strikingBellsNow := 1
  Random, delayRandNoon, 950, 5050

  If (InStr(exactTime, "06:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        CreateBibleGUI(generateDateTimeTxt(1,1))
     SoundPlay, sounds\morning.mp3, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
  } Else If (InStr(exactTime, "18:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        CreateBibleGUI(generateDateTimeTxt(1,1))
     If (BeepsVolume>1)
        SoundPlay, sounds\evening.mp3, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
     If (StrLen(isHolidayToday)>3)
        SetTimer, TollExtraNoon, -51000
  } Else If (InStr(exactTime, "00:00") && tollNoon=1)
  {
     If (A_WDay=2 || A_WDay=5) && (ScriptInitialized=1)
        FreeAhkResources(1,1)
     Sleep, 100
     If (ScriptInitialized=1)
        testCelebrations()
     volumeAction := SetMyVolume()
     If (displayClock=1)
        CreateBibleGUI(generateDateTimeTxt(1,1))
     SoundPlay, sounds\midnight.mp3, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
  }

  If (InStr(CurrentTime, ":15") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        CreateBibleGUI(generateDateTimeTxt(1,1))
     strikeQuarters()
  } Else If (InStr(CurrentTime, ":30") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        CreateBibleGUI(generateDateTimeTxt(1,1))
     Loop, 2
        strikeQuarters()
  } Else If (InStr(CurrentTime, ":45") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        CreateBibleGUI(generateDateTimeTxt(1,1))
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
        If (displayClock=1)
           CreateBibleGUI(generateDateTimeTxt(1,1))
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
        If (displayClock=1)
           CreateBibleGUI(generateDateTimeTxt(1,1))
        Loop, %countHours2beat%
        {
           strikeHours()
           If (stopStrikesNow=0)
              Sleep, % A_Index * 85
        }
     } Else If (tollHours=1)
     {
        volumeAction := SetMyVolume()
        If (displayClock=1)
           CreateBibleGUI(generateDateTimeTxt(1,1))
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

        If (displayClock=1 && tollHours=0)
           CreateBibleGUI(generateDateTimeTxt(1,1))

        If (stopStrikesNow=0 && ScriptInitialized=1 && volumeAction>0 && BeepsVolume>1)
        {
           SoundPlay, sounds\noon%choice%.mp3, 1
        } Else If (stopStrikesNow=0 && BeepsVolume>1)
        {
           Random, newDelay, 39000, 89000
           SoundPlay, sounds\noon%choice%.mp3
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

CreateBibleGUI(msg2Display, isBibleQuote:=0, centerMsg:=0) {
    Critical, On
    bibleQuoteVisible := (isBibleQuote=1) ? 1 : 0
    FontSizeMin := (isBibleQuote=1) ? FontSizeQuotes : FontSize
    Gui, BibleGui: Destroy
    Sleep, 25
    If (isBibleQuote=1)
    {
       msg2Display := ST_wordWrap(msg2Display, maxBibleLength)
       LastBibleQuoteDisplay := A_TickCount
    } Else msg2Display := OSDprefix msg2Display OSDsuffix
    HorizontalMargins := (isBibleQuote=1) ? OSDmarginSides : 1
    Gui, BibleGui: -DPIScale -Caption +Owner +ToolWindow +HwndhBibleOSD
    Gui, BibleGui: Margin, %OSDmarginSides%, %HorizontalMargins%
    Gui, BibleGui: Color, %OSDbgrColor%
    If (FontChangedTimes>190)
       Gui, BibleGui: Font, c%OSDtextColor% s%FontSizeMin% Bold,
    Else
       Gui, BibleGui: Font, c%OSDtextColor% s%FontSizeMin% Bold, %FontName%
    Gui, BibleGui: Font, s1
    If (isBibleQuote=0)
       Gui, BibleGui: Add, Text, w2 h%OSDmarginTop% BackgroundTrans, .
    Gui, BibleGui: Font, s%FontSizeMin%
    Gui, BibleGui: Add, Text, y+%HorizontalMargins% hwndhBibleTxt, %msg2Display%
    Gui, BibleGui: Font, s1
    If (isBibleQuote=0)
       Gui, BibleGui: Add, Text, w2 y+0 h%OSDmarginBottom% BackgroundTrans, .
    Gui, BibleGui: Show, NoActivate AutoSize Hide x%GuiX% y%GuiY%, ChurchTowerBibleWin
    WinGetPos,,, mainWid, mainHeig, ahk_id %hBibleOSD%
    If (centerMsg=1)
    {
       If (makeScreenDark=1)
          ScreenBlocker(0,1)
       ActiveMon := MWAGetMonitorMouseIsIn()
       If ActiveMon
       {
          SysGet, mCoord, MonitorWorkArea, %ActiveMon%
          semiFinal_x := max(mCoordLeft, min(mCoordLeft+1, mCoordRight - 100))
          semiFinal_y := max(mCoordTop, min(mCoordTop+1, mCoordBottom - 100))
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
    } Else
    {
       ActiveMon := MWAGetMonitorMouseIsIn(GuiX, GuiY)
       If !ActiveMon
          ActiveMon := MWAGetMonitorMouseIsIn()
       SysGet, mCoord, MonitorWorkArea, %ActiveMon%
       Final_x := max(mCoordLeft, min(GuiX, mCoordRight - mainWid))
       Final_y := max(mCoordTop, min(GuiY, mCoordBottom - mainHeig))
       If !ActiveMon
       {
          Final_x := GuiX
          Final_y := GuiY
       }
       Gui, BibleGui: Show, NoActivate x%Final_x% y%Final_y%, ChurchTowerBibleWin
    }
    WinSet, Transparent, %OSDalpha%, ChurchTowerBibleWin
    WinSet, AlwaysOnTop, On, ChurchTowerBibleWin
    BibleGuiVisible := 1
    If (isBibleQuote=0 && PrefOpen!=1)
       SetTimer, DestroyBibleGui, % -DisplayTime
}

MouseMove(wP, lP, msg, hwnd) {
; Function by Drugwash
  Global
  Local A
  SetFormat, Integer, H
  hwnd+=0, A := WinExist("A"), hwnd .= "", A .= ""
  SetFormat, Integer, D
  HideDelay := (PrefOpen=1) ? 600 : 1950
  If (InStr(hBibleOSD, hwnd) && (A_TickCount - LastBibleQuoteDisplay>HideDelay))
  {
     Tickcount_start2 := A_TickCount
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
 ;      While GetKeyState("LButton", "P")
 ;      {
          PostMessage, 0xA1, 2,,, ahk_id %hBibleOSD%
          DllCall("user32\SetCursor", "Ptr", hCursM)
 ;      }
        SetTimer, trackMouseDragging, -50
        Sleep, 1
     } Else If ((wP&0x2) || (wP&0x10) || bibleQuoteVisible=1)
        DestroyBibleGui()
  } Else If ColorPickerHandles
  {
     If hwnd in %ColorPickerHandles%
        DllCall("user32\SetCursor", "Ptr", hCursH)
  }

  If (InStr(hwnd, hBibleOSD) || InStr(hwnd, hBibleTxt)) && (PrefOpen=0)
  {
     If (A_TimeIdle<100) && (A_TickCount - LastBibleQuoteDisplay>HideDelay)
        DestroyBibleGui()
  }
}

trackMouseDragging() {
; Function by Drugwash
  Global
  WinGetPos, NewX, NewY,,, ahk_id %hBibleOSD%

  GuiX := !NewX ? "2" : NewX
  GuiY := !NewY ? "2" : NewY

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
  regEntry := """" A_ScriptFullPath """"
  StringReplace, regEntry, regEntry, .ahk", .exe"
  RegRead, currentReg, %StartRegPath%, %appName%
  If (ErrorLevel=1 || currentReg!=regEntry)
  {
     StringReplace, TestThisFile, ThisFile, .ahk, .exe
     If !FileExist(TestThisFile)
        MsgBox, This option works only in the compiled edition of this script.
     RegWrite, REG_SZ, %StartRegPath%, %appName%, %regEntry%
     Menu, Tray, Check, Sta&rt at boot
     CreateBibleGUI("Enabled Start at Boot")
  } Else
  {
     RegDelete, %StartRegPath%, %appName%
     Menu, Tray, Uncheck, Sta&rt at boot
     CreateBibleGUI("Disabled Start at Boot")
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
   FreeAhkResources(1)
   If !A_IsSuspended
   {
      stopStrikesNow := 1
      SetTimer, theChimer, Off
      Menu, Tray, Uncheck, &%appName% activated
      SoundLoop("")
   } Else
   {
      stopStrikesNow := 0
      Menu, Tray, Check, &%appName% activated
      If (tickTockNoise=1)
         SoundLoop(tickTockSound)
      theChimer()
   }
   SoundPlay, non-existent.lol
   friendlyName := A_IsSuspended ? " activated" : " deactivated"
   CreateBibleGUI(appName friendlyName)

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
    Menu, Tray, Add, &Customize, ShowOSDsettings
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
       Menu, Tray, Add, Tick/Tock sound, ToggleTickTock
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
    If (tickTockNoise=1)
       Menu, Tray, Check, Tick/Tock sound
}

ToggleLargeFonts() {
    PrefsLargeFonts := !PrefsLargeFonts
    LargeUIfontValue := 13
    INIaction(1, "PrefsLargeFonts", "SavedSettings")
    INIaction(1, "LargeUIfontValue", "SavedSettings")
    Menu, Tray, % (PrefsLargeFonts=0 ? "Uncheck" : "Check"), L&arge UI fonts
    If (PrefOpen=1)
       SwitchPreferences(1)
    Else If (AnyWindowOpen=1)
    {
       CloseWindow()
       AboutWindow()
    }
}

ToggleTickTock() {
    tickTockNoise := !tickTockNoise
    INIaction(1, "tickTockNoise", "SavedSettings")
    Menu, Tray, % (tickTockNoise=0 ? "Uncheck" : "Check"), Tick/Tock sound
    If (tickTockNoise=1)
       SoundLoop(tickTockSound)
    Else
       SoundLoop("")
}

ReloadScript(silent:=1) {
    Thread, Priority, 50
    Critical, On

    If (PrefOpen=1)
    {
       CloseSettings()
       Return
    }

    If FileExist(ThisFile)
    {
        Cleanup()
        Try Reload
        Sleep, 70
        ExitApp
    } Else
    {
        CreateBibleGUI("FATAL ERROR: Main file missing. Execution terminated.")
        SoundBeep
        Sleep, 2000
        Cleanup() ; if you don't do it HERE you're not doing it right, Run %i% will force the script to close before cleanup
        MsgBox, 4,, Do you want to choose another file to execute?
        IfMsgBox, Yes
        {
            FileSelectFile, i, 2, %A_ScriptDir%\%A_ScriptName%, Select a different script to load, AutoHotkey script (*.ahk; *.ah1u)
            If !InStr(FileExist(i), "D")  ; we can't run a folder, we need to run a script
               Run, %i%
        } Else (Sleep, 500)
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
   If (ScriptInitialized!=1)
      ExitApp

   PrefOpen := 0
   If (FileExist(ThisFile) && showMSG)
   {
      INIsettings(1)
      CreateBibleGUI("Bye byeee :-)")
      Sleep, 350
   } Else If showMSG
   {
      CreateBibleGUI("Adiiooosss :-(((")
      Sleep, 950
   }
   Cleanup()
   ExitApp
}

;================================================================
;  Settings window.
;   various functions used in the UI.
;================================================================

SettingsGUI(whiteBgr:=0) {
   Global
   Gui, SettingsGUIA: Destroy
   Sleep, 15
   Gui, SettingsGUIA: Default
   Gui, SettingsGUIA: -MaximizeBox -MinimizeBox hwndhSetWinGui
   Gui, SettingsGUIA: Margin, 15, 15
   If (whiteBgr=1)
      Gui, SettingsGUIA: Color, FAfaFA
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
       semiFinal_x := max(mCoordLeft, min(mCoordLeft+1, mCoordRight - 100))
       semiFinal_y := max(mCoordTop, min(mCoordTop+1, mCoordBottom - 100))
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
       ShowOSDsettings()
       VerifyOsdOptions(ApplySettingsBTN)
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
    Static LastBorderState, lastFnt := FontName
    Gui, SettingsGUIA: Submit, NoHide
    SetTimer, DestroyBibleGui, Off
    If (ShowPreview=0)
    {
       DestroyBibleGui()
       Return
    }

    CreateBibleGUI(generateDateTimeTxt(1, !ShowPreviewDate))
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

generateDateTimeTxt(LongD:=1, noDate:=0) {
    If (displayTimeFormat=1)
       FormatTime, CurrentTime,, H:mm
    Else
       FormatTime, CurrentTime,, h:mm tt

    If (LongD=1)
       FormatTime, CurrentDate,, LongDate
    Else
       FormatTime, CurrentDate,, ShortDate

    If (noDate=1)
       txtReturn := CurrentTime
    Else
       txtReturn := CurrentTime " | " CurrentDate
    Return txtReturn
}

editsOSDwin() {
  If (A_TickCount-DoNotRepeatTimer<1000)
     Return
  VerifyOsdOptions()
}

checkBoxStrikeQuarter() {
  GuiControlGet, tollQuarters
  stopStrikesNow := 0
  VerifyOsdOptions()
  If (tollQuarters=1)
     strikeQuarters()
}

checkBoxStrikeHours() {
  GuiControlGet, tollHours
  stopStrikesNow := 0
  VerifyOsdOptions()
  If (tollHours=1)
     strikeHours()
}

checkBoxStrikeAdditional() {
  GuiControlGet, AdditionalStrikes
  stopStrikesNow := 0
  VerifyOsdOptions()
  If (AdditionalStrikes=1)
     SoundPlay, sounds\auxilliary-bell.mp3
}

ShowOSDsettings() {
    doNotOpen := initSettingsWindow()
    If (doNotOpen=1)
       Return

    Global CurrentPrefWindow := 5
    Global DoNotRepeatTimer := A_TickCount
    Global editF1, editF2, editF3, editF4, editF5, editF6, Btn1, volLevel, editF40, editF60, editF73, Btn2, txt4, Btn3
         , editF7, editF8, editF9, editF10, editF11, editF13, editF35, editF36, editF37, editF38, txt1, txt2, txt3, Btn4
    columnBpos1 := columnBpos2 := 160
    editFieldWid := 220
    If (PrefsLargeFonts=1)
    {
       Gui, Font, s%LargeUIfontValue%
       editFieldWid := 285
       columnBpos1 := columnBpos2 := columnBpos2 + 90
    }
    columnBpos1b := columnBpos1 + 20

    Gui, Add, Tab3, , General|OSD options

    Gui, Tab, 1 ; general
    Gui, Add, Text, x+15 y+15 Section +0x200 vvolLevel, % "Audio volume: " BeepsVolume " % "
    Gui, Add, Slider, x+5 hp ToolTip NoTicks gVolSlider w200 vBeepsVolume Range0-99, %BeepsVolume%
    Gui, Add, Checkbox, gVerifyOsdOptions x+5 Checked%DynamicVolume% vDynamicVolume, Dynamic
    Gui, Add, Checkbox, xs y+10 gVerifyOsdOptions Checked%AutoUnmute% vAutoUnmute, Automatically unmute master volume [when required]
    Gui, Add, Checkbox, y+10 gVerifyOsdOptions Checked%tollNoon% vtollNoon, Toll distinctively every six hours [eg., noon, midnight]
    Gui, Add, Checkbox, y+10 gcheckBoxStrikeQuarter Checked%tollQuarters% vtollQuarters, Strike quarter-hours
    Gui, Add, Checkbox, x+10 gVerifyOsdOptions Checked%tollQuartersException% vtollQuartersException, ... except on the hour
    Gui, Add, Checkbox, xs y+10 gcheckBoxStrikeHours Checked%tollHours% vtollHours, Strike on the hour
    Gui, Add, Checkbox, x+10 gVerifyOsdOptions Checked%tollHoursAmount% vtollHoursAmount, ... the number of hours
    Gui, Add, Checkbox, xs y+10 gVerifyOsdOptions Checked%displayClock% vdisplayClock, Display time on screen when bells toll
    Gui, Add, Checkbox, x+10 gVerifyOsdOptions Checked%displayTimeFormat% vdisplayTimeFormat, 24 hours format
    Gui, Add, Checkbox, xs y+10 gcheckBoxStrikeAdditional Checked%AdditionalStrikes% vAdditionalStrikes, Additional strike every (in minutes)
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF38, %strikeEveryMin%
    Gui, Add, UpDown, gVerifyOsdOptions vstrikeEveryMin Range1-720, %strikeEveryMin%
    Gui, Add, Checkbox, xs y+7 gVerifyOsdOptions Checked%showBibleQuotes% vshowBibleQuotes, Show a Bible quote every (in hours)
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF40, %BibleQuotesInterval%
    Gui, Add, UpDown, gVerifyOsdOptions vBibleQuotesInterval Range2-12, %BibleQuotesInterval%
    Gui, Add, Checkbox, xs y+7 gVerifyOsdOptions Checked%ObserveHolidays% vObserveHolidays, Observe Christian feasts / holidays
    Gui, Add, DropDownList, x+2 w100 gVerifyOsdOptions AltSubmit Choose%UserReligion% vUserReligion, Catholic|Orthodox
    Gui, Add, Button, x+1 hp w50 gListCelebrationsBtn vBtn3, List
    Gui, Add, Checkbox, xs y+7 gVerifyOsdOptions Checked%SemantronHoliday% vSemantronHoliday, Mark days of feast by regular semantron drumming
    Gui, Add, Text, xs y+10, Interval between tower strikes (in miliseconds):
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit5 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF37, %strikeInterval%
    Gui, Add, UpDown, gVerifyOsdOptions vstrikeInterval Range900-5500, %strikeInterval%
    Gui, Add, DropDownList, xs y+10 w270 gVerifyOsdOptions AltSubmit Choose%silentHours% vsilentHours, Limit chimes to specific periods...|Play chimes only...|Keep silence...
    Gui, Add, Text, xp+15 y+6 hp +0x200 vtxt1, from
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF35, %silentHoursA%
    Gui, Add, UpDown, gVerifyOsdOptions vsilentHoursA Range0-23, %silentHoursA%
    Gui, Add, Text, x+2 hp  +0x200 vtxt2, :00   to
    Gui, Add, Edit, x+10 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF36, %silentHoursB%
    Gui, Add, UpDown, gVerifyOsdOptions vsilentHoursB Range0-23, %silentHoursB%
    Gui, Add, Text, x+1 hp  +0x200 vtxt3, :59

    Gui, Tab, 2 ; style
    Gui, Add, Text, x+15 y+15 Section, OSD position (x, y)
    Gui, Add, Edit, xs+%columnBpos2% ys w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF1, %GuiX%
    Gui, Add, UpDown, vGuiX gVerifyOsdOptions 0x80 Range-9995-9998, %GuiX%
    Gui, Add, Edit, x+5 w70 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF2, %GuiY%
    Gui, Add, UpDown, vGuiY gVerifyOsdOptions 0x80 Range-9995-9998, %GuiY%
    Gui, Add, Button, x+5 w60 hp gLocatePositionA vBtn4, Locate

    Gui, Add, Text, xm+15 ys+30 Section, Margins (top, bottom, sides)
    Gui, Add, Edit, xs+%columnBpos2% ys+0 Section w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF11, %OSDmarginTop%
    Gui, Add, UpDown, gVerifyOsdOptions vOSDmarginTop Range1-900, %OSDmarginTop%
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF9 , %OSDmarginBottom%
    Gui, Add, UpDown, gVerifyOsdOptions vOSDmarginBottom Range1-900, %OSDmarginBottom%
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF13, %OSDmarginSides%
    Gui, Add, UpDown, gVerifyOsdOptions vOSDmarginSides Range1-900, %OSDmarginSides%

    Gui, Add, Text, xm+15 y+10 Section, Font name
    Gui, Add, Text, xs yp+30, OSD colors and opacity
    Gui, Add, Text, xs yp+30, Font size (normal, quotes)
    Gui, Add, Text, xs yp+30, Display time (in sec.)
    Gui, Add, Text, xs yp+30 vTxt4, Max. line length, for Bible quotes
    Gui, Add, Checkbox, xs yp+30 gVerifyOsdOptions Checked%makeScreenDark% vmakeScreenDark, Dim the screen for Bible quotes
    Gui, Add, Checkbox, xs yp+35 h30 +0x1000 gVerifyOsdOptions Checked%ShowPreview% vShowPreview, Show preview window
    Gui, Add, Checkbox, y+5 hp gVerifyOsdOptions Checked%ShowPreviewDate% vShowPreviewDate, Include current date into preview

    Gui, Add, DropDownList, xs+%columnBpos2% ys+0 section w205 gVerifyOsdOptions Sort Choose1 vFontName, %FontName%
    Gui, Add, ListView, xp+0 yp+30 w55 h25 %CCLVO% Background%OSDtextColor% vOSDtextColor hwndhLV1,
    Gui, Add, ListView, x+5 yp w55 h25 %CCLVO% Background%OSDbgrColor% vOSDbgrColor hwndhLV2,
    Gui, Add, Edit, x+5 yp+0 w55 hp geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF10, %OSDalpha%
    Gui, Add, UpDown, vOSDalpha gVerifyOsdOptions Range25-250, %OSDalpha%
    Gui, Add, Edit, xp-120 yp+30 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF5, %FontSize%
    Gui, Add, UpDown, gVerifyOsdOptions vFontSize Range12-295, %FontSize%
    Gui, Add, Edit, x+5 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF73, %FontSizeQuotes%
    Gui, Add, UpDown, gVerifyOsdOptions vFontSizeQuotes Range10-200, %FontSizeQuotes%
    Gui, Add, Edit, xp-60 yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF6, %DisplayTimeUser%
    Gui, Add, UpDown, vDisplayTimeUser gVerifyOsdOptions Range1-99, %DisplayTimeUser%
    Gui, Add, Edit, xp+0 yp+30 w55 hp geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF60, %maxBibleLength%
    Gui, Add, UpDown, vmaxBibleLength gVerifyOsdOptions Range20-130, %maxBibleLength%
    Gui, Add, Button, x+0 hp w120 gInvokeBibleQuoteNow vBtn2, Preview quote
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
    Gui, Add, Button, x+8 w160 hp gDeleteSettings, R&estore defaults
    Gui, Show, AutoSize, Customize: %appName%
    verifySettingsWindowSize()
    VerifyOsdOptions(0)
    ColorPickerHandles := hLV1 "," hLV2 "," hLV3 "," hLV5 "," hTXT
}

VerifyOsdOptions(EnableApply:=1) {
    GuiControlGet, ShowPreview
    GuiControlGet, silentHours
    GuiControlGet, tollHours
    GuiControlGet, tollQuarters
    GuiControlGet, AdditionalStrikes
    GuiControlGet, showBibleQuotes
    GuiControlGet, SemantronHoliday
    GuiControlGet, ObserveHolidays

    GuiControl, % (EnableApply=0 ? "Disable" : "Enable"), ApplySettingsBTN
    GuiControl, % (AdditionalStrikes=0 ? "Disable" : "Enable"), editF38
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF40
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF60
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF73
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Btn2
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Txt4
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), makeScreenDark
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
    GuiControl, % ((ObserveHolidays=0 && SemantronHoliday=0) ? "Disable" : "Enable"), UserReligion
    GuiControl, % ((ObserveHolidays=0 && SemantronHoliday=0) ? "Disable" : "Enable"), btn3

    Static LastInvoked := 1

    If (A_TickCount - LastInvoked>200) || (BibleGuiVisible=0 && ShowPreview=1)
    || (BibleGuiVisible=1 && ShowPreview=0)
    {
       LastInvoked := A_TickCount
       OSDpreview()
    }
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
    If !ActiveMon
       Return
    SysGet, mCoord, MonitorWorkArea, %ActiveMon%
    ResolutionWidth := Abs(max(mCoordRight, mCoordLeft) - min(mCoordRight, mCoordLeft))
    ResolutionHeight := Abs(max(mCoordTop, mCoordBottom) - min(mCoordTop, mCoordBottom))

    Gui, ScreenBl: Destroy
    Gui, ScreenBl: +AlwaysOnTop -DPIScale -Caption +ToolWindow
    Gui, ScreenBl: Margin, 0, 0
    Gui, ScreenBl: Color, % (darkner=1) ? 221122 : 543210
    Gui, ScreenBl: Show, NoActivate x%mCoordLeft% y%mCoordTop% w%ResolutionWidth% h%ResolutionHeight%, ScreenShader
    WinSet, Transparent, % (darkner=1) ? 125 : 30, ScreenShader
    If (darkner=1)
       Gui, ScreenBl: +E0x20
    WinSet, AlwaysOnTop, On, ScreenShader
}

LocatePositionA() {
    ScreenBlocker()
    ToolTip, Move mouse to desired location and click
    KeyWait, LButton, D, T10
    MouseGetPos, mX, mY
    ToolTip
    ScreenBlocker(1)
    GuiControl, , ShowPreview, 1
    GuiControl, , GuiX, %mX%
    GuiControl, , GuiY, %mY%
    OSDpreview()
    VerifyOsdOptions()
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
     isHolidayToday := "The Life-Giving Spring - when Blessed Mary healed a blind man by drinking water from a spring"

  return result
}

testCelebrations() {
  testEquiSols()
  If (ObserveHolidays=0 && SemantronHoliday=0)
     Return

  easterdate := calcEasterDate()
  divineMercyDate := DivineMercy()
  2ndeasterdate := SecondDayEaster()
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

  testFeast := A_MDay "." A_Mon
  If (testFeast="06.01")
     isHolidayToday := (UserReligion=1) ? "Epiphany - the revelation of God incarnate as Jesus Christ" : "Theophany - the baptism of Jesus in the Jordan River"
  Else If (testFeast="07.01" && UserReligion=2)
     isHolidayToday := "The Synaxis of Saint John the Baptist - a Jewish itinerant preacher, and a prophet"
  Else If (testFeast="30.01" && UserReligion=2)
     isHolidayToday := "The Three Holy Hierarchs - Basil the Great, John Chrysostom and Gregory the Theologian"
  Else If (testFeast="02.02")
     isHolidayToday := "The Presentation of Lord Jesus - at the Temple in Jerusalem to induct Him into Judaism"
  Else If (testFeast="25.03" && !isHolidayToday)
     isHolidayToday := "The Annunciation of the Lord [Virgin Mary] - when Virgin Mary was told she would conceive and become the mother of Jesus"
  Else If (testFeast="23.04" && !isHolidayToday)
     isHolidayToday := "Saint George - a Roman soldier of Greek origin under the Roman emperor Diocletian - he was sentenced to death for refusing to recant his Christian faith"
  Else If (testFeast="24.06")
     isHolidayToday := "Birth of John the Baptist - a Jewish itinerant preacher, and a prophet"
  Else If (testFeast="06.08")
     isHolidayToday := "The Feast of the Transfiguration of Jesus - when He becomes radiant in glory upon a mountain"
  Else If (testFeast="15.08")
     isHolidayToday := (UserReligion=1) ? "Assumption of Virgin Mary - her body and soul assumed into heavenly glory" : "Falling Asleep of the Blessed Virgin Mary"
  Else If (testFeast="29.08")
     isHolidayToday := "The Beheading of Saint John the Baptist - he was killed on the orders of Herod Antipas through the vengeful request of his step-daughter Salomé and her mother Herodias"
  Else If (testFeast="08.09")
     isHolidayToday := "Birth of the Virgin Mary"
  Else If (testFeast="14.09")
     isHolidayToday := "The Exaltation of the Holy Cross - the recovery of the cross on which Jesus Christ was crucified"
  Else If (testFeast="04.10" && UserReligion=1)
     isHolidayToday := "Saint Francis of Assisi - an Italian friar, deacon, preacher and founder of different orders within Catholic church"
  Else If (testFeast="14.10" && UserReligion=2)
     isHolidayToday := "Saint Paraskeva of the Balkans - an ascetic female saint of the 10th century of half Serbian and half Greek origins"
  Else If (testFeast="01.11" && UserReligion=1)
     isHolidayToday := "All saints day"
  Else If (testFeast="02.11" && UserReligion=1)
     isHolidayToday := "All souls' day - commemoration of all the faithful departed"
  Else If (testFeast="21.11")
     isHolidayToday := "The Presentation of the Blessed Virgin Mary - when she was brought, as a child, to the Temple in Jerusalem to be consecrated to God"
  Else If (testFeast="08.12" && UserReligion=1)
     isHolidayToday := "The Solemnity of Immaculate Conception - of Jesus Christ by Virgin Mary"
  Else If (testFeast="25.12")
     isHolidayToday := "Christmas day - the birth of Jesus Christ"
  Else If (testFeast="26.12")
     isHolidayToday := "Christmas 2nd day - the birth of Jesus Christ"
  Else If (testFeast="28.12" && UserReligion=1)
     isHolidayToday := "Feast of the Holy Innocents - in remembrance of the young children killed in Bethlehem by King Herod the Great in his attempt to kill the infant Jesus"

  OSDprefix := ""
  If (StrLen(isHolidayToday)>2 && ObserveHolidays=1)
  {
     OSDprefix := "✝ "
     If (AnyWindowOpen!=1)
        CreateBibleGUI(generateDateTimeTxt() " || " isHolidayToday, 1, 1)
  }
}

ListCelebrationsBtn() {
  celebYear := A_Year
  VerifyOsdOptions()
  ListCelebrations()
}

ListCelebrations() {
  easterdate := calcEasterDate()
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

  FormatTime, easterdate, %easterdate%, LongDate
  FormatTime, divineMercyDate, %divineMercyDate%, LongDate
  FormatTime, palmdaydate, %palmdaydate%, LongDate
  FormatTime, maundydate, %maundydate%, LongDate
  FormatTime, HolySaturdaydate, %HolySaturdaydate%, LongDate
  FormatTime, goodFridaydate, %goodFridaydate%, LongDate
  FormatTime, ashwednesdaydate, %ashwednesdaydate%, LongDate
  FormatTime, ascensiondaydate, %ascensiondaydate%, LongDate
  FormatTime, pentecostdate, %pentecostdate%, LongDate
  FormatTime, TrinitySundaydate, %TrinitySundaydate%, LongDate
  FormatTime, corpuschristidate, %corpuschristidate%, LongDate
  FormatTime, holyTrinityOrthdoxDate, %holyTrinityOrthdoxDate%, LongDate
  FormatTime, lifeSpringDate, %lifeSpringDate%, LongDate

  Epiphany := celebYear 0106010101
  SynaxisSaintJohnBaptist := celebYear 0107010101
  ThreeHolyHierarchs := celebYear 0130010101
  PresentationLord := celebYear 0202010101
  AnnunciationLord := celebYear 0325010101
  SaintGeorge := celebYear 0423010101
  BirthJohnBaptist := celebYear 0624010101
  FeastTransfiguration := celebYear 0806010101
  AssumptionVirginMary := celebYear 0815010101
  BeheadingJohnBaptist := celebYear 0829010101
  BirthVirginMary := celebYear 0908010101
  ExaltationHolyCross := celebYear 0914010101
  SaintFrancisAssisi := celebYear 1004010101
  SaintParaskeva := celebYear 1014010101
  Allsaintsday := celebYear 1101010101
  Allsoulsday := celebYear 1102010101
  PresentationVirginMary := celebYear 1121010101
  ImmaculateConception := celebYear 1208010101
  Christmasday := celebYear 1225010101
  FeastHolyInnocents := celebYear 1228010101

  FormatTime, Epiphany, %Epiphany%, LongDate
  FormatTime, SynaxisSaintJohnBaptist, %SynaxisSaintJohnBaptist%, LongDate
  FormatTime, ThreeHolyHierarchs, %ThreeHolyHierarchs%, LongDate
  FormatTime, PresentationLord, %PresentationLord%, LongDate
  FormatTime, AnnunciationLord, %AnnunciationLord%, LongDate
  FormatTime, SaintGeorge, %SaintGeorge%, LongDate
  FormatTime, BirthJohnBaptist, %BirthJohnBaptist%, LongDate
  FormatTime, FeastTransfiguration, %FeastTransfiguration%, LongDate
  FormatTime, AssumptionVirginMary, %AssumptionVirginMary%, LongDate
  FormatTime, BeheadingJohnBaptist, %BeheadingJohnBaptist%, LongDate
  FormatTime, BirthVirginMary, %BirthVirginMary%, LongDate
  FormatTime, ExaltationHolyCross, %ExaltationHolyCross%, LongDate
  FormatTime, SaintFrancisAssisi, %SaintFrancisAssisi%, LongDate
  FormatTime, SaintParaskeva, %SaintParaskeva%, LongDate
  FormatTime, Allsaintsday, %Allsaintsday%, LongDate
  FormatTime, Allsoulsday, %Allsoulsday%, LongDate
  FormatTime, PresentationVirginMary, %PresentationVirginMary%, LongDate
  FormatTime, ImmaculateConception, %ImmaculateConception%, LongDate
  FormatTime, Christmasday, %Christmasday%, LongDate
  FormatTime, FeastHolyInnocents, %FeastHolyInnocents%, LongDate
  relName := (UserReligion=1) ? "Catholic" : "Orthodox"
  msgboxID := 1
  If (UserReligion=1)
  {
     OnMessage(0x44, "OnMsgBox")
     MsgBox 0x2001, %relName% celebrations in %celebYear%,
     (Ltrim
       Easter related celebrations:
       Ash Wednesday: %ashwednesdaydate%
       Palm Sunday: %palmdaydate%
       Maundy Thursday: %maundydate%
       Good Friday: %goodFridaydate%
       Holy Saturday: %HolySaturdaydate%
       Catholic Easter: %easterdate%
       Divine Mercy: %divineMercyDate%
       Ascension of Jesus: %ascensiondaydate%
       Pentecost: %pentecostdate%
       Trinity Sunday: %TrinitySundaydate%
       Corpus Christi: %corpuschristidate%
     )
     OnMessage(0x44, "")

     IfMsgBox, OK
     {
       msgboxID := 2
       OnMessage(0x44, "OnMsgBox")
       MsgBox 0x2001, %relName% celebrations in %celebYear%,
       (Ltrim
         Other celebrations:
         Epiphany: %Epiphany%
         The Presentation of Lord Jesus: %PresentationLord%
         The Annunciation of the Virgin Mary: %AnnunciationLord%
         Saint George: %SaintGeorge%
         Birth of John the Baptist: %BirthJohnBaptist%
         Feast of Transfiguration: %FeastTransfiguration%
         Assumption of Virgin Mary: %AssumptionVirginMary%
         The Beheading of Saint John the Baptist: %BeheadingJohnBaptist%
         Birth of Virgin Mary: %BirthVirginMary%
         The Exaltation of the Holy Cross: %ExaltationHolyCross%
         Saint Francis of Assisi: %SaintFrancisAssisi%
         All saints day: %Allsaintsday%
         All souls' day: %Allsoulsday%
         The Presentation of the Virgin Mary: %PresentationVirginMary%
         The Solemnity of Immaculate Conception: %ImmaculateConception%
         Christmas day: %Christmasday%
         Feast of the Holy Innocents: %FeastHolyInnocents%
       )
       IfMsgBox OK, {
         celebYear++
         ListCelebrations()
       } Else Return
   
     } Else Return
  } Else
  {
     OnMessage(0x44, "OnMsgBox")
     MsgBox 0x2001, %relName% celebrations in %celebYear%,
     (Ltrim
       Easter related celebrations:
       Flowery Sunday: %palmdaydate%
       Maundy Thursday: %maundydate%
       Holy Friday: %goodFridaydate%
       Holy Saturday: %HolySaturdaydate%
       Orthodox Easter: %easterdate%
       Life-giving Spring: %lifeSpringDate%
       Ascension of Jesus: %ascensiondaydate%
       Pentecost: %pentecostdate%
       Holy Trinity: %holyTrinityOrthdoxDate%
       All saints day: %TrinitySundaydate%
     )
     OnMessage(0x44, "")

     IfMsgBox, OK
     {
       msgboxID := 2
       OnMessage(0x44, "OnMsgBox")
       MsgBox 0x2001, %relName% celebrations in %celebYear%,
       (Ltrim
         Other celebrations:
         Theophany: %Epiphany%
         The Synaxis of Saint John the Baptist: %SynaxisSaintJohnBaptist%
         The Three Holy Hierarchs: %ThreeHolyHierarchs%
         The Presentation of Lord Jesus: %PresentationLord%
         The Annunciation of the Virgin Mary: %AnnunciationLord%
         Saint George: %SaintGeorge%
         Birth of John the Baptist: %BirthJohnBaptist%
         Feast of Transfiguration: %FeastTransfiguration%
         Falling Asleep of Virgin Mary: %AssumptionVirginMary%
         The Beheading of Saint John the Baptist: %BeheadingJohnBaptist%
         Birth of Virgin Mary: %BirthVirginMary%
         The Exaltation of the Holy Cross: %ExaltationHolyCross%
         Saint Paraskeva of the Balkans: %SaintParaskeva%
         The Presentation of the Virgin Mary: %PresentationVirginMary%
         Christmas day: %Christmasday%
       )
       IfMsgBox OK, {
         celebYear++
         ListCelebrations()
       } Else Return
   
     } Else Return
  }
}

OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, % (msgboxID=2) ? "&Next year" : "&Others"
        ControlSetText Button2, &Close
    }
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
    Gui, Font, c1166AA s19 Bold, Arial, -wrap
    Gui, Add, Picture, x14 y10 h65 w-1 gTollExtraNoon hwndhBellIcon, bell-image.png
    Gui, Add, Text, x+14 yp+5 Section, %appName%

    Gui, Font
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
       Gui, Font, s%LargeUIfontValue%
    }
    Gui, Add, Link, y+4, Developed by <a href="http://marius.sucan.ro">Marius Şucan</a> on AHK_H.
    If (tickTockNoise!=1)
       SoundLoop(tickTockSound)

    testCelebrations()
    MarchEquinox := compareYearDays(78, A_YDay) "March equinox."   ; 03 / 20
    If InStr(MarchEquinox, "now")
       MarchEquinox := "The March equinox is here now."
    JuneSolstice := compareYearDays(170, A_YDay) "June solstice."  ; 06 / 21
    If InStr(JuneSolstice, "now")
       JuneSolstice := "The June solstice is here now."
    SepEquinox := compareYearDays(263, A_YDay) "September equinox."  ; 09 / 22
    If InStr(SepEquinox, "now")
       SepEquinox := "The September equinox is here now."
    DecSolstice := compareYearDays(354, A_YDay) "December solstice."  ; 12 / 21
    If InStr(DecSolstice, "now")
       DecSolstice := "The December solstice is here now."

    percentileYear := Round(A_YDay/366*100) "%"
    FormatTime, CurrentYear,, yyyy

    FormatTime, CurrentDateTime,, yyyyMMddHHmm
    FormatTime, CurrentDay,, yyyyMMdd
    FirstMinOfDay := CurrentDay "0001"
    EnvSub, CurrentDateTime, %FirstMinOfDay%, Minutes
    minsPassed := CurrentDateTime
    percentileDay := Round(minsPassed/1440*100) "%"

    Gui, Add, Text, x15 y+20 w%txtWid% Section, Dedicated to Christians, church-goers and bell lovers.
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
    StringRight, weeksPassed, A_YWeek, 2
    weeksPlural := (weeksPassed>1) ? "weeks" : "week"
    weeksPlural2 := (weeksPassed>1) ? "have" : "has"

    If (A_YDay>=353)
    {
       Gui, Font, Bold
       Gui, Add, Text, y+7 w%txtWid%, Season's greetings! Enjoy the holidays! 😊
       Gui, Font, Normal
    }
    If (StrLen(isHolidayToday)>2 && ObserveHolidays=1)
    {
       relName := (UserReligion=1) ? "Catholic" : "Orthodox"
       Gui, Font, Bold
       Gui, Add, Text, y+7 w%txtWid%, % relName " Christians celebrate today: " isHolidayToday "."
       Gui, Font, Normal
    }

    If (A_YDay>172 && A_YDay<353)
       Gui, Add, Text, y+7, The days are getting shorter until the winter solstice, in December.
    Else If (A_YDay>356 && A_YDay<168)
       Gui, Add, Text, y+7, The days are getting longer until the summer solstice, in June..
    Gui, Add, Text, y+15 Section, % CurrentYear " {" CalcTextHorizPrev(A_YDay, 366) "} " NextYear
    Gui, Add, Text, xp+15 y+5, %weeksPassed% %weeksPlural% (%percentileYear%) of %CurrentYear% %weeksPlural2% elapsed.
    Gui, Add, Text, xs y+10, % "0h {" CalcTextHorizPrev(minsPassed, 1440, 0, 22) "} 24h "
    Gui, Add, Text, xp+15 y+5, %minsPassed% minutes (%percentileDay%) of today have elapsed.
    Gui, Add, Text, xs y+15 w%txtWid%, This application contains code from various entities. You can find more details in the source code.
    If (storeSettingsREG=1)
       Gui, Add, Link, xs y+15 w%txtWid%, This application was downloaded through <a href="ms-windows-store://pdp/?productid=9PFQBHN18H4K">Windows Store</a>.
    Else      
       Gui, Add, Link, xs y+15 w%txtWid%, The development page is <a href="https://github.com/marius-sucan/ChurchBellsTower">on GitHub</a>.
    Gui, Font, Bold
    Gui, Add, Link, xp+30 y+10, To keep the development going, `n<a href="https://www.paypal.me/MariusSucan/15">please donate</a> or <a href="mailto:marius.sucan@gmail.com?subject=%appName% v%Version%">send me feedback</a>.
    Gui, Add, Picture, x+10 yp+0 gDonateNow hp w-1 +0xE hwndhDonateBTN, paypal.png

    Gui, Font, Normal
    Gui, Add, Button, xs+0 y+20 h30 w105 Default gCloseWindow, &Deus lux est
    Gui, Add, Button, x+5 hp w80 gShowOSDsettings, &Settings
    Gui, Add, Text, x+8 hp +0x200, v%Version% (%ReleaseDate%)
    Gui, Show, AutoSize, About %appName% v%Version%
    verifySettingsWindowSize()
    ColorPickerHandles := hDonateBTN "," hBellIcon
    Sleep, 25
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

INIsettings(a) {
  FirstRun := 0
  If (a=1) ; a=1 means save into INI
  {
     INIaction(1, "FirstRun", "SavedSettings")
     INIaction(1, "ReleaseDate", "SavedSettings")
     INIaction(1, "Version", "SavedSettings")
  }
  INIaction(a, "PrefsLargeFonts", "SavedSettings")
  INIaction(a, "tollQuarters", "SavedSettings")
  INIaction(a, "tollQuartersException", "SavedSettings")
  INIaction(a, "tollNoon", "SavedSettings")
  INIaction(a, "tollHours", "SavedSettings")
  INIaction(a, "tollHoursAmount", "SavedSettings")
  INIaction(a, "displayClock", "SavedSettings")
  INIaction(a, "silentHours", "SavedSettings")
  INIaction(a, "silentHoursA", "SavedSettings")
  INIaction(a, "silentHoursB", "SavedSettings")
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
  INIaction(a, "makeScreenDark", "SavedSettings")
  INIaction(a, "BibleQuotesInterval", "SavedSettings")
  INIaction(a, "SemantronHoliday", "SavedSettings")
  INIaction(a, "ObserveHolidays", "SavedSettings")
  INIaction(a, "UserReligion", "SavedSettings")
  INIaction(a, "LargeUIfontValue", "SavedSettings")

; OSD settings
  INIaction(a, "DisplayTimeUser", "OSDprefs")
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
    BinaryVar(makeScreenDark, 0)
    BinaryVar(SemantronHoliday, 0)
    BinaryVar(ObserveHolidays, 0)

; verify numeric values: min, max and default values
    MinMaxVar(DisplayTimeUser, 1, 99, 3)
    MinMaxVar(FontSize, 12, 300, 26)
    MinMaxVar(FontSizeQuotes, 10, 201, 20)
    MinMaxVar(GuiX, -9999, 9999, 40)
    MinMaxVar(GuiY, -9999, 9999, 250)
    MinMaxVar(OSDmarginTop, 1, 900, 20)
    MinMaxVar(OSDmarginBottom, 1, 900, 20)
    MinMaxVar(OSDmarginSides, 1, 900, 25)
    MinMaxVar(BeepsVolume, 0, 99, 45)
    MinMaxVar(strikeEveryMin, 1, 720, 5)
    MinMaxVar(silentHours, 1, 3, 1)
    MinMaxVar(silentHoursA, 0, 23, 12)
    MinMaxVar(silentHoursB, 0, 23, 14)
    MinMaxVar(LastNoon, 1, 4, 2)
    MinMaxVar(LargeUIfontValue, 10, 18, 13)
    MinMaxVar(UserReligion, 1, 2, 1)
    MinMaxVar(strikeInterval, 900, 5500, 2000)
    MinMaxVar(BibleQuotesInterval, 2, 12, 5)
    MinMaxVar(maxBibleLength, 20, 130, 55)
    MinMaxVar(OSDalpha, 24, 252, 230)
    If (silentHoursB<silentHoursA)
       silentHoursB := silentHoursA

; verify HEX values

   HexyVar(OSDbgrColor, "131209")
   HexyVar(OSDtextColor, "FFFEFA")

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
    OnMessage(0x4a, "")
    OnMessage(0x200, "")
    OnMessage(0x102, "")
    OnMessage(0x103, "")
    DllCall("wtsapi32\WTSUnRegisterSessionNotification", "Ptr", hMain)
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
  If (A_TickCount - lastExec<1900)
     Return
  Loop, 2
  {
    ahkthread_free(sndChanQ), sndChanQ := ""
    ahkthread_free(sndChanH), sndChanH := ""
    If (cleanAll=1)
    {
       ahkthread_free(sndChanS), sndChanS := ""
       ahkthread_free(sndChanA), sndChanA := ""
       ahkthread_free(sndChanJ), sndChanJ := ""
       ahkthread_free(sndChanN), sndChanN := ""
    }
    Sleep, 100
  }
  lastExec := A_TickCount
  If (bumpExec=1)
     timesExec++
  If (timesExec>3)
     ReloadScript()
}
