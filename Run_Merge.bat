@echo off
:: This bypasses PowerShell execution restrictions for just this one run
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0merge_subs.ps1"