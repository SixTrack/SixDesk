rem This little script tar-balls the Sixtrack results in the current directory

rem BE CAREFUL!! IT RUNS IN THE CURRENT DIRECTORY!!
rem AND CREATES/DELETES MANY THINGS


setlocal

rem collect results
rem just in case the tarfile exists already
rem in which case tar asks for keyboard input!!
del sixres.*
del sixres.tar
rem No need to send back the executable
del sixtrack\sixtrack.exe

rem HAVE to tar THEN gzip on WINDOWS
gtar.exe -cvf sixres.tar sixtrack
gzip.exe sixres.tar
rem clean up a bit
del sixtrack\*?.*
rmdir sixtrack
endlocal
