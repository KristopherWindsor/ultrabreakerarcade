@ECHO OFF

REM compiles dev environment where the game can be compiled from git source and run with a copy of the git data files

SET targetfolder="../../dev"

RD /S /Q %targetfolder%
MKDIR %targetfolder%

COPY Ultrabreaker.bas %targetfolder%
COPY Leveler.bas %targetfolder%

XCOPY /E /Q ..\distribution\* %targetfolder%
