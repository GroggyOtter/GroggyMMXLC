*+Esc::ExitApp()
mmxlc.initialize()

class mmxlc
{
    #Requires AutoHotkey >=2.0
    static version := "1.1"
    
    ;static game_exe := "ahk_exe notepad.exe"
    static game_exe := "ahk_exe RXC1.exe"
    static title := "Groggy MMXLC"
    static default_save := "_default"
    
    static github_url := "https://raw.githubusercontent.com/GroggyOtter/GroggyMMXLC/main"
    static url_main => this.github_url "/src/GroggyMMXLC.ahk"
    static url_updater => this.github_url "/src/updater.ahk"
    
    static paths :=
        {main     :A_AppData "\GroggyMMXLC"
        ,download :A_AppData "\GroggyMMXLC\download"
        ,images   :A_AppData "\GroggyMMXLC\images"}
    static data_file => this.paths.main "\data.ini"
    static main_file => this.paths.main "\GroggyMMXLC.ahk"
    static updater_file => this.paths.download "\updater.ahk"
    static download_file => this.paths.download "\github.ahk"
    
    static pics :=
        {background  :{path :this.paths.images "\MMXLC BG.jpg"            ,url:this.github_url "/img/MMXLC%20BG.jpg"}
        ,launch      :{path :this.paths.images "\MMXLC Start Capsule.png" ,url:this.github_url "/img/MMXLC%20Start%20Capsule.png"}
        ,update_down :{path :this.paths.images "\MMXLC Update Down.png"   ,url:this.github_url "/img/MMXLC%20Update%20Down.png"}
        ,update_up   :{path :this.paths.images "\MMXLC Update Up.png"     ,url:this.github_url "/img/MMXLC%20Update%20Up.png"}
        ,exit        :{path :this.paths.images "\MMXLC Exit.png"          ,url:this.github_url "/img/MMXLC%20Exit.png"} }
    
    ; Start / Menu
    static control_obj :=
        {Up       :{name:"Up"              ,game_key:"Up"    ,user_key:"w"           ,col:0 ,row:0 }
        ,Down     :{name:"Down"            ,game_key:"Down"  ,user_key:"s"           ,col:0 ,row:1 }
        ,Left     :{name:"Left"            ,game_key:"Left"  ,user_key:"a"           ,col:0 ,row:2 }
        ,Right    :{name:"Right"           ,game_key:"Right" ,user_key:"d"           ,col:0 ,row:3 }
        ,Weapon   :{name:"Attack"          ,game_key:"z"     ,user_key:"Numpad4"     ,col:0 ,row:4 }
        ,Jump     :{name:"Jump"            ,game_key:"x"     ,user_key:"Numpad2"     ,col:0 ,row:5 }
        ,Dash     :{name:"Dash"            ,game_key:"a"     ,user_key:"Numpad6"     ,col:0 ,row:6 }
        ,Alt      :{name:"Alt Wep"         ,game_key:"s"     ,user_key:"Numpad8"     ,col:0 ,row:7 }
        ,WepLeft  :{name:"Weapon Left"     ,game_key:"c"     ,user_key:"Numpad7"     ,col:0 ,row:8 }
        ,WepRight :{name:"Weapon Right"    ,game_key:"d"     ,user_key:"Numpad9"     ,col:0 ,row:9 }
        ,Select   :{name:"Select"          ,game_key:"Esc"   ,user_key:"Numpad0"     ,col:0 ,row:10} 
        ,Start    :{name:"Menu/Start"      ,game_key:"Space" ,user_key:"NumpadEnter" ,col:0 ,row:11}
        ,Giga     :{name:"Giga (X4 Only)"  ,game_key:"v"     ,user_key:"Numpad5"     ,col:0 ,row:12} 
        ,Menu     :{name:"MMXLC Menu"      ,game_key:"Tab"   ,user_key:"Tab"         ,col:0 ,row:13} 
        ,_gui     :{name:"GUI Hide/Show"   ,game_key:"F1"    ,user_key:"F1"          ,col:0 ,row:14} }
    
    static modifier_map := Map("+","Shift"
                              ,"!","Alt"
                              ,"^","Control"
                              ,"#","LWin" )
    
    static update_available := 0
    
    ; === Methods() ===
    static initialize() {
        obm := ObjBindMethod(this, "on_exit")
        OnExit(obm)                             ; Cleanup on exit
        this.path_check()                       ; Ensure paths exist
        this.data_check()                       ; Initialize data/settings file
        this.image_check()                      ; Acquire images
        this.update_check()                     ; Check for possible update
        this.make_gui()                         ; Build gui
        this.make_hotkeys()                     ; Create hotkeys
        this.load_config()                      ; Load last used config
    }
    
    static load(section, key) {
        return IniRead(this.data_file, section, key, "")
    }
    
    static save(section, key, data) {
        IniWrite(data, this.data_file, section, key)
    }
    
    static path_check() {
        For k, path in this.paths.OwnProps()
            If !DirExist(path)
                DirCreate(path)
    }
    
    static data_check() {
        FileExist(this.data_file) ? 0
            : FileAppend("; " this.title " Data File", this.data_file)
    }
    
    static image_check() {
        for k, img in this.pics.OwnProps()
            if !FileExist(img.path)
                Download(img.url, img.path)    
    }
    
    static update_check() {
        this.update_available := 0
        this.delete_file(this.download_file)
        if !this.download(this.url_main, this.download_file)
            return
        if !FileExist(this.download_file)
            return
        txt := FileRead(this.download_file)
        if RegExMatch(txt, 'static version.*?(\d+.\d+)', &match)
            if this.is_new_version(match.1, this.version)
                this.update_available := 1
        this.delete_file(this.download_file)
    }
    
    ; Return false on download fail and suprresses errors
    static download(url, path) {
        try
            Download(url, path)
        catch
            Return 0
        Return 1
    }
    
    static run_update(*) {
        MsgBox("Starting update!")
        this.delete_file(this.updater_file)
        
        If !this.Download(this.url_main, this.download_file)        ; Get file
            Return MsgBox("Error downloading update.")
        If !this.download(this.url_updater, this.updater_file)      ; Get updater
            Return MsgBox("Error downloading updater file.")
        
        args := this.args(DllCall("GetCurrentProcessId")            ; Build args
            , this.download_file
            , this.main_file )
        
        If !FileExist(this.download_file)                           ; Verify updater exists
            return MsgBox("Could not run updater")
        
        Run(A_AhkPath " " this.updater_file " " args)               ; Run updater + args
        Sleep(1)
        ExitApp()                                                   ; Terminate script
    }
    
    ; Creates quoted and spaced args
    static args(arr*) {
        str := ""
        For k, v in arr
            str .= ' "' v '"'
        return str
    }
    
    static is_new_version(new, current) {
        n := StrSplit(new, ".")
        c := StrSplit(current, ".")
        
        Loop n.Length
            if (n[A_Index] > c[A_Index])
                return 1
        
        return 0
    }
    
    static make_gui() {
        col := row := 0
        this.get_col_row(&col, &row)
        
        ; Core
        margin      := 5
        margin2     := margin * 2
        spacer      := 2
        def_h       := 20
        btn_def_h   := 100
        btn_buff    := 80
        ; Hotkey
        hk_w        := 120
        hk_h        := def_h
        ; Text
        txt_w       := 120
        txt_h       := def_h
        ; Buttons
        btn_exit    := btn_def_h
        btn_up_w    := 100
        btn_up_h    := 50
        btn_st_w    := 60
        btn_st_h    := btn_def_h
        btn_w       := 80
        btn_h       := def_h
        
        ; Gui creation start
        gw  := (hk_w * 2 + txt_w) * col + (margin * col + margin)
        gh  := margin2 + (def_h + spacer) * row +  + btn_buff + btn_def_h
        opt := "+AlwaysOnTop -Caption +Border"
        goo := Gui(opt, this.title)
        goo.MarginX := margin
        goo.MarginY := margin
        goo.BackColor := 0x101010
        
        ; Background image
            goo.AddPicture("y0 x0 w" gw " h" gh, this.pics.background.path)
        
        ; Hotkey text headers
        action_w := hk_w * 2 + txt_w
        Loop col
        {
            ; User HK
            x := margin + (action_w + margin) * (col - 1)
            y := margin
            opt := this.make_whxy(hk_w, txt_h, x, y, "Border Center 0x207")
            con := goo.AddText(opt, "User Defined Key")
            con.SetFont("Bold s8 cFFFFFF")
            
            ; Action
            x += hk_w
            opt := this.make_whxy(txt_w, txt_h, x, y, "Border Center 0x207")
            con := goo.AddText(opt, "Action")
            con.SetFont("Bold s8 cFFFFFF")
            
            ; In-game HK
            x += txt_w
            opt := this.make_whxy(hk_w, txt_h, x, y, "Border Center 0x207")
            con := goo.AddText(opt, "In-Game Key")
            con.SetFont("Bold s8 cFFFFFF")
        }
        
        ; Generate hotkeys
        for k, v in this.control_obj.OwnProps()
        {
            ; Add user hotkey box
            x := margin + (v.col * (action_w + margin))
            y := margin + txt_h + (v.row * (hk_h + spacer))
            if (k = "_gui")
                y += hk_h
            opt := this.make_whxy(hk_w, hk_h, x, y, "0x200 Border")
            con := goo.AddHotkey(opt, v.user_key)
            con.SetFont("Bold")
            obm := ObjBindMethod(this, "update_hotkey", k)
            con.OnEvent("change", obm)
            
            ; Add action text
            x += hk_w
            w := txt_w
            h := txt_h
            opt := this.make_whxy(w, h, x, y, "Border 0x200 Center")
            con := goo.AddText(opt, " " v.name)
            con.SetFont("s10 cFFFFFF")
            
            ; Add in-game hotkey box
            x += txt_w
            opt := this.make_whxy(hk_w, hk_h, x, y, "0x200 Border Disabled")
            con := goo.AddHotkey(opt, v.game_key)
            con.SetFont("Bold")
        }
        
        ; Launch MMXLC btn
            y := gh - margin - btn_st_h
            opt := this.make_whxy(btn_st_w, btn_st_h, margin, y)
            con := goo.AddPicture(opt " Border", this.pics.launch.path)
            con := this.add_shadow_text(goo, con, "0x200 Center", "Launch", "bold s12")
            obm := ObjBindMethod(this, "launchmmx")
            con.OnEvent("Click", obm)
        
        ; Update button
            x := (gw/2 - btn_up_w/2)
            y := gh - margin - btn_up_h
            opt := this.make_whxy(btn_up_w, btn_up_h, x, y)
            con := goo.AddPicture(opt, this.pics.update_up.path)
            obm := ObjBindMethod(this, "run_update")
            con.OnEvent("Click", obm)
            con.name := "up"
            this.update_button := con
            this.update_button.visible := this.update_available
            ; if !this.update_available
            ;     con.Visible := 0
            
            ;obm := ObjBindMethod(this, "update")
            ;opt := "x" x " y" y " h" btn_h " w" btn_w
            ;btn_con := goo.AddButton(opt, "Hide Overlay")
            ;btn_con.OnEvent("Click", obm)
        
        ; Exit script
            y := gh - margin - btn_exit
            x := gw - margin - btn_st_w
            opt := "x" x " y" y " h" btn_exit " w" btn_st_w
            con := goo.AddPicture(opt " border", this.pics.exit.path)
            con := this.add_shadow_text(goo, con, "0x200 Center", "Exit", "bold s12")
            obm := ObjBindMethod(this, "quit")
            con.OnEvent("Click", obm)
        
        goo.Move(,,gw, gh)
        
        obm := ObjBindMethod(this, "save_gui_pos")
        goo.OnEvent("Close", obm)
        
        this.mmxlcgui := goo
        obm := ObjBindMethod(this, "WM_MOUSEMOVE")
        OnMessage(0x200, obm)
        this.load_gui_pos()
    }
    
    static add_shadow_text(gobj, con_in, extra_opt, txt, gf) {
        w := h := x := y := 0
        ,con_in.GetPos(&x, &y, &w, &h)
        ,opt := this.make_whxy(w, h, x, y)
        ,con := gobj.AddText(opt " " extra_opt " BackgroundTrans c000000", txt)
        ,con.SetFont(gf)
        ,x+=2, y+=2, w-=2, h-=2
        ,opt := this.make_whxy(w, h, x, y)
        ,con := gobj.AddText(opt " " extra_opt " BackgroundTrans cFFFFFF", txt)
        ,con.SetFont(gf)
        return con
    }
    
    static make_whxy(w, h, x, y, extra:="") {
        return "w" w " h" h " x" x " y" y " " extra
    }
    
    static load_config(name := "") {
        if (name = "")
            name := this.default_save
        
        data := this.load("saves", name)
        
        For k, v in StrSplit(data, "  ")
        {
            RegExMatch(v, "(.+?)->(.+)", &match)
            id := match.1
            this.control_obj.%id%.user_key := match.2
        }
    }
    
    static save_config(name:="") {
        (name = "") ? name := this.default_save : 0
        
        data := ""
        For k, v in this.control_obj.OwnProps()
            data .= (A_Index > 1 ? "  " : "") k "->" v.user_key
        
        this.save("saves", name, data)
        MsgBox("check ini file for save")
        ExitApp()
    }
    
    ; Prevents user from using the same key for 2 things
    static dupe_hotkey_prevent(new_key, new_id) {
        For id, v in this.control_obj.OwnProps()
            If (v.user_key = new_key)
                this.control_obj.%id%.user_key := this.control_obj.%new_id%.user_key
    }
    
    static single_modifier_check(key) {
        if this.modifier_map.has(key)
            return this.modifier_map[key]
        return key
    }
    
    static update_hotkey(id, hkcon, last) {
        MsgBox("id: " id "`nhkcon.value: " hkcon.value)
        key := this.single_modifier_check(hkcon.value)
        this.dupe_hotkey_prevent(key, id)
        this.hotkey_disable(this.control_obj.%id%.user_key, this.game_exe)
        this.hotkey_enable(key, this.game_exe)
    }
    
    static hotkey_disable(key, win:="") {
        HotIfWinactive(win)
        Hotkey("*" key, "Off")
        Hotkey("*" key " Up", "Off")
    }
    
    static hotkey_enable(key, win:="", up:=1) {
        HotIfWinactive(win)
        obm := ObjBindMethod(this, "remapper", key, "Down")
        Hotkey("*" key, obm, "On")
        If (up)
            obm := ObjBindMethod(this, "remapper", key, "Up")
            ,Hotkey("*" key " Up", obm, "On")
    }
    
    static make_hotkeys() {
        ; F1: Hide/show MMXLC GUI
            HotIf()
            obm := ObjBindMethod(this, "toggle_gui")
            Hotkey("$*F1", obm)
        
        ; Hide/show key remap window?
        
        ; Create game hotkeys
            For k, v in this.control_obj.OwnProps()
            {
                
                this.hotkey_enable(v.game_key, this.game_exe)
            }
        ; test key
        ; obm := ObjBindMethod(this, "test")
        ; Hotkey("$*F4", obm)
    }
    
    static get_col_row(&col, &row) {
        for k, v in this.control_obj.OwnProps()
             (v.col > col) ? col := v.col : 0
            ,(v.row > row) ? row := v.row : 0
        col++
        row++
    }
    
    static load_gui_pos() {
        w := h := 0
        ,x := this.load("gui", "x")
        ,y := this.load("gui", "y")
        ,!IsNumber(x) ? x := 0 : 0
        ,!IsNumber(y) ? y := 0 : 0
        ,this.mmxlcgui.GetPos(,, &w, &h)
        ,this.mmxlcgui.Show(this.make_whxy(w, h, x, y))
    }
    
    static save_gui_pos() {
        x := y := 0
        this.mmxlcgui.GetPos(&x, &y)
        this.save("gui", "x", x)
        this.save("gui", "y", y)
    }
    
    static WM_MOUSEMOVE(wparam, lparam, msg, hwnd) {
        static save_flag := 0
        ; Click+Drag functionality
        if (wparam = 1)
            PostMessage(0xA1, 2,,, "A") ; WM_NCLBUTTONDOWN
            ,save_flag := 1
        
        ; Save gui position
        if (wparam = 0 && save_flag = 1)
            this.save_gui_pos()
            ,save_flag := 0
        
        ; Update on-hover
        MouseGetPos(,,&win,&con)
        this.update_hover_switch(ControlGetHwnd(con, win))
        
        
        ;this.hover_check()
        
        ; Button highlighting
        ;con := 0
        ;MouseGetPos(,,,&con)
        ;if InStr(con, "static")
        ;    ToolTip("static")
        ;else ToolTip()
    }
    
    static update_hover_switch(con_hwnd) {
        If (this.update_button.name = "up")
        && (this.update_button.hwnd = con_hwnd)
            this.update_button.value := this.pics.update_down.path
            ,this.update_button.name := "down"
        Else If (this.update_button.name = "down")
        && (this.update_button.hwnd != con_hwnd)
            this.update_button.value := this.pics.update_up.path
            ,this.update_button.name := "up"
    }
    
    static toggle_gui(*) {
        WinExist("ahk_id " this.mmxlcgui.hwnd)
            ? this.guihide()
            : this.guishow()
    }
    static guishow(*) {
        this.mmxlcgui.Show()
    }
    static guihide(*) {
        this.mmxlcgui.Hide()
    }
    
    static launchmmx(*) {
        If !WinExist(this.game_exe)
            Run("steam://rungameid/743890")
        Else WinActivate(this.game_exe)
    }
    
    static quit(*) {
        If (MsgBox("Quit " this.title "?", "Confirm Exit", 0x40004) = "yes")
            this.save_config()
            ,ExitApp()
    }
    
    static delete_file(f) {
        While FileExist(f)
            FileDelete(f)
            ,Sleep(1)
    }
    
    static remapper(game_key, state, arr*) {
        SendInput("{" game_key " " state "}")
    }
    
    static on_exit(*) {
        
    }
    
    static test(*) {
        MsgBox("working")
    }
}


/* Controller Defaults

== Script Hotkeys
gui hide/show       F1
gui hide            Escape

== MMXLC
MMXLC Menu
change game type    x
quit game           tab
OK                  z
Back                a

== MMX1 MMX2 MMX3
up                  up arrow
down                down arrow
left                left arrow
right               right arrow
shot                x
jump                z
dash                a
weaponL             d
weaponR             c
Start / Menu        Space        

== MMX Challenge
up                  up arrow
down                down arrow
left                left arrow
right               right arrow
shot                x
jump (Menu Choose)  z
dash (Menu Cancel)  a
special Attack      s
weaponL             d
weaponR             c

== MMX4
up                  up arrow
down                down arrow
left                left arrow
right               right arrow
main weapon         x
jump (Menu Choose)  z
dash (Menu Cancel)  a
giga                v
Alt weapon          s
weaponL             c
weaponR             d
Start / Menu
*/

/*
Mega Man X Legacy Collection / ROCKMAN X ANNIVERSARY COLLECTION
ahk_class Mega Man X Legacy Collection / ROCKMAN X ANNIVERSARY COLLECTION
ahk_exe RXC1.exe
*/



; Controls
; Only A, S, D, F, Z, X, C, and V can be remapped
; I, J, K, L and the Arrow keys are bound to movement
; Space to pause
; Esc functions as Select for X1-X4
; Tab opens the game menu



/*
ini settings that change based on in game changes
[DISPLAY]
Resolution=2560x1440
FullScreen=OFF
Borderless=OFF
VSYNC=ON
*/
