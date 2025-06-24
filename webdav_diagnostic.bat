@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title WebDAV 连接诊断工具
chcp 65001 > nul

rem ======================================
rem 配置和常量
rem ======================================
set "CONFIG_FILE=%~dp0rclone.conf"
set "DIAGNOSTIC_LOG=%~dp0diagnostic.log"

rem ======================================
rem 诊断主函数
rem ======================================
echo ================================================
echo               WebDAV 连接诊断工具
echo ================================================
echo 开始诊断时间: %date% %time%
echo ================================================

rem 清空之前的诊断日志
echo %date% %time% - 开始WebDAV连接诊断 > "%DIAGNOSTIC_LOG%"

rem 1. 检查必要文件
call :check_files

rem 2. 读取配置信息
call :read_config

rem 3. 测试网络连接
call :test_network

rem 4. 测试rclone连接
call :test_rclone_connection

rem 5. 输出诊断结果
call :show_results

echo.
echo 诊断完成！详细日志保存在: %DIAGNOSTIC_LOG%
pause
goto :EOF

rem ======================================
rem 检查必要文件
rem ======================================
:check_files
echo [检查] 验证必要文件...
echo %date% %time% - 开始检查必要文件 >> "%DIAGNOSTIC_LOG%"

if exist "rclone.exe" (
    echo [✓] rclone.exe 存在
    echo %date% %time% - rclone.exe 存在 >> "%DIAGNOSTIC_LOG%"
) else (
    echo [✗] rclone.exe 不存在
    echo %date% %time% - 错误: rclone.exe 不存在 >> "%DIAGNOSTIC_LOG%"
    set "file_error=1"
)

if exist "%CONFIG_FILE%" (
    echo [✓] rclone.conf 存在
    echo %date% %time% - rclone.conf 存在 >> "%DIAGNOSTIC_LOG%"
) else (
    echo [✗] rclone.conf 不存在
    echo %date% %time% - 错误: rclone.conf 不存在 >> "%DIAGNOSTIC_LOG%"
    set "file_error=1"
)

if defined file_error (
    echo [✗] 必要文件缺失，无法继续诊断
    echo %date% %time% - 诊断中断: 必要文件缺失 >> "%DIAGNOSTIC_LOG%"
    pause
    exit /b 1
)
exit /b

rem ======================================
rem 读取配置信息
rem ======================================
:read_config
echo [检查] 读取配置信息...
echo %date% %time% - 开始读取配置信息 >> "%DIAGNOSTIC_LOG%"

rem 从配置文件中提取URL
for /f "tokens=2 delims== " %%a in ('findstr "^url" "%CONFIG_FILE%" 2^>nul') do (
    set "webdav_url=%%a"
    set "webdav_url=!webdav_url: =!"
)

rem 从配置文件中提取用户名
for /f "tokens=2 delims== " %%a in ('findstr "^user" "%CONFIG_FILE%" 2^>nul') do (
    set "webdav_user=%%a"
    set "webdav_user=!webdav_user: =!"
)

if defined webdav_url (
    echo [✓] 找到WebDAV地址: !webdav_url!
    echo %date% %time% - WebDAV地址: !webdav_url! >> "%DIAGNOSTIC_LOG%"
) else (
    echo [✗] 未找到WebDAV地址配置
    echo %date% %time% - 错误: 未找到WebDAV地址配置 >> "%DIAGNOSTIC_LOG%"
    set "config_error=1"
)

if defined webdav_user (
    echo [✓] 找到用户名: !webdav_user!
    echo %date% %time% - 用户名: !webdav_user! >> "%DIAGNOSTIC_LOG%"
) else (
    echo [✗] 未找到用户名配置
    echo %date% %time% - 错误: 未找到用户名配置 >> "%DIAGNOSTIC_LOG%"
    set "config_error=1"
)
exit /b

rem ======================================
rem 测试网络连接
rem ======================================
:test_network
echo [测试] 网络连接测试...
echo %date% %time% - 开始网络连接测试 >> "%DIAGNOSTIC_LOG%"

if not defined webdav_url (
    echo [✗] 无法进行网络测试：WebDAV地址未配置
    echo %date% %time% - 跳过网络测试: WebDAV地址未配置 >> "%DIAGNOSTIC_LOG%"
    exit /b
)

rem 提取主机名进行ping测试
for /f "tokens=3 delims=/" %%a in ("!webdav_url!") do set "hostname=%%a"

echo [测试] Ping 主机: !hostname!
ping -n 2 "!hostname!" > nul 2>&1
if !errorlevel! equ 0 (
    echo [✓] 主机 !hostname! 可达
    echo %date% %time% - 主机可达: !hostname! >> "%DIAGNOSTIC_LOG%"
) else (
    echo [✗] 主机 !hostname! 不可达
    echo %date% %time% - 主机不可达: !hostname! >> "%DIAGNOSTIC_LOG%"
    set "network_error=1"
)

rem 使用PowerShell测试HTTPS连接
echo [测试] HTTPS连接测试...
powershell -Command "try { $response = Invoke-WebRequest -Uri '!webdav_url!' -Method OPTIONS -TimeoutSec 10 -ErrorAction Stop; Write-Output 'SUCCESS' } catch { Write-Output 'FAILED' }" > temp_result.txt 2>&1

for /f %%a in (temp_result.txt) do set "https_result=%%a"
del temp_result.txt > nul 2>&1

if "!https_result!"=="SUCCESS" (
    echo [✓] HTTPS连接成功
    echo %date% %time% - HTTPS连接成功 >> "%DIAGNOSTIC_LOG%"
) else (
    echo [✗] HTTPS连接失败
    echo %date% %time% - HTTPS连接失败 >> "%DIAGNOSTIC_LOG%"
    set "https_error=1"
)
exit /b

rem ======================================
rem 测试rclone连接
rem ======================================
:test_rclone_connection
echo [测试] rclone 连接测试...
echo %date% %time% - 开始rclone连接测试 >> "%DIAGNOSTIC_LOG%"

rem 测试rclone版本
echo [测试] 检查rclone版本...
rclone version > temp_version.txt 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=2" %%a in ('findstr "rclone v" temp_version.txt') do (
        echo [✓] rclone版本: %%a
        echo %date% %time% - rclone版本: %%a >> "%DIAGNOSTIC_LOG%"
    )
) else (
    echo [✗] 无法获取rclone版本
    echo %date% %time% - 错误: 无法获取rclone版本 >> "%DIAGNOSTIC_LOG%"
)
del temp_version.txt > nul 2>&1

rem 测试配置文件语法
echo [测试] 验证配置文件语法...
rclone config show drfycloud > temp_config.txt 2>&1
if !errorlevel! equ 0 (
    echo [✓] 配置文件语法正确
    echo %date% %time% - 配置文件语法正确 >> "%DIAGNOSTIC_LOG%"
) else (
    echo [✗] 配置文件语法错误
    echo %date% %time% - 配置文件语法错误 >> "%DIAGNOSTIC_LOG%"
    set "syntax_error=1"
)
del temp_config.txt > nul 2>&1

rem 测试WebDAV连接
echo [测试] WebDAV认证测试...
echo %date% %time% - 开始WebDAV认证测试 >> "%DIAGNOSTIC_LOG%"

rclone --config "%CONFIG_FILE%" --no-check-certificate ls drfycloud: --max-depth 1 > temp_ls.txt 2>&1
set "rclone_exit_code=!errorlevel!"

if !rclone_exit_code! equ 0 (
    echo [✓] WebDAV连接成功
    echo %date% %time% - WebDAV连接成功 >> "%DIAGNOSTIC_LOG%"
    type temp_ls.txt | head -5
) else (
    echo [✗] WebDAV连接失败
    echo %date% %time% - WebDAV连接失败，退出代码: !rclone_exit_code! >> "%DIAGNOSTIC_LOG%"
    echo [错误详情]:
    type temp_ls.txt
    echo %date% %time% - 错误详情: >> "%DIAGNOSTIC_LOG%"
    type temp_ls.txt >> "%DIAGNOSTIC_LOG%"
    set "webdav_error=1"
)
del temp_ls.txt > nul 2>&1
exit /b

rem ======================================
rem 显示诊断结果
rem ======================================
:show_results
echo ================================================
echo                  诊断结果汇总
echo ================================================

if not defined file_error if not defined config_error if not defined network_error if not defined https_error if not defined syntax_error if not defined webdav_error (
    echo [✓] 所有测试通过 - WebDAV配置正常
    echo %date% %time% - 诊断结果: 所有测试通过 >> "%DIAGNOSTIC_LOG%"
    echo.
    echo 建议操作:
    echo 1. 尝试重新挂载WebDAV
    echo 2. 检查是否有防火墙或安全软件干扰
    echo 3. 重启rclone服务
) else (
    echo [✗] 发现问题，需要修复
    echo %date% %time% - 诊断结果: 发现问题 >> "%DIAGNOSTIC_LOG%"
    echo.
    echo 问题详情:
    if defined file_error echo - 必要文件缺失
    if defined config_error echo - 配置文件问题
    if defined network_error echo - 网络连接问题
    if defined https_error echo - HTTPS连接问题
    if defined syntax_error echo - 配置语法错误
    if defined webdav_error echo - WebDAV认证失败
    
    echo.
    echo 建议修复操作:
    if defined webdav_error (
        echo 1. 检查WebDAV用户名和密码是否正确
        echo 2. 使用主脚本的"获取rclone的加密密码"功能重新加密密码
        echo 3. 确认WebDAV服务器是否正常运行
        echo 4. 检查账户是否被锁定或权限被更改
    )
    if defined network_error echo 5. 检查网络连接和防火墙设置
    if defined syntax_error echo 6. 检查rclone.conf文件格式是否正确
)

echo ================================================
exit /b 