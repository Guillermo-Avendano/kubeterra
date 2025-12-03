@echo off
setlocal enabledelayedexpansion

set "DEFAULT_DISTNAME=mobius"
set /p "DISTNAME=Enter WSL name (default: %DEFAULT_DISTNAME%): "
if "%DISTNAME%"=="" set "DISTNAME=%DEFAULT_DISTNAME%"

set "dirName=C:\rocket\wsl\%DISTNAME%"
set "CURR_DIR=%~dp0"

echo. 
echo ==== WSL Installation ==== 
echo Distribution Name: %DISTNAME% 
echo Directory: %dirName% 
echo Current Directory: %CURR_DIR% 

REM --- Check if distribution exists ---
echo Checking if WSL distribution "%DISTNAME%" exists... 
set "EXISTS=false"
for /f "tokens=*" %%i in ('wsl -l -q') do (
    if /i "%%i"=="%DISTNAME%" set "EXISTS=true"
)

if "%EXISTS%"=="true" (
    echo ERROR: The WSL distribution "%DISTNAME%" already exists! 
    echo Please choose a different name. 
    echo Script aborted due to existing distribution. 
    goto :end
)

REM --- Check and create directory ---
echo Checking directory "%dirName%"... 
if exist "%dirName%" (
    echo Directory already exists. 
) else (
    mkdir "%dirName%"
    if exist "%dirName%" (
        echo Directory created successfully. 
    ) else (
        echo ERROR: Could not create directory. 
        goto :end
    )
)

REM --- Import WSL distribution ---
echo Importing WSL distribution... 
echo Command: wsl --import %DISTNAME% "%dirName%" "%CURR_DIR%ubuntu22.04.tar.gz" --version 2 
wsl --import %DISTNAME% "%dirName%" "%CURR_DIR%ubuntu22.04.tar.gz" --version 2  2>&1

echo WSL import completed. 
echo Initial User Credentials: 
echo user=rocket password=rocket 
echo To access the new distribution, run: wsl -d %DISTNAME% 

:end
