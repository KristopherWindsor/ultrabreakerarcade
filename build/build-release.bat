@ECHO OFF

REM compiles playable game

SET targetfolder="../../release"

RD /S /Q %targetfolder%
MKDIR %targetfolder%

CALL compile.bat
CALL compile-leveler.bat

MOVE ../src/Ultrabreaker.exe %targetfolder%
MOVE ../src/Leveler.exe %targetfolder%

XCOPY /E /Q ..\distribution\* %targetfolder%
