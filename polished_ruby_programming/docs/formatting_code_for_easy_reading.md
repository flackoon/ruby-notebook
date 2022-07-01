# Formatting Code for Easy Reading

## Learning how syntactic consistency affects maintainability

Enforcing syntactic consistency can increase the performance of philosophers (people who find **syntactic
inconsistency** bothersome). The poets (the opposite of a philosopher) may find such code boring and not as fun to work
on, and it is likely that enforcing syntactic consistency will affect their enjoyment of working on the code, but it's
unlikely that it will harm their productivty, as they are, in general, able to read and write a wide variety of styles.

## Enforcing consistency with RuboCop

One approach to trying to satisfy the philosophers on the team without undue irritation to the poets is to start with
all of RuboCop's cops disabled, except those related ot syntax issues that have previously been complained about during
code review. Then, as future code reviews happen, if one of the philosophers complains about a new syntax issue that is
avaiable as a RuboCop cop, you can consider enabling that cop.

> Enforcing arbitrary (RuboCop's default) limits on your code will make the code worse, not better.
