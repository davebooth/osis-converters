#!/usr/bin/perl
# This file is part of "osis-converters".
# 
# Copyright 2018 John Austin (gpl.programs.info@gmail.com)
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

# This script might be loaded on any operating system.

# This is the starting point for osis-converter scripts. Global path 
# variables are initialized or cleaned up and then the script is 
# started.

# This script must be called with the following line, having X replaced 
# by the calling script's proper sub-directory depth (and don't bother
# trying to shorten anything since 'require' only handles absolute 
# paths, and File::Spec->rel2abs(__FILE__) is the only way to get the 
# script's absolute path, and it must work on both host opsys and 
# Vagrant and the osis-converters installation directory name is 
# unknown):
# use File::Spec; $SCRIPT = File::Spec->rel2abs(__FILE__); $SCRD = $SCRIPT; $SCRD =~ s/([\\\/][^\\\/]+){X}$//; require "$SCRD/scripts/bootstrap.pl";

use File::Spec;

$INPD = shift;
$LOGFILE = shift; # the special value of 'none' will print to the console with no log file created

$INPD = File::Spec->rel2abs($INPD);
$INPD =~ s/\\/\//g;
$INPD =~ s/\/(sfm|GoBible|eBook|html|sword|images)(\/.*?$|$)//; # allow using a subdir as project dir
if (!-e $INPD) {die "Error: Project directory \"$INPD\" does not exist. Check your command line.\n";}
  
if ($LOGFILE && $LOGFILE ne 'none') {
  $LOGFILE = File::Spec->rel2abs($LOGFILE);
  $LOGFILE =~ s/\\/\//g;
}

$SCRIPT = File::Spec->rel2abs($SCRIPT);
$SCRIPT =~ s/\\/\//g;

$SCRD = File::Spec->rel2abs($SCRD);
$SCRD =~ s/\\/\//g;

require "$SCRD/scripts/common_opsys.pl";
&start_script();

1;
