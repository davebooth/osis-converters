# This file is part of "osis-converters".
# 
# Copyright 2015 John Austin (gpl.programs.info@gmail.com)
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

# This function adds cross-reference notes to a Bible OSIS file. But
# for valid cross-references to be added, the following requirements 
# must be met:
# 1) A set of cross-reference OSIS notes must be supplied in the form of 
#    an external xml file.
# 2) The external cross-reference notes must all exactly follow one of 
#    the standard SWORD verse systems (such as KJV, Synodal or SynodalProt).
# 3) The Bible OSIS file must exactly match the SWORD verse system of  
#    the cross-references.
# 4) The previous requirement means that if the Bible contains any verses 
#    which follow a different verse system than the cross-references 
#    (and this is very common), then those sections must have been marked
#    up and fitted by the fitToVerseSystem() function. However, in this 
#    case, the added cross-reference notes will be placed in the alternate 
#    location (and external references to verses in alternate locations 
#    will later also be modified to target that alternate location by 
#    correctReferencesVSYS() ).
sub runAddCrossRefs($) {
  my $osisP = shift;
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1addCrossRefs$3/;

  &Log("\n--- ADDING CROSS REFERENCES\n-----------------------------------------------------\n\n", 1);
  
  my $def = "bible/Cross_References/".(!$VERSESYS ? "KJV":$VERSESYS).".xml";
  my $CrossRefFile = &getDefaultFile($def, -1);
  if (!-e $CrossRefFile) {
    &Warn("Could not locate a Cross Reference source file: $def", "
The cross reference source file is an OSIS file that contains only 
cross-references for the necessary verse system: $VERSESYS. Without 
one, cross-references will not be added to the text. It should be 
typically placed in the following directory:
osis-converters/defaults/bible/CrossReferences/$VERSESYS.xml
The reference tags in the file do not need to contain presentational 
text, because it would be replaced with localized text anyway. 
Example OSIS cross-references:

<div type=\"book\" osisID=\"Gen\">
  <chapter osisID=\"Gen.1\">
  
    <note type=\"crossReference\" osisRef=\"Gen.1.27\" osisID=\"Gen.1.27!crossReference.r1\">
      <reference osisRef=\"Matt.19.4\"/>
      <reference osisRef=\"Mark.10.6\"/>
    </note>
    
    <note type=\"crossReference\" subType=\"x-parallel-passage\" osisRef=\"Gen.36.1\" osisID=\"Gen.36.1!crossReference.p1\">
      <reference osisRef=\"1Chr.1.35-1Chr.1.37\" type=\"parallel\"/>
   </note>
   
  </chapter>
</div>
");
    return 0;
  }
  
  my $bookNamesMsg = decode('utf8', 
"Cross-references are localized using a file called 
BookNames.xml in the sfm directory which should contain localized 
'abbr' abbreviations for all 66 Bible books, like this:

<?xml version=\"1.0\" encoding=\"utf-8\"?>
<BookNames>
  <book code=\"1SA\" abbr=\"1Şam\" />
  <book code=\"2SA\" abbr=\"2Şam\" />
</BookNames>

");

  &Log("READING OSIS FILE: \"$$osisP\".\n");
  my $osis = $XML_PARSER->parse_file($$osisP);
  &Log("You are including cross references for ".@{$XPC->findnodes('/osis:osis/osis:osisText/osis:header/osis:work[@osisWork=/osis:osis/osis:osisText/@osisIDWork]/osis:scope', $osis)}[0]->textContent.".\n");

  # Any presentational text will be removed from cross-references. Then localized  
  # note text will be added using Paratext meta-data and/or \toc tags.
  my %localization;
  my @files = split(/\n/, &shell("find \"$INPD/sfm\" -type f -exec grep -q \"<RangeIndicator>\" {} \\; -print", 3));
  if (@files[0]) {$ssf = $XML_PARSER->parse_file(@files[0]);}

  my %elems = (
    'RangeIndicator' => '-', 
    'SequenceIndicator' => ',', 
    'ReferenceFinalPunctuation' => '.', 
    'ChapterNumberSeparator' => '; ', 
    'ChapterRangeSeparator' => decode('utf8', '—'), 
    'ChapterVerseSeparator' => ':',
    'BookSequenceSeparator' => '; '
  );
  
  foreach my $k (keys %elems) {
    $v = $elems{$k};
    if ($ssf) {
      my $kv = @{$XPC->findnodes("$k", $ssf)}[0];
      if ($kv && $kv->textContent) {
        $v = $kv->textContent;
        &Note("<>Found localized Scripture reference settings in \"".@files[0]."\"");
      }
    }
    $localization{$k} = $v;
  }
  foreach my $x (sort keys %elems) {&Note("$x = '".$localization{$x}."'");}
  
  # find the shortest name in BOOKNAMES and x-usfm-toc milestones, prefering BOOKNAMES when equal length
  my $countLocalizedNames = 0;
  my @bntypes = ('long', 'short', 'abbr');
  my @books = split(/\s+/, $OT_BOOKS.' '.$NT_BOOKS);
  foreach my $book (@books) {
    my %osisName;
    for (my $x=1; $x<=3; $x++) {
      my $n = @{$XPC->findnodes('//osis:div[@type="book"][@osisID="'.$book.'"]/descendant::osis:milestone[@type="x-usfm-toc'.$x.'"][1]/@n', $osis)}[0];
      if ($n) {$osisName{'toc'.$x} = $n->value;}
    }
    my $shortName;
    for (my $x=1; $x<=3; $x++) {
      if (!$osisName{'toc'.$x}) {next;}
      if ($shortName && length($shortName) < length($osisName{'toc'.$x})) {next;}
      $shortName = $osisName{'toc'.$x};
    }
    for (my $x=0; $x<@bntypes; $x++) {
      if (!$BOOKNAMES{$book}{@bntypes[$x]}) {next;}
      if ($shortName && length($shortName) < length($BOOKNAMES{$book}{@bntypes[$x]})) {next;}
      $shortName = $BOOKNAMES{$book}{@bntypes[$x]};
    }
    if ($shortName) {
      if (!$osisName{'toc3'} && !$BOOKNAMES{$book}{@bntypes[2]}) {
        &Warn("A localized book abbreviation for \"$book\" was not found in a \\toc3 USFM tag or 'abbr' attribute of BookNames.xml file.", 
"<>A Longer book name will be used instead. This will increase
the length of externally added cross-reference notes considerably. If 
you want to shorten them, supply either an 'abbr' attribute value to 
BookNames.xml or add a \\toc3 USFM tag to the top of the USFM file, with 
the abbreviation.");
      }
    
      $countLocalizedNames++;
      $localization{$book} = $shortName;
      &Note("$book = $shortName");
    }
    else {&Warn("Missing translation for \"$book\".", 
"<>That all 66 Bible books have, preferably, the 'abbr' attribute set 
in BookNames.xml. Or else another attribute in BookNames.xml will be 
used, if available, or else \\toc1, \\toc2 or \\toc3 tags in SFM files
will be used. Since none of these were found for some books, some 
cross-references will be unreadable.\n$bookNamesMsg");}
  }
  
  if ($countLocalizedNames == 66) {
    $localization{'hasLocalization'}++;
    &Note("Applying localization to all cross references.");
  }
  else {
    &Warn(
"Unable to localize all book names. This means eBooks will show 
cross-references as '1', '2'... which is very unhelpful.\n", $bookNamesMsg);
  }
  
  # for a big speed-up, find all verse tags and add them to a hash with a key for every verse
  my %verses;
  foreach my $v ($XPC->findnodes('//osis:verse', $osis)) {
    my $type = 'start'; my $seID = $v->getAttribute('sID');
    if (!$seID) {$type = 'end'; $seID = $v->getAttribute('eID');}
    foreach my $osisIDV (split(/\s+/, $seID)) {$verses{$osisIDV}{$type} = $v;}
  }

  &Log("READING CROSS REFERENCE FILE \"$CrossRefFile\".\n");
  my $xml = $XML_PARSER->parse_file($CrossRefFile);
  
  foreach my $alt ($XPC->findnodes('//osis:hi[@subType="x-alternate"]', $osis)) {
    $INSERT_NOTE_SPEEDUP{@{$XPC->findnodes('following::osis:verse[@eID][1]', $alt)}[0]->getAttribute('eID')}++;
  }
  
  my $movedP = &getAltVersesOSIS($osis);
  my $osisBooksHP = &getBooksOSIS($osis);
  foreach my $note ($XPC->findnodes('//osis:note', $xml)) {
    foreach my $t ($note->childNodes()) {if ($t->nodeType == XML::LibXML::XML_TEXT_NODE) {$t->unbindNode();}}
    
    # decide where to place this note
    my $fixed = $note->getAttribute('osisID');
    $fixed =~ s/^(.*?)(\!.*)?$/$1/;
    $fixed =~ s/^[^\:]*\://;
    
    # map crossReferences to be placed within verses that were moved by translators from their fixed verse-system positions
    my $placement = ($movedP->{'fixed2Alt'}{$fixed} ? $movedP->{'fixed2Fixed'}{$fixed}:$fixed);
    
    # check and filter the note placement
    if ($placement =~ /\.0\b/) {
      &ErrorBug("Cross reference notes should not be placed in an introduction: $placement =~ /\.0\b/");
      next;
    }
    if ($placement !~ /^([^\.]+)\.(\d+)\.(\d+)$/) {
      &ErrorBug("CrossReference has unexpected placement: $placement !~ /^([^\.]+)\.(\d+)\.(\d+)\$/");
      next;
    }
    my $b = $1; my $c = $2; my $v = $3;
    if (!$osisBooksHP->{$b}) {next;}
    if (!$verses{$placement}) {next;}
    
    # add annotateRef so readers know where the note belongs
    my $annotateRef = ($movedP->{'fixed2Alt'}{$fixed} ? $movedP->{'fixed2Alt'}{$fixed}:$fixed);
    if ($localization{'hasLocalization'} && $annotateRef =~ /^([^\.]+)\.(\d+)\.(\d+)$/) {
      my $bk = $1; my $ch = $2; my $vs = $3;
      # later, the fixed verse system osisRef here will get mapped and annotateRef added, by correctReferencesVSYS()
      my $elem = "<reference osisRef=\"$fixed\" type=\"annotateRef\">$ch".$localization{'ChapterVerseSeparator'}."$vs</reference> ";
      $note->insertBefore($XML_PARSER->parse_balanced_chunk($elem), $note->firstChild);
    }
    
    # add resp attribute, which identifies this note as an external note
    $note->setAttribute('resp', &getOsisIDWork($xml)."-".&getVerseSystemOSIS($xml));  
    &insertNote($note, $fixed, \%verses, $movedP, \%localization);
  }

  &Log("WRITING NEW OSIS FILE: \"$output\".\n");
  if (open(OUTF, ">$output")) {
    print OUTF $osis->toString();
    close(OUTF);
    $$osisP = $output;
  }
  else {&ErrorBug("Could not open \"$output\" for writing.");}

  $ADD_CROSS_REF_LOC = ($ADD_CROSS_REF_LOC ? $ADD_CROSS_REF_LOC:0);
  $ADD_CROSS_REF_NUM = ($ADD_CROSS_REF_NUM ? $ADD_CROSS_REF_NUM:0);
  &Log("\n");
  &Report("Placed $ADD_CROSS_REF_NUM cross-reference notes.");
  if ($ADD_CROSS_REF_BAD) {
    &Error("$ADD_CROSS_REF_LOC individual reference links were localized but $ADD_CROSS_REF_BAD could only be numbered.", "
Add the missing book abbreviations with either a \\toc3 tag in the SFM
file, or else with an 'abbr' entry in the BookNames.xml file.");
  }
  else {
    &Note("$ADD_CROSS_REF_LOC individual reference links were localized.\n");
  }
  
  return 1;
}

# Insert the note near the beginning or end of the verse depending on type.
# Normal cross-references go near the end, but parallel passages go near the 
# beginning of the verse. Sometimes a verse contains alternate verses within
# itself, and in this case, altVerseID is used to place the note within the 
# appropriate alternate verse.
sub insertNote($$\%\%\%) {
  my $note = shift;
  my $fixed = shift;
  my $verseP = shift;
  my $movedP = shift;
  my $localeP = shift;
  
  my $verseNum = ($movedP->{'fixed2Alt'}{$fixed} =~ /\.(\d+)$/ ? $1:'');
  my $placement = ($movedP->{'fixed2Alt'}{$fixed} ? $movedP->{'fixed2Fixed'}{$fixed}:$fixed);
  $verseP = \%{$verseP->{$placement}};
  
  # add readable reference text to the note's references (required by some front ends and eBooks)
  my @refs = $XPC->findnodes('osis:reference[@osisRef][not(@type="annotateRef")]', $note);
  for (my $i=0; $i<@refs; $i++) {
    my $ref = @refs[$i];
    my $osisRef = $ref->getAttribute('osisRef');
    if ($osisRef =~ s/^.*?://) {$ref->setAttribute('osisRef', $osisRef);}
    foreach my $child ($ref->childNodes()) {$child->unbindNode();}
    my $t;
    if ($localeP->{'hasLocalization'}) {
      # later, any fixed verse system osisRef here will get mapped and annotateRef added, by correctReferencesVSYS()
      my $readRef = ($movedP->{'fixed2Alt'}{$osisRef} ? $movedP->{'fixed2Alt'}{$osisRef}:$osisRef);
      my $tr = &translateRef($readRef, $localeP);
      if ($tr) {$ADD_CROSS_REF_LOC++;} else {$ADD_CROSS_REF_BAD++;}
      $t = ($i==0 ? '':' ') . ($tr ? $tr:($i+1)) . ($i==@refs-1 ? '':$localeP->{'SequenceIndicator'});
    }
    else {$t = sprintf("%i%s", $i+1, ($i==@refs-1 ? '':','));}
    $ref->insertAfter(XML::LibXML::Text->new($t), undef);
  }

  # insert note in the right place
  # NOTE: the crazy looking while loop approach, and not using normalize-space() but rather $nt =~ /^\s*$/, greatly increases processing speed
  if ($note->getAttribute('subType') eq 'x-parallel-passage') {
    my $start = $verseP->{'start'};
    if ($verseNum) {
      while (my $alt = @{$XPC->findnodes('following::osis:hi[@subType="x-alternate"][1][following::osis:verse[1][@eID="'.$verseP->{'end'}->getAttribute('eID').'"]]', $start)}[0]) {
        $start = $alt;
        if ($start->textContent =~ /\b$verseNum\b/) {last;}
      }
    }
    my $nt = @{$XPC->findnodes('following::text()[1]', $start)}[0];
    while ($nt) {
      if ($nt =~ /^\s*$/ || (my $title = @{$XPC->findnodes('ancestor::osis:title[not(@canonical="true")]', $nt)}[0])) { # next text
        $nt = @{$XPC->findnodes('following::text()[1]', $nt)}[0];
      }
      elsif (my $n = @{$XPC->findnodes('ancestor::osis:note', $nt)}[0]) {$n->parentNode->insertAfter($note, $n); last;} # insert after
      elsif (my $reference = @{$XPC->findnodes('ancestor::osis:reference', $nt)}[0]) {$reference->parentNode->insertBefore($note, $reference); last;} #insert before
      else {$nt->parentNode->insertBefore($note, $nt); last;}
    }
    if ($nt) {$ADD_CROSS_REF_NUM++;}
    else {&ErrorBug("Failed to place parallel passage reference note: \"".$note->toString()."\".");}
  }
  else {
    my $end = $verseP->{'end'};
    if ($INSERT_NOTE_SPEEDUP{$verseP->{'end'}->getAttribute('eID')}) {
      while (my $alt = @{$XPC->findnodes('preceding::osis:hi[@subType="x-alternate"][1][preceding::osis:verse[1][@sID="'.$verseP->{'start'}->getAttribute('sID').'"]]', $end)}[0]) {
        if (!$alt || ($verseNum && $alt->textContent =~ /\b$verseNum\b/) || 
           !@{$XPC->findnodes('preceding::text()[normalize-space()][1][preceding::osis:verse[1][@sID="'.$verseP->{'start'}->getAttribute('sID').'"]]', $alt)}[0]
         ) {last;}
        $end = $alt;
      }
    }
    $pt = @{$XPC->findnodes('preceding::text()[1]', $end)}[0];
    while ($pt) {
      if ($pt =~ /^\s*$/ || (my $title = @{$XPC->findnodes('ancestor::osis:title[not(@canonical="true")] | ancestor::osis:l[@type="selah"]', $pt)}[0])) { # next text
        $pt = @{$XPC->findnodes('preceding::text()[1]', $pt)}[0];
      }
      elsif (my $n = @{$XPC->findnodes('ancestor::osis:note', $pt)}[0]) {$n->parentNode->insertAfter($note, $n); last;} # insert after
      elsif (my $reference = @{$XPC->findnodes('ancestor::osis:reference', $pt)}[0]) {$reference->parentNode->insertAfter($note, $reference); last;} # insert after
      else {
        my $punc = '';
        my $txt = $pt->nodeValue();
        if ($txt =~ s/([\.\?\s]+)$//) {
          $punc = $1;
          $pt->setData($txt);
        }
        $pt->parentNode->insertAfter($note, $pt);
        if ($punc) {$note->parentNode->insertAfter(XML::LibXML::Text->new($punc), $note);}
        last;
      }
    }
    if ($pt) {$ADD_CROSS_REF_NUM++;}
    else {&ErrorBug("Failed to place cross reference note: \"".$note->toString()."\".");}
  }
}

sub translateRef($$) {
  my $osisRef = shift;
  my $localeP = shift;
  
  my $t = '';
  if ($osisRef =~ /^([\w\.]+)(\-([\w\.]+))?$/) {
    my $r1 = $1; my $r2 = ($2 ? $3:'');
    $t = &translateSingleRef($r1, $localeP);
    if ($t && $r2) {
      my $t2 = &translateSingleRef($r2, $localeP);
      if ($t2) {
        if ($t =~ /^(.*?)\d+$/) {
          my $baseRE = "^$1(\\d+)\$";
          if ($t2 =~ /$baseRE/) {$t2 = $1;}
        }
        $t .= $localeP->{'RangeIndicator'} . $t2;
      }
      else {$t = '';}
    }
  }
  else {
    &ErrorBug("Malformed osisRef: $osisRef !~ /^([\w\.]+)(\-([\w\.]+))?\$/");
  }
  
  return $t;
}

sub translateSingleRef($$) {
  my $osisRefSingle = shift;
  my $localeP = shift;

  my $t = '';
  if ($osisRefSingle =~ /^([^\.]+)(\.([^\.]+)(\.([^\.]+))?)?/) {
    my $b = $1; my $c = ($2 ? $3:''); my $v = ($4 ? $5:'');
    if ($localeP->{$b}) {
      $t = $localeP->{$b} . ($c ? ' ' . $c . ($v ? $localeP->{'ChapterVerseSeparator'} . $v:''):'');
    }
    else {$t = '';}
  }
  else {
    &ErrorBug("Malformed osisRef: $osisRefSingle !~ /^([^\.]+)(\.([^\.]+)(\.([^\.]+))?)?/");
  }
  
  return $t;
}

1;
