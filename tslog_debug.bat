
@echo off
@CLS
@ECHO.
@chcp 936 >nul
@ECHO =========================
@ECHO ThinkStation 日志收集工具
@ECHO =========================
@ECHO 本工具所收集信息仅限故障诊断使用，并不涉及您的个人隐私，请放心使用！


@:init
@setlocal DisableDelayedExpansion
@set "batchPath=%~0"
@for %%k in (%0) do set batchName=%%~nk
@set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
@setlocal EnableDelayedExpansion

@:checkPrivileges
@NET FILE 1>NUL 2>NUL
@if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

@:getPrivileges
@if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
@ECHO.
@ECHO **************************************
@ECHO 获取Administrator权限中，请点击同意！
@ECHO **************************************

@ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
@ECHO args = "ELEV " >> "%vbsGetPrivileges%"
@ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
@ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
@ECHO Next >> "%vbsGetPrivileges%"
@ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
@"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
@exit /B

@:gotPrivileges
@setlocal & pushd .
@cd /d %~dp0
@if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

@::::::::::::::::::::::::::::
@::START
@::::::::::::::::::::::::::::
@mkdir "%cd%"\tslog
@set workpath="%cd%"\tslog
@set toolpath="%cd%"\tools
@echo 收集软件列表中，请耐心等待！
@wmic product get name,version >%workpath%\SoftwareList.txt
@echo 收集BIOS信息中，请耐心等待！
%cd%\tools\AMIDEWINx64.exe>nul 2>nul /DUMPALL %cd%\tslog\AMI_BIOS_DUMP.txt
%cd%\tools\AMIDEWINx64.exe>nul 2>nul /DMS %cd%\tslog\DMS.txt
%cd%\tools\bios\CFGWIN_x64.exe>nul 2>nul /c /path:%workpath%\bios_settings.txt
%cd%\tools\bios\SRWINx64.exe>nul 2>nul /b %workpath%\bios_settings_raw.txt
@echo 导出SIO日志中，请耐心等待！
@cd %toolpath%
@.\HwDiagWin.exe /dumplog  >>%workpath%\SIO_Events.log
@cd ..
@echo 收集操作系统信息中，请耐心等待！
@systeminfo >%workpath%\Systeminfo.txt
@echo 收集操作系统电源设置中，请耐心等待！
@powercfg /L >%workpath%\powercfg.txt
@powercfg /Q >>%workpath%\powercfg.txt
@echo 收集操作系统日志中，请耐心等待！
@mkdir %cd%\tslog\oslog
xcopy %SystemRoot%\System32\winevt\Logs\* %workpath%\oslog /E/C
@echo 收集操作系统DUMP文件中，请耐心等待！
@mkdir %cd%\tslog\osdump
copy %SystemRoot%\MEMORY.DMP %workpath%\osdump
xcopy %SystemRoot%\Minidump\* %workpath%\osdump /E/C
@echo 收集操作系统进程中，请耐心等待！
@tasklist /V >%workpath%\Tasklist.txt
@echo 收集磁盘分区信息中，请耐心等待！
@wmic DISKDRIVE get model^,interfacetype^,size^,totalsectors^,partitions /value >%workpath%\Partitions.txt
@echo 收集硬件信息中，请耐心等待！
@%cd%\tools\Devcon.exe findall * >%workpath%\Devicesinfo.txt
@echo 收集阵列信息中，请耐心等待！
@%cd%\tools\IntelVROCCli.exe -V >%workpath%\Intel_RAID_Info_VROC.txt
@%cd%\tools\IntelVROCCli.exe -I >>%workpath%\Intel_RAID_Info_VROC.txt
@%cd%\tools\rstcli64.exe -V >%workpath%\Intel_RAID_Info_RSTe.txt
@%cd%\tools\rstcli64.exe -I >>%workpath%\Intel_RAID_Info_RSTe.txt
@%cd%\tools\storcli64.exe /call/eall/sall show all >%workpath%\BCM_RAID_Info.txt
@%cd%\tools\storcli64.exe /call show events file=%workpath%\BCM_RAID_EVENT.txt
@%cd%\tools\storcli64.exe  /call show termlog >>%workpath%\BCM_termlog.txt
@echo 收集硬盘S.M.A.R.T信息中，请耐心等待！
@%cd%\tools\smartctl.exe --scan >%cd%\tools\SMART.txt
@for /f  "tokens=1-3" %%i in (%cd%\tools\SMART.txt) do %cd%\tools\smartctl.exe -a %%i >>%workpath%\SMARTINFO.txt
@echo 收集NVIDIA显卡信息中，请耐心等待！
@%cd%\tools\nvidia-smi.exe  >%workpath%\NVIDIA_INFO.txt
@%cd%\tools\nvidia-smi.exe -a  >>%workpath%\NVIDIA_INFO.txt
@%cd%\tools\nvdebugdump.exe -D
@copy %cd%\dump.zip %workpath%\NVIDIA_dump.zip
@echo 收集DriextX诊断信息中，请耐心等待！
@dxdiag /t %workpath%\dxdiag.txt
@echo 日志打包中，请耐心等待！
@set date_str=%date:~,4%%date:~5,2%%date:~8,2%
@set time_str=%time:~,2%%time:~3,2%%time:~6,2%
@set name=%date_str%%time_str%
%cd%\tools\7-Zip\7z.exe a %cd%\%name%.7z %workpath%\
@rd /S/Q "%workpath%"
@rd /S/Q "%cd%\tools"
@del %cd%\dump.zip
@del %0