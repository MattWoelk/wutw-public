call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
scons platform=windows target=template_release -j 16
scons platform=windows target=template_debug -j 16
