use lib '..';
use strict;

use CGI::ProgressBar qw/:standard/;
$| = 1;	# Do not buffer output

# This (for -style below) won't work since $CSS is only filled
# when the internal 'init' methods are called, and they're only
# called when progress_bar is called. So, use OOP....
my $stylecode = $CGI::ProgressBar::CSS;

print header,
	start_html(
		-title=>'A Simple Example',
		-style=>{-src=>'my_stylesheet.css',
		# -code=>$stylecode
	} ),
	h1('A Simple Example'),
	p('This example will fill the screen with nonsense between updates to a progress bar.'),
	progress_bar( -from=>1, -to=>10 );

for (1..10){
	print update_progress_bar;
	# Simulate being busy:
	# print rand>0.5 ? chr 47 : chr 92 for 0 .. 100000;
	print "//";
}
print hide_progress_bar;
print p('All done.');
print end_html;
exit;
