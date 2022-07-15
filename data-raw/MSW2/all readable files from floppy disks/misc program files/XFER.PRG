* XFER.PRG
* a Clipper program -- compiled to XFER.EXE

USE XFER2
GOTO TOP

DO WHILE .NOT. EOF()

   tVar = ALLTRIM(NAME)
   tTaxon = ALLTRIM(TAXON)
   tVar = STRTRAN(tVar, "<^")
   tVar = STRTRAN(tVar, "^>")

   REPLACE PRINTNAME WITH tVar

   IF tTaxon = 'SPECIES'
      tPos = AT(' ', tVar)
      tVar = SUBSTR(tVar, tPos+1)
   ENDIF

   REPLACE NAME WITH tVar
      
   ? PRINTNAME + ' * ' + NAME

   tComm = COMMENT
   IF Len(AllTrim(tComm)) > 0
      REPLACE NOTES WITH tComm
   ENDIF
   ? NOTES

   tSyn = SYNONYMS
   IF LEN(AllTrim(tSyn)) > 0
      REPLACE SYNON WITH tSyn
   ENDIF
   ? SYNON

   SKIP
   ? " "
ENDDO

CLOSE DATA
RETURN
