XTMUNIT1	;JLI/FO-OAK-CONTINUATION OF UNIT TEST ROUTINE ;2013-07-26  11:34 AM
	;;7.3;TOOLKIT;**81**;APR 25 1995;Build 24
	;;Per VHA Directive 2004-038, this routine should not be modified
	D EN^XTMUNIT("ZZUTXTMU")
	Q
	;
CHEKTEST(ROU,XTMUNIT,XTMUETRY)	; Collect Test list.
	; XTMROU - input - Name of routine to check for tags with @TEST attribute
	; XTMUNIT - input/output - passed by reference
	; XTMUETRY - input/output - passed by reference
	; 
	; Test list collected in two ways:
	; - @TEST on labellines
	; - Offsets of XTENT
	;
	; NB: VEN/SMH - first block moved from XTMUNIT
	S XTMUNIT("ENTN")=0 ; Number of test, sub to XTMUETRY.
	;
	F XTMUI=1:1 S XTMUNIT("ELIN")=$T(@("XTENT+"_XTMUI_"^"_XTMUROU(XTMUNIT("CURR")))) Q:$P(XTMUNIT("ELIN"),";",3)=""  D
	. S XTMUNIT("ENTN")=XTMUNIT("ENTN")+1,XTMUETRY(XTMUNIT("ENTN"))=$P(XTMUNIT("ELIN"),";",3),XTMUETRY(XTMUNIT("ENTN"),"NAME")=$P(XTMUNIT("ELIN"),";",4)
	; VEN/SMH - END
	;
	; VEN/SMH - This code is far far more complex than it needs to be. Just use $TEXT.
	; get routine code into a location to check it
	N CNT,LN,I,DIF,X,XCNP,TMP,LINE
	S I=$$SETNAMES^XTECGLO(ROU,"") I I<0 Q "-1^Invalid Routine Name"
	; $$ROU(ROU) used a check of the ROUTINE file for file name
	; but routines with names longer than the standard always
	; show up as not found will trap the error instead if not present
	; I '$$ROU(ROU) Q "-1^Routine Not found" ; JLI 120806
	N $ETRAP S $ETRAP="D CATCHERR^XTMUNIT1"
	S DIF="TMP(",XCNP=0,X=ROU
	X ^%ZOSF("LOAD")
	I '$D(TMP(1,0)) Q
	F I=1:1 Q:'$D(TMP(I,0))  S LINE=TMP(I,0) I $E(LINE)'=" ",$$UP^XLFSTR(LINE)["@TEST" D
	. N TAGNAME,CHAR,NPAREN S TAGNAME="",NPAREN=0
	. F  Q:LINE=""  S CHAR=$E(LINE),LINE=$E(LINE,2,999) Q:CHAR=""  Q:" ("[CHAR  S TAGNAME=TAGNAME_CHAR
	. ; should be no paren or arguments
	. I CHAR="(" Q
	. F  Q:LINE=""  S CHAR=$E(LINE) Q:" ;"'[CHAR  S LINE=$E(LINE,2,999)
	. I $$UP^XLFSTR($E(LINE,1,5))="@TEST" S LINE=$E(LINE,6,999) D
	. . S XTMUNIT("ENTN")=XTMUNIT("ENTN")+1,XTMUETRY(XTMUNIT("ENTN"))=TAGNAME
	. . F  Q:LINE=""  S CHAR=$E(LINE) Q:CHAR?1AN  S LINE=$E(LINE,2,999)
	. . S XTMUETRY(XTMUNIT("ENTN"),"NAME")=LINE
	. . Q
	. Q
	Q
	;
CATCHERR	; catch error on trying to load file if it doesn't exist ; JLI 120806
	S $ZE="",$EC=""
	;
	; VEN/SMH 26JUL2013 - Moved GETTREE here.
GETTREE(XTMUROU,XTMULIST)	;
	; first get any other routines this one references for running subsequently
	; then any that they refer to as well
	; this builds a tree of all routines referred to by any routine including each only once
	N XTMUK,XTMUI,XTMUJ,XTMURNAM,XTMURLIN
	F XTMUK=1:1 Q:'$D(XTMUROU(XTMUK))  D
	. F XTMUI=1:1 S XTMURLIN=$T(@("XTROU+"_XTMUI_"^"_XTMUROU(XTMUK))) S XTMURNAM=$P(XTMURLIN,";",3) Q:XTMURNAM=""  D
	. . F XTMUJ=1:1:XTMULIST I XTMUROU(XTMUJ)=XTMURNAM S XTMURNAM="" Q
	. . I XTMURNAM'="",$T(@("+1^"_XTMURNAM))="" W:'$D(XWBOS) "Referenced routine ",XTMURNAM," not found.",! Q
	. . S:XTMURNAM'="" XTMULIST=XTMULIST+1,XTMUROU(XTMULIST)=XTMURNAM
	. . Q
	. Q
	Q
