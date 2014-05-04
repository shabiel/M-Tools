XTMUNIT1    ;JLI/FO-OAK-CONTINUATION OF UNIT TEST ROUTINE ;2014-04-17  5:26 PM
    ;;7.3;TOOLKIT;**81**;APR 25 1995;Build 24
    ;
    ; Original by Dr. Joel Ivey
    ; Major contributions by Dr. Sam Habiel
    ;
    ; Changes:
    ; 130726 SMH - Moved test collection logic from XTMUNIT to here (multiple places)
    ; 131218 SMH - dependence on XLFSTR removed
    ; 131218 SMH - CHEKTEST refactored to use $TEXT instead of ^%ZOSF("LOAD")
    ; 131218 SMH - CATCHERR now nulls out $ZS if on GT.M
    ; 
    ; TODO: find this routine and add to repo.
    D EN^XTMUNIT("ZZUTXTMU")
    Q
    ;
CHEKTEST(ROU,XTMUNIT,XTMUETRY)  ; Collect Test list.
    ; XTMROU - input - Name of routine to check for tags with @TEST attribute
    ; XTMUNIT - input/output - passed by reference
    ; XTMUETRY - input/output - passed by reference
    ; 
    ; Test list collected in two ways:
    ; - @TEST on labellines
    ; - Offsets of XTENT
    ;
    S XTMUNIT("ENTN")=0 ; Number of test, sub to XTMUETRY.
    ;
    ; This stanza and everything below is for collecting @TEST.
    ; VEN/SMH - block refactored to use $TEXT instead of ^%ZOSF("LOAD")
    N I,LINE
    S I=$L($T(@(U_ROU))) I I<0 Q "-1^Invalid Routine Name"
    N $ETRAP S $ETRAP="D CATCHERR^XTMUNIT1"
    ;
    ; Complexity galore: $TEXT loops through routine
    ; IF tab or space isn't the first character ($C(9,32)) and line contains @TEST
    ; Load that line as a testing entry point
    F I=1:1 S LINE=$T(@("+"_I_U_ROU)) Q:LINE=""  I $C(9,32)'[$E(LINE),$$UP(LINE)["@TEST" D
    . N TAGNAME,CHAR,NPAREN S TAGNAME="",NPAREN=0
    . F  Q:LINE=""  S CHAR=$E(LINE),LINE=$E(LINE,2,999) Q:CHAR=""  Q:" ("[CHAR  S TAGNAME=TAGNAME_CHAR
    . ; should be no paren or arguments
    . I CHAR="(" Q
    . F  Q:LINE=""  S CHAR=$E(LINE) Q:" ;"'[CHAR  S LINE=$E(LINE,2,999)
    . I $$UP($E(LINE,1,5))="@TEST" S LINE=$E(LINE,6,999) D
    . . S XTMUNIT("ENTN")=XTMUNIT("ENTN")+1,XTMUETRY(XTMUNIT("ENTN"))=TAGNAME
    . . F  Q:LINE=""  S CHAR=$E(LINE) Q:CHAR?1AN  S LINE=$E(LINE,2,999)
    . . S XTMUETRY(XTMUNIT("ENTN"),"NAME")=LINE
    ;
    ;
    ;
    ; This Stanza is to collect XTENT offsets
    N XTMUI F XTMUI=1:1 S XTMUNIT("ELIN")=$T(@("XTENT+"_XTMUI_"^"_XTMUROU(XTMUNIT("CURR")))) Q:$P(XTMUNIT("ELIN"),";",3)=""  D
    . S XTMUNIT("ENTN")=XTMUNIT("ENTN")+1,XTMUETRY(XTMUNIT("ENTN"))=$P(XTMUNIT("ELIN"),";",3),XTMUETRY(XTMUNIT("ENTN"),"NAME")=$P(XTMUNIT("ELIN"),";",4)
    ;
    QUIT
    ;
    ; VEN/SMH - Is this catch needed anymore?
CATCHERR    ; catch error on trying to load file if it doesn't exist ; JLI 120806
    S $ZE="",$EC=""
    I +$SY=47 S $ZS="" ; VEN/SMH fur GT.M.
    QUIT
    ;
    ; VEN/SMH 26JUL2013 - Moved GETTREE here.
GETTREE(XTMUROU,XTMULIST)   ;
    ; first get any other routines this one references for running subsequently
    ; then any that they refer to as well
    ; this builds a tree of all routines referred to by any routine including each only once
    N XTMUK,XTMUI,XTMUJ,XTMURNAM,XTMURLIN
    F XTMUK=1:1 Q:'$D(XTMUROU(XTMUK))  D
    . F XTMUI=1:1 S XTMURLIN=$T(@("XTROU+"_XTMUI_"^"_XTMUROU(XTMUK))) S XTMURNAM=$P(XTMURLIN,";",3) Q:XTMURNAM=""  D
    . . F XTMUJ=1:1:XTMULIST I XTMUROU(XTMUJ)=XTMURNAM S XTMURNAM="" Q
    . . I XTMURNAM'="",$T(@("+1^"_XTMURNAM))="" W:'$D(XWBOS) "Referenced routine ",XTMURNAM," not found.",! Q
    . . S:XTMURNAM'="" XTMULIST=XTMULIST+1,XTMUROU(XTMULIST)=XTMURNAM
    QUIT
    ;
    ; VEN/SMH 17DEC2013 - Remove dependence on VISTA - Uppercase here instead of XLFSTR.
UP(X)  Q $TR(X,"abcdefghijklmnopqrstuvwxyz","ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    ;
COV(NMSP,COVCODE,VERBOSITY) ; VEN/SMH - PUBLIC ENTRY POINT; Coverage calculations
    ; NMSP: Namespace of the routines to analyze. End with * to include all routines.
    ;       Not using * will only include the routine with NMSP name.
    ;       e.g. PSOM* will include all routines starting with PSOM
    ;            PSOM will only include PSOM.
    ; COVCODE: Mumps code to run over which coverage will be calculated. Typically Unit Tests.
    ; VERBOSITY (optional): Scalar from -1 to 3.
    ;    - -1 = Global output in ^TMP("XTMCOVREPORT",$J)
    ;    - 0 = Print only total coverage
    ;    - 1 = Break down by routine
    ;    - 2 = Break down by routine and tag
    ;    - 3 = Break down by routine and tag, and print lines that didn't execute for each tag.
    ;
    Q:'(+$SY=47)  ; GT.M only!
    ;
    S VERBOSITY=+$G(VERBOSITY) ; Get 0 if not passed.
    N %ZR ; GT.M specific
    D SILENT^%RSEL(NMSP,"SRC") ; GT.M specific. On Cache use $O(^$R(RTN)).
    ;
    N RN S RN=""
    W "Loading routines to test coverage...",!
    F  S RN=$O(%ZR(RN)) Q:RN=""  W RN," " D
    . N L2 S L2=$T(+2^@RN)
    . S L2=$TR(L2,$C(9,32)) ; Translate spaces and tabs out
    . I $E(L2,1,2)'=";;" K %ZR(RN)  ; Not a human produced routine
    ;
    N RTNS M RTNS=%ZR
    K %ZR
    ;
    N GL
    S GL=$NA(^TMP("XTMCOVCOHORT",$J))
    K @GL
    D RTNANAL(.RTNS,GL)
    K ^TMP("XTMCOVCOHORTSAV",$J)
    M ^TMP("XTMCOVCOHORTSAV",$J)=^TMP("XTMCOVCOHORT",$J)
    ;
    ;
    K ^TMP("XTMCOVRESULT",$J)
    VIEW "TRACE":1:$NA(^TMP("XTMCOVRESULT",$J))  ; GT.M START PROFILING
    DO  ; Run the code, but keep our variables to ourselves.
    . NEW $ETRAP,$ESTACK
    . SET $ETRAP="Q:($ES&$Q) -9 Q:$ES  W ""CTRL-C ENTERED"""
    . USE $PRINCIPAL:(CTRAP=$C(3))
    . NEW (DUZ,IO,COVCODE,U,DILOCKTM,DISYS,DT,DTIME,IOBS,IOF,IOM,ION,IOS,IOSL,IOST,IOT,IOXY)
    . XECUTE COVCODE
    VIEW "TRACE":0:$NA(^TMP("XTMCOVRESULT",$J))  ; GT.M STOP PROFILING
    ;
    D COVCOV($NA(^TMP("XTMCOVCOHORT",$J)),$NA(^TMP("XTMCOVRESULT",$J))) ; Venn diagram matching between globals
    ;
    ; Report
    I VERBOSITY=-1 D 
    . K ^TMP("XTMCOVREPORT",$J)
    . D COVRPTGL($NA(^TMP("XTMCOVCOHORTSAV",$J)),$NA(^TMP("XTMCOVCOHORT",$J)),$NA(^TMP("XTMCOVRESULT",$J)),$NA(^TMP("XTMCOVREPORT",$J)))
    E  D COVRPT($NA(^TMP("XTMCOVCOHORTSAV",$J)),$NA(^TMP("XTMCOVCOHORT",$J)),$NA(^TMP("XTMCOVRESULT",$J)),VERBOSITY)
    ;
    QUIT
    ;
RTNANAL(RTNS,GL) ; [Private] - Routine Analysis
    ; Create a global similar to the trace global produced by GT.M in GL
    ; Only non-comment lines are stored.
    ; A tag is always stored. Tag,0 is stored only if there is code on the tag line (format list or actual code).
    ; tags by themselves don't count toward the total.
    ;
    N RTN S RTN=""
    F  S RTN=$O(RTNS(RTN)) Q:RTN=""  D                       ; for each routine
    . N TAG
    . S TAG=RTN                                              ; start the tags at the first
    . N I,LN F I=2:1 S LN=$T(@TAG+I^@RTN) Q:LN=""  D         ; for each line, starting with the 3rd line (2 off the first tag)
    . . I $E(LN)?1A D  QUIT                                  ; formal line
    . . . N T                                                ; Terminator
    . . . N J F J=1:1:$L(LN) S T=$E(LN,J) Q:T'?1AN           ; Loop to...
    . . . S TAG=$E(LN,1,J-1)                                 ; Get tag
    . . . S @GL@(RTN,TAG)=TAG                                ; store line
    . . . I T="(" S @GL@(RTN,TAG,0)=LN                       ; formal list
    . . . E  D                                               ; No formal list
    . . . . N LNTR S LNTR=$P(LN,TAG,2,999),LNTR=$TR(LNTR,$C(9,32)) ; Get rest of line, Remove spaces and tabs
    . . . . I $E(LNTR)=";" QUIT                              ; Comment
    . . . . S @GL@(RTN,TAG,0)=LN                             ; Otherwise, store for testing
    . . . S I=0                                              ; Start offsets from zero (first one at the for will be 1)
    . . I $C(32,9)[$E(LN) D  QUIT                            ; Regular line
    . . . N LNTR S LNTR=$TR(LN,$C(32,9))                     ; Remove all spaces and tabs
    . . . I $E(LNTR)=";" QUIT                                ; Comment line -- don't want.
    . . . S @GL@(RTN,TAG,I)=LN                               ; Record line
    QUIT
    ;
ACTLINES(GL) ; [Private] $$ ; Count active lines
    ;
    N CNT S CNT=0
    N REF S REF=GL
    N GLQL S GLQL=$QL(GL)
    F  S REF=$Q(@REF) Q:REF=""  Q:(GL'=$NA(@REF,GLQL))  D
    . N REFQL S REFQL=$QL(REF)
    . N LASTSUB S LASTSUB=$QS(REF,REFQL)
    . I LASTSUB?1.N S CNT=CNT+1
    QUIT CNT
    ;
COVCOV(C,R) ; [Private] - Analyze coverage Cohort vs Result
    N RTN S RTN=""
    F  S RTN=$O(@C@(RTN)) Q:RTN=""  D  ; For each routine in cohort set
    . I '$D(@R@(RTN)) QUIT             ; Not present in result set
    . N TAG S TAG=""
    . F  S TAG=$O(@R@(RTN,TAG)) Q:TAG=""  D  ; For each tag in the routine in the result set
    . . N LN S LN=""
    . . F  S LN=$O(@R@(RTN,TAG,LN)) Q:LN=""  D  ; for each line in the tag in the routine in the result set
    . . . I $D(@C@(RTN,TAG,LN)) K ^(LN)  ; if present in cohort, kill off
    QUIT
    ;
COVRPT(C,S,R,V) ; [Private] - Coverage Report
    ; C = COHORT    - Global name
    ; S = SURVIVORS - Global name
    ; R = RESULT    - Global name
    ; V = Verbosity - Scalar from -1 to 3
    N ORIGLINES S ORIGLINES=$$ACTLINES(C)
    N LEFTLINES S LEFTLINES=$$ACTLINES(S)
    W !!
    W "ORIG: "_ORIGLINES,!
    W "LEFT: "_LEFTLINES,!
    W "COVERAGE PERCENTAGE: "_$S(ORIGLINES:$J(ORIGLINES-LEFTLINES/ORIGLINES*100,"",2),1:100.00),!
    W !!
    W "BY ROUTINE:",!
    I V=0 QUIT  ; No verbosity. Don't print routine detail
    N RTN S RTN=""
    F  S RTN=$O(@C@(RTN)) Q:RTN=""  D
    . N O S O=$$ACTLINES($NA(@C@(RTN)))
    . N L S L=$$ACTLINES($NA(@S@(RTN)))
    . W ?3,RTN,?21,$S(O:$J(O-L/O*100,"",2),1:"100.00"),!
    . I V=1 QUIT  ; Just print the routine coverage for V=1
    . N TAG S TAG=""
    . F  S TAG=$O(@C@(RTN,TAG)) Q:TAG=""  D
    . . N O S O=$$ACTLINES($NA(@C@(RTN,TAG)))
    . . N L S L=$$ACTLINES($NA(@S@(RTN,TAG)))
    . . W ?5,TAG,?21,$S(O:$J(O-L/O*100,"",2),1:"100.00"),!
    . . I V=2 QUIT  ; Just print routine/tags coverage for V=2; V=3 print uncovered lines
    . . N LN S LN=""
    . . F  S LN=$O(@S@(RTN,TAG,LN)) Q:LN=""  W TAG_"+"_LN_": "_^(LN),!
    QUIT
    ;
COVRPTGL(C,S,R,OUT) ; [Private] - Coverage Global for silent invokers
    ; C = COHORT    - Global name
    ; S = SURVIVORS - Global name
    ; R = RESULT    - Global name
    ; OUT = OUTPUT  - Global name
    ;
    N O S O=$$ACTLINES(C)
    N L S L=$$ACTLINES(S)
    S @OUT=(O-L)_"/"_O
    N RTN,TAG,LN S (RTN,TAG,LN)=""
    F  S RTN=$O(@C@(RTN)) Q:RTN=""  D
    . N O S O=$$ACTLINES($NA(@C@(RTN)))
    . N L S L=$$ACTLINES($NA(@S@(RTN)))
    . S @OUT@(RTN)=(O-L)_"/"_O
    . F  S TAG=$O(@C@(RTN,TAG)) Q:TAG=""  D
    . . N O S O=$$ACTLINES($NA(@C@(RTN,TAG)))
    . . N L S L=$$ACTLINES($NA(@S@(RTN,TAG)))
    . . S @OUT@(RTN,TAG)=(O-L)_"/"_O
    . . F  S LN=$O(@S@(RTN,TAG,LN)) Q:LN=""  S @OUT@(RTN,TAG,LN)=@S@(RTN,TAG,LN)
    QUIT
