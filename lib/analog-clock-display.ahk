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

   faceElements := "111111"
   faceBgrColor := "eeEEee"
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
   ; If (OSDroundCorners!=1)
   ;    roundsize := 1

   SetFormat, Integer, H
   faceOpacity+=0
   faceOpacityBgr+=0
   SetFormat, Integer, D

   Width := Height := ClockWinSize + 2      ; make width and height slightly bigger to avoid cut away edges
   rsz := roundsize*2 ; (width + height)//4
   Global infoWidget
   Gui, ClockGui: Destroy
   Sleep, 25
   Gui, ClockGui: -DPIScale -Caption -Border +E0x80000 +AlwaysOnTop +ToolWindow +hwndHfaceClock
   Gui, ClockGui: Add, Text, x1 y1 w%Width% h%Height% vinfoWidget, Analog clock widget.
   Gui, ClockGui: Show, NoActivate x%ClockPosX% y%ClockPosY% w%Width% h%height%
   If (roundedClock=1)
      WinSet, Region, 0-0 R%rsz%-%rsz% w%Width% h%Height%, ahk_id %hFaceClock%
   Gui, ClockGui: Hide
   CenterX := CenterY := ClockCenter

; Prepare our pGraphic so we have a 'canvas' to work upon
   globalhbm := CreateDIBSection(Width, Height), globalhdc := CreateCompatibleDC()
   globalobm := SelectObject(globalhdc, globalhbm), globalG := Gdip_GraphicsFromHDC(globalhdc)
   Gdip_SetSmoothingMode(globalG, 4)
   Gdip_SetInterpolationMode(globalG, 7)
   ; Gdip_TranslateWorldTransform(globalG, ClockWinSize/4, ClockWinSize/4s)

; Draw outer circle
   Diameter := Round(ClockDiameter * 1.35, 4)
   pBrush := Gdip_BrushCreateSolid(faceOpacityBgr faceElements)      ; clock face background 
   Gdip_FillRectangle(globalG, pBrush, 0, 0, ClockWinSize*1.5, ClockWinSize*1.5)
   Gdip_FillRectangle(globalG, pBrush, 0, 0, ClockWinSize*1.5, ClockWinSize*1.5)
   ; Gdip_FillRoundedRectangle(globalG, pBrush, 0, 0, Ceil(ClockWinSize), Ceil(ClockWinSize), Ceil(roundsize//2))
   Gdip_DeleteBrush(pBrush)

   Diameter := ClockDiameter - 2*Round((ClockDiameter/100)*1.2)
   pPen := Gdip_CreatePen("0xaa" faceElements, Round((ClockDiameter/100)*1.2))
   Gdip_DrawEllipse(globalG, pPen, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeletePen(pPen)

; Draw inner circle
   Diameter := Round(ClockDiameter - ClockDiameter*0.04, 4) + Round((ClockDiameter/100)*1.2, 4)  ; white border
   pBrush := Gdip_BrushCreateSolid(faceOpacity faceBgrColor)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

; Draw Second Marks
   Diameter := Round(ClockDiameter - ClockDiameter*0.08, 4)  ; inner circle is 8 % smaller than clock's Diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.08, 4) ; inner position
   pPen := Gdip_CreatePen("0xaa" faceElements, (ClockDiameter/100)*1.2) ; 1.2 % of total Diameter is our pen width
   sPen := Gdip_CreatePen("0x66" faceElements, (ClockDiameter/100)*1.2) ; 1.2 % of total Diameter is our pen width
   Gdip_DrawEllipse(globalG, sPen, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   If (ClockDiameter>=100)
      DrawClockMarks(60, R1, R2, globalG, pPen)                 ; we have 60 seconds
   Else If (ClockDiameter>=50)
      DrawClockMarks(24, R1, R2+0.1, globalG, pPen)
   Gdip_DeletePen(pPen)
   Gdip_DeletePen(sPen)

   R2 := Round(Diameter/2 - 1 - Diameter/2*0.04, 4) ; inner position
   pPen := Gdip_CreatePen("0x88" faceElements, (ClockDiameter/100)*0.7) ; 1.2 % of total Diameter is our pen width
   If (ClockDiameter>250)
      DrawClockMarks(120, R1, R2, globalG, pPen)                 ; we have 60 seconds
   Gdip_DeletePen(pPen)

; Draw Hour Marks
   R2 := (showAnalogHourLabels=1) ? Round(Diameter/2 - 1 - Diameter/2*0.15, 2) : Round(Diameter/2 - 1 - Diameter/2*0.2, 2) ; inner position
   pPen := Gdip_CreatePen("0xff" faceElements, (ClockDiameter/100)*2.3) ; 2.3 % of total Diameter is our pen width
   DrawClockMarks(12, R1, R2, globalG, pPen)                  ; we have 12 hours
   R2b := Round(Diameter/2 - 1 - Diameter/2*0.20, 4)
   If (showAnalogHourLabels=1)
      DrawHoursLabels(R1, R2b, globalG)
   Gdip_DeletePen(pPen)
   
   Diameter := Round(ClockDiameter - ClockDiameter*0.17, 4)  ; inner circle is 17 % smaller than clock's Diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.2, 4) ; inner position
   pPen := Gdip_CreatePen("0xff" faceElements, (ClockDiameter/100)*4) ; 4 % of total Diameter is our pen width
   If (ClockDiameter>250 && showAnalogHourLabels!=1)
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
   Diameter := Round(ClockDiameter - ClockDiameter*0.22, 4)  ; 18 % less than clock's outer Diameter
   
   ; delete whatever has been drawn here
   pBrush := Gdip_BrushCreateSolid(0x00000000) ; fully transparent brush 'eraser'
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)
   
   Gdip_SetCompositingMode(globalG, 0) ; switch off overdraw

   pBrush := Gdip_BrushCreateSolid(faceOpacityBgr faceElements)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   pBrush := Gdip_BrushCreateSolid(faceOpacity faceBgrColor)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

; draw hour labels
   sDiameter := Round(ClockDiameter - ClockDiameter*0.08, 4)  ; inner circle is 8 % smaller than clock's Diameter
   R1 := sDiameter/2-1                        ; outer position
   R2b := Round(sDiameter/2 - 1 - sDiameter/2*0.20, 4)
   If (showAnalogHourLabels=1)
      DrawHoursLabels(R1, R2b, globalG)

   Gdip_SetSmoothingMode(globalG, 4)   ; turn on antialiasing
; draw moon phase
   If (analogMoonPhases=1)
      coreMoonPhaseDraw(faceBgrColor, faceElements, CenterX, CenterY, ClockDiameter, lastUsedGeoLocation, globalG)

; Draw HoursPointer
   t := (A_Hour*360//12) + ((A_Min//15*15)*360//60)//12 + 90
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.50, 2) ; outer position
   pPen := Gdip_CreatePen("0xff666666", Round((ClockDiameter/100)*3.9, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.45, 4) ; outer position
   pPen := Gdip_CreatePen("0xcc" faceElements, Round((ClockDiameter/100)*1.6, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)
   
; Draw MinutesPointer
   t := Round(A_Min*360/60+90, 4)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.35, 4) ; outer position
   pPen := Gdip_CreatePen("0xff707070", Round((ClockDiameter/100)*2.3, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer
   t := Round(A_Sec*360/60+90, 4)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.25, 4) ; outer position
   pPen := Gdip_CreatePen("0xdd898989", Round((ClockDiameter/100)*1.3, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer end stick
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.75, 4) ; outer position
   pPen := Gdip_CreatePen("0xdd898989", Round((ClockDiameter/100)*1.3, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX + (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY + (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

; draw center
   Diameter := Round(ClockDiameter*0.08, 4)
   pBrush := Gdip_BrushCreateSolid("0x66" faceElements)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   Diameter := Round(ClockDiameter*0.04, 4)
   pBrush := Gdip_BrushCreateSolid("0x95" faceElements)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   UpdateLayeredWindow(hFaceClock, globalhdc, , , , , mainOSDopacity)
   Return
}

coreMoonPhaseDraw(bgrColor, itemColor, cX, cY, boxSize, givenGeoLocation, gup) {
     Static moonPhase := [], elevu := 1, lastCalcZeit := 1, lastCoords := 0, lastAngleMoon := 0

     If (A_TickCount - lastCalcZeit>98501) || (lastCoords!=givenGeoLocation)
     {
        If InStr(givenGeoLocation, "|")
           w := StrSplit(givenGeoLocation, "|")

        If (w.Count()>5)
           getMoonElevation(A_NowUTC, w[2], w[3], 0, azii, elevu)
        Else
           elevu := 20

        moonPhase := MoonPhaseCalculator()
        lastCalcZeit := A_TickCount
        ; lastAngleMoon := getMoonLichtAngle(A_NowUTC, w[2], w[3], w[6])
        ; ToolTip, % lastAngleMoon , , , 2
        lastCoords := givenGeoLocation
     }

     o_moonCycle := Round(moonPhase[3], 3)
     ; o_moonCycle := 0.63
     fu := (elevu<0) ? 0.05 : 0.3
     darkFace := mixARGB("0xFF" itemColor, "0xFF" bgrColor, fu)
     brightFace := "0xFF" bgrColor

     ; Static o_moonCycle := 0
     ; o_moonCycle += 0.05
     ; If (o_moonCycle>1)
     ;    o_moonCycle := 0
     moonCycle := (o_moonCycle<0.5) ? o_moonCycle * 2 : 1 - (o_moonCycle - 0.5)*2
     If (o_moonCycle>=0.75)
        flap := 2
     Else If (o_moonCycle>=0.5)
        flap := 1

     If (moonCycle>=0.5 && flap!=2)
     {
        flip := 1
        moonCycle -= 0.50001
     }

     bDark := (flip!=1) ? Gdip_BrushCreateSolid(darkFace) : Gdip_BrushCreateSolid(brightFace)
     bBright := (flip!=1) ? Gdip_BrushCreateSolid(brightFace) : Gdip_BrushCreateSolid(darkFace)
     Diameter := Round(boxSize*0.20, 2)
     Gdip_FillEllipse(gup, bBright, cX-(Diameter/2), cY + Diameter/2.18, Diameter, Diameter)

     pPath := Gdip_CreatePath()
     Gdip_AddPathEllipse(pPath, cX-(Diameter/2), cY + Diameter/2.18, Diameter, Diameter)
     Gdip_SetClipPath(gup, pPath)
     DiameterZ := (flip=1) ? Diameter*(moonCycle*2) : Diameter*(1 - moonCycle*2)
     ; DiameterZ := (moonCycle<0.5) ? Diameter*(1 - moonCycle*2) : Diameter*(moonCycle/1.25)
     ; ToolTip, % flap "|" DiameterZ "|" Diameter "|" darkFace "|" brightFace "|" cX-(Diameter/2) , , , 2
     If (flap=2)
        Gdip_FillRectangle(gup, bDark, cX, cY + Diameter/2.18, Diameter//2, Diameter)
     Else If (flap=1)
        Gdip_FillRectangle(gup, bDark, cX - Diameter/2, cY + Diameter/2.18, Diameter//2, Diameter)
     Else If (moonCycle<0.5 && flip!=1)
        Gdip_FillRectangle(gup, bDark, cX - Diameter/2, cY + Diameter/2.18, Diameter//2, Diameter)
     Else
        Gdip_FillRectangle(gup, bDark, cX, cY + Diameter/2.18, Diameter//2, Diameter)
    
     Gdip_FillEllipse(gup, bDark, cX - (DiameterZ/2), cY + Diameter/2.18, DiameterZ, Diameter)
     Gdip_ResetClip(gup)
     Gdip_DeletePath(pPath)
    
     Diameter := Round(boxSize*0.20, 2)
     pPen := Gdip_CreatePen("0x66" itemColor, Round((boxSize/100)*1.3, 2))
     Gdip_DrawEllipse(gup, pPen, cX - (Diameter/2), cY + Diameter/2.18,Diameter, Diameter)
     If (elevu<0)
     {
        thisBrush := Gdip_BrushCreateSolid("0x77" itemColor)
        Gdip_FillEllipse(gup, thisBrush, cX - (Diameter/2), cY + Diameter/2.18,Diameter, Diameter)
        Gdip_DeleteBrush(thisBrush)
     }
     ; mainBitmap := Gdip_CreateBitmapFromFileSimplified("resources\earth-surface-map.jpg")
     ; pBitmap := Gdip_RotateBitmapAtCenter(mainBitmap, -lastAngleMoon)
     ; Gdip_DrawImage(gup, pBitmap, ClockCenter, ClockCenter, 100, 100)
     ; Gdip_DisposeImage(pBitmap)
     ; Gdip_DisposeImage(mainBitmap)

     Gdip_DeletePen(pPen)
     Gdip_DeleteBrush(bDark)
     Gdip_DeleteBrush(bBright)
     Return elevu
}

DrawClockMarks(items, R1, R2, G, pPen) {
   CenterX := CenterY := ClockCenter
   Loop, %items%
   {
      x1 := CenterX - Round(R1 * Cos(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2)
      y1 := CenterY - Round(R1 * Sin(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2)
      x2 := CenterX - Round(R2 * Cos(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2)
      y2 := CenterY - Round(R2 * Sin(((a_index-1)*360/Items) * Atan(1) * 4 / 180), 2)

      Gdip_DrawLine(G, pPen, x1, y1, x2, y2)
   }
}

DrawHoursLabels(R1, R2, G) {
   static zr := {1:"I", 2:"II", 3:"III", 4:"IV", 5:"V", 6:"VI", 7:"VII", 8:"VIII", 9:"IX", 10:"X", 11:"XI", 12:"XII"}
        , zo := {1:9,2:10,3:11,4:12,5:1,6:2,7:3,8:4,9:5,10:6,11:7,12:8}

   CenterX := CenterY := ClockCenter
   Loop, 12
   {
      x1 := CenterX - Round(R1 * Cos(((a_index-1)*360/12) * Atan(1) * 4 / 180), 2)
      y1 := CenterY - Round(R1 * Sin(((a_index-1)*360/12) * Atan(1) * 4 / 180), 2)
      x2 := CenterX - Round(R2 * Cos(((a_index-1)*360/12) * Atan(1) * 4 / 180), 2)
      y2 := CenterY - Round(R2 * Sin(((a_index-1)*360/12) * Atan(1) * 4 / 180), 2)

      ; ToolTip, % textus "|" A_Index , , , 2
      zf := zr[ zo[A_Index] ]
      If (zo[A_Index]=5 || zo[A_Index]=9 || zo[A_Index]=3 || zo[A_Index]=11 || zo[A_Index]=12)
         y1 -= R2/20
      If (zo[A_Index]=5)
         y1 -= R2/20
      If (zo[A_Index]=8)
         x1 -= R2/12
      If (zo[A_Index]=1)
         x1 -= R2/18

      txtOptions := "x" x1 " y" y1 " Center vCenter cEE111111 Bold nowrap s" Round(R2*0.22)
      Gdip_TextToGraphics(G, zf, txtOptions, "Arial", 3*(x2 - x1), 3*(y2 - y1))
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
    lastInvoked := 1
    ; If (CtrlHwnd && IsRightClick=1)
    ; || ((A_TickCount-lastInvoked>250) && IsRightClick=0)
    ; {
    ;    lastInvoked := A_TickCount
    ;    Return
    ; }

    ; lastInvoked := A_TickCount
    SetTimer, showContextMenuAnalogClock, -100
    Return
}

showContextMenuAnalogClock() {
    Static menuGenerated
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

    pk := MoonPhaseCalculator()
    Menu, ClockSizesMenu, Check, %analogDisplayScale%x
    Menu, ContextMenu, Add, Sc&ale, :ClockSizesMenu
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, &Hide the clock, toggleAnalogClock
    Menu, ContextMenu, Add, Rounded &widget, toggleRoundedWidget
    If (roundedClock=1)
       Menu, ContextMenu, Check, Rounded &widget
    Menu, ContextMenu, Add, Show &moon phases, toggleMoonPhasesAnalog
    Menu, ContextMenu, Add, Show &hour labels, toggleHourLabelsAnalog
    Try Menu, ContextMenu, Add, % pk[1], dummy
    Try Menu, ContextMenu, Disable, % pk[1]
    If (analogMoonPhases=1)
       Menu, ContextMenu, Check, Show &moon phases
    If (showAnalogHourLabels=1)
       Menu, ContextMenu, Check, Show &hour labels

    Menu, ContextMenu, Add
    If (PrefOpen=0)
    {
       Menu, ContextMenu, Add, &Tick/tock sounds, ToggleTickTock
       If (tickTockNoise=1)
          Menu, ContextMenu, Check, &Tick/tock sounds
       Menu, ContextMenu, Add
       Menu, ContextMenu, Add, Astronom&y / Today, PanelTodayInfos
       Menu, ContextMenu, Add, Set &alarm or timer, PanelSetAlarm
       Menu, ContextMenu, Add, Stop&watch, PanelStopWatch
       Menu, ContextMenu, Add, &Celebrations, PanelIncomingCelebrations
       Menu, ContextMenu, Add
       Menu, ContextMenu, Add, &Settings, ShowSettings
       Menu, ContextMenu, Add
       Menu, ContextMenu, Add, &About, PanelAboutWindow
    }

    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, Restart app, ReloadScript
    ; Menu, ContextMenu, Add, Close menu, dummy
    Menu, ContextMenu, Show
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

