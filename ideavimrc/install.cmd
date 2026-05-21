@echo off
REM Windows: run ideavimrc/install.sh via Git Bash
setlocal
cd /d "%~dp0"
if defined NVIM_GIT_BASH (
  "%NVIM_GIT_BASH%" "%~dp0install.sh" %*
  exit /b %ERRORLEVEL%
)
where bash.exe >nul 2>&1
if %ERRORLEVEL%==0 (
  bash.exe "%~dp0install.sh" %*
  exit /b %ERRORLEVEL%
)
echo [install.cmd] Install Git Bash or set NVIM_GIT_BASH to bash.exe 1>&2
exit /b 1
