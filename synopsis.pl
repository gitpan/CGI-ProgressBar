	use lib '..';

	use CGI::ProgressBar qw/:standard/;
	$| = 1;	# Do not buffer output

	print header,
		start_html('A Simple Example'),
		h1('A Simple Example'),
		p('This example will fill the screen with nonsense between updates to a progress bar.'),
		progress_bar( -from=>1, -to=>10 );

	for (1..10){
		print update_progress_bar;
		# Simulate being busy:
		print rand>0.5 ? chr 47 : chr 92 for 0 .. 100000;
	}
	print hide_progress_bar;
	print p('All done.');
	print end_html;
	exit;
