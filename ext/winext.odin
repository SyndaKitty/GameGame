package ext

import win "core:sys/windows"

foreign import kernel32 "system:kernel32.lib"

@(default_calling_convention = "stdcall")
foreign kernel32 {
    GetLocalTime :: proc(lpSystemTime: ^win.SYSTEMTIME) ---
}