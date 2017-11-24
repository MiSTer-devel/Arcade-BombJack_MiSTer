@echo off

set    zip=bombjack.zip
set ifiles=01_h03t.bin+02_p04t.bin+02_p04t.bin+03_e08t.bin+03_e08t.bin+04_h08t.bin+04_h08t.bin+05_k08t.bin+05_k08t.bin+06_l08t.bin+07_n08t.bin+08_r08t.bin+09_j01b.bin+10_l01b.bin+11_m01b.bin+12_n01b.bin+13.1r+14_j07b.bin+15_l07b.bin+16_m07b.bin 
set  ofile=a.bmbjck.rom

rem =====================================
setlocal ENABLEDELAYEDEXPANSION

set pwd=%~dp0
echo.
echo.

if EXIST %zip% (

	!pwd!7za x -otmp %zip%
	if !ERRORLEVEL! EQU 0 ( 
		cd tmp

		copy /b/y %ifiles% !pwd!%ofile%
		if !ERRORLEVEL! EQU 0 ( 
			echo.
			echo ** done **
			echo.
			echo Copy "%ofile%" into root of SD card
		)
		cd !pwd!
		rmdir /s /q tmp
	)

) else (

	echo Error: Cannot find "%zip%" file
	echo.
	echo Put "%zip%", "7za.exe" and "%~nx0" into the same directory
)

echo.
echo.
pause
