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
;@Ahk2Exe-SetVersion 1.7.6
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
 ; #Warn Debug
 ComObjError(false)
 SetTitleMatchMode, 2
 SetBatchLines, -1
 ListLines, Off
 SetWorkingDir, %A_ScriptDir%
 Critical, On

; Default Settings

 Global IniFile         := "bells-tower.ini"
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
 , BibleQuotesInterval  := 5
 , maxBibleLength       := 55

; OSD settings
 , displayTimeFormat      := 1
 , DisplayTimeUser        := 3     ; in seconds
 , OSDborder              := 0
 , GuiX                   := 40
 , GuiY                   := 250
 , GuiWidth               := 350
 , MaxGuiWidth            := A_ScreenWidth
 , FontName               := (A_OSVersion="WIN_XP") ? "Lucida Sans Unicode" : "Arial"
 , FontSize               := 26
 , PrefsLargeFonts        := 0
 , OSDbgrColor            := "131209"
 , OSDalpha               := 230
 , OSDtextColor           := "FFFEFA"
 , OSDsizingFactorW       := 0
 , OSDsizingFactor        := calcOSDresizeFactor("A",1)
 , OSDsizingFactorH       := 86

; Release info
 , ThisFile               := A_ScriptName
 , Version                := "1.7.6"
 , ReleaseDate            := "2018 / 10 / 23"
 , storeSettingsREG := FileExist("win-store-mode.ini") && A_IsCompiled && InStr(A_ScriptFullPath, "WindowsApps") ? 1 : 0
 , ScriptInitialized, FirstRun := 1
 , QuotesAlreadySeen := ""
 , LastNoon := 0, appName := "Church Bells Tower"
 , APPregEntry := "HKEY_CURRENT_USER\SOFTWARE\" appName "\v1-0"

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
      OSDsizingFactorW := calcOSDresizeFactor(0,2)
      INIsettings(1)
   }

; Initialization variables. Altering these may lead to undesired results.

Global Debug := 0    ; for testing purposes
 , CSthin      := "░"   ; light gray 
 , CSmid       := "▒"   ; gray 
 , CSdrk       := "▓"   ; dark gray
 , CSblk       := "█"   ; full block

 , DisplayTime := DisplayTimeUser*1000
 , GuiHeight := 50                    ; a default, later overriden
 , OSDvisible := 0
 , Tickcount_start2 := A_TickCount    ; timer to keep track of OSD redraws
 , Tickcount_start := 0               ; timer to count repeated key presses
 , MousePosition := ""
 , DoNotRepeatTimer := 0
 , PrefOpen := 0
 , FontList := []
 , actualVolume := 0
 , AdditionalStrikeFreq := strikeEveryMin * 60000  ; minutes
 , bibleQuoteFreq := BibleQuotesInterval * 3600000 ; hours
 , LargeUIfontValue := 13
 , ShowPreview := 0
 , ShowPreviewDate := 0
 , stopStrikesNow := 0
 , stopAdditionalStrikes := 0
 , strikingBellsNow := 0
 , CurrentDPI := A_ScreenDPI
 , AnyWindowOpen := 0
 , LastBibleQuoteDisplay := 1
 , CurrentPrefWindow := 0
 , ScriptelSuspendel := 0
 , StartRegPath := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
 , tickTockSound := A_ScriptDir "\sounds\ticktock.wav"
 , hBibleTxt, hBibleOSD, hOSD, OSDhandles, dragOSDhandles, ColorPickerHandles
 , hMain := A_ScriptHwnd
 , CCLVO := "-E0x200 +Border -Hdr -Multi +ReadOnly Report AltSubmit gsetColors"
 , hWinMM := DllCall("kernel32\LoadLibraryW", "Str", "winmm.dll", "Ptr")

; Initializations of the core components and functionality

If (A_IsCompiled && storeSettingsREG=0)
   VerifyFiles()

CreateOSDGUI()
Sleep, 5
SetMyVolume()
InitializeTray()

hCursM := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32646, "Ptr")  ; IDC_SIZEALL
hCursH := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32649, "Ptr")  ; IDC_HAND
OnMessage(0x200, "MouseMove")    ; WM_MOUSEMOVE
OnMessage(0x404, "AHK_NOTIFYICON")
OnMessage(0x11, "WM_ENDSESSION")
OnMessage(0x16, "WM_ENDSESSION")
Sleep, 5
If (tickTockNoise=1)
   SoundLoop(tickTockSound)
theChimer()
Sleep, 30
ScriptInitialized := 1      ; the end of the autoexec section and INIT
ShowHotkey(generateDateTimeTxt())
SetTimer, HideGUI, % -DisplayTime/2
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
  If (countFiles<11)
     FileRemoveDir, sounds, 1
  Sleep, 50
  FileCreateDir, sounds
  FileInstall, bible-quotes.txt, bible-quotes.txt
  FileInstall, bell-image.png, bell-image.png
  FileInstall, paypal.png, paypal.png
  FileInstall, sounds\ticktock.wav, sounds\ticktock.wav
  FileInstall, sounds\auxilliary-bell.wav, sounds\auxilliary-bell.wav
  FileInstall, sounds\japanese-bell.wav, sounds\japanese-bell.wav
  FileInstall, sounds\quarters.wav, sounds\quarters.wav
  FileInstall, sounds\hours.wav, sounds\hours.wav
  FileInstall, sounds\evening.mp3, sounds\evening.mp3
  FileInstall, sounds\noon1.mp3, sounds\noon1.mp3
  FileInstall, sounds\noon2.mp3, sounds\noon2.mp3
  FileInstall, sounds\noon3.mp3, sounds\noon3.mp3
  FileInstall, sounds\morning.wav, sounds\morning.wav
  FileInstall, sounds\midnight.wav, sounds\midnight.wav
  Sleep, 300
}

AHK_NOTIFYICON(wParam, lParam, uMsg, hWnd) {
  If (PrefOpen=1 || A_IsSuspended)
     Return
  If (lParam = 0x201) || (lParam = 0x204)
  {
     stopStrikesNow := 1
     strikingBellsNow := 0
     If (lParam = 0x204)
        ShowHotkey(generateDateTimeTxt())
     Else
        ShowHotkey(generateDateTimeTxt(1,1))
     SetTimer, HideGUI, % -DisplayTime/1.5
  } Else If (lParam = 0x207) && (strikingBellsNow=0)
  {
     SetMyVolume(1)
     ShowHotkey(generateDateTimeTxt())
     SetTimer, HideGUI, % -DisplayTime/1.5
     If (tollQuarters=1)
        strikeQuarters()
     If (tollHours=1 || tollHoursAmount=1)
        strikeHours()
  } Else If (OSDvisible=0 && strikingBellsNow=0)
  {
     ShowHotkey(generateDateTimeTxt(0))
     SetTimer, HideGUI, % -DisplayTime/1.5
  }
}

InvokeBibleQuoteNow() {
  Static bibleQuotesFile
  
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
     countLines := st_count(bibleQuotesFile, "`n") + 1
     Loop
     {
       Random, Line2Read, 1, %countLines%
       If !InStr(QuotesAlreadySeen, "a" Line2Read "a")
          stopLoop := 1
     } Until (stopLoop=1 || A_Index>712)
  } Else Line2Read := "R"
 ;  FileReadLine, bibleQuote, bible-quotes.txt, %LineRead%
  bibleQuote := ST_ReadLine(bibleQuotesFile, Line2Read)
  QuotesAlreadySeen .= "a" Line2Read "a"
  StringReplace, QuotesAlreadySeen, QuotesAlreadySeen, aa, a
  StringRight, QuotesAlreadySeen, QuotesAlreadySeen, 95
  If (StrLen(bibleQuote)>6)
     CreateBibleGUI(bibleQuote)
  If (PrefOpen!=1)
  {
     SetMyVolume(1)
     INIaction(1, "QuotesAlreadySeen", "SavedSettings")
     SoundPlay, sounds\japanese-bell.wav, 1
  }
  quoteDisplayTime := (PrefOpen=1) ? DisplayTime*1.5 : StrLen(bibleQuote) * 123
  SetTimer, DestroyBibleGui, % -quoteDisplayTime
}

DestroyBibleGui() {
  Gui, BibleGui: Destroy
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

RandomNumberCalc(minVariation:=250,maxVariation:=500) {
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
  ahkdll1 := AhkThread("#NoTrayIcon`nSoundPlay, sounds\quarters.wav, 1") 
  If (PrefOpen!=1)
     Sleep, % strikeInterval + sleepDelay
  Else
     Sleep, 600
}

strikeHours() {
  If (stopStrikesNow=1)
     Return
  sleepDelay := RandomNumberCalc()
  ahkdll2 := AhkThread("#NoTrayIcon`nSoundPlay, sounds\hours.wav, 1") 
  If (PrefOpen!=1)
     Sleep, % strikeInterval + sleepDelay
}

TollExtraNoon() {
  Static lastToll := 1
  If (AnyWindowOpen=1)
     stopStrikesNow := 0
  If (stopStrikesNow=1 || PrefOpen=1)
  || ((A_TickCount - lastToll<100000) && (AnyWindowOpen=1))
     Return
  ahkdll3 := AhkThread("#NoTrayIcon`nRandom, choice, 1, 3`nSoundPlay, sounds\noon%choice%.mp3, 1")
  lastToll := A_TickCount
}

AdditionalStriker() {
  If (stopAdditionalStrikes=1 || A_IsSuspended || PrefOpen=1 || strikingBellsNow=1)
     Return
  SetMyVolume(1)
  SoundPlay, sounds\auxilliary-bell.wav, 1
}

theChimer() {
  Critical, on
  Static lastChimed
  FormatTime, CurrentTime,, hh:mm
  
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
     SetTimer, theChimer, % ((15 - Mod(A_Min, 15)) * 60 - A_Sec) * 1000 - A_MSec + 50      ; formula provided by Bon [AHK forums]
     Return
  }

  SoundGet, master_vol
  stopStrikesNow := stopAdditionalStrikes := 0
  strikingBellsNow := 1
  If (displayClock=1)
     SetTimer, HideGUI, % -DisplayTime

  Random, delayRandNoon, 950, 5050
  If (InStr(exactTime, "06:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1 && tollHours=0)
        ShowHotkey(generateDateTimeTxt(1,1))
     SoundPlay, sounds\morning.wav, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
  } Else If (InStr(exactTime, "18:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1 && tollHours=0)
        ShowHotkey(generateDateTimeTxt(1,1))
     If (BeepsVolume>1)
        SoundPlay, sounds\evening.mp3, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
  } Else If (InStr(exactTime, "00:00") && tollNoon=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1 && tollHours=0)
        ShowHotkey(generateDateTimeTxt(1,1))
     SoundPlay, sounds\midnight.wav, 1
     If (stopStrikesNow=0)
        Sleep, %delayRandNoon%
  }

  If (InStr(CurrentTime, ":15") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        ShowHotkey(generateDateTimeTxt(1,1))
     strikeQuarters()
  } Else If (InStr(CurrentTime, ":30") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        ShowHotkey(generateDateTimeTxt(1,1))
     Loop, 2
        strikeQuarters()
  } Else If (InStr(CurrentTime, ":45") && tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        ShowHotkey(generateDateTimeTxt(1,1))
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
           ShowHotkey(generateDateTimeTxt(1,1))
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
           ShowHotkey(generateDateTimeTxt(1,1))
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
           ShowHotkey(generateDateTimeTxt(1,1))
        strikeHours()
     }

     If (InStr(exactTime, "12:0") && tollNoon=1)
     {
        Random, delayRand, 2000, 8500
        If (stopStrikesNow=0)
           Sleep, %delayRand%
        volumeAction := SetMyVolume()
        choice := (LastNoon=3) ? 1 : LastNoon + 1
        If (storeSettingsREG=0)
           IniWrite, %choice%, %IniFile%, SavedSettings, LastNoon
        Else
           RegWrite, REG_SZ, %APPregEntry%, LastNoon, %choice%

        If (displayClock=1 && tollHours=0)
           ShowHotkey(generateDateTimeTxt(1,1))

        If (stopStrikesNow=0 && ScriptInitialized=1 && volumeAction>0 && BeepsVolume>1)
        {
           SoundPlay, sounds\noon%choice%.mp3, 1
        } Else If (stopStrikesNow=0 && BeepsVolume>1)
        {
           Random, newDelay, 35000, 85000
           SoundPlay, sounds\noon%choice%.mp3
           If (A_WDay=1)  ; on Sundays
              SetTimer, TollExtraNoon, % -newDelay
        }
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
  SetTimer, theChimer, % ((15 - Mod(A_Min, 15)) * 60 - A_Sec) * 1000 - A_MSec + 50      ; formula provided by Bon [AHK forums]
}

calcOSDresizeFactor(given,retour:=0) {
  SizingFactor := Round(A_ScreenDPI / 1.1 - FontSize/30)
  OSDsizeW := Round(10000/SizingFactor)
  If (given>0)
     OSDsizingFactor := Round(10000/given)
  Else If (given="A")
     OSDsizingFactorW := Round(10000/SizingFactor)

  If (retour=1)
     Return SizingFactor
  Else If (retour=2)
     Return OSDsizeW
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

CreateBibleGUI(msg2Display) {
    Critical, Off
    FontSizeMin := Round(FontSize*0.6)
    If (FontSizeMin<9)
       FontSizeMin := 9
    msg2Display := ST_wordWrap(msg2Display, maxBibleLength)
    Gui, BibleGui: Destroy
    Sleep, 125
    LastBibleQuoteDisplay := A_TickCount
    Gui, BibleGui: -DPIScale -Caption +HwndhBibleOSD
    Gui, BibleGui: Margin, 20, 20
    Gui, BibleGui: Color, %OSDbgrColor%
    Gui, BibleGui: Font, c%OSDtextColor% s%FontSizeMin% Bold, %FontName%
    Gui, BibleGui: Add, Text, hwndhBibleTxt, %msg2Display%
    Gui, BibleGui: Show, NoActivate AutoSize x%GuiX% y%GuiY%, ChurchTowerBibleWin
    WinSet, Transparent, %OSDalpha%, ChurchTowerBibleWin
    WinSet, AlwaysOnTop, On, ChurchTowerBibleWin
}

CreateOSDGUI() {
    Global
    Critical, off
    Gui, OSD: Destroy
    Sleep, 125
    Gui, OSD: +AlwaysOnTop -Caption +Owner +LastFound +ToolWindow +HwndhOSD
    Gui, OSD: Margin, 20, 10
    Gui, OSD: Color, %OSDbgrColor%
    If (ShowPreview=0 || PrefOpen=0)
       Gui, OSD: Font, c%OSDtextColor% s%FontSize% Bold, %FontName%, -wrap
    Else
       Gui, OSD: Font, c%OSDtextColor%, -wrap

    Gui, OSD: Font, c%OSDbgrColor% s%FontSize% Bold,
    Gui, OSD: Add, Text, w20, lol
    Gui, OSD: Font, c%OSDtextColor%, -wrap
    Gui, OSD: Add, Text, xp yp -wrap w20 vHotkeyText hwndhOSDctrl, %HotkeyText%

    If (OSDborder=1)
    {
        WinSet, Style, +0xC40000
        WinSet, Style, -0xC00000
        WinSet, Style, +0x800000   ; small border
    }
    WinSet, Transparent, %OSDalpha%
    Gui, OSD: Show, NoActivate Hide x%GuiX% y%GuiY%, ChurchTowerWin  ; required for initialization when Drag2Move is active
    OSDhandles := hOSD "," hOSDctrl "," hOSDind1 "," hOSDind2 "," hOSDind3 "," hOSDind4
    dragOSDhandles := hOSDind1 "," hOSDind2 "," hOSDind3 "," hOSDind4
}

ShowHotkey(string) {
;  Sleep, 70 ; megatest

    Global Tickcount_start2 := A_TickCount
    Text_width := GetTextExtentPoint(string, FontName, FontSize) / (OSDsizingFactor/100)
    Text_width := Round(Text_width)
    GuiControl, OSD: , HotkeyText, %string%
    GuiControl, OSD: Move, HotkeyText, % " w" Text_width*2 " h" GuiHeight*2

    Gui, OSD: Show, NoActivate x%GuiX% y%GuiY% w%Text_width% h%GuiHeight%, ChurchTowerWin
    WinSet, AlwaysOnTop, On, ChurchTowerWin
    OSDvisible := 1
}

HideGUI() {
    OSDvisible := 0
    Gui, OSD: Hide
}

GetTextExtentPoint(sString, sFaceName, nHeight, initialStart := 0) {
; Function by Sean from:
; https://autohotkey.com/board/topic/16414-hexview-31-for-stdlib/#entry107363
; modified by Marius Șucan and Drugwash

  If (!sString || StrLen(sString)<4)
     sString := "LOLA"

  hDC := DllCall("user32\GetDC", "Ptr", 0, "Ptr")
  nHeight := -DllCall("kernel32\MulDiv", "Int", nHeight, "Int", DllCall("gdi32\GetDeviceCaps", "Ptr", hDC, "Int", 90), "Int", 72)
  hFont := DllCall("gdi32\CreateFontW"
    , "Int", nHeight
    , "Int", 0    ; nWidth
    , "Int", 0    ; nEscapement
    , "Int", 0    ; nOrientation
    , "Int", 700  ; fnWeight
    , "UInt", 0   ; fdwItalic
    , "UInt", 0   ; fdwUnderline
    , "UInt", 0   ; fdwStrikeOut
    , "UInt", 0   ; fdwCharSet
    , "UInt", 0   ; fdwOutputPrecision
    , "UInt", 0   ; fdwClipPrecision
    , "UInt", 0   ; fdwQuality
    , "UInt", 0   ; fdwPitchAndFamily
    , "Str", sFaceName
    , "Ptr")

  hFold := DllCall("gdi32\SelectObject", "Ptr", hDC, "Ptr", hFont, "Ptr")
  DllCall("gdi32\GetTextExtentPoint32W", "Ptr", hDC, "Str", sString, "Int", StrLen(sString), "Int64P", nSize)
  DllCall("gdi32\SelectObject", "Ptr", hDC, "Ptr", hFold)
  DllCall("gdi32\DeleteObject", "Ptr", hFont)
  DllCall("user32\ReleaseDC", "Ptr", 0, "Ptr", hDC)
  SetFormat, Integer, D
  minWidth := FontSize*5
  nWidth := nSize & 0xFFFFFFFF
  nWidth := (nWidth<minWidth) ? minWidth : Round(nWidth) + 20

  heightUnit := 7 + Round(FontSize/16)
  minHeight := Round(FontSize*1.55)
  If (minHeight<heightUnit*3.5)
     minHeight := Round(heightUnit*3.5)
  maxHeight := Round(FontSize*3.1)
  If (minHeight>maxHeight)
     maxHeight := minHeight
  HeightScalingFactor := OSDsizingFactorH/100
  GuiHeight := nSize >> 32 & 0xFFFFFFFF
  GuiHeight := GuiHeight / (OSDsizingFactor/100) + (OSDsizingFactor/10) + 4
  GuiHeight := (GuiHeight<minHeight) ? minHeight+1 : Round(GuiHeight)
  GuiHeight := (GuiHeight>maxHeight) ? maxHeight-1 : Round(GuiHeight)
  GuiHeight := Round(GuiHeight*HeightScalingFactor)+Round(heightUnit*0.4)

  Return nWidth
}

GuiGetSize(ByRef W, ByRef H, vindov) {
; function by VxE from https://autohotkey.com/board/topic/44150-how-to-properly-getset-gui-size/
; Sleep, 60 ; megatest

  If (vindov=0)
     Gui, OSDghost: +LastFoundExist
  If (vindov=1)
     Gui, OSD: +LastFoundExist
  If (vindov=5)
     Gui, SettingsGUIA: +LastFoundExist
  VarSetCapacity(rect, 16, 0)
  DllCall("user32\GetClientRect", "Ptr", MyGuiHWND := WinExist(), "Ptr", &rect)
  W := NumGet(rect, 8, "UInt")
  H := NumGet(rect, 12, "UInt")
}


MouseMove(wP, lP, msg, hwnd) {
; Function by Drugwash
  Global
  Local A
  SetFormat, Integer, H
  hwnd+=0, A := WinExist("A"), hwnd .= "", A .= ""
  SetFormat, Integer, D

  If InStr(OSDhandles, hwnd)
  {
        Tickcount_start2 := A_TickCount
        If (PrefOpen=0)
           HideGUI()
        DllCall("user32\SetCursor", "Ptr", hCursM)
        If !(wP&0x13)    ; no LMR mouse button is down, we hover
        {
           If A not in %OSDhandles%
              hAWin := A
           Else HideGUI()
        } Else If (wP&0x1)  ; L mouse button is down, we're dragging
        {
           SetTimer, HideGUI, Off
           While GetKeyState("LButton", "P")
           {
              PostMessage, 0xA1, 2,,, ahk_id %hOSD%
              DllCall("user32\SetCursor", "Ptr", hCursM)
           }
           SetTimer, trackMouseDragging, -1
           Sleep, 0
        } Else If ((wP&0x2) || (wP&0x10))
           HideGUI()
  } Else If ColorPickerHandles
  {
     If hwnd in %ColorPickerHandles%
        DllCall("user32\SetCursor", "Ptr", hCursH)
  }

  If (InStr(hwnd, hBibleOSD) || InStr(hwnd, hBibleTxt))
  {
     If (A_TimeIdle<100) && (A_TickCount - LastBibleQuoteDisplay>900)
        Gui, BibleGui: Destroy
  }
}

trackMouseDragging() {
; Function by Drugwash
  Global
  WinGetPos, NewX, NewY,,, ahk_id %hOSD%

  GuiX := !NewX ? "2" : NewX
  GuiY := !NewY ? "2" : NewY

  If hAWin
  {
     If hAWin not in %OSDhandles%
        WinActivate, ahk_id %hAWin%
  }

  GuiControl, OSD: Enable, Edit1
  saveGuiPositions()
}

saveGuiPositions() {
; function called after dragging the OSD to a new position

  If (PrefOpen=0)
  {
     Sleep, 700
     SetTimer, HideGUI, -1500
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
     ShowHotkey("Enabled Start at Boot")
  } Else
  {
     RegDelete, %StartRegPath%, %appName%
     Menu, Tray, Uncheck, Sta&rt at boot
     ShowHotkey("Disabled Start at Boot")
  }
  SetTimer, HideGUI, % -DisplayTime
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
   If !A_IsSuspended
   {
      stopStrikesNow := 1
      ScriptelSuspendel := 1
      SetTimer, theChimer, Off
      SetTimer, AdditionalStriker, Off
      Menu, Tray, Uncheck, &%appName% activated
      SoundLoop("")
   } Else
   {
      stopStrikesNow := 0
      ScriptelSuspendel := 0
      Menu, Tray, Check, &%appName% activated
      If (tickTockNoise=1)
         SoundLoop(tickTockSound)
      SetTimer, theChimer, 100
      If (AdditionalStrikes=1)
         SetTimer, AdditionalStriker, %AdditionalStrikeFreq%
   }
   SoundPlay, non-existent.lol
   CreateOSDGUI()
   friendlyName := A_IsSuspended ? " activated" : " deactivated"
   ShowHotkey(appName friendlyName)

   Sleep, 50
   SetTimer, HideGUI, % -DisplayTime/2
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
    If FileExist("sounds\ticktock.wav")
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
    INIaction(1, "PrefsLargeFonts", "SavedSettings")
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

    CreateOSDGUI()
    If FileExist(ThisFile)
    {
        If (silent!=1)
           ShowHotkey("Restarting...")
        Cleanup()
        Try Reload
        Sleep, 70
        ExitApp
    } Else
    {
        ShowHotkey("FATAL ERROR: Main file missing. Execution terminated.")
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
    MsgBox, 4,, Are you sure you want to delete the stored settings?
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
      ShowHotkey("Bye byeee :-)")
      Sleep, 350
   } Else If showMSG
   {
      ShowHotkey("Adiiooosss :-(((")
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
   Gui, SettingsGUIA: -MaximizeBox
   Gui, SettingsGUIA: -MinimizeBox
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

verifySettingsWindowSize() {
    If (PrefsLargeFonts=0) || (A_TickCount-DoNotRepeatTimer<40000)
       Return
    GuiGetSize(Wid, Heig, 5)
    SysGet, SM_CXMAXIMIZED, 61
    SysGet, SM_CYMAXIMIZED, 62
    If (Heig>SM_CYMAXIMIZED-75) || (Wid>SM_CXMAXIMIZED-50)
    {
       Global DoNotRepeatTimer := A_TickCount
       SoundBeep, 300, 900
       MsgBox, 4,, The option "Large UI fonts" is enabled. The window seems to exceed your screen resolution. `nDo you want to disable Large UI fonts?
       IfMsgBox, Yes
       {
           ToggleLargeFonts()
           If (PrefOpen=1)
              SwitchPreferences(1)
           Else If (AnyWindowOpen=1)
              AboutWindow()
       }
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
    If (CurrentPrefWindow!=5)
       HideGUI()
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
  CreateOSDGUI()
  Sleep, 100
  OSDpreview()
}

UpdateFntNow() {
  Global
  Fnt_DeleteFont(hfont)
  fntOptions := "s" FontSize " Bold Q5"
  hFont := Fnt_CreateFont(FontName,fntOptions)
  Fnt_SetFont(hOSDctrl,hfont,true)
}

OSDpreview() {
  Static LastBorderState
    Gui, SettingsGUIA: Submit, NoHide
    If (ShowPreview=0)
    {
       HideGUI()
       Return
    }

    Sleep, 25
    ; CreateOSDGUI()
    UpdateFntNow()
    calcOSDresizeFactor(OSDsizingFactorW)
    ShowHotkey(generateDateTimeTxt(1, !ShowPreviewDate))
    WinSet, Transparent, %OSDalpha%, ChurchTowerWin
    If (OSDborder=1 && LastBorderState!=OSDborder)
    {
       WinSet, Style, +0xC40000, ChurchTowerWin
       WinSet, Style, -0xC00000, ChurchTowerWin
       LastBorderState := OSDborder
    } Else If (OSDborder=0)
       WinSet, Style, -0xC40000, ChurchTowerWin
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

ResetOSDsizeFactor() {
  Random, RandNumber, 85, 95
  GuiControl, , editF9, % calcOSDresizeFactor("A",2)
  GuiControl, , editF11, %RandNumber%
}

ShowOSDsettings() {
    doNotOpen := initSettingsWindow()
    If (doNotOpen=1)
       Return

    If ShowPreview             ; If OSD is already visible don't hide/show it,
       SetTimer, HideGUI, Off  ; just update the text (avoids the flicker)
    Global CurrentPrefWindow := 5
    Global DoNotRepeatTimer := A_TickCount
    Global editF1, editF2, editF3, editF4, editF5, editF6, Btn1, volLevel, editF40, editF60, Btn2, txt4
         , editF7, editF8, editF9, editF10, editF11, editF35, editF36, editF37, editF38, Btn2, txt1, txt2, txt3
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
    Gui, Add, Checkbox, y+10 gVerifyOsdOptions Checked%tollQuarters% vtollQuarters, Strike quarter-hours
    Gui, Add, Checkbox, x+10 gVerifyOsdOptions Checked%tollQuartersException% vtollQuartersException, ... except on the hour
    Gui, Add, Checkbox, xs y+10 gVerifyOsdOptions Checked%tollHours% vtollHours, Strike on the hour
    Gui, Add, Checkbox, x+10 gVerifyOsdOptions Checked%tollHoursAmount% vtollHoursAmount, ... the number of hours
    Gui, Add, Checkbox, xs y+10 gVerifyOsdOptions Checked%displayClock% vdisplayClock, Display time on screen when bells toll
    Gui, Add, Checkbox, x+10 gVerifyOsdOptions Checked%displayTimeFormat% vdisplayTimeFormat, 24 hours format
    Gui, Add, Checkbox, xs y+10 gVerifyOsdOptions Checked%AdditionalStrikes% vAdditionalStrikes, Additional strike every (in minutes)
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF38, %strikeEveryMin%
    Gui, Add, UpDown, gVerifyOsdOptions vstrikeEveryMin Range1-720, %strikeEveryMin%
    Gui, Add, Checkbox, xs y+7 gVerifyOsdOptions Checked%showBibleQuotes% vshowBibleQuotes, Show a Bible quote every (in hours)
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF40, %BibleQuotesInterval%
    Gui, Add, UpDown, gVerifyOsdOptions vBibleQuotesInterval Range3-11, %BibleQuotesInterval%
    Gui, Add, Text, xs y+10, Interval between tower strikes (in miliseconds):
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit5 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF37, %strikeInterval%
    Gui, Add, UpDown, gVerifyOsdOptions vstrikeInterval Range500-5500, %strikeInterval%
    Gui, Add, DropDownList, xs y+10 w270 gVerifyOsdOptions AltSubmit Choose%silentHours% vsilentHours, Limit chimes to specific periods...|Play chimes only...|Keep silence...
    Gui, Add, Text, xp+15 y+6 hp +0x200 vtxt1, from
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF35, %silentHoursA%
    Gui, Add, UpDown, gVerifyOsdOptions vsilentHoursA Range0-23, %silentHoursA%
    Gui, Add, Text, x+1 hp  +0x200 vtxt2, :00   to
    Gui, Add, Edit, x+10 w65 geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF36, %silentHoursB%
    Gui, Add, UpDown, gVerifyOsdOptions vsilentHoursB Range0-23, %silentHoursB%
    Gui, Add, Text, x+1 hp  +0x200 vtxt3, :59

    Gui, Tab, 2 ; style
    Gui, Add, Text, x+15 y+15 Section, OSD position (x, y)
    Gui, Add, Edit, xs+%columnBpos2% ys w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF1, %GuiX%
    Gui, Add, UpDown, vGuiX gVerifyOsdOptions 0x80 Range-9995-9998, %GuiX%
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF2, %GuiY%
    Gui, Add, UpDown, vGuiY gVerifyOsdOptions 0x80 Range-9995-9998, %GuiY%

    Gui, Add, Text, xm+15 ys+30 Section, Height and width scaling
    Gui, Add, Edit, xs+%columnBpos2% ys+0 Section w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF11, %OSDsizingFactorH%
    Gui, Add, UpDown, gVerifyOsdOptions vOSDsizingFactorH Range12-350, %OSDsizingFactorH%
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF9 , %OSDsizingFactorW%
    Gui, Add, UpDown, gVerifyOsdOptions vOSDsizingFactorW Range12-350, %OSDsizingFactorW%
    Gui, Add, Button, x+5 w25 hp gResetOSDsizeFactor, R

    Gui, Add, Text, xm+15 y+10 Section, Font name
    Gui, Add, Text, xs yp+30, OSD colors and opacity
    Gui, Add, Text, xs yp+30, Font size
    Gui, Add, Text, xs yp+30, Display time (in sec.)
    Gui, Add, Text, xs yp+30 vTxt4, Max. line length, for Bible quotes
    Gui, Add, Checkbox, y+9 gVerifyOsdOptions Checked%OSDborder% vOSDborder, System border around OSD
    Gui, Add, Checkbox, xs yp+35 h30 +0x1000 gVerifyOsdOptions Checked%ShowPreview% vShowPreview, Show preview window
    Gui, Add, Checkbox, y+5 hp gVerifyOsdOptions Checked%ShowPreviewDate% vShowPreviewDate, Include current date into preview

    Gui, Add, DropDownList, xs+%columnBpos2% ys+0 section w205 gVerifyOsdOptions Sort Choose1 vFontName, %FontName%
    Gui, Add, ListView, xp+0 yp+30 w55 h25 %CCLVO% Background%OSDtextColor% vOSDtextColor hwndhLV1,
    Gui, Add, ListView, xp+60 yp w55 h25 %CCLVO% Background%OSDbgrColor% vOSDbgrColor hwndhLV2,
    Gui, Add, Edit, x+5 yp+0 w55 hp geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF10, %OSDalpha%
    Gui, Add, UpDown, vOSDalpha gVerifyOsdOptions Range25-250, %OSDalpha%
    Gui, Add, Edit, xp-120 yp+30 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF5, %FontSize%
    Gui, Add, UpDown, gVerifyOsdOptions vFontSize Range12-295, %FontSize%
    Gui, Add, Edit, xp+0 yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF6, %DisplayTimeUser%
    Gui, Add, UpDown, vDisplayTimeUser gVerifyOsdOptions Range1-99, %DisplayTimeUser%
    Gui, Add, Edit, xp+0 yp+30 w55 hp geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF60, %maxBibleLength%
    Gui, Add, UpDown, vmaxBibleLength gVerifyOsdOptions Range10-130, %maxBibleLength%
    Gui, Add, Button, x+5 hp gInvokeBibleQuoteNow vBtn2, Preview quote
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
    GuiControlGet, OSDsizingFactor
    GuiControlGet, silentHours
    GuiControlGet, tollHours
    GuiControlGet, tollQuarters
    GuiControlGet, AdditionalStrikes
    GuiControlGet, showBibleQuotes

    GuiControl, % (EnableApply=0 ? "Disable" : "Enable"), ApplySettingsBTN
    GuiControl, % (AdditionalStrikes=0 ? "Disable" : "Enable"), editF38
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF40
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), editF60
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Btn2
    GuiControl, % (showBibleQuotes=0 ? "Disable" : "Enable"), Txt4
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

    Static LastInvoked := 1

    If (OSDsizingFactorW>398 || OSDsizingFactorW<12)
       GuiControl, , editF9, % calcOSDresizeFactor("A",2)

    If (A_TickCount - LastInvoked>200) || (OSDvisible=0 && ShowPreview=1)
    || (OSDvisible=1 && ShowPreview=0)
    {
       LastInvoked := A_TickCount
       OSDpreview()
    }
}

trimArray(arr) { ; Hash O(n) 
; Function by errorseven from:
; https://stackoverflow.com/questions/46432447/how-do-i-remove-duplicates-from-an-autohotkey-array
    hash := {}, newArr := []
    For e, v in arr
        If (!hash.Haskey(v))
            hash[(v)] := 1, newArr.push(v)
    Return newArr
}

DonateNow() {
   Run, https://www.paypal.me/MariusSucan/10
   CloseWindow()
}

HowLong(FromDay,ToDay) {
; function from: https://autohotkey.com/boards/viewtopic.php?f=6&t=54796
; by Jack Dunning modified by Marius Șucan

   Static Years,Months,Days

; Trim any time component from the input dates
   FromDay := SubStr(FromDay,1,8)
   ToDay := SubStr(ToDay,1,8)
;   Tooltip, %FromDay% -- %today%

; For proper date order before calculation
   If (ToDay <= FromDay)
      Return 0

; Calculate years
   Years := % SubStr(ToDay,5,4) - SubStr(FromDay,5,4) < 0 ? SubStr(ToDay,1,4)-SubStr(FromDay,1,4)-1 
         : SubStr(ToDay,1,4)-SubStr(FromDay,1,4)

; Remove years from the calculation
   FromYears := Substr(FromDay,1,4)+years . SubStr(FromDay,5,4)

/*
   Calculate the number of months between the Start date (Years removed)
   and the Stop date. If the day of the month in the Start date is greater than
   the day of the month in the Stop date, then add 11 or 12 months to the 
   calculation depending upon the comparison between month days.
*/

   If (Substr(FromYears,5,2) <= Substr(ToDay,5,2)) and (Substr(FromYears,7,2) <= Substr(ToDay,7,2))
      Months := Substr(ToDay,5,2) - Substr(FromYears,5,2)
   Else If (Substr(FromYears,5,2) < Substr(ToDay,5,2)) and (Substr(FromYears,7,2) > Substr(ToDay,7,2))
      Months := Substr(ToDay,5,2) - Substr(FromYears,5,2) - 1
   Else If (Substr(FromYears,5,2) > Substr(ToDay,5,2)) and (Substr(FromYears,7,2) <= Substr(ToDay,7,2))
      Months := Substr(ToDay,5,2) - Substr(FromYears,5,2) +12
   Else If (Substr(FromYears,5,2) >= Substr(ToDay,5,2)) and (Substr(FromYears,7,2) > Substr(ToDay,7,2))
      Months := Substr(ToDay,5,2) - Substr(FromYears,5,2) +11

; If the start day of the month is less than the stop day of the month use the same month
; Otherwise use the previous month, (If Jan "01" use Dec "12")
 
    If (Substr(FromYears,7,2) <= Substr(ToDay,7,2))
       FromMonth := Substr(ToDay,1,4) . SubStr(ToDay,5,2) . Substr(FromDay,7,2)
    Else If Substr(ToDay,5,2) = "01"
       FromMonth := Substr(ToDay,1,4)-1 . "12" . Substr(FromDay,7,2)
    Else
       FromMonth := Substr(ToDay,1,4) . Format("{:02}", SubStr(ToDay,5,2)-1) . Substr(FromDay,7,2)

; FromMonth := Substr(ToDay,1,4) . Substr("0" . SubStr(ToDay,5,2)-1,-1) . Substr(FromDay,7,2)
; "The Format("{:02}",  SubStr(ToDay,5,2)-1)" function replaces the original "Substr("0" . SubStr(ToDay,5,2)-1,-1)"
; function found in the line of code above. Both serve the same purpose, although the original function
; uses sleight of hand to pad single digit months with a zero (0).

; Adjust for previous months with less days than target day
   Date1 := Substr(FromMonth,1,6) . "01"
   Date2 := Substr(ToDay,1,6) . "01"
   Date2 -= Date1, Days
   If (Date2 < Substr(FromDay,7,2)) and (Date2 != 0)
      FromMonth := Substr(FromMonth,1,6) . Date2

; Calculate remaining days. This operation (EnvSub) changes the value of the original 
; ToDay variable, but, since this completes the function, we don't need to save ToDay 
; in its original form. 

   ToDay -= %FromMonth% , d
   Days := ToDay
   
   DayNoun := (Days>1) ? " and " Days " days" : " and " Days " day"
   If (Days=0)
      DayNoun := ""

   Weeksz := Round(Days/7,1)

   If (Years>0)
      Return 0
   If (Months>1)
      Result := Months " months" DayNoun
   Else If (Months=1 && Weeksz>1)
      Result := "1 month and " Weeksz " weeks" 
   Else If (Months=1 && Weeksz<1)
      Result := "1 month and a few days"
   Else If (Months<=0) && (Days>1)
   {
      If (Weeksz>1)
      {
         If (Round(Weeksz)>Floor(Weeksz))
            Result := "More than " Floor(Weeksz) " weeks"
         Else
            Result := Floor(Weeksz) " weeks"
      } Else
         Result := "Less than a week"
      ; Result := Days " days"
   }
   Else Return 0

   Return Result
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
  Return, output
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

    FormatTime, CurrentDateTime,, yyyyMMdd
    FormatTime, CurrentYear,, yyyy

    Random, RandyDay, 19, 21
    MarchEquinox := CurrentYear "0320"
    Random, RandyDay, 21, 24
    SeptemberEquinox := CurrentYear "0922"
    Random, RandyDay, 20, 22
    JuneSolstice := CurrentYear "0621"
    Random, RandyDay, 20, 22
    DecemberSolstice := CurrentYear "1221"

    resultMarchEquinox := HowLong(CurrentDateTime,MarchEquinox)
    If !resultMarchEquinox
    {
       resultMarchEquinox := HowLong(MarchEquinox,CurrentDateTime)
       If !resultMarchEquinox
          resultMarchEquinox := "The March equinox is here!"
       Else
          resultMarchEquinox .= " since the March equinox."
    } Else
       resultMarchEquinox .= " until the March equinox."

    resultJuneSolstice := HowLong(CurrentDateTime,JuneSolstice)
    If !resultJuneSolstice
    {
       resultJuneSolstice := HowLong(JuneSolstice,CurrentDateTime)
       If !resultJuneSolstice
          resultJuneSolstice := "The June solstice is here!"
       Else
          resultJuneSolstice .= " since the June solstice."
    } Else
       resultJuneSolstice .= " until the June solstice."

    resultSeptemberEquinox := HowLong(CurrentDateTime,SeptemberEquinox)
    If !resultSeptemberEquinox
    {
       resultSeptemberEquinox := HowLong(SeptemberEquinox,CurrentDateTime)
       If !resultSeptemberEquinox
          resultSeptemberEquinox := "The September equinox is here!"
       Else
          resultSeptemberEquinox .= " since the September equinox."
    } Else
       resultSeptemberEquinox .= " until the September equinox."

    resultDecemberSolstice := HowLong(CurrentDateTime,DecemberSolstice)
    If !resultDecemberSolstice
    {
       resultDecemberSolstice := HowLong(DecemberSolstice,CurrentDateTime)
       If !resultDecemberSolstice
          resultDecemberSolstice := "The December solstice is here!"
       Else
          resultDecemberSolstice .= " since the December solstice."
    } Else
       resultDecemberSolstice .= " until the December solstice."

    percentileYear := Round(A_YDay/366*100) "%"

    FormatTime, CurrentDateTime,, yyyyMMddHHmm
    FormatTime, CurrentDay,, yyyyMMdd
    FirstMinOfDay := CurrentDay "0001"
    EnvSub, CurrentDateTime, %FirstMinOfDay%, Minutes
    minsPassed := CurrentDateTime
    percentileDay := Round(minsPassed/1440*100) "%"

    Gui, Add, Text, x15 y+20 w%txtWid% Section, Dedicated to Christians, church-goers and bell lovers.
    If (resultMarchEquinox ~= "until|here")
       Gui, Font, Bold
    If !(resultMarchEquinox ~= "month")
       Gui, Add, Text, y+7 w%txtWid%, %resultMarchEquinox%
    Gui, Font, Normal
    If (resultJuneSolstice ~= "until|here")
       Gui, Font, Bold
    If !(resultJuneSolstice ~= "month")
       Gui, Add, Text, y+7 w%txtWid%, %resultJuneSolstice%
    Gui, Font, Normal
    If (resultSeptemberEquinox ~= "until|here")
       Gui, Font, Bold
    Gui, Font, Normal
    If !(resultSeptemberEquinox ~= "month")
       Gui, Add, Text, y+7 w%txtWid%, %resultSeptemberEquinox%
    Gui, Font, Normal
    If (resultDecemberSolstice ~= "until|here")
       Gui, Font, Bold
    If !(resultDecemberSolstice ~= "month")
       Gui, Add, Text, y+7 w%txtWid%, %resultDecemberSolstice%
    Gui, Font, Normal
    StringRight, weeksPassed, A_YWeek, 2
    weeksPlural := weeksPassed>1 ? "weeks" : "week"
    weeksPlural2 := weeksPassed>1 ? "have" : "has"

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
    Gui, Font, Bold
    Gui, Add, Link, xp+30 y+10, To keep the development going, `n<a href="https://www.paypal.me/MariusSucan/15">please donate</a> or <a href="mailto:marius.sucan@gmail.com?subject=%appName% v%Version%">send me feedback</a>.
    Gui, Add, Picture, x+10 yp+0 gDonateNow hp w-1 +0xE hwndhDonateBTN, paypal.png

    Gui, Font, Normal
    Gui, Add, Button, xs+0 y+20 h30 w105 Default gCloseWindow, &Deus lux est
    Gui, Add, Button, x+5 hp w80 gShowOSDsettings, &Settings
    Gui, Add, Text, x+8 hp +0x200, v%Version% released on %ReleaseDate%
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
  INIaction(a, "BibleQuotesInterval", "SavedSettings")

; OSD settings
  INIaction(a, "CurrentDPI", "OSDprefs")
  INIaction(a, "DisplayTimeUser", "OSDprefs")
  INIaction(a, "FontName", "OSDprefs")
  INIaction(a, "FontSize", "OSDprefs")
  INIaction(a, "GuiX", "OSDprefs")
  INIaction(a, "GuiY", "OSDprefs")
  INIaction(a, "OSDalpha", "OSDprefs")
  INIaction(a, "OSDbgrColor", "OSDprefs")
  INIaction(a, "OSDborder", "OSDprefs")
  INIaction(a, "OSDtextColor", "OSDprefs")
  INIaction(a, "OSDsizingFactorH", "OSDprefs")
  INIaction(a, "OSDsizingFactorW", "OSDprefs")
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
       testNumber := defy
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

; correct contradictory settings

    If (OSDsizingFactorW>10)
       calcOSDresizeFactor(OSDsizingFactorW)

    If (CurrentDPI!=A_ScreenDPI) || (OSDsizingFactorW<=10)
    {
       CurrentDPI := A_ScreenDPI
       OSDsizingFactor := calcOSDresizeFactor("A",1)
       OSDsizingFactorW := calcOSDresizeFactor(0,2)
    }

; verify numeric values: min, max and default values
    MinMaxVar(DisplayTimeUser, 1, 99, 3)
    MinMaxVar(FontSize, 12, 300, 26)
    MinMaxVar(GuiX, -9999, 9999, 40)
    MinMaxVar(GuiY, -9999, 9999, 250)
    MinMaxVar(BeepsVolume, 0, 99, 45)
    MinMaxVar(strikeEveryMin, 1, 720, 5)
    MinMaxVar(silentHours, 1, 3, 1)
    MinMaxVar(silentHoursA, 0, 23, 12)
    MinMaxVar(silentHoursB, 0, 23, 14)
    MinMaxVar(LastNoon, 1, 3, 2)
    MinMaxVar(strikeInterval, 500, 5500, 2000)
    MinMaxVar(BibleQuotesInterval, 3, 11, 5)
    MinMaxVar(maxBibleLength, 10, 130, 55)
    MinMaxVar(OSDalpha, 24, 252, 230)
    MinMaxVar(OSDsizingFactorW, 10, 350, 0)
    MinMaxVar(OSDsizingFactorH, 10, 350, 86)
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
        Return DllCall("gdi32\GetStockObject","Int",DEFAULT_GUI_FONT)

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
    If not hFont  ;-- Zero or null
        Return True

    Return DllCall("gdi32\DeleteObject","Ptr",hFont) ? True:False
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
    Return True  ;-- Continue enumeration
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
   Return DllCall("Winmm.dll\PlaySound" . AW, "Ptr", File = "" ? 0 : &File, "Ptr", 0, "UInt", 0x0002200B)
}


dummy() {
    Return
}
