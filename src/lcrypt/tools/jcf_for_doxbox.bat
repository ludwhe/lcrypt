
rem echo "%~n1.log" > out.log

"C:\Apps\jcf\jcf.exe" -clarify -backup -y -config="P:\tools\JcfSettings_for_doxbox.cfg" -F %1 > "P:\tools\jcf_logs\%~n1.log"

