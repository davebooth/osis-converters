#!/usr/bin/perl
# This file is part of "osis-converters".
# 
# Copyright 2019 John Austin (gpl.programs.info@gmail.com)
#     
# "osis-converters" is free software: you can redistribute it and/or 
# modify it under the terms of the GNU General Public License as 
# published by the Free Software Foundation, either version 2 of 
# the License, or (at your option) any later version.
# 
# "osis-converters" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with "osis-converters".  If not, see 
# <http://www.gnu.org/licenses/>.

sub getGlossaryScopeAttribute($) {
  my $e = shift;
  
  my $eDiv = @{$XPC->findnodes('./ancestor-or-self::osis:div[@type="x-aggregate-subentry"]', $e)}[0];
  if ($eDiv && $eDiv->getAttribute('scope')) {return $eDiv->getAttribute('scope');}

  my $glossDiv = @{$XPC->findnodes('./ancestor-or-self::osis:div[@type="glossary"]', $e)}[0];
  if ($glossDiv) {return $glossDiv->getAttribute('scope');}

  return '';
}

# Returns names of filtered divs, or else '-1' if all would be filtered or '0' if none would be filtered
sub filterGlossaryToScope($$$) {
  my $osisP = shift;
  my $scope = shift;
  my $filterNavMenu = shift;
  
  my @removed;
  my @kept;
  
  my $xml = $XML_PARSER->parse_file($$osisP);
  my @glossDivs = $XPC->findnodes('//osis:div[@type="glossary"][not(@subType="x-aggregate")]', $xml);
  my %glossScopes;
  foreach my $div (@glossDivs) {
    my $divScope = &getGlossaryScopeAttribute($div);
    
    # keep all glossary divs that don't specify a particular scope
    if (!$divScope) {push(@kept, $divScope); next;}
  
    # keep if any book within the glossary scope matches $scope
    my $bookOrderP; &getCanon(&conf("Versification"), NULL, \$bookOrderP, NULL);
    if (&inContext(&getScopeAttributeContext($divScope, $bookOrderP), &getContextAttributeHash($scope))) {
      if ($div->getAttribute('resp') eq $ROC) {$glossScopes{$divScope}++;}
      push(@kept, $divScope);
      next;
    }
    
    # keep if this is NAVMENU or INT and we're not filtering them out
    if (!$filterNavMenu && $divScope =~ /^(NAVMENU|INT)$/) {
      if ($div->getAttribute('resp') eq $ROC) {$glossScopes{$divScope}++;}
      push(@kept, $divScope);
      next;
    }
    
    $div->unbindNode();
    push(@removed, $divScope);
  }

  if (!@removed) {return '0';}
  
  # since at least one keyword was filtered out, some built in keyword navmenus are now wrong, so just remove them all to be sure
  foreach my $nm ($XPC->findnodes('//osis:div[starts-with(@type, "x-keyword")]/descendant::osis:item[@subType="x-prevnext-link"]', $xml)) {
    $nm->unbindNode();
  }

  if (@removed == @glossDivs) {return '-1';}
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1filterGlossaryToScope$3/;
  &writeXMLFile($xml, $output, $osisP);
  
  return join(',', @removed);
}

# Returns scopes of filtered entries, or else '-1' if all were filtered or '0' if none were filtered
sub filterAggregateEntries($$) {
  my $osisP = shift;
  my $scope = shift;
  
  my $xml = $XML_PARSER->parse_file($$osisP);
  my @check = $XPC->findnodes('//osis:div[@type="glossary"][@subType="x-aggregate"]//osis:div[@type="x-aggregate-subentry"]', $xml);
  my $bookOrderP; &getCanon(&conf("Versification"), NULL, \$bookOrderP, NULL);
  
  my @removed; my $removeCount = 0;
  foreach my $subentry (@check) {
    my $glossScope = $subentry->getAttribute('scope');
    if ($glossScope && !&inContext(&getScopeAttributeContext($glossScope, $bookOrderP), &getContextAttributeHash($scope))) {
      $subentry->unbindNode();
      my %scopes = map {$_ => 1} @removed;
      if (!$scopes{$glossScope}) {push(@removed, $glossScope);}
      $removeCount++;
    }
  }
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1filterAggregateEntries$3/;
  &writeXMLFile($xml, $output, $osisP);
  
  if ($removeCount == scalar(@check)) {&removeAggregateEntries($osisP);}
  
  return ($removeCount == scalar(@check) ? '-1':(@removed ? join(',', @removed):'0'));
}

sub removeAggregateEntries($) {
  my $osisP = shift;

  my $xml = $XML_PARSER->parse_file($$osisP);
  my @dels = $XPC->findnodes('//osis:div[@type="glossary"][@subType="x-aggregate"]', $xml);
  foreach my $del (@dels) {$del->unbindNode();}
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1removeAggregateEntries$3/;
  &writeXMLFile($xml, $output, $osisP);
}

# uppercase dictionary keys were necessary to avoid requiring ICU in SWORD.
# XSLT was not used to do this because a custom uc2() Perl function is needed.
sub upperCaseKeys($) {
  my $osis_or_teiP = shift;
  
  my $xml = $XML_PARSER->parse_file($$osis_or_teiP);
  if (&conf('ModDrv') =~ /LD/) {
    my @keywords = $XPC->findnodes('//*[local-name()="entryFree"]/@n', $xml);
    foreach my $keyword (@keywords) {$keyword->setValue(&uc2($keyword->getValue()));}
  }
  my @dictrefs = $XPC->findnodes('//*[local-name()="reference"][starts-with(@type, "x-gloss")]/@osisRef', $xml);
  foreach my $dictref (@dictrefs) {
    my $mod; my $e = &osisRef2Entry($dictref->getValue(), \$mod);
    $dictref->setValue(&entry2osisRef($mod, &uc2($e)));
  }
  my $output = $$osis_or_teiP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1upperCaseKeys$3/;
  &writeXMLFile($xml, $output, $osis_or_teiP);
}

1;
