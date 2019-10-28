set LOBSTER_ROOT=E:/LOBSTER
set MONITORED_FOLDER=E:/LOBSTER_sandbox/Monitored
set ERROR_LOG=E:/LOBSTER_sandbox/Logs/Errorlog.txt

matlab.exe -r -nosplash "cd %LOBSTER_ROOT% ; init ; JULI('%MONITORED_FOLDER%','%ERROR_LOG%');"