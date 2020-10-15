# Little::Schemer

## Name

Little::Schemer - A Perl-like Implementation of "The Little Schemer" Programs.

## Synopsis

```
use Little::Schemer;
say car car [['a', 'b'], 'c'];  #=> a

# You can see the recursion process of &isMember or as you want.
$Little::Schemer::sayDump = 'isMember';
say 'YES' unless isMember 'a', [qw(b c d e)];  #=> YES

undef $Little::Schemer::sayDump;
say join('', insertL('y', 'x', [qw(a x b x c)])->@*);  #=> ayxbxc
```

## Description

(stub)

## Version

0.01

## License

(stub)
