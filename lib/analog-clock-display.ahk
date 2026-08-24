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
      constantAnalogClock := 0
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
   Gdip_DeletePen(pPen)
   ; the hour labels are not part of this base drawing; they sit inside the circle
   ; UpdateEverySecond() erases and repaints every second, so it draws them itself
   
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
; The caller must have painted the window at a (near) zero alpha before showing it,
; otherwise the first frame of the fade-in is the fully opaque clock.
   z := GetWindowPlacement(hFaceClock)
   Loop,
   {
      alphaLevel := A_Index*15
      If (alphaLevel>=analogClockOpacity)
         Break

      UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, alphaLevel)
      Sleep, 1
   }
   ; land on the configured opacity instead of on the last multiple of 15 below it
   UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, analogClockOpacity)
}

animateAnalogClockHiding() {
   z := GetWindowPlacement(hFaceClock)
   Loop,
   {
      alphaLevel := analogClockOpacity - A_Index*15
      If (alphaLevel<2)
         Break

      UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, alphaLevel)
      Sleep, 1
   }
}

UpdateEverySecond(alphaLevel:=0) {
; alphaLevel overrides the opacity the frame is shown with; the timer calls this
; without it, showAnalogClock() passes 1 so that the fade-in can start from nothing.
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

; draw timer progress
   Static laz := 1
   Diameter := Round(ClockDiameter - ClockDiameter*0.05, 4)
   If (userTimerExpire && userMustDoTimer=1)
   {
      opaz := (laz=1) ? "0xFFff4411" : "0xFFff1100"
      lk := coreInitUserTimer("last")
      an := A_Now
      an -= lk[1],Seconds
      za := ( an / lk[2] ) * 360
   }

   Gdip_SetSmoothingMode(globalG, 4)   ; turn on antialiasing
   thisClr := (swapColorAnalogClock=1 || transparentAnalogClock=1) ? clockFgrClr : clockBgrClr
   sweep := (userTimerExpire && userMustDoTimer=1) ? clampInRange(za, 2, 361) : 360
   If (userTimerExpire && userMustDoTimer=1)
      sPen := Gdip_CreatePen(opaz, (ClockDiameter/70)*1.25)
   Else
      sPen := Gdip_CreatePen("0xFF" thisClr, (ClockDiameter/70)*1.25)
   Gdip_DrawArc(globalG, sPen, CenterX-(Diameter/2), CenterY-(Diameter/2),Diameter, Diameter, -90, sweep)
   Gdip_DeletePen(sPen)
   laz := !laz

; draw hour labels
   If (showAnalogHourLabels=1)
      DrawHoursLabels(globalG, clockFgrClr)

; draw moon phase
   If (analogMoonPhases=1)
   {
      coreMoonPhaseDraw(clockBgrClr, clockFgrClr, CenterX, CenterY, ClockDiameter, lastUsedGeoLocation, globalG)
   } Else If (analogMoonPhases=2)
   {
      If (displayTimeFormat=1)
      {
         FormatTime, CurrentTime,, HH:mm:ss
      } Else
      {
         timeSuffix := (A_Hour<12) ? " AM" : " PM"
         FormatTime, CurrentTime,, h:mm:ss
      }

      ; The box is sized to the text and centred below the hands. Every measure derives
      ; from ClockDiameter, so the OSD margins (which only enlarge the window) cannot move
      ; or resize it. The 12-hour text is longer, hence its smaller font, which keeps the
      ; box clear of the VIII and IV labels.
      txtOptions := "cFF" clockBgrClr " Bold nowrap s" Round(ClockDiameter * ((displayTimeFormat=1) ? 0.072 : 0.055))
      m := StrSplit(Gdip_TextToGraphics(globalG, CurrentTime timeSuffix, "x0 y0 " txtOptions, "Arial", 0, 0, 1), "|")
      boxW := Round(m[3] + ClockDiameter*0.05), boxH := Round(m[4] + ClockDiameter*0.015)
      boxX := CenterX - boxW//2, boxY := Round(CenterY + ClockDiameter*0.095)
      pBrush := Gdip_BrushCreateSolid("0xDD" clockFgrClr)
      Gdip_FillRoundedRectangle(globalG, pBrush, boxX, boxY, boxW, boxH, 4*analogClockScale)
      Gdip_DeleteBrush(pBrush)
      Gdip_TextToGraphics(globalG, CurrentTime timeSuffix, "x" boxX " y" boxY + Ceil(boxH*0.05) " Center vCenter " txtOptions, "Arial", boxW, boxH)
   }

; Draw HoursPointer
   t := A_Hour*30 + (A_Min//5)*2.5 + 90    ; the hour hand advances in 5-minute steps, by design
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
   UpdateLayeredWindow(hFaceClock, globalhdc, , , z.w, z.h, alphaLevel ? alphaLevel : analogClockOpacity)
   Return
}

swapVars(ByRef a, ByRef b) {
   tempus := a,   a := b,   b := tempus
}

coreMoonPhaseDraw(bgrColor, itemColor, cX, cY, boxSize, givenGeoLocation, gup, datu:=0) {
; datu is an UTC time stamp; it defaults to the present moment. The offset of the
; place named by givenGeoLocation is applied below, before the moon is asked for.
     Static moonPhase := [], elevu := 1, lastCalcZeit := 1, lastCoords := 0, lastAngleMoon := 0
     If (swapColorAnalogClock=1)
        swapVars(bgrColor, itemColor)

     If !datu
        datu := A_NowUTC

     thisCoords := givenGeoLocation "|" SubStr(datu, 1, StrLen(datu) - 3)
     If (A_TickCount - lastCalcZeit>98501) || (lastCoords!=thisCoords)
     {
        If InStr(givenGeoLocation, "|")
        {
           w := StrSplit(givenGeoLocation, "|")
           yearu := SubStr(datu, 1, 4)
           FormatTime, gyd, % datu, Yday
           k := TZI_GetTimeZoneInformation(yearu, gyd)
           gmtOffset := pickSeasonalGmtOffset(gyd, k, w[4], w[5])
           datu += gmtOffset, Hours   ; getMoonElevation() and MoonPhaseCalculator() both subtract it back
        }

        If (w.Count()>5)
           getMoonElevation(datu, w[2], w[3], gmtOffset, azii, elevu)
        Else
           elevu := 20

        moonPhase := MoonPhaseCalculator(datu, gmtOffset, w[2], w[3])
        lastCalcZeit := A_TickCount
        ; lastAngleMoon := getMoonLichtAngle(A_NowUTC, w[2], w[3], w[6])
        ; ToolTip, % thisCoords , , , 2
        lastCoords := thisCoords
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

DrawHoursLabels(G, itemColor) {
; The labels sit on a ring just inside the hour marks. Every measure derives from
; ClockDiameter, never from the window size: the OSD margins only enlarge the window
; around the dial and must not move the labels. The ring, glyphs included, has to stay
; inside the circle UpdateEverySecond() erases every second (radius 0.39 x ClockDiameter),
; because that is where the labels are repainted each second and where a toggle of
; the labels or of the numerals takes effect.
   Static zr := {1:"I", 2:"II", 3:"III", 4:"IV", 5:"V", 6:"VI", 7:"VII", 8:"VIII", 9:"IX", 10:"X", 11:"XI", 12:"XII"}
   R := ClockDiameter * 0.315
   sr := Round(ClockDiameter * 0.075)
   bw := sr*3, bh := sr*2      ; Gdip_TextToGraphics() centres the text only inside an explicit box
   Loop, 12
   {
      a := A_Index * 30 * Atan(1) * 4 / 180      ; clockwise from twelve o'clock
      x1 := Round(ClockCenter + R * Sin(a) - bw/2, 2)
      y1 := Round(ClockCenter - R * Cos(a) - bh/2, 2)
      txt := (useArabNumeralsAnalogClock=1) ? A_Index : zr[A_Index]
      txtOptions := "x" x1 " y" y1 " Center vCenter cEE" itemColor " Bold nowrap s" sr
      Gdip_TextToGraphics(G, txt, txtOptions, "Arial", bw, bh)
   }
}

hideAnalogClock() {
  If (ClockVisibility!=1)
     Return

  SetTimer, UpdateEverySecond, Off    ; a tick during the fade-out would repaint the clock at full opacity
  If (PrefOpen=0)
     animateAnalogClockHiding()

  Gui, ClockGui: Hide
  ClockVisibility := 0
  Return
}

showAnalogClock() {
  If (ClockVisibility!=0)
     Return

  lastShowTime := A_TickCount
  ; paint the current time before the window comes up; when it is going to fade in,
  ; paint it (nearly) invisible, so that the fade-in does not start with an opaque frame
  UpdateEverySecond((PrefOpen=0) ? 1 : 0)
  Gui, ClockGui: Show, NoActivate
  SetTimer, UpdateEverySecond, 1000
  If (PrefOpen=0)
     animateAnalogClockAppeareance()

  ClockVisibility := 1
  Return
}

exitAnalogClock() {
   hideAnalogClock()     ; fades out and stops the timer; a no-op when the clock is already hidden
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
    If (showAnalogHourLabels=1)
    {
       Menu, customClockMenu, Check, Show &hour labels
       Menu, customClockMenu, Add, Use Arabic numerals, MenuToggleArabNumeralz
       If (useArabNumeralsAnalogClock=1)
          Menu, customClockMenu, Check, Use Arabic numerals
    }

    Menu, customClockMenu, Add, Transparent clock face, MenuToggleTransparentClock
    If (transparentAnalogClock=1)
       Menu, customClockMenu, Check, Transparent clock face
    Menu, customClockMenu, Add, Show digital cloc&k, toggleDigitalTimeAnalog
    If (analogMoonPhases=2)
       Menu, customClockMenu, Check, Show digital cloc&k
    Menu, customClockMenu, Add
    Menu, customClockMenu, Add, Show &moon phases, toggleMoonPhasesAnalog
    Try Menu, customClockMenu, Add, % pk[1], dummy
    Try Menu, customClockMenu, Disable, % pk[1]
    If (analogMoonPhases=1)
       Menu, customClockMenu, Check, Show &moon phases
    Menu, customClockMenu, Add
    Menu, customClockMenu, Add, Lock clock &position, MenuToggleLockClockAnalogPosition
    If (lockAnalogClockPosition=1)
       Menu, customClockMenu, Check, Lock clock &position
}

MenuSetQuickTimer(aa:=0) {
  If InStr(aa, "custom")
  {
     PanelSetAlarm()
     Return
  } Else If InStr(aa, "turn off")
  {
     userMustDoTimer := userTimerExpire := 0
     SetTimer, doUserTimerAlert, Off
     Return
  }

  userTimerMsg := ""
  userTimerHours := (aa>59) ? 1 : 0
  userTimerMins := (aa>=60) ? aa - 60 : aa
  INIaction(1, "userTimerMins", "SavedSettings")
  INIaction(1, "userTimerHours", "SavedSettings")
  ; INIaction(1, "userTimerMsg", "SavedSettings")
  userMustDoTimer := 1
  coreInitUserTimer()
  ; ToolTip, % aa , , , 2
}

showContextMenuAnalogClock() {
    Menu, ContextMenu, UseErrorLevel
    Menu, ContextMenu, DeleteAll
    Try Menu, ClockOpacityMenu, DeleteAll
    Try Menu, ClockSizesMenu, DeleteAll
    Try Menu, ClockTimersMenu, DeleteAll
    Sleep, 5
    Menu, ClockSizesMenu, UseErrorLevel
    Loop, Parse, analogClockScalesList, |
        Menu, ClockSizesMenu, Add, % A_LoopField "x", ChangeMenuClockSize

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

    Try Menu, ClockSizesMenu, Check, % nearestAnalogClockScale(analogClockScale) "x"
    Loop, 9
        Menu, ClockOpacityMenu, Add, % (A_Index + 1) * 10 "%", ChangeMenuClockOpacity
    pop := Round(analogClockOpacity/255 * 100) "%"
    ; Menu, ClockOpacityMenu, Add
    ; Menu, ClockOpacityMenu, Add, % pop, dummy
    ; Menu, ClockOpacityMenu, Disable, % pop
    Try Menu, ClockOpacityMenu, Check, % pop
    createCustomClockOptionsMenu()
    Menu, ContextMenu, Add, Sc&ale, :ClockSizesMenu
    Menu, ContextMenu, Add, &Opacity, :ClockOpacityMenu
    If (PrefOpen=0)
    {
       Menu, ContextMenu, Add, C&ustomize, :customClockMenu
       createMenuOSDprefs()
       Menu, ContextMenu, Add, OSD &settings, :MenuOSDprefs
    }

    Menu, ContextMenu, Add
    If (PrefOpen=0)
       Menu, ContextMenu, Add, &Set timer, :ClockTimersMenu
    Menu, ContextMenu, Add, &Hide the clock, toggleAnalogClock

    Menu, ContextMenu, Add
    If (PrefOpen=0)
    {
       Menu, ContextMenu, Add, &Mute all sounds, ToggleAllMuteSounds
       If (userMuteAllSounds=1)
          Menu, ContextMenu, Check, &Mute all sounds

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
  If !analogClockMenuActionAllowed()
     Return

  saveAnalogClockPosition()
  Try Menu, ClockSizesMenu, Uncheck, % nearestAnalogClockScale(analogClockScale) "x"
  StringLeft, newSize, A_ThisMenuItem, 4
  MenuChangeClockSizeScale(newSize)
}

analogClockMenuActionAllowed() {
; The customization handlers of the clock's context menu do nothing while the app is
; suspended or the Settings window is open; in the latter case that window is brought up.
   If (A_IsSuspended || PrefOpen=1)
   {
      SoundBeep, 300, 900
      If (PrefOpen=1)
         WinActivate, ahk_id %hSetWinGui%
      Return 0
   }

   Return 1
}

ChangeMenuClockOpacity() {
   If !analogClockMenuActionAllowed()
      Return

   newSize := ( StrReplace(A_ThisMenuItem, "%") /100 ) * 255
   analogClockOpacity := Round(newSize)
   INIaction(1, "analogClockOpacity", "OSDprefs")
   reInitializeAnalogClock()
}

MenuChangeClockSizeScale(newSize) {
   If !analogClockMenuActionAllowed()
      Return

   analogClockScale := newSize
   INIaction(1, "analogClockScale", "OSDprefs")
   reInitializeAnalogClock()
}

MenuToggleSwapAnalogColors() {
   If !analogClockMenuActionAllowed()
      Return

   swapColorAnalogClock := !swapColorAnalogClock
   INIaction(1, "swapColorAnalogClock", "OSDprefs")
   reInitializeAnalogClock()
}

MenuToggleAnalogBgrClock() {
   If !analogClockMenuActionAllowed()
      Return

   coloredAnalogClockBgr := !coloredAnalogClockBgr
   INIaction(1, "coloredAnalogClockBgr", "OSDprefs")
   reInitializeAnalogClock()
}

MenuToggleTransparentClock() {
   If !analogClockMenuActionAllowed()
      Return

   transparentAnalogClock := !transparentAnalogClock
   INIaction(1, "transparentAnalogClock", "OSDprefs")
   reInitializeAnalogClock()
}

MenuToggleArabNumeralz() {
   If !analogClockMenuActionAllowed()
      Return

   useArabNumeralsAnalogClock := !useArabNumeralsAnalogClock
   INIaction(1, "useArabNumeralsAnalogClock", "OSDprefs")
   ; reInitializeAnalogClock()
}


MenuToggleLockClockAnalogPosition() {
   If !analogClockMenuActionAllowed()
      Return

   lockAnalogClockPosition := !lockAnalogClockPosition
   INIaction(1, "lockAnalogClockPosition", "OSDprefs")
   ; reInitializeAnalogClock()
}

