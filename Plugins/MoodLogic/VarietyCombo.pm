package Plugins::MoodLogic::VarietyCombo;

#$Id$

# SlimServer Copyright (C) 2001-2004 Sean Adams, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

use strict;
use Slim::Buttons::Common;
use Plugins::MoodLogic::Plugin;
use Slim::Utils::Timers;
use Slim::Music::Info;
use Slim::Display::Display;

our %functions = ();

sub init {
	Slim::Buttons::Common::addMode('moodlogic_variety_combo', getFunctions(), \&setMode);

	# Variety Combo Selection UI
	%functions = (
		
		'up' => sub {
			my $client = shift;
			my $variety = Slim::Utils::Prefs::get('varietyCombo');
			my $inc = 1;
			my $rate = 50; #Hz maximum
			my $accel = 15; #Hz/s

			if (Slim::Hardware::IR::holdTime($client) > 0) {
				$inc *= Slim::Hardware::IR::repeatCount($client,$rate,$accel);
			} else {
				$inc = 2;
			}

			$variety += $inc;
			if ($variety > 100) { $variety = 100; };
			Slim::Utils::Prefs::set('varietyCombo', $variety);
			$client->update();
		},

		'down' => sub  {
			my $client = shift;
			my $variety = Slim::Utils::Prefs::get('varietyCombo');
			my $inc = 1;
			my $rate = 50; #Hz maximum
			my $accel = 15; #Hz/s

			if (Slim::Hardware::IR::holdTime($client) > 0) {
				$inc *= Slim::Hardware::IR::repeatCount($client,$rate,$accel);
			} else {
				$inc = 2;
			}

			$variety -= $inc;
			if ($variety < 0) { $variety = 0; };
			Slim::Utils::Prefs::set('varietyCombo', $variety);
			$client->update();
		},
		
		'left' => sub  {
			my $client = shift;
			Slim::Buttons::Common::popModeRight($client);
		},
		
		'right' => sub  {
			my $client = shift;
			my $instantMix;

			my $mood   = $client->param('mood');
			my $track  = $client->param('song');
			my $artist = $client->param('artist');
			my $genre  = $client->param('genre');
			my $ds     = Slim::Music::Info::getCurrentDataStore();
			
			if (defined $track) {

				$instantMix = Plugins::MoodLogic::Plugin::getMix($track->moodlogic_id(), undef, 'song');

			} elsif (defined $mood && defined $artist) {

				$instantMix = Plugins::MoodLogic::Plugin::getMix($artist->moodlogic_id(), $mood, 'artist');

			} elsif (defined $mood && defined $genre) {

				$instantMix = Plugins::MoodLogic::Plugin::getMix($genre->moodlogic_id(), $mood, 'genre');
			}

			if (scalar @$instantMix) {
				Slim::Buttons::Common::pushMode($client, 'instant_mix', { 'mix' => $instantMix });
				specialPushLeft($client, 0);
			} else {
				$client->bumpRight()
			}
		},

		'play' => sub  {
			my $client = shift;
			my $currentItem;
			if (defined $client->param( 'song')) {
				$currentItem = $client->param( 'song');
				Slim::Buttons::Common::pushMode($client, 'instant_mix', {'song' => $client->param( 'song')});
				specialPushLeft($client, 0);
			} else {
				$client->bumpRight()
			}
		},
	);
}

sub getFunctions {
	return \%functions;
}

sub setMode {
	my $client = shift;
	
	$client->lines(\&lines);
}

#
# figure out the lines to be put up to display
#
sub lines {
	my $client = shift;
	my ($line1, $line2);
	my $variety = Slim::Utils::Prefs::get('varietyCombo');
	my $level = int($variety / 100 * 40);
	
	$line1 = $client->linesPerScreen() == 2 ? $client->string('SETUP_VARIETYCOMBO') : $client->string('SETUP_VARIETYCOMBO_DBL');
	$line1 .= " (".$variety.")";

	$line2 = $client->symbols($client->progressBar($client->displayWidth(), $level / 40));

	if ($client->linesPerScreen() == 1) { $line2 = $line1; }

	return {
		'line1'    => $line1,
		'line2'    => $line2,
		'overlay1' => $client->string('MUSICMAGIC_MIXRIGHT'),
	};
}

sub specialPushLeft {
	my $client   = shift;
	my $step     = shift;

	my $now  = Time::HiRes::time();
	my $when = $now + 0.5;
	my $mixer;
	
	$mixer  = $client->string('MOODLOGIC_MIXING');
	
	if ($step == 0) {

		Slim::Buttons::Common::pushMode($client, 'block');
		$client->pushLeft(undef, { 'line1' => $mixer });
		Slim::Utils::Timers::setTimer($client,$when,\&specialPushLeft,$step+1);

	} elsif ($step == 3) {

		Slim::Buttons::Common::popMode($client);
		$client->pushLeft({ 'line1' => $mixer."..." }, undef);

	} else {

		$client->update( { 'line1' => $mixer.("." x $step) } );
		Slim::Utils::Timers::setTimer($client,$when,\&specialPushLeft,$step+1);
	}
}

1;

__END__
