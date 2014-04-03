XTMUNITT ; VEN/SMH - Testing routines for M-Unit;2014-04-01  2:04 PM
 ;;7.3;KERNEL TOOLKIT;
 ;
 ; Dear Users,
 ;
 ; I know about about the irony of a test suite for the testing suite,
 ; so stop snikering. Aside from that, it's actually going to be hard.
 ;
 ; Truly yours,
 ;
 ; Sam H
 ;
 D EN^XTMUNIT($T(+0),1) ; Run tests here, be verbose, and break on errors.
 QUIT
 ;
STARTUP ; M-Unit Start-Up - This runs before anything else.
 S ^TMP($J,"XTMU","STARTUP")=""
 S KBANCOUNT=1
 QUIT
 ;
SHUDOWN ; M-Unit Shutdown - This runs after everything else is done.
 K ^TMP($J,"XTMU","STARTUP")
 K KBANCOUNT
 QUIT
 ;
 ;
 ;
SETUP ; This runs before every test.
 S KBANCOUNT=KBANCOUNT+1
 QUIT
 ;
TEARDOWN ; This runs after every test
 S KBANCOUNT=KBANCOUNT-1
 QUIT
 ;
 ;
 ;
T1 ; @TEST - Make sure Start-up Ran
 D CHKTF($D(^TMP($J,"XTMU","STARTUP")),"Start-up node on ^TMP must exist")
 QUIT
 ;
T2 ; @TEST - Make sure Set-up runs
 D CHKEQ(KBANCOUNT,2,"KBANCount not incremented properly at SETUP")
 QUIT
 ;
T3 ; @TEST - Make sure Teardown runs
 D CHKEQ(KBANCOUNT,2,"KBANCount not decremented properly at TEARDOWN")
 QUIT
 ;
T4 ; Specified in XTMTAG
 D CHKEQ(XTMUETRY(4),"T4","T4 should be the collected as the fourth entry in XTMUETRY")
 QUIT
 ;
T5 ; ditto
 D CHKTF(0,"This is an intentional failure.")
 D CHKEQ(XTMUNIT("FAIL"),1,"By this point, we should have failed one test")
 D FAIL^XTMUNIT("Intentionally throwing a failure")
 D CHKEQ(XTMUNIT("FAIL"),2,"By this point, we should have failed two tests")
 ; S XTMUNIT("FAIL")=0 ; Okay... Boy's and Girls... as the developer I can do that.
 QUIT
 ;
T6 ; ditto
 N TESTCOUNT S TESTCOUNT=XTMUNIT("CHK")
 D SUCCEED^XTMUNIT
 D SUCCEED^XTMUNIT
 D CHKEQ(XTMUNIT("CHK"),TESTCOUNT+2,"Succeed should increment the number of tests")
 QUIT
 ;
 ;
 ;
 ; Shortcut methods for M-Unit
CHKTF(X,Y)   D CHKTF^XTMUNIT(X,$G(Y))   QUIT
CHKEQ(A,B,M) D CHKEQ^XTMUNIT(A,B,$G(M)) QUIT
 ;
XTENT ; Entry points
 ;;T4;Entry point using XTMENT
 ;;T5;Error count check
 ;;T6;Succeed Entry Point
XTROU ; Routines containing additional tests
 ;;XTMUNITU
