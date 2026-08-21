================================================================================
 moon-accuracy-study - where the lunar series came from, and what they are worth
================================================================================

Nothing here is compiled into cbt-main.dll and nothing here is on any build
path. Two things live in this folder:

  * gen_moonelp.py, which writes cpp-dll/MoonELP.cpp - the truncated ELP/MPP02
    series the DLL now uses. That file is generated; this is where it comes
    from, and re-running the script reproduces it byte for byte.

  * the measurement harness behind every accuracy figure quoted in MoonELP.cpp
    and in the comments of cbt-main.cpp, which lays the DLL's own answers beside
    JPL DE440.

Delete the folder if you do not want it; the DLL does not know it exists. But
MoonELP.cpp cannot be regenerated without it.

--------------------------------------------------------------------------------
 Setting it up
--------------------------------------------------------------------------------

  python3 -m venv venv
  ./venv/bin/pip install numpy jplephem
  curl -O https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de440s.bsp

de440s.bsp is 32 MB and is deliberately not committed. It covers 1849-2150,
which bounds the windows the scripts sample.

Everything is run from inside this folder, e.g.  ./venv/bin/python v_place.py

--------------------------------------------------------------------------------
 Generating the series
--------------------------------------------------------------------------------

  gen_moonelp.py      Writes ../MoonELP.cpp: the ELP/MPP02 series cut to the
                      terms of at least 0''.01, with the LLR-fitted parameters
                      folded into the amplitudes.  Two constants at the top of
                      it set the cut and which of the theory's two parameter
                      sets to use.
  MoonELP_code.inc    The hand-written half of MoonELP.cpp - the code that sums
                      the series and turns the answer into the frame the rest of
                      the DLL works in.  Edit this, not MoonELP.cpp.
  elp_main.*          The series themselves, in the reformatted layout published
  elp_pert.*          with the C++ implementation at github.com/ytliu0/ElpMpp02.
                      The coefficients are Chapront and Francou's, from the
                      files the IMCCE published with the theory; that
                      repository's own code is GPL-3 and none of it is used
                      here or anywhere in this project.  The IMCCE ftp site
                      those files came from no longer serves them.

--------------------------------------------------------------------------------
 Checking the DLL against DE440
--------------------------------------------------------------------------------

t_dll.cpp builds the DLL's own sources on Linux - a three-line shim stands in
for windows.h - and drives its exports from stdin, so what is measured is the
shipping code and not a copy of it:

  g++ -O2 -fpermissive -I winshim -I .. -D'__declspec(x)=' -D'__stdcall=' \
      -o t_dll t_dll.cpp

  t_verify.py     The reference: DE440 with the light time taken off it, and the
                  same reduction to horizontal coordinates the DLL performs.
  v_place.py      Longitude, latitude, distance, azimuth, altitude and the
                  illuminated fraction, 3000 instants.
  v_riseset.py    Moonrise and moonset, twelve places, ninety days, against a
                  DE440 root-find on the same criterion.  Also with an observer
                  300 m up, to exercise the dip.
  v_phases.py     The four principal phases, against a DE440 root-find on the
                  elongation - beside what chapter 49 alone would have said.
  v_misc.py       The moon's highest point, and a check that the old 24-hour
                  window function and the new day function agree.
  v_edge.py       Polar days with no rise or no set, a "reverse" day where the
                  set precedes the rise, 23 and 25 hour days, and 1900 to 2200.
  b_dll.cpp       Times the exports.  Same build line as t_dll.cpp.

--------------------------------------------------------------------------------
 How the design was settled
--------------------------------------------------------------------------------

  t_elp.py        elp.py against the ten test cases published with the theory.
                  Run this before trusting anything else here.
  elp.py          ELP/MPP02 in numpy, written from the published equations.
  de440.py        DE440 through jplephem, plus the frame rotations.
  t_moonelp.cpp   The C++ port of the series against elp.py, same truncation.
  t_prec.py       Why MoonELP.cpp rotates out to J2000 and back rather than
                  simply adding the precession to ELP's longitude.
  t_cheb.py       How many Chebyshev points one day of the moon needs, which is
                  what cbt-main.cpp's day block is built on.
  t_cut.py        Accuracy against DE440 at seven truncation levels.
  t_size.py       Term counts and table sizes at those levels.
  t_range.py      What the chosen truncation does outside 1850-2150, measured
                  against the complete 35901-term theory where DE440s stops.
  b_moonelp.cpp   Times one call of the series on its own.

--------------------------------------------------------------------------------
 What it replaced
--------------------------------------------------------------------------------

These measure the code as it stood before, and are kept so the comparison can
be repeated rather than taken on trust.

  t_old.cpp       Builds the DLL as it stood before the rebuild and drives the
                  same exports, so the "before" column of every comparison is
                  the old code itself rather than a replica of it.  Fetch those
                  sources out of git first:

                    mkdir old
                    for f in cbt-main cbt-main.h MoonPhase MoonPhase.h SunRise \
                             SunRise.h MoonRise MoonRise.h Twilight Twilight.h \
                             SolarCalculator SolarCalculator.h; do
                      git show <commit>:cpp-dll/$f > old/$f
                    done
                    g++ -O2 -fpermissive -I winshim -I old \
                        -D'__declspec(x)=' -D'__stdcall=' -o t_old t_old.cpp

                  (the commit before the rebuild is the one that removed
                  convertUTCtoLocalTime).  "t_old bench" times it.
  v_riseset_old.py  The old rise and set against the same DE440 reference.
  meeus47.py      Meeus chapter 47, the 60-term series cbt-main.cpp carried,
  meeus47.json    with its tables as they were lifted from that source.
  riseset.py      MoonRise.cpp - the Sky & Telescope 1989 series, its 24-hour
                  window and its parabola - replicated step for step.
  pipeline.py     The DLL's reduction in Python, driving any of the theories.
  compare.py      Geocentric position, chapter 47 and ELP at seven cuts.
  rs_compare.py   Moonrise and moonset out of MoonRise.cpp, twelve places.
  misc_compare.py Topocentric position and the lit fraction, by theory and site.
  phases.py       Chapter 49's phase instants against a DE440 root-find.
  noise.py        What moves a rise or a set for reasons that have nothing to do
  noise2.py       with the lunar theory: refraction, the horizon dip, delta T.
