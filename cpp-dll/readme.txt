
https://linux.die.net/man/1/g++
F:\temp\winlibs-i686-gcc-12.1.0-mingw-w64msvcrt-10.0.0-r3\mingw32\bin
F:\temp\winlibs-x86_64-gcc-12.1.0-mingw-w64msvcrt-10.0.0-r3\mingw64\bin


cd /d "E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\cpp-dll"

g++ -c -fpermissive cbt-main.cpp

g++ -shared -o cbt-main.dll cbt-main.o -W -static-libgcc -static-libstdc++


