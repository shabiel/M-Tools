ZZUTXTD1	;FO-OAK/JLI-UNIT TESTS FOR XTDEBUG ;05/10/08  13:27
	;;7.3;TOOLKIT;**???**;Apr 25, 1995
	D EN^XTMUNIT("ZZUTXTD1")
	Q
	;
LOGUTEST	; run unit test with logging turned on
	D INITEASY^XTMLOG("G,DEBUG-DATA","DEBUG")
	D EN^XTMUNIT("ZZUTXTD1")
	D ENDLOG^XTMLOG
	Q
	;
STARTUP	;
	Q
	;
SHUTDOWN	;
	Q
	;
OPENTAG	;
	N XTDEB1,XTDEB2,XTDEB3,XTDEBLOC,XTDEBLVL
	S XTDEBLOC=$$GETGLOB^XTDEBUG() K @XTDEBLOC
	;D FILEINIT^XTMLOG("ZZUTXTD1") K ^XTMP("ZZUTXTD1")
	S XTDEBLVL=1,@XTDEBLOC@("LASTLVL")=XTDEBLVL
	S @XTDEBLOC@("LVL",XTDEBLVL,"ROUTINE")="ZZUTXTD1",@XTDEBLOC@("LVL",XTDEBLVL,"LINE")=20
	D OPENTAG^XTDEBUG() ; no args, shouldn't error
	;
	D WARN^XTMLOG("IN OPENTAG")
	D OPENTAG^XTDEBUG("","") ;
	;
	S XTDEB1=5
	D OPENTAG^XTDEBUG("XTDEB1,""TEXT VALUE""","XTDEB2,XTDEB3")
	D CHKEQ^XTMUNIT(XTDEB2,"5","INDIVIDUAL VALUE NOT RIGHT")
	D CHKEQ^XTMUNIT(XTDEB3,"TEXT VALUE","STRING VALUE NOT RIGHT")
	;
	S XTDEB1="THIS VALUE"
	D OPENTAG^XTDEBUG("XTDEB1,$L(XTDEB1)","XTDEB2,XTDEB3")
	D CHKEQ^XTMUNIT(XTDEB2,"THIS VALUE","STRING VALUE NOT RIGHT")
	D CHKEQ^XTMUNIT(XTDEB3,"10","FUNCTION VALUE NOT RIGHT")
	;
	S XTDEB1="A1",XTDEB1(1)="A11",XTDEB1("B",4,3)="AB43"
	D OPENTAG^XTDEBUG(".XTDEB1,$$GETGLOB^XTDEBUG()","XTDEB2,XTDEB3")
	D CHKEQ^XTMUNIT($G(XTDEB2),"A1","MISSING TOP LEVEL OF REFERENCE VARIABLE")
	D CHKEQ^XTMUNIT($G(XTDEB2(1)),"A11","MISSING SINGLE SUBSCRIPT")
	D CHKEQ^XTMUNIT($G(XTDEB2("B",4,3)),"AB43","MISSING MULTIPLE SUBSCRIPT")
	D CHKEQ^XTMUNIT($G(XTDEB3),"^TMP(""XTDEBUG"","_$J_")","BAD RESULT FROM INTRINSIC FUNCTION")
	D DEBUG^XTMLOG("EXITING OPENTAG")
	D ENDLOG^XTMLOG("ZZUTXTD1")
	Q
	;
LEAVETAG	;
	N AVALUE,X1,XTDEB1,XTDEB2,XTDEBLOC
	S X1="A1",AVALUE="B1",XTDEBLOC=$$GETGLOB^XTDEBUG() K @XTDEBLOC
	S @XTDEBLOC@("LASTLVL")=0
	D OPENTAG^XTDEBUG("X1","AVALUE")
	S AVALUE="A2"
	G LEAVETAG^XTDEBUG
	D CHKEQ^XTMUNIT(AVALUE,"B1","NOT THE PREVIOUS VALUE")
	D CHKEQ^XTMUNIT($G(@XTDEBLOC@("LASTLVL")),"0","LEVEL DIDN'T CHANGE CORRECTLY")
	;
	S XTDEB1="A1",XTDEB1(1)="A11",XTDEB1("B",4,3)="AB43",XTDEB2="DEB2",XTDEB2(1)="DEB2-1"
	D OPENTAG^XTDEBUG(".XTDEB1,$$GETGLOB^XTDEBUG()","XTDEB2,XTDEB3")
	S XTDEB2("B",4,3)="BB43"
	G LEAVETAG^XTDEBUG
	D CHKEQ^XTMUNIT(XTDEB1("B",4,3),"BB43","INCORRECT VALUE FOR REFERENCE VARIABLE")
	D CHKEQ^XTMUNIT(XTDEB2,"DEB2","PREVIOUS VALUE WASN'T RESTORED CORRECTLY")
	D CHKEQ^XTMUNIT(XTDEB2(1),"DEB2-1","SUBSCRIPT OF PREVIOUS VALUE WASN'T RESTORED CORRECTLY")
	Q
	;
NEWVARS	;handle newing of variables
	N X,B,XTDEBARG,XTDEBLOC
	S XTDEBLOC=$$GETGLOB^XTDEBUG()
	S @XTDEBLOC@("LASTLVL")=1,X="A",B="C",B(1)="B1"
	S XTDEBARG("ARGS",1)="X",XTDEBARG("ARGS",2)="B"
	D NEWVARS^XTDEBUG(.XTDEBARG)
	D CHKEQ^XTMUNIT($D(X),0,"X value wasn't cleared on NEWing")
	D CHKEQ^XTMUNIT($D(B),0,"B value wasn't cleared on NEWing")
	S X=1,X(1)="X1",B="B"
	D CHKEQ^XTMUNIT($D(X),11,"X value isn't correct")
	D CHKEQ^XTMUNIT($D(B),1,"B value isn't correct")
	D POPLEVEL^XTDEBUG
	D CHKEQ^XTMUNIT($D(X),1,"X $D isn't returned to previous value")
	D CHKEQ^XTMUNIT($D(B),11,"B $D isn't returned to previous value")
	D CHKEQ^XTMUNIT(X,"A","X value isn't returned to previous value")
	D CHKEQ^XTMUNIT(B(1),"B1","B value isn't returned to previous value")
	Q
	;
ADDLEVEL	;step into a level
	N XTDEBLOC
	S XTDEBLOC=$$GETGLOB^XTDEBUG()
	S @XTDEBLOC@("LASTLVL")=0 D ADDLEVEL^XTDEBUG
	D CHKEQ^XTMUNIT(@XTDEBLOC@("LASTLVL"),1,"Didn't increase LEVEL on entering new level")
	Q
	;
POPLEVEL	;
	N TESTVALU,XTDEBGLO
	S XTDEBGLO=$$GETGLOB^XTDEBUG()
	S @XTDEBGLO@("LASTLVL")=1 D POPLEVEL^XTDEBUG
	D CHKEQ^XTMUNIT(@XTDEBGLO@("LASTLVL"),0,"Didn't decrease LEVEL on leaving level")
	S @XTDEBGLO@("LASTLVL")=1 K TESTVALU S @XTDEBGLO@("LVL",@XTDEBGLO@("LASTLVL"),"NEWED","TESTVALU")="YEAH"
	D POPLEVEL^XTDEBUG
	D CHKEQ^XTMUNIT($D(TESTVALU),1,"TESTVALU $D not correct")
	D CHKEQ^XTMUNIT($G(TESTVALU),"YEAH","TESTVALU not correct")
	Q
	;
SETVARS	;
	N X1,Y1,XX,XVALS
	S XX("X1")="X1 VALUE",XX("Y1")="Y1 VALUE"
	D SETVARS^XTDEBUG(.XVALS,.XX)
	D CHKEQ^XTMUNIT($D(X1),1,"X1 $D incorrect")
	D CHKEQ^XTMUNIT(X1,"X1 VALUE","X1 VALUE IS INCORRECT")
	Q
FORLIMIT	; FOR LOOP WITH VARIABLE MAXIMUM LIMIT, NO QUIT
	S ZZUTX=0,ZZUTY=3 F ZZUTI=1:1:ZZUTY S ZZUTX=ZZUTX+ZZUTI
	Q
FORLIM1(A,B,C)	; FOR LOOP WITH INPUT VARIABLE LIMITS, NO QUIT
	S ZZUTX=0 F ZZUTXTDI=A:B:C S ZZUTX=ZZUTX+ZZUTXTDI
	Q
	;
FORCOMMA(A,B,C)	; FOR LOOP WITH COMMA SPECIFIERS
	S ZZUTX="" F ZZUTXTDI=A,B,C S ZZUTX=ZZUTX_$S(ZZUTX="":"",1:" ")_ZZUTXTDI
	Q
	;
FORCOMA1	; COMMA SPECIFIERS, INCLUDING RANGES
	S ZZUTX="" F ZZUTXTDI=1:1:3,"A",5:2:9,15 S ZZUTX=ZZUTX_$S(ZZUTX="":"",1:" ")_ZZUTXTDI
	;
DOLINEA	;
	S X=4,Y=3 D TESTENT^ZZUTXTD1(X,Y) F I=1:1:5 Q:I=3  S X=X+I ; COMMENT
	Q
	;
DOLINEB	;
	S X=4,Y=$$GETGLOB^XTDEBUG() ; W !,Y D DOLINEA G DOLINEC
	Q
	;
DOLINEC	;
	W !,"THE Y VALUE = ",Y
	Q
	;
NOARG	;
	D  S X=Y+2
	. S Y=1
	Q
	;
NOARG1	;
	S X=X+1 D
	. S Y=Y+1 D  S Y=X+Y+Z
	. . S Z=Z+4
	. . . S Z=Z+6 ; INTENTIONAL - IGNORE
	. . S Z=Z+Y
	S N=N+4
	Q
	;
TESTENT(VAR1,VAR2)	; test entry location
	N X,Y
	D TESTB
	S X=VAR1
	S Y=VAR2
	K VAR1,VAR2
	S X=X+Y
	D TESTENT1(3,14)
	S X=X-1
	Q
	;
TESTENT1(A,B)	;
	S X=X+A+B
	S Y=$$FACTORIL^ZZUTXTD1(3)
	Q
	;
FACTORIL(VALUE)	;
	N N1,N,VAL1
	S VAL1=VALUE
	N VALUE
	I VAL1=1 S N1=1
	E  S N1=$$FACTORIL^ZZUTXTD1(VAL1-1)
	S N=VAL1*N1
	Q N
	;
TESTA	;
	D
	. W !,"AT TESTA"
	. G TESTB
	W !,"BACK AT TESTA"
	Q
	;
TESTB	;
	W !,"IN TESTB"
	W !
	W !,"TEST1-"
	W "TESTB"
	W "-TESTC",!
	Q
	;
TESTREAD	;
	N DTIME,INVAL1,INVAL2,INVAL3,INVAL4,INVAL6,INVAL7,S
	S DTIME=300,S=2
	W !,"Normal Read PROMPT1: "
	R INVAL1:DTIME
	S X=1
	W !,"INPUT WAS ",INVAL1,!
	S X=2
	R !,"INPUT PROMPT2 (#2 Read): ",INVAL2#S:DTIME,"     INPUTPROMPT3: ",INVAL3:DTIME ; INTENTIONAL
	S X=3
	W !,"INPUT2 WAS: ",INVAL2,"    INVAL3: ",INVAL3,!,"ENTER INVAL4 (STAR READ): "
	S X=4
	R *INVAL4:DTIME ; INTENTIONAL
	S X=5
	W !,"INVAL4 (STAR READ): ",INVAL4,!
	S X=6
	W !,"Now two reads with out prompts and 2 second timeout"
	W !,"First is normal Read, Second is star (*) Read"
	W !,"Results of time-out shown between '|' characters",!
	R INVAL6:2
	S X=4
	W !,"INVAL6: |",INVAL6,"|",!
	S X=3
	R *INVAL7:2 ; INTENTIONAL
	S X=4
	W !,"INVAL7: |",INVAL7,"|"
	S X=7
	Q
	;
TESTSUB1(A,B,C)	; TEST SUB FOR CHECKING ARGUMENTS INPUT
	W !,"B=",B
	W !,"C=",C
	M VALA=A
	S VALB=B
	S VALC=C
	Q
	;
DODIC	;
	S DIC="^DOPT(""DII"",",DIC(0)="AEQZ" D ^DIC K DIC,DIK G Q:Y<0  S X=$P(Y(0),U,2,99) K Y
	Q
	;
Q	;
	Q
	;
DOGETFIL	;
	S DIC="^DOPT(""DII"",",DIC(0)="AEQZ"
	D GETFILE^DIC0(.DIC,.DIFILEI,.DIENS) I DIFILEI="" S Y=-1 Q
	S %=$P("K^",U,DIC(0)["K")
	S (D,DINDEX,DINDEX("START"))=$$DINDEX^DICL(DIFILEI,%)
	Q
	;
DTEST(A,B,C)	;
	S X=A_" "_B,Y=C
	S A="NEW VALUE"
	S A(1)="NEW VALUE1"
	Q
	;
POPTEST(A)	;
	K A
	S A=1
	Q
	;
XTROU	;
	;;ZZUTXTD2;
	;;ZZUTXTD3;
	;;ZZUTXTD4;
	;;ZZUTXTD5;
	;;ZZUTXTD6;
	;;ZZUTXTD7;
	;
XTENT	;
	;;OPENTAG;test ability to get variables correct for entering a tag
	;;LEAVETAG;check functioning of leaving or quiting a called tag
	;;NEWVARS;handle newing of variables
	;;POPLEVEL;handle coming out of a level
	;;ADDLEVEL;step into a level
	;;SETVARS;setup variables
