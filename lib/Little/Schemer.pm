package Little::Schemer 0.10;

use 5.22.0;
use warnings;
no warnings 'prototype';
use Carp          qw( croak );
use Data::Dumper  qw( Dumper );

our $assertable;
BEGIN {
    local $@;  eval "use Carp::Assert 'assert';";
    $Little::Schemer::assertable = 1  unless $@;
}


=head1 SYNOPSIS

    use Little::Schemer;
    say car car [['a', 'b'], 'c'];  #=> a

    # You can see the recursion process of &isMember or as you want.
    $Little::Schemer::sayDump = 'isMember';
    say 'YES' unless isMember 'a', [qw(b c d e)];  #=> YES

    undef $Little::Schemer::sayDump;
    say join('', insertL('y', 'x', [qw(a x b x c)])->@*);  #=> ayxbxc

=cut


sub import {
    my $tgt = caller;

    no strict 'refs';
    *{ $tgt."::$_" } = \&{ __PACKAGE__."::$_" }
        for grep { defined *{ __PACKAGE__."::$_" }{CODE} }
            %{ __PACKAGE__.'::' };
}

sub get_subname {
    state $pkg = __PACKAGE__;
    (my $subname = (caller 2)[3]) =~ s/^${pkg}:://;
    return $subname;
}

sub except {
    my $msg = shift;
    my $subname = get_subname();

    croak "$subname: $msg\n";
}

our $sayDump = 0;
sub dmp {
    my $args = shift;
    my $subname = get_subname();
    return if !$sayDump  or $sayDump ne $subname;

    my $d = Dumper($args);
    for ($d) {
        s/^\s+|\s+$//gm;
        s/\n+/ /gs;
    }
    say "  $subname: $d";
}


# # #

sub True  :prototype() { 1 }
sub False :prototype() { 0 }

sub isSExp :prototype($) {
    my $exp = shift;

    !ref($exp) or ref($exp) eq 'ARRAY';
}

sub isAtom :prototype($) {
    my $s_exp = shift;
    except 'not an S-exp!' unless isSExp $s_exp;

    !ref($s_exp);
}

sub isNull :prototype($) {
    my $list = shift;
    except 'not a list!' if isAtom $list;

    !($list->@*);
}

sub car :prototype($) {
    my $ne_list = shift;
    except 'null list!' if isNull $ne_list;

    return $ne_list->[0];
}

sub cdr :prototype($) {
    my $ne_list = shift;
    except 'null list!' if isNull $ne_list;

    my $new_list = [ $ne_list->@* ];
    shift $new_list->@*;
    return $new_list;
}

sub cons :prototype($$) {
    my ($s_exp, $list) = @_;
    except 'not an S-exp!' unless isSExp $s_exp;
    except 'not a list!' if isAtom $list;

    return [ $s_exp, $list->@* ];
}

    $assertable  and eval <<'END_OF_ASSERTIONS';
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
assert( car ['a', 'b'] eq 'a'                   );
assert( (car [['a', 'b'], 'c'])->[1] eq 'b'     );
assert( (cdr ['a', 'b', 'c'])->[0] eq 'b'       );
assert( isNull cdr [42]                         );
assert( (cons 'a', ['b', 'c'])->[0] eq 'a'      );
assert( (cons 'a', ['b', 'c'])->[1] eq 'b'      );
assert( (cons 'a', ['b', 'c'])->[2] eq 'c'      );
assert( !defined +(cons 'a', ['b', 'c'])->[3]   );
END_OF_ASSERTIONS


sub isLat    :prototype($);
sub isMember :prototype($$);
sub rember   :prototype($$);
sub firsts   :prototype($);
sub insertR  :prototype($$$);
sub insertL  :prototype($$$);

sub isLat :prototype($) {
    dmp \@_;
    my $list = shift;
    except 'not a list!' if isAtom $list;

    isNull $list?
        True:
        isAtom car $list?
            isLat cdr $list:
            False;
}

sub isMember :prototype($$) {
    dmp \@_;
    my ($atom, $lat) = @_;
    except 'not an atom!' unless isAtom $atom;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        False:
        car $lat eq $atom
            or isMember $atom, cdr $lat;
}

sub rember :prototype($$) {
    dmp \@_;
    my ($atom, $lat) = @_;
    except 'not an atom!' unless isAtom $atom;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        []:
        car $lat eq $atom?
            cdr $lat:
            cons car $lat, rember $atom, cdr $lat;
}

sub firsts :prototype($) {
    dmp \@_;
    my $list = shift;
    except 'not a list!' if isAtom $list;

    isNull $list?
        []:
        cons car car $list, firsts cdr $list;
}

sub insertR :prototype($$$) {
    dmp \@_;
    my ($new, $old, $lat) = @_;
    except 'not an atom!' unless isAtom $new and isAtom $old;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        []:
        car $lat eq $old?
            cons $old, cons $new, cdr $lat:
            cons car $lat, insertR $new, $old, cdr $lat;
}

sub insertL :prototype($$$) {
    dmp \@_;
    my ($new, $old, $lat) = @_;
    except 'not an atom!' unless isAtom $new and isAtom $old;
    except 'not a lat!' unless isLat $lat;

    isNull $lat?
        []:
        car $lat eq $old?
            cons $new, $lat:
            cons car $lat, insertL $new, $old, cdr $lat;
}

    $assertable  and eval <<'END_OF_ASSERTIONS';
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


1;
