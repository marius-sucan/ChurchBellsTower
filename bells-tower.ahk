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
;@Ahk2Exe-SetCompanyName sucan.ro
;@Ahk2Exe-SetDescription Church Bells Tower
;@Ahk2Exe-SetVersion 1.5.6
;@Ahk2Exe-SetOrigFilename bells-tower.ahk
;@Ahk2Exe-SetMainIcon bell-tower.ico

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

; OSD settings
 , displayTimeFormat      := 1
 , DisplayTimeUser        := 3     ; in seconds
 , OSDborder              := 0
 , GUIposition            := 1     ; toggle between positions with Ctrl + Alt + Shift + F9
 , GuiX                   := 40
 , GuiY                   := 250
 , GuiWidth               := 350
 , MaxGuiWidth            := A_ScreenWidth
 , FontName               := (A_OSVersion="WIN_XP") ? "Lucida Sans Unicode" : "Arial"
 , FontSize               := 19
 , PrefsLargeFonts        := 0
 , OSDbgrColor            := "131209"
 , OSDalpha               := 200
 , OSDtextColor           := "FFFEFA"
 , OSDsizingFactor        := calcOSDresizeFactor()

; Release info
 , ThisFile               := A_ScriptName
 , Version                := "1.5.6"
 , ReleaseDate            := "2018 / 09 / 30"
 , ScriptInitialized, FirstRun := 1
 , LastNoon := 0, appName := "Church Bells Tower"

   If !A_IsCompiled
      Menu, Tray, Icon, bell-tower.ico

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

Global Debug := 0    ; for testing purposes
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
 , LargeUIfontValue := 13
 , ShowPreview := 0
 , stopStrikesNow := 0
 , CurrentDPI := A_ScreenDPI
 , AnyWindowOpen := 0
 , ScriptelSuspendel := 0
 , tickTockSound := A_ScriptDir "\sounds\ticktock.wav"
 , hOSD, OSDhandles, dragOSDhandles, ColorPickerHandles
 , hMain := A_ScriptHwnd
 , CCLVO := "-E0x200 +Border -Hdr -Multi +ReadOnly Report AltSubmit gsetColors"
 , hWinMM := DllCall("kernel32\LoadLibraryW", "Str", "winmm.dll", "Ptr")

; Initializations of the core components and functionality

If (A_IsCompiled)
   VerifyFiles()

CreateOSDGUI()
Sleep, 5
SetMyVolume()
InitializeTray()

hCursM := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32646, "Ptr")  ; IDC_SIZEALL
hCursH := DllCall("user32\LoadCursorW", "Ptr", NULL, "Int", 32649, "Ptr")  ; IDC_HAND
OnMessage(0x200, "MouseMove")    ; WM_MOUSEMOVE
OnMessage(0x404, "AHK_NOTIFYICON")
Sleep, 5
If (tickTockNoise=1)
   SoundLoop(tickTockSound)
theChimer()
SetTimer, theChimer, 15000
ScriptInitialized := 1      ; the end of the autoexec section and INIT
ShowHotkey(generateDateTimeTxt())
SetTimer, HideGUI, % -DisplayTime/2
Return

VerifyFiles() {
  Loop, Files, sounds\*.wav
        countFiles++
  Loop, Files, sounds\*.mp3
        countFiles++
  If (countFiles<0)
     FileRemoveDir, sounds, 1
  Sleep, 50
  FileCreateDir, sounds
  FileInstall, sounds\ticktock.wav, sounds\ticktock.wav
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
  
  If (lParam = 0x201) || (lParam = 0x204) || (lParam = 0x207)
  {
     stopStrikesNow := 1
     ShowHotkey(generateDateTimeTxt())
     SetTimer, HideGUI, % -DisplayTime/1.5
  } Else If (OSDvisible=0)
  {
     ShowHotkey(generateDateTimeTxt(0))
     SetTimer, HideGUI, % -DisplayTime/1.5
  }
}

SetMyVolume() {
  Static mustRestoreVol, LastInvoked := 1

  If (PrefOpen=1)
     GuiControlGet, DynamicVolume

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
  && (A_TickCount - LastInvoked > 20500)
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
  actualVolume := val + Round(randySound)
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
    SetMyVolume()
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

theChimer() {
  Critical, on
  Static lastChimed
  FormatTime, CurrentTime,, hh:mm
  If (lastChimed=CurrentTime || A_IsSuspended || PrefOpen=1)
     Return
  FormatTime, exactTime,, HH:mm
  If (displayTimeFormat=1)
     FormatTime, CurrentTimeDisplay,, H:mm
  Else
     FormatTime, CurrentTimeDisplay,, h:mm tt
  FormatTime, HoursIntervalTest,, H ; 0-23 format

  If (HoursIntervalTest>=silentHoursA && HoursIntervalTest<=silentHoursB && silentHours=2)
     soundBells := 1

  If (HoursIntervalTest>=silentHoursA && HoursIntervalTest<=silentHoursB && silentHours=3)
  || (soundBells!=1 && silentHours=2)
     Return
  SoundGet, master_vol
  stopStrikesNow := 0

  If InStr(CurrentTime, ":15") && (tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        ShowHotkey(CurrentTimeDisplay)
     strikeQuarters()
  } Else If InStr(CurrentTime, ":30") && (tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        ShowHotkey(CurrentTimeDisplay)
     Loop, 2
        strikeQuarters()
  } Else If InStr(CurrentTime, ":45") && (tollQuarters=1)
  {
     volumeAction := SetMyVolume()
     If (displayClock=1)
        ShowHotkey(CurrentTimeDisplay)
     Loop, 3
     {
        strikeQuarters()
        Sleep, % A_Index * 150
     }
  } Else If InStr(exactTime, "05:59") && (tollNoon=1)
  {
     volumeAction := SetMyVolume()
     SoundPlay, sounds\morning.wav, 1
  } Else If InStr(exactTime, "17:59") && (tollNoon=1)
  {
     volumeAction := SetMyVolume()
     If (BeepsVolume>1)
        SoundPlay, sounds\evening.mp3, 1
  } Else If InStr(exactTime, "23:59") && (tollNoon=1)
  {
     volumeAction := SetMyVolume()
     SoundPlay, sounds\midnight.wav, 1
  } Else If InStr(CurrentTime, ":00")
  {
     FormatTime, countHours2beat,, h   ; 0-12 format
     If (tollQuarters=1 && tollQuartersException=0)
     {
        volumeAction := SetMyVolume()
        volumeActionRan := 1
        If (displayClock=1)
           ShowHotkey(CurrentTimeDisplay)
        Loop, 4
        {
           strikeQuarters()
           Sleep, % A_Index * 125
        }
     }
     Random, delayRand, 900, 1600
     Sleep, %delayRand%
     If (countHours2beat="00") || (countHours2beat=0)
        countHours2beat := 12
     If (tollHoursAmount=1 && tollHours=1)
     {
        volumeAction := SetMyVolume()
        volumeActionRan := 1
        If (displayClock=1)
           ShowHotkey(CurrentTimeDisplay)
        Loop, %countHours2beat%
        {
           strikeHours()
           Sleep, % A_Index * 75
        }
     } Else If (tollHours=1)
     {
        volumeAction := SetMyVolume()
        volumeActionRan := 1
        If (displayClock=1)
           ShowHotkey(CurrentTimeDisplay)
        strikeHours()
     }

     If InStr(exactTime, "12:0") && (tollNoon=1)
     {
        Random, delayRand, 2000, 4500
        Sleep, %delayRand%
        If (volumeActionRan!=1)
           volumeAction := SetMyVolume()
        choice := (LastNoon=3) ? 1 : LastNoon + 1
        IniWrite, %choice%, %IniFile%, SavedSettings, LastNoon
        If (stopStrikesNow=0 && ScriptInitialized=1 && volumeAction>0 && BeepsVolume>1)
           SoundPlay, sounds\noon%choice%.mp3, 1
        Else If (stopStrikesNow=0 && BeepsVolume>1)
           SoundPlay, sounds\noon%choice%.mp3
     }
  }

  If (AutoUnmute=1 && volumeAction>0)
  {
     If (volumeAction=1 || volumeAction=3)
        SoundSet, 1, , mute
     If (volumeAction=2 || volumeAction=3)
        SoundSet, %master_vol%
  }

  SetTimer, HideGUI, % -DisplayTime
  lastChimed := CurrentTime
}

calcOSDresizeFactor() {
  Return Round(A_ScreenDPI / 1.1)
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
    Gui, OSD: Show, NoActivate Hide x%GuiX% y%GuiY%, txtCapOSDwin  ; required for initialization when Drag2Move is active
    OSDhandles := hOSD "," hOSDctrl "," hOSDind1 "," hOSDind2 "," hOSDind3 "," hOSDind4
    dragOSDhandles := hOSDind1 "," hOSDind2 "," hOSDind3 "," hOSDind4
}

ShowHotkey(string) {
;  Sleep, 70 ; megatest

    Global Tickcount_start2 := A_TickCount
    Text_width := GetTextExtentPoint(string, FontName, FontSize) / (OSDsizingFactor/100)
    Text_width := Round(Text_width)
    GuiControl, OSD: , HotkeyText, %string%
    GuiControl, OSD: Move, HotkeyText, w%Text_width%

    Gui, OSD: Show, NoActivate x%GuiX% y%GuiY% AutoSize, txtCapOSDwin
    WinSet, AlwaysOnTop, On, txtCapOSDwin
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
; Sleep, 60 ; megatest

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

  nWidth := nSize & 0xFFFFFFFF
  nWidth := (nWidth<35) ? 36 : Round(nWidth)

  minHeight := Round(FontSize*1.55)
  maxHeight := Round(FontSize*3.1)
  GuiHeight := nSize >> 32 & 0xFFFFFFFF
  GuiHeight := GuiHeight / (OSDsizingFactor/100) + (OSDsizingFactor/10) + 4
  GuiHeight := (GuiHeight<minHeight) ? minHeight+1 : Round(GuiHeight)
  GuiHeight := (GuiHeight>maxHeight) ? maxHeight-1 : Round(GuiHeight)
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
     SetTimer, HideGUI, 1500
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
  RegRead, currentReg, HKCU, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %appName%
  If (ErrorLevel=1 || currentReg!=regEntry)
  {
     StringReplace, TestThisFile, ThisFile, .ahk, .exe
     If !FileExist(TestThisFile)
        MsgBox, This option works only in the compiled edition of this script.
     RegWrite, REG_SZ, HKCU, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %appName%, %regEntry%
     Menu, PrefsMenu, Check, Sta&rt at boot
     ShowHotkey("Enabled Start at Boot")
  } Else
  {
     RegDelete, HKCU, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %appName%
     Menu, PrefsMenu, Uncheck, Sta&rt at boot
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
      Menu, Tray, Uncheck, &%appName% activated
      If (tickTockNoise=1)
         SoundLoop("")
   } Else
   {
      ScriptelSuspendel := 0
      Menu, Tray, Check, &%appName% activated
      If (tickTockNoise=1)
         SoundLoop(tickTockSound)
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
    Menu, PrefsMenu, Add, &Customize, ShowOSDsettings
    Menu, PrefsMenu, Add
    Menu, PrefsMenu, Add, L&arge UI fonts, ToggleLargeFonts
    Menu, PrefsMenu, Add, Sta&rt at boot, SetStartUp
    Menu, PrefsMenu, Add

    RegRead, currentReg, HKCU, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %appName%
    If (StrLen(currentReg)>5)
       Menu, PrefsMenu, Check, Sta&rt at boot

    If (PrefsLargeFonts=1)
       Menu, PrefsMenu, Check, L&arge UI fonts

    RunType := A_IsCompiled ? "" : " [script]"
    Menu, Tray, NoStandard
    Menu, Tray, Add, &Preferences, :PrefsMenu
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
    Menu, PrefsMenu, % (PrefsLargeFonts=0 ? "Uncheck" : "Check"), L&arge UI fonts
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
        Reload
        Sleep, 50
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

RunAdminMode() {
  If !A_IsAdmin
  {
      Try {
         Cleanup()
         If A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
         Else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
         ExitApp
      }
  }
}

DeleteSettings() {
    MsgBox, 4,, Are you sure you want to delete the stored settings?
    IfMsgBox, Yes
    {
       FileSetAttrib, -R, %IniFile%
       FileDelete, %IniFile%
       Cleanup()
       Reload
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

SettingsGUI() {
   Global
   Gui, SettingsGUIA: Destroy
   Sleep, 15
   Gui, SettingsGUIA: Default
   Gui, SettingsGUIA: -MaximizeBox
   Gui, SettingsGUIA: -MinimizeBox
   Gui, SettingsGUIA: Margin, 15, 15
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
    Gui, SettingsGUIA: Destroy
}

CloseSettings() {
   GuiControlGet, ApplySettingsBTN, Enabled
   PrefOpen := 0
   CloseWindow()
   If (ApplySettingsBTN=0)
   {
      Sleep, 25
      SuspendScript()
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
  Fnt_SetFont(hOSDctrl,hfont,true)
}

OSDpreview() {
    Gui, SettingsGUIA: Submit, NoHide
    If (ShowPreview=0)
    {
       HideGUI()
       Return
    }

    Sleep, 25
    CreateOSDGUI()
    UpdateFntNow()
    ShowHotkey(generateDateTimeTxt())
}

generateDateTimeTxt(LongD:=1) {
    If (displayTimeFormat=1)
       FormatTime, CurrentTime,, H:mm
    Else
       FormatTime, CurrentTime,, h:mm tt

    If (LongD=1)
       FormatTime, CurrentDate,, LongDate
    Else
       FormatTime, CurrentDate,, ShortDate

    txtReturn := CurrentTime " | " CurrentDate
    Return txtReturn
}

editsOSDwin() {
  If (A_TickCount-DoNotRepeatTimer<1000)
     Return
  VerifyOsdOptions()
}

ResetOSDsizeFactor() {
  GuiControl, , editF9, % calcOSDresizeFactor()
}

ShowOSDsettings() {
    doNotOpen := initSettingsWindow()
    If (doNotOpen=1)
       Return

    If ShowPreview             ; If OSD is already visible don't hide/show it,
       SetTimer, HideGUI, Off  ; just update the text (avoids the flicker)
    Global CurrentPrefWindow := 5
    Global DoNotRepeatTimer := A_TickCount
    Global positionB, editF1, editF2, editF3, editF4, editF5, editF6, Btn1, volLevel
         , editF7, editF8, editF9, editF10, editF35, editF36, editF37, Btn2, txt1, txt2, txt3
    GUIposition := GUIposition + 1
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
    Gui, Add, Text, xs y+10, Interval between strikes (in miliseconds):
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
    Gui, Add, Edit, xs+%columnBpos1b% ys w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF1, %GuiX%
    Gui, Add, UpDown, vGuiX gVerifyOsdOptions 0x80 Range-9995-9998, %GuiX%
    Gui, Add, Edit, x+5 w65 geditsOSDwin r1 limit4 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF2, %GuiY%
    Gui, Add, UpDown, vGuiY gVerifyOsdOptions 0x80 Range-9995-9998, %GuiY%

    Gui, Add, Text, xm+15 ys+40 Section, Text width factor (lower = larger)
    Gui, Add, Edit, xs+%columnBpos1b% ys+0 w65 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF9, %OSDsizingFactor%
    Gui, Add, UpDown, gVerifyOsdOptions vOSDsizingFactor Range20-399, %OSDsizingFactor%
    Gui, Add, Text, x+5 gResetOSDsizeFactor hwndhTXT, DPI: %A_ScreenDPI%

    Gui, Add, Text, xm+15 y+25 Section, Font name
    Gui, Add, Text, xs yp+30, Text and background colors
    Gui, Add, Text, xs yp+30, Display time (in sec.)
    Gui, Add, Text, xs yp+30, Transparency
    Gui, Add, Text, xs yp+30, Font size
    Gui, Add, Checkbox, y+9 gVerifyOsdOptions Checked%OSDborder% vOSDborder, System border around OSD
    Gui, Add, Checkbox, xs+%columnBpos2% yp+0 h25 +0x1000 gVerifyOsdOptions Checked%ShowPreview% vShowPreview, Show preview window

    Gui, Add, DropDownList, xs+%columnBpos2% ys+0 section w200 gVerifyOsdOptions Sort Choose1 vFontName, %FontName%
    Gui, Add, ListView, xp+0 yp+30 w55 h20 %CCLVO% Background%OSDtextColor% vOSDtextColor hwndhLV1,
    Gui, Add, ListView, xp+60 yp w55 h20 %CCLVO% Background%OSDbgrColor% vOSDbgrColor hwndhLV2,
    Gui, Add, Edit, xp-60 yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF6, %DisplayTimeUser%
    Gui, Add, UpDown, vDisplayTimeUser gVerifyOsdOptions Range1-99, %DisplayTimeUser%
    Gui, Add, Edit, xp+0 yp+30 w55 hp geditsOSDwin r1 limit2 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF10, %OSDalpha%
    Gui, Add, UpDown, vOSDalpha gVerifyOsdOptions Range25-250, %OSDalpha%
    Gui, Add, Edit, xp+0 yp+30 w55 geditsOSDwin r1 limit3 -multi number -wantCtrlA -wantReturn -wantTab -wrap veditF5, %FontSize%
    Gui, Add, UpDown, gVerifyOsdOptions vFontSize Range7-295, %FontSize%

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
    GuiControlGet, GUIposition
    GuiControlGet, ShowPreview
    GuiControlGet, OSDsizingFactor
    GuiControlGet, silentHours
    GuiControlGet, tollHours
    GuiControlGet, tollQuarters

    GuiControl, % (EnableApply=0 ? "Disable" : "Enable"), ApplySettingsBTN
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursA
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), silentHoursB
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF35
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), editF36
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt1
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt2
    GuiControl, % (silentHours=1 ? "Disable" : "Enable"), txt3
    GuiControl, % (tollHours=0 ? "Disable" : "Enable"), tollHoursAmount
    GuiControl, % (tollQuarters=0 ? "Disable" : "Enable"), tollQuartersException

    Static LastInvoked := 1

    If (OSDsizingFactor>398 || OSDsizingFactor<12)
       GuiControl, , editF9, % calcOSDresizeFactor()
    If (A_TickCount - LastInvoked>900) || (OSDvisible=0 && ShowPreview=1)
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
   Run, https://www.paypal.me/MariusSucan/15
   CloseWindow()
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

    SettingsGUI()
    AnyWindowOpen := 1
    btnWid := 100
    txtWid := 360
    Global btn1
    Gui, Font, s20 Bold, Arial, -wrap
    Gui, Add, Text, x+7 y15 Section, %appName% v%Version%
    Gui, Font
    If (PrefsLargeFonts=1)
    {
       btnWid := btnWid + 50
       txtWid := txtWid + 105
       Gui, Font, s%LargeUIfontValue%
    }
    Gui, Add, Link, y+4, Developed by <a href="http://marius.sucan.ro">Marius Şucan</a> on AHK_H v1.1.28.
    Gui, Add, Text, y+10 w%txtWid% Section, Dedicated to Christians, church-goers or bell lovers.
    Gui, Add, Text, y+10 w%txtWid%, This application contains code from various entities. You can find more details in the source code.
    Gui, Font, Bold
    Gui, Add, Link, xp+25 y+10, To keep the development going, `n<a href="https://www.paypal.me/MariusSucan/15">please donate</a> or <a href="mailto:marius.sucan@gmail.com">send me feedback</a>.
    Gui, Font, Normal
    Gui, Add, Button, xs+0 y+20 h30 w105 Default gCloseWindow, &Deus lux est
    Gui, Add, Button, x+5 hp w80 gShowOSDsettings, &Settings
    Gui, Add, Text, x+8 hp +0x200, Released: %ReleaseDate%
    Gui, Show, AutoSize, About %appName%
    verifySettingsWindowSize()
    ColorPickerHandles := hDonateBTN "," hIcon
    Sleep, 25
}

;================================================================
; - Load, verify and save settings functions
;================================================================

INIaction(act, var, section) {
  varValue := %var%
  If (act=1)
     IniWrite, %varValue%, %IniFile%, %section%, %var%
  Else
     IniRead, %var%, %IniFile%, %section%, %var%, %varValue%
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
  INIaction(a, "OSDsizingFactor", "OSDprefs")

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
    If givenVar is not digit
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

; correct contradictory settings

    If (CurrentDPI!=A_ScreenDPI)
    {
       CurrentDPI := A_ScreenDPI
       OSDsizingFactor := calcOSDresizeFactor()
    }

; verify numeric values: min, max and default values
    MinMaxVar(DisplayTimeUser, 1, 99, 3)
    MinMaxVar(FontSize, 6, 300, 20)
    MinMaxVar(GuiX, -9999, 9999, 40)
    MinMaxVar(GuiY, -9999, 9999, 250)
    MinMaxVar(BeepsVolume, 0, 99, 45)
    MinMaxVar(silentHours, 1, 3, 1)
    MinMaxVar(silentHoursA, 0, 23, 12)
    MinMaxVar(silentHoursB, 0, 23, 14)
    MinMaxVar(LastNoon, 1, 3, 2)
    MinMaxVar(strikeInterval, 500, 5500, 2000)
    MinMaxVar(OSDalpha, 24, 252, 200)
    MinMaxVar(OSDsizingFactor, 20, 400, calcOSDresizeFactor())
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


#Space::
Return