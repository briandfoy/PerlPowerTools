@perl -S -x %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
@goto endofperl
#!perl -w 
#line 5
my $prog = shift || die "Usage:$0 <program>\n";
my @path = ('.',split(/;/,$ENV{'PATH'}));
my @suf  = split(/;/,$ENV{'PATHEXT'});
unshift(@suf,'') if ($prog =~ /\.[^\.]+$/);
foreach my $dir (@path)
 {
  foreach my $sfx (@suf)
   {
    my $name = $dir . '\\' . $prog . $sfx;
    if (-r $name)
     {
      print $name,"\n";
      exit;
     }
   } 
 } 
#print join(':',@path),"\n";
__END__
:endofperl
