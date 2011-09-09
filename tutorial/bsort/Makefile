GHC = ghc #/c/ghc/ghc/inplace/bin/ghc-stage2
GHC_OPTS = -O2 -threaded -eventlog -rtsopts
#EXT = .exe
# HEAP = -H100M
HEAP =
EBH = -feager-blackholing

all:	
	$(GHC) $(GHC_OPTS) --make BSort.hs -o bsort
	$(GHC) $(GHC_OPTS) --make BSortPar.hs -o bsortpar
	$(GHC) $(GHC_OPTS) --make BSortPar2.hs -o bsortpar2
#	$(GHC) $(GHC_OPTS) --make BSortPar3.hs -o bsortpar3
	$(GHC) $(GHC_OPTS) --make BSortStreaming.hs -o bsort_streaming


run0:	
	./bsort +RTS -N1 -ls -qg0 -qb 

run1:	
	./bsortpar +RTS -N1 -ls -qg0 -qb -sbsortpar-N1.log
	mv bsortpar$(EXT).eventlog bsortpar-N1.eventlog 
	./bsortpar +RTS -N2 -ls -qg0 -qb -sbsortpar-N2.log
	mv bsortpar$(EXT).eventlog bsortpar-N2.eventlog 

run2:	
	./bsortpar2 +RTS -N1 -ls -qg0 -qb -sbsortpar2-N1.log
	mv bsortpar2$(EXT).eventlog bsortpar2-N1.eventlog 
	./bsortpar2 +RTS -N2 -ls -qg0 -qb -sbsortpar2-N2.log
	mv bsortpar2$(EXT).eventlog bsortpar2-N2.eventlog 

run3:	
	./bsortpar3 +RTS -N1 -ls -qg0 -qb -sbsortpar3-N1.log
	mv bsortpar3$(EXT).eventlog bsortpar3-N1.eventlog 
	./bsortpar3 +RTS -N2 -ls -qg0 -qb -sbsortpar3-N2.log
	mv bsortpar3$(EXT).eventlog bsortpar3-N2.eventlog 

runs:	
	./bsort_streaming +RTS -N1 -ls -qg0 -qb -Sbsort-streaming-n1.log
	mv bsort_streaming$(EXT).eventlog bsort-streaming-n1.eventlog
	./bsort_streaming +RTS -N2 -ls -qg0 -qb -Sbsort-streaming-n2.log
	mv bsort_streaming$(EXT).eventlog bsort-streaming-n2.eventlog

clean:	
	rm -f bsort bsortpar bsort_streaming *.hi *.o
