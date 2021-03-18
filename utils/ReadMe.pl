#! /usr/bin/perl

use strict; 

# Update osis-converters ReadMe.md

BEGIN { # allow subs to be redefined
  our $SCRIPT_NAME = 'convert';
  use strict; use File::Spec; our $SCRIPT = File::Spec->rel2abs(__FILE__); our $SCRD = $SCRIPT; $SCRD =~ s/([\\\/][^\\\/]+){2}$//; require "$SCRD/lib/common/bootstrap.pm";
}

our $SCRD;

open(INF, ">:encoding(UTF-8)", "$SCRD/ReadMe.md") || die;

print INF "# osis-converters
On Ubuntu 16 or 18 `sudo ./provision.sh` will install the necessary dependencies. On other operating systems, including MS-Windows and MacOS, install [Vagrant](https://www.vagrantup.com/downloads), [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Perl](https://www.activestate.com/products/perl/downloads/) and osis-converters will run in a virtual machine.\n";
print INF &help();

close(INF);

########################################################################
########################################################################

# Redefine subs from help.pm to output md markup.
sub helpList {
  my $listheadAP = shift;
  my $listAP = shift;
  
  my $r;
  
  if (!$listheadAP->[0] && !$listheadAP->[1]) {
    foreach my $row (@{$listAP}) {
      $r .= $row->[0] . ': ' . &para(&helpTags($row->[1]), 0, 0, 0, 1, 1) . "\n";
    }
    $r .= "\n";
    return $r;
  }
  
  $r .= &esc($listheadAP->[0]) . ' | ' . 
        &helpTags(&esc($listheadAP->[1])) . "\n";
        
  $r .= '-' x length($listheadAP->[0]) . ' | ' . 
        '-' x length(&helpTags($listheadAP->[1])) . "\n";
                    
  foreach my $row (@{$listAP}) {
    my $e = $row->[0];
    if ($e !~ /^[\(\*]/) {$e = '**' . $e . '**';}
    $r .= &esc($e) . ' | ' . &para(&esc($row->[1]), 0, 0, 0, 1, 1);
  }
  $r .= "\n";
  
  return $r;
}

sub esc {
  my $t = shift;
  
  $t =~ s/\|/&#124;/g;
  return $t;
}

sub helpTags {
  my $t = shift;
  
  # Local file paths: PATH(<encoded-path>?)
  $t =~ s/PATH\(([^\)]*)\)/
    my $p = $1; 
    my $e; 
    my $r = &const($1,\$e); 
    '`' . &helpPath($e ? $r : &shortPath($r)) . '`'/seg;
  
  # Copy of help: HELP(<script>;<heading>;[<key>])
  $t =~ s/HELP\(([^\)]+)\)/&help($1,undef,1,1)/seg;
    
  # Hyperlinks: [text](href)
  $t =~ s/\[([^\]]*)\]\(([^\)]+)\)/my $r=($1 ? "[$1]($2)":"[$2]($2)")/seg;
 
  return $t;
}

sub format {
  my $text = &helpTags(shift);
  my $type = shift;
  
  if (!$text) {return;}
  
  my @args; if ($type =~ s/:(.+)$//) {@args = split(/,/, $1);}
  
  if ($type eq 'title') {
    return "\n# $text \n";
  }
  elsif ($type eq 'heading') {
    return "\n## $text \n";
  }
  elsif ($type eq 'sub-heading') {
    return "\n### $text \n";
  }
  elsif ($type eq 'para') {
    return &para($text, @args);
  }
  
  return $text;
}

sub para {
  my $t = &helpTags(shift);
  my $indent = shift; if (!defined($indent)) {$indent = 0;}
  my $left   = shift; if (!defined($left))   {$left   = 0;}
  my $width  = shift; if (!defined($width))  {$width  = 72;}
  my $noBlankLine = shift;
  my $noNewlines = shift;
  
  $t =~ s/\s*\n\s*/ /g;
  $t =~ s/(^\s*|\s*$)//g;
  if (!$noNewlines) {
    $t =~ s/(\s*\\b\s*)/\n/g;
  }
  else {
    $t =~ s/(\s*\\b\s*)/ /g;
  }
  
  my $r = $t;
  
  $r .= "\n";
  if (!$noBlankLine) {$r .= "\n";}
  
  return $r;
}
