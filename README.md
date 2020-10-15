# Little::Schemer

## Name

Little::Schemer - A Perl-like Implementation of "The Little Schemer" Programs.

## Synopsis

```
use Little::Schemer;
say car car [['a', 'b'], 'c'];  #=> a

# You can see the recursion process of any functions.
push @$Little::Schemer::sayDump, qw( isMember car );
say 'YES' unless isMember 'a', [qw(b c d e)];  #=> YES

$Little::Schemer::sayDump = [];
say join('', insertL('y', 'x', [qw(a x b x c)])->@*);  #=> ayxbxc
```

## Description

### How To Define Your Own Scheme-ish Perl Functions

If you want not only to define your function in the Scheme-ish manner, but also to see the recursion process of it, you have to insert `dmp \@_;` into the top of the function.

```
use Little::Schemer;
use 5.22.0;
use feature 'signatures';
use warnings;
no warnings  qw( prototype recursion experimental::signatures );

# redundant forward declarations make you free from the parentheses of tail recursion
sub pairreverse :prototype($);

sub pairreverse :prototype($) ($list) {
    dmp \@_;

    isNull $list?
        []:
        cons
            # sometimes parentheses are necessary!
            cons( car cdr car $list, [car car $list] ),
            pairreverse cdr $list;
}

push @$Little::Schemer::sayDump, qw( pairreverse cdr );
say dump_of pairreverse [['a', 'b'], ['c', 'd'], ['e', 'f']];
#=> $VAR1 = [ [ 'b', 'a' ], [ 'd', 'c' ], [ 'f', 'e' ] ];
```

## Dependent CPAN (Non-Core) Modules

- Sub::Prepend
- Carp::Assert (it's OK without this)

## Version

0.02

## License

(stub)
