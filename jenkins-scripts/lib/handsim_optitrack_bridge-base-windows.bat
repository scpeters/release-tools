:: Supposed to has been called ignition-base before
:: asumming a haptix-comm source at WORKSPACE/haptix-comm
::

@echo on

set win_lib=%SCRIPT_DIR%\lib\windows_library.bat

:: Call vcvarsall and all the friends
echo # BEGIN SECTION: configure the MSVC compiler
call %win_lib% :configure_msvc_compiler
echo # END SECTION

echo # BEGIN SECTION: setup workspace
cd %WORKSPACE%
IF exist workspace ( rmdir /s /q workspace ) || goto :error
mkdir workspace
cd workspace
echo # END SECTION

echo # BEGIN SECTION: move sources so we agree with configure.bat layout
set HANDSIM_WS=%WORKSPACE%\workspace\handsim
if exist %HANDSIM_WS% ( rm /s /q %HANDSIM_WS% || goto :error )
xcopy %WORKSPACE%\handsim %HANDSIM_WS% /s /i /e > xcopy.log || goto :error
echo # END SECTION


echo # BEGIN SECTION: downloading optitrack libraries
cd %WORKSPACE%/workspace
mkdir bridgeLibs
cd bridgeLibs
call %win_lib% :download_7za
call %win_lib% :wget 'https://www.dropbox.com/s/tkc25e1pzn4lm8f/bridgeLibs.zip?dl=1' bridgeLibs.zip
call %win_lib% :unzip_7za bridgeLibs.zip
echo # END SECTION

echo # BEGIN SECTION: compiling handsim/windows
cd %WORKSPACE%/workspace/handsim/windows || goto :error
mkdir build
cd build
copy %WORKSPACE%\workspace\NPTrackingToolsx64.dll .
call "..\configure.bat" Release %BITNESS% || goto :error
nmake || goto :error
echo # END SECTION

echo # BEGIN SECTION: generating the zip
mkdir %WORKSPACE%\workspace\package || goto %win_lib% :error
cd %WORKSPACE%\workspace\package || goto %win_lib% :error
copy %WORKSPACE%\workspace\bridgeLibs\* .
copy %WORKSPACE%\workspace\handsim\windows\build\*.exe .

cd %WORKSPACE%\workspace\
call %win_lib% :download_7za
7za.exe a -tzip optitrack_bridge.zip %WORKSPACE%\workspace\package
echo # END SECTION

goto :EOF

:error - error routine
::
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
