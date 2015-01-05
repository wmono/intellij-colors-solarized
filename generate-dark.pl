#!/usr/bin/perl
use strict;
use warnings;

use XML::Twig;

# Re-generates Solarized Dark.icls from Solarized Light.icls

my %colour_map = (
	base03			=> '002b36',
	base02			=> '073642',
	base01			=> '586e75',
	base00			=> '657b83',
	base0			=> '839496',
	base1			=> '93a1a1',
	base2			=> 'eee8d5',
	base3			=> 'fdf6e3',
	yellow			=> 'b58900',
	orange			=> 'cb4b16',
	red				=> 'dc322f',
	nagenta			=> 'd33682',
	violet			=> '6c71c4',
	blue			=> '268bd2',
	cyan			=> '2aa198',
	green			=> '859900',
);
foreach my $key (keys %colour_map) {
	$colour_map{$colour_map{$key}} = $key;
}

my %exception = (
	'ADDED_LINES_COLOR'												=> ['baeeba', 'baffba'],
	'MODIFIED_LINES_COLOR'											=> ['bccff9', '99ccff'],
	'CONSOLE_DARKGRAY_OUTPUT FOREGROUND'							=> ['586e75', '586e75'],
	'CONSOLE_GRAY_OUTPUT FOREGROUND'								=> ['657b83', '657b83'],
	'EXECUTIONPOINT_ATTRIBUTES FOREGROUND'							=> ['fdf6e3', 'eee8d5'],
	'EXECUTIONPOINT_ATTRIBUTES BACKGROUND'							=> ['1f70a6', '1f70a6'],
	'IDENTIFIER_UNDER_CARET_ATTRIBUTES BACKGROUND'					=> ['ccccff', '11407e'],
	'IDENTIFIER_UNDER_CARET_ATTRIBUTES ERROR_STRIPE_COLOR'			=> ['ccccff', 'ccccff'],
	'SEARCH_RESULT_ATTRIBUTES BACKGROUND'							=> ['ccccff', '11407e'],
	'WARNING_ATTRIBUTES BACKGROUND'									=> ['ffdf80', 'b58900'],
	'WARNING_ATTRIBUTES ERROR_STRIPE_COLOR'							=> ['ffff00', 'b58900'],
	'WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES BACKGROUND'			=> ['ffcce5', '432c38'],
	'WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES ERROR_STRIPE_COLOR'	=> ['ffcce5', '432c38'],
	'WRITE_SEARCH_RESULT_ATTRIBUTES BACKGROUND'						=> ['ffcce5', '432c38'],
);

my $twig = XML::Twig->new(
	comments => 'keep',
	keep_atts_order => 1,
	keep_encoding => 1,
	output_filter => 'safe',
	pretty_print => 'indented',
);

$twig->parsefile('Solarized Light.icls');
$twig->root->set_att('name', 'Solarized Dark');

# Flip colours
foreach my $elt ($twig->descendants) {
	process_option($elt);
}

$twig->print;

sub process_option {
	my ($elt) = @_;
	my $tag = $elt->tag;
	my $name = $elt->att('name');
	my $colour = $elt->att('value');

	if ($elt->att_exists('#skip')) {
		return;
	}

	if ($tag eq 'option' && defined $colour && $colour =~ m/^[0-9A-Fa-f]{3,6}$/) {
		my $colour_name = $colour_map{sprintf('%06s', lc $colour)};
		my $node_name = describe_node($elt);

		if (exists $exception{$node_name}) {
			if ($exception{$node_name}->[0] ne $colour) {
				warn "Colour option $node_name has changed from $exception{$node_name}->[0] to $colour\n";
			}
			$elt->set_att('value', $exception{$node_name}->[1]);
			return;
		}

		if (not defined $colour_name) {
			warn "Colour option $node_name is not a Solarized colour: $colour\n";
			return;
		}

		my ($base_colour, $extra_colour, $extra_type);

		if (($base_colour) = $colour_name =~ m/^base([0123])$/) {
			$colour = $colour_map{"base0$base_colour"};
		}
		elsif (($base_colour) = $colour_name =~ m/^base0([0123])$/) {
			$colour = $colour_map{"base$base_colour"};
		}

		$colour =~ s/^0+//;
		$elt->set_att('value', $colour);
	}
}

sub describe_node {
	my ($node) = @_;

	my @path;
	while (defined $node and $node->tag ne 'scheme') {
		my $node_name = $node->att('name');
		unshift @path, $node_name if defined $node_name;
		$node = $node->parent;
	};

	return join(' ', @path);
}

# vim: set ts=4 sw=4:
