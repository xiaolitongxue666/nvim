@echo off
REM Windows: Git Bash for toggleterm. Override with env NVIM_GIT_BASH (full path to bash.exe).
setlocal
if defined NVIM_GIT_BASH (
  "%NVIM_GIT_BASH%" --login -i
  exit /b %ERRORLEVEL%
)
where bash.exe >nul 2>&1
if %ERRORLEVEL%==0 (
  bash.exe --login -i
  exit /b %ERRORLEVEL%
)
echo [bash.cmd] Set NVIM_GIT_BASH to your Git bash.exe path. 1>&2
exit /b 1
