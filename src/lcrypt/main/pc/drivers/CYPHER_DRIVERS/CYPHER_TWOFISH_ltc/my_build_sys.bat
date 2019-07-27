@echo off

rem Set the build environment - if not set by build_all_x.bat 
if "%DOXBOX_FORCE_CPU%"=="" (
	call ..\Common\bin\setup_env_common.bat
	call ..\Common\bin\setup_env_driver.bat
)


rem Move into the correct src directory...
%PROJECT_DRIVE%
cd %PROJECT_DIR%\CYPHER_DRIVERS\CYPHER_TWOFISH_ltc\src

rem The build utility can't handle source files not being in the same dir
call %PROJECT_DIR%\Common\bin\copy_common_driver_files.bat
call %PROJECT_DIR%\Common\bin\copy_lrw_driver_files.bat
call %PROJECT_DIR%\Common\bin\copy_xts_driver_files.bat

rem Implementation...
copy %PROJECT_BASE_DIR%\src\Common\CYPHER_DRIVERS\CYPHER_TWOFISH_ltc\FreeOTFECypherTwofish_ltc.c .
copy %PROJECT_BASE_DIR%\src\Common\CYPHER_DRIVERS\CYPHER_TWOFISH_ltc\FreeOTFECypherTwofish_ltc.h .

rem libtomcrypt library...
copy %THIRD_PARTY_DIR%\libtomcrypt\crypt-1.17\src\ciphers\twofish\twofish.c .
copy %THIRD_PARTY_DIR%\libtomcrypt\crypt-1.17\src\ciphers\twofish\twofish_tab.c .



echo Building SYS...
build -gZ

rem Copying the binary over...
copy %FREEOTFE_OUTPUT_DIR%\FreeOTFECypherTwofish_ltc.sys %BIN_OUTPUT_DIR%

del twofish.c
del twofish_tab.c
del FreeOTFECypherTwofish_ltc.c 
del FreeOTFECypherTwofish_ltc.h 

call %PROJECT_DIR%\Common\bin\delete_lrw_driver_files.bat
call %PROJECT_DIR%\Common\bin\delete_common_driver_files.bat
call %PROJECT_DIR%\Common\bin\delete_xts_driver_files.bat
cd ..

