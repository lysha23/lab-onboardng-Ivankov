@echo off
chcp 65001 >nul
setlocal DisableDelayedExpansion
REM Диагностика клиентского компьютера. Иванков. 26.10.2026.
title Диагностика компьютера
set "report=%~dp0pc_report.txt"
type nul > "%report%"
if errorlevel 1 (
    echo Не удалось создать отчёт. Распакуйте папку в доступное для записи место.
    pause
    exit /b 1
)
REM Получение сведений через WMIC, как в задании.
where wmic >nul 2>&1
if errorlevel 1 goto cim
for /f "tokens=1,* delims==" %%A in ('wmic os get Caption,Version,TotalVisibleMemorySize,FreePhysicalMemory /value 2^>nul') do for /f "delims=" %%C in ("%%B") do set "%%A=%%C"
for /f "tokens=1,* delims==" %%A in ('wmic cpu get Name /value 2^>nul') do for /f "delims=" %%C in ("%%B") do set "%%A=%%C"
for /f "tokens=1,* delims==" %%A in ('wmic logicaldisk where "DeviceID='C:'" get Size,FreeSpace /value 2^>nul') do for /f "delims=" %%C in ("%%B") do set "%%A=%%C"
if defined Caption if defined Name if defined Size goto show
:cim
REM Запасной способ для Windows без WMIC. Открывать PowerShell вручную не нужно.
for /f "tokens=1,* delims==" %%A in ('powershell.exe -NoLogo -NoProfile -Command "[Console]::OutputEncoding=[Text.UTF8Encoding]::new(); $ErrorActionPreference='Stop'; try { $o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor; $d=Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\"; 'Caption='+$o.Caption; 'Version='+$o.Version; 'Name='+($c.Name -join ', '); 'TotalVisibleMemorySize='+$o.TotalVisibleMemorySize; 'FreePhysicalMemory='+$o.FreePhysicalMemory; 'Size='+$d.Size; 'FreeSpace='+$d.FreeSpace } catch { exit 1 }"') do set "%%A=%%B"
:show
setlocal EnableDelayedExpansion
REM Заголовок и сведения об операционной системе.
set "line=Диагностика компьютера"
call :emit
set "line========================================="
call :emit
set "line=Операционная система"
call :emit
set "line=Название: !Caption!"
call :emit
set "line=Версия: !Version!"
call :emit
set "line=----------------------------------------"
call :emit
REM Полное название процессора.
set "line=Процессор: !Name!"
call :emit
set "line=----------------------------------------"
call :emit
REM Память приходит в КБ. Делим на 1048576, получаем целые ГБ.
set "line=Оперативная память"
call :emit
set "memoryReady="
if defined TotalVisibleMemorySize if defined FreePhysicalMemory set "memoryReady=1"
if defined memoryReady (
    set /a totalGB=TotalVisibleMemorySize / 1048576
    set /a freeGB=FreePhysicalMemory / 1048576
    set "line=Всего памяти: !totalGB! ГБ"
    call :emit
    set "line=Свободно памяти: !freeGB! ГБ"
    call :emit
) else (
    set "line=Не удалось получить сведения о памяти."
    call :emit
)
set "line=----------------------------------------"
call :emit
REM Диск приходит в байтах. Делим на 1024 трижды без переполнения set /a.
set "line=Диск C"
call :emit
set "diskReady="
if defined Size if defined FreeSpace set "diskReady=1"
if defined diskReady (
    set "number=!Size!"
    call :bytesToGB
    set "line=Всего места: !number! ГБ"
    call :emit
    set "number=!FreeSpace!"
    call :bytesToGB
    set "line=Свободно места: !number! ГБ"
    call :emit
) else (
    set "line=Не удалось получить сведения о диске C."
    call :emit
)
set "line=----------------------------------------"
call :emit
REM Список программ из реестра. В отчёт попадают только названия.
set "line=Установленные программы"
call :emit
set "line=Идёт поиск программ..."
call :emit
set /a count=0
setlocal DisableDelayedExpansion
for %%K in ("HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall") do (
    for /f "tokens=1,2,*" %%A in ('reg query "%%~K" /s /v DisplayName 2^>nul ^| findstr /c:"REG_SZ" /c:"REG_EXPAND_SZ"') do (
        if /i "%%A"=="DisplayName" (
            set "line=%%C"
            setlocal EnableDelayedExpansion
            call :emit
            endlocal
            set /a count+=1 >nul
        )
    )
)
REM Возвращаем число найденных программ из вложенного setlocal.
endlocal & set "count=%count%"
if !count! equ 0 (
    set "line=Названия программ в проверенных разделах реестра не найдены."
    call :emit
)
set "line=----------------------------------------"
call :emit
set "line=Отчёт сохранён"
call :emit
pause
exit /b

:emit
REM Одна и та же строка выводится в окно и дописывается в отчёт.
echo(!line!
>>"!report!" echo(!line!
exit /b

:bytesToGB
REM Деление длинного десятичного числа по цифрам: 1024^3 = 1073741824.
for /l %%P in (1,1,3) do (
    set "quotient="
    set /a remainder=0
    for /l %%I in (0,1,24) do (
        set "digit=!number:~%%I,1!"
        if defined digit (
            set /a "part=remainder*10+digit, q=part/1024, remainder=part%%1024"
            if defined quotient (
                set "quotient=!quotient!!q!"
            ) else if !q! neq 0 set "quotient=!q!"
        )
    )
    if not defined quotient set "quotient=0"
    set "number=!quotient!"
)
exit /b
