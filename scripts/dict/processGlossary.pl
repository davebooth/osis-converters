sub getEntryScope($) {
  my $e = shift;

  my @eDiv = $XPC->findnodes('./ancestor-or-self::osis:div[@type="x-aggregate-subentry"]', $e);
  if (@eDiv && @eDiv[0]->getAttribute('scope')) {return @eDiv[0]->getAttribute('scope');}
  
  return &getGlossaryScope($e);
}

sub getGlossaryScope($) {
  my $e = shift;

  my @glossDiv = $XPC->findnodes('./ancestor-or-self::osis:div[@type="glossary"]', $e);
  if (!@glossDiv) {return '';}

  return @glossDiv[0]->getAttribute('scope');
}

# Returns names of filtered divs, or else '-1' if all were filtered or '0' if none were filtered
sub filterGlossaryToScope($$$) {
  my $osisP = shift;
  my $scope = shift;
  my $filterNavMenu = shift;
  
  my @removed;
  my @kept;
  
  my $xml = $XML_PARSER->parse_file($$osisP);
  my @glossDivs = $XPC->findnodes('//osis:div[@type="glossary"][not(@subType="x-aggregate")]', $xml);
  foreach my $div (@glossDivs) {
    my $divScope = &getGlossaryScope($div);
    
    # keep all glossary divs that don't specify a particular scope
    if (!$divScope) {push(@kept, $divScope); next;}
  
    # keep if any book within the glossary scope matches $scope
    my $bookOrderP; &getCanon($ConfEntryP->{"Versification"}, NULL, \$bookOrderP, NULL);
    if (&inGlossaryContext(&scopeToBooks($divScope, $bookOrderP), &getContexts($scope))) {
      push(@kept, $divScope);
      next;
    }
    
    # keep if this is NAVMENU or INT and we're not filtering them out
    if (!$filterNavMenu && $divScope =~ /^(NAVMENU|INT)$/) {push(@kept, $divScope); next;}
    
    $div->unbindNode();
    push(@removed, $divScope);
  }

  if (@removed == @glossDivs) {return '-1';}
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1filterGlossaryToScope$3/;
  open(OUTF, ">$output");
  print OUTF $xml->toString();
  close(OUTF);
  $$osisP = $output;
  
  return (@removed ? join(',', @removed):'0');
}

sub removeDuplicateEntries($) {
  my $osisP = shift;
  
  my $xml = $XML_PARSER->parse_file($$osisP);
  my @dels = $XPC->findnodes('//osis:div[contains(@type, "duplicate")]', $xml);
  foreach my $del (@dels) {$del->unbindNode();}
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1removeDuplicateEntries$3/;
  open(OUTF, ">$output");
  print OUTF $xml->toString();
  close(OUTF);
  $$osisP = $output;
  
  &Report(@dels." instance(s) of x-keyword-duplicate div removal.");
}

# Returns scopes of filtered entries, or else '-1' if all were filtered or '0' if none were filtered
sub filterAggregateEntries($$) {
  my $osisP = shift;
  my $scope = shift;
  
  my $xml = $XML_PARSER->parse_file($$osisP);
  my @check = $XPC->findnodes('//osis:div[@type="glossary"][@subType="x-aggregate"]//osis:div[@type="x-aggregate-subentry"]', $xml);
  my $bookOrderP; &getCanon($ConfEntryP->{"Versification"}, NULL, \$bookOrderP, NULL);
  
  my @removed; my $removeCount = 0;
  foreach my $subentry (@check) {
    my $glossScope = $subentry->getAttribute('scope');
    if ($glossScope && !&inGlossaryContext(&scopeToBooks($glossScope, $bookOrderP), &getContexts($scope))) {
      $subentry->unbindNode();
      my %scopes = map {$_ => 1} @removed;
      if (!$scopes{$glossScope}) {push(@removed, $glossScope);}
      $removeCount++;
    }
  }
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1filterAggregateEntries$3/;
  open(OUTF, ">$output");
  print OUTF $xml->toString();
  close(OUTF);
  $$osisP = $output;
  
  if ($removeCount == scalar(@check)) {&removeAggregateEntries($osisP);}
  
  return ($removeCount == scalar(@check) ? '-1':(@removed ? join(',', @removed):'0'));
}

sub removeAggregateEntries($) {
  my $osisP = shift;

  my $xml = $XML_PARSER->parse_file($$osisP);
  my @dels = $XPC->findnodes('//osis:div[@type="glossary"][@subType="x-aggregate"]', $xml);
  foreach my $del (@dels) {$del->unbindNode();}
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1removeAggregateEntries$3/;
  open(OUTF, ">$output");
  print OUTF $xml->toString();
  close(OUTF);
  $$osisP = $output;
}

# uppercase dictionary keys were necessary to avoid requiring ICU in SWORD.
# XSLT was not used to do this because a custom uc2() Perl function is needed.
sub upperCaseKeys($) {
  my $osisP = shift;
  
  my $xml = $XML_PARSER->parse_file($$osisP);
  if ($MODDRV =~ /LD/) {
    my @keywords = $XPC->findnodes('//*[local-name()="entryFree"]/@n', $xml);
    foreach my $keyword (@keywords) {$keyword->setValue(&uc2($keyword->getValue()));}
  }
  my @dictrefs = $XPC->findnodes('//*[local-name()="reference"][starts-with(@type, "x-gloss")]/@osisRef', $xml);
  foreach my $dictref (@dictrefs) {
    my $mod; my $e = &osisRef2Entry($dictref->getValue(), \$mod);
    $dictref->setValue(&entry2osisRef($mod, &uc2($e)));
  }
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1upperCaseKeys$3/;
  open(OSIS2, ">$output");
  print OSIS2 $xml->toString();
  close(OSIS2);
  $$osisP = $output;
}

1;
