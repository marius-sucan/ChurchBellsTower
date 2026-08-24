wmic Path win32_process where "commandline Like '%%\\v3\\bells-tower%%'"  Call Terminate
timeout /t 3 /nobreak
cd /d "E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\cpp-dll"
g++ -O2 -ffunction-sections -fdata-sections -fpermissive -c cbt-main.cpp
timeout /t 2 /nobreak
g++ -shared -s -static -Wl,--gc-sections -o cbt-main.dll cbt-main.o
timeout /t 2 /nobreak
"E:\Sucan twins\_small-apps\AutoHotkey\my scripts\bells-tower\v3\AutoHotkeyU64.exe - Raccourci.lnk"
timeout /t 2 /nobreak
exit
close
quit
break
