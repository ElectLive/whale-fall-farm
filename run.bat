@echo off
rem Launch Whale Fall Farm with a local Godot 4.7 binary.
rem Set GODOT_BIN if your Godot executable is not on PATH.
setlocal
if "%GODOT_BIN%"=="" set GODOT_BIN=godot
"%GODOT_BIN%" --path "%~dp0"
if errorlevel 1 pause
