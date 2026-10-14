@echo off
rem Wrapper to allow running "git-account" directly from CMD or PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0git-account.ps1" %*
