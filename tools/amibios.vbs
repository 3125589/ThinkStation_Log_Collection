set wshell=createobject("wscript.shell")
currentpath = createobject("Scripting.FileSystemObject").GetFolder(".").Path
Set Ws=CreateObject("Wscript.Shell")
Clipboard="MsHta vbscript:ClipBoardData.setData(""Text"","""&"cd%/tools/AMIDUMP.BAT"&""")(Window.Close)"
Ws.Run(Clipboard)
wshell.run "cmd.exe",1
wscript.sleep 1000
wshell.sendkeys "{%}"
wshell.sendkeys "^v"
wshell.sendkeys "{enter}"
wshell.sendkeys "{enter}"
wshell.sendkeys "{enter}"
wshell.sendkeys "{enter}"
wscript.sleep 1000
wshell.sendkeys "exit"
wshell.sendkeys "{enter}"
wshell.sendkeys "{enter}"