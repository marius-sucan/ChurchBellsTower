; analog-clock-display.ahk - lib file
; https://github.com/marius-sucan/ChurchBellsTower
;
; Charset for this file must be UTF 8 with BOM.
; it may not function properly otherwise.
;
; based on the GDI+ ahk analog clock example written by derRaphael
; from https://autohotkey.com/board/topic/34692-examplesminituts-the-gdi-examplecodes-thread/#entry219089
; posted on 17 November 2008

InitClockFace() {
   Critical, on
   clockFgrClr := (swapColorAnalogClock=1) ? clockBgrColor : clockFgrColor
   clockBgrClr := (swapColorAnalogClock=1) ? clockFgrColor : clockBgrColor
   If (!pToken := Gdip_Startup())
   {
      constantAnalogClock := analogOSDclockDisplay := 0
      SoundBeep , 300, 900
      Return
   }

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

   ClockDiameter := Round(FontSize * 4 * analogClockScale)
   ClockWinSize := ClockDiameter + Round((OSDmarginBottom//2 + OSDmarginTop//2 + OSDmarginSides//2) * analogClockScale)
   roundsize := Round(roundedCsize * (analogClockScale/1.5))
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
   Gui, ClockGui: Add, Text, x1 y1 w%Width% h%Height% vinfoWidget, Analog clock widget
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
   pBrush := Gdip_BrushCreateSolid("0xFF" clockOutColor)      ; clock face background 
   If (transparentAnalogClock!=1 && coloredAnalogClockBgr!=0)
      Gdip_FillRectangle(globalG, pBrush, 0, 0, ClockWinSize*1.5, ClockWinSize*1.5)
   Gdip_DeleteBrush(pBrush)

   Diameter := ClockDiameter - 2*Round((ClockDiameter/100)*1.2)
   pPen := Gdip_CreatePen("0xaa" clockFgrClr, Round((ClockDiameter/100)*1.2))
   If (transparentAnalogClock!=1)
      Gdip_DrawEllipse(globalG, pPen, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeletePen(pPen)

; Draw inner circle
   Diameter := Round(ClockDiameter - ClockDiameter*0.04, 4) + Round((ClockDiameter/100)*1.2, 4)  ; white border
   pBrush := Gdip_BrushCreateSolid(faceOpacity clockBgrClr)
   If (transparentAnalogClock!=1)
      Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

; Draw Second Marks
   Diameter := Round(ClockDiameter - ClockDiameter*0.08, 4)  ; inner circle is 8 % smaller than clock's Diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.08, 4) ; inner position
   topi := (transparentAnalogClock=1) ? "0xFF" : "0x66"
   pPen := Gdip_CreatePen("0xaa" clockFgrClr, (ClockDiameter/100)*1.2) ; 1.2 % of total Diameter is our pen width
   sPen := Gdip_CreatePen(topi clockFgrClr, (ClockDiameter/100)*1.2) ; 1.2 % of total Diameter is our pen width
   Gdip_DrawEllipse(globalG, sPen, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   If (ClockDiameter>=100)
      DrawClockMarks(60, R1, R2, globalG, pPen)                 ; we have 60 seconds
   Else If (ClockDiameter>=50)
      DrawClockMarks(24, R1, R2+0.1, globalG, pPen)
   Gdip_DeletePen(pPen)
   Gdip_DeletePen(sPen)

   R2 := Round(Diameter/2 - 1 - Diameter/2*0.04, 4) ; inner position
   pPen := Gdip_CreatePen("0x88" clockFgrClr, (ClockDiameter/100)*0.7) ; 1.2 % of total Diameter is our pen width
   If (ClockDiameter>250)
      DrawClockMarks(120, R1, R2, globalG, pPen)                 ; we have 60 seconds
   Gdip_DeletePen(pPen)

; Draw Hour Marks
   R2 := (showAnalogHourLabels=1) ? Round(Diameter/2 - 1 - Diameter/2*0.15, 2) : Round(Diameter/2 - 1 - Diameter/2*0.2, 2) ; inner position
   pPen := Gdip_CreatePen("0xff" clockFgrClr, (ClockDiameter/100)*2.3) ; 2.3 % of total Diameter is our pen width
   DrawClockMarks(12, R1, R2, globalG, pPen)                  ; we have 12 hours
   R2b := Round(Diameter/2 - 1 - Diameter/2*0.20, 4)
   If (showAnalogHourLabels=1)
      DrawHoursLabels(R1, R2b, globalG, clockFgrClr)
   Gdip_DeletePen(pPen)
   
   Diameter := Round(ClockDiameter - ClockDiameter*0.17, 4)  ; inner circle is 17 % smaller than clock's Diameter
   R1 := Diameter/2-1                        ; outer position
   R2 := Round(Diameter/2 - 1 - Diameter/2*0.2, 4) ; inner position
   pPen := Gdip_CreatePen("0xff" clockFgrClr, (ClockDiameter/100)*4) ; 4 % of total Diameter is our pen width
   If (ClockDiameter>250 && showAnalogHourLabels!=1)
      DrawClockMarks(4, R1, R2, globalG, pPen)                  ; we have 4 quarters
   Gdip_DeletePen(pPen)

   z := GetWindowPlacement(hFaceClock)
   UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, mainOSDopacity)
   moduleAnalogClockInit := 1
   Return
}

animateAnalogClockAppeareance() {
   Loop,
   {
      alphaLevel := A_Index*15
      If (alphaLevel>mainOSDopacity)
         Break

      z := GetWindowPlacement(hFaceClock)
      UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, alphaLevel)
      Sleep, 1
   }
}

animateAnalogClockHiding() {
   Loop,
   {
      alphaLevel := mainOSDopacity - A_Index*15
      If (alphaLevel<5)
         Break

      z := GetWindowPlacement(hFaceClock)
      UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, alphaLevel)
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

   pBrush := Gdip_BrushCreateSolid(faceOpacityBgr clockFgrClr)
   If (transparentAnalogClock!=1)
      Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   pBrush := Gdip_BrushCreateSolid(faceOpacity clockBgrClr)
   If (transparentAnalogClock!=1)
      Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

; draw hour labels
   sDiameter := Round(ClockDiameter - ClockDiameter*0.08, 4)  ; inner circle is 8 % smaller than clock's Diameter
   R1 := sDiameter/2-1                        ; outer position
   R2b := Round(sDiameter/2 - 1 - sDiameter/2*0.20, 4)
   ; ToolTip, % sDiameter "`n" R1 "`n" R2b , , , 2
   If (showAnalogHourLabels=1)
      DrawHoursLabels(R1, R2b, globalG, clockFgrClr)

   Gdip_SetSmoothingMode(globalG, 4)   ; turn on antialiasing
; draw moon phase
   If (analogMoonPhases=1)
   {
      coreMoonPhaseDraw(clockBgrClr, clockFgrClr, CenterX, CenterY, ClockDiameter, lastUsedGeoLocation, globalG)
   } Else If (analogMoonPhases=2)
   {
      pBrush := Gdip_BrushCreateSolid("0xDD" clockFgrClr)
      Gdip_FillRoundedRectangle(globalG, pBrush, CenterX - (ClockDiameter*0.175), CenterY*1.145, ClockDiameter/2.58, ClockDiameter*0.12, 4*analogClockScale)
      Gdip_DeleteBrush(pBrush)
      ppo := " x" CenterX - (ClockDiameter*0.185) " y" CenterY*1.155
      txtOptions := ppo " Center vCenter cFF" clockBgrClr " Bold nowrap s" Round(CenterY*0.11)
      If (displayTimeFormat=1)
      {
         FormatTime, CurrentTime,, HH:mm:ss
      } Else
      {
         timeSuffix := (A_Hour<12) ? " AM" : " PM"
         FormatTime, CurrentTime,, h:mm
      }

      Gdip_TextToGraphics(globalG, CurrentTime timeSuffix, txtOptions, "Arial", ClockDiameter/2.49, ClockDiameter*0.12)
   }

; Draw HoursPointer
   t := (A_Hour*360//12) + ((A_Min//15*15)*360//60)//12 + 90
   clrA := (transparentAnalogClock=1) ? "0x85" clockFgrClr : "0xFF" MixRGB(clockFgrClr, clockBgrClr, 0.6)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.50, 2) ; outer position
   pPen := Gdip_CreatePen(clrA, Round((ClockDiameter/100)*3.9, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.45, 4) ; outer position
   pPen := Gdip_CreatePen("0xCC" clockFgrClr, Round((ClockDiameter/100)*1.6, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)
   
; Draw MinutesPointer
   t := Round(A_Min*360/60+90, 4)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.35, 4) ; outer position
   clrA :=  (transparentAnalogClock=1) ? "0x85" clockFgrClr : "0xFF" MixRGB(clockFgrClr, clockBgrClr, 0.5)
   pPen := Gdip_CreatePen(clrA, Round((ClockDiameter/100)*2.3, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer
   t := Round(A_Sec*360/60+90, 4)
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.25, 4) ; outer position
   clrA :=  (transparentAnalogClock=1) ? "0x55" clockFgrClr : "0xDD" MixRGB(clockFgrClr, clockBgrClr, 0.4)
   pPen := Gdip_CreatePen(clrA, Round((ClockDiameter/100)*1.3, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX - (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY - (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

; Draw SecondsPointer end stick
   R1 := Round(ClockDiameter/2 - (ClockDiameter/2)*0.75, 4) ; outer position
   pPen := Gdip_CreatePen(clrA, Round((ClockDiameter/100)*1.3, 4))
   Gdip_DrawLine(globalG, pPen, CenterX, CenterY
      , Round(CenterX + (R1 * Cos(t * Atan(1) * 4 / 180)), 4)
      , Round(CenterY + (R1 * Sin(t * Atan(1) * 4 / 180)), 4))
   Gdip_DeletePen(pPen)

; Draw center
   Diameter := Round(ClockDiameter*0.08, 4)
   pBrush := Gdip_BrushCreateSolid("0x66" clockFgrClr)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   Diameter := Round(ClockDiameter*0.04, 4)
   pBrush := Gdip_BrushCreateSolid("0x95" clockFgrClr)
   Gdip_FillEllipse(globalG, pBrush, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter)
   Gdip_DeleteBrush(pBrush)

   z := GetWindowPlacement(hFaceClock)
   UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, mainOSDopacity)
   Return
}

swapVars(ByRef a, ByRef b) {
   tempus := a,   a := b,   b := tempus
}

coreMoonPhaseDraw(bgrColor, itemColor, cX, cY, boxSize, givenGeoLocation, gup) {
     Static moonPhase := [], elevu := 1, lastCalcZeit := 1, lastCoords := 0, lastAngleMoon := 0
     If (swapColorAnalogClock=1)
        swapVars(bgrColor, itemColor)

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

DrawHoursLabels(rR1, R2, G, clockFgrClr) {
   Static zr := {1:"I", 2:"II", 3:"III", 4:"IV", 5:"V", 6:"VI", 7:"VII", 8:"VIII", 9:"IX", 10:"X", 11:"XI", 12:"XII"}
        , zo := {1:9,2:10,3:11,4:12,5:1,6:2,7:3,8:4,9:5,10:6,11:7,12:8}
        , zf := {1:0.17,2:0.2,3:0.25,4:0.3,5:0.21,6:0.3,7:0.24,8:0.29,9:0.25,10:0.2,11:0.15,12:0.15}
        , zx := {1:1,2:0.99,3:1.01,4:1.05,5:1,6:1,7:1,8:0.95,9:0.97,10:1.04,11:1.05,12:1}
        , zy := {1:0.94,2:0.9,3:0.92,4:0.97,5:0.95,6:1,7:0.95,8:0.96,9:0.92,10:0.91,11:1,12:1.03}

   CenterX := CenterY := ClockCenter
   sr := Round(R2*0.22)
   Loop, 12
   {
      R1 := rR1 - ClockCenter * zf[ zo[A_Index] ]
      x1 := CenterX - Round(R1 * Cos(((A_Index - 1)*360/12) * Atan(1) * 4 / 180), 6)
      y1 := CenterY - Round(R1 * Sin(((A_Index - 1)*360/12) * Atan(1) * 4 / 180), 6)
      x1 := Round( x1 * zx[ zo[A_Index] ], 2 )
      y1 := Round( y1 * zy[ zo[A_Index] ], 2 )

      txt := zr[ zo[A_Index] ]
      txtOptions := "x" x1 " y" y1 " Center vCenter cEE" clockFgrClr " Bold nowrap s" sr
      Gdip_TextToGraphics(G, txt, txtOptions, "Arial")
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
  If (analogOSDclockDisplay=1 && constantAnalogClock=0 && PrefOpen=0)
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

createCustomClockOptionsMenu() {
    pk := MoonPhaseCalculator()
    Menu, customClockMenu, UseErrorLevel
    Menu, customClockMenu, DeleteAll
    Menu, customClockMenu, Add, Swap clock colors, MenuToggleSwapAnalogColors
    If (swapColorAnalogClock=1)
       Menu, customClockMenu, Check, Swap clock colors

    If (transparentAnalogClock=0)
    {
       Menu, customClockMenu, Add, Paint clock exterior, MenuToggleAnalogBgrClock
       If (coloredAnalogClockBgr=1)
       {
          Menu, customClockMenu, Check, Paint clock exterior
          Menu, customClockMenu, Add, Rounded &frame, toggleRoundedWidget
          If (roundedClock=1)
             Menu, customClockMenu, Check, Rounded &frame
       }
    }

    Menu, customClockMenu, Add, Show &hour labels, toggleHourLabelsAnalog
    Menu, customClockMenu, Add, Transparent clock face, MenuToggleTransparentClock
    If (transparentAnalogClock=1)
       Menu, customClockMenu, Check, Transparent clock face
    Menu, customClockMenu, Add, Show digital cloc&k, toggleDigitalTimeAnalog
    Menu, customClockMenu, Add
    Menu, customClockMenu, Add, Show &moon phases, toggleMoonPhasesAnalog
    Try Menu, customClockMenu, Add, % pk[1], dummy
    Try Menu, customClockMenu, Disable, % pk[1]
    If (analogMoonPhases=1)
       Menu, customClockMenu, Check, Show &moon phases
    If (analogMoonPhases=2)
       Menu, customClockMenu, Check, Show digital cloc&k
    If (showAnalogHourLabels=1)
       Menu, customClockMenu, Check, Show &hour labels
}

showContextMenuAnalogClock() {
    Static menuGenerated
    Menu, ContextMenu, UseErrorLevel
    Menu, ContextMenu, DeleteAll
    Sleep, 5
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

    Menu, ClockSizesMenu, Check, %analogClockScale%x
    createCustomClockOptionsMenu()
    Menu, ContextMenu, Add, Sc&ale, :ClockSizesMenu
    Menu, ContextMenu, Add, C&ustomize, :customClockMenu
    Menu, ContextMenu, Add
    Menu, ContextMenu, Add, &Hide the clock, toggleAnalogClock

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
       Menu, ContextMenu, Add, &Settings, PanelShowSettings
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
  Menu, ClockSizesMenu, Uncheck, %analogClockScale%x
  StringLeft, newSize, A_ThisMenuItem, 4
  MenuChangeClockSizeScale(newSize)
}

MenuChangeClockSizeScale(newSize) {
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
      If (PrefOpen=1)
         WinActivate, ahk_id %hSetWinGui%
      Return
   }

   analogClockScale := newSize
   INIaction(1, "analogClockScale", "OSDprefs")
   reInitializeAnalogClock()
}

MenuToggleSwapAnalogColors() {
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
      If (PrefOpen=1)
         WinActivate, ahk_id %hSetWinGui%
      Return
   }

   swapColorAnalogClock := !swapColorAnalogClock
   INIaction(1, "swapColorAnalogClock", "OSDprefs")
   reInitializeAnalogClock()
}

MenuToggleAnalogBgrClock() {
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
      If (PrefOpen=1)
         WinActivate, ahk_id %hSetWinGui%
      Return
   }

   coloredAnalogClockBgr := !coloredAnalogClockBgr
   INIaction(1, "coloredAnalogClockBgr", "OSDprefs")
   reInitializeAnalogClock()
}

MenuToggleTransparentClock() {
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
      If (PrefOpen=1)
         WinActivate, ahk_id %hSetWinGui%
      Return
   }

   transparentAnalogClock := !transparentAnalogClock
   INIaction(1, "transparentAnalogClock", "OSDprefs")
   reInitializeAnalogClock()
}

