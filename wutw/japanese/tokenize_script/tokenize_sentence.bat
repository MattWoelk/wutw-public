@echo off
setlocal

chcp 65001 > nul

set VENV_DIR=%~dp0.venv
set SCRIPT_NAME=tokenize_sentence.py

if not exist "%VENV_DIR%\Scripts\python.exe" (
    echo Creating virtual environment...
    echo "%VENV_DIR%"
    mkdir "%VENV_DIR%"
    python -m venv "%VENV_DIR%"
    
    echo Installing dependencies...
    "%VENV_DIR%\Scripts\pip.exe" install -r "%~dp0requirements.txt"
)

"%VENV_DIR%\Scripts\python.exe" -X utf8 "%~dp0%SCRIPT_NAME%" "%~1" > "%~2"
