XTMLOPAR	;JLI/FO-OAK - HANDLE PARSING FOR LOG4M XML CONFIGURATION FILE ;06/07/08  17:05
	;;7.3;TOOLKIT;**81**;Apr 25, 1995
	;;Per VHA Directive 2004-038, this routine should not be modified
	Q
ENTRY(XTMNAME,GLOBROOT,RESULTS)	; RESULTS is passed by reference
	S ELNUM=0,COUNT=0,APPCOUNT=0,GLOROOT=$NA(^TMP("JLIXML",$J)),GLOROOT(0)=GLOROOT K @GLOROOT
	S ARRAY("STARTDOCUMENT")="STARTDOC^XTMLOPAR",ARRAY("ENDDOCUMENT")="ENDDOC^XTMLOPAR"
	S ARRAY("DOCTYPE")="DOCTYPE^XTMLOPAR",ARRAY("STARTELEMENT")="STARTEL^XTMLOPAR"
	S ARRAY("ENDELEMENT")="ENDEL^XTMLOPAR",ARRAY("CHARACTERS")="CHARS^XTMLOPAR"
	S ARRAY("PI")="PI^XTMLOPAR",ARRAY("NOTATION")="NOTATION^XTMLOPAR"
	S ARRAY("EXTERNAL")="EXTERNAL^XTMLOPAR",ARRAY("COMMENT")="COMMENT^XTMLOPAR",ARRAY("ERROR")="ERROR^XTMLOPAR"
	D EN^MXMLPRSE(GLOBROOT,.ARRAY,"V")
	Q
	;
STARTDOC	; STARTDOCUMENT
	W !,"START DOC ENTRY"
	Q
	;
ENDDOC	; ENDDOCUMENT
	W !,"END DOC ENTRY"
	Q
	;
DOCTYPE(ROOT,PUBID,SYSID)	; DOCTYPE
	W !,"DOCTYPE ENTRY"
	W !,"ROOT=",ROOT,"  PUBID=",PUBID,"  SYSID=",SYSID
	Q
	;
STARTEL(NAME,ATTRIBS)	; STARTELEMENT
	;W !,"START ELEMENT ",NAME,! ZW ATTRIBS
	S ELNUM=$G(ELNUM)+1
	S COUNT=COUNT+1
	S GLOROOT(ELNUM)=$NA(@GLOROOT(ELNUM-1)@(NAME,COUNT))
	S A="" F  S A=$O(ATTRIBS(A)) Q:A=""  S @GLOROOT(ELNUM)@(A)=ATTRIBS(A)
	S FLAG=$G(FLAG),PARAMFLG=""
	I $$UP^XLFSTR(NAME)="ROOT" S FLAG="ROOT"
	I $$UP^XLFSTR(NAME)="APPENDER" S FLAG="APPENDER",APPNAME=""
	I $$UP^XLFSTR(NAME)="PARAM" S PARAMFLG=1
	I FLAG="ROOT" D ROOT(NAME,.ATTRIBS)
	I FLAG="APPENDER" D APPENDER(NAME,.ATTRIBS)
	Q
	;
ENDEL(NAME)	; ENDELEMENT
	W !,"END ELEMENT ",NAME
	K GLOROOT(ELNUM)
	S ELNUM=ELNUM-1
	Q
	;
CHARS(TEXT)	; CHARACTERS
	;W !,"IN CHARS: ",TEXT
	Q
	;
PI(TARGET,TEXT)	; PI
	;W !,"IN PI: TARGET=",TARGET,"  TEXT=",TEXT
	Q
	;
NOTATION(NAME,SYSID,PUBIC)	; NOTATION
	;W !,"IN NOTATION, NAME=",NAME,"  SYSID=,$G(SYSID),"  PUBIC=",$G(PUBIC)
	Q
	;
EXTERNAL(SYSID,PUBID,GLOBAL)	; EXTERNAL
	;W !,"IN EXTERNAL SYSID=",$G(SYSID),"  PUBID=",$G(PUBID),"  GLOBAL=",$G(GLOBAL)
	S PUBID=SYSID,SYSID=""
	Q
	;
COMMENT(TEXT)	; COMMENT
	;W !,"IN COMMENT: TEXT=",TEXT
	Q
	;
ERROR(ERR)	; ERROR - ERR is a local array
	;W !,"IN ERROR",! ZW ERR
	Q
	;
ROOT(NAME,ATTRIBS)	;
	N ATTNAME,COUNT
	;W !,"IN ROOT: NAME=",NAME,! ZW ATTRIBS
	S ATTNAME="",COUNT=0 F  S ATTNAME=$O(ATTRIBS(ATTNAME)) Q:ATTNAME=""  S COUNT=COUNT+1,XNAME(COUNT)=ATTNAME
	I COUNT=1 S RESULTS(XTMNAME,$$UP^XLFSTR(NAME))=$$UP^XLFSTR(ATTRIBS(XNAME(1)))
	Q
	;
APPENDER(NAME,ATTRIBS)	;
	I APPNAME="" D  Q
	. S ATTNAME="" F  S ATTNAME=$O(ATTRIBS(ATTNAME)) Q:ATTNAME=""  I $$UP^XLFSTR(ATTNAME)="NAME" S APPCOUNT=APPCOUNT+1,APPNAME=APPCOUNT,RESULTS(XTMNAME,"APPENDER",APPNAME,"TYPE")=$$UP^XLFSTR(ATTRIBS(ATTNAME))
	. I APPNAME'="" S ATTNAME="" F  S ATTNAME=$O(ATTRIBS(ATTNAME)) Q:ATTNAME=""  I $$UP^XLFSTR(ATTNAME)'="NAME" S RESULTS(XTMNAME,"APPENDER",APPNAME,$$UP^XLFSTR(ATTNAME))=$$UP^XLFSTR(ATTRIBS(ATTNAME))
	. Q
	; now parameters
	I PARAMFLG D  Q
	. S ATTNAME="",XNAME="",XVALUE="" F  S ATTNAME=$O(ATTRIBS(ATTNAME)) Q:ATTNAME=""  S:$$UP^XLFSTR(ATTNAME)="NAME" XNAME=ATTNAME S:$$UP^XLFSTR(ATTNAME)="VALUE" XVALUE=ATTNAME
	. I XNAME'="",XVALUE'="" S RESULTS(XTMNAME,"APPENDER",APPNAME,$$UP^XLFSTR(ATTRIBS(XNAME)))=$$UP^XLFSTR(ATTRIBS(XVALUE))
	. Q
	E  D DEBUG^XTMLOG("IN APPENDER WITH NO FLAG")
	Q
	;
LOADGLOB	; Load input (pasted) text into a global
	N XGLOB,COUNT,X
	W !,"Paste your text.  When there are no more lines within 5 seconds, it will finish.",!,":"
	S XGLOB=$NA(^TMP("XTMLOAD",$J)) K @XGLOB
	S COUNT=0 F  R X:5 Q:'$T  W ! D
	. F  Q:$E(X,$L(X))'=" "  S X=$E(X,1,$L(X)-1) ; remove trailing spaces
	. I X'="" S COUNT=COUNT+1,@XGLOB@(COUNT)=X ; skip null lines and store text
	. Q
	W !!,COUNT," lines input and stored under ",XGLOB
	Q
