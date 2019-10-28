set LOBSTER_ROOT=E:/LOBSTER
set MONITORED_FOLDER=E:/LOBSTER_sandbox/Monitored
set ERROR_LOG=E:/LOBSTER_sandbox/Logs/Errorlog.txt
set EMAIL=costneubias@gmail.com
set PASSWORD=lK45TGh_vSD564FV_d

matlab.exe -r -nosplash "cd %LOBSTER_ROOT% ; init ; JULI('%MONITORED_FOLDER%','%ERROR_LOG%','%EMAIL%','%PASSWORD%');"