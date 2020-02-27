set MONITORED_FOLDER=E:/LOBSTER_sandbox/Monitored
set ERROR_LOG=E:/LOBSTER_sandbox/Logs/Errorlog.txt
set EMAIL=your@email.com
set PASSWORD=youremailpassword

"matlab.exe" -nosplash -r "cd('%~dp0');init;JULI('%MONITORED_FOLDER%','%ERROR_LOG%','%EMAIL%','%PASSWORD%');"