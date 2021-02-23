#!/usr/bin/perl
# This file is part of "osis-converters".
# 
# Copyright 2020 John Austin (gpl.programs.info@gmail.com)
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

use strict;
use Encode;
use File::Path; 

# This file is used only by forks.pm to run any function as a separate 
# osis-converters thread.

#print("\nDEBUG: fork.pm ARGV=\n".join("\n", @ARGV)."\n");

# INPD              = @ARGV[0]; # - Full path of the project directory.
# LOGFILE           = @ARGV[1]; # - Full path of log file for this fork, 
                                #   which must be in a subdirectory that 
                                #   is unique to this fork instance.
our $forkScriptName = @ARGV[2]; # - Used by osis-converters to signal it 
                                #   is running as a fork of a parent script.
our $forkRequire    = @ARGV[3]; # - Full path of script containing $forkFunc
our $forkFunc       = @ARGV[4]; # - Name of function to run
our @forkArgs;      my $a = 5;  # - Arguments to use with $forkFunc

while (defined(@ARGV[$a])) {push(@forkArgs, decode('utf8', @ARGV[$a++]));}

# Create the fork tmp directory and startup log
my $forklog = @ARGV[1]; 
my $tmpdir  = @ARGV[1]; $tmpdir =~ s/(?<=\/)[^\/]+$//;
File::Path::make_path($tmpdir);
@ARGV[1] = "$tmpdir/OUT_startup.txt";

# Initialize osis-converters
use strict; use File::Spec; our $SCRIPT = File::Spec->rel2abs(__FILE__); our $SCRD = $SCRIPT; $SCRD =~ s/([\\\/][^\\\/]+){3}$//; require "$SCRD/lib/common/bootstrap.pm"; &init(shift, shift);
our $LOGFILE = $forklog;

require("$SCRD/lib/forks/fork_funcs.pm");
require($forkRequire);

if (!exists &{$forkFunc}) {
  &ErrorBug("forkFunc '$forkFunc' does not exist in '$forkRequire'.\n", 1);
}

# Run the function
no strict "refs";

&Debug("Starting fork: $forkFunc(".join(', ', map("'$_'", @forkArgs)).")");

&$forkFunc(@forkArgs);

1;
