@ECHO OFF

SETLOCAL

SET DiskPartScript="%TEMP%DiskpartScript.txt"

ECHO SELECT VDISK FILE="%~1" > %DiskPartScript%
ECHO DETACH VDISK >> %DiskPartScript%

DiskPart /s %DiskPartScript%

ENDLOCAL