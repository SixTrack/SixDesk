rem This little script prepares a
rem Sixtrack test job 

rem BE CAREFUL!! IT RUNS IN THE CURRENT DIRECTORY!!
rem AND CREATES/DELETES MANY THINGS

setlocal
dir

mkdir sixtrack

move sixtrack.exe sixtrack\.

move fort.*  sixtrack

endlocal
