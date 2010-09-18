# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is IRC Auto Downloader
#
# The Initial Developer of the Original Code is
# David Nilsson.
# Portions created by the Initial Developer are Copyright (C) 2010
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#
# ***** END LICENSE BLOCK *****

#
# Reads and writes the ~/.autodl/AutodlState.xml file
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::AutodlState;
use AutodlIrssi::XmlParser;
use AutodlIrssi::FileUtils;
use base qw/ AutodlIrssi::XmlParser /;

# Reads settings from the saved file
sub read {
	my ($self, $filename) = @_;

	my $autodlState = {
		trackersVersion => -1,
		trackerStates => {},
	};

	return $autodlState unless -f $filename;
	my $doc = $self->openFile($filename);
	return $autodlState unless defined $doc;

	my $autodlElem = $self->getTheChildElement($doc, "autodl");

	my $trackersVersionElem = $self->getOptionalChildElement($autodlElem, "trackers-version");
	if ($trackersVersionElem) {
		$autodlState->{trackersVersion} = $self->readTextNodeInteger($trackersVersionElem, undef, -1);
	}

	my $trackersElem = $self->getTheChildElement($autodlElem, "trackers");
	my @trackerElems = $self->getChildElementsByTagName($trackersElem, "tracker");
	for my $trackerElem (@trackerElems) {
		my $trackerType = $self->readAttribute($trackerElem, "type");
		die "Invalid tracker type\n" unless defined $trackerType && $trackerType ne "";
		my $lastAnnounce = $self->readTextNodeInteger($trackerElem, "last-announce");

		$autodlState->{trackerStates}{$trackerType} = {
			lastAnnounce => $lastAnnounce,
		};
	}

	return $autodlState;
}

sub write {
	my ($self, $filename, $autodlState) = @_;

	my $doc = $self->createDocument();
	my $autodlElem = $doc->createElement("autodl");
	$doc->setDocumentElement($autodlElem);

	my $trackersVersionElem = $doc->createElement("trackers-version");
	$autodlElem->appendChild($trackersVersionElem);
	$trackersVersionElem->appendChild($doc->createTextNode($autodlState->{trackersVersion}));

	my $trackersElem = $doc->createElement("trackers");
	$autodlElem->appendChild($trackersElem);

	while (my ($trackerType, $info) = each %{$autodlState->{trackerStates}}) {
		my $trackerElem = $doc->createElement("tracker");
		$trackersElem->appendChild($trackerElem);

		$trackerElem->setAttribute("type", $trackerType);

		my $lastAnnounce = defined $info->{lastAnnounce} ? $info->{lastAnnounce} : "";
		my $lastAnnounceElem = $doc->createElement("last-announce");
		$lastAnnounceElem->appendChild($doc->createTextNode($lastAnnounce));

		$trackerElem->appendChild($lastAnnounceElem);
	}

	saveRawDataToFile($filename, $doc->toString(1));
}

1;