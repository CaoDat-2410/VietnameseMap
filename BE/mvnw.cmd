@REM ----------------------------------------------------------------------------
@REM Maven Wrapper startup script for Windows
@REM ----------------------------------------------------------------------------

@echo off
setlocal

set MAVEN_PROJECTBASEDIR=%~dp0
set WRAPPER_JAR="%MAVEN_PROJECTBASEDIR%.mvn\wrapper\maven-wrapper.jar"
set WRAPPER_URL="https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.jar"

@REM Download wrapper JAR if not present
if not exist %WRAPPER_JAR% (
    echo Downloading Maven Wrapper...
    if not exist "%MAVEN_PROJECTBASEDIR%.mvn\wrapper" mkdir "%MAVEN_PROJECTBASEDIR%.mvn\wrapper"
    powershell -Command "Invoke-WebRequest -Uri '%WRAPPER_URL%' -OutFile '%WRAPPER_JAR%'"
)

@REM Find java
set JAVA_HOME=
for /f "tokens=*" %%i in ('where java 2^>nul') do (
    set JAVA_HOME=%%~dpi
    goto :found
)
:found

@REM Run Maven
"%JAVA_HOME%..\..\bin\java.exe" -jar %WRAPPER_JAR% %*
