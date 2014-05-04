XTMUNIT ;OAKLAND OIFO/JLI - MUNIT UNIT TESTING FOR M ROUTINES ;2014-04-02  10:51 PM
 ;;7.3;TOOLKIT;**81**;Apr 25, 1995;Build 24
 ;
 ; Original by Dr. Joel Ivey
 ; Contributions by Dr. Sam Habiel
 ; 
 ; 100622 JLI - corrected typo in comments where XTMUINPT was listed as XTMUINP
 ; 100622 JLI - removed a comment which indicated data could potentially be returned from the called routine
 ;              in the XTMUINPT array.
 ; 100622 JLI - added code to handle STARTUP and SHUTDOWN from GUI app
 ; 110719 JLI - modified separators in GUI handling from ^ to ~~^~~
 ;              in the variable XTGUISEP if using a newer version of the
 ;              GUI app (otherwise, it is simply set to ^) since results
 ;              with a series of ^ embedded disturbed the output reported
 ; 130726 SMH - Fixed SETUP and TEARDOWN so that they run before/after each
 ;              test rather than once. General refactoring.
 ; 130726 SMH - SETUT initialized IO in case it's not there to $P. Inits vars
 ;              using DT^DICRW.
 ; 131217 SMH - Change call in SETUP to S U="^" instead of DT^DICRW
 ; 131218 SMH - Any checks to $ZE will also check $ZS for GT.M.
 ; 131218 SMH - Remove calls to %ZISUTL to manage devices to prevent dependence on VISTA.
 ;              Use XTMUNIT("DEV","OLD") for old devices
 ; 140109 SMH - Add parameter XTMBREAK - Break upon error
 ; 1402   SMH - Break will cause the break to happen even on failed tests.
 ; 140401 SMH - Added Succeed entry point for take it into your hands tester.
 ; 140401 SMH - Reformatted the output of M-Unit so that the test's name
 ;              will print BEFORE the execution of the test. This has been
 ;              really confusing for beginning users of M-Unit, so this was
 ;              necessary.
 ; 140401 SMH - OK message gets printed at the end of --- as [OK].
 ; 140401 SMH - FAIL message now prints. Previously, OK failed to be printed.
 ;              Unfortunately, that's rather passive aggressive. Now it
 ;              explicitly says that a test failed.
 ; 140503 SMH - Fixed IO issues all over the routine. Much simpler now. 
 Q
 ;
EN(XTMURNAM,XTMUVERB,XTMBREAK) ; .SR Entry point with primary test routine name, optional 1 for verbose output
 N XTMULIST,XTMUROU,XTMUNIT
 I $G(XTMUVERB)'=1 S XTMUVERB=0
 S XTMULIST=1,XTMUROU(XTMULIST)=XTMURNAM
 D SETUT
 D EN1(.XTMUROU,XTMULIST)
 Q
 ;
SETUT ;
 ; VEN/SMH 26JUL2013
 I '($D(IO)#2) S IO=$P
 S U="^"
 ; VEN/SMH 26JUL2013 END
 ;
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 S XTMUNIT("IO")=IO
 S XTMUNIT=1 ; set to identify unit test being run check with $$ISUTEST^XTMUNIT()
 ;
 ; ZEXCEPT: XTMBREAK
 I $G(XTMBREAK) S XTMUNIT("BREAK")=1
 Q
 ;
EN1(XTMUROU,XTMULIST) ;
 ; VEN/SMH 26JUL2013 - This block is refactored to fix problems with 
 ; SETUP and TEARDOWN not happening at the right time
 N XTMUERRL,XTMUK,XTMUI,XTMUJ,XTMUSTRT
 ; ZEXCEPT: XTMUVERB   -- ARGUMENT TO EN
 ; ZEXCEPT: XTMUGUI      -- CONDITIONALLY DEFINED BY GUINEXT
 ; ZEXCEPT: XTMUNIT  -- NEWED IN EN
 ;
 ; Structure map for XTMUNIT
 ; -- CURR = Counter for routine number. Used as sub in XTMUROU
 ; -- ECNT = Entry point count in loop (cf. NERT); VEN/SMH - Needed?
 ; -- FAIL = Number of failures
 ; -- CHK  = Number of checks ran (TF/EQ/FAIL)
 ; -- NENT = Number of entry points ran
 ; -- ERRN = Number of errors
 S XTMUNIT("CURR")=0,XTMUNIT("ECNT")=0,XTMUNIT("FAIL")=0,XTMUNIT("CHK")=0,XTMUNIT("NENT")=0,XTMUNIT("ERRN")=0
 ;
 ; -- GET LIST OF ROUTINES --
 ; first get any tree of routines from this one
 D GETTREE^XTMUNIT1(.XTMUROU,.XTMULIST)
 ;
 ; -- STARTUP --
 ; 070224 - following code added to allow one overall STARTUP code JLI
 F  S XTMUNIT("CURR")=XTMUNIT("CURR")+1 Q:'$D(XTMUROU(XTMUNIT("CURR")))  D  I $G(XTMUSTRT)'="" D @XTMUSTRT Q
 . I $T(@("STARTUP^"_XTMUROU(XTMUNIT("CURR"))))'="" S XTMUSTRT="STARTUP^"_XTMUROU(XTMUNIT("CURR"))
 . Q
 ; 070224 - end of addition JLI
 ;
 ;
 ; Now process each routine that has been referenced
 S XTMUNIT("CURR")=0
 F  S XTMUNIT("CURR")=XTMUNIT("CURR")+1 Q:'$D(XTMUROU(XTMUNIT("CURR")))  D
 . N XTMUETRY ; Test list to run
 . ; 
 . ; Collect Test list.
 . D CHEKTEST^XTMUNIT1(XTMUROU(XTMUNIT("CURR")),.XTMUNIT,.XTMUETRY)
 . ;
 . ; if a SETUP entry point exists, save it off in XTMUNIT
 . N XTMSETUP S XTMSETUP="SETUP^"_XTMUROU(XTMUNIT("CURR"))
 . S XTMUNIT("LINE")=$T(@XTMSETUP) I XTMUNIT("LINE")'="" S XTMUNIT("SETUP")=XTMSETUP
 . K XTMSETUP ; we're done!
 . ;
 . ; if a TEARDOWN entry point exists, ditto
 . N XTMTEARDOWN S XTMTEARDOWN="TEARDOWN^"_XTMUROU(XTMUNIT("CURR"))
 . S XTMUNIT("LINE")=$T(@XTMTEARDOWN) I XTMUNIT("LINE")'="" S XTMUNIT("TEARDOWN")=XTMTEARDOWN
 . K XTMTEARDOWN ; done here.
 . ;
 . ; VEN/SMH 26JUL2013 - this block changed to correct running of setup and teardown
 . ; run each of the specified entry points
 . ;
 . ; == THIS FOR/DO BLOCK IS THE CENTRAL TEST RUNNER ==
 . S XTMUI=0
 . F  S XTMUI=$O(XTMUETRY(XTMUI)) Q:XTMUI'>0  S XTMUNIT("ENUM")=XTMUNIT("ERRN")+XTMUNIT("FAIL") D  
 . . N $ETRAP S $ETRAP="D ERROR^XTMUNIT"
 . . ; 
 . . ; Run Set-up Code (only if present)
 . . S XTMUNIT("ENT")=$G(XTMUNIT("SETUP")) ; Current entry
 . . S XTMUNIT("NAME")="Set-up Code"
 . . D:XTMUNIT("ENT")]"" @XTMUNIT("ENT")
 . . ;
 . . ; Run actual test
 . . S XTMUNIT("ECNT")=XTMUNIT("ECNT")+1
 . . S XTMUNIT("NAME")=XTMUETRY(XTMUI,"NAME")
 . . S XTMUNIT("ENT")=XTMUETRY(XTMUI)_"^"_XTMUROU(XTMUNIT("CURR"))
 . . I XTMUVERB,'$D(XTMUGUI) D VERBOSE1(.XTMUETRY,XTMUI) ; Say what we executed.
 . . D @XTMUNIT("ENT")
 . . ;
 . . ; Run Teardown Code (only if present)
 . . S XTMUNIT("ENT")=$G(XTMUNIT("TEARDOWN"))
 . . S XTMUNIT("NAME")="Teardown Code"
 . . D:XTMUNIT("ENT")]"" @XTMUNIT("ENT")
 . . ;
 . . ; ENUM = Number of errors + failures
 . . ; Only print out the success message [OK] If our error number remains
 . . ; the same as when we started the loop.
 . . I XTMUVERB,'$D(XTMUGUI) D
 . . . I XTMUNIT("ENUM")=(XTMUNIT("ERRN")+XTMUNIT("FAIL")) D VERBOSE(.XTMUETRY,XTMUI,1) I 1
 . . . E  D VERBOSE(.XTMUETRY,XTMUI,0)
 . ;
 . ;
 . ; keep a XTMUCNT of number of entry points executed across all routines
 . S XTMUNIT("NENT")=XTMUNIT("NENT")+XTMUNIT("ENTN")
 . Q
 ;
 ; -- SHUTDOWN --
 ; 070224 - following code added to allow one overall SHUTDOWN code JLI
 N XTFINISH
 S XTMUNIT("CURR")=0
 F  S XTMUNIT("CURR")=XTMUNIT("CURR")+1 Q:'$D(XTMUROU(XTMUNIT("CURR")))  D  I $G(XTFINISH)'="" D @XTFINISH Q
 . I $T(@("SHUTDOWN^"_XTMUROU(XTMUNIT("CURR"))))'="" S XTFINISH="SHUTDOWN^"_XTMUROU(XTMUNIT("CURR"))
 . Q
 ; 070224 - End of addition JLI
 ;
 D SETIO
 W !!,"Ran ",XTMULIST," Routine",$S(XTMULIST>1:"s",1:""),", ",XTMUNIT("NENT")," Entry Tag",$S(XTMUNIT("NENT")>1:"s",1:"")
 W !,"Checked ",XTMUNIT("CHK")," test",$S(XTMUNIT("CHK")>1:"s",1:""),", with ",XTMUNIT("FAIL")," failure",$S(XTMUNIT("FAIL")'=1:"s",1:"")," and encountered ",XTMUNIT("ERRN")," error",$S(XTMUNIT("ERRN")'=1:"s",1:""),"."
 D RESETIO  
 Q
 ; -- end EN1
VERBOSE(XTMUETRY,XTMUI,SUCCESS) ; Say whether we succeeded or failed.
 ; ZEXCEPT: XTMUNIT - NEWED IN EN
 D SETIO
 N I F I=$X+3:1:73 W "-"
 W ?73
 I $G(SUCCESS) W "[OK]"
 E  W "[FAIL]"
 D RESETIO
 Q
 ;
VERBOSE1(XTMUETRY,XTMUI) ; Print out the entry point info
 ; ZEXCEPT: XTMUNIT - NEWED IN EN
 D SETIO
 W !,XTMUETRY(XTMUI) I $G(XTMUETRY(XTMUI,"NAME"))'="" W " - ",XTMUETRY(XTMUI,"NAME")
 D RESETIO
 Q
CHKTF(XTSTVAL,XTERMSG) ; Entry point for checking True or False values
 ; ZEXCEPT: XTMUERRL,XTMUGUI - CREATED IN SETUP, KILLED IN END
 ; ZEXCEPT: XTMUNIT - NEWED IN EN
 I $G(XTSTVAL)="" D NVLDARG Q
 I $G(XTERMSG)="" S XTERMSG="no failure message provided"
 S XTMUNIT("CHK")=$G(XTMUNIT("CHK"))+1
 I '$D(XTMUGUI) D
 . D SETIO
 . I 'XTSTVAL W !,XTMUNIT("ENT")," - " W:XTMUNIT("NAME")'="" XTMUNIT("NAME")," - " D
 . . W XTERMSG,! S XTMUNIT("FAIL")=XTMUNIT("FAIL")+1,XTMUERRL(XTMUNIT("FAIL"))=XTMUNIT("NAME"),XTMUERRL(XTMUNIT("FAIL"),"MSG")=XTERMSG,XTMUERRL(XTMUNIT("FAIL"),"ENTRY")=XTMUNIT("ENT")
     . . I $D(XTMUNIT("BREAK")) BREAK  ; Break upon failure
 . . Q
 . E  W "."
 . D RESETIO
 . Q
 I $D(XTMUGUI),'XTSTVAL S XTMUNIT("CNT")=XTMUNIT("CNT")+1,@XTMUNIT("RSLT")@(XTMUNIT("CNT"))=XTMUNIT("LOC")_XTGUISEP_"FAILURE"_XTGUISEP_XTERMSG
 Q
 ;
CHKEQ(XTEXPECT,XTACTUAL,XTERMSG) ; Entry point for checking values to see if they are EQUAL
 N FAILMSG
 ; ZEXCEPT: XTMUERRL,XTMUGUI -CREATED IN SETUP, KILLED IN END
 ; ZEXCEPT: XTMUNIT  -- NEWED IN EN
 I '$D(XTEXPECT),'$D(XTACTUAL) D NVLDARG Q
 S XTACTUAL=$G(XTACTUAL),XTEXPECT=$G(XTEXPECT)
 I $G(XTERMSG)="" S XTERMSG="no failure message provided"
 S XTMUNIT("CHK")=XTMUNIT("CHK")+1
 I XTEXPECT'=XTACTUAL S FAILMSG="<"_XTEXPECT_"> vs <"_XTACTUAL_"> - "
 I '$D(XTMUGUI) D
 . D SETIO
 . I XTEXPECT'=XTACTUAL W !,XTMUNIT("ENT")," - " W:XTMUNIT("NAME")'="" XTMUNIT("NAME")," - " W FAILMSG,XTERMSG,! D
 . . S XTMUNIT("FAIL")=XTMUNIT("FAIL")+1,XTMUERRL(XTMUNIT("FAIL"))=XTMUNIT("NAME"),XTMUERRL(XTMUNIT("FAIL"),"MSG")=XTERMSG,XTMUERRL(XTMUNIT("FAIL"),"ENTRY")=XTMUNIT("ENT")
     . . I $D(XTMUNIT("BREAK")) BREAK  ; Break upon failure
 . . Q
 . E  W "."
 . D RESETIO
 . Q
 I $D(XTMUGUI),XTEXPECT'=XTACTUAL S XTMUNIT("CNT")=XTMUNIT("CNT")+1,@XTMUNIT("RSLT")@(XTMUNIT("CNT"))=XTMUNIT("LOC")_XTGUISEP_"FAILURE"_XTGUISEP_FAILMSG_XTERMSG
 Q
 ;
FAIL(XTERMSG) ; Entry point for generating a failure message
 ; ZEXCEPT: XTMUERRL,XTMUGUI -CREATED IN SETUP, KILLED IN END
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 I $G(XTERMSG)="" S XTERMSG="no failure message provided"
 S XTMUNIT("CHK")=XTMUNIT("CHK")+1
 I '$D(XTMUGUI) D
 . D SETIO
 . W !,XTMUNIT("ENT")," - " W:XTMUNIT("NAME")'="" XTMUNIT("NAME")," - " W XTERMSG,! D
 . . S XTMUNIT("FAIL")=XTMUNIT("FAIL")+1,XTMUERRL(XTMUNIT("FAIL"))=XTMUNIT("NAME"),XTMUERRL(XTMUNIT("FAIL"),"MSG")=XTERMSG,XTMUERRL(XTMUNIT("FAIL"),"ENTRY")=XTMUNIT("ENT")
 . . I $D(XTMUNIT("BREAK")) BREAK  ; Break upon failure
 . . Q
 . D RESETIO
 . Q
 I $D(XTMUGUI) S XTMUNIT("CNT")=XTMUNIT("CNT")+1,@XTMUNIT("RSLT")@(XTMUNIT("CNT"))=XTMUNIT("LOC")_XTGUISEP_"FAILURE"_XTGUISEP_XTERMSG
 Q
SUCCEED ; Entry point for forcing a success (Thx David Whitten)
 ; ZEXCEPT: XTMUERRL,XTMUGUI - CREATED IN SETUP, KILLED IN END
 ; ZEXCEPT: XTMUNIT - NEWED IN EN
 ; Switch IO and write out the dot for activity
 I '$D(XTMUGUI) D
 . D SETIO
 . W "."
 . D RESETIO 
 ;
 ; Increment test counter
 S XTMUNIT("CHK")=XTMUNIT("CHK")+1
 QUIT
 ;
CHKLEAKS(XTMUCODE,XTMULOC,XTMUINPT) ; functionality to check for variable leaks on executing a section of code
 ; XTMUCODE - A string that specifies the code that is to be XECUTED and checked for leaks.
 ;            this should be a complete piece of code (e.g., "S X=$$NEW^XLFDT()" or "D EN^XTMUNIT(""ROUNAME"")")
 ; XTMULOC  - A string that is used to indicate the code tested for variable leaks
 ; XTMUINPT - An optional variable which may be passed by reference.  This may
 ;           be used to pass any variable values, etc. into the code to be
 ;           XECUTED.  In this case, set the subscript to the variable name and the
 ;           value of the subscripted variable to the desired value of the subscript.
 ;              e.g., (using NAME as my current namespace)
 ;                   S CODE="S XTMUINPT=$$ENTRY^ROUTINE(ZZVALUE1,ZZVALUE2)"
 ;                   S NAMELOC="ENTRY^ROUTINE leak test"   (or simply "ENTRY^ROUTINE")
 ;                   S NAMEINPT("ZZVALUE1")=ZZVALUE1
 ;                   S NAMEINPT("ZZVALUE2")=ZZVALUE2
 ;                   D CHKLEAKS^XTMUNIT(CODE,NAMELOC,.NAMEINPT)
 ;
 ;           If part of a unit test, any leaked variables in ENTRY^ROUTINE which result
 ;           from running the code with the variables indicated will be shown as FAILUREs.
 ;
 ;           If called outside of a unit test, any leaked variables will be printed to the
 ;           current device.
 ;
 N (XTMUCODE,XTMULOC,XTMUINPT,DUZ,IO,U,XTMUERRL,XTMUNIT,XTMUGUI,XTMUI,XTMUJ,XTMUK,XTMULIST,XTMUROU,XTMUSTRT)
 ; ZEXCEPT: XTMUNIT - part of exclusive NEW TESTS FOR EXISTENCE ONLY
 ; ZEXCEPT: XTMUVAR - handled by exclusive NEW
 ;
 ; ACTIVATE ANY VARIABLES PASSED AS SUBSCRIPTS TO XTMUINPT TO THEIR VALUES
 S XTMUVAR=" " F  S XTMUVAR=$O(XTMUINPT(XTMUVAR)) Q:XTMUVAR=""  S (@XTMUVAR)=XTMUINPT(XTMUVAR)
 X XTMUCODE
 N ZZUTVAR S ZZUTVAR="%"
 I $G(XTMUNIT)=1 D
 . I $D(@ZZUTVAR),'$D(XTMUINPT(ZZUTVAR)) D FAIL^XTMUNIT(XTMULOC_" VARIABLE LEAK: "_ZZUTVAR)
 . F  S ZZUTVAR=$O(@ZZUTVAR) Q:ZZUTVAR=""  I $E(ZZUTVAR,1,4)'="XTMU",'$D(XTMUINPT(ZZUTVAR)),",DUZ,IO,U,DTIME,ZZUTVAR,DT,"'[(","_ZZUTVAR_",") D FAIL^XTMUNIT(XTMULOC_" VARIABLE LEAK: "_ZZUTVAR)
 . Q
 I '($G(XTMUNIT)=1) D
 . I $D(@ZZUTVAR),'$D(XTMUINPT(ZZUTVAR)) W !,XTMULOC_" VARIABLE LEAK: "_ZZUTVAR
 . F  S ZZUTVAR=$O(@ZZUTVAR) Q:ZZUTVAR=""  I $E(ZZUTVAR,1,4)'="XTMU",'$D(XTMUINPT(ZZUTVAR)),",DUZ,IO,U,DTIME,ZZUTVAR,DT,"'[(","_ZZUTVAR_",") W !,XTMULOC_" VARIABLE LEAK: "_ZZUTVAR
 . Q
 Q
 ;
NVLDARG ; generate message for invalid arguments to test
 N XTERMSG
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 ; ZEXCEPT: XTMUERRL,XTMUGUI -CREATED IN SETUP, KILLED IN END
 S XTERMSG="NO VALUES INPUT TO CHKEQ^XTMUNIT - no evaluation possible"
 I '$D(XTMUGUI) D
 . D SETIO
 . W !,XTMUNIT("ENT")," - " W:XTMUNIT("NAME")'="" XTMUNIT("NAME")," - " W XTERMSG,! D
 . . S XTMUNIT("FAIL")=XTMUNIT("FAIL")+1,XTMUERRL(XTMUNIT("FAIL"))=XTMUNIT("NAME"),XTMUERRL(XTMUNIT("FAIL"),"MSG")=XTERMSG,XTMUERRL(XTMUNIT("FAIL"),"ENTRY")=XTMUNIT("ENT")
 . . Q
 . D RESETIO
 . Q
 I $D(XTMUGUI) S XTMUNIT("CNT")=XTMUNIT("CNT")+1,@XTMUNIT("RSLT")@(XTMUNIT("CNT"))=XTMUNIT("LOC")_XTGUISEP_"FAILURE"_XTGUISEP_XTERMSG
 Q
 ;
ERROR ; record errors
 ; ZEXCEPT: XTMUERRL,XTMUGUI,XTMUERR -CREATED IN SETUP, KILLED IN END
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 S XTMUNIT("CHK")=XTMUNIT("CHK")+1
 I '$D(XTMUGUI) D ERROR1
 I $D(XTMUGUI) D
 . S XTMUNIT("CNT")=XTMUNIT("CNT")+1
 . S XTMUERR=XTMUERR+1
 . S @XTMUNIT("RSLT")@(XTMUNIT("CNT"))=XTMUNIT("LOC")_XTGUISEP_"ERROR"_XTGUISEP_$S(+$SY=47:$ZS,1:$ZE)
 . Q
 S @($S(+$SY=47:"$ZS",1:"$ZE")_"="_""""""),$EC=""
 Q
 ;
ERROR1 ;
 I $G(XTMUNIT("BREAK")) BREAK  ; if we are asked to break upon error, please do so!
 ; ZEXCEPT: XTMUERRL -CREATED IN SETUP, KILLED IN END
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 D SETIO
 W !,XTMUNIT("ENT")," - " W:XTMUNIT("NAME")'="" XTMUNIT("NAME")," - Error: " W $S(+$SY=47:$ZS,1:$ZE),! D
 . S XTMUNIT("ERRN")=XTMUNIT("ERRN")+1,XTMUERRL(XTMUNIT("ERRN"))=XTMUNIT("NAME"),XTMUERRL(XTMUNIT("FAIL"),"MSG")=$S(+$SY=47:$ZS,1:$ZE),XTMUERRL(XTMUNIT("FAIL"),"ENTRY")=XTMUNIT("ENT")
 . Q
 D RESETIO 
 Q
SETIO ; Set M-Unit Device to write the results to...
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 I $IO'=XTMUNIT("IO") S (IO(0),XTMUNIT("DEV","OLD"))=$IO USE XTMUNIT("IO") SET IO=$IO
 QUIT
 ;
RESETIO ; Reset $IO back to the original device if we changed it.
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 I $D(XTMUNIT("DEV","OLD")) S IO(0)=XTMUNIT("IO") U XTMUNIT("DEV","OLD") S IO=$IO K XTMUNIT("DEV","OLD")
 QUIT
 ;
ISUTEST() ; .SUPPORTED API TO DETERMINE IF CURRENTLY IN UNIT TEST
 ; ZEXCEPT: XTMUNIT  -- NEWED ON ENTRY
 Q $G(XTMUNIT)=1
 ;
PICKSET ; .OPT Interactive selection of MUnit Test Group
 N DIC,Y,XTMUROU,XTMULIST,DIR
 S DIC=8992.8,DIC(0)="AEQM" D ^DIC Q:Y'>0  W !
 D GETSET(+Y,.XTMUROU,.XTMULIST)
 N DIC,Y,XTMUNIT
 D SETUT
 D EN1(.XTMUROU,XTMULIST)
 S DIR(0)="EA",DIR("A")="Enter RETURN to continue:" D ^DIR K DIR
 Q
 ;
RUNSET(SETNAME) ; .SR Run with Specified Selection of MUnit Test Group
 N Y,XTMUROU,XTMULIST
 Q:$G(SETNAME)=""
 S Y=+$$FIND1^DIC(8992.8,"","X",SETNAME) Q:Y'>0
 D GETSET(Y,.XTMUROU,.XTMULIST)
 N Y,SETNAME,XTMUNIT
 D SETUT
 D EN1(.XTMUROU,XTMULIST)
 Q
 ;
DOSET(IEN) ;
 N XTMUROU,XTMULIST
 S XTMULIST=0
 D GETSET($G(IEN),.XTMUROU,.XTMULIST)
 I XTMULIST>0  N IEN,XTMUNIT D SETUT,EN1(.XTMUROU,XTMULIST)
 Q
 ;
GETSET(IEN,XTMUROU,XTMULIST) ;
 N IENS,XTMROOT
 S IENS=IEN_"," D GETS^DIQ(8992.8,IENS,"1*","","XTMROOT")
 S XTMULIST=0,IENS="" F  S IENS=$O(XTMROOT(8992.81,IENS)) Q:IENS=""  S XTMULIST=XTMULIST+1,XTMUROU(XTMULIST)=XTMROOT(8992.81,IENS,.01)
 Q
 ;
GUISET(XTMURSLT,XTSET) ; Entry point for GUI start with selected Test Set IEN
 N XTMUROU,XTMULIST,XTMUNIT
 D SETUT
 S XTMUNIT("RSLT")=$NA(^TMP("MUNIT-XTMURSLT",$J)) K @XTMUNIT("RSLT")
 D GETSET(XTSET,.XTMUROU,.XTMULIST)
 D GETLIST(.XTMUROU,XTMULIST,XTMUNIT("RSLT"))
 S @XTMUNIT("RSLT")@(1)=(@XTMUNIT("RSLT")@(1))_"^1" ; 110719 mark as new version
 S XTMURSLT=XTMUNIT("RSLT")
 Q
 ;
GUILOAD(XTMURSLT,XTMUROUN) ; Entry point for GUI start with XTMUROUN containing primary routine name
 N XTMUROU,XTMUNIT
 D SETUT
 S XTMUNIT("RSLT")=$NA(^TMP("MUNIT-XTMURSLT",$J)) K @XTMUNIT("RSLT")
 S XTMUROU(1)=XTMUROUN
 D GETLIST(.XTMUROU,1,XTMUNIT("RSLT"))
 S @XTMUNIT("RSLT")@(1)=(@XTMUNIT("RSLT")@(1))_"^1" ; 110719 mark as new version
 S XTMURSLT=XTMUNIT("RSLT")
 Q
 ;
GETLIST(XTMUROU,XTMULIST,XTMURSLT) ;
 N I,XTMUROUL,XTMUROUN,XTMUNIT,XTCOMNT,XTVALUE,XTMUCNT
 S XTVALUE=$NA(^TMP("GUI-MUNIT",$J)) K @XTVALUE
 S XTMUCNT=0,XTCOMNT=""
 D GETTREE^XTMUNIT1(.XTMUROU,XTMULIST)
 F I=1:1 Q:'$D(XTMUROU(I))  S XTMUROUL(XTMUROU(I))=""
 S XTMUROUN="" F  S XTMUROUN=$O(XTMUROUL(XTMUROUN)) Q:XTMUROUN=""  D LOAD(XTMUROUN,.XTMUCNT,XTVALUE,XTCOMNT,.XTMUROUL)
 M @XTMURSLT=@XTVALUE
 K @XTMURSLT@("SHUTDOWN")
 K @XTMURSLT@("STARTUP")
 S @XTVALUE@("LASTROU")="" ; Use this to keep track of place in routines
 Q
 ;
 ; generate list of unit test routines, entry points and comments on test for entry point
LOAD(XTMUROUN,XTMUNCNT,XTVALUE,XTCOMNT,XTMUROUL) ;
 I $T(@("^"_XTMUROUN))="" S XTMUNCNT=XTMUNCNT+1,@XTVALUE@(XTMUNCNT)=XTMUROUN_"^^*** ERROR - ROUTINE NAME NOT FOUND" Q
 S XTMUNCNT=XTMUNCNT+1,@XTVALUE@(XTMUNCNT)=XTMUROUN_U_U_XTCOMNT
 N XTMUI,XTX1,XTX2,LINE
 ; 100622 JLI added code to identify STARTUP and TEARDOWN
 I $T(@("STARTUP^"_XTMUROUN))'="",'$D(@XTVALUE@("STARTUP")) S @XTVALUE@("STARTUP")="STARTUP^"_XTMUROUN
 I $T(@("SHUTDOWN^"_XTMUROUN))'="",'$D(@XTVALUE@("SHUTDOWN")) S @XTVALUE@("SHUTDOWN")="SHUTDOWN^"_XTMUROUN
 F XTMUI=1:1 S LINE=$T(@("XTENT+"_XTMUI_"^"_XTMUROUN)) S XTX1=$P(LINE,";",3) Q:XTX1=""  S XTX2=$P(LINE,";",4),XTMUNCNT=XTMUNCNT+1,@XTVALUE@(XTMUNCNT)=XTMUROUN_U_XTX1_U_XTX2
 F XTMUI=1:1 S LINE=$T(@("XTROU+"_XTMUI_"^"_XTMUROUN)) S XTX1=$P(LINE,";",3) Q:XTX1=""  S XTCOMNT=$P(LINE,";",4) I '$D(XTMUROUL(XTX1)) S XTMUROUL(XTX1)="" D LOAD(XTX1,.XTMUNCNT,XTVALUE,XTCOMNT,.XTMUROUL)
 Q
 ;
GUINEXT(XTMURSLT,XTMULOC,XTGUISEP) ; Entry point for GUI execute next test
 ; XTGUISEP - added 110719 to provide for changing separator for GUI
 ;            return from ^ to another value ~~^~~  so that data returned
 ;            is not affected by ^ values in the data - if not present
 ;            sets value to default ^
 N XTMUETRY,XTMUROUT,XTOLROU,XTVALUE,XTMUERR,XTMUGUI
 N XTMUNIT
 I $G(XTGUISEP)="" S XTGUISEP="^"
 D SETUT
 S XTMUNIT("CNT")=0,XTMUNIT("LOC")=XTMULOC
 S XTVALUE=$NA(^TMP("GUI-MUNIT",$J))
 S XTMUNIT("RSLT")=$NA(^TMP("GUINEXT",$J)) K @XTMUNIT("RSLT")
 S XTMURSLT=XTMUNIT("RSLT")
 S XTMUETRY=$P(XTMULOC,U),XTMUROUT=$P(XTMULOC,U,2),XTOLROU=$G(@XTVALUE@("LASTROU"))
 S XTMUGUI=1
 I XTMUROUT'=XTOLROU D  I XTMUROUT="" S @XTMURSLT@(1)="" K @XTVALUE Q
 . ; 100622 JLI added code to handle STARTUP for GUI app
 . I XTOLROU="",$D(@XTVALUE@("STARTUP")) D
 . . S XTMUNIT("LOC")=@XTVALUE@("STARTUP")
 . . N $ETRAP S $ETRAP="D ERROR^XTMUNIT"
 . . D @(@XTVALUE@("STARTUP"))
 . . Q
 . I XTOLROU'="" I $T(@("TEARDOWN^"_XTOLROU))'="" D
 . . S XTMUNIT("LOC")="TEARDOWN^"_XTMUROUT
 . . N $ETRAP S $ETRAP="D ERROR^XTMUNIT"
 . . D @("TEARDOWN^"_XTOLROU)
 . . Q
 . S @XTVALUE@("LASTROU")=XTMUROUT I XTMUROUT'="",$T(@("SETUP^"_XTMUROUT))'="" D
 . . S XTMUNIT("LOC")="SETUP^"_XTMUROUT
 . . N $ETRAP S $ETRAP="D ERROR^XTMUNIT"
 . . D @("SETUP^"_XTMUROUT)
 . . Q
 . ; 100622 JLI added code to handle SHUTDOWN
 . I XTMUROUT="",$D(@XTVALUE@("SHUTDOWN")) D
 . . S XTMUNIT("LOC")=@XTVALUE@("SHUTDOWN")
 . . N $ETRAP S $ETRAP="D ERROR^XTMUNIT"
 . . D @(@XTVALUE@("SHUTDOWN"))
 . . Q
 . Q
 S XTMUNIT("LOC")=XTMULOC
 S XTMUNIT("CHK")=0,XTMUNIT("CNT")=1,XTMUERR=0
 D  ; to limit range of error trap so we continue through other tests
 . N $ETRAP S $ETRAP="D ERROR^XTMUNIT"
 . D @XTMUNIT("LOC")
 S @XTMUNIT("RSLT")@(1)=XTMUNIT("CHK")_XTGUISEP_(XTMUNIT("CNT")-1-XTMUERR)_XTGUISEP_XTMUERR
 Q
