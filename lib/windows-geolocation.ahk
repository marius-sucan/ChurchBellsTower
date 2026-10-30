;================================================================
; windows-geolocation.ahk
;
; Identify device location on the planet Earth :-).
;
; Most precision is through Windows.Devices.Geolocation.Geolocator, the
; runtime class that sits behind Settings > Privacy > Location on Windows 10
; and Windows 11. It is the same source the Maps and the Weather apps read.
; A machine carrying a GPS receiver is placed within a few metres; a machine
; without one is placed all the same, from the Wi-Fi networks within earshot
; or, those failing, from the address its network hands out. The coarse case
; lands a few kilometres off, which is still well inside what naming a city
; asks for. Whichever way it arrives, the reply is a true latitude and
; longitude.
;
; Fallback mechanism:
;
;   - the country set under Settings > Time & language > Region - the same
;     home region the WinRT GlobalizationPreferences.HomeGeographicRegion
;     reports, read here through its classic equivalents GetUserGeoID and
;     GetGeoInfoW so that Windows 7 answers too - which the user picked
;     deliberately and which Windows always has an answer for;
;   - the language of the keyboard layout the user is typing with, which
;     carries a region in its language identifier: 0x0418 is Romanian as
;     spoken in Romania, 0x0809 is English as written in Britain;
;   - the language Windows itself is displayed in, which carries a region
;     the same way;
;   - the time zone this computer keeps, which names no country but narrows
;     one: a machine whose Region says United States and whose clock keeps
;     UTC-8 in January and UTC-7 in July is on the Pacific coast, and that
;     is worth three thousand kilometres over assuming the capital.
;
; The WinRT calls below are made straight against the ABI vtables rather than
; through a projection, since AutoHotkey has none. That is safe to do only
; because a published WinRT interface may never be reordered once it ships -
; the slot numbers named here are the declaration order in the Windows SDK's
; windows.devices.geolocation.idl and they are fixed for good. The first six
; slots of every one of them belong to IInspectable: QueryInterface, AddRef,
; Release, GetIids, GetRuntimeClassName, GetTrustLevel.
;
; RoActivateInstance hands back the default interface of the class it built,
; so the IInspectable it returns for Geolocator is already an IGeolocator and
; needs no QueryInterface. The same holds down the chain: Geoposition arrives
; as IGeoposition, Geocoordinate as IGeocoordinate. The one interface that
; must be asked for by name is IAsyncInfo, which carries the status of the
; operation while it runs.
; 
; Code written with Claude Opus 5 by Marius Șucan.
;
;================================================================
 
WinGeoRuntimeReady() {
; Whether this Windows has the runtime at all. combase.dll arrived with
; Windows 8; on anything older there is nothing here to ask.

   Static wgReady := ""
   If (wgReady="")
      wgReady := DllCall("kernel32\LoadLibraryW", "WStr", "combase.dll", "UPtr") ? 1 : 0

   Return wgReady
}

WinGeoInitApartment() {
; The thread must be an apartment before it may activate a runtime class.
; AutoHotkey has already made it one for OLE, so this ordinarily returns
; S_FALSE, and RPC_E_CHANGED_MODE would only say the apartment is threaded
; the other way - either is an apartment and either will do. The matching
; RoUninitialize is deliberately never called: the reference is wanted for
; as long as the application runs, and giving it back would tread on the
; OLE apartment AutoHotkey set up for itself.

   Static wgApartment := 0
   If wgApartment
      Return (wgApartment=1)

   wgHr := DllCall("combase.dll\RoInitialize", "Int", 0, "Int") & 0xFFFFFFFF   ; RO_INIT_SINGLETHREADED
   wgApartment := (wgHr=0x0 || wgHr=0x1 || wgHr=0x80010106) ? 1 : 2   ; S_OK, S_FALSE, RPC_E_CHANGED_MODE
   Return (wgApartment=1)
}

WinGeoSlot(wgPtr, wgIndex) {
; The address parked in slot wgIndex of the vtable wgPtr points at.
   Return NumGet(NumGet(wgPtr+0, 0, "UPtr")+0, wgIndex*A_PtrSize, "UPtr")
}

WinGeoRelease(ByRef wgPtr) {
   If wgPtr
      DllCall(WinGeoSlot(wgPtr, 2), "Ptr", wgPtr)

   wgPtr := 0
}

WinGeoDropRequest(ByRef wgInfo, ByRef wgAsync, ByRef wgLocator) {
; The three references one position request holds open, given back together.

   WinGeoRelease(wgInfo)
   WinGeoRelease(wgAsync)
   WinGeoRelease(wgLocator)
}

WinGeoQueryInterface(wgPtr, wgIID) {
; QueryInterface is slot 0 of every COM interface there has ever been.

   VarSetCapacity(wgGuid, 16, 0)
   If DllCall("ole32\CLSIDFromString", "WStr", wgIID, "Ptr", &wgGuid, "Int")
      Return 0

   wgOut := 0
   If DllCall(WinGeoSlot(wgPtr, 0), "Ptr", wgPtr, "Ptr", &wgGuid, "Ptr*", wgOut, "Int")
      Return 0

   Return wgOut
}

WinGeoFaultText(wgHr) {
; The handful of failures worth naming plainly. Everything else is given back
; as the bare HRESULT, which is at least something to search for.

   wgHr := wgHr & 0xFFFFFFFF
   If (wgHr=0x80070005)   ; E_ACCESSDENIED
      Return "Windows is not letting desktop applications read the location of this computer.`n`nSettings > Privacy > Location has one switch for the service itself and a second one further down for desktop applications; both have to be on."
   Else If (wgHr=0x80070490)   ; HRESULT_FROM_WIN32(ERROR_NOT_FOUND), no provider answered
      Return "Windows has no way of telling where this computer is. There is no location sensor here, and neither the Wi-Fi networks in range nor the network address gave the service anything to work with."
   Else If (wgHr=0x80004005)   ; E_FAIL
      Return "The Windows location service failed without saying why."
   Else If (wgHr=0x80070422)
      Return "The Windows location service is not activated."

   Return "Windows location service error code: " . Format("0x{:08X}", wgHr) . "."
}

WinGeoStatusText(wgStatus) {
; PositionStatus, as the service reports it after a request has gone through.
; Ready and Initializing say nothing useful about a failure, so they are left
; blank and the HRESULT is allowed to speak instead.

   If (wgStatus=2)
      Return "The location service is running but has nothing to report yet."
   Else If (wgStatus=3)
      Return "Location is switched off for this computer."
   Else If (wgStatus=5)
      Return "This computer has no location provider Windows can use."

   Return ""
}

WinGeoPosition(ByRef wgLat, ByRef wgLong, ByRef wgAccuracy, ByRef wgAltitude, ByRef wgFault, wgTimeout := 12000) {
; Ask the location service where we are and wait up to wgTimeout milliseconds
; for it to say. Gives back 1 with the coordinates filled in, or 0 with a
; sentence in wgFault fit to put in front of the user.
;
; Latitude and longitude are read off IGeocoordinate's own slots. The metadata
; marks those two deprecated in favour of the Point property, but deprecation
; in WinRT only discourages a caller - it may not move a slot or remove one -
; so they answer on Windows 11 exactly as they did on Windows 8. Altitude is a
; boxed IReference<double> and is very often null, since only a real GPS fix
; carries one.

   Static IID_IAsyncInfo := "{00000036-0000-0000-C000-000000000046}"
        , wgClass := "Windows.Devices.Geolocation.Geolocator"
        , SLOT_LOCATIONSTATUS := 12, SLOT_GETGEOPOSITIONASYNC := 13   ; IGeolocator
        , SLOT_GETRESULTS := 8                                        ; IAsyncOperation
        , SLOT_STATUS := 7, SLOT_ERRORCODE := 8, SLOT_CANCEL := 9     ; IAsyncInfo
        , SLOT_COORDINATE := 6                                        ; IGeoposition
        , SLOT_LATITUDE := 6, SLOT_LONGITUDE := 7, SLOT_ALTITUDE := 8, SLOT_ACCURACY := 9  ; IGeocoordinate
        , SLOT_VALUE := 6                                             ; IReference<double>

   wgLat := wgLong := wgAccuracy := wgAltitude := wgFault := ""
   wgLocator := wgAsync := wgInfo := 0
   If !WinGeoRuntimeReady()
   {
      wgFault := "This edition of Windows has no location service to ask; it wants Windows 8 or later."
      Return 0
   }

   If !WinGeoInitApartment()
   {
      wgFault := "The Windows Runtime would not start on this thread."
      Return 0
   }

   wgString := 0
   If DllCall("combase.dll\WindowsCreateString", "WStr", wgClass, "UInt", StrLen(wgClass), "Ptr*", wgString, "Int")
   {
      wgFault := "The name of the location service could not be prepared."
      Return 0
   }

   wgHr := DllCall("combase.dll\RoActivateInstance", "Ptr", wgString, "Ptr*", wgLocator, "Int")
   DllCall("combase.dll\WindowsDeleteString", "Ptr", wgString)
   If (wgHr || !wgLocator)
   {
      wgFault := "The Windows location service would not start.`n`n" WinGeoFaultText(wgHr)
      Return 0
   }

   wgHr := DllCall(WinGeoSlot(wgLocator, SLOT_GETGEOPOSITIONASYNC), "Ptr", wgLocator, "Ptr*", wgAsync, "Int")
   If (wgHr || !wgAsync)
   {
      wgFault := WinGeoDiagnose(wgLocator, wgHr)
      WinGeoDropRequest(wgInfo, wgAsync, wgLocator)
      Return 0
   }

   wgInfo := WinGeoQueryInterface(wgAsync, IID_IAsyncInfo)
   If !wgInfo
   {
      wgFault := "The location request could not be followed to its end."
      WinGeoDropRequest(wgInfo, wgAsync, wgLocator)
      Return 0
   }

   ; The work happens on a thread of the service's own and the status is
   ; posted from there, so watching it is enough - no completion handler has
   ; to be built. Sleep is what makes the wait harmless: it hands the message
   ; queue back to Windows, so the window stays alive and drawn throughout.
   wgDeadline := A_TickCount + wgTimeout
   wgStatus := 0
   Loop
   {
      wgHr := DllCall(WinGeoSlot(wgInfo, SLOT_STATUS), "Ptr", wgInfo, "Int*", wgStatus, "Int")
      If (wgHr || wgStatus!=0)   ; AsyncStatus.Started
         Break

      If (A_TickCount>wgDeadline)
      {
         DllCall(WinGeoSlot(wgInfo, SLOT_CANCEL), "Ptr", wgInfo)
         wgStatus := -1
         Break
      }
      Sleep, 40
   }

   If (wgStatus=-1)
      wgFault := "Windows did not settle on a position within " Round(wgTimeout/1000) " seconds. A first fix on a cold receiver can take longer than that; trying again usually finds it waiting."
   Else If (wgStatus=2)   ; AsyncStatus.Canceled
      wgFault := "The location request was cancelled."
   Else If (wgStatus!=1)  ; anything that is not AsyncStatus.Completed
   {
      wgCode := 0
      DllCall(WinGeoSlot(wgInfo, SLOT_ERRORCODE), "Ptr", wgInfo, "Int*", wgCode, "Int")
      wgFault := WinGeoDiagnose(wgLocator, wgCode)
   }

   If wgFault
   {
      WinGeoDropRequest(wgInfo, wgAsync, wgLocator)
      Return 0
   }

   wgPosition := 0
   wgHr := DllCall(WinGeoSlot(wgAsync, SLOT_GETRESULTS), "Ptr", wgAsync, "Ptr*", wgPosition, "Int")
   WinGeoDropRequest(wgInfo, wgAsync, wgLocator)
   If (wgHr || !wgPosition)
   {
      wgFault := "Windows reported a position and then would not hand it over.`n`n" WinGeoFaultText(wgHr)
      Return 0
   }

   wgCoord := 0
   wgHr := DllCall(WinGeoSlot(wgPosition, SLOT_COORDINATE), "Ptr", wgPosition, "Ptr*", wgCoord, "Int")
   WinGeoRelease(wgPosition)
   If (wgHr || !wgCoord)
   {
      wgFault := "The position Windows reported carries no coordinate."
      Return 0
   }

   wgLat := wgLong := wgAccuracy := 0
   DllCall(WinGeoSlot(wgCoord, SLOT_LATITUDE), "Ptr", wgCoord, "Double*", wgLat, "Int")
   DllCall(WinGeoSlot(wgCoord, SLOT_LONGITUDE), "Ptr", wgCoord, "Double*", wgLong, "Int")
   DllCall(WinGeoSlot(wgCoord, SLOT_ACCURACY), "Ptr", wgCoord, "Double*", wgAccuracy, "Int")

   wgBoxed := 0
   If !DllCall(WinGeoSlot(wgCoord, SLOT_ALTITUDE), "Ptr", wgCoord, "Ptr*", wgBoxed, "Int") && wgBoxed
   {
      wgMetres := 0
      If !DllCall(WinGeoSlot(wgBoxed, SLOT_VALUE), "Ptr", wgBoxed, "Double*", wgMetres, "Int")
         wgAltitude := wgMetres

      WinGeoRelease(wgBoxed)
   }
   WinGeoRelease(wgCoord)

   ; Zero north, zero east is a mile or two of open Atlantic south of Ghana.
   ; No fix ever really lands there, so a pair of exact zeroes is the shape a
   ; provider's empty answer takes rather than a place worth reporting.
   If (wgLat>90 || wgLat<-90 || wgLong>180 || wgLong<-180 || (wgLat=0 && wgLong=0))
   {
      wgLat := wgLong := wgAccuracy := wgAltitude := ""
      wgFault := "Windows gave back a position that cannot be a place on Earth."
      Return 0
   }

   Return 1
}

WinGeoDiagnose(wgLocator, wgHr) {
; Why the request came to nothing. The HRESULT is the first thing to go on,
; but LocationStatus read straight afterwards often knows more - it is the
; only thing that distinguishes a switched-off service from a computer that
; simply has nothing to locate itself with.

   Static SLOT_LOCATIONSTATUS := 12

   wgStatus := -1
   DllCall(WinGeoSlot(wgLocator, SLOT_LOCATIONSTATUS), "Ptr", wgLocator, "Int*", wgStatus, "Int")
   wgSaid := WinGeoStatusText(wgStatus)
   If ((wgHr & 0xFFFFFFFF)=0x80070005)   ; E_ACCESSDENIED outranks anything the status has to say
      Return WinGeoFaultText(wgHr)

   If wgSaid
      Return wgSaid

   Return WinGeoFaultText(wgHr)
}

WinGeoKeyboardCountry() {
; The country carried by the keyboard layout being typed with. Every layout is
; installed against a language identifier and the sublanguage half of it names
; a region: 0x0409 is English as written in the United States, 0x0C0C French as
; written in Canada. GetKeyboardLayout reads the calling thread's layout, and
; since the window whose button was just pressed is the foreground one, that is
; the layout showing in the taskbar.

   wgHkl := DllCall("user32\GetKeyboardLayout", "UInt", 0, "Ptr")
   wgLang := wgHkl & 0xFFFF
   If !wgLang
      Return ""

   Return WinGeoCountryOfLocale(wgLang)
}

WinGeoUILanguageCountry() {
; The country carried by the language Windows itself is displayed in. A weak
; hint - an English Windows is installed the world over - which is why the
; caller asks for it last, but it costs nothing and it is never empty.

   Return WinGeoCountryOfLocale(DllCall("kernel32\GetUserDefaultUILanguage", "UShort"))
}

WinGeoNamesAlike(wgA, wgB) {
; Whether two names are the same word to a reader who minds neither case nor
; accents: Sao Paulo answers for São Paulo, CHISINAU for Chișinău. That is
; CompareStringW at the invariant locale, told to ignore case and nonspacing
; marks - on every Windows this script could land on, XP included.

   Return (DllCall("kernel32\CompareStringW", "UInt", 0x7F, "UInt", 0x3, "WStr", wgA, "Int", -1, "WStr", wgB, "Int", -1, "Int")=2)   ; LOCALE_INVARIANT, NORM_IGNORECASE|NORM_IGNORENONSPACE, CSTR_EQUAL
}

WinGeoCountryOfLocale(wgLcid) {
; The ISO 3166-1 alpha-2 code a locale belongs to, straight from Windows.

   VarSetCapacity(wgBuf, 64, 0)
   wgLen := DllCall("kernel32\GetLocaleInfoW", "UInt", wgLcid, "UInt", 0x5A, "Ptr", &wgBuf, "Int", 16, "Int")   ; LOCALE_SISO3166CTRYNAME
   wgCode := (wgLen>1) ? StrGet(&wgBuf, wgLen - 1, "UTF-16") : ""
   Return (StrLen(wgCode)=2) ? Format("{:U}", wgCode) : ""
}

WinGeoRegionCountry() {
; The country the user set under Settings > Time & language > Region.
; GetUserDefaultGeoName came with Windows 10 1709 and gives the code outright;
; before that the country was a numeric identifier that GetGeoInfo translates.

   VarSetCapacity(wgBuf, 64, 0)
   wgProc := WinGeoProcAddress("kernel32.dll", "GetUserDefaultGeoName")
   wgLen := wgProc ? DllCall(wgProc, "Ptr", &wgBuf, "Int", 16, "Int") : 0
   wgCode := (wgLen>1) ? StrGet(&wgBuf, wgLen - 1, "UTF-16") : ""
   If (StrLen(wgCode)=2)
      Return Format("{:U}", wgCode)

   wgGeoId := DllCall("kernel32\GetUserGeoID", "Int", 16, "Int")   ; GEOCLASS_NATION
   If (!wgGeoId || wgGeoId=-1)
      Return WinGeoCountryOfLocale(DllCall("kernel32\GetUserDefaultLCID", "UInt"))

   VarSetCapacity(wgBuf, 64, 0)
   wgLen := DllCall("kernel32\GetGeoInfoW", "Int", wgGeoId, "UInt", 4, "Ptr", &wgBuf, "Int", 16, "UShort", 0, "Int")   ; GEO_ISO2
   wgCode := (wgLen>1) ? StrGet(&wgBuf, wgLen - 1, "UTF-16") : ""
   If (StrLen(wgCode)=2)
      Return Format("{:U}", wgCode)

   Return WinGeoCountryOfLocale(DllCall("kernel32\GetUserDefaultLCID", "UInt"))
}

WinGeoProcAddress(wgDll, wgFunc) {
; Whether a given Windows version exports a given function at all. Asked before
; the call rather than after it, so that a name missing on an older Windows is
; an ordinary answer here instead of a failed DllCall to be picked apart.

   wgModule := DllCall("kernel32\GetModuleHandleW", "WStr", wgDll, "Ptr")
   If !wgModule
      wgModule := DllCall("kernel32\LoadLibraryW", "WStr", wgDll, "Ptr")

   Return wgModule ? DllCall("kernel32\GetProcAddress", "Ptr", wgModule, "AStr", wgFunc, "Ptr") : 0
}

WinGeoTimeZoneOffsets(ByRef wgJanuary, ByRef wgJuly) {
; The two offsets from UTC this computer's time zone keeps, in hours, written
; the way the location index writes them: the offset in force on the 1st of
; January and the one in force on the 1st of July - 2.0 and 3.0 for Romania,
; 11.0 and 10.0 for Sydney, whose summer time runs over the new year, 4.5 twice
; over for Afghanistan, which keeps no summer time. The index is kept by season
; rather than by standard and daylight time, so that one rule serves both
; hemispheres; handing over standard and daylight time here, as this used to,
; had every location south of the equator an hour out all year round.
;
; TIME_ZONE_INFORMATION states its biases as the minutes to be added to local
; time to arrive at UTC, so an offset east of Greenwich is a negative bias and
; the sign has to be turned around here. A zone that never changes its clocks
; leaves DaylightDate.wMonth at zero, and then the one offset serves for both.
; Where the clocks do change, the months the two dates fall in tell the
; hemispheres apart: a zone whose daylight time begins later in the year than
; it ends - October to April, say - is on daylight time in January.

   wgJanuary := wgJuly := ""
   VarSetCapacity(wgTzi, 172, 0)
   If (DllCall("kernel32\GetTimeZoneInformation", "Ptr", &wgTzi, "UInt")=0xFFFFFFFF)
      Return 0

   wgBias := NumGet(wgTzi, 0, "Int")
   wgStdMonth := NumGet(wgTzi, 70, "UShort")    ; StandardDate.wMonth
   wgStdBias := NumGet(wgTzi, 84, "Int")
   wgDstMonth := NumGet(wgTzi, 154, "UShort")   ; DaylightDate.wMonth
   wgDstBias := NumGet(wgTzi, 168, "Int")
   wgStandard := WinGeoTrimOffset(-(wgBias + wgStdBias)/60)
   wgDaylight := wgDstMonth ? WinGeoTrimOffset(-(wgBias + wgDstBias)/60) : wgStandard
   wgSouthern := (wgDstMonth && wgStdMonth && wgDstMonth>wgStdMonth) ? 1 : 0
   wgJanuary := wgSouthern ? wgDaylight : wgStandard
   wgJuly := wgSouthern ? wgStandard : wgDaylight
   Return 1
}

WinGeoTrimOffset(wgHours) {
; An offset written short but never bare: 2.0, -3.5, 5.75, the quarter hours
; that Nepal and the Chathams keep included.

   wgText := Round(wgHours, 2)
   wgText := RegExReplace(wgText, "(\.\d*?)0+$", "$1")
   Return RegExReplace(wgText, "\.$", ".0")
}
