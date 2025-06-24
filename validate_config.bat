@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title rclone 配置文件验证工具
chcp 65001 > nul

rem ======================================
rem 配置和常量
rem ======================================
set "CONFIG_FILE=%~dp0rclone.conf"
set "BACKUP_DIR=%~dp0config_backup"
set "VALIDATION_LOG=%~dp0config_validation.log"

echo ================================================
echo            rclone 配置文件验证工具
echo ================================================
echo 验证时间: %date% %time%
echo ================================================

rem 清空之前的验证日志
echo %date% %time% - 开始配置文件验证 > "%VALIDATION_LOG%"

rem 1. 检查配置文件是否存在
call :check_config_exists

rem 2. 验证配置文件语法
call :validate_syntax

rem 3. 检查必要参数
call :check_required_params

rem 4. 测试配置连接
call :test_config_connection

rem 5. 显示验证结果
call :show_validation_results

echo.
echo 验证完成！详细日志保存在: %VALIDATION_LOG%
pause
goto :EOF

rem ======================================
rem 检查配置文件是否存在
rem ======================================
:check_config_exists
echo [检查] 验证配置文件存在性...
echo %date% %time% - 检查配置文件存在性 >> "%VALIDATION_LOG%"

if exist "%CONFIG_FILE%" (
    echo [✓] 配置文件存在: %CONFIG_FILE%
    echo %date% %time% - 配置文件存在 >> "%VALIDATION_LOG%"
    
    rem 显示文件信息
    for %%A in ("%CONFIG_FILE%") do (
        echo     文件大小: %%~zA 字节
        echo     最后修改: %%~tA
        echo %date% %time% - 文件大小: %%~zA 字节, 最后修改: %%~tA >> "%VALIDATION_LOG%"
    )
) else (
    echo [✗] 配置文件不存在: %CONFIG_FILE%
    echo %date% %time% - 错误: 配置文件不存在 >> "%VALIDATION_LOG%"
    set "file_missing=1"
    exit /b
)
exit /b

rem ======================================
rem 验证配置文件语法
rem ======================================
:validate_syntax
echo [检查] 验证配置文件语法...
echo %date% %time% - 开始语法验证 >> "%VALIDATION_LOG%"

if defined file_missing (
    echo [跳过] 配置文件不存在，跳过语法验证
    echo %date% %time% - 跳过语法验证: 文件不存在 >> "%VALIDATION_LOG%"
    exit /b
)

rem 使用rclone检查配置语法
rclone config show drfycloud > temp_syntax_check.txt 2>&1
set "syntax_exit_code=!errorlevel!"

if !syntax_exit_code! equ 0 (
    echo [✓] 配置文件语法正确
    echo %date% %time% - 配置文件语法正确 >> "%VALIDATION_LOG%"
    
    rem 显示配置内容（隐藏密码）
    echo [信息] 配置内容预览:
    type temp_syntax_check.txt | findstr /v "pass"
) else (
    echo [✗] 配置文件语法错误
    echo %date% %time% - 配置文件语法错误 >> "%VALIDATION_LOG%"
    echo [错误详情]:
    type temp_syntax_check.txt
    echo %date% %time% - 语法错误详情: >> "%VALIDATION_LOG%"
    type temp_syntax_check.txt >> "%VALIDATION_LOG%"
    set "syntax_error=1"
)

del temp_syntax_check.txt > nul 2>&1
exit /b

rem ======================================
rem 检查必要参数
rem ======================================
:check_required_params
echo [检查] 验证必要参数...
echo %date% %time% - 开始参数检查 >> "%VALIDATION_LOG%"

if defined file_missing (
    echo [跳过] 配置文件不存在，跳过参数检查
    echo %date% %time% - 跳过参数检查: 文件不存在 >> "%VALIDATION_LOG%"
    exit /b
)

rem 检查section名称
findstr "^\[drfycloud\]" "%CONFIG_FILE%" > nul
if !errorlevel! equ 0 (
    echo [✓] 找到配置节: [drfycloud]
    echo %date% %time% - 找到配置节: [drfycloud] >> "%VALIDATION_LOG%"
) else (
    echo [✗] 未找到配置节: [drfycloud]
    echo %date% %time% - 错误: 未找到配置节 [drfycloud] >> "%VALIDATION_LOG%"
    set "section_error=1"
)

rem 检查type参数
findstr "^type.*=" "%CONFIG_FILE%" > nul
if !errorlevel! equ 0 (
    for /f "tokens=2 delims== " %%a in ('findstr "^type" "%CONFIG_FILE%"') do (
        set "config_type=%%a"
        set "config_type=!config_type: =!"
    )
    if "!config_type!"=="webdav" (
        echo [✓] 类型配置正确: !config_type!
        echo %date% %time% - 类型配置正确: !config_type! >> "%VALIDATION_LOG%"
    ) else (
        echo [✗] 类型配置错误: !config_type! (应为 webdav)
        echo %date% %time% - 类型配置错误: !config_type! >> "%VALIDATION_LOG%"
        set "type_error=1"
    )
) else (
    echo [✗] 未找到type参数
    echo %date% %time% - 错误: 未找到type参数 >> "%VALIDATION_LOG%"
    set "type_error=1"
)

rem 检查url参数
findstr "^url.*=" "%CONFIG_FILE%" > nul
if !errorlevel! equ 0 (
    for /f "tokens=2 delims== " %%a in ('findstr "^url" "%CONFIG_FILE%"') do (
        set "config_url=%%a"
        set "config_url=!config_url: =!"
    )
    echo [✓] 找到URL配置: !config_url!
    echo %date% %time% - URL配置: !config_url! >> "%VALIDATION_LOG%"
    
    rem 检查URL格式
    echo !config_url! | findstr "^https://" > nul
    if !errorlevel! equ 0 (
        echo [✓] URL格式正确 (HTTPS)
        echo %date% %time% - URL格式正确 (HTTPS) >> "%VALIDATION_LOG%"
    ) else (
        echo [!] URL可能不安全 (非HTTPS)
        echo %date% %time% - 警告: URL不安全 (非HTTPS) >> "%VALIDATION_LOG%"
    )
) else (
    echo [✗] 未找到url参数
    echo %date% %time% - 错误: 未找到url参数 >> "%VALIDATION_LOG%"
    set "url_error=1"
)

rem 检查user参数
findstr "^user.*=" "%CONFIG_FILE%" > nul
if !errorlevel! equ 0 (
    for /f "tokens=2 delims== " %%a in ('findstr "^user" "%CONFIG_FILE%"') do (
        set "config_user=%%a"
        set "config_user=!config_user: =!"
    )
    echo [✓] 找到用户名配置: !config_user!
    echo %date% %time% - 用户名配置: !config_user! >> "%VALIDATION_LOG%"
) else (
    echo [✗] 未找到user参数
    echo %date% %time% - 错误: 未找到user参数 >> "%VALIDATION_LOG%"
    set "user_error=1"
)

rem 检查pass参数
findstr "^pass.*=" "%CONFIG_FILE%" > nul
if !errorlevel! equ 0 (
    echo [✓] 找到密码配置
    echo %date% %time% - 找到密码配置 >> "%VALIDATION_LOG%"
    
    rem 检查密码是否为占位符
    findstr "您的webdav密码" "%CONFIG_FILE%" > nul
    if !errorlevel! equ 0 (
        echo [!] 密码似乎是占位符，需要更新为实际密码
        echo %date% %time% - 警告: 密码是占位符 >> "%VALIDATION_LOG%"
        set "placeholder_password=1"
    ) else (
        echo [✓] 密码已配置 (非占位符)
        echo %date% %time% - 密码已正确配置 >> "%VALIDATION_LOG%"
    )
) else (
    echo [✗] 未找到pass参数
    echo %date% %time% - 错误: 未找到pass参数 >> "%VALIDATION_LOG%"
    set "pass_error=1"
)
exit /b

rem ======================================
rem 测试配置连接
rem ======================================
:test_config_connection
echo [测试] 测试配置连接...
echo %date% %time% - 开始连接测试 >> "%VALIDATION_LOG%"

if defined file_missing (
    echo [跳过] 配置文件不存在，跳过连接测试
    echo %date% %time% - 跳过连接测试: 文件不存在 >> "%VALIDATION_LOG%"
    exit /b
)

if defined syntax_error (
    echo [跳过] 配置语法错误，跳过连接测试
    echo %date% %time% - 跳过连接测试: 语法错误 >> "%VALIDATION_LOG%"
    exit /b
)

rem 尝试连接测试（快速列表）
echo [测试] 尝试连接WebDAV服务器...
rclone --config "%CONFIG_FILE%" --no-check-certificate ls drfycloud: --max-depth 1 --timeout 30s > temp_connection_test.txt 2>&1
set "connection_exit_code=!errorlevel!"

if !connection_exit_code! equ 0 (
    echo [✓] WebDAV连接测试成功
    echo %date% %time% - WebDAV连接测试成功 >> "%VALIDATION_LOG%"
    echo [信息] 连接正常，可以访问远程目录
) else (
    echo [✗] WebDAV连接测试失败
    echo %date% %time% - WebDAV连接测试失败，退出代码: !connection_exit_code! >> "%VALIDATION_LOG%"
    
    rem 分析错误类型
    findstr "401" temp_connection_test.txt > nul
    if !errorlevel! equ 0 (
        echo [错误] 401 Unauthorized - 认证失败，请检查用户名和密码
        echo %date% %time% - 401认证错误 >> "%VALIDATION_LOG%"
        set "auth_error=1"
    )
    
    findstr "404" temp_connection_test.txt > nul
    if !errorlevel! equ 0 (
        echo [错误] 404 Not Found - URL地址错误或服务不存在
        echo %date% %time% - 404地址错误 >> "%VALIDATION_LOG%"
        set "url_not_found=1"
    )
    
    findstr "timeout" temp_connection_test.txt > nul
    if !errorlevel! equ 0 (
        echo [错误] 连接超时 - 网络问题或服务器无响应
        echo %date% %time% - 连接超时 >> "%VALIDATION_LOG%"
        set "timeout_error=1"
    )
    
    echo [详细错误]:
    type temp_connection_test.txt
    echo %date% %time% - 连接错误详情: >> "%VALIDATION_LOG%"
    type temp_connection_test.txt >> "%VALIDATION_LOG%"
    set "connection_error=1"
)

del temp_connection_test.txt > nul 2>&1
exit /b

rem ======================================
rem 显示验证结果
rem ======================================
:show_validation_results
echo ================================================
echo                  验证结果汇总
echo ================================================

rem 计算错误数量
set "error_count=0"
if defined file_missing set /a error_count+=1
if defined syntax_error set /a error_count+=1
if defined section_error set /a error_count+=1
if defined type_error set /a error_count+=1
if defined url_error set /a error_count+=1
if defined user_error set /a error_count+=1
if defined pass_error set /a error_count+=1
if defined connection_error set /a error_count+=1

rem 计算警告数量
set "warning_count=0"
if defined placeholder_password set /a warning_count+=1

if !error_count! equ 0 (
    if !warning_count! equ 0 (
        echo [✓] 配置文件验证通过 - 所有检查正常
        echo %date% %time% - 验证结果: 完全通过 >> "%VALIDATION_LOG%"
    ) else (
        echo [!] 配置文件基本正常，但有警告 (!warning_count! 个)
        echo %date% %time% - 验证结果: 有警告 >> "%VALIDATION_LOG%"
    )
) else (
    echo [✗] 配置文件验证失败 - 发现 !error_count! 个错误
    echo %date% %time% - 验证结果: 失败，错误数: !error_count! >> "%VALIDATION_LOG%"
)

echo.
echo 详细结果:
if defined file_missing echo - [错误] 配置文件缺失
if defined syntax_error echo - [错误] 语法错误
if defined section_error echo - [错误] 配置节问题
if defined type_error echo - [错误] 类型配置错误
if defined url_error echo - [错误] URL配置缺失
if defined user_error echo - [错误] 用户名配置缺失
if defined pass_error echo - [错误] 密码配置缺失
if defined connection_error echo - [错误] 连接测试失败
if defined placeholder_password echo - [警告] 密码为占位符

echo.
echo 修复建议:
if defined file_missing echo 1. 创建 rclone.conf 配置文件
if defined auth_error echo 2. 检查并更新WebDAV用户名和密码
if defined placeholder_password echo 3. 使用主脚本的"获取rclone的加密密码"功能设置正确的密码
if defined url_not_found echo 4. 验证WebDAV服务器URL是否正确
if defined timeout_error echo 5. 检查网络连接和防火墙设置

echo ================================================
exit /b 