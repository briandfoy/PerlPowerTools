package SymbolicMode;

#
# $Id: SymbolicMode.pm,v 1.3 2004/08/05 14:18:01 cwest Exp $
#
# $Log: SymbolicMode.pm,v $
# Revision 1.3  2004/08/05 14:18:01  cwest
# cleanup, new version number on website
#
# Revision 1.1  2004/07/23 20:10:01  cwest
# initial import
#
# Revision 1.1  1999/03/07 12:03:54  abigail
# Initial revision
#
#

use strict;

sub mod ($$) {
    my $symbolic     = shift;
    my $file         = shift;

    # Initialization.
    # The 'user', 'group' and 'other' groups.
    my @ugo          = qw /u g o/;
    # Bit masks for '[sg]uid', 'sticky', 'read', 'write' and 'execute'.
    # Can't use qw // cause silly Perl doesn't know '2' is a number
    # when dealing with &= ~$bit.
    my %bits         = (s => 8, t => 8, r => 4, w => 2, x => 1);


    # For parsing.
    my $who_re       = '[augo]*';
    my $action_re    = '[-+=][rstwxXugo]*';


    # Find the current permissions. This is what we start with.
    my $mode         = sprintf "%04o" => (stat $file) [2] || 0;
    my $current      = substr $mode => -3;  # rwx permissions for ugo.

    my %perms;
       @perms {@ugo} = split // => $current;

    # Handle the suid, guid and sticky bits.
    # It looks like permission are 4 groups of 3 bits, groups for user,
    # group and others, and a group for the special flags, but they are
    # really 3 groups of 4 bits. Or maybe not. 
    # Anyway, this function is greatly simplified by treating them as
    # 3 4-bit groups. The highest bit will be "special" one. suid for
    # the users group, guid for the group group, and the sticky bit
    # for the others group.
    my $special      = substr $mode => -4, 1;
    my $bit          = 1;
    foreach my $c (reverse @ugo) {
        $perms {$c} |= 8 if $special & $bit;
        $bit <<= 1;
    }

    # Keep track of the original permissions.
    my %orig         = %perms;

    # Find the umask setting, and store the bits for each group
    # in a hash.
    my %umask;                              # umask bits.
       @umask {@ugo} = split // => sprintf "%03o" => umask;


    # Time to parse...
    foreach my $clause (split /,/ => $symbolic) {

        # Perhaps we should die if we can't parse it?
        return undef unless
            my ($who, $actions) =
                $clause =~ /^($who_re)((?:$action_re)+)$/o;
            # We would rather split the different actions out here,
            # but there doesn't seem to be a way to collect them.
            # /^($who_re)($action_re)+/ only gets the last one.
            # Now, we have to reparse in later.

        my %who;
        if ($who) {
            $who =~ s/a/ugo/;  # Ignore multiple 'a's.
            @who {split // => $who} = undef;
        }

        # @who will contain who these settings applies to.
        # if who isn't set, it might be masked with the umask,
        # hence, this isn't the final decision.
        # Maybe we don't need this.
        my @who = $who ? keys %who : @ugo;

        foreach my $action (split /(?=$action_re)/o => $actions) {
            # The first character has to be the operator.
            my $operator = substr $action, 0, 1;
            # And the rest are the permissions.
            my $perms    = substr $action, 1;

            # BSD documentation says 'X' is to be ignored unless
            # the operator is '-'. GNU, HP, SunOS and Solaris handle
            # '-' and '=', while OpenBSD ignores only '-'.
            # Solaris, HP and OpenBSD all turn a file with permission
            # 666 to a file with permission 000 if chmod =X is
            # is applied on it. SunOS and GNU act as if chmod = was
            # applied to it. I cannot find out what the reasoning
            # behind the choices of Solaris, HP and OpenBSD is.
            # GNU and SunOS seem to ignore the 'X', which, after
            # careful studying of the documentation seems to be
            # the right choice.
            # Therefore, remove any 'X' if the operator ain't '+';
            $perms =~ s/X+//g unless $operator eq '+';

            # If there are no permissions, things are simple.
            unless ($perms) {
                # Things like u+ and go- are ignored; only = makes sense.
                next unless $operator eq '=';
                           # Clear permissions on u= and go=.
                if ($who) {@perms {keys %who} = (0) x 3;}
                           # '=' is special. Sets permissions to the umask.
                else      {%perms             = %umask;}
                next;
            }

            # If we arrive here, $perms is a string.
            # We can iterate over the characters.
            foreach (split // => $perms) {
                if ($_ eq 'X') {
                    # We know the operator eq '+'.
                    # Permission of `X' is special. If used on a regular file,
                    # the execution bit will only be turned on if any of the
                    # execution bits of the _unmodified_ file are turned on.
                    # That is,
                    #      chmod 600 file; chmod u+x,a+X file;
                    # should result in the file having permission 700, not 711.
                    # GNU and SunOS get this wrong;
                    # Solaris, HP and OpenBSD get it right.
                    next unless -d $file || grep {$orig {$_} & 1} @ugo;
                    # Now, do as if it's an x.
                    $_ = 'x';
                }

                if (/[st]/) {
                    # BSD man page says operations on 's' and 't' are to
                    # be ignored if they operate only on the "other" group.
                    # GNU and HP happely accept 'o+t'. Sun rejects 'o+t',
                    # but also rejects 'g+t', accepting only 'u+t'.
                    # OpenBSD acceps both 'u+t' and 'g+t', ignoring 'o+t'.
                    # We do too.
                    # OpenBSD however, accepts 'o=t', clearing all the bits
                    # of the "other" group.
                    # We don't, as that doesn't make any sense, and doesn't
                    # confirm to the documentation.
                    next if $who =~ /^o+$/;
                }

                # Determine the $bit for the mask.
                my $bit = /[ugo]/ ? $orig {$_} & ~8 : $bits {$_};

                die "Weird permission `$_' found\n" unless defined $bit;
                                                            # Should not happen.

                # Determine the set on which to operate.
                my @set = $who ? @who : grep {!($umask {$_} & $bit)} @ugo;

                # If the permission is 's', don't operate on the other group.
                # Unless the operator was '='. But in that case, don't set
                # the 8 bit for 'other'.
                my $equal_s;
                if (/s/) {
                    if ($operator eq '=') {$equal_s = 1;}
                    else                  {@set     = grep {!/o/} @set or next;}
                }
                # If the permission is 't', only  operate on the other group;
                # regardless what the 'who' settings are.
                # Note that for a directory with permissions 1777, and a
                # umask of 002, a chmod =t on HP and Solaris turn the
                # permissions to 1000, GNU and SunOS turn the permissiosn
                # to 1020, while OpenBSD keeps 1777.
                /t/ and @set = qw /o/;

                # Apply.
                foreach my $s (@set) {
                    do {$perms {$s} |=  $bit; next} if $operator eq '+';
                    do {$perms {$s} &= ~$bit; next} if $operator eq '-';
                    do {$perms {$s}  =  $bit; next} if $operator eq '=';
                    die "Weird operator `$operator' found\n";
                                                            # Should not happen.
                }

                # Special case '=s'.
                $perms {o} &= ~$bit if $equal_s;
            }
        }
    }

    # Now, translate @perms to an *octal* number.

    # First, deal with the suid, guid, and sticky bits by collecting
    # the high bits of the ugo permissions.
    my $first = 0;
       $bit   = 1;
    for my $c (reverse @ugo) {
        if ($perms {$c} & 8) {$first |= $bit; $perms {$c} &= ~8;}
        $bit <<= 1;
    }

    join "" => $first, @perms {@ugo};
}

1;


__END__
