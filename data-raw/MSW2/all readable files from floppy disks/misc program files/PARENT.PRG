* Assign Parents

SET TALK OFF
Done = .F.
Target = 'CLASS'
Choices = ''

tDBF = '        '
CLEAR
@ 5, 10 SAY 'Database:' GET tDBF
READ
IF LEN(TRIM(tDBF)) = 0
  SET TALK ON
  RETURN
ENDIF

USE &tDBF
REPLACE ALL ME WITH RECNO() - 1

LOCATE FOR TRIM(NAME) = '-0-'
IF Found()
   tVar = ME
ELSE
   CLOSE DATA
   SET TALK ON
   RETURN
ENDIF

DO WHILE .NOT. Done

   GOTO TOP
   DO WHILE .NOT. EOF()
      ThisOne = TRIM(TAXON)
      IF ThisOne = Target
         REPLACE MYPARENT WITH tVar
         ? ThisOne + ' ' + PRINTNAME
      ELSE
         IF AT(ThisOne, Choices) > 0
            tVar = ME
         ENDIF
      ENDIF
      SKIP
   ENDDO

   DO CASE
   CASE Target = 'CLASS'
      Target = 'ORDER'
      Choices = 'CLASS'
   CASE Target = 'ORDER'
      Target = 'FAMILY'
      Choices = Choices + ' ORDER'
   CASE Target = 'FAMILY'
      Target = 'SUBFAMILY'
      Choices = Choices + ' FAMILY'
   CASE Target = 'SUBFAMILY'
      Target = 'GENUS'
      Choices = Choices + ' SUBFAMILY'
   CASE Target = 'GENUS'
      Target = 'SPECIES'
      Choices = Choices + ' GENUS'
   CASE Target = 'SPECIES'
      Done = .T.
   ENDCASE

ENDDO
      
CLOSE DATA
SET TALK ON
RETURN
