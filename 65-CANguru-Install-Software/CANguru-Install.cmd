@echo off
SET COMPORT=COM3

:loop
cls
echo.
echo CARguru - Helper
echo.
echo USB-Anschluesse:
call files
echo.
echo Bitte waehlen Sie eine der folgenden Optionen:
echo. 
echo  1 - COM-Port festlegen
echo  2 - Flash-Speicher loeschen
echo  3 - OTA-Upload einleiten (IP-Adresse zuweisen) auf %COMPORT%, weiter mit Browser
echo  4 - Upload CANguru-Decoder (aus Ordner CANguru-Files) ueber %COMPORT%
echo  5 - IP-Adresse zuweisen und Upload CANguru-Decoder (aus Ordner CANguru-Files) ueber %COMPORT%
echo  6 - Upload CANguru-Bridge (aus Ordner CANguru-Bridge) ueber %COMPORT%
echo  7 - Putty starten
echo. 
echo  x - Beenden
echo.
set /p SELECTED=Ihre Auswahl: 

if "%SELECTED%" == "x" goto :eof
if "%SELECTED%" == "1" goto :1SetComPort
if "%SELECTED%" == "2" goto :2ERASE_FLASH
if "%SELECTED%" == "3" goto :3PREPARE_OTA
if "%SELECTED%" == "4" goto :4UPLOAD_FIRMWARE
if "%SELECTED%" == "5" goto :5PREPARE_UPLOAD_FIRMWARE
if "%SELECTED%" == "6" goto :6UPLOAD_BRIDGE
if "%SELECTED%" == "7" goto :7Putty

goto :errorInput 


:1SetComPort
REM @echo OFF
REM FOR /L %%x IN (1, 1, 29) DO ECHO %%x - Setze COM-Port %%x
echo Bitte geben Sie die Nummer des COM-Anschlusses ein (z.B. 5 fuer COM5) oder x fuer Exit
echo.
set /p SELECTED=Ihre Auswahl: 

if "%SELECTED%" == "x" goto :loop

set COMPORT=COM%SELECTED%
goto :loop
goto :errorInput 

pause
goto :loop

:2ERASE_FLASH
@echo on
esptool.exe --chip esp32 --port %COMPORT% erase_flash
@echo off
echo.
pause
goto :loop

:3PREPARE_OTA
@echo on
echo.
echo Weist dem Decoder eine IP-Adresse zu; anschließend sollte diese Adresse im Browser aufgerufen werden;
echo dann kann von dort eine Software (firmware.bin) ausgewaehlt und auf den Decoder geladen werden
esptool.exe --chip esp32 --port %COMPORT% --baud 460800 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 Prepare-OTA/bootloader.bin 0x8000 Prepare-OTA/partitions.bin 0xe000 Prepare-OTA/boot_app0.bin 0x10000 Prepare-OTA/firmware.bin
Putty\putty.exe -serial %COMPORT% -sercfg 115200,8,n,1,N
@echo off
echo.
pause
goto :loop

:4UPLOAD_FIRMWARE
@echo on
echo.
echo Geht davon aus, dass die aktuelle Decoder-Software im Verzeichnis CANguru-Files steht und laedt diese Software (firmware.bin) auf den Decoder hoch
esptool.exe --chip esp32 --port %COMPORT% --baud 460800 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 CANguru-Files/bootloader.bin 0x8000 CANguru-Files/partitions.bin 0x10000 CANguru-Files/firmware.bin
@echo off
echo.
pause
goto :loop

:5PREPARE_UPLOAD_FIRMWARE
@echo on
echo.
echo Geht davon aus, dass die aktuelle Decoder-Software im Verzeichnis CANguru-Files steht; weist dem Decoder eine IP-Adresse zu;
echo laedt anschließend diese Software (firmware.bin) auf den Decoder hoch
esptool.exe --chip esp32 --port %COMPORT% --baud 460800 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 Prepare-Upload/bootloader.bin 0x8000 Prepare-Upload/partitions.bin 0x10000 Prepare-Upload/firmware.bin
Putty\putty.exe -serial %COMPORT% -sercfg 115200,8,n,1,N
esptool.exe --chip esp32 --port %COMPORT% --baud 460800 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 CANguru-Files/bootloader.bin 0x8000 CANguru-Files/partitions.bin 0x10000 CANguru-Files/firmware.bin
@echo off
echo.
pause
goto :loop

:6UPLOAD_BRIDGE
@echo on
echo.
echo Geht davon aus, dass die aktuelle Bridge-Software im Verzeichnis CANguru-Bridge steht; laedt diese Software auf den Olimex ESP32-EVB hoch
esptool.exe --chip esp32 --port %COMPORT% --baud 460800 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 CANguru-Bridge/bootloader.bin 0x8000 CANguru-Bridge/partitions.bin 0x10000 CANguru-Bridge/firmware.bin
@echo off
echo.
pause
goto :loop

:7Putty
@echo on
Putty\putty.exe -serial %COMPORT% -sercfg 115200,8,n,1,N
@echo off
echo.
pause
goto :loop

:errorInput
echo.
echo Falsche Eingabe! Bitte erneut versuchen!
echo.
pause
goto :loop

