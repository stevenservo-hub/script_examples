:: The purpose of this script is to issue reboot of HDHR & retrieve status and tuner information. Steven Spring
@echo off
:: Clears the value of %HDHRIP%. The quotes are to prevent extra spaces from sneaking onto the end
set "HDHRIP="
:: Sets variable HDHRIP to what the user inputs.
:choice
set /p HDHRIP=What is the IP of the HD Homerun? 
:: Displays what is happening
echo Rebooting HD Homerun located at %HDHRIP%
:: Run Program
cd c:\"Program Files"\Silicondust\HDHomeRun
hdhomerun_config %HDHRIP% set /sys/restart self
:: End
:end
echo %HDHRIP% Rebooting
:choice
set /p c=Would you like to continue to Diagnostics? Press [Y] to continue [N] to exit or any other key to start over: 
if /I "%c%" EQU "Y" goto :diag
if /I "%c%" EQU "N" goto :exit
goto :choice
::Exit prompt
:exit
exit
::moving forward
:diag 
echo Starting. . .
::adding sleep to allow for hdhr to reboot before debug
CALL :sleep 5
:: Check status of hdhr
echo Pulling debug info for HDHR Located @ %HDHRIP% 
::adding sleep to allow for hdhr to reboot before debug
Echo Establishing connection
:: loop until HDHR is reachable
:Loop
ping -n 1 %HDHRIP% | find "TTL="
if not %errorlevel% equ 0 goto :Loop
echo Connection established
:: Running Debug
hdhomerun_config %HDHRIP% get /sys/debug
:end
:: Running tuner scripts
echo One moment, waiting for signal lock. . .
:: added thirty second sleep to allow for tuner to reestablish lock
CALL :sleep 60
echo Fetching tuner0 statistics
hdhomerun_config %HDHRIP% get /tuner0/status
:end
hdhomerun_config %HDHRIP% get /tuner0/streaminfo
:end
echo Fetching tuner1 statistics
hdhomerun_config %HDHRIP% get /tuner1/status
:end
hdhomerun_config %HDHRIP% get /tuner1/streaminfo
:end
 ::Prompt for exit
echo Press any key to exit . . .
:end
pause>nul
::ping sleep to act delay
:sleep
ping 127.0.0.1 -n 2 -w 1000 > NUL
ping 127.0.0.1 -n %1 -w 1000 > NUL
