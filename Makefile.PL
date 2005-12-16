use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::ProgressBar',
    'VERSION_FROM'	=> 'ProgressBar.pm', # finds $VERSION
    'PREREQ_PM'		=> {CGI => 3.15}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ProgressBar.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard -at- cpan -dot- org>') : ()),
);
