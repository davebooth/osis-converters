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

sub toVersificationBookOrder($$) {
  my $vsys = shift;
  my $osis = shift;
  
  if (!$vsys) {$vsys = "KJV";}

  &Log("\n\nOrdering books and peripherals in \"$osis\" according to versification = $vsys\n");

  my $canonP;
  my $bookOrderP;
  my $testamentP;
  my $bookArrayP;
  
  if (!&getCanon($vsys, \$canonP, \$bookOrderP, \$testamentP, \$bookArrayP)) {
    &Log("ERROR: Not re-ordering books in OSIS file!\n");
    return;
  }

  my $xml = $XML_PARSER->parse_file($osis);

  # remove all books
  my @books = $XPC->findnodes('//osis:div[@type="book"]', $xml);
  foreach my $bk (@books) {
    $bk = $bk->parentNode()->removeChild($bk);
  }

  # remove all introductions
  my @intros = $XPC->findnodes('//osis:div[@type="introduction"][not(@subType)]', $xml);
  foreach my $intro (@intros) {
    $intro = $intro->parentNode()->removeChild($intro);
  }
  
  # remove bookGroups (if any)
  my @removeBookGroups = $XPC->findnodes('//osis:div[@type="bookGroup"]', $xml);
  foreach my $removeBookGroup (@removeBookGroups) {$removeBookGroup->parentNode()->removeChild($removeBookGroup);}
  
  # create empty bookGroups
  my @bookGroups;
  push(@bookGroups, XML::LibXML::Element->new("div"));
  push(@bookGroups, @bookGroups[0]->cloneNode());
  foreach my $bookGroup (@bookGroups) {$bookGroup->setAttribute('type', 'bookGroup');}
    
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
  
  foreach my $bk (@books) {
    if ($bk ne '') {&Log("ERROR: Book \"$bk\" not found in $vsys Canon\n");}
  }
  
  my $osisText = @{$XPC->findnodes('//osis:osisText', $xml)}[0];
  foreach my $bookGroup (@bookGroups) {
    if (!$XPC->findnodes('descendant::*', $bookGroup)) {next;}
    $osisText->appendChild($bookGroup);
  }

  # place all introductions in their proper places
  for (my $i=@intros-1; $i >= 0; $i--) {
    my $intro = @intros[$i];

    # read the first comment to find desired target location(s), if any
    my @commentNode = $XPC->findnodes('./comment()', $intro);

    # default target is the introduction to first book
    if (!@commentNode || @commentNode[0] !~ /\s\S+ == \S+/) {
      my @bkdef = $XPC->findnodes('//osis:div[@type="book"]', $xml);
      if (@bkdef) {&placeIntroduction($intro, @bkdef[0]);}
      else {&Log("ERROR: Removing intro! No book in which to place it:\n$intro\n");}
    }
    else {
      my $comment = @commentNode[0];
      #<!-- id comment - (FRT) titlePage == osis:div[@type='book'], tableofContents == remove, preface == osis:div[@type='bookGroup'][1], preface == osis:div[@type='bookGroup'][1] -->
      $comment =~ s/^<\!\-\-.*?(?=\s\S+ ==)//; # strip beginning stuff
      $comment =~ s/\s*\-\->$//; # strip end stuff
      
      # process comment parts in reverse order to acheive expected element order
      my @parts = split(/(,\s*\S+ == )/, ", $comment");
      for (my $x=@parts-1; $x>0; $x -= 2) {
        my $part = $parts[$x-1] . $parts[$x];
        $part =~ s/^,\s*//;
        if ($part !~ /^(\S+) == (.*?)$/) {
          &Log("ERROR: Unhandled location assignment \"$part\" in \"".@commentNode[0]."\" in CF_usfm2osis.txt\n");
        }
        my $emsg = "as specified in \"$part\" in CF_usfm2osis.txt";
        my $int = $1;
        my $xpath = $2;
        if ($xpath =~ /^remove$/i) {
          &Log("NOTE: Removing \"$int\" as requested\n");
          next;
        }
        # div[@type"bookGroup"] were created without osis namespace (otherwise the resulting tags are monstrous) so here's a fix
        $xpath =~ s/osis\:(div(\[[^\]]+\])*\[\@type=["']bookGroup["']\])/$1/g;
        my @targXpath = $XPC->findnodes('//'.$xpath, $xml);
        if (!@targXpath) {
          &Log("ERROR: Removing intro! Could not locate \"$xpath\" $emsg\n");
          next;
        }
        if ($int eq 'introduction') {&placeIntroduction($intro, @targXpath[$#targXpath]);}
        else {
          my @periphs = $XPC->findnodes('.//osis:div[@type="introduction"][@subType="'.$int.'"]', $intro);
          if (!@periphs) {
            @periphs = $XPC->findnodes('.//osis:div[@type="'.$int.'"]', $intro);
            if (!@periphs) {
              &Log("ERROR: Removing intro! Did not find \"$int\" $emsg\n");
              next;
            }
          }
          my $periph = @periphs[$#periphs]->parentNode()->removeChild(@periphs[$#periphs]);
          &placeIntroduction($periph, @targXpath[$#targXpath]);
        }
      }
    }
  }
  
  # Don't check that all books/chapters/verses are included in this 
  # OSIS file, but DO insure that all verses are in sequential order 
  # without any skipping (required by GoBible Creator).
  my @verses = $XPC->findnodes('//osis:verse[@osisID]', $xml);
  my $lastbkch = '';
  my $vcounter;
  foreach my $verse (@verses) {
    my $insertBefore = 0;
    my $osisID = $verse->getAttribute('osisID');
    if ($osisID !~ /^([^\.]+\.\d+)\.(\d+)/) {&Log("ERROR: Can't read vfirst \"$v\"\n");}
    my $bkch = $1;
    my $vfirst = (1*$2);
    if ($bkch ne $lastbkch) {$vcounter = 1;}
    $lastbkch = $bkch;
    foreach my $v (split(/\s+/, $osisID)) {
      if ($v !~ /^\Q$bkch\E\.(\d+)(\-(\d+))?$/) {&Log("ERROR: Can't read v \"$v\" in \"$osisID\"\n");}
      my $vv1 = (1*$1);
      my $vv2 = ($3 ? (1*$3):$vv1);
      for (my $vv = $vv1; $vv <= $vv2; $vv++) {
        if ($vcounter > $vv) {&Log("ERROR: Verse number goes backwards \"$osisID\"\n");}
        while ($vcounter < $vv) {
          $insertBefore++; $vcounter++;
        }
        $vcounter++;
      }
    }
    if ($insertBefore) {
      my $v = ($vfirst-1-$insertBefore);
      my $osisID = "$bkch.$v";
      my @vsid = $XPC->findnodes('//osis:verse[@osisID="'.$osisID.'"]', $xml);
      if (!@vsid) {&Log("ERROR: Problem locating verse osisID=\"".$osisID."\"\n");}
      else {
        my @veid = $XPC->findnodes('//osis:verse[@eID="'.@vsid[0]->getAttributeNode('sID')->getValue().'"]', $xml);
        while ($insertBefore--) {
          $v++;
          my $id = "$bkch.$v";
          my @ats = (@vsid[0]->getAttributeNode('osisID'), @vsid[0]->getAttributeNode('sID'), @veid[0]->getAttributeNode('eID'));
          foreach my $at (@ats) {$at->setValue($at->getValue()." $bkch.$v");}
        }
        &Log("WARNING: Missing verse(s). Changing verse osis='$osisID' to '".@vsid[0]->getAttribute('osisID')."'. You should check that this is intentional and not the result of a conversion problem!\n");
      }
    }
  }
  
  my $t = $xml->toString();
  
  # removed books left a \n dangling, so remove it too
  $t =~ s/\n+/\n/gm;
  
  open(OUTF, ">$osis");
  print OUTF $t;
  close(OUTF);
}

sub placeIntroduction($$) {
  my $intro = shift;
  my $dest = shift;
  if ($dest->nodeName =~ /\:?header$/) {$dest->parentNode()->insertAfter($intro, $dest);}
  elsif ($dest->hasChildNodes()) {$dest->insertBefore($intro, $dest->firstChild);}
  else {$dest->parentNode()->insertAfter($intro, $dest);}
}
1;
