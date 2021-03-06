#!/usr/bin/perl
# This file is part of "osis-converters".
# 
# Copyright 2012 John Austin (gpl.programs.info@gmail.com)
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

# usage: osis2GoBible.pl [Bible_Directory]

# Run this script to create GoBible mobile phone Bibles from an osis 
# file. The following input files need to be in a 
# "Bible_Directory/GoBible" sub-directory:
#    collections.txt            - build-control file
#    ui.properties              - user interface translation
#    icon.png                   - icon for the application
#    normalChars.txt (optional) - character replacement file
#    simpleChars.txt (optional) - simplified character replacement file

# OSIS wiki: http://www.crosswire.org/wiki/OSIS_Bibles
# GoBible wiki: http://www.crosswire.org/wiki/Projects:Go_Bible

use File::Spec; $SCRIPT = File::Spec->rel2abs(__FILE__); $SCRD = $SCRIPT; $SCRD =~ s/([\\\/][^\\\/]+){1}$//; require "$SCRD/scripts/bootstrap.pl";

$GOBIBLE = "$INPD/GoBible";
if (!-e $GOBIBLE) {&Error("Missing GoBible directory: $GOBIBLE", "Copy the default/bible/GoBible directory to $INPD", 1);}

&runAnyUserScriptsAt("GoBible/preprocess", \$INOSIS);

$INXML = $XML_PARSER->parse_file($INOSIS);
foreach my $e (@{$XPC->findnodes('//osis:list[@subType="x-navmenu"]', $INXML)}) {$e->unbindNode();}
$output = $INOSIS; $output =~ s/^(.*?\/)([^\/]+)(\.[^\.\/]+)$/$1removeNavMenu$3/;
open(OUTF, ">$output");
print OUTF $INXML->toString();
close(OUTF);
$INOSIS = $output;

&runScript($MODULETOOLS_BIN."osis2gobible.xsl", \$INOSIS);

&Log("\n--- Creating Go Bible osis.xml file...\n");
&copy($INOSIS, "$TMPDIR/osis.xml");

@FILES = ("$GOBIBLE/ui.properties", "$GOBIBLE/collections.txt", "$TMPDIR/osis.xml");
foreach my $f (@FILES) {if (!-e $f) {&Error("Missing required file: $f", "Copy the default file from defaults/bible/GoBible to $INPD.");}}
if (!-e "$GOBIBLE/icon.png") {&Error("Missing icon file: $GOBIBLE/icon.png", "Copy the default file from defaults/bible/GoBible to $INPD.");}

&Log("\n--- Converting characters (normal)\n");
require("$SCRD/scripts/bible/GoBible/goBibleConvChars.pl");
&goBibleConvChars("normal", \@FILES);
copy("$GOBIBLE/icon.png", "$TMPDIR/normal/icon.png");
&makeGoBible("normal");

if (-e "$GOBIBLE/simpleChars.txt") {
  &Log("\n--- Converting characters (simple)\n");
  &goBibleConvChars("simple", \@FILES);
  copy("$GOBIBLE/icon.png", "$TMPDIR/simple/icon.png");
  &makeGoBible("simple");
}
else {&Warn("Skipping simplified character apps because there is no simpleChars.txt file.", "Copy the default file from defaults/bible/GoBible to $INPD.");}

sub makeGoBible($) {
  my $type = shift;
  &Log("\n--- Running Go Bible Creator with collections.txt\n");
  my $cmd = "cp ".&escfile("$TMPDIR/$type/ui.properties")." ".&escfile($GO_BIBLE_CREATOR."GoBibleCore/ui.properties");
  &Log($cmd."\n");
  system($cmd);
  $cmd = "java -jar ".&escfile($GO_BIBLE_CREATOR."GoBibleCreator.jar")." ".&escfile("$TMPDIR/$type/collections.txt")." >> ".&escfile($LOGFILE);
  &Log($cmd."\n");
  system($cmd);

  &Log("\n--- Copying module to MKS directory $MOD".$ConfEntryP->{"Version"}."\n");
  chdir("$TMPDIR/$type");
  opendir(DIR, "./");
  my @f = readdir(DIR);
  closedir(DIR);
  for (my $i=0; $i < @f; $i++) {
    if ($f[$i] !~ /\.(jar|jad)$/i) {next;}
    copy("$TMPDIR/$type/$f[$i]", "$GBOUT/$f[$i]");
  }
  chdir($SCRD);
}

&timer('stop');

1;
