/**********************************************************
 * TAGPARSE.C
 * parse "tag-and-value" text into comma-delimited ASCII
 * this version for Don Wilson's mammal project
 *
 * Written by: Barbara Weitbrecht, Smithsonian OIRM
 * last revision: 5/31/91
 **********************************************************/

#include <stdio.h>
#include <string.h>

#define MAXTAGS 18                    /* maximum number of different tags */
#define MAXOUT 13                     /* number of output fields          */
#define MAXSTRING 254                 /* maximum length of I/O buffers    */
#define SMALLSTR 81                   /* length of short string           */
#define OUTFILE "TAGPARSE.DAT"        /* default output file name         */
#define TRUE 1
#define FALSE 0

FILE *infptr, *outfptr ;              /* our input and output files       */

/* adding 1 to MAXSTRING makes indexing more elegant later */
char iBuffer[MAXSTRING+1],            /* for processing input text        */
	oBuffer[MAXSTRING+1] ;           /* for holding output text          */

char *iStart = iBuffer,
	*iEnd   = iBuffer,               /* pointers into iBuffer            */
	*oStart = oBuffer,
	*oEnd   = oBuffer,
	*oLimit = oBuffer + MAXSTRING ;  /* pointers into oBuffer            */

int InLongValue ;                     /* if TRUE, value is truncated      */
int ThisTag,
    TagOut = 0 ;

enum Disposition
   { Special, Literal, Ignore } ;     /* what can happen to fields        */

/* Structure containing data on our tags */
struct TagStruct
   {
   char Tag[SMALLSTR] ;                /* the tag itself */
   enum Disposition Treatment ;        /* how to handle it */
   int OutputPos ;                     /* where it goes in the output */
   int TagLen ;                        /* how long it is */
   int Candidate ;                     /* workspace -- TRUE or FALSE */
   } ;

struct TagStruct TagData[MAXTAGS] =
   {   { "ORDER:",             Special,  0, 0, TRUE },
	  { "FAMILY:",            Special,  0, 0, TRUE },
	  { "SUBFAMILY:",         Special,  0, 0, TRUE },
	  { "*CURRENT NAME:",     Special,  0, 0, TRUE },
	  { "CURRENT NAME:",      Special,  0, 0, TRUE },
	  { "AUTHOR:",            Literal,  2, 0, TRUE },
	  { "CITATION:",          Literal,  3, 0, TRUE },
	  { "COMMON NAME:",       Literal,  4, 0, TRUE },
	  { "ORIGINAL NAME:",     Literal,  5, 0, TRUE },
	  { "TYPE SPECIES:",      Literal,  6, 0, TRUE },
	  { "TYPE(S):",           Literal,  7, 0, TRUE },
	  { "TYPE LOCALITY:",     Literal,  8, 0, TRUE },
	  { "DISTRIBUTION:",      Literal,  9, 0, TRUE },
	  { "COMMENT:",           Literal, 10, 0, TRUE },
	  { "STATUS:",            Literal, 11, 0, TRUE },
	  { "COMMON SYNONYM(S):", Literal, 12, 0, TRUE },
	  { "CONTRIBUTOR(S):",    Ignore,   0, 0, TRUE },
	  { "REVIEWER(S):",       Ignore,   0, 0, TRUE } } ;

char Taxa[5][SMALLSTR] =
	  { "ORDER", "FAMILY", "SUBFAMILY", "GENUS", "SPECIES" } ;

int MaxLengths[MAXOUT] ;

/**********************************************************
 *                   Function Prototypes
 **********************************************************/

char *GetNewLine(void) ;           /* get a line from the input file     */
void ResetOBuffer(void) ;          /* prepare oBuffer for a new line     */
void AddSpace(void) ;              /* add a space to oBuffer             */
void CopyToOBuffer(void) ;         /* move iBuffer into it               */
int  CheckForTag(void) ;           /* check iBuffer for initial tag      */
int  CheckForText(void) ;          /* move iStart to next non-white text */
void WriteToOutput(int) ;          /* writes contents of oBuffer to file */
void WriteField(int, char*) ;      /* actual field write occurs here     */
void Report(void) ;                /* final report to the user (stdout)  */


void main(int argc, char *argv[])
{
int i, temp ;
int TagFound = FALSE ;
char OutFileName[SMALLSTR] = OUTFILE ;           /* name of output file */

/* check syntax, exit with message if incorrect */
if ( (argc < 2) || (argc > 3) )
   {
   printf("Syntax:  TAGPARSE <infilename> [<outfilename>]") ;
   exit() ;
   }

/* open input file for reading -- if can't be opened, exit */
if ( ( infptr = fopen(argv[1], "r") ) == NULL )
   {
   printf("Input file %s cannot be opened\n", argv[1]) ;
   exit() ;
   }

/* if a second parameter was supplied, use it for the output file name */
if ( argc == 3 )
   strncpy(OutFileName, argv[2], SMALLSTR) ;

/* open output file for writing -- if can't be opened, exit */
if ( ( outfptr = fopen(OutFileName, "a") ) == NULL )
   {
   printf("Output file %s cannot be opened\n", OutFileName) ;
   fclose(infptr) ;
   exit() ;
   }

/* Initialize variables we will need */
/* Tag lengths are decremented to start counting at 0 */
for ( i=0 ; i < MAXTAGS ; i++ )
   TagData[i].TagLen = ( (strlen(TagData[i].Tag)) - 1 ) ;

/* initialize max length array*/
for ( i = 0 ; i < MAXOUT ; i++ )
   MaxLengths[i] = 0 ;

oLimit = (char *) (oBuffer + MAXSTRING) ;        /* end of output buffer */
ResetOBuffer() ;

/* locate the first tag or the end of the file */
TagFound = FALSE ;
while ( !(TagFound) )
   {
   /* watch out for EOF */
   if (GetNewLine() == NULL)
	 {
	 /* close input and output files */
	 fclose(infptr) ;
	 fclose(outfptr) ;
	 exit() ;
	 }
   TagFound = ( (ThisTag = CheckForTag()) != -1 );
   }

/* we have found the first tag here */
CopyToOBuffer() ;

/* now process the rest of the file */
while (GetNewLine() != NULL)
   {
   TagFound = ( (temp = CheckForTag()) != -1 );
   if ( TagFound )
	 {
	 WriteToOutput(ThisTag) ;
	 ThisTag = temp ;
	 ResetOBuffer() ;
	 CopyToOBuffer() ;
	 }
   else
	 {
	 AddSpace() ;
	 CopyToOBuffer() ;
	 }
   }

/* process the last tag in the file */
WriteToOutput(ThisTag) ;
Report() ;

/* close input and output files */
fclose(infptr) ;
fclose(outfptr) ;
}

/**********************************************************
 *                   end of main()
 **********************************************************/


/**********************************************************
 * get a line from infptr and put it into iBuffer;
 * set iStart and iEnd
 **********************************************************/
char *GetNewLine(void)
   {
   char *cp ;
   int i ;

   iStart = iEnd = iBuffer ;
   for ( i = 0 ; i < MAXSTRING ; i++ )
	 *(iBuffer + i) = '\0' ;

   if ( ( cp = fgets(iBuffer, MAXSTRING, infptr) ) != NULL )
	 iEnd = (char *) ( iStart + strlen(iBuffer) ) ;

   return cp ;
   }

/**********************************************************
 * prepare oBuffer for a new string,
 * set InLongValue to FALSE
 **********************************************************/
void ResetOBuffer(void)
   {
   int i ;
   oStart = oEnd = oBuffer ;
   for ( i = 0 ; i < MAXSTRING ; i++ )
	 *(oBuffer + i) = '\0' ;
   *oLimit = '\0' ;
   InLongValue = FALSE ;
   }

/**********************************************************
 * Copy text from iBuffer to oBuffer, starting at iStart;
 * if oBuffer overflows, set InLongValue to TRUE
 * Change all white-space chars (tabs and newlines)
 * to spaces, and all double quote to single quotes.
 * Then remove trailing spaces.
 **********************************************************/
void CopyToOBuffer(void)
   {
   char *iSave ;

   /* fix up some potentially troublesome characters */
   iSave = iStart ;
   while (iStart < iEnd)
	 {
	 if (isspace(*iStart))
	    *iStart = ' ' ;
	 else
	    {
	    if (*iStart == '\"')
		  *iStart = '\'' ;
	    }
	 iStart++ ;
	 }
   iStart = iSave ;

   /* move characters into oBuffer */
   while ( (iStart < iEnd) && ( !(InLongValue) ) )
	 {
	 *oEnd = *iStart ;
	 oEnd++ ;
	 iStart++ ;
	 if (oEnd >= oLimit)
	    {
	    printf("\n") ;               /* open a line in the log */
	    InLongValue = TRUE ;
	    }
	 }

   /* add overflow to log */
   if ( (InLongValue) && (iStart < iEnd) )
	 {
	 printf("%s", iStart) ;
	 }

   /* strip off white space characters */
   oEnd-- ;
   while ( (isspace(*oEnd)) && (oEnd > oStart) )
	 {
	 *oEnd = '\0' ;
	 oEnd-- ;
	 }

   /* position to first null */
   while ( (*oEnd != '\0') && (oEnd < oLimit) )
	 oEnd++ ;
   }

/**********************************************************
 * add a space to oBuffer for a continued line
 **********************************************************/
void AddSpace(void)
   {
   if (oEnd < (oLimit-1))
	 {
	 *oEnd = ' ' ;
	 oEnd++ ;
	 }
   }

/**********************************************************
 * check text in iBuffer for an initial tag
 * if found, return the number of the tag
 * else, return -1
 **********************************************************/
int CheckForTag(void)
   {
   int i, j ;
   int rc = -1 ;
   int Found = FALSE ;
   int Position = 0 ;
   int NumCandidates = MAXTAGS ;
   char *iSave ;

   for (i = 0 ; i < MAXTAGS ; i++ )    /* initialize Candidate array */
	 TagData[i].Candidate = TRUE ;

   if ( CheckForText() )               /* is there text on the line? */
	 {
	 iSave = iStart ;                 /* points to first text */

	 /*
	  * check initial text in line until we have found a tag,
	  * or we know we don't have a tag,
	  * or we are at the end of the input text.
	  * if we find a tag, rc is the tag number.
	  */
	 while ( (NumCandidates > 0) && (iStart < iEnd) )
	    {
	    for (i = 0 ; i < MAXTAGS ; i++ )
		  {
		  /* for each, check if it's still a candidate */
		  if (TagData[i].Candidate)
			/* if so, check if we're past the end of the tag */
			if (Position > TagData[i].TagLen)
			   {
			   TagData[i].Candidate = FALSE ;
			   NumCandidates-- ;
			   }
			/* if we aren't, check current letter */
			else
			   {
				 if (*iStart == *(TagData[i].Tag+Position))
				 {
				 /* guard against substring matches */
				 if ( (Position == TagData[i].TagLen) &&
					 (*iStart == ':') )
				    {
				    Found = TRUE ;
				    rc = i ;
				    }
				 }
			   else
				 {
				 TagData[i].Candidate = FALSE ;
				 NumCandidates-- ;
				 }
			   }
		  if (Found)
			break ;
		  }
	    if (Found)
		  break ;
	    Position++ ;
	    iStart++ ;
	    }
	 }

   /*
    * if we find a tag, move iStart to next text
    * else, move iStart back to first text of line
    */
   if (Found)
	 {
	 iStart++ ;
	 CheckForText() ;
	 }
   else
	 iStart = iSave ;
   return (rc) ;
   }

/**********************************************************
 * move iStart to next non-white text in iBuffer.
 * if text is found, return TRUE;
 * if no text is found, leave iStart at iEnd and return FALSE.
 **********************************************************/
int CheckForText(void)
   {
   while ( (isspace(*iStart) ) && (iStart < iEnd) )
	 iStart++ ;
   return (iStart < iEnd) ;
   }

/**********************************************************
 * write the text in oBuffer to outfptr
 * tag id is signaled by parameter which
 **********************************************************/
void WriteToOutput(int which)
   {
   int i ;
   int where = TagData[which].OutputPos ;
   enum Disposition how = TagData[which].Treatment ;

   if (how != Ignore)
	 {
	 /* position to correct output field */
	 while (where != TagOut)
	    {
	    WriteField(TagOut, "") ;
	    TagOut = ((++TagOut) % MAXOUT) ;
	    }

	 /* normal field handling */
	 if (how == Literal)
	    {
	    WriteField(where, oBuffer) ;
	    TagOut = ((++TagOut) % MAXOUT) ;  /* increment output counter */
	    }

	 /* special field handling */
	 else
	    {
	    WriteField(0, Taxa[which]) ;
	    WriteField(1, oBuffer) ;

	    /* screen output so we can see how we're doing */
	    for (i = 0 ; i < which ; ++i )
		  printf("\t") ;
	    printf("%s\n", oBuffer) ;

	    TagOut = 2 ;
	    }

	 if (InLongValue)
	    printf("\n(Field: %s )\n\n", TagData[which].Tag) ;
	 }
   }

/**********************************************************
 * adds proper punctuation for writing field
 **********************************************************/
void WriteField(int where, char *what)
   {
   int howlong = strlen(what) ;

   /* record field length */
   if (howlong > MaxLengths[where])
	 MaxLengths[where] = howlong ;

   if (where == 0)
	 {
	 fprintf(outfptr, "\"%s\"", what) ;
	 }
	 else
	    {
	    if (where == (MAXOUT-1) )
		  {
		  fprintf(outfptr, ",\"%s\"\n", what) ;
		  }
	    else
		  {
		  fprintf(outfptr, ",\"%s\"", what) ;
		  }
	    }
   }

/**********************************************************
 * Report to user (stdout)
 **********************************************************/
void Report(void)
   {
   int i ;
   printf("\n\nMAXIMUM FIELD LENTHS:\n\n") ;
   for ( i = 0 ; i < MAXOUT ; i++ )
	 printf("Field %d:     %d\n", (i+1), MaxLengths[i]) ;
   }

