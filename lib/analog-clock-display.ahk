; from https://autohotkey.com/board/topic/34692-examplesminituts-the-gdi-examplecodes-thread/#entry219089
; GDI+ ahk analogue clock example written by derRaphael
; posted on 17 November 2008 - 06:15 PM.
; extensively modified by Marius Șucan in January 2019
; Parts based on examples from Tic's GDI+ Tutorials and of course on his GDIP.ahk

; This code has been licensed under the terms of EUPL 1.0

InitClockFace() {
   Critical, on
   If (!pToken := Gdip_Startup())
   {
      constantAnalogClock := analogDisplay := 0
      SoundBeep , 300, 900
      Return
   }

   faceElements := OSDbgrColor
   faceBgrColor := OSDtextColor
   If (moduleAnalogClockInit!=1 || PrefOpen=1)
   {
      If (constantAnalogClock=1 && PrefOpen=0)
      {
         INIaction(0, "ClockGuiX", "OSDprefs")
         INIaction(0, "ClockGuiY", "OSDprefs")
      }
      ; ToolTip, % ClockGuiX "==" ClockGuiY , , , 2
      ClockPosX := (constantAnalogClock=1 && PrefOpen=0) ? ClockGuiX : GuiX
      ClockPosY := (constantAnalogClock=1 && PrefOpen=0) ? ClockGuiY : GuiY
   }

   ClockDiameter := Round(FontSize * 4 * analogDisplayScale)
   ClockWinSize := ClockDiameter + Round((OSDmarginBottom//2 + OSDmarginTop//2 + OSDmarginSides//2) * analogDisplayScale)
   roundsize := Round(roundedCsize * (analogDisplayScale/1.5))
   If (ClockDiameter<=80)
   {
      ClockDiameter := 80
      ClockWinSize := 90
      roundsize := 20
   }

   ClockCenter := Round(ClockWinSize/2)
   If (OSDroundCorners!=1)
      roundsize := 1

   SetFormat, Integer, H
   faceOpacity+=0
   faceOpacityBgr+=0
   SetFormat, Integer, D

   Width := Height := ClockWinSize + 2      ; make width and height slightly bigger to avoid cut away edges
   Gui, ClockGui: Destroy
   Sleep, 25
   Gui, ClockGui: -DPIScale -Caption -Border +E0x80000 +AlwaysOnTop +ToolWindow +hwndHfaceClock
   Gui, ClockGui: Show, NoActivate x%ClockPosX% y%ClockPosY% w%Width% h%height%
   Gui, ClockGui: Hide
   ; WinSet, Region, 0-0 R%roundedCsize%-%roundedCsize% w%Width% h%Height%, ahk_id %hFaceClock%
   CenterX := CenterY := ClockCenter

; Prepare our pGraphic so we have a 'canvas' to work upon
   globalhbm := CreateDIBSection(Width, Height), globalhdc := CreateCompatibleDC()
   globalobm := SelectObject(globalhdc, globalhbm), globalG := Gdip_GraphicsFromHDC(globalhdc)
   Gdip_SetSmoothingMode(globalG, 4)
   Gdip_SetInterpolationMode(globalG, 7)

; Draw outer circle
   Diameter := Round(ClockDiameter * 1.35)
   pBrush := Gdip_BrushCreateSolid(faceOpacityBgr faceElements)      ; clock face background 
   Gdip_FillRectangle(globalG, pBrush, 0, 0, Ceil(ClockWinSize), Ceil(ClockWinSize))
   Gdip_FillRoundedRectangle(globalG, pBrush, 0, 0, Ceil(ClockWinSize), Ceil(ClockWinSize), Ceil(roundsize))
   Gdip_DeleteBrush(pBrush)

   Diameter := ClockDiameter - 2*Floor((ClockDiameter//100)*1.2)
   pPen := Gdip_CreatePen("0xaa" faceElements, floor((ClockDiameter/100)*1.2))
   Gdip_DrawEllipse(globalG, pPen, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeletePen(pPen)

; Draw inner circle
   Diameter := Round(ClockDiameter - ClockDiameter*0.04, 2) + Round((ClockDiameter/100)*1.2, 2)  ; white border
   pBrush := Gdip_BrushCreateSolid(faceOpacity faceBgrColor)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

; Draw Second Marks
   Diameter := Round(ClockDiameter - ClockDiameter*0.08, 2)  ; inner circle is 8 % smaller than clock's diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.08, 2) ; inner position
   pPen := Gdip_CreatePen("0xaa" faceElements, (ClockDiameter/100)*1.2) ; 1.2 % of total diameter is our pen width
   If (ClockDiameter>=100)
      DrawClockMarks(60, R1, R2, globalG, pPen)                 ; we have 60 seconds
   Else If (ClockDiameter>=50)
      DrawClockMarks(24, R1, R2+0.1, globalG, pPen)
   Gdip_DeletePen(pPen)

   R2 := Round(Diameter/2 - 1 - Diameter/2*0.04, 2) ; inner position
   pPen := Gdip_CreatePen("0x88" faceElements, (ClockDiameter/100)*0.7) ; 1.2 % of total diameter is our pen width
   If (ClockDiameter>250)
      DrawClockMarks(120, R1, R2, globalG, pPen)                 ; we have 60 seconds
   Gdip_DeletePen(pPen)

; Draw Hour Marks
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.2, 2) ; inner position
   pPen := Gdip_CreatePen("0xff" faceElements, (ClockDiameter/100)*2.3) ; 2.3 % of total diameter is our pen width
   DrawClockMarks(12, R1, R2, globalG, pPen)                  ; we have 12 hours
   Gdip_DeletePen(pPen)
   
   Diameter := Round(ClockDiameter - ClockDiameter*0.17, 2)  ; inner circle is 17 % smaller than clock's diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.2, 2) ; inner position
   pPen := Gdip_CreatePen("0xff" faceElements, (ClockDiameter/100)*4) ; 4 % of total diameter is our pen width
   If (ClockDiameter>250)
      DrawClockMarks(4, R1, R2, globalG, pPen)                  ; we have 4 quarters
   Gdip_DeletePen(pPen)
   
   UpdateLayeredWindow(hFaceClock, globalhdc, , , , , mainOSDopacity)
   moduleAnalogClockInit := 1
   Return
}

animateAnalogClockAppeareance() {
   Loop,
   {
      alphaLevel := A_Index*15
      If (alphaLevel>mainOSDopacity)
         Break

      UpdateLayeredWindow(hFaceClock, globalhdc, , , , , alphaLevel)
      Sleep, 1
   }
}

animateAnalogClockHiding() {
   Loop,
   {
      alphaLevel := mainOSDopacity - A_Index*15
      If (alphaLevel<5)
         Break

      UpdateLayeredWindow(hFaceClock, globalhdc, , , , , alphaLevel)
      Sleep, 1
   }
}

UpdateEverySecond() {
   CenterX := CenterY := ClockCenter

; prepare to empty previously drawn stuff
   Gdip_SetSmoothingMode(globalG, 1)   ; turn off aliasing
   Gdip_SetCompositingMode(globalG, 1) ; set to overdraw
   
; delete previous graphic and redraw background
   Diameter := Round(ClockDiameter - ClockDiameter*0.22, 2)  ; 18 % less than clock's outer diameter
   
   ; delete whatever has been drawn here
   pBrush := Gdip_BrushCreateSolid(0x00000000) ; fully transparent brush 'eraser'
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)
   
   Gdip_SetCompositingMode(globalG, 0) ; switch off overdraw

   pBrush := Gdip_BrushCreateSolid(faceOpacityBgr faceElements)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   pBrush := Gdip_BrushCreateSolid(faceOpacity faceBgrColor)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   Diameter := Round(ClockDiameter*0.08, 2)
   pBrush := Gdip_BrushCreateSolid("0x66" faceElements)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   Diameter := Round(ClockDiameter*0.04, 2)
   pBrush := Gdip_BrushCreateSolid("0x95" faceElements)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY-(Diameter//2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

; draw moon phase
   If (analogMoonPhases=1)
   {
     moonPhase := MoonPhaseCalculator(A_Year, A_Mon, A_MDay)
     moonPhaseF := Round(moonPhase[2])
     darkFace := mixARGB("0xFF" faceElements, "0xFF" faceBgrColor, 0.4)
     brightFace := "0xEE" faceBgrColor
     Diameter := Round(ClockDiameter*0.18, 2)
     If (moonPhaseF=0 || moonPhaseF=4)
     {
        pBrush := (moonPhaseF=0) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
        Diameter := Round(ClockDiameter*0.19, 2)
        Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY + diameter//2, Diameter, Diameter)
        Gdip_DeleteBrush(pBrush)
     } Else If (moonPhaseF=2 || moonPhaseF=6)
     {
        Diameter := Round(ClockDiameter*0.2, 2)
        pBrush := (moonPhaseF=2) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
        Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY + diameter//2.1, Diameter, Diameter)
        Gdip_DeleteBrush(pBrush)

        offsetuC := Diameter
        Gdip_SetClipRect(globalG, CenterX - Diameter//2 + offsetuC*0.5, CenterY + diameter//2.1, Diameter, Diameter)
        pBrush := (moonPhaseF=6) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
        Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter//2), CenterY + diameter//2.1, Diameter, Diameter)
        Gdip_DeleteBrush(pBrush)
        Gdip_ResetClip(globalG)
     } Else If (moonPhaseF=1 || moonPhaseF=5)
     {
        pBrushA := (moonPhaseF=5) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
        pBrushB := (moonPhaseF=1) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
        offsetuC := Diameter
        DiameterZ := Round(ClockDiameter*0.20, 2)
        Gdip_FillEllipse(globalG, pBrushB, CenterX - (DiameterZ/2), CenterY + DiameterZ/2.08, DiameterZ, DiameterZ)
        Gdip_SetClipRect(globalG, CenterX - Diameter/2 + offsetuC*0.5, CenterY + diameter/2.58, Diameter, Diameter*1.25)
        Diameter := Round(ClockDiameter*0.20, 2)
        Gdip_FillEllipse(globalG, pBrushA, CenterX-(Diameter/2), CenterY + diameter/2.08, Diameter, Diameter)
        Gdip_DeleteBrush(pBrushA)

        ; Gdip_SetClipRect(globalG, CenterX - Diameter//2 + offsetuC*0.3, CenterY + diameter//1.81, Diameter, Diameter, 1)
        Gdip_FillEllipse(globalG, pBrushB, CenterX - (Diameter/1.4), CenterY + diameter/2.18, Diameter, Diameter)
        Gdip_DeleteBrush(pBrushB)
        Gdip_ResetClip(globalG)
     } Else If (moonPhaseF=3 || moonPhaseF=7)
     {
        pBrushA := (moonPhaseF=3) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
        pBrushB := (moonPhaseF=7) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
        offsetuC := Diameter
        DiameterZ := Round(ClockDiameter*0.20, 2)
        Gdip_FillEllipse(globalG, pBrushB, CenterX - (DiameterZ/2), CenterY + DiameterZ/2.08, DiameterZ, DiameterZ)
        Gdip_SetClipRect(globalG, CenterX - Diameter, CenterY + diameter/2.58, Diameter, Diameter*1.25)
        Diameter := Round(ClockDiameter*0.20, 2)
        Gdip_FillEllipse(globalG, pBrushA, CenterX-(Diameter/2), CenterY + diameter/2.08, Diameter, Diameter)
        Gdip_DeleteBrush(pBrushA)

        ; Gdip_SetClipRect(globalG, CenterX - Diameter//2 + offsetuC*0.3, CenterY + diameter//1.81, Diameter, Diameter, 1)
        Gdip_FillEllipse(globalG, pBrushB, CenterX - (Diameter/3.4), CenterY + diameter/2.18, Diameter, Diameter)
        Gdip_DeleteBrush(pBrushB)
        Gdip_ResetClip(globalG)
     }

     Diameter := Round(ClockDiameter*0.20, 2)
     pPen := Gdip_CreatePen("0xFF" faceElements, Round((ClockDiameter/100)*1.3, 2))
     Gdip_DrawEllipse(globalG, pPen, CenterX-(Diameter//2), CenterY + diameter//2.25,Diameter, Diameter)
     Gdip_DeletePen(pPen)
   }

; Draw HoursPointer
   Gdip_SetSmoothingMode(globalG, 4)   ; turn on antialiasing
   t := (A_Hour*360//12) + ((A_Min//15*15)*360//60)//12 + 90
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.50, 2) ; outer position
   pPen := Gdip_CreatePen("0xaa" faceElements, Round((ClockDiameter/100)*3.3, 2))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.45, 2) ; outer position
   pPen := Gdip_CreatePen("0xcc" faceElements, Round((ClockDiameter/100)*1.6, 2))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)
   
; Draw MinutesPointer
   t := Round(A_Min*360/60+90, 2)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.35, 2) ; outer position
   pPen := Gdip_CreatePen("0x55" faceElements, Round((ClockDiameter/100)*2.8, 2))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer
   t := Round(A_Sec*360/60+90, 2)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.25, 2) ; outer position
   pPen := Gdip_CreatePen("0x99" faceElements, Round((ClockDiameter/100)*1.3, 2))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer end stick
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.75, 2) ; outer position
   pPen := Gdip_CreatePen("0x99" faceElements, Round((ClockDiameter/100)*1.3, 2))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX + (R1 * Cos(t * Atan(1) * 4 / 180)), 2)
      , Round(CenterY + (R1 * Sin(t * Atan(1) * 4 / 180)), 2))
   Gdip_DeletePen(pPen)

   UpdateLayeredWindow(hFaceClock, globalhdc, , , , , mainOSDopacity)
   Return
}

DrawClockMarks(items, R1, R2, G, pPen) {
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

hideAnalogClock() {
  If (ClockVisibility!=1)
     Return

  If (PrefOpen=0)
     animateAnalogClockHiding()

  Gui, ClockGui: Hide
  SetTimer, UpdateEverySecond, Off
  ClockVisibility := 0
  Return
}

showAnalogClock() {
  If (ClockVisibility!=0)
     Return

  lastShowTime := A_TickCount
  Gui, ClockGui: Show, NoActivate
  UpdateEverySecond()
  SetTimer, UpdateEverySecond, 1000
  If (PrefOpen=0)
     animateAnalogClockAppeareance()

  ClockVisibility := 1
  delayu := Ceil(DisplayTime * 1.25) + 2500
  If (analogDisplay=1 && constantAnalogClock=0 && PrefOpen=0)
     SetTimer, hideAnalogClock, % -delayu

  lastShowTime := A_TickCount
  Return
}

exitAnalogClock() {
   If (PrefOpen=0)
      animateAnalogClockHiding()
   SetTimer, UpdateEverySecond, Off
   Gui, ClockGui: Destroy
   ClockVisibility := 0
   moduleAnalogClockInit := 0
   SelectObject(globalhdc, globalobm)
   DeleteObject(globalhbm)
   DeleteDC(globalhdc)
   Gdip_DeleteGraphics(globalG)
   Gdip_Shutdown(pToken)
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
       Menu, ClockSizesMenu, Add, 0.25x, ChangeMenuClockSize
       Menu, ClockSizesMenu, Add, 0.50x, ChangeMenuClockSize
       Menu, ClockSizesMenu, Add, 1.00x, ChangeMenuClockSize
       Menu, ClockSizesMenu, Add, 1.50x, ChangeMenuClockSize
       Menu, ClockSizesMenu, Add, 2.00x, ChangeMenuClockSize
       Menu, ClockSizesMenu, Add, 3.00x, ChangeMenuClockSize
       Menu, ClockSizesMenu, Add, 4.00x, ChangeMenuClockSize
       menuGenerated := 1
    }

    Menu, ClockSizesMenu, Check, %analogDisplayScale%x
    Menu, ContextMenu, Add, Sc&ale, :ClockSizesMenu
    Menu, ContextMenu, Add, 
    Menu, ContextMenu, Add, &Hide the clock, toggleAnalogClock
    Menu, ContextMenu, Add, Show &moon phases, toggleMoonPhasesAnalog
    If (analogMoonPhases=1)
       Menu, ContextMenu, Check, Show &moon phases

    Menu, ContextMenu, Add, 
    If (PrefOpen=0)
    {
       Menu, ContextMenu, Add, &Tick/tock sounds, ToggleTickTock
       If (tickTockNoise=1)
          Menu, ContextMenu, Check, &Tick/tock sounds
       Menu, ContextMenu, Add, &Settings, ShowSettings
       Menu, ContextMenu, Add, &About, AboutWindow
    }

    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Close menu, dummy
    Menu, ContextMenu, Show
    lastInvoked := A_TickCount
    Return
}

SynchSecTimer() {
  SetTimer, UpdateEverySecond, Off
  SetTimer, UpdateEverySecond, 1000
}

ChangeMenuClockSize() {
  saveAnalogClockPosition()
  Menu, ClockSizesMenu, Uncheck, %analogDisplayScale%x
  StringLeft, newSize, A_ThisMenuItem, 4
  ChangeClockSize(newSize)
}

