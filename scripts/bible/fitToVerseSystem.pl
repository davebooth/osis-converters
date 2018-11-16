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

$fitToVerseSystemDoc = "
------------------------------------------------------------------------
------------------------------------------------------------------------
OSIS-CONVERTERS VERSIFICATION INSTRUCTIONS:
The goal is to fit a source Bible translation having a custom verse 
system into a known fixed versification system so that every verse of 
the source system is identified according to the known system. Both the 
fixed and the source verse systems are recorded together in a single 
OSIS file. This process should be as easy as possible for the person 
running the conversion, so only differences between the source and fixed 
verse systems need to be identified, using the small set of instructions
described below. Also the Bible translation can be easily read from the 
OSIS file (for instance using a simple XSLT) with either the source or 
fixed verse system, while at the same time all Scripture references will 
be correct according to the chosen verse system.

IMPORANT:
In the following descriptions, this:
BK.1.2.3
means this:
Bible book 'BK' chapter '1' verse '2' through '3', or, BK 1:2-3

VSYS_MOVED: BK.1.2.3 -> BK.4.5.6
Specifies that this translation has moved the verses that would be found 
in a range of the fixed verse system to a different position in the 
source verse system, indicated by the range to the right of '->'. The 
two ranges must be the same size. It is processed as: 
VSYS_MISSING: <fixed-vsys-range> 
then:
VSYS_EXTRA: <source-vsys-range>
followed by: 
VSYS_FROM_TO <fixed-vsys-range> <source-vsys-range> 
The end verse portion of either range may be the keyword 'PART' (such as 
Gen.4.7.PART), meaning that the reference applies to only part of the 
specified verse. Furthermore the VSYS_MOVED instruction also updates the 
hyperlink targets of externally supplied Scripture cross-references so 
that they correctly point to their moved location in the source and 
fitted verse systems.

VSYS_MISSING: BK.1.2.3
Specifies that this translation does not include a range of verses of
the fixed verse system. So the fitted verse system will have the 
preceeding extant verse id modified to span the missing range, but in no 
case exceeding the end of a chapter. Any externally supplied cross-
references to the missing verses will then be removed. Also, if there 
are source verse(s) already sharing the verse number(s) of the missing 
verse(s), then these, as well as any following verses in the chapter 
will be renumbered upward by the number of missing verses, and alternate 
verse numbers will be appended to them displaying their original source 
verse system number. Additionally in the case of renumbered verses, 
externally supplied Scripture cross-reference to these verses are 
updated so as to be correct for both the source and fitted verse 
systems. Entire missing chapters are not supported.

VSYS_EXTRA: BK.1.2.3
Specifies that the source verse system includes an extra range of verses 
which are not there in the fixed verse system. So for the fitted verse 
system, the additional verse(s) will be converted to alternate verse(s) 
and appended to the preceding extant verse in the fixed verse system. 
Also, if there are any verses following the extra verses in the source 
verse system, then these will be renumbered downward by the number of 
extra verses, and alternate verse numbers will be appended to display  
their original verse number(s) in the source verse system. Additionally 
in the case of renumbered verses, externally supplied Scripture cross-
reference to these verses are updated so as to be correct for both the 
source and fitted verse systems. The extra verse range may be an entire 
chapter if it occurs at the end of a book (like Psalm 151), in which 
case an alternate chapter number will be inserted and the entire extra 
chapter will be appended to the last verse of the previous extant 
chapter.

VSYS_MOVED_ALT: 
Similar to VSYS_MOVED but this should be used when alternate verse 
markup like '\va 2\va*' has already been used by the translators for the 
moved verses (rather than regular verse markers, which is the more 
common case). This instruction will not change the OSIS markup of the 
alternate verses. It is the same as 'VSYS_MISSING: A' followed by 
'VSYS_FROM_TO: A -> B'.

VSYS_MISSING_FN:
Same as VSYS_MISSING but it only accepts a single verse and is only used 
if a footnote was included in the verse before the missing verse which 
addresses the missing verse. This will forward references to the 
missing verses to the previous verse which contains the footnote. This 
instruction is the same as a VSYS_MISSING followed by a VSYS_FROM_TO 
instruction.

VSYS_EMPTY: BK.1.2.3
Use this if regular verse markers are included in the text, however the 
verses are left empty. This will just remove external Scripture 
cross-references to the removed verse(s).

VSYS_FROM_TO: BK.1.2.3 -> BK.4.5.6
This does not effect any verse or alternate verse markup or locations. 
It only allows references in the source and fixed verse systems to have 
their addresses forwarded to their location in the fitted verse system 
and to each other. It also allows the human readable portion of external 
cross-references to be updated to their locations in the source verse 
system. It could be used if a verse is marked in the text but is left 
empty, while there is a footnote about it in the previous verse (but see 
VSYS_MISSING_FN which is the more common case). VSYS_FROM_TO is usually 
not the right instruction for most use cases, but it is used most often 
internally.

SET_customBookOrder:true
Turns off the book re-ordering step so books will remain in processed 
order.

NOTES:
- Each instruction is evaluated in fixed verse system order regardless 
of their order in the CF_ file.
- A verse may be effected by multiple instructions.
- This implementation does not accomodate extra books, or ranges of 
chapters, and whole chapters are only supported with VSYS_EXTRA for
chapters at the end of a book, where the chapter was simply appended 
(such as Psalm 151 of Synodal).
------------------------------------------------------------------------
------------------------------------------------------------------------

";

$verseSystemDoc = "
------------------------------------------------------------------------
------------------------------------------------------------------------
OSIS-CONVERTERS VERSIFICATION SYSTEM:
Special milestone markers are added to the OSIS file to facilitate 
reference mapping between the source, fixed and fitted verse systems:
source: The custom source verse system created by the translators. 
        Because it is a unique and customized verse system, by itself 
        there is no way to link its verses with external texts or 
        cross-references.
fixed:  A known, unchanging, verse system which is most similar to the 
        source verse system. Because it is a known verse system, its 
        verses can be linked to any other known external text or 
        cross-reference.
fitted: A fusion between the source and fixed verse systems arrived at 
        by applying OSIS-CONVERTERS VERSIFICATION INSTRUCTIONS. The 
        fitted verse system maintains the exact form of the custom verse 
        system, but also exactly fits within the fixed verse system. The
        resulting fitted verse system will have 'missing' verses or 
        'extra' alternate verses appended to the end of a verse if there 
        are differences between the source and fixed verse systems. 
        These differences usually represent moved, split, or joined 
        verses. The OSIS file can then be extracted in either the source 
        or the fixed verse system in such a way that all internal and  
        external reference hyperlinks are made correct and functional.
        
The fitted verse system requires that applicable reference links have 
two osisRef attributes, one for the fixed verse system (osisRef) and 
another for the source (annotateRef with annotateType = source). To 
facilitate this, the following maps are provided:
1) fixed2Source: Given a verse in the fixed verse system, get the id of 
   the source verse system verse which corresponds to it. This is needed 
   to map a readable externally supplied cross-reference in the fixed 
   verse system to the moved location in the source verse system. 
   Example: A fixed verse system cross-reference targets Romans 14:24, 
   but in the source verse system this verse is at Romans 16:25.
2) source2Fitted: Given a verse in the source verse system, get the id 
   of the fitted (fixed verse system) verse which contains it. This is 
   needed to map source references to their location in the fitted verse 
   system. Example: Source verse Rom.16.25 might correspond to a 
   different location in the fixed verse system, but in the fitted 
   (fixed) verse system it is appended to the end of Rom.16.24 (the last 
   verse of the fixed verse system's chapter).
3) fixed2Fitted: Given a verse in the fixed verse system, get the id of 
   the fitted (also a fixed verse system) verse which contains it. This  
   is used to map externally supplied cross-references for the fixed 
   verse system to their actual location in the fitted verse system. 
   Example: A fixed verse system cross-reference targets Rom.14.24, 
   but in the fitted OSIS file, this verse is appended to the end of 
   Rom.16.24. This is a convenience map since it is the same 
   as source2Fitted{fixed2Source{verse}}
4) missing: If a fixed verse system verse is left out of the translation
   and is not even included in a footnote, then there will be no cross
   references pointing to it.
------------------------------------------------------------------------
------------------------------------------------------------------------

";

# The following MAPs were taken from usfm2osis.py and apply to USFM 2.4
%ID_TYPE_MAP = (
  # File ID code => <div> type attribute value
  'FRT' => 'front',
  'INT' => 'introduction',
  'BAK' => 'back',
  'CNC' => 'concordance',
  'GLO' => 'glossary',
  'TDX' => 'index',
  'NDX' => 'gazetteer',
  'OTH' => 'x-other'
);
%ID_TYPE_MAP_R = reverse %ID_TYPE_MAP;

%PERIPH_TYPE_MAP = (
  # Text following \periph => <div> type attribute value
  'Title Page' => 'titlePage', 
  'Half Title Page' => 'x-halfTitlePage', 
  'Promotional Page' => 'x-promotionalPage',
  'Imprimatur' => 'imprimatur', 
  'Publication Data' => 'publicationData', 
  'Foreword' => 'x-foreword', 
  'Preface' => 'preface',
  'Table of Contents' => 'tableofContents', 
  'Alphabetical Contents' => 'x-alphabeticalContents',
  'Table of Abbreviations' => 'x-tableofAbbreviations', 
  'Chronology' => 'x-chronology',
  'Weights and Measures' => 'x-weightsandMeasures', 
  'Map Index' => 'x-mapIndex',
  'NT Quotes from LXX' => 'x-ntQuotesfromLXX', 
  'Cover' => 'coverPage', 
  'Spine' => 'x-spine', 
  'Tables' => 'x-tables', 
  'Verses for Daily Living' => 'x-dailyVerses',
  'Bible Introduction' => 'introduction', 
  'Old Testament Introduction' => 'introduction',
  'Pentateuch Introduction' => 'introduction', 
  'History Introduction' => 'introduction', 
  'Poetry Introduction' => 'introduction',
  'Prophecy Introduction' => 'introduction', 
  'New Testament Introduction' => 'introduction',
  'Gospels Introduction' => 'introduction', 
  'Acts Introduction' => 'introduction', 
  'Epistles Introduction' => 'introduction',
  'Letters Introduction' => 'introduction', 
  'Deuterocanon Introduction' => 'introduction'
);
%PERIPH_TYPE_MAP_R = reverse %PERIPH_TYPE_MAP;

%PERIPH_SUBTYPE_MAP = (
  # Text following \periph => <div type=introduction"> subType attribute value
  'Bible Introduction' => 'x-bible', 
  'Old Testament Introduction' => 'x-oldTestament',
  'Pentateuch Introduction' => 'x-pentateuch', 
  'History Introduction' => 'x-history', 
  'Poetry Introduction' => 'x-poetry',
  'Prophecy Introduction' => 'x-prophecy', 
  'New Testament Introduction' => 'x-newTestament',
  'Gospels Introduction' => 'x-gospels', 
  'Acts Introduction' => 'x-acts', 
  'Epistles Introduction' => 'x-epistles',
  'Letters Introduction' => 'x-letters', 
  'Deuterocanon Introduction' => 'x-deuterocanon'
);
%PERIPH_SUBTYPE_MAP_R = reverse %PERIPH_SUBTYPE_MAP;

%USFM_DEFAULT_PERIPH_TARGET = (
  'Cover|Title Page|Half Title Page|Promotional Page|Imprimatur|Publication Data|Table of Contents|Table of Abbreviations|Bible Introduction|Foreword|Preface|Chronology|Weights and Measures|Map Index' => 'place-according-to-scope',
  'Old Testament Introduction' => 'osis:div[@type="bookGroup"][1]/node()[1]',
  'NT Quotes from LXX' => 'osis:div[@type="bookGroup"][last()]/node()[1]',
  'Pentateuch Introduction' => 'osis:div[@type="book"][@osisID="Gen"]',
  'History Introduction' => 'osis:div[@type="book"][@osisID="Josh"]',
  'Poetry Introduction' => 'osis:div[@type="book"][@osisID="Ps"]',
  'Prophecy Introduction' => 'osis:div[@type="book"][@osisID="Isa"]',
  'New Testament Introduction' => 'osis:div[@type="bookGroup"][2]/node()[1]',
  'Gospels Introduction' => 'osis:div[@type="book"][@osisID="Matt"]',
  'Acts Introduction' => 'osis:div[@type="book"][@osisID="Acts"]/node()[1]',
  'Letters Introduction' => 'osis:div[@type="book"][@osisID="Acts"]',
  'Deuterocanon Introduction' => 'osis:div[@type="book"][@osisID="Tob"]'
);

sub orderBooksPeriphs($$$) {
  my $osisP = shift;
  my $vsys = shift;
  my $maintainBookOrder = shift;
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1orderBooksPeriphs$3/;
  
  if (!$vsys) {$vsys = "KJV";}

  &Log("\nOrdering books and peripherals of \"$$osisP\" by versification $vsys\n", 1);

  my $canonP; my $bookOrderP; my $testamentP; my $bookArrayP;
  if (!&getCanon($vsys, \$canonP, \$bookOrderP, \$testamentP, \$bookArrayP)) {
    &ErrorBug("Cannot re-order books in OSIS file because getCanon($vsys) failed.");
    return;
  }

  my $xml = $XML_PARSER->parse_file($$osisP);

  # remove all books
  my @books = $XPC->findnodes('//osis:div[@type="book"]', $xml);
  foreach my $bk (@books) {$bk->unbindNode();}

  # remove all peripheral file divs
  my $xpath;
  my $sep;
  foreach my $type (values(%ID_TYPE_MAP)) {
    $xpath .= $sep.'//osis:div[@type="'.$type.'"][not(@subType)]';
    $sep = '|';
  }
  my @periphFiles = $XPC->findnodes($xpath, $xml);
  foreach my $periphFile (@periphFiles) {$periphFile->unbindNode();}
  
  # create empty bookGroups
  my $osisText = @{$XPC->findnodes('//osis:osisText', $xml)}[0];
  my $bg;
  $bg = $osisText->addNewChild("http://www.bibletechnologies.net/2003/OSIS/namespace", 'div'); $bg->setAttribute('type', 'bookGroup');
  $bg = $osisText->addNewChild("http://www.bibletechnologies.net/2003/OSIS/namespace", 'div'); $bg->setAttribute('type', 'bookGroup');
  my @bookGroups = $XPC->findnodes('//osis:osisText/osis:div[@type="bookGroup"]', $xml);

  # place books into proper bookGroup in proper order
  if ($maintainBookOrder) {
    # maintain original book order
    my $i = 0;
    foreach my $bk (@books) {
      my $bkname = $bk->findvalue('./@osisID');
      # Switch to NT bookGroup upon reaching the first NT book
      if ($i==0 && $NT_BOOKS =~ /\b$bkname\b/i) {$i = 1;}
      @bookGroups[$i]->appendChild($bk);
      $bk = '';
    }
  }
  else {
    # place all books back in canon order
    foreach my $v11nbk (@{$bookArrayP}) {
      if (!$v11nbk) {next;} # bookArrayP[0] is empty
      foreach my $bk (@books) {
        if (!$bk || $bk->findvalue('./@osisID') ne $v11nbk) {next;}
        my $i = ($testamentP->{$v11nbk} eq 'OT' ? 0:1);
        @bookGroups[$i]->appendChild($bk);
        $bk = '';
        last;
      }
    }
  }
  
  foreach my $bk (@books) {
    if ($bk ne '') {&ErrorBug("Book \"$bk\" was not found in $vsys Canon.");}
  }
  
  foreach my $bookGroup (@bookGroups) {
    if (!$bookGroup->hasChildNodes()) {$bookGroup->unbindNode();}
  }

  # place all peripheral files, and separately any \periph sections they may contain, each to their proper places
  foreach my $periphFile (@periphFiles) {
    my $placedPeriphFile;

    # read the first comment to find desired target location(s) and scope, if any
    my $commentNode = @{$XPC->findnodes('child::node()[2][self::comment()]', $periphFile)}[0];

    if (!$commentNode || $commentNode !~ /\s\S+ == \S+/) {
      &Error("Removing periph(s)!", "You must specify the location where each peripheral file should be placed within the OSIS file.");
      &Log(&placementMessage());
      &Warn("REMOVED:\n$periphFile");
    }
    else {
      my $comment = $commentNode->textContent;
      #<!-- id comment - (FRT) scope="Gen", titlePage == osis:div[@type='book'], tableofContents == remove, preface == osis:div[@type='bookGroup'][1], preface == osis:div[@type='bookGroup'][1] -->
      $comment =~ s/^.*?(?=\s(?:\S+|"[^"]+") ==)//; $comment =~ s/\s*$//;  # strip beginning/end stuff 
      my @parts = split(/(,\s*(?:\S+|"[^"]+") == )/, ", $comment");
      for (my $x=1; $x < @parts; $x += 2) { # start at $x=1 because 0 is always just a leading comma
        my $command = @parts[$x] . @parts[($x+1)];
        $command =~ s/^,\s*//;
        if ($command !~ /^(\S+|"[^"]+") == (.*?)$/) {
          &Error("Unhandled location or scope assignment \"$command\" in \"$commentNode\" in CF_usfm2osis.txt");
          next;
        }
        my $left = $1;
        my $xpath = $2;
  
        $left =~ s/"//g; # strip possible quotes
        if ($left eq 'scope') {
          $xpath =~ s/"//g; # strip possible quotes
          if (!$periphFile->getAttribute('osisRef')) {
            $periphFile->setAttribute('osisRef', $xpath); # $xpath is not an xpath in this case but rather a scope
          }
          else {&Error("Introduction comment specifies scope == $xpath, but introduction already has osisRef=\"".$periphFile->getAttribute('osisRef')."\"");}
          next;
        }       
        if ($xpath eq "osis:header") {
          $xpath = "osis:header/following-sibling::node()[1]";
          &Error("Introduction comment specifies '$command' but this usage has been deprecated.", 
"This xpath was previously interpereted as 'place after the header' but 
it now means 'place as preceding sibling of the header' which is not 
what you want. To retain the old meaning, change osis:header to $xpath");
          &Warn("Changing osis:header to $xpath");
        }
        elsif ($xpath =~ /div\[\@type=.bookGroup.]\[\d+\]$/) {
          $xpath .= "/node()[1]";
          &Error("Introduction comment specifies '$command' but this usage has been deprecated.", 
"This xpath was previously interpereted as 'place as first child of the 
bookGroup' but it now is interpereted as 'place as the preceding sibling 
of the bookGroup' which is probably not what you want. To retain the old 
meaning, change it to $xpath");
          &Warn("Changing $command to $left == $xpath");
        }
     
        my $beforeNode;
        if ($xpath =~ /^remove$/i) {$xpath = '';}
        else {
          $beforeNode = @{$XPC->findnodes('//'.$xpath, $xml)}[0];
          if (!$beforeNode) {
            &Error("Removing periph! Could not locate xpath:\"$xpath\" in command $command");
            next;
          }
        }
        
        if ($left eq 'location') {
          $placedPeriphFile = 1;
          if ($xpath) {&placeIntroduction($periphFile, $beforeNode);}
        }
        else {
          my $periph = &findThisPeriph($periphFile, $left, $command);
          if (!$periph) {next;}
          $periph->unbindNode();
          if ($xpath) {&placeIntroduction($periph, $beforeNode);}
        }
        
        if ($xpath) {
          my $tg = $periphFile->toString(); $tg =~ s/>.*$/>/s;
          &Note("Placing $left == $xpath for $tg");
        }
        else {&Note("Removing \"$left\" in command $command.");}
      }
    }
    
    if (!$placedPeriphFile) {
      my $tst = @{$XPC->findnodes('.//*', $periphFile)}[0];
      my $tst2 = @{$XPC->findnodes('.//text()[normalize-space()]', $periphFile)}[0];
      if ($tst || $tst2) {
        &Error(
"The placement location for the following peripheral material was 
not specified and its position may be incorrect:
$periphFile
To position the above material, add location == <XPATH> after the \\id tag."
        );
        &Log(&placementMessage());
      }
      else {
        $periphFile->unbindNode();
        my $tg = $periphFile->toString(); $tg =~ s/>.*$/>/s;
        &Note("Removing empty div: $tg");
      }
    }
  }

  open(OUTF, ">$output");
  print OUTF $xml->toString();
  close(OUTF);
  $$osisP = $output;
}

sub findThisPeriph($$$) {
  my $parent = shift;
  my $left = shift;
  my $command = shift;
  
  my $type;
  my $subType;
  if ($left eq 'x-unknown') {$type = $left;}
  elsif (defined($PERIPH_TYPE_MAP{$left})) {
    $type = $PERIPH_TYPE_MAP{$left};
    $subType = $PERIPH_SUBTYPE_MAP{$left};
  }
  elsif (defined($PERIPH_TYPE_MAP_R{$left})) {$type = $left;}
  elsif (defined($PERIPH_SUBTYPE_MAP_R{$left})) {$type = "introduction"; $subType = $left;}
  else {
    &Error("Could not place periph! Unable to map $left to a div element in $command.");
    return '';
  }
  my $xpath = './/osis:div[@type="'.$type.'"]'.($subType ? '[@subType="'.$subType.'"]':'[not(@subType)]');
  my $periph = @{$XPC->findnodes($xpath, $parent)}[0];
  if (!$periph) {
    &Error("Could not place periph! Did not find \"$xpath\"in $command.");
    return '';
  }
  
  return $periph;
}

# Insert $periph node before $beforeNode. But when $beforeNode is a toc 
# or runningHead element, then insert $periph before the following non-
# toc, non-runningHead node instead.
sub placeIntroduction($$) {
  my $periph = shift;
  my $beforeNode = shift;

  # place as first non-toc and non-runningHead element in destination container
  while (@{$XPC->findnodes('./self::text()[not(normalize-space())] | ./self::osis:title[@type="runningHead"] | ./self::osis:milestone[starts-with(@type, "x-usfm-toc")]', $beforeNode)}[0]) {
    $beforeNode = $beforeNode->nextSibling();
  }
  $beforeNode->parentNode->insertBefore($periph, $beforeNode);
}

sub placementMessage() {
  if ($AlreadyReportedThis) {return '';}
  $AlreadyReportedThis = 1;
return
"------------------------------------------------------------------------
| The destination location of peripheral files and, if desired, of each 
| \periph section within these files, must be appended to the end of 
| each peripheral USFM file's \id line, like this:
|
| \id INT location == <xpath-expression>, <div-type> == <xpath-expression>, <div-type> == <xpath-expression>, ...
|
| Where 'location' is used to specify where the entire file should go.
|
| Where <div-type> is one of the following:
| \t-A peripheral OSIS div type or subType will select the next div 
| \t\tin the converted OSIS file having that type or subType.
| \t- A USFM \periph type within double quotes (and don't forget the 
| \t\tquotes) will select the next OSIS div of that periph type. 
| \t- If the div you want to select is not part of the USFM 2.4 
| \t\tspecification, it can only be specified with: 
| \t\tx-unknown == <xpath-expression>.
|
| Where <xpath-expression> is one of:
| \t-The keyword 'remove' to remove it from the OSIS file entirely.
| \t-The keyword 'osis:header' to place it after the header element,
| \t\twhich is the location for full Bible introductory material.
| \t-An XPATH expression selecting the parent element at the top of 
| \t\twhich it should be placed, such as: 
| \t\tosis:div[\@osisID=\"Ruth\"]
| \t\tto place it at the beginning of the book of Ruth.
|
| Optionally, you may also specify the scope of each peripheral file by 
| adding \"scope == Matt-Rev\" for instance. This is used by single
| Bible-book eBooks to duplicate peripheral material where needed.
------------------------------------------------------------------------\n";
}

sub fitToVerseSystem($$) {
  my $osisP = shift;
  my $vsys = shift;
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1fitToVerseSystem$3/;
  
  if (!$vsys) {$vsys = "KJV";}

  &Log("\nFitting OSIS \"$$osisP\" to versification $vsys\n", 1);

  my $canonP; my $bookOrderP; my $testamentP; my $bookArrayP;
  if (!&getCanon($vsys, \$canonP, \$bookOrderP, \$testamentP, \$bookArrayP)) {
    &ErrorBug("Not Fitting OSIS versification because getCanon($vsys) failed.");
    return;
  }

  my $xml = $XML_PARSER->parse_file($$osisP);
  
  # Check if this osis file has already been fitted, and bail if so
  my @existing = $XPC->findnodes('//osis:milestone[@annotateType="'.$VSYS{'prefix'}.$VSYS{'AnnoTypeSource'}.'"]', $xml);
  if (@existing) {
    &Warn("
There are ".@existing." fitted tags in the text. This OSIS file has 
already been fitted so this step will be skipped!");
  }
  
  # Apply VSYS instructions to the translation (first do the fitting, then mark moved verses)
  elsif (@VSYS_INSTR) {
    foreach my $argsP (@VSYS_INSTR) {
      if ($argsP->{'inst'} ne 'FROM_TO') {&applyVsysInstruction($argsP, $canonP, $xml);}
    }
    $xml = &writeReadXML($xml, $output);
    &addMovedMarkers($canonP, $xml);
    my $scopeElement = @{$XPC->findnodes('/osis:osis/osis:osisText/osis:header/osis:work[child::osis:type[@type="x-bible"]]/osis:scope', $xml)}[0];
    if ($scopeElement) {&changeNodeText($scopeElement, &getScope($xml));}
    $xml = &writeReadXML($xml, $output);
    $$osisP = $output;
  }
  
  # Warn that these alternate verse tags in source could require further VSYS intructions
  my @nakedAltTags = $XPC->findnodes('//osis:hi[@subType="x-alternate"][not(preceding::*[1][self::osis:milestone[starts-with(@type, "'.$VSYS{'prefix'}.'")]])]', $xml);
  if (@nakedAltTags) {
    &Warn("The following alternate verse tags were found.",
"If these represent verses which normally appear somewhere else in the 
$vsys verse system, then a VSYS_MOVED_ALT instruction should be 
added to CF_usfm2osis.txt to allow correction of external cross-
references:");
    foreach my $at (@nakedAltTags) {
      my $verse = @{$XPC->findnodes('preceding::osis:verse[@sID][1]', $at)}[0];
      &Log($verse." ".$at."\n");
    }
  }
}

sub checkVerseSystem($$) {
  my $bibleosis = shift;
  my $vsys = shift;
  
  my $xml = $XML_PARSER->parse_file($bibleosis);
  
  my $canonP; my $bookOrderP; my $testamentP; my $bookArrayP;
  if (!&getCanon($vsys, \$canonP, \$bookOrderP, \$testamentP, \$bookArrayP)) {
    &ErrorBug("Leaving checkVerseSystem() because getCanon($vsys) failed.");
    return;
  }
  
  # Insure that all verses are accounted for and in sequential order 
  # without any skipping (required by GoBible Creator).
  my @ve = $XPC->findnodes('//osis:verse[@sID]', $xml);
  my @v = map($_->getAttribute('sID'), @ve);
  my $x = 0;
  my $checked = 0;
  my $errors = 0;

BOOK:
  foreach my $bk (map($_->getAttribute('osisID'), $XPC->findnodes('//osis:div[@type="book"]', $xml))) {
    if (@v[$x] !~ /^$bk\./) {next;}
    my $ch = 1;
    foreach my $vmax (@{$canonP->{$bk}}) {
      for (my $vs = 1; $vs <= $vmax; $vs++) {
        @v[$x] =~ /^([^\.]+)\.(\d+)\.(\d+)(\s|$)/; my $ebk = $1; my $ech = (1*$2); my $evs = (1*$3);
        if (($ech != 1 && $ech < $ch) || ($ech == $ch && $evs < $vs)) {
          &Error("Chapter/verse ordering problem at ".@v[$x]." (expected $ch.$vs)", "Check your SFM for out of order chapter/verses and fix them.");
          $errors++;
          next;
        }
        if (@v[$x] !~ /\b\Q$bk.$ch.$vs\E\b/) {
          &Error("Missing verse $bk.$ch.$vs.", "If this verse is supposed to be missing, then add a VSYS_MISSING instruction to CF_usfm2osis.txt. $fitToVerseSystemDoc");
          $fitToVerseSystemDoc = '';
          $errors++;
          next;
        }
        @v[$x] =~/\.(\d+)\s*$/; $vs = ($1*1);
        $x++;
      }
      while (@v[$x] =~ /^\Q$bk.$ch./) {
        &Error("Extra verse: ".@v[$x], "If this verse is supposed to be extra, then add a VSYS_EXTRA instruction to CF_usfm2osis.txt. $fitToVerseSystemDoc");
        $fitToVerseSystemDoc = '';
        $errors++;
        $x++;
      }
      $ch++;
    }
    while (@v[$x] =~ /^\Q$bk./) {
      &Error("Extra chapter: ".@v[$x], "If this chapter is supposed to be missing, then add a VSYS_EXTRA instruction to CF_usfm2osis.txt. $fitToVerseSystemDoc");
      $fitToVerseSystemDoc = '';
      $errors++;
      $x++;
    }
  }
  if ($x == @v) {&Log("\n"); &Note("All verses were checked against verse system $vsys.");}
  else {&Log("\n"); &ErrorBug("Problem checking chapters and verses in verse system $vsys (stopped at $x of @v verses: ".@v[$x].")");}
  
  &Log("\n");
  &Report("$errors verse system problems detected".($errors ? ':':'.'));
  if ($errors) {
    &Note("
      This translation does not fit the $vsys verse system. The errors 
      listed above must be fixed. Add the appropriate instructions:
      VSYS_EXTRA, VSYS_MISSING and/or VSYS_MOVED to CF_usfm2osis.txt. $fitToVerseSystemDoc");
    $fitToVerseSystemDoc = '';
  }
}

# Newly written elements may not have the right name-spaces until the file is re-read!
sub writeReadXML($$) {
  my $tree = shift;
  my $file = shift;
  
  open(OUTF, ">$file");
  print OUTF $tree->toString();
  close(OUTF);
  return $XML_PARSER->parse_file($file);
}

# Read bibleMod and the osis file and:
# 1) Find all verse osisIDs in $bibleMod which were changed by VSYS 
#    instructions. These are used for updating source osisRefs, but 
#    these do not effect osisRefs of runAddCrossRefs() references. 
# 2) Find all verse osisIDs in $bibleMod which were moved by the 
#    translators with respect to the fixed verse system. These
#    are used for updating external osisRefs.
# 3) Find applicable osisRefs in $osis which point to the osisIDs found 
#    in #2 and #3, and correct them, plus add source target as annotateRef.
sub correctReferencesVSYS($) {
  my $osisP = shift;
  
  my $output = $$osisP; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1correctReferencesVSYS$3/;
  
  my $in_bible = ($INPD eq $MAININPD ? $$osisP:&getProjectOsisFile($MAINMOD));
  if (! -e $in_bible) {
    &Warn("No OSIS Bible file was found. References effected by VSYS instructions will not be corrected.");
    return;
  }
  &Log("\n\nUpdating osisRef attributes of \"$$osisP\" that require re-targeting after VSYS instructions:\n", 1);
  
  # Read Bible file
  my $bibleXML = $XML_PARSER->parse_file($in_bible);
  my $vsys = &getVerseSystemOSIS($bibleXML);
  
  # Read OSIS file
  my $osisXML = $XML_PARSER->parse_file($$osisP);
  my @existing = $XPC->findnodes('//osis:reference[@annotateType="'.$VSYS{'prefix'}.$VSYS{'AnnoTypeSource'}.'"][@annotateRef][@osisRef]', $osisXML);
  if (@existing) {
    &Warn(@existing." references have already been updated, so this step will be skipped.");
    return;
  }

  # Look for osisRefs in the osis file that need updating and update them
  my @maps = ('source2Fitted', 'fixed2Fitted', 'fixedMissing');
  my $altVersesOSISP = &getAltVersesOSIS($bibleXML);
  foreach my $m (@maps) {
    my $lastch = '';
    my @checkrefs = ();
    foreach my $verse (&normalizeOsisID([ keys(%{$altVersesOSISP->{$m}}) ])) {
      $verse =~ /^(.*?)\.\d+$/;
      my $ch = $1;
      if (!$lastch || $lastch ne $ch) {
        my $xpath = "//*[contains(\@osisRef, '$ch')][not(starts-with(\@type, '".$VSYS{'prefix'}."'))]";
        if ($m =~ /^source/) {
          $xpath .= "[not(ancestor-or-self::osis:note[\@type='crossReference'][\@resp])]";
        }
        else {
          $xpath .= "[ancestor-or-self::osis:note[\@type='crossReference'][\@resp]]";
        }
        @checkrefs = $XPC->findnodes($xpath, $osisXML);
      }
      $lastch = $ch;
      &addrids(\@checkrefs, $verse, $m, $altVersesOSISP);
    }
  }
  
  my $count = &applyrids($osisXML);

  # Overwrite OSIS file if anything changed
  if ($count) {
    if (open(OUTF, ">$output")) {
      print OUTF $osisXML->toString();
      close(OUTF);
      $$osisP = $output;
    }
    else {&ErrorBug("Could not open \"$output\" to write osisRef fixes.");}
  }
  
  &Log("\n");
  &Report("\"$count\" osisRefs were corrected to account for differences between source and fixed verse systems.");
}

# Look for references to $verse in $checkRefsAP array, and any matching 
# references will be updated. The rids attribute will eventually become 
# the updated osisRef and the annotateRef attribute will hold the source 
# verse system reference.
sub addrids(\@$$\%) {
  my $checkRefsAP = shift;
  my $verse = shift;
  my $map = shift; # source2Fitted, fixed2Fitted or fixedMissing
  my $altVersesOSISP = shift;
  
  my @attribs = ('osisRef', 'annotateRef', 'rids');
  foreach my $e (@{$checkRefsAP}) {
    foreach my $a (@attribs) {
      my @ar = (split(/\s+/, &osisRef2osisID($e->getAttribute($a))));
      $$a = \@ar;
    }
    foreach my $ref (@$osisRef) {
      my $v = $verse;
      my $vIsPartial = ($v =~ s/!PART$// ? 1:0);
      if ($ref ne $v) {next;}
      elsif (!$altVersesOSISP->{$map}{$verse}) {&ErrorBug("Could not map \"$verse\" to verse system.");}
      
      $e->setAttribute('osisRefOrig', $e->getAttribute('osisRef'));
      $e->setAttribute('annotateType', $VSYS{'prefix'}.$VSYS{'AnnoTypeSource'});
  
      # map source references to fitted
      if ($map eq 'source2Fitted') {
        if ($vIsPartial) {push(@$rids, $v);}
        push(@$rids, $altVersesOSISP->{'source2Fitted'}{$verse});
        push(@$annotateRef, $v);
      }
      # map externally added references to fitted
      elsif ($map eq 'fixed2Fitted') {
        if ($vIsPartial) {push(@$rids, $v);}
        push(@$rids, $altVersesOSISP->{'fixed2Fitted'}{$verse});
        my $ar = $altVersesOSISP->{'fixed2Source'}{$verse}; $ar =~ s/!PART$//;
        push(@$annotateRef, $ar);
      }
      elsif ($map eq 'fixedMissing') {
        if ($vIsPartial) {push(@$rids, $v);}
      }
      else {&ErrorBug("Unexpected map $map.");}
      
      $ref = '';
    }
    foreach my $a (@attribs) {
      my $val = &osisID2osisRef(join(' ', &normalizeOsisID($$a)));
      if ($val ne $e->getAttribute($a)) {$e->setAttribute($a, $val);}
    }
  }
}

# Merges the osisRef and rids attributes of all elements having the rids 
# attribute, then rids is removed. Also merges osisRef into annotateRef.
# If an element's osisRef is empty, the reference tags are entirely 
# removed.
sub applyrids($\%) {
  my $xml = shift;
  
  my ($update, $remove);
  my $count = 0;
  foreach my $e ($XPC->findnodes('//*[@rids]', $xml)) {
    $count++;
    my $tag = $e->toString(); $tag =~ s/^(<[^>]*>).*?$/$1/s;
    my @annotateRef = (split(/\s+/, &osisRef2osisID($e->getAttribute('annotateRef'))));
    my @rids = (split(/\s+/, &osisRef2osisID($e->getAttribute('rids'))));
    $e->removeAttribute('rids');
    my $osisRefOrig = $e->getAttribute('osisRefOrig');
    $e->removeAttribute('osisRefOrig');
    my @osisRef = (split(/\s+/, &osisRef2osisID($e->getAttribute('osisRef'))));
    push(@annotateRef, @osisRef);
    push(@osisRef, @rids);

    my $osisRefNew     = &fillGapsInOsisRef(&osisID2osisRef(join(' ', &normalizeOsisID(\@osisRef))));
    my $annotateRefNew = &fillGapsInOsisRef(&osisID2osisRef(join(' ', &normalizeOsisID(\@annotateRef))));
    $e->setAttribute('annotateRef', $annotateRefNew);
   
    if ($osisRefNew) {
      my $ie = ($e->nodeName =~ /(note|reference)/ ? (@{$XPC->findnodes('./ancestor-or-self::osis:note[@resp]', $e)}[0] ? 'external ':'internal '):'');
      $update .= sprintf("UPDATING %s %-10s osisRef: %32s -> %-32s annotateRef: %-32s\n", $ie, $e->nodeName, $osisRefOrig, $osisRefNew, $e->getAttribute('annotateRef'));
      $e->setAttribute('osisRef', $osisRefNew);
    }
    else {
      my $parent = $e->parentNode();
      $parent = $parent->toString(); $parent =~ s/^[^<]*(<[^>]+?>).*$/$1/s;
      if ($e->getAttribute('type') eq "crossReference") {
        $remove .= "REMOVING cross-reference for empty verse: $tag\n";
      }
      else {
        $remove .= "REMOVING tags for empty verse: $tag \n";
        foreach my $chld ($e->childNodes) {$e->parentNode()->insertBefore($chld, $e);}
      }
      $e->unbindNode();
    }
  }
  
  if ($update) {&Note("\n$update\n");}
  if ($remove) {&Note("\n$remove\n");}
  
  return $count;
}

# Take an osisRef's starting and ending point, and if they are in the
# same chapter, return an osisRef that covers the entire range between
# them. This can be used to 'heal' missing verses in mapped ranges.
sub fillGapsInOsisRef() {
  my $osisRef = shift;
  
  my @id = split(/\s+/, &osisRef2osisID($osisRef));
  @id[0]    =~ /^([^\.]+\.\d+\.)(\d+)$/; my $chf = $1; my $vf = $2;
  @id[$#id] =~ /^([^\.]+\.\d+\.)(\d+)$/; my $chl = $1; my $vl = $2;
  if ($chf eq $chl && $vf ne $vl) {return @id[0].'-'.@id[$#id];}
  return $osisRef;
}

sub applyVsysInstruction(\%\%$) {
  my $argP = shift;
  my $canonP = shift;
  my $xml = shift;
  
  &Log("\nVSYS_".$argP->{'inst'}.": fixed=".$argP->{'fixed'}.", source=".$argP->{'source'}."\n");

  my $inst = $argP->{'inst'};
  
  # NOTE: 'fixed' always refers to the known fixed verse system, 
  # and 'source' always refers to the customized source verse system
  my $fixedP  = ($argP->{'fixed'}  ? &parseVsysArgument($argP->{'fixed'},  $xml):'');
  my $sourceP = ($argP->{'source'} ? &parseVsysArgument($argP->{'source'}, $xml):'');
  
  if ($fixedP && $sourceP && $fixedP->{'count'} != $sourceP->{'count'}) {
    &Error("'From' and 'To' are a different number of verses: $inst: ".$argP->{'fixed'}." -> ".$argP->{'source'});
    return 0;
  }
  
  my $test = ($fixedP->{'bk'} ? $fixedP->{'bk'}:$sourceP->{'bk'});
  if (!&getBooksOSIS($xml)->{$test}) {
    &Warn("Skipping VSYS_$inst because $test is not in the OSIS file.", "Is this instruction correct?");
    return 0;
  }
  
  if    ($inst eq 'MISSING') {&applyVsysMissing($fixedP, $xml);}
  elsif ($inst eq 'EXTRA')   {&applyVsysExtra($sourceP, $canonP, $xml);}
  elsif ($inst eq 'FROM_TO') {&applyVsysFromTo($fixedP, $sourceP, $xml);}
  else {&ErrorBug("applyVsysInstruction did nothing: $inst");}
  
  return 1;
}

sub parseVsysArgument($$) {
  my $value = shift;
  my $xml = shift;
  
  my %data;
  $data{'value'} = $value;
  
  # read and preprocess value
  if ($value !~ /^$VSYS_PINSTR_RE$/) {
    &ErrorBug("parseVsysArgument: Could not parse: $value !~ /^$VSYS_PINSTR_RE\$/");
    return \%data;
  }
  my $bk = $1; my $ch = $2; my $vs = ($3 ? $4:''); my $lv = ($5 ? $6:'');
  
  $data{'isPartial'} = ($lv =~ s/^PART$/$vs/ ? 1:0);
  $data{'isWholeChapter'} = &isWholeVsysChapter($bk, $ch, \$vs, \$lv, $xml);
  $data{'bk'} = $bk;
  $data{'ch'} = (1*$ch);
  $data{'vs'} = (1*$vs);
  $data{'lv'} = (1*$lv);
  $data{'count'} = 1+($lv-$vs);
  
  return \%data
}

sub addMovedMarkers($$) {
  my $canonP = shift;
  my $xml = shift;
  
  foreach my $argsP (@VSYS_INSTR) {
    if ($argsP->{'inst'} eq 'FROM_TO') {&applyVsysInstruction($argsP, $canonP, $xml);}
  }
  
  # VSYS_MISSING and VSYS_EXTRA may adust source verse numbers up or down
  # respectively to arrive at their fitted verse numbers. These need to be
  # marked as moved so that external cross-references can be updated.
  my @alts = $XPC->findnodes('//osis:hi[@subType="x-alternate"][@resp="fitToVerseSystem"]', $xml);
  foreach my $alt (@alts) {
    my $vsource = $alt->textContent(); $vsource =~ s/^\D*(\d+).*?$/$1/;
    my $vfixed = @{$XPC->findnodes('preceding::osis:verse[@osisID][1]', $alt)}[0];
    if (!$vfixed || $vfixed->getAttribute('type') ne $VSYS{'prefix'}.$VSYS{'TypeModified'}) {
      &ErrorBug("Problem with fitted alternate verse source: $vfixed<>$alt");
      next;
    }
    $vfixed = $vfixed->getAttribute('osisID');
    my $ch = ($vfixed =~ /^([^\.]+\.\d+)/ ? $1:'');
    $vsource = "$ch.$vsource";
    if (!$ch || $vfixed eq $vsource) {
      &ErrorBug("Empty chapter $ch, or fitted alternate same as source: $vfixed eq $vsource");
      next;
    }
    &applyVsysFromTo(&parseVsysArgument($vfixed, $xml), &parseVsysArgument($vsource, $xml), $xml);
  }
}

# This does not modify any verse tags. It only inserts milestone markers
# which later can be used to map Scripture references between the source
# and the fixed verse systems. For all VSYS markup, annotateRef always 
# refers to the source verse system osisID (assuming annotateType = 
# x-vsys-source as it should). And osisRef always refers to the fixed 
# verse system osisID.
# Types of milestones inserted are:
# $VSYS{'movedto'}, $VSYS{'missing'} and $VSYS{'movedfrom'} 
sub applyVsysFromTo($$$) {
  my $fixedP = shift;
  my $sourceP = shift;
  my $xml = shift;
  
  my $bk = $fixedP->{'bk'}; my $ch = $fixedP->{'ch'}; my $vs = $fixedP->{'vs'}; my $lv = $fixedP->{'lv'};
  for (my $v=$vs; $v<=$lv; $v++) {
    my $annotateRef = ($sourceP ? $sourceP->{'bk'}.'.'.$sourceP->{'ch'}.'.'.($sourceP->{'vs'} + $v - $vs):'');
    if ($sourceP && $sourceP->{'isPartial'}) {$annotateRef .= "!PART";}
    
    # Insert a movedto or missing marker at the end of the verse
    my $fixedVerseEnd = &getVerseTag("$bk.$ch.$v", $xml, 1);
    if (!$fixedVerseEnd) {
      &ErrorBug("Could not find FROM_TO verse $bk.$ch.$v");
      next;
    }
    my $type = (!$sourceP ? 'missing':'movedto');
    my $osisRef = "$bk.$ch.$v";
    if ($fixedP->{'isPartial'}) {$osisRef .= "!PART";}
    my $m = '<milestone type="'.$VSYS{'prefix'}.$VSYS{$type}.'" osisRef="'.$osisRef.'" ';
    if ($annotateRef) {$m .= 'annotateRef="'.$annotateRef.'" annotateType="'.$VSYS{'prefix'}.$VSYS{'AnnoTypeSource'}.'" ';}
    $m .= '/>';
    $fixedVerseEnd->parentNode->insertBefore($XML_PARSER->parse_balanced_chunk($m), $fixedVerseEnd);
    
    # Insert a movedfrom milestone at the end of the destination 
    # alternate verse, which should be either a milestone verse end (if 
    # the source was originally a regular verse) or else a hi with 
    # subType=x-alternate (if it was originally an alternate verse).
    my $ar = ($annotateRef =~ /^(.*?)!PART$/ ? $1:$annotateRef);
    my $altVerseEnd = &getSourceVerseTag($ar, $xml, 1);
    if (!$altVerseEnd) {$altVerseEnd = &getSourceAltVerseTag($ar, $xml, 1);}
    if (!$altVerseEnd) {
      &ErrorBug("Could not find FROM_TO destination alternate verse $ar");
      next;
    }
    $osisRef = @{$XPC->findnodes('preceding::osis:verse[@osisID][1]', $altVerseEnd)}[0];
    if (!$osisRef || !$osisRef->getAttribute('osisID')) {
      &ErrorBug("Could not find FROM_TO destination verse osisID: ".($osisRef ? 'no osisID':'no verse'));
      next;
    }
    $osisRef = $osisRef->getAttribute('osisID');
    $osisRef =~ s/^.*?\s+(\S+)$/$1/;
    $m = '<milestone type="'.$VSYS{'prefix'}.$VSYS{'movedfrom'}.'" osisRef="'.$osisRef.'" annotateRef="'.$annotateRef.'" annotateType="'.$VSYS{'prefix'}.$VSYS{'AnnoTypeSource'}.'"/>';
    $altVerseEnd->parentNode->insertBefore($XML_PARSER->parse_balanced_chunk($m), $altVerseEnd);
  }
}

# Find the source verse system verse tag (a milestone) associated with 
# an alternate $vid. Failure returns nothing.
sub getSourceVerseTag($$$) {
  my $vid = shift;
  my $xml = shift;
  my $isEnd = shift;
  
  my @svts = $XPC->findnodes('//*[@type="'.$VSYS{'prefix'}.'-verse'.($isEnd ? $VSYS{'end'}:$VSYS{'start'}).'"]', $xml);
  foreach my $svt (@svts) {
    my $ref = $svt->getAttribute('annotateRef');
    foreach my $idp (split(/\s+/, &osisRef2osisID($ref))) {
      if ($idp eq $vid) {return $svt;}
    }
  }
  return '';
}

# Find the source verse system alternate verse tag associated with an
# alternate $vid. Failure returns nothing.
sub getSourceAltVerseTag($$$) {
  my $vid = shift;
  my $xml = shift;
  my $isEnd = shift;
  
  if ($vid !~ /^([^\.]+)\.([^\.]+)\.([^\.]+)$/) {
    &ErrorBug("Could not parse $vid !~ /^([^\.]+)\.([^\.]+)\.([^\.]+)\$/");
    return '';
  }
  my $bk = 1; my $ch = $2; my $vs = $3;
  my @altsInChapter = $XPC->findnodes(
    '//osis:div[@type="book"][@osisID="'.$bk.'"]//osis:hi[@subType="x-alternate"]'.
    '[preceding::osis:chapter[1][@sID="'.$bk.'.'.$ch.'"]]'.
    '[following::osis:chapter[1][@eID="'.$bk.'.'.$ch.'"]]', $xml);
  foreach my $alt (@altsInChapter) {
    if ($alt->textContent !~ /\b$vs\b/) {next;}
    if (!$isEnd) {return $alt;}
    my $end = @{$XPC->findnodes('following::*[ancestor::div[@osisID="'.$bk.'"]]
        [self::osis:verse[@eID][1] or self::osis:hi[@subType="x-alternate"][1] or self::milestone[@type="'.$VSYS{'prefix'}.'verse'.$VSYS{'end'}.'"][1]]
        [1]', $alt)}[0];
    if ($end) {return $end;}
    &ErrorBug("Could not find end of $alt");
  }
  
  return '';
}

# Used when verses in the verse system were not included in the 
# translation. It modifies the previous verse osisID to include the 
# empty verses and renumbers the following verses in the chapter, also 
# inserting alternate verse numbers there. If the 'missing' verse was
# moved somewhere else (the usual case) that is marked-up by FROM_TO.
sub applyVsysMissing($$$) {
  my $fixedP = shift;
  my $xml = shift;
  
  my $bk = $fixedP->{'bk'}; my $ch = $fixedP->{'ch'}; my $vs = $fixedP->{'vs'}; my $lv = $fixedP->{'lv'};
  
  if ($fixedP->{'isPartial'}) {
    &Note("Verse reference is partial, so nothing to do here.");
    return;
  }
  
  my $count = (1 + $lv - $vs);
  
  my $verseTagToModify = &getVerseTag("$bk.$ch.".($vs!=1 ? ($vs-1):&getFirstVerseInChapterOSIS($bk, $ch, $xml)), $xml, 0);  
  # For any following verses, advance their verse numbers and add alternate verse numbers if needed
  my $followingVerse = @{$XPC->findnodes('./following::osis:verse[@sID][1]', $verseTagToModify)}[0];
  if ($followingVerse) {
    $followingVerse = $followingVerse->getAttribute('osisID');
    $followingVerse =~ s/^[^\.]+\.\d+\.(\d+)\b.*?$/$1/;
    if ($vs != ($followingVerse-$count) - ($vs!=1 ? 0:1)) {
      for (my $v=&getLastVerseInChapterOSIS($bk, $ch, $xml); $v>=$vs; $v--) {
        &reVersify($bk, $ch, $v, $count, $xml);
      }
    }
  }
  
  # Add the missing verses (by listing them in an existing osisID)
  # need to get verseTagToModify again since reVersify converted the old one to a milestone
  $verseTagToModify = &getVerseTag("$bk.$ch.".($vs!=1 ? ($vs-1):&getFirstVerseInChapterOSIS($bk, $ch, $xml)), $xml, 0);
  my $endTag = @{$XPC->findnodes('//osis:verse[@eID="'.$verseTagToModify->getAttribute('sID').'"]', $xml)}[0];
  my @missing;
  for (my $v = $vs; $v <= $lv; $v++) {
    my $a = "$bk.$ch.$v";
    &osisIDCheckUnique($a, $xml);
    push(@missing, $a);
  }

  push(@missing, $verseTagToModify->getAttribute('osisID'));
  my $newOsisID = join(' ', &normalizeOsisID(\@missing));
  &Note("Changing verse osisID='".$verseTagToModify->getAttribute('osisID')."' to '$newOsisID'");
  $verseTagToModify = &toAlternate($verseTagToModify, 0, 1);
  $endTag = &toAlternate($endTag, 0, 1);
  $verseTagToModify->setAttribute('osisID', $newOsisID);
  $verseTagToModify->setAttribute('sID', $newOsisID);
  $endTag->setAttribute('eID', $newOsisID);
}

# Used when the translation includes extra verses in a chapter compared
# to the target verse system (and which are marked up as regular 
# verses). For these extra verses, alternate verse numbers are inserted 
# and verse tags are converted into milestone elements. Then they are 
# enclosed within the proceding verse system verse. All following verses 
# in the chapter are renumbered and alternate verses inserted.
sub applyVsysExtra($$$$) {
  my $sourceP = shift;
  my $canonP = shift;
  my $xml = shift;
  my $adjusted = shift;
  
  my $bk = $sourceP->{'bk'}; my $ch = $sourceP->{'ch'}; my $vs = $sourceP->{'vs'}; my $lv = $sourceP->{'lv'};
  
  if ($sourceP->{'isPartial'}) {
    &Note("Verse reference is partial, so nothing to do here.");
    return;
  }
  
  my $isWholeChapter = ($ch > @{$canonP->{$bk}} ? 1:$sourceP->{'isWholeChapter'});
  
  # Handle the special case of an extra chapter (like Psalm 151)
  if ($ch > @{$canonP->{$bk}}) {
    if ($ch == (@{$canonP->{$bk}} + 1)) {
      my $lastv = &getLastVerseInChapterOSIS($bk, $ch, $xml);
      if ($vs != 1 || $lv != $lastv) {
        &Error("VSYS_EXTRA($bk, $ch, $vs, $lv): Cannot specify verses for a chapter outside the verse system.", "Use just '$bk.$ch' instead.");
      }
      $vs = 1;
      $lv = $lastv;
    }
    else {
      &ErrorBug("VSYS_EXTRA($bk, $ch, $vs, $lv): Not yet implemented (except when the extra chapter is the last chapter of the book).");
      return;
    }
  }
  
  # All verse tags between this startTag and endTag will become alternate
  my $startTag = (
    $isWholeChapter ?
    &getVerseTag("$bk.".($ch-1).".".&getLastVerseInChapterOSIS($bk, ($ch-1), $xml), $xml, 0) :
    &getVerseTag("$bk.$ch.".($vs!=1 ? ($vs-1):$vs), $xml, 0)
  );
  my $endTag = &getVerseTag("$bk.$ch.".(!$isWholeChapter && $vs==1 ? ($lv+1):$lv), $xml, 1);
  
  # VSYS_EXTRA references the source verse system, which may have been
  # modified by previous instructions. So adjust our inputs in that case.
  if (!$adjusted && &getAltID($startTag) =~ /^[^\.]+\.\d+\.(\d+)\b/) {
    my $arv = $1;
    $startTag->getAttribute('osisID') =~ /^[^\.]+\.\d+\.(\d+)\b/;
    my $shift = ($1 - $arv);
    if ($shift) {
      &Note("This verse was moved, adjusting position: '$shift'.");
      my $newSourceArgumentP = &parseVsysArgument($bk.'.'.$ch.'.'.($vs+$shift).'.'.($sourceP->{'isPartial'} ? 'PART':($lv+$shift)), $xml);
      &applyVsysExtra($newSourceArgumentP, $canonP, $xml, 1);
      return;
    }
  }
  
  if (!$startTag || !$endTag) {
    &ErrorBug("VSYS_EXTRA($bk, $ch, $vs, $lv): Missing start-tag (=$startTag) or end-tag (=$endTag)");
    return;
  }
 
  # If isWholeChapter, then convert chapter tags to alternates and add alternate chapter number
  if ($isWholeChapter) {
    my $chapLabel = @{$XPC->findnodes("//osis:title[\@type='x-chapterLabel'][not(\@canonical='true')][preceding::osis:chapter[\@osisID][1][\@sID='$bk.$ch'][not(preceding::osis:chapter[\@eID='$bk.$ch'])]]", $xml)}[0];
    if ($chapLabel) {
      &Note("Converting chapter label \"".$chapLabel->textContent."\" to alternate.");
      $chapLabel->setAttribute('type', 'x-chapterLabel-alternate');
      my $t = $chapLabel->textContent();
      &changeNodeText($chapLabel, '');
      my $alt = $XML_PARSER->parse_balanced_chunk("<hi type=\"italic\" subType=\"x-alternate\">$t</hi>");
      foreach my $chld ($chapLabel->childNodes) {$alt->insertAfter($chld, undef);}
      $chapLabel->insertAfter($alt, undef);
    }
    else {
      &Note("No chapter label was found, adding alternate chapter label \"$ch\".");
      my $alt = $XML_PARSER->parse_balanced_chunk("<title type=\"x-chapterLabel-alternate\"><hi type=\"italic\" subType=\"x-alternate\">$ch</hi></title>");
      my $chStart = @{$XPC->findnodes("//osis:chapter[\@osisID='$bk.$ch']", $xml)}[0];
      $chStart->parentNode()->insertAfter($alt, $chStart);
    }
    my $chEnd = &toAlternate(@{$XPC->findnodes("//osis:chapter[\@eID='$bk.$ch']", $xml)}[0]);
    $chEnd->setAttribute('eID', "$bk.".($ch-1));
    &toAlternate(@{$XPC->findnodes("//osis:chapter[\@eID='$bk.".($ch-1)."']", $xml)}[0], 1);
    &toAlternate(@{$XPC->findnodes("//osis:chapter[\@sID='$bk.$ch']", $xml)}[0], 1);
  }
  
  # Convert verse tags between startTag and endTag to alternate verse numbers
  # But if there are no in-between tags, then only modify the IDs.
  $startTag = &toAlternate($startTag, 0, 1);
  if ($startTag->getAttribute('sID') eq $endTag->getAttribute('eID')) {
    my %ids; map($ids{$_}++, split(/\s+/, $startTag->getAttribute('osisID')));
    for (my $v = $vs; $v <= $lv; $v++) {if ($ids{"$bk.$ch.$v"}) {delete($ids{"$bk.$ch.$v"});}}
    my $newID = join(' ', &normalizeOsisID([ keys(%ids) ]));
    $startTag->setAttribute('osisID', $newID);
    $startTag->setAttribute('sID', $newID);
  }
  else {
    # (THIS FINDNODES METHOD IS ULTRA SLOW BUT WORKS)
    my $ns1 = '//osis:verse[@sID="'.$startTag->getAttribute('sID').'"]/following::osis:verse[ancestor::osis:div[@type="book"][@osisID="'.$bk.'"]]';
    my $ns2 = '//osis:verse[@eID="'.$endTag->getAttribute('eID').'"]/preceding::osis:verse[ancestor::osis:div[@type="book"][@osisID="'.$bk.'"]]';
    my @convert = $XPC->findnodes($ns1.'[count(.|'.$ns2.') = count('.$ns2.')]', $xml);
    foreach my $v (@convert) {&toAlternate($v, 1, 0);}
  }
  # Also convert endTag to alternate and update eID 
  $endTag = &toAlternate($endTag);
  $endTag->setAttribute('eID', $startTag->getAttribute('sID'));
  
  # Following verses get decremented verse numbers plus an alternate verse number (unless isWholeChapter)
  if (!$isWholeChapter) {
    my $lastV = &getLastVerseInChapterOSIS($bk, $ch, $xml);
    my $count = (1 + $lv - $vs);
    for (my $v = $vs + $count + ($vs!=1 ? 0:1); $v <= $lastV; $v++) {
      &reVersify($bk, $ch, $v, (-1*$count), $xml);
    }
  }
}

# Markup verse as alternate and increment it by count
sub reVersify($$$$$) {
  my $bk = shift;
  my $ch = shift;
  my $vs = shift;
  my $count = shift;
  my $xml = shift;
  
  my $note = "reVersify($bk, $ch, $vs, $count)";
  
  my $vTagS = &getVerseTag("$bk.$ch.$vs", $xml, 0);
  if (!$vTagS) {$note .= "[Start tag not found]"; &Note($note); return;}
  my $vTagE = &getVerseTag("$bk.$ch.$vs", $xml, 1);
  if (!$vTagE) {$note .= "[End tag not found]"; &Note($note); return;}
  
  my $osisID = $vTagS->getAttribute('osisID');
  my $newVerseID;
  my $newID;
  if ($count) {
    my @verses = split(/\s+/, $osisID);
    $newVerseID = "$bk.$ch.".($vs + $count);
    foreach my $v (@verses) {if ($v  eq "$bk.$ch.$vs") {$v = $newVerseID;}}
    $newID = join(' ', @verses);
  }
  
  if (!$vTagS->getAttribute('type') || $vTagS->getAttribute('type') ne $VSYS{'prefix'}.$VSYS{'TypeModified'}) {
    $vTagS = &toAlternate($vTagS);
    $vTagE = &toAlternate($vTagE);
  }
  elsif (&getAltID($vTagS) eq $newID) {
    $vTagS = &undoAlternate(&getAltID($vTagS, 1));
    $vTagE = &undoAlternate(&getAltID($vTagE, 1));
    $osisID = $vTagS->getAttribute('osisID');
  }
  else {$note .= "[Alternate verse already set]";}
  
  # Increment/Decrement
  if ($count) {
    if ($newID ne $osisID) {
      $note .= "[Changing verse osisID from ".$vTagS->getAttribute('osisID')." to $newID]";
      &osisIDCheckUnique($newVerseID, $xml);
      $vTagS->setAttribute('osisID', $newID);
      $vTagS->setAttribute('sID', $newID);
      $vTagS->setAttribute('type', $VSYS{'prefix'}.$VSYS{'TypeModified'});
      $vTagE->setAttribute('eID', $newID);
      $vTagE->setAttribute('type', $VSYS{'prefix'}.$VSYS{'TypeModified'});
    }
  }
  &Note($note); 
}

# This takes a verse or chapter element (start or end) and marks it as
# modified during fitting, unless already done, by:
# 1) Cloning itself for further adjustment and use by the fitted verse system (unless remove is set)
# 2) Converting the original element into a milestone element 
# 3) Adding an alternate verse number if the element is verse-start (unless noAlt is set)
# This funtion returns the new target verse system element of #2.
sub toAlternate($$$) {
  my $elem = shift;
  my $remove = shift;
  my $noAlt = shift;
  
  # Typical alternate markup example:
  # <milestone type="x-vsys-verse-start" osisRef="Rom.14.24" annotateRef="Rom.16.25" annotateType="x-vsys-source"/>
  #<hi type="italic" subType="x-alternate" resp="fitToVerseSystem"><hi type="super">(25)</hi></hi>
  
  my $telem;
  my $type = ($elem->getAttribute('sID') ? 'start':($elem->getAttribute('eID') ? 'end':''));
  my $osisID = ($type eq 'start' ? $elem->getAttribute('sID'):$elem->getAttribute('eID'));
  my $isVerseStart = ($type eq 'start' && $elem->nodeName eq 'verse' ? 1:0);
  
  my $note = "toAlternate($osisID, ".$elem->nodeName.", $type)";
  
  if (&getAltID($elem)) {
    $note .= "[already done]";
    if ($remove && $elem->getAttribute('type') eq $VSYS{'prefix'}.$VSYS{'TypeModified'}) {
      $elem->unbindNode();
      $note .= "[removed target tag]";
    }
    &Note($note);
    return $elem;
  }
  
  if (!$remove) {
    $telem = $elem->cloneNode(1);
    if ($telem->getAttribute('type')) {&ErrorBug("Type already set on $telem");}
    $telem->setAttribute('type', $VSYS{'prefix'}.$VSYS{'TypeModified'});
    $elem->parentNode->insertBefore($telem, $elem);
    $note .= "[cloned]";
  }
  
  # Convert to milestone
  if (!$type) {
    &ErrorBug("Element missing sID or eID: $elem");
  }
  if ($type eq 'start' && $osisID ne $elem->getAttribute('osisID')) {
    &ErrorBug("osisID is different than sID: $osisID != ".$elem->getAttribute('osisID'));
  }
  $elem->setAttribute('type', $VSYS{'prefix'}.'-'.$elem->nodeName.$VSYS{$type});
  $elem->setAttribute('annotateRef', $osisID);
  $elem->setAttribute('annotateType', $VSYS{'prefix'}.$VSYS{'AnnoTypeSource'});
  $elem->setNodeName('milestone');
  if ($elem->hasAttribute('osisID')) {$elem->removeAttribute('osisID');}
  if ($elem->hasAttribute('sID')) {$elem->removeAttribute('sID');}
  if ($elem->hasAttribute('eID')) {$elem->removeAttribute('eID');}
  $note .= "[converted]";
  
  # Add alternate verse number
  if (!$noAlt && $isVerseStart) {
    if ($osisID =~ /^[^\.]+\.\d+\.(\d+)\b.*?(\.(\d+))?$/) {
      my $newv = ($2 ? "$1-$3":"$1");
      my $alt = $XML_PARSER->parse_balanced_chunk('<hi type="italic" subType="x-alternate" resp="fitToVerseSystem"><hi type="super">('.$newv.')</hi></hi>');
      my $firstTextNode = @{$XPC->findnodes('following::text()[normalize-space()][1]', $elem)}[0];
      $firstTextNode->parentNode()->insertBefore($alt, $firstTextNode);
      $note .= "[added alternate verse \"$newv\"]";
    }
    else {&ErrorBug("Could not parse: $osisID =~ /^[^\.]+\.\d+\.(\d+)\b.*?(\.(\d+))?\$/");}
  }
  
  &Note($note);
  return $telem;
}

# This will take an alternate milestone element (verse or chapter, start 
# or end) and convert it back to original by undoing everything 
# toAlternate() did. It returns the original element.
sub undoAlternate($) {
  my $ms = shift;
  
  my $note = "undoAlternate(".$ms->getAttribute('type').', '.$ms->getAttribute('annotateRef').')';

  my $avn = @{$XPC->findnodes('following::text()[normalize-space()][1]/ancestor-or-self::*[name()="hi"][@subType="x-alternate"][@resp="fitToVerseSystem"][1]', $ms)}[0];
  if ($avn) {
    $avn->unbindNode();
    $note .= "[removed alternate verse number]";
  }
  my $vtag = @{$XPC->findnodes('preceding-sibling::*[1][@type="'.$VSYS{'prefix'}.$VSYS{'TypeModified'}.'"]', $ms)}[0];
  if ($vtag) {
    $vtag->unbindNode();
    $note .= "[removed verse tag]";
  }
  my $chvsTypeRE = '^'.$VSYS{'prefix'}.'-(chapter|verse)('.$VSYS{'start'}.'|'.$VSYS{'end'}.')$'; $chvsTypeRE =~ s/-/\\-/g;
  if ($ms->getAttribute('type') =~ /$chvsTypeRE/) {
    my $name = $1; my $type = $2;
    $ms->setNodeName($name);
    if ($type eq '-start') {
      $ms->setAttribute('sID', $ms->getAttribute('annotateRef'));
      $ms->setAttribute('osisID', $ms->getAttribute('annotateRef'));
    }
    else {$ms->setAttribute('eID', $ms->getAttribute('annotateRef'));}
    $ms->removeAttribute('annotateRef');
    $ms->removeAttribute('annotateType');
    $ms->removeAttribute('type');
  }
  else {&ErrorBug("Can't parse: ".$ms->getAttribute('type')." !~ /$chvsTypeRE/");}
  
  $note .= "[converted milestone to verse]";
  &Note($note);
  
  return $ms;
}

# Report an error if any verse in this hypothetical osisID is already listed 
# in an existing osisID (to catch any bug causing multiple verse tags to cover 
# the same verse)
sub osisIDCheckUnique($$) {
  my $osisID = shift;
  my $xml = shift;
  
  my @verses = split(/\s+/, $osisID);
  foreach my $v (@verses) {
    my $chv = &getVerseTag($v, $xml, 0);
    if ($chv) {
      &ErrorBug("osisIDCheckUnique($osisID): Existing verse osisID=\"".$chv->getAttribute('osisID')."\" includes \"$v\"");
    }
  }
}

# Reads the osis file to find a chapter's smallest verse number
sub getFirstVerseInChapterOSIS($$$) {
  my $bk = shift;
  my $ch = shift;
  my $xml = shift;
  
  my @vs = $XPC->findnodes("//osis:verse[starts-with(\@osisID, '$bk.$ch.')]", $xml);
  
  my $fv = 200;
  foreach my $v (@vs) {if ($v->getAttribute('osisID') =~ /^\Q$bk.$ch.\E(\d+)/ && $1 < $fv) {$fv = $1;}}
  if ($fv == 200) {
    &ErrorBug("getFirstVerseInChapterOSIS($bk, $ch): Could not find first verse.");
    return '';
  }
  
  return $fv;
}

# Reads the osis file to find a chapter's largest verse number
sub getLastVerseInChapterOSIS($$$) {
  my $bk = shift;
  my $ch = shift;
  my $xml = shift;
  
  my @vs = $XPC->findnodes("//osis:verse[starts-with(\@osisID, '$bk.$ch.')]", $xml);
  
  my $lv = 0;
  foreach my $v (@vs) {if ($v->getAttribute('osisID') =~ /\b\Q$bk.$ch.\E(\d+)$/ && $1 > $lv) {$lv = $1;}}
  if (!$lv) {
    &ErrorBug("getLastVerseInChapterOSIS($bk, $ch): Could not find last verse.");
    return '';
  }
  
  return $lv;
}

# Checks that a 4 part verse range covers an entire chapter in the given
# verse system. Also normalizes verses so they never contain empty values.
sub isWholeVsysChapter($$\$\$$) {
  my $bk  = shift;
  my $ch  = shift;
  my $vsP  = shift;
  my $lvP  = shift;
  my $xml = shift;
  
  my $maxv = &getLastVerseInChapterOSIS($bk, $ch, $xml);

  my $haveVS = ($$vsP ? 1:0);
  $$vsP = ($haveVS ? $$vsP:1);
  $$lvP = ($$lvP ? $$lvP:($haveVS ? $$vsP:$maxv));

  return ($$vsP == 1 && $$lvP == $maxv);
}

# Take a verse element and return its alternate id, or '' if there isn't
# one. If returnElem is set the entire milestone element is returned.
sub getAltID($$) {
  my $verseElem = shift;
  my $returnElem = shift;
  
  my $ms = @{$XPC->findnodes('following::*[1][name()="milestone"][starts-with(@type, "'.$VSYS{'prefix'}.'-verse")]', $verseElem)}[0];
  if (!$ms) {return '';}
  return ($returnElem ? $ms:$ms->getAttribute('annotateRef'));
}

1;
