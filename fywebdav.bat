@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title Rclone WebDAV 挂载工具
chcp 65001 > nul

rem ======================================
rem 常量和配置
rem ======================================
set "CACHE_DIR=D:\drfycloudtmp"
set "CONFIG_FILE=%~dp0rclone.conf"
set "LOG_FILE=%~dp0rclone_mount.log"
set "MOUNT_FLAG=%~dp0rclone_mounted.flag"
set "RCLONE_LOG=%~dp0rclone.log"
set "AUTOSTART_SCRIPT=%~dp0autostart.vbs"
set "STARTUP_SHORTCUT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\RcloneWebDAVMount.lnk"
set "DRIVE_LETTER=H:"

rem ======================================
rem 初始化检查
rem ======================================
rem 检查必要文件
if not exist "rclone.exe" (
    call :print_error "未找到 rclone.exe，请确保该文件与脚本在同一目录！"
    call :pause_and_exit 1
)

if not exist "%CONFIG_FILE%" (
    call :print_error "未找到 rclone.conf，请确保该文件与脚本在同一目录！"
    call :pause_and_exit 1
)

rem 创建临时目录
if not exist "%CACHE_DIR%" (
    mkdir "%CACHE_DIR%" 2>nul
    if errorlevel 1 (
        call :print_error "无法创建缓存目录 %CACHE_DIR%"
        call :print_info "请确保有足够的权限或手动创建该目录。"
        call :pause_and_exit 1
    )
)

rem 检查是否已经有实例在运行
tasklist /fi "imagename eq rclone.exe" 2>nul | find "rclone.exe" > nul
if !errorlevel! equ 0 (
    call :print_warning "检测到 rclone 进程已在运行"
    call :print_info "建议先使用选项 2 卸载现有的挂载"
    echo.
)

rem 检查是否有自启动参数
if "%~1"=="autostart" goto mount

rem ======================================
rem 主菜单
rem ======================================
:menu
cls
call :print_header "Rclone WebDAV 挂载工具"
call :print_line "1. 挂载 WebDAV 到 %DRIVE_LETTER% 盘"
call :print_line "2. 卸载 %DRIVE_LETTER% 盘"
call :print_line "3. 检查挂载状态"
call :print_line "4. 设置开机自启动"
call :print_line "5. 取消开机自启动"
call :print_line "6. 获取 rclone 的加密密码"
call :print_line "7. 退出"
call :print_line "================================================="
call :print_line

set choice=
set /p choice=请选择操作 (1-7): 

if "%choice%"=="1" goto mount
if "%choice%"=="2" goto unmount
if "%choice%"=="3" goto status
if "%choice%"=="4" goto autostart
if "%choice%"=="5" goto remove_autostart
if "%choice%"=="6" goto encrypt_password
if "%choice%"=="7" goto end

call :print_error "无效的选择，请重试..."
timeout /t 2 /nobreak > nul
goto menu

rem ======================================
rem 挂载功能
rem ======================================
:mount
call :print_info "正在挂载 WebDAV 到 %DRIVE_LETTER% 盘..."

rem 清理可能存在的旧文件
if exist "%~dp0rclone_mount_temp.bat" del /f /q "%~dp0rclone_mount_temp.bat" > nul 2>&1
if exist "%~dp0start_mount.vbs" del /f /q "%~dp0start_mount.vbs" > nul 2>&1

rem 创建标志文件表示挂载状态
echo.> "%MOUNT_FLAG%"

rem 创建临时批处理文件来启动挂载进程
(
    echo @echo off
    echo chcp 65001 ^> nul
    echo :start
    echo if not exist "%MOUNT_FLAG%" (
    echo     echo %%date%% %%time%% - 检测到卸载信号，停止挂载... ^>^> "%LOG_FILE%"
    echo     exit /b
    echo ^)
    echo echo %%date%% %%time%% - 开始挂载 rclone... ^>^> "%LOG_FILE%"
    echo rclone mount drfycloud:/ %DRIVE_LETTER% --config "%CONFIG_FILE%" --vfs-cache-mode full --cache-dir %CACHE_DIR% --use-mmap --dir-cache-time 1m --attr-timeout 1m  --buffer-size 4096M --vfs-read-chunk-size 128M --vfs-read-chunk-size-limit 2G --vfs-cache-max-size 10G --vfs-cache-max-age 12h --transfers 16 --checkers 16 --metadata  --no-check-certificate --log-file "%RCLONE_LOG%" --log-level INFO
    echo echo %%date%% %%time%% - 挂载断开，10秒后重新连接... ^>^> "%LOG_FILE%"
    echo timeout /t 10 /nobreak ^> nul
    echo goto start
) > "%~dp0rclone_mount_temp.bat"

rem 创建VBS脚本来启动挂载进程
(
    echo Set objShell = CreateObject^("WScript.Shell"^)
    echo objShell.Run "cmd /c ""%~dp0rclone_mount_temp.bat""", 0, False
    echo Set objShell = Nothing
) > "%~dp0start_mount.vbs"

rem 使用VBS脚本启动挂载进程
cscript //nologo "%~dp0start_mount.vbs"

rem 增加等待时间，确保挂载完成
call :print_info "等待挂载完成..."
timeout /t 5 /nobreak > nul

rem 检查rclone进程是否在运行
tasklist /fi "imagename eq rclone.exe" 2>nul | find "rclone.exe" > nul
if !errorlevel! neq 0 (
    call :print_error "rclone 进程未运行，挂载失败"
    goto mount_failed
)

rem 检查标志文件
if not exist "%MOUNT_FLAG%" (
    call :print_error "挂载标志文件不存在，挂载失败"
    goto mount_failed
)

rem 只要rclone进程在运行且标志文件存在，我们就认为挂载成功
call :print_success "rclone 进程正在运行，挂载成功！"
goto mount_success

:mount_failed
call :print_warning "挂载失败。请检查rclone配置和日志文件。"
rem 清理临时文件
if exist "%~dp0start_mount.vbs" del /f /q "%~dp0start_mount.vbs" > nul 2>&1
if exist "%~dp0rclone_mount_temp.bat" del /f /q "%~dp0rclone_mount_temp.bat" > nul 2>&1
call :pause_and_continue
goto menu

:mount_success
call :print_success "挂载成功！%DRIVE_LETTER% 盘已可用。"
rem 清理VBS脚本（保留批处理文件供进程使用）
if exist "%~dp0start_mount.vbs" del /f /q "%~dp0start_mount.vbs" > nul 2>&1

rem 刷新资源管理器
call :refresh_explorer
call :print_info "已刷新资源管理器，%DRIVE_LETTER%盘现在应该可见。"
call :pause_and_continue
goto menu

rem ======================================
rem 卸载功能
rem ======================================
:unmount
call :print_info "正在卸载 %DRIVE_LETTER% 盘..."

rem 首先删除标志文件，阻止rclone服务重启
if exist "%MOUNT_FLAG%" (
    call :print_info "移除挂载标志..."
    del /f /q "%MOUNT_FLAG%" > nul 2>&1
)

rem 删除临时文件
if exist "%~dp0start_mount.vbs" del /f /q "%~dp0start_mount.vbs" > nul 2>&1
if exist "%~dp0rclone_mount_temp.bat" del /f /q "%~dp0rclone_mount_temp.bat" > nul 2>&1

rem 通过PID查找并结束所有rclone进程
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq rclone.exe" /fo table /nh 2^>nul') do (
    call :print_info "终止 rclone 进程: %%a"
    taskkill /f /pid %%a > nul 2>&1
)
timeout /t 1 /nobreak > nul

rem 确认进程已结束
tasklist /fi "imagename eq rclone.exe" 2>nul | find "rclone.exe" > nul
if !errorlevel! equ 0 (
    call :print_info "正在强制结束所有 rclone 进程..."
    taskkill /f /im rclone.exe /t > nul 2>&1
    timeout /t 2 /nobreak > nul
)

rem 断开网络驱动器
call :print_info "正在断开 %DRIVE_LETTER% 驱动器..."
net use %DRIVE_LETTER% /delete /y > nul 2>&1

rem 查找并结束挂载进程
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq cmd.exe" /fo table /nh 2^>nul') do (
    wmic process where "ProcessId=%%a" get CommandLine 2^>nul | find "rclone_mount_temp.bat" > nul
    if !errorlevel! equ 0 (
        call :print_info "终止挂载进程: %%a"
        taskkill /f /pid %%a > nul 2>&1
    )
)

call :print_success "%DRIVE_LETTER% 盘已成功卸载"

rem 刷新资源管理器
call :refresh_explorer
call :print_info "已刷新资源管理器，%DRIVE_LETTER%盘现在应该已移除。"
call :pause_and_continue
goto menu

rem ======================================
rem 状态检查功能
rem ======================================
:status
call :print_info "正在检查挂载状态..."

rem 检查网络驱动器
rem 使用更可靠的方法检查H盘
if exist "%DRIVE_LETTER%\" (
    set drive_status=0
) else (
    set drive_status=1
)

rem 检查rclone进程
tasklist /fi "imagename eq rclone.exe" 2>nul | find "rclone.exe" > nul
set process_status=!errorlevel!

rem 检查实际访问
if !drive_status! equ 0 (
    dir %DRIVE_LETTER%\ /a /b > nul 2>&1
    set access_status=!errorlevel!
) else (
    set access_status=1
)

rem 检查标志文件
if exist "%MOUNT_FLAG%" (
    set flag_status=0
) else (
    set flag_status=1
)

rem 检查开机自启动设置
if exist "%STARTUP_SHORTCUT%" (
    set autostart_shortcut=0
) else (
    set autostart_shortcut=1
)

if exist "%AUTOSTART_SCRIPT%" (
    set autostart_script=0
) else (
    set autostart_script=1
)

rem 综合判断
call :print_header "挂载状态信息"
if !drive_status! equ 0 (
    if !access_status! equ 0 (
        call :print_success "%DRIVE_LETTER% 盘已成功挂载且可以访问"
    ) else (
        call :print_warning "%DRIVE_LETTER% 盘已挂载但无法访问内容"
    )
) else (
    call :print_error "%DRIVE_LETTER% 盘未挂载"
)

if !process_status! equ 0 (
    call :print_success "rclone 进程正在运行"
    call :print_info "进程详情:"
    tasklist /fi "imagename eq rclone.exe" | find "rclone.exe"
) else (
    call :print_error "rclone 进程未运行"
)

if !flag_status! equ 0 (
    call :print_success "挂载标志文件存在"
) else (
    call :print_error "挂载标志文件不存在"
)

call :print_header "开机自启动状态"
if !autostart_shortcut! equ 0 (
    if !autostart_script! equ 0 (
        call :print_success "已设置开机自启动"
        call :print_info "   - 快捷方式: %STARTUP_SHORTCUT%"
        call :print_info "   - 自启动脚本: %AUTOSTART_SCRIPT%"
    ) else (
        call :print_warning "开机自启动设置不完整"
        call :print_info "   - 快捷方式存在，但脚本文件缺失"
    )
) else (
    if !autostart_script! equ 0 (
        call :print_warning "开机自启动设置不完整"
        call :print_info "   - 脚本文件存在，但快捷方式缺失"
    ) else (
        call :print_error "未设置开机自启动"
    )
)

call :pause_and_continue
goto menu

rem ======================================
rem 设置开机自启动
rem ======================================
:autostart
call :print_info "正在设置开机自启动..."

rem 创建VBS脚本用于开机自启动
(
    echo Set objShell = CreateObject^("WScript.Shell"^)
    echo objShell.Run "cmd /c ""%~dp0fywebdav.bat"" autostart", 0, False
) > "%AUTOSTART_SCRIPT%"

rem 创建快捷方式指向VBS脚本
(
    echo Set oWS = WScript.CreateObject^("WScript.Shell"^)
    echo sLinkFile = "%STARTUP_SHORTCUT%"
    echo Set oLink = oWS.CreateShortcut^(sLinkFile^)
    echo oLink.TargetPath = "%AUTOSTART_SCRIPT%"
    echo oLink.WorkingDirectory = "%~dp0"
    echo oLink.Description = "Rclone WebDAV 挂载"
    echo oLink.WindowStyle = 7
    echo oLink.Save
) > "%TEMP%\CreateShortcut.vbs"

cscript //nologo "%TEMP%\CreateShortcut.vbs"
del "%TEMP%\CreateShortcut.vbs" > nul 2>&1

call :print_success "开机启动快捷方式创建成功！"
call :print_info "路径: %STARTUP_SHORTCUT%"
call :pause_and_continue
goto menu

rem ======================================
rem 取消开机自启动
rem ======================================
:remove_autostart
call :print_info "正在取消开机自启动..."

if exist "%STARTUP_SHORTCUT%" (
    del /f /q "%STARTUP_SHORTCUT%" > nul 2>&1
    call :print_success "已删除开机启动快捷方式"
) else (
    call :print_error "未找到开机启动快捷方式"
)

if exist "%AUTOSTART_SCRIPT%" (
    del /f /q "%AUTOSTART_SCRIPT%" > nul 2>&1
    call :print_success "已删除自启动脚本"
) else (
    call :print_error "未找到自启动脚本"
)

call :pause_and_continue
goto menu

rem ======================================
rem 密码加密功能
rem ======================================
:encrypt_password
cls
call :print_header "WebDAV 密码加密工具"
call :print_line "此工具将帮助您加密 WebDAV 密码"
call :print_line "以便在 rclone.conf 文件中使用。"
call :print_line ""
call :print_line "请在下方输入您的 WebDAV 密码："
call :print_line ""

rem 检查 rclone.exe 是否存在
if not exist "%~dp0rclone.exe" (
    call :print_error "在当前目录中未找到 rclone.exe！"
    call :print_error "请确保此脚本与 rclone.exe 在同一目录中"
    call :pause_and_continue
    goto menu
)

rem 获取密码输入
set /p "password=请输入密码: "

rem 加密密码
call :print_info "正在加密密码..."
echo.
call :print_success "您的加密密码是："
echo.
for /f "usebackq tokens=*" %%a in (`echo^|"%~dp0rclone.exe" obscure "%password%"`) do set encrypted=%%a
echo !encrypted!
echo.
call :print_info "您现在可以复制这个加密密码"
call :print_info "并将其粘贴到 rclone.conf 文件中"
call :print_info "在 'pass = ' 行之后。"
echo.
call :pause_and_continue
goto menu

rem ======================================
rem 程序退出
rem ======================================
:end
endlocal
call :print_info "感谢使用 Rclone WebDAV 挂载工具！"
call :pause_and_exit 0

rem ======================================
rem 工具函数 - 输出样式和辅助功能
rem ======================================
:print_line
if "%~1"=="" (
    echo.
) else (
    echo %~1
)
exit /b

:print_header
echo ================================================
echo              %~1
echo ================================================
exit /b

:print_success
echo [✓] %~1
exit /b

:print_error
echo [✗] %~1
exit /b

:print_warning
echo [!] %~1
exit /b

:print_info
echo [i] %~1
exit /b

:print_line_to_log
echo %date% %time% - %~1 >> "%LOG_FILE%"
exit /b

:pause_and_continue
pause
exit /b

:pause_and_exit
echo 按任意键退出...
pause > nul
exit /b %~1

rem ======================================
rem 刷新资源管理器视图
rem ======================================
:refresh_explorer
call :print_info "正在刷新资源管理器..."

rem 使用命令行直接打开H盘或计算机视图来强制刷新
if "%choice%"=="1" (
    rem 挂载后，直接打开H盘
    start explorer.exe %DRIVE_LETTER%\
) else if "%choice%"=="2" (
    rem 卸载后，打开计算机视图
    start explorer.exe ::{20D04FE0-3AEA-1069-A2D8-08002B30309D}
) else (
    rem 其他情况，只打开计算机视图
    start explorer.exe ::{20D04FE0-3AEA-1069-A2D8-08002B30309D}
)

exit /b 
