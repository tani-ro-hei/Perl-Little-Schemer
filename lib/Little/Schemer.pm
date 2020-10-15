package Little::Schemer 0.02;

use 5.22.0;
use feature 'signatures';
use warnings;
no warnings  qw( prototype recursion redefine experimental::signatures );

use constant { T => 1, F => 0 };

use Carp          qw();
use Data::Dumper  qw();
use List::Util    qw();
use Sub::Prepend  qw();

our $assertable;
BEGIN {
    local $@;  eval "use Carp::Assert 'assert';";
    $Little::Schemer::assertable = 1  unless $@;
}

sub import {
    no strict 'refs';

    my @codenames
        = grep {
            defined *{ __PACKAGE__."::$_" }{CODE};
        } %{ __PACKAGE__.'::' }
    ;
    for my $cname (@codenames) {
        next if $cname =~ /^(?: assert | import | _get_subname | except | dump_of | dmp )$/x;

        Sub::Prepend::prepend $cname => sub {
            dmp(\@_, $cname);
        }
    }
    my $tgt = caller;
    for my $cname (@codenames) {
        next if $cname =~ /^(?: assert | import | _get_subname )$/x;

        *{ $tgt."::$cname" } = \&{ __PACKAGE__."::$cname" };
    }
}

sub _get_subname {
    my ($pkg, $subname) = (caller 2)[0, 3];
    $subname =~ s/^${pkg}:://r;
}

sub except ($msg) {
    my $subname = _get_subname;
    Carp::croak "$subname: $msg\n";
}

sub dump_of ($var) {
    my $d = Data::Dumper::Dumper($var);
    for ($d) {
        s/^\s+|\s+$//gm;
        s/\n+/ /gs;
        s/^\$VAR1 = |;$//g;
        s/\[ /[/g;
        s/ \]/]/g;
    }
    return $d;
}

our $show = [];
sub dmp ($args, $subname = undef) {
    $subname //= _get_subname;
    return unless 'ARRAY' eq (ref $show // '');
    return unless List::Util::first { $_ eq $subname } $show->@*;

    my $d = dump_of $args;
    say "  $subname: $d";
}


# # #

sub isSExp :prototype($) ($exp) {
    return T  if !ref $exp;
    return T  if ref $exp eq 'ARRAY';
    return F;
}

sub isAtom :prototype($) ($s_exp) {
    except 'not an S-exp!' unless isSExp $s_exp;

    (!ref $s_exp)?  T : F;
}

sub isNull :prototype($) ($list) {
    except 'not a list!' if isAtom $list;

    (! $list->@*)?  T : F;
}

sub isEq :prototype($$) ($atom1, $atom2) {
    except 'not an atom!' unless isAtom $atom1;
    except 'not an atom!' unless isAtom $atom2;

    ($atom1 eq $atom2)?  T : F;
}

sub Or :prototype($$) ($bool1, $bool2) {
    ($bool1 or $bool2)?  T : F;
}

sub car :prototype($) ($ne_list) {
    except 'null list!' if isNull $ne_list;

    return $ne_list->[0];
}

sub cdr :prototype($) ($ne_list) {
    except 'null list!' if isNull $ne_list;

    my $new_list = [ $ne_list->@* ];
    shift $new_list->@*;
    return $new_list;
}

sub cons :prototype($$) ($s_exp, $list) {
    except 'not an S-exp!' unless isSExp $s_exp;
    except 'not a list!' if isAtom $list;

    return [ $s_exp, $list->@* ];
}

{
    local $@;
    eval <<'END_OF_ASSERTIONS' if $assertable;
assert( isSExp 'hoge'                           );
assert( isSExp 42                               );
assert( isSExp [qw/ a b c d /]                  );
assert( isSExp ['hoge', 2, ['fuga', 4], 'piyo'] );
assert( !isSExp {name => 'John'}                );
assert( isAtom 'hoge'                           );
assert( isAtom 42                               );
assert( !isAtom [qw/ a b c d /]                 );
assert( isNull []                               );
assert( !isNull [1, 2, 3]                       );
assert( !isNull [[]]                            );
assert( isEq 'ab', 'ab'                         );
assert( !isEq 'ab', 'cd'                        );
assert( isEq Or(T, F), T                        );
assert( car ['a', 'b'] eq 'a'                   );
assert( (car [['a', 'b'], 'c'])->[1] eq 'b'     );
assert( (cdr ['a', 'b', 'c'])->[0] eq 'b'       );
assert( isNull cdr [42]                         );
assert( (cons 'a', ['b', 'c'])->[0] eq 'a'      );
assert( (cons 'a', ['b', 'c'])->[1] eq 'b'      );
assert( (cons 'a', ['b', 'c'])->[2] eq 'c'      );
assert( !defined +(cons 'a', ['b', 'c'])->[3]   );
END_OF_ASSERTIONS
    die "$@" if $@;
}


sub isLat    :prototype($);
sub isMember :prototype($$);
sub rember   :prototype($$);
sub firsts   :prototype($);
sub insertR  :prototype($$$);
sub insertL  :prototype($$$);

sub isLat :prototype($) ($list) {
    except 'not a list!' if isAtom $list;

    isNull $list?
        T:
        isAtom car $list?
            isLat cdr $list:
            F;
}

sub isMember :prototype($$) ($atom, $lat) {
    except 'not an atom!' unless isAtom $atom;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        F:
        Or
            isEq( car $lat, $atom ),
            isMember $atom, cdr $lat;
}

sub rember :prototype($$) ($atom, $lat) {
    except 'not an atom!' unless isAtom $atom;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        []:
        isEq( car $lat, $atom )?
            cdr $lat:
            cons car $lat, rember $atom, cdr $lat;
}

sub firsts :prototype($) ($list) {
    except 'not a list!' if isAtom $list;

    isNull $list?
        []:
        cons car car $list, firsts cdr $list;
}

sub insertR :prototype($$$) ($new, $old, $lat) {
    except 'not an atom!' unless isAtom $new and isAtom $old;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        []:
        isEq( car $lat, $old )?
            cons $old, cons $new, cdr $lat:
            cons car $lat, insertR $new, $old, cdr $lat;
}

sub insertL :prototype($$$) ($new, $old, $lat) {
    except 'not an atom!' unless isAtom $new and isAtom $old;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        []:
        isEq( car $lat, $old )?
            cons $new, $lat:
            cons car $lat, insertL $new, $old, cdr $lat;
}

{
    local $@;
    eval <<'END_OF_ASSERTIONS' if $assertable;
assert( isLat [qw/a b c d/]                                          );
assert( !isLat ['a', [qw(b c)], 'd']                                 );
assert( isMember 'a', [qw(a b c d)]                                  );
assert( !isMember 'a', [qw(b c d e)]                                 );
assert( @{rember 'b', [qw/x y z/]} == 3                              );
assert( @{rember 'b', [qw/a b c/]} == 2                              );
assert( (rember 'b', [qw/a b c/])->[1] eq 'c'                        );
assert( (firsts [[['a'], 'b'], [[], 'd'], ['e']])->[0][0] eq 'a'     );
assert( (firsts [[['a'], 'b'], [[], 'd'], ['e']])->[1]->@* == 0      );
assert( (firsts [[['a'], 'b'], [[], 'd'], ['e']])->[2] eq 'e'        );
assert( !defined +(firsts [[['a'], 'b'], [[], 'd'], ['e']])->[3]     );
assert( join('', insertR('y', 'x', [qw(a x b x c)])->@*) eq 'axybxc' );
assert( join('', insertL('y', 'x', [qw(a x b x c)])->@*) eq 'ayxbxc' );
END_OF_ASSERTIONS
    die "$@" if $@;
}


1;
