XTMUNITU ; VEN/SMH - Bad Ass Continuation of Unit Tests;2014-04-01  1:03 PM
 ;;7.3;KERNEL TOOLKIT;
 ;
T11 ; @TEST An @TEST Entry point in Another Routine invoked through XTROU offsets
 D CHKTF^XTMUNIT(1)
 QUIT
T12 ;
 D CHKTF^XTMUNIT(1)
 QUIT
XTENT ;
 ;;T12;An XTENT offset entry point in Another Routine invoked through XTROU offsets
