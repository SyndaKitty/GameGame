package log

import "core:time"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:thread"
import "core:sync"

import win "core:sys/windows"
import win32 "core:sys/win32"
import "../ext"

@private
log_console_fields :: struct {
    flag: bool,
}
log_console: log_console_fields


@private
log_file_fields :: struct {
    flag: bool,
    handle: os.Handle,
    buffer: strings.Builder,
    // TODO: This doesn't need to be a separate thread.. we can just batch writes together
    thread: ^thread.Thread,
    mutex: sync.Mutex,
}
log_file: log_file_fields


should_log_to_console :: proc(flag: bool) {
    log_console.flag = flag
}


should_log_to_file :: proc(flag: bool) {
    log_file.flag = flag
    if flag {
        if log_file.handle == 0 {
            _create_log_file()
        }
        if log_file.thread == nil {
            log_file.buffer = strings.make_builder(0, 1024)
            log_file.thread = thread.create_and_start(_file_writer_worker)
            sync.mutex_init(&log_file.mutex)
        }
    }
    else if log_file.thread != nil {
        thread.join(log_file.thread)
        log_file.thread = nil
        strings.destroy_builder(&log_file.buffer)
        sync.mutex_destroy(&log_file.mutex)
    }
}


write :: proc(args: ..any, sep := " ") {
    if !log_file.flag && !log_console.flag { return }
    _write_formatted(_format_message(args=args, sep=sep))
}


write_to_file :: proc(buffer: strings.Builder) {
    if log_file.handle == 0 {
        _create_log_file()
    }
    
    sync.mutex_lock(&log_file.mutex)
    
    _, err := os.write_string(log_file.handle, strings.to_string(buffer))
    if err != os.ERROR_NONE {
        should_log_to_file(false)
        write("Failure to write string to file, disabling log to file")
    }
    err = os.flush(log_file.handle)
    if err != os.ERROR_NONE {
        should_log_to_file(false)
        write("Failure to flush string to file, disabling log to file")
    }
    strings.reset_builder(&log_file.buffer)

    sync.mutex_unlock(&log_file.mutex)
}


@private
WRITE_FREQUENCY:: 10
_file_writer_worker :: proc(thread: ^thread.Thread) {
    for {
        write_to_file(log_file.buffer)
        time.sleep(time.Millisecond * WRITE_FREQUENCY)
    }
}


@private
_write_formatted :: proc(message: string) {
    if log_file.flag {
        sync.mutex_lock(&log_file.mutex)
        fmt.sbprint(&log_file.buffer, message)
        sync.mutex_unlock(&log_file.mutex)
    }
    if log_console.flag {
        fmt.print(message)
    }
}


@private
_create_log_file :: proc() {
    temp_log := strings.make_builder(0, 512, context.temp_allocator)

    FILE_PATH_MAX :: 300
    data: [FILE_PATH_MAX]byte
    
    file_path: string
    
    res := win32.get_module_file_name_a(cast(win32.Hmodule)nil, transmute(cstring)&data, FILE_PATH_MAX)

    if win.GetLastError() != 0 {
        fmt.sbprint(&temp_log, _format_message("Unable to locate exe, falling back to current directory"))
        file_path = string(os.get_current_directory())
    }
    else {
        file_path = string(data[:])
        file_path = file_path[:strings.last_index(file_path, "\\")]
    }

    file_path = fmt.tprintf("%s\\log.txt", file_path)
    
    err: os.Errno
    log_file.handle,err = os.open(file_path, os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    if err != 0 {
        should_log_to_file(false)
        fmt.sbprint(&temp_log, _format_message("Unable to create log file at", file_path, ", disabling log to file"))
        fmt.print(strings.to_string(temp_log))
        return
    }
    fmt.sbprint(&temp_log, _format_message("Logging to", file_path))
    fmt.print(strings.to_string(temp_log))
}


@private
_format_message :: proc(args: ..any, sep := " ") -> string {
    t: win.SYSTEMTIME
    ext.GetLocalTime(&t)
    
    message := fmt.tprint(args=args, sep=sep)
    line := fmt.tprintf("%2d:%2d:%2d.%3d: %s\n", t.hour, t.minute, t.second, t.milliseconds, message)

    return line
}