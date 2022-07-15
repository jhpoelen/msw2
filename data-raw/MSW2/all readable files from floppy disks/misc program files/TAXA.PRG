*************************************************************************
* TAXA.PRG
* Manage data in a taxonomic hierarchy, in interpreted dBASE.
* Memo fields are included.
*
* last revision: 7 January 1992
*************************************************************************
* Calls:   TAXAPROC.PRG (procedure file)
*          KEYRESET.PRG (external program file)
*          REPORTIT.PRG (external program)       
*          UTIL.PRG     (external program file)
*************************************************************************
* Also required to run:
*          REPTPROC.PRG (procedure file called by REPORTIT.PRG)
*          UTILPROC.PRG (procedure file called by UTIL.PRG)
*          TAXA.FMT     (format file)
*          TAXA2.FMT    (format file)
*************************************************************************
* Uses:    COLORS.MEM   (saves screen colors)
*          TAXAKEYS.MEM (saves function key definitions)
*          TAXADEF.MEM  (saves name of current database)
*************************************************************************
* vError values:  0 = no error
*                 1 = null file
*                 2 = Root record not present
*                 3 = Root can't be located
*                 4 = Parent can't be found
*                 5 = Maximium depth exceeded
*************************************************************************

PUBLIC vReturn, Choice, Working, vPrompt, OurDBF
PUBLIC Color0, Color1, Color2, Color3
PRIVATE tFile, Choices, Tb, tRow, vDisk, vInFile, vOutFile, YesNo

* define environment
SET TALK OFF
SET ESCAPE OFF
SET STATUS OFF
SET EXACT OFF
SET BELL OFF
SET DELETED ON
CLOSE DATA
SET PROC TO TAXAPROC
SET FORMAT TO
SET HEADING OFF
SET MEMOWIDTH TO 78

* set default screen colors
Color0 = 'BG+/B, GR+/N, N'                     && dot prompt color
Color1 = 'BG+/B, GR+/N, B+'
Color2 = 'BG+/B, GR+/N, RB'
Color3 = 'BG+/B, GR+/N, G+'

* override defaults from a memory file
IF FILE('COLORS.MEM')
   RESTORE FROM COLORS ADDITIVE
ENDIF
SET COLOR TO &Color1

* get function keys from memory file
DO KEYRESET WITH 'TAXAKEYS'             && external program call

Choice = ' '
Choices = 'EASMDNIRUQ'
Tb = 20
vReturn = 0

Working = .T.
vPrompt = ' '

OurDBF = ''
DBFok = .F.

* set up our database environment
* if the memory file exists, get the current filename from it,
* else get it from user

SELECT 1

IF FILE('TAXADEF.MEM')
   RESTORE FROM TAXADEF ADDITIVE
   OurDBF = TRIM(LTRIM(OurDBF))
   tFile = OurDBF + '.DBF'
   IF FILE(tFile)
      DO NewDBF WITH OurDBF
      IF vReturn = 0
         DBFok = .T.
      ENDIF
   ELSE
      OurDBF = ' '
      DO NewDBF WITH OurDBF
      IF vReturn = 0
         DBFok = .T.
      ENDIF
   ENDIF
ELSE
   OurDBF = ' '
   DO NewDBF WITH ' '
   IF vReturn = 0
      DBFok = .T.
   ENDIF
ENDIF

* if user has named a non-existent database, offer to create it
IF (.NOT. DBFok) .AND. (vReturn = 2)
   YesNo = 'N'
   DO QueryBox WITH OurDBF + ' does not exist!  Create it?', YesNo
   IF YesNo = 'Y'
      USE XFER3
      SET SAFETY OFF
      COPY STRU TO &OurDBF
      SET SAFETY ON
      USE &OurDBF
      APPEND BLANK
      * note that the value of Root is given as a literal here.
      * we have not yet defined our global variables,
      * so this little inelegance is required.
      REPLACE ME WITH 0, MYPARENT WITH -1, RORDER WITH 0, ;
         NAME WITH '-0-', PRINTNAME WITH '-0-'
      DO NewDBF WITH OurDBF
      IF vReturn = 0
         DBFok = .T.
      ENDIF
   ENDIF
ENDIF

* restore environment and get out if no database was chosen
IF .NOT. DBFok
   DO ResetAll
   CLOSE PROC
   RETURN
ENDIF

* Set up structures needed to traverse tree, and position it to first element
DO TreeInit

* Check for unrooted tree or null file in error code (vError)
IF vError <> 0
   DO ErrorMsg
   Working = .F.
ENDIF

*************************************************************************
* Main loop:  do until user chooses to quit
*************************************************************************

DO WHILE Working 

   * Show menu, get Choice
   Choice = ' '
   CLEAR
   @ 2,3 TO 21, 75 DOUBLE
   @ 4,Tb  SAY 'MAMMALS OF THE WORLD -- using database ' + OurDBF
   @ ROW()+2,Tb  SAY 'E  EDIT'
   @ ROW()+1,Tb  SAY 'A  APPEND a new record'
   @ ROW()+1,Tb  SAY 'S  Reorder a SIBLING group'
   @ ROW()+1,Tb  SAY 'M  MOVE a group to a new parent'
   @ ROW()+1,Tb  SAY 'D  DELETE a record'

   @ ROW()+2,Tb  SAY 'N  Use a NEW database'
   @ ROW()+1,Tb  SAY 'I  Remake INDEX files'
   @ ROW()+1,Tb  SAY 'R  REPORT Menu'
   @ ROW()+1,Tb  SAY 'U  UTILITY Menu'

   @ ROW()+2,Tb  SAY 'Q  QUIT'
   tRow = ROW()+2
   * get user input until a valid key is struck
   DO WHILE AT(Choice, Choices) = 0
     @ tRow,Tb SAY 'Your choice:' GET Choice PICTURE '!'
     READ
   ENDDO

   * process Choice
   DO CASE

   * set flag for exit
   CASE Choice = 'Q'
      Working = .F.   

   * edit and traverse records             
   CASE Choice = 'E'
      DO EditAll

   * append a new record
   CASE Choice = 'A'
      DO AppendIt

   * order a sibling group
   CASE Choice = 'S'
      DO OrderSibs

   * move a group to a new parent
   CASE Choice = 'M'
      DO ReParent

   * delete a group
   CASE Choice = 'D'
      DO DeleteIt

   * use a new file
   CASE Choice = 'N'
      DO NewDBF WITH ' '

   * remake indices
   CASE Choice = 'I'
      DO MsgBox WITH 'Please wait while I update the database', .F.
      CLOSE DATA
      DO NewDBF WITH OurDBF
      SET TALK ON
      PACK
      SET TALK OFF

   * go to report menu
   CASE Choice = 'R'
      DO ReportIt                    && external program call

   * go to utility menu
   CASE Choice = 'U'
      DO Util                        && external program call

   OTHERWISE
      DO MsgBox WITH 'Not a valid choice!', .T. 
   ENDCASE

   * detect fatal errors
   IF vError <> 0
      DO ErrorMsg
      Working = .F.
   ENDIF
      
ENDDO

* save current database name to a memory file
SET SAFETY OFF
SAVE TO TAXADEF ALL LIKE OurDBF
SET SAFETY ON

* restore environment
DO ResetAll
CLOSE PROC
RETURN

