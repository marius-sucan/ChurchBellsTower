wmic Path win32_process where "commandline Like '%%\\v3\\bells-tower%%'"  Call Terminate
timeout /t 3 /nobreak
cd /d "E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\cpp-dll"
g++ -c -fpermissive cbt-main.cpp
timeout /t 2 /nobreak
g++ -shared -o cbt-main.dll cbt-main.o -W -static-libgcc -static-libstdc++
timeout /t 2 /nobreak
"E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\AutoHotkeyU64.exe - Raccourci.lnk"
timeout /t 2 /nobreak
exit
close
quit
break
