set CB_BIN=%~dp0
set CB_ROOT=%CB_BIN%..
set CB_ERTS=%CB_ROOT%\erts-<ERLANG_VER>\bin

cmd /q /c "%CB_BIN%service_stop.bat"

cmd /q /c "%CB_BIN%service_unregister.bat"

cmd /q /c "%CB_BIN%service_register.bat"

cmd /q /c "%CB_BIN%service_start.bat"

