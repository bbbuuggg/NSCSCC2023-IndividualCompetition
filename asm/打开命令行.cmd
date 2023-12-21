@echo off
set PATH=%cd%\python37-32;%cd%\msys\1.0\bin;%cd%\toolchain\bin;%cd%\qemu;%PATH%
cd %cd%\..\source\supervisor_v*\kernel
call cmd
