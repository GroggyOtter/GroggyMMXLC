; MMXLC Updater
#Requires AutoHotkey >=2.0
#Warn VarUnset, Off
for k, v in ["pid","dl","save"]
    %v% := A_Args[A_Index]
ProcessClose(pid)
While ProcessExist(pid)
    Sleep(1)
FileMove(dl, save, 1)
Run(A_AhkPath " " save)
