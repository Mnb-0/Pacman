@echo off
rem Builds Pacman.exe from the command line (Visual Studio 2022 or Build Tools with the C++ workload).
rem Set IRVINE to your Irvine32 folder if it isn't C:\Irvine32.
if "%IRVINE%"=="" set IRVINE=C:\Irvine32
set VCVARS=
for %%E in (Community Professional Enterprise BuildTools) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars32.bat" set VCVARS="C:\Program Files\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars32.bat"
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars32.bat" set VCVARS="C:\Program Files (x86)\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars32.bat"
)
if not defined VCVARS (
    echo Visual Studio 2022 C++ tools not found.
    exit /b 1
)
call %VCVARS% >nul
cd /d "%~dp0"
if not exist build mkdir build
ml /nologo /c /coff /Zi /I"%IRVINE%" /Fobuild\main.obj main.asm || exit /b 1
link /nologo /SUBSYSTEM:CONSOLE /DEBUG /OUT:build\Pacman.exe build\main.obj /LIBPATH:"%IRVINE%" Irvine32.lib kernel32.lib user32.lib winmm.lib || exit /b 1
echo Built build\Pacman.exe - run it from this folder so the .wav files are found.
