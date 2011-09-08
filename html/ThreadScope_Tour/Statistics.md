Objectives
---------
Collect statistics about a program so that you know what you're ThreadScoping

* Baseline vs parallel timings
* Spark creation and conversion

Concepts
--------
* sparks converted - sparks actually executed; whatever sparks you create,
  you generally want them to be converted rather than pruned
* sparks pruned - sparks discarded by the runtime system either because
  they are found to have been evaluated or not referenced by the rest of
  the program

Steps
-----

1. Get a copy of the par-tutorial code and build it

        git clone https://github.com/simonmar/par-tutorial.git
        cd par-tutorial/code
        make
 
2. Run the sudoku2 program on a sample input, using just one core

        ./sudoku2 sudoku17.1000.txt +RTS -s

3. Examine the statistics output.  Look for statistics like the following:

        SPARKS: 2 (0 converted, 2 pruned)
      
        INIT  time    0.00s  (  0.00s elapsed)
        MUT   time    3.88s  (  4.01s elapsed)
        GC    time    0.11s  (  0.13s elapsed)
        EXIT  time    0.00s  (  0.00s elapsed)
        Total time    3.99s  (  4.14s elapsed)

4. Notice here the *total* time elapsed (4.14s in my sample).  Note
   this as your baseline time.   You do not want the parallel version
   of your program to be any slower than this. 

5. Run the program again using a couple of cores, again generating
   statistics

        ./sudoku2 sudoku17.1000.txt +RTS -s -N2

6. Examine the statistics output, looking for the following:

        SPARKS: 2 (1 converted, 1 pruned)
      
        INIT  time    0.00s  (  0.00s elapsed)
        MUT   time    3.84s  (  2.79s elapsed)
        GC    time    0.43s  (  0.17s elapsed)
        EXIT  time    0.00s  (  0.00s elapsed)
        Total time    4.27s  (  2.97s elapsed)

7. Notice the wall clock speedup (from 4.14s to 2.97s)

8. Notice also the number of sparks that were created and compare
   to the single core case. In both cases, two sparks are created,
   but in the single core case they are both *pruned*, thrown out.
   In the two core case, we see one of the sparks being *converted*
   (executed).

   TODO... bit of discussion here

[ph-tutorial]: http://community.haskell.org/~simonmar/par-tutorial.pdf
