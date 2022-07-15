*************************************************************************
* REPORTIT.PRG
* Reports menu for the Taxa program
*
* last revision: 31 January 1992
*************************************************************************
* Called by:  TAXA.PRG
* Calls:      REPTPROC.PRG  (procedure file)
*************************************************************************
* text-formatting codes:
*
* <^  ^>   = underline on and off
* <$  $>   = small caps on and off
* <%  %>   = bold on and off
* 
* <!>      = hard carriage return
* <!!>     = 2 hard carriage returns
* <*>      = 1 indent
* <*#>     = 1 indent, 1 margin release
* <**#>    = 2 indents, 1 margin release
* <****##> = 4 indents, 2 margin releases
*
* <@>      = paragraph (in Comments only)
*
* style codes for PageMaker:
* <Order> <Family> <Subfamily> <Genus> <Subgenus> <Body text>
*************************************************************************

PRIVATE Working, Choice, Choices, Tb, tRow, Finished
PRIVATE tNum, vStart, OutFile, tTaxon, tName
PRIVATE StartRec, EndRec, EndType, Key1
PRIVATE vThisLine, vLastLine, vCRLF1, vCRLF2, vCRLF3, vnCRLF

CLOSE PROCEDURE
SET PROCEDURE TO REPTPROC
SET COLOR TO &Color2
SET ESCAPE OFF

Working = .T.
Choices = '1234567NQ'
Tb = 20

* top of main loop
DO WHILE Working 

   * close our alternate files
   * if any are open
   SET ALTERNATE OFF
   CLOSE ALTERNATE

   * Show menu, set Choice
   Choice = ' '
   CLEAR
   @ 3,3 TO 21, 75 DOUBLE
   @ 5,Tb  SAY 'REPORTS -- using database: ' + OurDBF
   @ ROW()+2,Tb  SAY '1  Names only'
   @ ROW()+1,Tb  SAY '2  All data -- empty fields not shown'
   @ ROW()+1,Tb  SAY '3  All data -- empty fields shown'
   @ ROW()+1,Tb  SAY "4  Copy editor's report -- book fields shown"
   @ ROW()+1,Tb  SAY "5  Copy editor's report -- empty fields not shown"
   @ ROW()+1,Tb  SAY "6  Author's report -- orginal tags"
   @ ROW()+1,Tb  SAY "7  Printer's report -- typesetting codes"
   @ ROW()+2,Tb  SAY 'N  NEW database'
   @ ROW()+1,Tb  SAY 'Q  Return to main menu'
   tRow = ROW()+2
   DO WHILE AT(Choice, Choices) = 0
      @ tRow,Tb SAY 'Your choice:' GET Choice PICTURE '!'
      READ
   ENDDO

   * exit if we need to
   IF Choice = 'Q'
      Working = .F.
      LOOP
   ENDIF

   * new database
   IF Choice = 'N'
      DO NewDBF WITH ''
      LOOP
   ENDIF

   * get info for all reports
   StartRec = 0
   EndRec = 0
   Key1 = ' '
   EndType = 'BRANCH'
   DO FindEnds WITH StartRec, EndRec, EndType, Key1
   IF Key1 = 12
      LOOP
   ENDIF

   IF vError = 0
      OutFile = 'OUTPUT' + Choice
      OutFile = OutFile + REPLICATE(' ', (8 - LEN(OutFile)) )
      DO QueryBox WITH 'Name of output file?', OutFile
      IF AT(OutFile, '.') = 0
         OutFile = TRIM(OutFile) + '.TXT'
      ENDIF
      SET ALTERNATE TO &OutFile
      SET ALTERNATE ON
   ELSE
      DO ErrorMsg
      Working = .F.
      LOOP
   ENDIF 

   GOTO StartRec
   DO GetDepth

   * process Choice
   DO CASE

   * Names only
   CASE Choice = '1'
      CLEAR
      vStart = Depth
      Finished = .F.
      DO WHILE .NOT. Finished
         tTaxon = UPPER(TRIM(TAXON))
         IF AT('SPEC', tTaxon) > 0 .OR. ;
            AT('GENUS', tTaxon) > 0
            tName = '<^' + TRIM(PRINTNAME) + '^>'
         ELSE
            tName = TRIM(PRINTNAME)
         ENDIF
         ? REPLICATE('   ', Depth+1) + tName
         DO CheckNext WITH EndType, EndRec, vStart, Finished
      ENDDO

      LOOP

   * Empty fields deleted, tags as in book
   CASE Choice = '2'
      CLEAR
      vStart = Depth
      Finished = .F.
      DO WHILE .NOT. Finished
         tTaxon = '<!!>' + UPPER(TRIM(TAXON))   && save two carriage returns
         IF AT('GENUS', tTaxon) > 0 .OR. ;
            AT('SPECIE', tTaxon) > 0
            ? tTaxon + ' <^' + TRIM(PRINTNAME) + '^> ' + TRIM(AUTHOR)
         ELSE
            ? tTaxon + '  ' + TRIM(PRINTNAME) + ' ' + TRIM(AUTHOR)
         ENDIF

         IF LEN(TRIM(CITATION)) > 0
            ? '<!>CITATION:<*>' + TRIM(CITATION)
         ENDIF

         IF LEN(TRIM(COMMON_NM)) > 0
            ? '<!>COMMON NAME:<*>' + TRIM(COMMON_NM)
         ENDIF

         IF LEN(TRIM(ORIG_NM)) > 0
            ? '<!>ORIGINAL NAME:<*>' + TRIM(ORIG_NM)
         ENDIF

         IF LEN(TRIM(TYPE_SPEC)) > 0
            ? '<!>TYPE SPECIES:<*>' + TRIM(TYPE_SPEC)
         ENDIF

         IF LEN(TRIM(TYPE_LOC)) > 0
            ? '<!>TYPE LOCALITY:<*>' 
            ? TRIM(TYPE_LOC)
         ENDIF

         IF LEN(TRIM(TYPES)) > 0
            ? '<!>TYPES:<*>' + TRIM(TYPES)
         ENDIF

         IF LEN(TRIM(DISTRIB)) > 0
            ? '<!>DISTRIBUTION:<*>'
            ? TRIM(DISTRIB)
         ENDIF                         

         IF LEN(TRIM(DISTRIB2)) > 0
            ? TRIM(DISTRIB2)
         ENDIF                         

         IF LEN(TRIM(STATUS_)) > 0
            ? '<!>STATUS:<*>'
            ? TRIM(STATUS_)
         ENDIF

         ? '<!>SYNONYMS:<*>'
         ? SYNON

         ? '<!>COMMENTS:<*>'
         ? NOTES

         DO CheckNext WITH EndType, EndRec, vStart, Finished

      ENDDO

   * Empty fields shown, tags as in book
   CASE Choice = '3'
      CLEAR
      vStart = Depth
      Finished = .F.
      DO WHILE .NOT. Finished
         tTaxon = '<!!>' + UPPER(TRIM(TAXON))         
         IF AT('GENUS', tTaxon) > 0 .OR. ;
            AT('SPECIE', tTaxon) > 0
            ? tTaxon + ' <^' + TRIM(PRINTNAME) + '^> ' + TRIM(AUTHOR)
         ELSE
            ? tTaxon + '  ' + TRIM(PRINTNAME) + ' ' + TRIM(AUTHOR)
         ENDIF

         ? '<!>CITATION:<*>' + TRIM(CITATION)
         ? '<!>COMMON NAME:<*>' + TRIM(COMMON_NM)
         ? '<!>ORIGINAL NAME:<*>' + TRIM(ORIG_NM)

         IF AT('GENUS', tTaxon) > 0
            ? '<!>TYPE SPECIES:<*>' + TRIM(TYPE_SPEC)
         ENDIF

         * species and subspecies
         IF AT('SPECIE', tTaxon) > 0
            ? '<!>TYPE LOCALITY:<*>' 
            ? TRIM(TYPE_LOC)
            ? '<!>TYPES:<*>' + TRIM(TYPES)
         ENDIF

         ? '<!>DISTRIBUTION:<*>'
         ? TRIM(DISTRIB)

         IF LEN(TRIM(DISTRIB2)) > 0
            ? TRIM(DISTRIB2)
         ENDIF                         

         ? '<!>STATUS:<*>'
         ? TRIM(STATUS_)

         ? '<!>SYNONYMS:<*>'
         ? SYNON
         ? '<!>COMMENTS:<*>'
         ? NOTES

         DO CheckNext WITH EndType, EndRec, vStart, Finished

      ENDDO

   * Create manuscript for copy editor
   CASE Choice = '4'
      CLEAR
      vCRLF1 = '<!><*#>'
      vCRLF2 = '<!><**#>'
      vCRLF3 = '<!><****##>'
      vStart = Depth
      Finished = .F.

      DO WHILE .NOT. Finished
         tTaxon = UPPER(TRIM(TAXON))         
         IF tTaxon = 'CLASS' .OR. ;
            tTaxon = 'ORDER' .OR. ;
            tTaxon = 'FAMILY' .OR. ;
            tTaxon = 'GENUS'

            vnCRLF = '<!!>'
         ELSE
            vnCRLF = '<!>'
         ENDIF            

         DO CASE

         CASE tTaxon = 'CLASS' .OR. ;
              tTaxon = 'ORDER'
               
            ? vnCRLF + vCRLF1 + tTaxon + ' ' + TRIM(PRINTNAME)
            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'FAMILY' .OR. ;
              tTaxon = 'SUBFAMILY'
               
            ? vnCRLF + vCRLF1 + '<%' + tTaxon + ' ' + TRIM(PRINTNAME) + ;
              '%> ' + TRIM(AUTHOR) + '  ' + TRIM(CITATION)
            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'GENUS' 
            ? vnCRLF + vCRLF1 + '<^' + TRIM(PRINTNAME) + '^> ' + ;
              TRIM(AUTHOR) + '  ' + TRIM(CITATION)
            ? vCRLF3 + 'TYPE SPECIES:  ' + TRIM(TYPE_SPEC)
            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'SUBGENUS' 
            ? vnCRLF + vCRLF2 + '<^' + TRIM(PRINTNAME) + '^> ' + ;
              TRIM(AUTHOR) + '  ' + TRIM(CITATION)
            ? vCRLF3 + 'TYPE SPECIES:  ' + TRIM(TYPE_SPEC)
            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'SPECIES' .OR. ;
              tTaxon = 'SUBSPECIE'
            ? vnCRLF + vCRLF2 + '<^' + TRIM(PRINTNAME) + '^> ' + ;
              TRIM(AUTHOR) + '  ' + TRIM(CITATION)
            ? vCRLF3 + 'TYPE LOCALITY:  ' 
            ? TRIM(TYPE_LOC)

            ? vCRLF3 + 'DISTRIBUTION:  ' 
            ? TRIM(DISTRIB)

            IF LEN(TRIM(DISTRIB2)) > 0
               ? TRIM(DISTRIB2)
            ENDIF

            ? vCRLF3 + 'STATUS:  '
            ? TRIM(STATUS_)

            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         OTHERWISE
            ? vCRLF + 'Unknown taxonomic level:  ' + tTaxon

         ENDCASE
         DO CheckNext WITH EndType, EndRec, vStart, Finished

      ENDDO

   * Create manuscript for copy editor, empty fields not shown
   CASE Choice = '5'
      CLEAR
      vCRLF1 = '<!><*#>'
      vCRLF2 = '<!><**#>'
      vCRLF3 = '<!><****##>'
      vStart = Depth
      Finished = .F.

      DO WHILE .NOT. Finished
         tTaxon = UPPER(TRIM(TAXON))         
         IF tTaxon = 'CLASS' .OR. ;
            tTaxon = 'ORDER' .OR. ;
            tTaxon = 'FAMILY' .OR. ;
            tTaxon = 'GENUS'

            vnCRLF = '<!!>'
         ELSE
            vnCRLF = '<!>'
         ENDIF            

         DO CASE

         CASE tTaxon = 'CLASS' .OR. ;
              tTaxon = 'ORDER'
               
            ? vnCRLF + vCRLF1 + tTaxon + ' ' + TRIM(PRINTNAME)
            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'FAMILY' .OR. ;
              tTaxon = 'SUBFAMILY'
               
            ? vnCRLF + vCRLF1 + '<%' + tTaxon + ' ' + TRIM(PRINTNAME) + ;
              '%> ' + TRIM(AUTHOR) + '  ' + TRIM(CITATION)
            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'GENUS' 
            ? vnCRLF + vCRLF1 + '<^' + TRIM(PRINTNAME) + '^> ' + ;
              TRIM(AUTHOR) + '  ' + TRIM(CITATION)

            IF LEN(TRIM(TYPE_SPEC)) > 0
               ? vCRLF3 + 'TYPE SPECIES:  ' + TRIM(TYPE_SPEC)
            ENDIF

            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'SUBGENUS' 
            ? vnCRLF + vCRLF2 + '<^' + TRIM(PRINTNAME) + '^> ' + ;
              TRIM(AUTHOR) + '  ' + TRIM(CITATION)

            IF LEN(TRIM(TYPE_SPEC)) > 0
               ? vCRLF3 + 'TYPE SPECIES:  ' + TRIM(TYPE_SPEC)
            ENDIF

            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         CASE tTaxon = 'SPECIES' .OR. ;
              tTaxon = 'SUBSPECIE'
            ? vnCRLF + vCRLF2 + '<^' + TRIM(PRINTNAME) + '^> ' + ;
              TRIM(AUTHOR) + '  ' + TRIM(CITATION)

            IF LEN(TRIM(TYPE_LOC)) > 0
               ? vCRLF3 + 'TYPE LOCALITY:  ' 
               ? TRIM(TYPE_LOC)
            ENDIF

            IF LEN(TRIM(DISTRIB)) > 0
               ? vCRLF3 + 'DISTRIBUTION:  ' 
               ? TRIM(DISTRIB)
            ENDIF

            IF LEN(TRIM(DISTRIB2)) > 0
               ? TRIM(DISTRIB2)
            ENDIF

            IF LEN(TRIM(STATUS_)) > 0
               ? vCRLF3 + 'STATUS:  '
               ? TRIM(STATUS_)
            ENDIF

            ? vCRLF3 + 'SYNONYMS:  '
            ? SYNON
            ? vCRLF3 + 'COMMENTS:  '
            ? NOTES

         OTHERWISE
            ? vCRLF + 'Unknown taxonomic level:  ' + tTaxon

         ENDCASE
         DO CheckNext WITH EndType, EndRec, vStart, Finished

      ENDDO

   * Author's copy, original tags
   CASE Choice = '6'
      CLEAR
      vStart = Depth
      Finished = .F.
      DO WHILE .NOT. Finished
         tTaxon = UPPER(TRIM(TAXON))         
         tName = TRIM(PRINTNAME)

         DO CASE
         CASE tTaxon = 'ORDER' 
            ? '<!!>' + 'ORDER:<*>' + tName
         CASE tTaxon = 'FAMILY'
            ? '<!!>' + 'FAMILY:<*>' + tName
         CASE tTaxon = 'SUBFAMILY'
            ? '<!!>' + 'SUBFAMILY:<*>' + tName
         CASE tTaxon = 'GENUS' .OR. tTaxon = 'SUBGENUS'
            ? '<!!>' + '*CURRENT NAME:<*><^' + tName + '^>'
         CASE tTaxon = 'SPECIES' .OR. tTaxon = 'SUBSPECIE'
            ? '<!!>' + 'CURRENT NAME:<*><^' + tName + '^>'
         ENDCASE

         ? '<!>AUTHOR:<*>' + TRIM(AUTHOR) 
         ? '<!>CITATION:<*>' + TRIM(CITATION)
         ? '<!>COMMON NAME:<*>' + TRIM(COMMON_NM)
         ? '<!>ORIGINAL NAME:<*>' + TRIM(ORIG_NM)

         * genus
         IF AT('GENUS', tTaxon) > 0
            ? '<!>TYPE SPECIES:<*>' + TRIM(TYPE_SPEC)
         ENDIF

         * species and subspecies
         IF AT('SPECIE', tTaxon) > 0
            ? '<!>TYPES:<*>' + TRIM(TYPES)
            ? '<!>TYPE LOCALITY:<*>' 
            ? TRIM(TYPE_LOC)
         ENDIF

         ? '<!>DISTRIBUTION:<*>'
         ? TRIM(DISTRIB)

         IF LEN(TRIM(DISTRIB2)) > 0
            ? TRIM(DISTRIB2)
         ENDIF                         

         ? '<!>COMMENT:<*>'
         ? NOTES

         ? '<!>STATUS:<*>'
         ? TRIM(STATUS_)

         ? '<!>COMMON SYNONYMS:<*>'
         ? SYNON

         DO CheckNext WITH EndType, EndRec, vStart, Finished

      ENDDO

   * Printer's copy, typesetting codes
   CASE Choice = '7'
      CLEAR
      vStart = Depth
      Finished = .F.
      DO WHILE .NOT. Finished
         tTaxon = UPPER(TRIM(TAXON))         
         tName = TRIM(PRINTNAME)

         DO CASE
         CASE tTaxon = 'ORDER' 
            ? '<!><Order>ORDER ' + UPPER(tName)
	      *** handle Rodentia suborder exception
              If name='Hystricognathi'
                ? '<FAMILYTOP> + TRIM(AUTHOR)'  
                ? '<!><Order><%Suborder ' + tName + '%> ' + ;
                 TRIM(AUTHOR) + ' ' + TRIM(CITATION)
              Endif	

         CASE tTaxon = 'FAMILY'
         *** handle exceptions in Rodentia where authors are at the family level 

         If name='Aplodontidae'
           ? '<FAMILYTOP> + TRIM(AUTHOR)'  
           ? '<!><Family><%Family ' + tName + '%> ' + ;
             TRIM(AUTHOR) + ' ' + TRIM(CITATION)

          Else
          If name='Sciuridae'
            ? '<FAMILYTOP> + TRIM(AUTHOR)'  
            ? '<!><Family><%Family ' + tName + '%> ' + ;
              TRIM(AUTHOR) + ' ' + TRIM(CITATION)

            Else
            If name='Castoridae'
              ? '<FAMILYTOP> + TRIM(AUTHOR)'   
              ? '<!><Family><%Family ' + tName + '%> ' + ;
               TRIM(AUTHOR) + ' ' + TRIM(CITATION)

              Else
              If name='Geomyidae'
                ? '<FAMILYTOP> + TRIM(AUTHOR)'
                ? '<!><Family><%Family ' + tName + '%> ' + ;
                 TRIM(AUTHOR) + ' ' + TRIM(CITATION)
 
                Else
                If name='Heteromyidae'
                  ? '<FAMILYTOP> + TRIM(AUTHOR)' 
                  ? '<!><Family><%Family ' + tName + '%> ' + ;
                   TRIM(AUTHOR) + ' ' + TRIM(CITATION)
  
                  Else
                  If name='Dipodidae'
                    ? '<FAMILYTOP> + TRIM(AUTHOR)' 
                    ? '<!><Family><%Family ' + tName + '%> ' + ;
                     TRIM(AUTHOR) + ' ' + TRIM(CITATION)
  
                    Else
                    If name='Muridae'
                      ? '<FAMILYTOP> + TRIM(AUTHOR)' 
                      ? '<!><Family><%Family ' + tName + '%> ' + ;
                       TRIM(AUTHOR) + ' ' + TRIM(CITATION)
          
                      Else
                      If name='Anomaluridae'
                        ? '<FAMILYTOP> + TRIM(AUTHOR)' 
                        ? '<!><Family><%Family ' + tName + '%> ' + ;
                         TRIM(AUTHOR) + ' ' + TRIM(CITATION)
         
                        Else
                        If name='Pedetidae'
                          ? '<FAMILYTOP> + TRIM(AUTHOR)' 
                          ? '<!><Family><%Family ' + tName + '%> ' + ;
                           TRIM(AUTHOR) + ' ' + TRIM(CITATION)
           
                         Else
                         If name='Ctenodactylidae'
                           ? '<FAMILYTOP> + TRIM(AUTHOR)' 
                           ? '<!><Family><%Family ' + tName + '%> ' + ;
                            TRIM(AUTHOR) + ' ' + TRIM(CITATION)
             
                           Else
                           If name='Myoxidae'
                             ? '<FAMILYTOP> + TRIM(AUTHOR)' 
                             ? '<!><Family><%Family ' + tName + '%> ' + ;
                              TRIM(AUTHOR) + ' ' + TRIM(CITATION)
                  
                             Else
                               ? '<!><Family><%Family ' + tName + '%> ' + ;
                               TRIM(AUTHOR) + ' ' + TRIM(CITATION)
  			   Endif
                         Endif
                       Endif
                     Endif
                   Endif
                 Endif
               Endif
             Endif
           Endif
         Endif
       Endif

         CASE tTaxon = 'SUBFAMILY'
            ? '<!><Subfamily><%Subfamily ' + tName + '%> ' + ;
              TRIM(AUTHOR) + ' ' + TRIM(CITATION)

         CASE tTaxon = 'GENUS'
            ? '<!><Genus><^' + tName + '^> ' + TRIM(AUTHOR) + ;
              ' ' + TRIM(CITATION)

            IF LEN(TRIM(TYPE_SPEC)) > 0
               ? '<!><Body text><$type species:$> ' + TRIM(TYPE_SPEC)
            ENDIF

         CASE tTaxon = 'SUBGENUS'
            ? '<!><Subgenus><^' + tName + '^> ' + TRIM(AUTHOR) + ;
              ' ' + TRIM(CITATION)

            IF LEN(TRIM(TYPE_SPEC)) > 0
               ? '<!><Body text><$type species:$> ' + TRIM(TYPE_SPEC)
            ENDIF

         CASE AT('SPECIE', tTaxon) > 0
            ? '<!><Species><^' + tName + '^> ' + TRIM(AUTHOR) + ;
              ' ' + TRIM(CITATION)

            IF LEN(TRIM(TYPE_LOC)) > 0
               ? '<!><Body text><$type locality:$> ' 
               ? TRIM(TYPE_LOC)
            ENDIF

            IF LEN(TRIM(DISTRIB)) > 0
               ? '<!><Body text><$distribution:$>' 
               ? TRIM(DISTRIB)
            ENDIF

            IF LEN(TRIM(DISTRIB2)) > 0
		? TRIM(DISTRIB2)
            ENDIF

            IF LEN(TRIM(STATUS_)) > 0
               ? '<!><Body text><$status:$> ' 
               ? TRIM(STATUS_)
            ENDIF

         ENDCASE

         ? '<!><Body text><$synonyms:$> '
         ? SYNON
         ? '<!><Body text><$comments:$> '
         ? NOTES

         DO CheckNext WITH EndType, EndRec, vStart, Finished
      ENDDO

   OTHERWISE
      DO MsgBox WITH 'Not a valid choice!', .T. 
   ENDCASE

   * detect fatal errors
   IF vError <> 0
      DO ErrorMsg
      Working = .F.
      vError = 0
   ENDIF

   * close our alternate files
   SET ALTERNATE OFF
   CLOSE ALTERNATE

   DO MsgBox WITH 'Halfway there....', .F.

   * now get rid of trailing blanks
   SELECT 2
   USE PRINTLN
   SET SAFETY OFF
   ZAP
   SET SAFETY ON
   APPEND FROM &Outfile TYPE SDF
   GOTO TOP

   SET ALTERNATE TO &Outfile
   SET ALTERNATE ON
   vThisLine = TRIM(PLINE)
   DO WHILE .NOT. EOF()
      vLastLine = vThisLine
      vThisLine = TRIM(PLINE)
      IF LEN(vLastLine) > 0             && strip out blank lines
         IF AT('<!', vThisLine) = 1
            ? vLastLine
         ELSE
            IF LEN(vLastLine) < 254
              ? vLastLine + ' '        && add a space if not before a tag
            ELSE
              ? vLastLine
            ENDIF
         ENDIF
      ENDIF
      SKIP
   ENDDO

   ? vThisLine

   SET ALTERNATE OFF
   CLOSE ALTERNATE

   SET SAFETY OFF
   ZAP
   SET SAFETY ON
   USE

   SELECT 1

ENDDO

* detect fatal errors
IF vError <> 0
   DO ErrorMsg
   vError = 0
ENDIF

CLOSE PROCEDURE
SET PROCEDURE TO TAXAPROC
SET COLOR TO &Color1

RETURN        && to TAXA.PRG


