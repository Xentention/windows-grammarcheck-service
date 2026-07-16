@echo off

setlocal
set SERVICE_NAME=%1
set PORT=%2
set TOKEN=%3
set APP_DIR=%~dp0
set NSSM=%APP_DIR%nssm.exe
set EXE=%APP_DIR%RuGrammarCheck.exe

if "%SERVICE_NAME%"=="" (
  echo Usage: install-service.bat ^<ServiceName^> [Port] [Token]
  exit /b 1
)

echo Installing service "%SERVICE_NAME%" -^> %EXE%
"%NSSM%" install %SERVICE_NAME% "%EXE%"
"%NSSM%" set %SERVICE_NAME% AppDirectory "%APP_DIR%"
"%NSSM%" set %SERVICE_NAME% DisplayName "%SERVICE_NAME%"
"%NSSM%" set %SERVICE_NAME% Description "RU grammar correction service"
"%NSSM%" set %SERVICE_NAME% Start SERVICE_AUTO_START

set ENVARGS=
if not "%PORT%"=="" (
  echo   overriding PORT=%PORT% for this instance
  set ENVARGS=PORT=%PORT%
)

if not "%ENVARGS%"=="" (
  "%NSSM%" set %SERVICE_NAME% AppEnvironmentExtra %ENVARGS%
)

mkdir "%APP_DIR%logs\%SERVICE_NAME%" 2>nul
"%NSSM%" set %SERVICE_NAME% AppStdout "%APP_DIR%logs\%SERVICE_NAME%\stdout.log"
"%NSSM%" set %SERVICE_NAME% AppStderr "%APP_DIR%logs\%SERVICE_NAME%\stderr.log"
"%NSSM%" set %SERVICE_NAME% AppRotateFiles 1
"%NSSM%" set %SERVICE_NAME% AppRotateOnline 1
"%NSSM%" set %SERVICE_NAME% AppRotateBytes 10485760

"%NSSM%" start %SERVICE_NAME%

echo.
echo Done. Useful commands:
echo   "%NSSM%" status %SERVICE_NAME%
echo   "%NSSM%" stop %SERVICE_NAME%
echo   "%NSSM%" remove %SERVICE_NAME% confirm
endlocal