================================================================================
 cbt-main.dll - building with Microsoft Visual Studio
================================================================================

Open cbt-main.sln, pick a configuration in the toolbar (Release / x64 is the one
that matters for the 64-bit AutoHotkey build), then Build > Build Solution
(Ctrl+Shift+B).

The old MinGW/g++ route described in readme.txt still works exactly as before -
nothing in the .cpp / .h files was modified for Visual Studio. All the
adjustments needed by the Microsoft compiler live in cbt-main.vcxproj.


--------------------------------------------------------------------------------
 Output
--------------------------------------------------------------------------------

  build\x64\Release\cbt-main.dll      <- the one the 64-bit script loads
  build\Win32\Release\cbt-main.dll    <- 32-bit build
  build\<Platform>\<Config>\cbt-main.pdb, .lib, .exp

To deploy, copy the DLL where bells-tower.ahk looks for it:

  copy /Y build\x64\Release\cbt-main.dll ..\cbt-main.dll
  copy /Y build\x64\Release\cbt-main.dll .\cbt-main.dll

(the script loads <script dir>\cbt-main.dll, or <script dir>\cpp-dll\cbt-main.dll
when it runs uncompiled from the development folder.)

The build never overwrites the DLLs already committed in this folder; the copy
step above is deliberate and manual.


--------------------------------------------------------------------------------
 Only cbt-main.cpp is compiled
--------------------------------------------------------------------------------

cbt-main.cpp is a "unity build": it #includes MoonPhase.cpp, SunRise.cpp,
MoonRise.cpp, Twilight.cpp and SolarCalculator.cpp directly, in that order, and
the order matters (struct skyCoordinates is defined only once, in SunRise.cpp;
MoonRise.cpp relies on it).

So the other .cpp files are listed in the project - so that they show up in
Solution Explorer and can be edited - but they are marked
"Excluded From Build". Do not turn that off: compiling them separately produces
duplicate symbols and errors. moonDiskAngle.cpp/.h are not used at all (their
#include in cbt-main.cpp is commented out).

IntelliSense will show squiggles inside those excluded files because it parses
them standalone. That is expected and does not affect the build.


--------------------------------------------------------------------------------
 Why the project settings are what they are
--------------------------------------------------------------------------------

These are the places where the Microsoft compiler differs from g++ and where a
default Visual Studio project would fail or misbehave:

_USE_MATH_DEFINES (preprocessor)
    MSVC does not define M_PI in <math.h> unless this macro is set first. The
    code uses M_PI in every source file.

Forced include file: cmath  (/FI cmath)
    SunRise.cpp and MoonRise.cpp do "#define remainder(x, y) ..." as a function
    macro. In the Microsoft STL, <cmath> / <xtgmath.h> declare overloads and
    templates named remainder(...), so if <cmath> were first pulled in after
    that #define - which is what happens when SolarCalculator.cpp is included -
    the macro would rewrite those declarations and the build would break.
    Forcing <cmath> in before the first line of the translation unit makes the
    later #include <cmath> a no-op. It also brings in the integral overloads of
    isnan()/signbit(), which the code calls with time_t arguments.

/utf-8  (additional option)
    cbt-main.cpp, SolarCalculator.cpp/.h are UTF-8 without a BOM and contain
    non-ASCII characters in comments (author name, delta-T, Saemundsson). Without
    /utf-8 the compiler reads them in the local ANSI code page and emits C4819.

Conformance mode off (/permissive) + C++17
    Matches "g++ -fpermissive -std=gnu++17" that this code was written against.

NOMINMAX
    <algorithm> is included after <windows.h> in cbt-main.cpp; this keeps the
    min/max macros from breaking the standard headers.

SDL checks off
    /sdl promotes warnings such as C4700 (potentially uninitialized local) to
    errors. SunRise.cpp / MoonRise.cpp use "goto noevent" jumps over plain
    uninitialized declarations, which is legal C++ but trips that analysis.

Runtime library: Multi-threaded (/MT, static)
    The g++ build used -static-libgcc -static-libstdc++ so the DLL had no
    external runtime dependency. /MT gives the same: the resulting DLL does not
    need the Visual C++ redistributable installed on the user's machine.

Floating point model: Precise
    calcSunriseSunset() signals "no event" by returning NaN and the callers test
    it with isnan(). /fp:fast is allowed to assume NaNs never occur.

Disabled warnings 4018 4101 4102 4244 4267 4305 4477 4996
    Noise only: implicit double->int/float narrowing, signed/unsigned compares,
    unused locals and labels, "unsafe" CRT calls. The g++ build was equally
    quiet about them.

Platform toolset / Windows SDK
    The project uses $(DefaultPlatformToolset) and Windows SDK "10.0" (= latest
    installed), so it opens and builds in any recent Visual Studio without a
    retarget prompt. The .sln header says "Version 17"; a newer Visual Studio
    just updates that line the first time it saves the solution.


--------------------------------------------------------------------------------
 Exported names
--------------------------------------------------------------------------------

The exports are declared as   extern "C" __declspec(dllexport) __stdcall.

  x64   : undecorated, e.g. getMoonPhase
  Win32 : decorated,   e.g. _getMoonPhase@56

That is exactly what callCBTdllFunc() in bells-tower.ahk builds for each of the
two bitnesses, so no .def file is needed. Check a build with:

  dumpbin /exports build\x64\Release\cbt-main.dll

Nine functions should be listed: calculateEquiSols, getMoonElevation,
getMoonNoon, getMoonPhase, getSolarCalculatorData, getSunAzimuthElevation,
getSunMoonRiseSet, getTwilightDuration, oldgetMoonPhase.
(getMoonLitAngle is commented out in cbt-main.cpp and is not exported.)


--------------------------------------------------------------------------------
 Command line builds
--------------------------------------------------------------------------------

From a "Developer Command Prompt for VS":

  msbuild cbt-main.sln /p:Configuration=Release /p:Platform=x64
  msbuild cbt-main.sln /p:Configuration=Release /p:Platform=Win32
