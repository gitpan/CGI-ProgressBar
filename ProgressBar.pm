package CGI::ProgressBar;

=head1 NAME

CGI::ProgressBar - CGI.pm sub-class with a progress bar object

=head1 SYNOPSIS

	use lib '..';

	use CGI::ProgressBar qw/:standard/;
	$| = 1;	# Do not buffer output

	my $steps = 10;

	print header,
		start_html('A Simple Example'),
		h1('A Simple Example'),
		p('This example will fill the screen with nonsense between updates to a progress bar.'),
		progress_bar( -from=>1, -to=>$steps );

	for (1..$steps){
		print update_progress_bar;
		# Simulate being busy:
		print rand>0.5 ? chr 47 : chr 92 for 0 .. 100000;
	}
	print hide_progress_bar;
	print p('All done.');
	print end_html;
	exit;

=head1 DESCRIPTION

This module provides a progress bar for web browsers.

It aims to require that the recipient client have a minimum
of JavaScript 1.0, HTML 4.0, ancd CSS/1, but this has yet to be tested.

All feedback would be most welcome. Address at the end of the POD.

=cut

use 5.004;
use strict;
use warnings;

=head2 DEPENDENCIES

	CGI

=cut

BEGIN {
	our $VERSION = '0.01';
	use CGI::Util qw(rearrange );
	use base 'CGI';

=head2 EXPORT

	progress_bar
	update_progress_bar
	hide_progress_bar

=cut

	no strict 'refs';
	foreach (qw/ progress_bar update_progress_bar hide_progress_bar/){
		*{caller(0).'::'.$_} = \&{__PACKAGE__.'::'.$_};
	}
	use strict 'refs';
}

=head1 USE

The module sub-classes CGI.pm, providing three additional methods (or
functions, depending on your taste), each of which are detailed below.

Simply replace your "use CGI qw//;" with "use CGI::ProgressBar qw//;".

Treat each new function as any other CGI.pm HTML-producing routine with
the exception that the arguments should be supplied as in OOP form. In
other words, the following are all the same:

	my $html = $query->progress_bar;
	my $html = progress_bar;
	my $html = progress_bar(from=>1, to=>10);
	my $html = $query->progress_bar(from=>1, to=>10);
	my $html = $query->progress_bar(-to=>10);

This will probably change if someone would like it to.

=head2 FUNCTION/METHOD progress_bar

Returns mark-up that instantiates a progress bar.
Currently that is HTML and JS, but perhaps the JS
ought to go into the head.

The progress bar itself is an object in this class,
stored in the calling (C<CGI>) object - specifically
in the field C<progress_bar>, which we create as
an array.

=over 4

=item from

=item to

Values which the progress bar spans.
Defaults: 0, 100.

=item width

=item height

The width and height of the progress bar, in pixels. Cannot accept
percentages (yet).
Defaults: 400, 20.

=item blocks

The number of blocks to appear in the progress bar.
Default: 100.

=item gap

The amount of space between blocks, in pixels.
Default: 1.

=item label

Supply this parameter with a true value to have a numerical
display of progress.

=cut


sub progress_bar {
    local $_;
    my ($self,%args);
    ($self,@_) = &CGI::self_or_default(@_);

	my $pb = bless {
		from	=> 0,		to		=> 100,	width	=> '400',
		height	=> '20',	blocks	=> 10,	gap		=> '1',
		label	=> 1,		colors	=> [100,'blue'],
	},__PACKAGE__;

	#my @arg_names = qw/from to width height blocks gap label colors/;
	#if (@p){
	#	my @vals = rearrange([ @arg_names ],@p);
	#	for (0..$#arg_names){
	#		# warn "Set arg $arg_names[$_] to ",($vals[$_] || $pb->{$arg_names[$_]}),"\t";
	#		$pb->{$arg_names[$_]} = $vals[$_] if $vals[$_];
	#	}
	#}

	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	else {
		warn "Usage: \$class->new(  keys=>values,  )";
		return undef;
	}
	foreach my $k (keys %args){
		my $nk = $k;
		$nk =~ s/^-(.*)$/$1/;
		$pb->{$nk} = $args{$k};
	}

	$pb->{colors}	= $pb->{colors}? {@{$pb->{colors}}} : {100=>'blue'};
	$pb->{_length}	= $pb->{to} - $pb->{from};	# Units in the bar
	# interval 		= $pb->{_length}>0? $pb->{blocks}/$pb->{_length} : 0;
	$pb->{interval}	= 1;	# publicise?

	# IN A LATER VERSION....Store ourself in caller's progress_bar array
	# push @{ $self->{progress_bar} },$pb;
	$self->{progress_bar} = $pb;

	return $self->_pb_init();
}

=head2 FUNCTION/METHOD update_progress_bar

Updates the progress bar.

=cut

sub update_progress_bar {
	return "<script type='text/javascript'>//<!--
	pblib_progress_update()\n//-->\n</script>\n";
}

=head2 FUNCTION/METHOD hide_progress_bar

Hides the progress bar.

=cut

sub hide_progress_bar {
	my($self,@p) = &CGI::self_or_default(@_);
	#my $pb = $self->{progress_bar}[$#{$self->{progress_bar}}];
	my $pb = $self->{progress_bar};
	return
	"<script type='text/javascript'>//<!--
	$pb->{layer_id}->{container}.style.display='none';\n//-->\n</script>\n";
}

=head1 CSS STYLE CLASS EMPLOYED

=item pblib_bar

A C<DIV> containing the whole progress bar, including any
accessories (such as the label). The only attribute used
by this module is C<width>, which is set dynamically.
The rest is up to you. A good start is:

	padding:    2 px;
	border:     solid black 1px;
	text-align: center;

=item pblib_block

An individual block within the status bar. The following
attributes are set dynamically: C<width>, C<height>,
C<margin-right>.

=item pblib_number

Formatting for the C<label> text (part of which is actually
an C<input type='text'> element. C<border> and C<text-align>
are used here, and the whole appears centred within a C<table>.

=cut

sub CGI::_pb_init { my $self = shift;
	# my $pb = $self->{progress_bar}[$#{$self->{progress_bar}}];
	my $pb = $self->{progress_bar};
	my $block_wi = int( ($pb->{width}-($pb->{gap}*$pb->{blocks})) /$pb->{blocks})-1;
	$block_wi = 1 if $block_wi < 1;
	$pb->{layer_id} = {
		container	=> 'pb_cont'.time,
		form		=> 'pb_form'.time,
		block		=> 'b'.time,
		number		=> 'n'.time,
	};

	my $html = "<style type='text/css'>
	.pblib_bar {
		width: $pb->{width} px;
	}
	.pblib_block {
		width: ".($block_wi)."px;
		height: ".$pb->{height}."px;
		margin-right:$pb->{gap}px;
	}";
	if ($pb->{label}){
		$html .=".pblib_number {
		border:none;
		text-align:right
		}";
	}
	$html .="\n</style>\n";
	$html .= "\n<!-- begin progress bar $pb->{layer_id}->{container} -->" if $^W;
	$html .= "\n<div id='$pb->{layer_id}->{container}'>\n";
	$html .= "\t<table>\n\t<tr><td><table align='center'><tr><td>" if $pb->{label};

	$html .= "\t<div class='pblib_bar'>\n\t";
	foreach my $i (1..$pb->{blocks}){
		$html .= "<span class='pblib_block' id='$pb->{layer_id}->{block}$i'></span>";
	}
	$html .= "\n\t</div>\n";
	$html .= "</td></tr>\n<tr><td align='center'>
		<form name='$pb->{layer_id}->{form}' action='noneEver'>
			<input name='$pb->{layer_id}->{number}' type='text' size='6' value='0' class='pblib_number'
			/><span class='pblib_number'>/$pb->{to}</span>
		</form>
		</td></tr></table>
		</td></tr></table>" if $pb->{label};
	$html .= "</div>\n";
	$html .="<!-- end progress bar $pb->{layer_id}->{container} -->\n\n" if $^W;
	$html .= "\n<script language='javascript' type='text/javascript'>\n// <!--";
	$html .= "\t progress bar produced by ".__PACKAGE__." at ".scalar(localtime)."\n" if $^W;
	$html .= "
	var progressColor = 'navy';
	var pblib_at;
	pblib_progress_clear();
	function pblib_progress_clear() {
		for (var i = 1; i <= $pb->{blocks}; i++)
			document.getElementById('$pb->{layer_id}->{block}'+i).style.backgroundColor='transparent';
		pblib_at = ".($pb->{from}).";
	}
	function pblib_progress_update() {
		pblib_at += $pb->{interval};
		if (pblib_at > $pb->{blocks})
			pblib_progress_clear();
		else {
			for (var i = 1; i <= Math.ceil(pblib_at); i++)
				document.getElementById('$pb->{layer_id}->{block}'+i).style.backgroundColor = progressColor;\n";
	$html .= "document.".$pb->{layer_id}->{form}.".".$pb->{layer_id}->{number}.".value++\n" if $pb->{label};
	$html .= "\t\t}\n\t}\n//-->\n</script>\n";

	return $html;
}

=head1 BUGS, CAVEATS, TODO

=over 4

=item One bar per page

This may change.

=item Parameter passing doesn't match F<CGI.pm>

But it will in the next release if you ask me for it.

=item C<colors> not implimented

I'd like to see here something like the C<Tk::ProgressBar::colors>;
not because I've ever used it, but because it might be cool.

=item Horizontal orientation only

You can get around this by adjusting the CSS, but you'd rather not.
And even if you did, the use of C<-label> might not look very nice.
So the next version will support an C<-orientation> option.

=item Inline CSS and JS

Because it's easiest for me. I suppose some kind of over-loading of
the C<CGI::start_html> would be possible, but then I'd have to check
it, and maybe update it, every time F<CGI.pm> was updated, which I
don't fancy.

=cut

1;
__END__

=head1 AUTHOR

Lee Goddard <lgoddard -at- cpan -dot- org>

=head2 COPYRIGHT

Copyright (C) Lee Goddard, 2002-2003. All Rights Reserved.
This software is made available under the same terms as Perl
itself. You may use and redistribute this software under the
same terms as Perl itself.

=head1 KEYWORDS

HTML, CGI, progress bar, widget

=head1 SEE ALSO

L<perl>. L<CGI>, L<Tk::ProgressBar>,

=cut
