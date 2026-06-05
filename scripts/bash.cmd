@echo off
REM Windows: Git Bash for toggleterm. Override with env NVIM_GIT_BASH (full path to bash.exe).
REM termopen 已设置 cwd；用 PWD 锚定后再 exec 交互 shell，避免落在 HOME。
setlocal
set "BASH="
if defined NVIM_GIT_BASH (
  set "BASH=%NVIM_GIT_BASH%"
) else (
  for /f "delims=" %%i in ('where bash.exe 2^>nul') do (
    set "BASH=%%i"
    goto :found
  )
)
if not defined BASH (
  echo [bash.cmd] Set NVIM_GIT_BASH to your Git bash.exe path. 1>&2
  exit /b 1
)
:found
"%BASH%" -i -c "cd \"${PWD}\" 2>/dev/null || cd \"$(pwd -W 2>/dev/null || pwd)\"; exec bash -i"
exit /b %ERRORLEVEL%
