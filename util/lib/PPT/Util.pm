package PPT::Util;
# $Id: Util.pm,v 1.2 2004/08/05 14:24:55 cwest Exp $
use strict;

#BEGIN{sub Pod::Simple::DEBUG () {10} }
use base qw[Exporter];
use Config::General;
use IO::All;
use Pod::Simple::HTML;
use Carp;
use FindBin;
use CGI qw[:all];
use Template;

use vars qw[@EXPORT $BASE $CONFIG $HTML $SRC $V7DOC $HTMLSRC $TT
$TTWRAPPER $TEMPLATE $BIN $CFG $README];
@EXPORT = qw[config_read config_cmds create_cmd_doc copy_cmd_src
create_cmd_index copy_v7doc clean_html_dir generate_what generate_table
generate_page clean_bin_dir copy_dist_contrib];
$BASE      = "$FindBin::Bin/.."; # relative to $dist/util
$CONFIG    = "$BASE/data/index.cfg";
$HTML      = "$BASE/html";
$SRC       = "$BASE/src";
$V7DOC     = "$BASE/data/v7doc";
$HTMLSRC   = "$BASE/html-src";
$TT        = "$BASE/data/tt";
$TTWRAPPER = "$TT/wrapper.tt";
$BIN       = "$BASE/bin";
$README    = "$BASE/README"; do $README; # evil trick for easy version numbering
$TEMPLATE  = Template->new({
    PROCESS     => $TTWRAPPER,
    OUTPUT_PATH => $HTML,
    ABSOLUTE    => 1,
    VARIABLES   => { version => __PACKAGE__->VERSION },
});

sub config_read {
    my $config = shift || $CONFIG;
    $CFG = { ParseConfig(
        -ConfigFile           => $config,
        -LowerCaseNames       => 1,
        -AutoTrue             => 1,
    ) }
}

sub config_cmds {
    my $class = shift;
    config_read unless $CFG;
    my @cmds;
    foreach ( keys %{$CFG->{command}} ) {
        push @cmds, $_ if
          ($class ? ($CFG->{command}->{$_}->{class} eq $class) : 1);
    }
    return @cmds;
}

sub _cmd_contrib {
    my $cmd = shift;
    croak "Requires command" unless $cmd;
    config_read unless $CFG;

    my $contribs = $CFG->{command}->{$cmd}->{contrib};
    my @contrib = ();
       @contrib = ref($contribs) eq 'ARRAY' ? @{$contribs} : $contribs
         if $contribs;

    my ($basename) = $cmd =~ /(.+)\.\d+/;
    return (\@contrib, $basename);
}

sub create_cmd_doc {
    my ($contrib, $basename) = &_cmd_contrib;
    return unless @{$contrib};
    
    foreach ( @{$contrib} ) {
        mkdir "$HTML/commands/$basename";
        my $parse = Pod::Simple::HTML->new;
        my $out   = '';
        $parse->output_string(\$out);
        my $res;
        if ( -e "$SRC/$basename/$basename.pod" ) {
            $res = $parse->parse_file("$SRC/$basename/$basename.pod");
        } else {
            $res = $parse->parse_file("$SRC/$basename/$_->{name}");
        }

        io("$HTML/commands/$basename/$_->{name}.html")->print($out)
          if $res;
    }
}

sub copy_cmd_src {
    my ($contrib, $basename) = &_cmd_contrib;
    return unless @{$contrib};
    
    foreach ( @{$contrib} ) {
        mkdir "$HTML/commands/$basename";
        io("$SRC/$basename/$_->{name}") > io("$HTML/commands/$basename/$_->{name}");
        if ( $_->{support} ) {
          io("$SRC/$basename/$_") > io("$HTML/commands/$basename/$_")
            for split m/\s+/, $_->{support};
        }
    }
}

sub copy_v7doc {
    my $cmd = shift;
    croak "Requires command" unless $cmd;
    config_read unless $CFG;

    my ($basename) = $cmd =~ /(.+)\.\d+/;
    mkdir "$HTML/commands/$basename";
    io("$V7DOC/$cmd") > io("$HTML/commands/$basename/$cmd")
      if -e "$V7DOC/$cmd";
}

sub create_cmd_index {
    my ($contrib, $basename) = _cmd_contrib(@_);
    my ($section) = $_[0] =~ /(\d+)$/;

    foreach ( @{$contrib} ) {
        $_->{manpage} = (-s "$HTML/commands/$basename/$_->{name}.html" ? 1 : 0);
    }
    
    $TEMPLATE->process("$TT/command.tt", {
                           command => $basename,
                           contrib => $contrib,
                           v7      => (-e "$V7DOC/$_[0]" ? $_[0] : undef ),
                           name    => $_[0],
                       },
                       "commands/$basename/index.html") || die $TEMPLATE->error;
}

sub clean_html_dir {
    `find $HTML/commands/* -type f | grep -v CVS | xargs rm`; # I know, it's cheap.
    `rm $HTML/*.html`;
}

sub clean_bin_dir {
    `rm $BIN/*`;
}

sub _make_cmd_links {
    my @cmds = @_;

    my %list;
    foreach ( @cmds ) {
         my ($base) = $_ =~ /(.+)\.\d+$/;
         $list{$base} = @{(_cmd_contrib($_))[0]} ? 1 : 0;
    }
    %list;
}

sub generate_what {
    my %commands = _make_cmd_links( sort {$a cmp $b} config_cmds('command') );
    my %games    = _make_cmd_links( sort {$a cmp $b} config_cmds('game') );

    $TEMPLATE->process("$TT/what.tt", { commands => \%commands, games => \%games },
                       "what.html") || die $TEMPLATE->error;
}

sub generate_table {
    my @commands = sort {$a cmp $b} config_cmds;
    
    my @rows;
    foreach (@commands) {
        my ($contrib, $base) = _cmd_contrib($_);
        my @row = ($base);
        push @row, $CFG->{command}->{$_}->{class};
        push @row, [map $_->{author}, @{$contrib}];
        push @row, [map $_->{date}, @{$contrib}];
        push @row, @{$contrib} ? 'done' : 'missing';
        push @row, (grep{-e "$HTML/commands/$base/$_->{name}.html"}@{$contrib}) ? 'done' : 'missing';
        my @tests;
        foreach my $c ( @{$contrib} ) {
            $_ = $c;
            if ( $_->{test} ) {
                my @test = ref($_->{test}) eq 'HASH' ? $_->{test} : @{$_->{test}};
                $_->{command} = $c->{name} for @test;
                push @tests, @test;
            }
        }
        push @row, \@tests;
        push @rows, \@row;
    }

    $TEMPLATE->process("$TT/doneness.tt", { commands => \@rows }, 'doneness.html')
      || die $TEMPLATE->error;
}

sub generate_page {
    my $page_name = shift;
    my $original  = "$HTMLSRC/$page_name";
    
    $TEMPLATE->process($original, {}, $page_name)
      || die $TEMPLATE->error;
}

sub copy_dist_contrib {
    my ($contrib, $basename) = _cmd_contrib(@_);
    return unless @{$contrib};
    
    my $dist;
    if ( @{$contrib} > 1 ) {
        foreach ( @{$contrib} ) {
            $dist = $_->{name} and last if $_->{dist} && $_->{dist} == 1;
        }
    } else {
        $dist = $contrib->[0]->{name}
          unless exists $contrib->[0]->{dist} && $contrib->[0]->{dist} == 0;
    }
    return unless $dist;
    
    $dist = "$SRC/$basename/$dist";
    io($dist) > io("$BIN/$basename");
    chmod 0755, "$BIN/$basename";
}

1;


