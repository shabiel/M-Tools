XTMUNIT1    ;JLI/FO-OAK-CONTINUATION OF UNIT TEST ROUTINE ;2014-04-01  12:53 PM
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
