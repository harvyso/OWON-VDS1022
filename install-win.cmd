@echo off
setlocal

pushd "%~dp0"

set ENVPATH=%PATH%
set PATH=%SYSTEMROOT%\System32
set ARCH=%PROCESSOR_ARCHITECTURE%

set PK_ID=OwonVdsTiny
set PK_NAME=OWON VDS1022 Oscilloscope
set PK_PUBLISHER=Fujian Lilliput Optoelectronics Technology Co.,Ltd
set PK_HOMEPAGE=https://github.com/florentbr/Owon-VDS1022
set PK_HELPLINK=https://owon.com.hk
set /p PK_VERSION=<".\version.txt"

reg query "HKU\S-1-5-19\Environment" >nul 2>nul || goto :err_permissions
if not exist ".\lib\win\%ARCH%\" goto :err_architecture
if not exist "%APPDATA%" goto :err_env_appdata


echo Check driver ...
find /c /i "{eb781aaf-9c70-4523-a5df-642a87eca567}" "%SYSTEMROOT%\INF\oem*.inf" >nul 2>nul || (
  echo Install driver ...
  pnputil >nul || goto :err_driver
  pnputil /add-driver ".\lib\win\usb_device.inf" /install >nul
  pnputil /enum-drivers | find /i "{eb781aaf-9c70-4523-a5df-642a87eca567}" >nul || goto :err_driver
)


echo Get Java from JAVA_HOME ...
if exist "%JAVA_HOME%\bin\javaw.exe" goto :end_locate_java

echo Locate Java in PATH ...
for %%I in ("javaw.exe") do for %%J in ("%%~dp$ENVPATH:I..") do set "JAVA_HOME=%%~fJ"
if not exist "%JAVA_HOME%\bin\javaw.exe" goto :err_java

echo Add missing environment variable JAVA_HOME ...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "JAVA_HOME" /t "REG_SZ" /d "%JAVA_HOME%" >nul
setx /m "JAVA_HOME" "%JAVA_HOME%" >nul 2>nul

:end_locate_java

if /i [%ARCH%] EQU [AMD64] "%JAVA_HOME%\bin\java.exe" -d64 -version >nul 2>nul || (
	echo Switch to 32 bits install ...
	"%SYSTEMROOT%\SysWOW64\cmd.exe" /c "%0"
	exit /b %errorlevel%
)


echo Install Microsoft C Runtime Library dependency ...
xcopy ".\lib\win\%ARCH%\msv*100.dll" "%SYSTEMROOT%\System32\" /d /y /c >nul 2>nul


echo Install program files ...
rmdir "%PROGRAMFILES%\%PK_ID%" /s /q >nul 2>nul
xcopy ".\doc\*"                "%PROGRAMFILES%\%PK_ID%\doc\"        /y /e >nul || goto :err_file
xcopy ".\fwr\*.bin"            "%PROGRAMFILES%\%PK_ID%\fwr\"        /y /e >nul || goto :err_file
xcopy ".\jar\*.jar"            "%PROGRAMFILES%\%PK_ID%\jar\"        /y /e >nul || goto :err_file
xcopy ".\lib\win\%ARCH%\*.dll" "%PROGRAMFILES%\%PK_ID%\lib\"        /y /e >nul || goto :err_file
copy  ".\version.txt"          "%PROGRAMFILES%\%PK_ID%\version.txt" /y    >nul || goto :err_file
copy  ".\ico\icon48.ico"       "%PROGRAMFILES%\%PK_ID%\icon.ico"    /y    >nul || goto :err_file


echo Clear settings ...
del /s /q "%APPDATA%\%PK_ID%\preferences*" >nul 2>nul


echo Create uninstall and menu shortcut ...

for /r "%PROGRAMFILES%\%PK_ID%" %%I in (*) do set /a PK_APP_SIZE+=%%~zI/1024

( echo [Version]
  echo Signature="$Windows NT$"
  echo AdvancedINF=2.5
  echo.
  echo [DefaultInstall]
  echo AddReg = AddReg
  echo ProfileItems = AddMenu
  echo.
  echo [AddReg]
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "ProductID"       , , "%PK_ID%"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "DisplayName"     , , "%PK_NAME% (x%ARCH:~-2%)"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "DisplayIcon"     , , "%%16422%%\%PK_ID%\icon.ico"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "DisplayVersion"  , , "%PK_VERSION%"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "InstallLocation" , , "%%16422%%\%PK_ID%"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "UninstallString" , , "rundll32 advpack.dll,LaunchINFSection ""%%16422%%\%PK_ID%\setup.inf"",UnInstall,3"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "Publisher"       , , "%PK_PUBLISHER%"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "HelpLink"        , , "%PK_HELPLINK%"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "URLInfoAbout"    , , "%PK_HOMEPAGE%"
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "EstimatedSize"   , 0x00010001, %PK_APP_SIZE%
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "NoModify"        , 0x00010001, 1
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%", "NoRepair"        , 0x00010001, 1
  echo.
  echo [AddMenu]
  echo Name = "%PK_NAME%"
  echo CmdLine = -1, "%%JAVA_HOME%%\bin", "javaw.exe -Djava.library.path=""%%16422%%\%PK_ID%\lib"" -Duser.dir=""%%APPDATA%%\%PK_ID%"" -cp ""%%16422%%\%PK_ID%\jar\*"" com.owon.vds.tiny.Main"
  echo IconPath = 16422, "%PK_ID%", "icon.ico"
  echo WorkingDir = 16422, "%PK_ID%"
  echo.
  echo [Uninstall]
  echo DelReg = DelReg
  echo ProfileItems = DelMenu
  echo RunPostSetupCommands = DelDirs
  echo.
  echo [DelReg]
  echo HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%PK_ID%"
  echo.
  echo [DelMenu]
  echo Name="%PK_NAME%", 2
  echo.
  echo [DelDirs]
  echo rundll32 advpack.dll,DelNodeRunDLL32 "%%16422%%\%PK_ID%" ; PROGRAMFILES
  echo rundll32 advpack.dll,DelNodeRunDLL32 "%%16410%%\%PK_ID%" ; APPDATA
  echo.
) > "%PROGRAMFILES%\%PK_ID%\setup.inf"

rundll32 advpack.dll,LaunchINFSection "%PROGRAMFILES%\%PK_ID%\setup.inf",DefaultInstall,3 || goto :err_register


echo Done !
pause & exit /b


:err_permissions
1>&2 echo Error: This script requires elevated privileges.
1>&2 echo   Right click on the file and select Run as administrator,
1>&2 echo   or run this script from an admin command prompt.
pause & exit /b 1

:err_architecture
1>&2 echo Error: Architecture "%ARCH%" not supported.
pause & exit /b 1

:err_env_appdata
1>&2 echo Error: Environement variable "APPDATA" is either not set or invalid.
pause & exit /b 1

:err_java
1>&2 echo Error: Java Runtime not found.
1>&2 echo   Environement variable "JAVA_HOME" is not set or invalid and "PATH" doesn't point to `java.exe` .
1>&2 echo   To install, visit  adoptopenjdk.net  or  java.com
pause & exit /b 1

:err_driver
1>&2 echo Error: Failed to install the driver.
1>&2 echo   Try to install the driver manually via device manager
1>&2 echo   Driver location: %CD%\lib\win
start "" /b devmgmt.msc
pause & exit /b 1

:err_file
1>&2 echo Error: Failed to copy to program files.
pause & exit /b 1

:err_register
1>&2 echo Error: Failed to create uninstall and menu shortcut.
pause & exit /b 1
