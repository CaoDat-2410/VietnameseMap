@REM ----------------------------------------------------------------------------
@REM Maven Wrapper startup script for Windows
@REM ----------------------------------------------------------------------------
@echo off
setlocal
set "MAVEN_PROJECTBASEDIR=%~dp0."
set "WRAPPER_JAR=%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.jar"
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" goto :run
for /f "delims=" %%i in ('where java 2^>nul') do (
    set "JAVA_EXE=%%i"
    goto :run_path
)
echo Java was not found. Set JAVA_HOME to a JDK 21 installation.
exit /b 1

:run_path
"%JAVA_EXE%" "-Dmaven.multiModuleProjectDirectory=%MAVEN_PROJECTBASEDIR%" -classpath "%WRAPPER_JAR%" org.apache.maven.wrapper.MavenWrapperMain %*
exit /b %ERRORLEVEL%

:run
"%JAVA_HOME%\bin\java.exe" "-Dmaven.multiModuleProjectDirectory=%MAVEN_PROJECTBASEDIR%" -classpath "%WRAPPER_JAR%" org.apache.maven.wrapper.MavenWrapperMain %*
