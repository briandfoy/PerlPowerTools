#!/usr/bin/perl -0777    
# ppt - reformat input as paper tape 
# mjd@plover.com

print "----------\n";
for (split //, <>) {
    $_ = unpack "B8", $_;
    s/.(....)(...)/$1.$2/;
    tr/01/ o/;
    print "|$_|\n";
} 

print "----------\n";

