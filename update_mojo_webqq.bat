@echo off

set drive=%~dp0
set drivep=%drive%
if #%drive:~-1%# == #\# set drivep=%drive:~0,-1%

set PATH=%drivep%\perl\bin;%PATH%
rem env variables
set TERM=
set PERL_JSON_BACKEND=
set PERL_YAML_BACKEND=
set PERL5LIB=
set PERL5OPT=
set PERL_MM_OPT=
set PERL_MB_OPT=

cpanm --mirror http://mirrors.163.com/cpan --mirror-only Mojo::Webqq && Pause

cmd /K