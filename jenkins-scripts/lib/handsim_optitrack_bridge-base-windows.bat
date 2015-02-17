:: Supposed to has been called ignition-base before
:: asumming a haptix-comm source at WORKSPACE/haptix-comm
::

@echo on

set win_lib=%SCRIPT_DIR%\lib\windows_library.bat

:: Call vcvarsall and all the friends
call %win_lib% :configure_msvc_compiler

cd %WORKSPACE%
IF exist workspace ( rmdir /s /q workspace ) || goto %win_lib% :error
mkdir workspace
move handsim %WORKSPACE%/workspace/handsim || goto %win_lib% :error

echo "Downloading optitrack libraries ..."
cd %WORKSPACE%/workspace
mkdir bridgeLibs
cd bridgeLibs
call %win_lib% :download_7za
call %win_lib% :wget https://www.dropbox.com/s/tkc25e1pzn4lm8f/bridgeLibs.zip?dl=1 bridgeLibs.zip
call %win_lib% :unzip_7za bridgeLibs.zip

echo "Compiling handsim/windows ..."
cd %WORKSPACE%/workspace/handsim/windows || goto %win_lib% :error
mkdir build
cd build
copy %WORKSPACE%\workspace\NPTrackingToolsx64.dll .
call "..\configure.bat" Release %BITNESS% || goto %win_lib% :error
nmake || goto %win_lib% :error

echo "Generating the zip"
mkdir %WORKSPACE%\workspace\package || goto %win_lib% :error
cd %WORKSPACE%\workspace\package || goto %win_lib% :error
copy %WORKSPACE%\workspace\bridgeLibs\* .
copy %WORKSPACE%\workspace\handsim\windows\build\*.exe .

cd %WORKSPACE%\workspace\
"%WORKSPACE%\workspace\7za.exe" a -tzip optitrack_bridge.zip %WORKSPACE%\workspace\package
