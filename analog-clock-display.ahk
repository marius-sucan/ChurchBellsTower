; from https://autohotkey.com/board/topic/34692-examplesminituts-the-gdi-examplecodes-thread/#entry219089
; GDI+ ahk analogue clock example written by derRaphael
; posted on 17 November 2008 - 06:15 PM.
; extensively modified by Marius Șucan in January 2019
; Parts based on examples from Tic's GDI+ Tutorials and of course on his GDIP.ahk

; This code has been licensed under the terms of EUPL 1.0

#SingleInstance, Force
#NoEnv
#NoTrayIcon
CoordMode, Mouse, Screen
SetBatchLines, -1
Global MainExe := AhkExported()
     , isAnalogClockFile := 1

If (!pToken := Gdip_Startup())
{
   isAnalogClockFile := 0
   MainExe.ahkassign("isAnalogClockFile", isAnalogClockFile)
   Sleep, 10
   ExitApp
}

Global faceBgrColor  := "eeEEee"
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
     , hFaceClock
     , G, pPen, hbm, hdc, obm, pBrush
     , ClockVisibility := 0
     , isAnalogClockFile := 1
     , analogDisplay := 0
     , analogDisplayScale := 1
     , constantAnalogClock := 0
     , DisplayTime := 0
     , moduleInit := 0
     , PrefOpen := 0
     , tickTockNoise := 0

OnMessage(0x200, "WM_MOUSEMOVE")
OnExit, OnHEXit
InitClockFace()
Return

InitClockFace() {
   If (moduleInit!=1 || PrefOpen=1)
   {
      ClockPosX := MainExe.ahkgetvar.GuiX
      ClockPosY := MainExe.ahkgetvar.GuiY
   }
   tickTockNoise := MainExe.ahkgetvar.tickTockNoise
   analogDisplayScale := MainExe.ahkgetvar.analogDisplayScale
   analogDisplay := MainExe.ahkgetvar.analogDisplay
   constantAnalogClock := MainExe.ahkgetvar.constantAnalogClock
   OSDmarginSides := MainExe.ahkgetvar.OSDmarginSides
   OSDmarginBottom := MainExe.ahkgetvar.OSDmarginBottom
   OSDmarginTop := MainExe.ahkgetvar.OSDmarginTop
   DisplayTime := MainExe.ahkgetvar.DisplayTime
   DisplayTime := Ceil(DisplayTime * 1.25) + 2500
   mainOSDopacity := MainExe.ahkgetvar.OSDalpha
   FontSize := MainExe.ahkgetvar.FontSize
   faceElements := MainExe.ahkgetvar.OSDbgrColor
   faceBgrColor := MainExe.ahkgetvar.OSDtextColor
   OSDroundCorners := MainExe.ahkgetvar.OSDroundCorners
   ClockDiameter := Round(FontSize * 4 * analogDisplayScale)
   ClockWinSize := ClockDiameter + Round((OSDmarginBottom//2 + OSDmarginTop//2 + OSDmarginSides//2) * analogDisplayScale)
   roundedCsize := MainExe.ahkgetvar.roundCornerSize
   roundedCsize := Round(roundedCsize * analogDisplayScale)
   If (ClockDiameter<=80)
   {
      ClockDiameter := 80
      ClockWinSize := 90
      roundedCsize := 20
   }
   ClockCenter := Round(ClockWinSize/2)
   If (OSDroundCorners!=1)
      roundedCsize := 1

   SetFormat, Integer, H
   faceOpacity+=0
   faceOpacityBgr+=0
   SetFormat, Integer, D

   Width := Height := ClockWinSize + 2      ; make width and height slightly bigger to avoid cut away edges
   Gui, ClockGui: Destroy
   Sleep, 25
   Gui, ClockGui: -DPIScale -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +hwndHfaceClock
   Gui, ClockGui: Show, NoActivate x%ClockPosX% y%ClockPosY% w%Width% h%height%
   Gui, ClockGui: Hide
   ; WinSet, Region, 0-0 R%roundedCsize%-%roundedCsize% w%Width% h%Height%, ahk_id %hFaceClock%
   CenterX := CenterY := ClockCenter

; Prepare our pGraphic so we have a 'canvas' to work upon
   hbm := CreateDIBSection(Width, Height), hdc := CreateCompatibleDC()
   obm := SelectObject(hdc, hbm), G := Gdip_GraphicsFromHDC(hdc)
   Gdip_SetSmoothingMode(G, 4)
   Gdip_SetInterpolationMode(G, 7)

; Draw outer circle
   Diameter := Round(ClockDiameter * 1.35)
   pBrush := Gdip_BrushCreateSolid(faceOpacityBgr faceElements)      ; clock face background 
   Gdip_FillRoundedRectangle(G, pBrush, 0, 0, ClockWinSize, ClockWinSize, roundedCsize)
   Gdip_DeleteBrush(pBrush)

   Diameter := ClockDiameter - 2*Floor((ClockDiameter//100)*1.2)
   pPen := Gdip_CreatePen("0xaa" faceElements, floor((ClockDiameter/100)*1.2))
   Gdip_DrawEllipse(G, pPen, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeletePen(pPen)

; Draw inner circle
   Diameter := Round(ClockDiameter - ClockDiameter*0.04, 2) + Round((ClockDiameter/100)*1.2, 2)  ; white border
   pBrush := Gdip_BrushCreateSolid(faceOpacity faceBgrColor)
   Gdip_FillEllipse(G, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

; Draw Second Marks
   Diameter := Round(ClockDiameter - ClockDiameter*0.08, 2)  ; inner circle is 8 % smaller than clock's diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.08, 2) ; inner position
   pPen := Gdip_CreatePen("0xaa" faceElements, (ClockDiameter/100)*1.2) ; 1.2 % of total diameter is our pen width
   If (ClockDiameter>=100)
      DrawClockMarks(60, R1, R2)                 ; we have 60 seconds
   Else If (ClockDiameter>=50)
      DrawClockMarks(24, R1, R2+0.1)
   Gdip_DeletePen(pPen)

   R2 := Round(Diameter/2 - 1 - Diameter/2*0.04, 2) ; inner position
   pPen := Gdip_CreatePen("0x88" faceElements, (ClockDiameter/100)*0.7) ; 1.2 % of total diameter is our pen width
   If (ClockDiameter>250)
      DrawClockMarks(120, R1, R2)                 ; we have 60 seconds
   Gdip_DeletePen(pPen)

; Draw Hour Marks
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.2, 2) ; inner position
   pPen := Gdip_CreatePen("0xff" faceElements, (ClockDiameter/100)*2.3) ; 2.3 % of total diameter is our pen width
   DrawClockMarks(12, R1, R2)                  ; we have 12 hours
   
   Diameter := Round(ClockDiameter - ClockDiameter*0.17, 2)  ; inner circle is 17 % smaller than clock's diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.2, 2) ; inner position
   pPen := Gdip_CreatePen("0xff" faceElements, (ClockDiameter/100)*4) ; 4 % of total diameter is our pen width
   If (ClockDiameter>250)
      DrawClockMarks(4, R1, R2)                  ; we have 4 quarters
   Gdip_DeletePen(pPen)
   
   UpdateLayeredWindow(hFaceClock, hdc, , , , , mainOSDopacity)
   moduleInit := 1
   Return
}

animateAppeareance() {
   Loop,
   {
      alphaLevel := A_Index*15
      If (alphaLevel>mainOSDopacity)
         Break
      UpdateLayeredWindow(hFaceClock, hdc, , , , , alphaLevel)
      Sleep, 1
   }
}

animateHiding() {
   Loop,
   {
      alphaLevel := mainOSDopacity - A_Index*15
      If (alphaLevel<5)
         Break
      UpdateLayeredWindow(hFaceClock, hdc, , , , , alphaLevel)
      Sleep, 1
   }
}

UpdateEverySecond() {
   CenterX := CenterY := ClockCenter

; prepare to empty previously drawn stuff
   Gdip_SetSmoothingMode(G, 1)   ; turn off aliasing
   Gdip_SetCompositingMode(G, 1) ; set to overdraw
   
; delete previous graphic and redraw background
   Diameter := Round(ClockDiameter - ClockDiameter*0.22, 2)  ; 18 % less than clock's outer diameter
   
   ; delete whatever has been drawn here
   pBrush := Gdip_BrushCreateSolid(0x00000000) ; fully transparent brush 'eraser'
   Gdip_FillEllipse(G, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)
   
   Gdip_SetCompositingMode(G, 0) ; switch off overdraw
   pBrush := Gdip_BrushCreateSolid(faceOpacityBgr faceElements)
   Gdip_FillEllipse(G, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   pBrush := Gdip_BrushCreateSolid(faceOpacity faceBgrColor)
   Gdip_FillEllipse(G, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   Diameter := Round(ClockDiameter*0.08, 2)
   pBrush := Gdip_BrushCreateSolid("0x66" faceElements)
   Gdip_FillEllipse(G, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)
   Diameter := Round(ClockDiameter*0.04, 2)
   pBrush := Gdip_BrushCreateSolid("0x95" faceElements)
   Gdip_FillEllipse(G, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)
   
; Draw HoursPointer
   Gdip_SetSmoothingMode(G, 4)   ; turn on antialiasing
   t := (A_Hour*360//12) + ((A_Min//15*15)*360//60)//12 + 90
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.50, 2) ; outer position
   pPen := Gdip_CreatePen("0xaa" faceElements, Round((ClockDiameter/100)*3.3, 2))
   Gdip_DrawLine(G, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.45, 2) ; outer position
   pPen := Gdip_CreatePen("0xcc" faceElements, Round((ClockDiameter/100)*1.6, 2))
   Gdip_DrawLine(G, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)
   
; Draw MinutesPointer
   t := Round(A_Min*360/60+90, 2)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.35, 2) ; outer position
   pPen := Gdip_CreatePen("0x55" faceElements, Round((ClockDiameter/100)*2.8, 2))
   Gdip_DrawLine(G, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer
   t := Round(A_Sec*360/60+90, 2)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.25, 2) ; outer position
   pPen := Gdip_CreatePen("0x99" faceElements, Round((ClockDiameter/100)*1.3, 2))
   Gdip_DrawLine(G, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer end stick
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.75, 2) ; outer position
   pPen := Gdip_CreatePen("0x99" faceElements, Round((ClockDiameter/100)*1.3, 2))
   Gdip_DrawLine(G, pPen, CenterX, CenterY
      , Round(CenterX + (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY + (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

   UpdateLayeredWindow(hFaceClock, hdc, , , , , mainOSDopacity)
   Return
}

DrawClockMarks(items, R1, R2) {
   CenterX := CenterY := ClockCenter
   Loop, %items%
   {
      Gdip_DrawLine(G, pPen
         , CenterX - Round(R1 * Cos(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2)
         , CenterY - Round(R1 * Sin(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2)
         , CenterX - Round(R2 * Cos(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2)
         , CenterY - Round(R2 * Sin(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2))
   }
}

hideClock() {
  If (ClockVisibility!=1)
     Return
  If (PrefOpen=0)
     animateHiding()
  Gui, ClockGui: Hide
  SetTimer, UpdateEverySecond, Off
  ClockVisibility := 0
  MainExe.ahkassign("ClockVisibility", ClockVisibility)
  Return
}

showClock() {
  constantAnalogClock := MainExe.ahkgetvar.constantAnalogClock
  If (ClockVisibility!=0)
     Return
  Gui, ClockGui: Show, NoActivate
  UpdateEverySecond()
  SetTimer, UpdateEverySecond, 1000
  If (PrefOpen=0)
     animateAppeareance()
  ClockVisibility := 1
  MainExe.ahkassign("ClockVisibility", ClockVisibility)
  If (analogDisplay=1 && constantAnalogClock=0 && PrefOpen=0)
     SetTimer, hideClock, % -DisplayTime
  Return
}

OnHEXit:
   If (PrefOpen=0)
      animateHiding()
   SetTimer, UpdateEverySecond, Off
   Gui, ClockGui: Destroy
   ClockVisibility := 0
   SelectObject(hdc, obm)
   DeleteObject(hbm)
   DeleteDC(hdc)
   Gdip_DeleteGraphics(G)
   Gdip_Shutdown(pToken)
   ExitApp
Return


WM_MOUSEMOVE(wP, lP, msg, hwnd) {
; Function by Drugwash
  Global
  Local A
  SetFormat, Integer, H
  hwnd+=0, A := WinExist("A"), hwnd .= "", A .= ""
  SetFormat, Integer, D

  If (constantAnalogClock=1 && A=hFaceClock && (wP&0x1) && PrefOpen=0)
  {
     PostMessage, 0xA1, 2,,, ahk_id %hFaceClock%
     SetTimer, trackMouseDragging, -25
  } Else If (constantAnalogClock=0 || PrefOpen=1)
     hideClock()
}

trackMouseDragging() {
     defAnalogClockPosChanged := 1
     MainExe.ahkassign("defAnalogClockPosChanged", defAnalogClockPosChanged)
     WinGetPos, ClockPosX, ClockPosY,,, ahk_id %hFaceClock%
     GetKeyState, already_down_state, LButton
     If (already_down_state = "D")
        SetTimer, trackMouseDragging, -25
}

ClockGuiGuiContextMenu(GuiHwnd, CtrlHwnd, EventInfo, IsRightClick, X, Y) {
    Static menuGenerated, lastInvoked := 1
    If (CtrlHwnd && IsRightClick=1)
    || ((A_TickCount-lastInvoked>250) && IsRightClick=0)
    {
       lastInvoked := A_TickCount
       Return
    }
    Menu, ContextMenu, UseErrorLevel
    Menu, ContextMenu, Delete
    Sleep, 25
    If (menuGenerated!=1)
    {
       Menu, ClockSizesMenu, Add, 0.25x, ChangeClockSize
       Menu, ClockSizesMenu, Add, 0.50x, ChangeClockSize
       Menu, ClockSizesMenu, Add, 1.00x, ChangeClockSize
       Menu, ClockSizesMenu, Add, 1.50x, ChangeClockSize
       Menu, ClockSizesMenu, Add, 2.00x, ChangeClockSize
       Menu, ClockSizesMenu, Add, 3.00x, ChangeClockSize
       menuGenerated := 1
    }
    Menu, ClockSizesMenu, Check, %analogDisplayScale%x
    Menu, ContextMenu, Add, Sc&ale, :ClockSizesMenu
    Menu, ContextMenu, Add, 
    Menu, ContextMenu, Add, &Hide the clock, HideClockNow
    Menu, ContextMenu, Add, 
    If (PrefOpen=0)
    {
       Menu, ContextMenu, Add, &Tick/tock sounds, ToggleTicks
       If (tickTockNoise=1)
          Menu, ContextMenu, Check, &Tick/tock sounds
       Menu, ContextMenu, Add, &Settings, ShowSettings
       Menu, ContextMenu, Add, &About, ShowAbout
    }
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Close menu, dummy
    Menu, ContextMenu, Show
    lastInvoked := A_TickCount
    Return
}

HideClockNow() {
  MainExe.ahkPostFunction["toggleAnalogClock"]
}

ShowSettings() {
  MainExe.ahkPostFunction["ShowSettings"]
}

ShowAbout() {
  MainExe.ahkPostFunction["AboutWindow"]
}

ToggleTicks() {
  MainExe.ahkPostFunction["ToggleTickTock"]
}

SynchSecTimer() {
  SetTimer, UpdateEverySecond, Off
  SetTimer, UpdateEverySecond, 1000
}

ChangeClockSize() {
  Menu, ClockSizesMenu, Uncheck, %analogDisplayScale%x
  StringLeft, newSize, A_ThisMenuItem, 4
  MainExe.ahkPostFunction["ChangeClockSize", newSize]
}

dummy() {
  Return
}

;#####################################################################################
; Gdip standard library v1.45 by tic (Tariq Porter) 07/09/11
; Modifed by Rseding91 using fincs 64 bit compatible Gdip library 5/1/2013
; Supports: Basic, _L ANSi, _L Unicode x86 and _L Unicode x64
; taken https://autohotkey.com/boards/viewtopic.php?t=6517

UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  if ((x != "") && (y != ""))
    VarSetCapacity(pt, 8), NumPut(x, pt, 0, "UInt"), NumPut(y, pt, 4, "UInt")

  if (w = "") ||(h = "")
    WinGetPos,,, w, h, ahk_id %hwnd%
   
  return DllCall("UpdateLayeredWindow"
          , Ptr, hwnd
          , Ptr, 0
          , Ptr, ((x = "") && (y = "")) ? 0 : &pt
          , "int64*", w|h<<32
          , Ptr, hdc
          , "int64*", 0
          , "uint", 0
          , "UInt*", Alpha<<16|1<<24
          , "uint", 2)
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="") {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  return DllCall("gdi32\BitBlt"
          , Ptr, dDC
          , "int", dx, "int", dy
          , "int", dw, "int", dh
          , Ptr, sDC
          , "int", sx, "int", sy
          , "uint", Raster ? Raster : 0x00CC0020)
}

StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster="") {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  return DllCall("gdi32\StretchBlt"
          , Ptr, ddc
          , "int", dx, "int", dy
          , "int", dw, "int", dh
          , Ptr, sdc
          , "int", sx, "int", sy
          , "int", sw, "int", sh
          , "uint", Raster ? Raster : 0x00CC0020)
}

SetStretchBltMode(hdc, iStretchMode=4) {
  return DllCall("gdi32\SetStretchBltMode"
          , A_PtrSize ? "UPtr" : "UInt", hdc
          , "int", iStretchMode)
}

SetImage(hwnd, hBitmap) {
  SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
  E := ErrorLevel
  DeleteObject(E)
  return E
}

SetSysColorToControl(hwnd, SysColor=15) {
   WinGetPos,,, w, h, ahk_id %hwnd%
   bc := DllCall("GetSysColor", "Int", SysColor, "UInt")
   pBrushClear := Gdip_BrushCreateSolid(0xff000000 | (bc >> 16 | bc & 0xff00 | (bc & 0xff) << 16))
   pBitmap := Gdip_CreateBitmap(w, h), G := Gdip_GraphicsFromImage(pBitmap)
   Gdip_FillRectangle(G, pBrushClear, 0, 0, w, h)
   hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
   SetImage(hwnd, hBitmap)
   Gdip_DeleteBrush(pBrushClear)
   Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
   return 0
}

Gdip_BitmapFromScreen(Screen=0, Raster="") {
  if (Screen = 0)
  {
    Sysget, x, 76
    Sysget, y, 77  
    Sysget, w, 78
    Sysget, h, 79
  } else if (SubStr(Screen, 1, 5) = "hwnd:")
  {
    Screen := SubStr(Screen, 6)
    if !WinExist( "ahk_id " Screen)
      return -2
    WinGetPos,,, w, h, ahk_id %Screen%
    x := y := 0
    hhdc := GetDCEx(Screen, 3)
  } else if (Screen&1 != "")
  {
    Sysget, M, Monitor, %Screen%
    x := MLeft, y := MTop, w := MRight-MLeft, h := MBottom-MTop
  } else
  {
    StringSplit, S, Screen, |
    x := S1, y := S2, w := S3, h := S4
  }

  if (x = "") || (y = "") || (w = "") || (h = "")
     Return -1

  chdc := CreateCompatibleDC(), hbm := CreateDIBSection(w, h, chdc), obm := SelectObject(chdc, hbm), hhdc := hhdc ? hhdc : GetDC()
  BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
  ReleaseDC(hhdc)
  
  pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
  SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
  Return pBitmap
}

Gdip_BitmapFromHWND(hwnd) {
  WinGetPos,,, Width, Height, ahk_id %hwnd%
  hbm := CreateDIBSection(Width, Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
  PrintWindow(hwnd, hdc)
  pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
  SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
  return pBitmap
}

CreateRectF(ByRef RectF, x, y, w, h) {
   VarSetCapacity(RectF, 16)
   NumPut(x, RectF, 0, "float"), NumPut(y, RectF, 4, "float"), NumPut(w, RectF, 8, "float"), NumPut(h, RectF, 12, "float")
}

CreateRect(ByRef Rect, x, y, w, h) {
  VarSetCapacity(Rect, 16)
  NumPut(x, Rect, 0, "uint"), NumPut(y, Rect, 4, "uint"), NumPut(w, Rect, 8, "uint"), NumPut(h, Rect, 12, "uint")
}

CreateSizeF(ByRef SizeF, w, h) {
   VarSetCapacity(SizeF, 8)
   NumPut(w, SizeF, 0, "float"), NumPut(h, SizeF, 4, "float")     
}

CreatePointF(ByRef PointF, x, y) {
   VarSetCapacity(PointF, 8)
   NumPut(x, PointF, 0, "float"), NumPut(y, PointF, 4, "float")     
}

CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  hdc2 := hdc ? hdc : GetDC()
  VarSetCapacity(bi, 40, 0)
  
  NumPut(w, bi, 4, "uint")
  , NumPut(h, bi, 8, "uint")
  , NumPut(40, bi, 0, "uint")
  , NumPut(1, bi, 12, "ushort")
  , NumPut(0, bi, 16, "uInt")
  , NumPut(bpp, bi, 14, "ushort")
  
  hbm := DllCall("CreateDIBSection"
          , Ptr, hdc2
          , Ptr, &bi
          , "uint", 0
          , A_PtrSize ? "UPtr*" : "uint*", ppvBits
          , Ptr, 0
          , "uint", 0, Ptr)

  if !hdc
     ReleaseDC(hdc2)
  return hbm
}

PrintWindow(hwnd, hdc, Flags=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("PrintWindow", Ptr, hwnd, Ptr, hdc, "uint", Flags)
}

DestroyIcon(hIcon) {
  return DllCall("DestroyIcon", A_PtrSize ? "UPtr" : "UInt", hIcon)
}

PaintDesktop(hdc) {
  return DllCall("PaintDesktop", A_PtrSize ? "UPtr" : "UInt", hdc)
}

CreateCompatibleBitmap(hdc, w, h) {
  return DllCall("gdi32\CreateCompatibleBitmap", A_PtrSize ? "UPtr" : "UInt", hdc, "int", w, "int", h)
}

CreateCompatibleDC(hdc=0) {
   return DllCall("CreateCompatibleDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}

SelectObject(hdc, hgdiobj) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("SelectObject", Ptr, hdc, Ptr, hgdiobj)
}

DeleteObject(hObject) {
  return DllCall("DeleteObject", A_PtrSize ? "UPtr" : "UInt", hObject)
}

GetDC(hwnd=0) {
  return DllCall("GetDC", A_PtrSize ? "UPtr" : "UInt", hwnd)
}

GetDCEx(hwnd, flags=0, hrgnClip=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("GetDCEx", Ptr, hwnd, Ptr, hrgnClip, "int", flags)
}

ReleaseDC(hdc, hwnd=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("ReleaseDC", Ptr, hwnd, Ptr, hdc)
}

DeleteDC(hdc) {
   return DllCall("DeleteDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}

Gdip_BitmapFromBRA(ByRef BRAFromMemIn, File, Alternate=0) {
  Static FName = "ObjRelease"
  
  if !BRAFromMemIn
    return -1
  Loop, Parse, BRAFromMemIn, `n
  {
    if (A_Index = 1)
    {
      StringSplit, Header, A_LoopField, |
      if (Header0 != 4 || Header2 != "BRA!")
        return -2
    } else if (A_Index = 2)
    {
      StringSplit, Info, A_LoopField, |
      if (Info0 != 3)
        return -3
    } else
      break
  }
  if !Alternate
    StringReplace, File, File, \, \\, All
  RegExMatch(BRAFromMemIn, "mi`n)^" (Alternate ? File "\|.+?\|(\d+)\|(\d+)" : "\d+\|" File "\|(\d+)\|(\d+)") "$", FileInfo)
  if !FileInfo
    return -4
  
  hData := DllCall("GlobalAlloc", "uint", 2, Ptr, FileInfo2, Ptr)
  pData := DllCall("GlobalLock", Ptr, hData, Ptr)
  DllCall("RtlMoveMemory", Ptr, pData, Ptr, &BRAFromMemIn+Info2+FileInfo1, Ptr, FileInfo2)
  DllCall("GlobalUnlock", Ptr, hData)
  DllCall("ole32\CreateStreamOnHGlobal", Ptr, hData, "int", 1, A_PtrSize ? "UPtr*" : "UInt*", pStream)
  DllCall("gdiplus\GdipCreateBitmapFromStream", Ptr, pStream, A_PtrSize ? "UPtr*" : "UInt*", pBitmap)
  If (A_PtrSize)
    %FName%(pStream)
  Else
    DllCall(NumGet(NumGet(1*pStream)+8), "uint", pStream)
  return pBitmap
}


Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipDrawRectangle", Ptr, pGraphics, Ptr, pPen, "float", x, "float", y, "float", w, "float", h)
}

Gdip_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r) {
  Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
  Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
  Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
  Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
  E := Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
  Gdip_ResetClip(pGraphics)
  Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
  Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
  Gdip_DrawEllipse(pGraphics, pPen, x, y, 2*r, 2*r)
  Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y, 2*r, 2*r)
  Gdip_DrawEllipse(pGraphics, pPen, x, y+h-(2*r), 2*r, 2*r)
  Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
  Gdip_ResetClip(pGraphics)
  return E
}

Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipDrawEllipse", Ptr, pGraphics, Ptr, pPen, "float", x, "float", y, "float", w, "float", h)
}

Gdip_DrawBezier(pGraphics, pPen, x1, y1, x2, y2, x3, y3, x4, y4) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  return DllCall("gdiplus\GdipDrawBezier"
          , Ptr, pgraphics
          , Ptr, pPen
          , "float", x1, "float", y1
          , "float", x2, "float", y2
          , "float", x3, "float", y3
          , "float", x4, "float", y4)
}

Gdip_DrawArc(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipDrawArc"
          , Ptr, pGraphics
          , Ptr, pPen
          , "float", x, "float", y
          , "float", w, "float", h
          , "float", StartAngle
          , "float", SweepAngle)
}

Gdip_DrawPie(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipDrawPie", Ptr, pGraphics, Ptr, pPen, "float", x, "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
}

Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  return DllCall("gdiplus\GdipDrawLine"
          , Ptr, pGraphics
          , Ptr, pPen
          , "float", x1, "float", y1
          , "float", x2, "float", y2)
}

Gdip_DrawLines(pGraphics, pPen, Points) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  StringSplit, Points, Points, |
  VarSetCapacity(PointF, 8*Points0)   
  Loop, %Points0%
  {
    StringSplit, Coord, Points%A_Index%, `,
    NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
  }
  return DllCall("gdiplus\GdipDrawLines", Ptr, pGraphics, Ptr, pPen, Ptr, &PointF, "int", Points0)
}

Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  return DllCall("gdiplus\GdipFillRectangle"
          , Ptr, pGraphics
          , Ptr, pBrush
          , "float", x, "float", y
          , "float", w, "float", h)
}

Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r) {
  Region := Gdip_GetClipRegion(pGraphics)
  Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
  Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
  Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
  Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
  E := Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
  Gdip_SetClipRegion(pGraphics, Region, 0)
  Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
  Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
  Gdip_FillEllipse(pGraphics, pBrush, x, y, 2*r, 2*r)
  Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y, 2*r, 2*r)
  Gdip_FillEllipse(pGraphics, pBrush, x, y+h-(2*r), 2*r, 2*r)
  Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
  Gdip_SetClipRegion(pGraphics, Region, 0)
  Gdip_DeleteRegion(Region)
  return E
}

Gdip_FillPolygon(pGraphics, pBrush, Points, FillMode=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  StringSplit, Points, Points, |
  VarSetCapacity(PointF, 8*Points0)   
  Loop, %Points0%
  {
    StringSplit, Coord, Points%A_Index%, `,
    NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
  }   
  return DllCall("gdiplus\GdipFillPolygon", Ptr, pGraphics, Ptr, pBrush, Ptr, &PointF, "int", Points0, "int", FillMode)
}

Gdip_FillPie(pGraphics, pBrush, x, y, w, h, StartAngle, SweepAngle) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  return DllCall("gdiplus\GdipFillPie"
          , Ptr, pGraphics
          , Ptr, pBrush
          , "float", x, "float", y
          , "float", w, "float", h
          , "float", StartAngle
          , "float", SweepAngle)
}

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipFillEllipse", Ptr, pGraphics, Ptr, pBrush, "float", x, "float", y, "float", w, "float", h)
}

Gdip_FillRegion(pGraphics, pBrush, Region) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipFillRegion", Ptr, pGraphics, Ptr, pBrush, Ptr, Region)
}

Gdip_FillPath(pGraphics, pBrush, Path) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipFillPath", Ptr, pGraphics, Ptr, pBrush, Ptr, Path)
}

Gdip_DrawImagePointsRect(pGraphics, pBitmap, Points, sx="", sy="", sw="", sh="", Matrix=1) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  StringSplit, Points, Points, |
  VarSetCapacity(PointF, 8*Points0)   
  Loop, %Points0%
  {
    StringSplit, Coord, Points%A_Index%, `,
    NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
  }

  if (Matrix&1 = "")
    ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
  else if (Matrix != 1)
    ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
    
  if (sx = "" && sy = "" && sw = "" && sh = "")
  {
    sx := 0, sy := 0
    sw := Gdip_GetImageWidth(pBitmap)
    sh := Gdip_GetImageHeight(pBitmap)
  }

  E := DllCall("gdiplus\GdipDrawImagePointsRect"
        , Ptr, pGraphics
        , Ptr, pBitmap
        , Ptr, &PointF
        , "int", Points0
        , "float", sx, "float", sy
        , "float", sw, "float", sh
        , "int", 2
        , Ptr, ImageAttr
        , Ptr, 0
        , Ptr, 0)
  if ImageAttr
    Gdip_DisposeImageAttributes(ImageAttr)
  return E
}

Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  if (Matrix&1 = "")
    ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
  else if (Matrix != 1)
    ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")

  if (sx = "" && sy = "" && sw = "" && sh = "")
  {
    if (dx = "" && dy = "" && dw = "" && dh = "")
    {
      sx := dx := 0, sy := dy := 0
      sw := dw := Gdip_GetImageWidth(pBitmap)
      sh := dh := Gdip_GetImageHeight(pBitmap)
    }
    else
    {
      sx := sy := 0
      sw := Gdip_GetImageWidth(pBitmap)
      sh := Gdip_GetImageHeight(pBitmap)
    }
  }

  E := DllCall("gdiplus\GdipDrawImageRectRect"
        , Ptr, pGraphics
        , Ptr, pBitmap
        , "float", dx, "float", dy
        , "float", dw, "float", dh
        , "float", sx, "float", sy
        , "float", sw, "float", sh
        , "int", 2
        , Ptr, ImageAttr
        , Ptr, 0
        , Ptr, 0)
  if ImageAttr
    Gdip_DisposeImageAttributes(ImageAttr)
  return E
}

Gdip_SetImageAttributesColorMatrix(Matrix) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  VarSetCapacity(ColourMatrix, 100, 0)
  Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
  StringSplit, Matrix, Matrix, |
  Loop, 25
  {
    Matrix := (Matrix%A_Index% != "") ? Matrix%A_Index% : Mod(A_Index-1, 6) ? 0 : 1
    NumPut(Matrix, ColourMatrix, (A_Index-1)*4, "float")
  }
  rezA := DllCall("gdiplus\GdipCreateImageAttributes", A_PtrSize ? "UPtr*" : "uint*", ImageAttr)
  rezB := DllCall("gdiplus\GdipSetImageAttributesColorMatrix", Ptr, ImageAttr, "int", 1, "int", 1, Ptr, &ColourMatrix, Ptr, 0, "int", 0)
  return ImageAttr
}

Gdip_GraphicsFromImage(pBitmap) {
  rez := DllCall("gdiplus\GdipGetImageGraphicsContext", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)
  return pGraphics
}

Gdip_GraphicsFromHDC(hdc) {
  rez := DllCall("gdiplus\GdipCreateFromHDC", A_PtrSize ? "UPtr" : "UInt", hdc, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)
  return pGraphics
}

Gdip_GetDC(pGraphics) {
  rez := DllCall("gdiplus\GdipGetDC", A_PtrSize ? "UPtr" : "UInt", pGraphics, A_PtrSize ? "UPtr*" : "UInt*", hdc)
  return hdc
}

Gdip_ReleaseDC(pGraphics, hdc) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipReleaseDC", Ptr, pGraphics, Ptr, hdc)
}

Gdip_GraphicsClear(pGraphics, ARGB=0x00ffffff) {
  return DllCall("gdiplus\GdipGraphicsClear", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", ARGB)
}

Gdip_BlurBitmap(pBitmap, Blur) {
  if (Blur > 100) || (Blur < 1)
    return -1  
  
  sWidth := Gdip_GetImageWidth(pBitmap), sHeight := Gdip_GetImageHeight(pBitmap)
  dWidth := sWidth//Blur, dHeight := sHeight//Blur

  pBitmap1 := Gdip_CreateBitmap(dWidth, dHeight)
  G1 := Gdip_GraphicsFromImage(pBitmap1)
  Gdip_SetInterpolationMode(G1, 7)
  Gdip_DrawImage(G1, pBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)

  Gdip_DeleteGraphics(G1)

  pBitmap2 := Gdip_CreateBitmap(sWidth, sHeight)
  G2 := Gdip_GraphicsFromImage(pBitmap2)
  Gdip_SetInterpolationMode(G2, 7)
  Gdip_DrawImage(G2, pBitmap1, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight)

  Gdip_DeleteGraphics(G2)
  Gdip_DisposeImage(pBitmap1)
  return pBitmap2
}

Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=75) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  SplitPath, sOutput,,, Extension
  if Extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
    return -1
  Extension := "." Extension

  DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
  VarSetCapacity(ci, nSize)
  DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, Ptr, &ci)
  if !(nCount && nSize)
    return -2
  
  If (A_IsUnicode){
    StrGet_Name := "StrGet"
    Loop, %nCount%
    {
      sString := %StrGet_Name%(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
      if !InStr(sString, "*" Extension)
        continue
      
      pCodec := &ci+idx
      break
    }
  } else {
    Loop, %nCount%
    {
      Location := NumGet(ci, 76*(A_Index-1)+44)
      nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
      VarSetCapacity(sString, nSize)
      DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
      if !InStr(sString, "*" Extension)
        continue
      
      pCodec := &ci+76*(A_Index-1)
      break
    }
  }
  
  if !pCodec
    return -3

  if (Quality != 75)
  {
    Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
    if Extension in .JPG,.JPEG,.JPE,.JFIF
    {
      DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, "uint*", nSize)
      VarSetCapacity(EncoderParameters, nSize, 0)
      DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, "uint", nSize, Ptr, &EncoderParameters)
      Loop, % NumGet(EncoderParameters, "UInt")      ;%
      {
        elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
        if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
        {
          p := elem+&EncoderParameters-pad-4
          NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
          break
        }
      }      
    }
  }

  if (!A_IsUnicode)
  {
    nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sOutput, "int", -1, Ptr, 0, "int", 0)
    VarSetCapacity(wOutput, nSize*2)
    DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sOutput, "int", -1, Ptr, &wOutput, "int", nSize)
    VarSetCapacity(wOutput, -1)
    if !VarSetCapacity(wOutput)
      return -4
    E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &wOutput, Ptr, pCodec, "uint", p ? p : 0)
  }
  else
    E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &sOutput, Ptr, pCodec, "uint", p ? p : 0)
  return E ? -5 : 0
}

Gdip_GetPixel(pBitmap, x, y) {
  rez := DllCall("gdiplus\GdipBitmapGetPixel", A_PtrSize ? "UPtr" : "UInt", pBitmap, "int", x, "int", y, "uint*", ARGB)
  return ARGB
}

Gdip_SetPixel(pBitmap, x, y, ARGB) {
   return DllCall("gdiplus\GdipBitmapSetPixel", A_PtrSize ? "UPtr" : "UInt", pBitmap, "int", x, "int", y, "int", ARGB)
}

Gdip_GetImageWidth(pBitmap) {
   rez := DllCall("gdiplus\GdipGetImageWidth", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Width)
   return Width
}

Gdip_GetImageHeight(pBitmap) {
   rez := DllCall("gdiplus\GdipGetImageHeight", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Height)
   return Height
}

Gdip_GetImageDimensions(pBitmap, ByRef Width, ByRef Height) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  rezA := DllCall("gdiplus\GdipGetImageWidth", Ptr, pBitmap, "uint*", Width)
  rezB := DllCall("gdiplus\GdipGetImageHeight", Ptr, pBitmap, "uint*", Height)
}

Gdip_GetDimensions(pBitmap, ByRef Width, ByRef Height) {
  Gdip_GetImageDimensions(pBitmap, Width, Height)
}

Gdip_GetImagePixelFormat(pBitmap) {
  rez := DllCall("gdiplus\GdipGetImagePixelFormat", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "UInt*", Format)
  return Format
}

Gdip_GetDpiX(pGraphics) {
  rez := DllCall("gdiplus\GdipGetDpiX", A_PtrSize ? "UPtr" : "uint", pGraphics, "float*", dpix)
  return Round(dpix)
}

Gdip_GetDpiY(pGraphics) {
  rez := DllCall("gdiplus\GdipGetDpiY", A_PtrSize ? "UPtr" : "uint", pGraphics, "float*", dpiy)
  return Round(dpiy)
}

Gdip_GetImageHorizontalResolution(pBitmap) {
  rez := DllCall("gdiplus\GdipGetImageHorizontalResolution", A_PtrSize ? "UPtr" : "uint", pBitmap, "float*", dpix)
  return Round(dpix)
}

Gdip_GetImageVerticalResolution(pBitmap) {
  rez := DllCall("gdiplus\GdipGetImageVerticalResolution", A_PtrSize ? "UPtr" : "uint", pBitmap, "float*", dpiy)
  return Round(dpiy)
}

Gdip_BitmapSetResolution(pBitmap, dpix, dpiy) {
  return DllCall("gdiplus\GdipBitmapSetResolution", A_PtrSize ? "UPtr" : "uint", pBitmap, "float", dpix, "float", dpiy)
}

Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="") {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  PtrA := A_PtrSize ? "UPtr*" : "UInt*"
  
  SplitPath, sFile,,, ext
  if ext in exe,dll
  {
    Sizes := IconSize ? IconSize : 256 "|" 128 "|" 64 "|" 48 "|" 32 "|" 16
    BufSize := 16 + (2*(A_PtrSize ? A_PtrSize : 4))
    
    VarSetCapacity(buf, BufSize, 0)
    Loop, Parse, Sizes, |
    {
      DllCall("PrivateExtractIcons", "str", sFile, "int", IconNumber-1, "int", A_LoopField, "int", A_LoopField, PtrA, hIcon, PtrA, 0, "uint", 1, "uint", 0)
      
      if !hIcon
        continue

      if !DllCall("GetIconInfo", Ptr, hIcon, Ptr, &buf)
      {
        DestroyIcon(hIcon)
        continue
      }
      
      hbmMask  := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4))
      hbmColor := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4) + (A_PtrSize ? A_PtrSize : 4))
      if !(hbmColor && DllCall("GetObject", Ptr, hbmColor, "int", BufSize, Ptr, &buf))
      {
        DestroyIcon(hIcon)
        continue
      }
      break
    }
    if !hIcon
      return -1

    Width := NumGet(buf, 4, "int"), Height := NumGet(buf, 8, "int")
    hbm := CreateDIBSection(Width, -Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
    if !DllCall("DrawIconEx", Ptr, hdc, "int", 0, "int", 0, Ptr, hIcon, "uint", Width, "uint", Height, "uint", 0, Ptr, 0, "uint", 3)
    {
      DestroyIcon(hIcon)
      return -2
    }
    
    VarSetCapacity(dib, 104)
    DllCall("GetObject", Ptr, hbm, "int", A_PtrSize = 8 ? 104 : 84, Ptr, &dib) ; sizeof(DIBSECTION) = 76+2*(A_PtrSize=8?4:0)+2*A_PtrSize
    Stride := NumGet(dib, 12, "Int"), Bits := NumGet(dib, 20 + (A_PtrSize = 8 ? 4 : 0)) ; padding
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", Stride, "int", 0x26200A, Ptr, Bits, PtrA, pBitmapOld)
    pBitmap := Gdip_CreateBitmap(Width, Height)
    G := Gdip_GraphicsFromImage(pBitmap)
    , Gdip_DrawImage(G, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
    SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
    Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapOld)
    DestroyIcon(hIcon)
  } else
  {
    if (!A_IsUnicode)
    {
      VarSetCapacity(wFile, 1024)
      DllCall("kernel32\MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sFile, "int", -1, Ptr, &wFile, "int", 512)
      DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &wFile, PtrA, pBitmap)
    } else
      DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &sFile, PtrA, pBitmap)
  }
  
  return pBitmap
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  rez := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", Ptr, hBitmap, Ptr, Palette, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
  return pBitmap
}

Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff) {
  rez := DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hbm, "int", Background)
  return hbm
}

Gdip_CreateBitmapFromHICON(hIcon) {
  rez := DllCall("gdiplus\GdipCreateBitmapFromHICON", A_PtrSize ? "UPtr" : "UInt", hIcon, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
  return pBitmap
}

Gdip_CreateHICONFromBitmap(pBitmap) {
  rez := DllCall("gdiplus\GdipCreateHICONFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hIcon)
  return hIcon
}

Gdip_CreateBitmap(Width, Height, Format=0x26200A) {
    rez := DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, A_PtrSize ? "UPtr" : "UInt", 0, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
    Return pBitmap
}

Gdip_CreateBitmapFromClipboard() {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  if !DllCall("OpenClipboard", Ptr, 0)
    return -1
  if !DllCall("IsClipboardFormatAvailable", "uint", 8)
    return -2
  if !hBitmap := DllCall("GetClipboardData", "uint", 2, Ptr)
    return -3
  if !pBitmap := Gdip_CreateBitmapFromHBITMAP(hBitmap)
    return -4
  if !DllCall("CloseClipboard")
    return -5
  DeleteObject(hBitmap)
  return pBitmap
}

Gdip_SetBitmapToClipboard(pBitmap) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  off1 := A_PtrSize = 8 ? 52 : 44, off2 := A_PtrSize = 8 ? 32 : 24
  hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
  DllCall("GetObject", Ptr, hBitmap, "int", VarSetCapacity(oi, A_PtrSize = 8 ? 104 : 84, 0), Ptr, &oi)
  hdib := DllCall("GlobalAlloc", "uint", 2, Ptr, 40+NumGet(oi, off1, "UInt"), Ptr)
  pdib := DllCall("GlobalLock", Ptr, hdib, Ptr)
  DllCall("RtlMoveMemory", Ptr, pdib, Ptr, &oi+off2, Ptr, 40)
  DllCall("RtlMoveMemory", Ptr, pdib+40, Ptr, NumGet(oi, off2 - (A_PtrSize ? A_PtrSize : 4), Ptr), Ptr, NumGet(oi, off1, "UInt"))
  DllCall("GlobalUnlock", Ptr, hdib)
  DllCall("DeleteObject", Ptr, hBitmap)
  DllCall("OpenClipboard", Ptr, 0)
  DllCall("EmptyClipboard")
  DllCall("SetClipboardData", "uint", 8, Ptr, hdib)
  DllCall("CloseClipboard")
}

Gdip_CloneBitmapArea(pBitmap, x, y, w, h, Format=0x26200A) {
  rez := DllCall("gdiplus\GdipCloneBitmapArea"
          , "float", x, "float", y
          , "float", w, "float", h
          , "int", Format
          , A_PtrSize ? "UPtr" : "UInt", pBitmap
          , A_PtrSize ? "UPtr*" : "UInt*", pBitmapDest)
  return pBitmapDest
}

Gdip_CreatePen(ARGB, w) {
   rez := DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "float", w, "int", 2, A_PtrSize ? "UPtr*" : "UInt*", pPen)
   return pPen
}

Gdip_CreatePenFromBrush(pBrush, w) {
  rez := DllCall("gdiplus\GdipCreatePen2", A_PtrSize ? "UPtr" : "UInt", pBrush, "float", w, "int", 2, A_PtrSize ? "UPtr*" : "UInt*", pPen)
  return pPen
}

Gdip_BrushCreateSolid(ARGB=0xff000000) {
  rez := DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, A_PtrSize ? "UPtr*" : "UInt*", pBrush)
  return pBrush
}

Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle=0) {
  rez := DllCall("gdiplus\GdipCreateHatchBrush", "int", HatchStyle, "UInt", ARGBfront, "UInt", ARGBback, A_PtrSize ? "UPtr*" : "UInt*", pBrush)
  return pBrush
}

Gdip_CreateTextureBrush(pBitmap, WrapMode=1, x=0, y=0, w="", h="") {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  , PtrA := A_PtrSize ? "UPtr*" : "UInt*"
  
  if !(w && h)
    rez := DllCall("gdiplus\GdipCreateTexture", Ptr, pBitmap, "int", WrapMode, PtrA, pBrush)
  else
    rez := DllCall("gdiplus\GdipCreateTexture2", Ptr, pBitmap, "int", WrapMode, "float", x, "float", y, "float", w, "float", h, PtrA, pBrush)
  return pBrush
}

Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode=1) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  CreatePointF(PointF1, x1, y1), CreatePointF(PointF2, x2, y2)
  rez := DllCall("gdiplus\GdipCreateLineBrush", Ptr, &PointF1, Ptr, &PointF2, "Uint", ARGB1, "Uint", ARGB2, "int", WrapMode, A_PtrSize ? "UPtr*" : "UInt*", LGpBrush)
  return LGpBrush
}

Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode=1, WrapMode=1) {
  CreateRectF(RectF, x, y, w, h)
  rez := DllCall("gdiplus\GdipCreateLineBrushFromRect", A_PtrSize ? "UPtr" : "UInt", &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, A_PtrSize ? "UPtr*" : "UInt*", LGpBrush)
  return LGpBrush
}

Gdip_CloneBrush(pBrush) {
  rez := DllCall("gdiplus\GdipCloneBrush", A_PtrSize ? "UPtr" : "UInt", pBrush, A_PtrSize ? "UPtr*" : "UInt*", pBrushClone)
  return pBrushClone
}

Gdip_DeletePen(pPen) {
  return DllCall("gdiplus\GdipDeletePen", A_PtrSize ? "UPtr" : "UInt", pPen)
}

Gdip_DeleteBrush(pBrush) {
  return DllCall("gdiplus\GdipDeleteBrush", A_PtrSize ? "UPtr" : "UInt", pBrush)
}

Gdip_DisposeImage(pBitmap) {
  return DllCall("gdiplus\GdipDisposeImage", A_PtrSize ? "UPtr" : "UInt", pBitmap)
}

Gdip_DeleteGraphics(pGraphics) {
  return DllCall("gdiplus\GdipDeleteGraphics", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}

Gdip_DisposeImageAttributes(ImageAttr) {
  return DllCall("gdiplus\GdipDisposeImageAttributes", A_PtrSize ? "UPtr" : "UInt", ImageAttr)
}

Gdip_DeleteFont(hFont) {
  return DllCall("gdiplus\GdipDeleteFont", A_PtrSize ? "UPtr" : "UInt", hFont)
}

Gdip_DeleteStringFormat(hFormat) {
  return DllCall("gdiplus\GdipDeleteStringFormat", A_PtrSize ? "UPtr" : "UInt", hFormat)
}

Gdip_DeleteFontFamily(hFamily) {
  return DllCall("gdiplus\GdipDeleteFontFamily", A_PtrSize ? "UPtr" : "UInt", hFamily)
}

Gdip_DeleteMatrix(Matrix) {
   return DllCall("gdiplus\GdipDeleteMatrix", A_PtrSize ? "UPtr" : "UInt", Matrix)
}

Gdip_TextToGraphics(pGraphics, Text, Options, Font="Arial", Width="", Height="", Measure=0) {
  IWidth := Width, IHeight:= Height
  
  RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
  RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
  RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
  RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
  RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", Colour)
  RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
  RegExMatch(Options, "i)NoWrap", NoWrap)
  RegExMatch(Options, "i)R(\d)", Rendering)
  RegExMatch(Options, "i)S(\d+)(p*)", Size)

  if !Gdip_DeleteBrush(Gdip_CloneBrush(Colour2))
    PassBrush := 1, pBrush := Colour2
  
  if !(IWidth && IHeight) && (xpos2 || ypos2 || Width2 || Height2 || Size2)
    return -1

  Style := 0, Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
  Loop, Parse, Styles, |
  {
    if RegExMatch(Options, "\b" A_loopField)
    Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
  }
  
  Align := 0, Alignments := "Near|Left|Centre|Center|Far|Right"
  Loop, Parse, Alignments, |
  {
    if RegExMatch(Options, "\b" A_loopField)
      Align |= A_Index//2.1      ; 0|0|1|1|2|2
  }

  xpos := (xpos1 != "") ? xpos2 ? IWidth*(xpos1/100) : xpos1 : 0
  ypos := (ypos1 != "") ? ypos2 ? IHeight*(ypos1/100) : ypos1 : 0
  Width := Width1 ? Width2 ? IWidth*(Width1/100) : Width1 : IWidth
  Height := Height1 ? Height2 ? IHeight*(Height1/100) : Height1 : IHeight
  if !PassBrush
    Colour := "0x" (Colour2 ? Colour2 : "ff000000")
  Rendering := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
  Size := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12

  hFamily := Gdip_FontFamilyCreate(Font)
  hFont := Gdip_FontCreate(hFamily, Size, Style)
  FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000
  hFormat := Gdip_StringFormatCreate(FormatStyle)
  pBrush := PassBrush ? pBrush : Gdip_BrushCreateSolid(Colour)
  if !(hFamily && hFont && hFormat && pBrush && pGraphics)
    return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0
   
  CreateRectF(RC, xpos, ypos, Width, Height)
  Gdip_SetStringFormatAlign(hFormat, Align)
  Gdip_SetTextRenderingHint(pGraphics, Rendering)
  ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)

  if vPos
  {
    StringSplit, ReturnRC, ReturnRC, |
    
    if (vPos = "vCentre") || (vPos = "vCenter")
      ypos += (Height-ReturnRC4)//2
    else if (vPos = "Top") || (vPos = "Up")
      ypos := 0
    else if (vPos = "Bottom") || (vPos = "Down")
      ypos := Height-ReturnRC4
    
    CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
    ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
  }

  if !Measure
    E := Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, RC)

  if !PassBrush
    Gdip_DeleteBrush(pBrush)
  Gdip_DeleteStringFormat(hFormat)   
  Gdip_DeleteFont(hFont)
  Gdip_DeleteFontFamily(hFamily)
  return E ? E : ReturnRC
}

Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  if (!A_IsUnicode)
  {
    nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, 0, "int", 0)
    VarSetCapacity(wString, nSize*2)
    DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, &wString, "int", nSize)
  }
  
  return DllCall("gdiplus\GdipDrawString"
          , Ptr, pGraphics
          , Ptr, A_IsUnicode ? &sString : &wString
          , "int", -1
          , Ptr, hFont
          , Ptr, &RectF
          , Ptr, hFormat
          , Ptr, pBrush)
}

Gdip_MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  VarSetCapacity(RC, 16)
  if !A_IsUnicode
  {
    nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, "uint", 0, "int", 0)
    VarSetCapacity(wString, nSize*2)   
    DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sString, "int", -1, Ptr, &wString, "int", nSize)
  }
  
  DllCall("gdiplus\GdipMeasureString"
          , Ptr, pGraphics
          , Ptr, A_IsUnicode ? &sString : &wString
          , "int", -1
          , Ptr, hFont
          , Ptr, &RectF
          , Ptr, hFormat
          , Ptr, &RC
          , "uint*", Chars
          , "uint*", Lines)
  
  return &RC ? NumGet(RC, 0, "float") "|" NumGet(RC, 4, "float") "|" NumGet(RC, 8, "float") "|" NumGet(RC, 12, "float") "|" Chars "|" Lines : 0
}

Gdip_SetStringFormatAlign(hFormat, Align) {
   return DllCall("gdiplus\GdipSetStringFormatAlign", A_PtrSize ? "UPtr" : "UInt", hFormat, "int", Align)
}

Gdip_StringFormatCreate(Format=0, Lang=0) {
   DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, A_PtrSize ? "UPtr*" : "UInt*", hFormat)
   return hFormat
}

Gdip_FontCreate(hFamily, Size, Style=0) {
   DllCall("gdiplus\GdipCreateFont", A_PtrSize ? "UPtr" : "UInt", hFamily, "float", Size, "int", Style, "int", 0, A_PtrSize ? "UPtr*" : "UInt*", hFont)
   return hFont
}

Gdip_FontFamilyCreate(Font) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  if (!A_IsUnicode)
  {
    nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, "uint", 0, "int", 0)
    VarSetCapacity(wFont, nSize*2)
    DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &Font, "int", -1, Ptr, &wFont, "int", nSize)
  }
  
  DllCall("gdiplus\GdipCreateFontFamilyFromName"
          , Ptr, A_IsUnicode ? &Font : &wFont
          , "uint", 0
          , A_PtrSize ? "UPtr*" : "UInt*", hFamily)
  
  return hFamily
}

Gdip_CreateAffineMatrix(m11, m12, m21, m22, x, y) {
   DllCall("gdiplus\GdipCreateMatrix2", "float", m11, "float", m12, "float", m21, "float", m22, "float", x, "float", y, A_PtrSize ? "UPtr*" : "UInt*", Matrix)
   return Matrix
}

Gdip_CreateMatrix() {
   DllCall("gdiplus\GdipCreateMatrix", A_PtrSize ? "UPtr*" : "UInt*", Matrix)
   return Matrix
}

Gdip_CreatePath(BrushMode=0) {
  DllCall("gdiplus\GdipCreatePath", "int", BrushMode, A_PtrSize ? "UPtr*" : "UInt*", Path)
  return Path
}

Gdip_AddPathEllipse(Path, x, y, w, h) {
  return DllCall("gdiplus\GdipAddPathEllipse", A_PtrSize ? "UPtr" : "UInt", Path, "float", x, "float", y, "float", w, "float", h)
}

Gdip_AddPathPolygon(Path, Points) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  StringSplit, Points, Points, |
  VarSetCapacity(PointF, 8*Points0)   
  Loop, %Points0%
  {
    StringSplit, Coord, Points%A_Index%, `,
    NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
  }   

  return DllCall("gdiplus\GdipAddPathPolygon", Ptr, Path, Ptr, &PointF, "int", Points0)
}

Gdip_DeletePath(Path) {
  return DllCall("gdiplus\GdipDeletePath", A_PtrSize ? "UPtr" : "UInt", Path)
}

Gdip_SetTextRenderingHint(pGraphics, RenderingHint) {
  return DllCall("gdiplus\GdipSetTextRenderingHint", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", RenderingHint)
}

Gdip_SetInterpolationMode(pGraphics, InterpolationMode) {
   return DllCall("gdiplus\GdipSetInterpolationMode", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", InterpolationMode)
}

Gdip_SetSmoothingMode(pGraphics, SmoothingMode) {
   return DllCall("gdiplus\GdipSetSmoothingMode", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", SmoothingMode)
}

Gdip_SetCompositingMode(pGraphics, CompositingMode=0) {
   return DllCall("gdiplus\GdipSetCompositingMode", A_PtrSize ? "UPtr" : "UInt", pGraphics, "int", CompositingMode)
}

Gdip_Startup() {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  if !DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
    DllCall("LoadLibrary", "str", "gdiplus")
  VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
  DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pToken, Ptr, &si, Ptr, 0)
  return pToken
}

Gdip_Shutdown(pToken) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  
  DllCall("gdiplus\GdiplusShutdown", Ptr, pToken)
  if hModule := DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
    DllCall("FreeLibrary", Ptr, hModule)
  return 0
}

Gdip_RotateWorldTransform(pGraphics, Angle, MatrixOrder=0) {
  return DllCall("gdiplus\GdipRotateWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", Angle, "int", MatrixOrder)
}

Gdip_ScaleWorldTransform(pGraphics, x, y, MatrixOrder=0) {
  return DllCall("gdiplus\GdipScaleWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", x, "float", y, "int", MatrixOrder)
}

Gdip_TranslateWorldTransform(pGraphics, x, y, MatrixOrder=0) {
  return DllCall("gdiplus\GdipTranslateWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", x, "float", y, "int", MatrixOrder)
}

Gdip_ResetWorldTransform(pGraphics) {
  return DllCall("gdiplus\GdipResetWorldTransform", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}

Gdip_GetRotatedTranslation(Width, Height, Angle, ByRef xTranslation, ByRef yTranslation) {
  pi := 3.14159, TAngle := Angle*(pi/180)  

  Bound := (Angle >= 0) ? Mod(Angle, 360) : 360-Mod(-Angle, -360)
  if ((Bound >= 0) && (Bound <= 90))
    xTranslation := Height*Sin(TAngle), yTranslation := 0
  else if ((Bound > 90) && (Bound <= 180))
    xTranslation := (Height*Sin(TAngle))-(Width*Cos(TAngle)), yTranslation := -Height*Cos(TAngle)
  else if ((Bound > 180) && (Bound <= 270))
    xTranslation := -(Width*Cos(TAngle)), yTranslation := -(Height*Cos(TAngle))-(Width*Sin(TAngle))
  else if ((Bound > 270) && (Bound <= 360))
    xTranslation := 0, yTranslation := -Width*Sin(TAngle)
}

Gdip_GetRotatedDimensions(Width, Height, Angle, ByRef RWidth, ByRef RHeight) {
  pi := 3.14159, TAngle := Angle*(pi/180)
  if !(Width && Height)
    return -1
  RWidth := Ceil(Abs(Width*Cos(TAngle))+Abs(Height*Sin(TAngle)))
  RHeight := Ceil(Abs(Width*Sin(TAngle))+Abs(Height*Cos(Tangle)))
}

Gdip_ImageRotateFlip(pBitmap, RotateFlipType=1) {
  return DllCall("gdiplus\GdipImageRotateFlip", A_PtrSize ? "UPtr" : "UInt", pBitmap, "int", RotateFlipType)
}

Gdip_SetClipRect(pGraphics, x, y, w, h, CombineMode=0) {
   return DllCall("gdiplus\GdipSetClipRect",  A_PtrSize ? "UPtr" : "UInt", pGraphics, "float", x, "float", y, "float", w, "float", h, "int", CombineMode)
}

Gdip_SetClipPath(pGraphics, Path, CombineMode=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipSetClipPath", Ptr, pGraphics, Ptr, Path, "int", CombineMode)
}

Gdip_ResetClip(pGraphics) {
   return DllCall("gdiplus\GdipResetClip", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}

Gdip_GetClipRegion(pGraphics) {
  Region := Gdip_CreateRegion()
  DllCall("gdiplus\GdipGetClip", A_PtrSize ? "UPtr" : "UInt", pGraphics, "UInt*", Region)
  return Region
}

Gdip_SetClipRegion(pGraphics, Region, CombineMode=0) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("gdiplus\GdipSetClipRegion", Ptr, pGraphics, Ptr, Region, "int", CombineMode)
}

Gdip_CreateRegion() {
  DllCall("gdiplus\GdipCreateRegion", "UInt*", Region)
  return Region
}

Gdip_DeleteRegion(Region) {
  return DllCall("gdiplus\GdipDeleteRegion", A_PtrSize ? "UPtr" : "UInt", Region)
}

Gdip_LockBits(pBitmap, x, y, w, h, ByRef Stride, ByRef Scan0, ByRef BitmapData, LockMode = 3, PixelFormat = 0x26200a) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  CreateRect(Rect, x, y, w, h)
  VarSetCapacity(BitmapData, 16+2*(A_PtrSize ? A_PtrSize : 4), 0)
  E := DllCall("Gdiplus\GdipBitmapLockBits", Ptr, pBitmap, Ptr, &Rect, "uint", LockMode, "int", PixelFormat, Ptr, &BitmapData)
  Stride := NumGet(BitmapData, 8, "Int")
  Scan0 := NumGet(BitmapData, 16, Ptr)
  return E
}

Gdip_UnlockBits(pBitmap, ByRef BitmapData) {
  Ptr := A_PtrSize ? "UPtr" : "UInt"
  return DllCall("Gdiplus\GdipBitmapUnlockBits", Ptr, pBitmap, Ptr, &BitmapData)
}

Gdip_SetLockBitPixel(ARGB, Scan0, x, y, Stride) {
  Numput(ARGB, Scan0+0, (x*4)+(y*Stride), "UInt")
}

Gdip_GetLockBitPixel(Scan0, x, y, Stride) {
  return NumGet(Scan0+0, (x*4)+(y*Stride), "UInt")
}

Gdip_ToARGB(A, R, G, B) {
  return (A << 24) | (R << 16) | (G << 8) | B
}

Gdip_FromARGB(ARGB, ByRef A, ByRef R, ByRef G, ByRef B) {
  A := (0xff000000 & ARGB) >> 24
  R := (0x00ff0000 & ARGB) >> 16
  G := (0x0000ff00 & ARGB) >> 8
  B := 0x000000ff & ARGB
}

Gdip_AFromARGB(ARGB) {
  return (0xff000000 & ARGB) >> 24
}

Gdip_RFromARGB(ARGB) {
  return (0x00ff0000 & ARGB) >> 16
}


Gdip_GFromARGB(ARGB) {
  return (0x0000ff00 & ARGB) >> 8
}

Gdip_BFromARGB(ARGB) {
  return 0x000000ff & ARGB
}

StrGetB(Address, Length=-1, Encoding=0) {
  ; Flexible parameter handling:
  if Length is not integer
  Encoding := Length,  Length := -1

  ; Check for obvious errors.
  if (Address+0 < 1024)
    return

  ; Ensure 'Encoding' contains a numeric identifier.
  if Encoding = UTF-16
    Encoding = 1200
  else if Encoding = UTF-8
    Encoding = 65001
  else if SubStr(Encoding,1,2)="CP"
    Encoding := SubStr(Encoding,3)

  if !Encoding ; "" or 0
  {
    ; No conversion necessary, but we might not want the whole string.
    if (Length == -1)
      Length := DllCall("lstrlen", "uint", Address)
    VarSetCapacity(String, Length)
    DllCall("lstrcpyn", "str", String, "uint", Address, "int", Length + 1)
  }
  else if Encoding = 1200 ; UTF-16
  {
    char_count := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0x400, "uint", Address, "int", Length, "uint", 0, "uint", 0, "uint", 0, "uint", 0)
    VarSetCapacity(String, char_count)
    DllCall("WideCharToMultiByte", "uint", 0, "uint", 0x400, "uint", Address, "int", Length, "str", String, "int", char_count, "uint", 0, "uint", 0)
  }
  else if Encoding is integer
  {
    ; Convert from target encoding to UTF-16 then to the active code page.
    char_count := DllCall("MultiByteToWideChar", "uint", Encoding, "uint", 0, "uint", Address, "int", Length, "uint", 0, "int", 0)
    VarSetCapacity(String, char_count * 2)
    char_count := DllCall("MultiByteToWideChar", "uint", Encoding, "uint", 0, "uint", Address, "int", Length, "uint", &String, "int", char_count * 2)
    String := StrGetB(&String, char_count, 1200)
  }
  
  return String
}
