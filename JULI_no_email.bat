set MONITORED_FOLDER=E:/LOBSTER_sandbox/Monitored
set ERROR_LOG=E:/LOBSTER_sandbox/Logs/Errorlog.txt

"matlab.exe" -nodisplay -nosplash - nodesktop -r "cd('%~dp0');init;JULI('%MONITORED_FOLDER%','%ERROR_LOG%');"