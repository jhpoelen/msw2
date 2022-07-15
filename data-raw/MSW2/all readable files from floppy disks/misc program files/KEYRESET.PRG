*******************************************************
* KEYRESET.PRG                                        *
* Sets values of function keys from memory files      *
* Last revision: 10 March 1988 -- BEW                 *
* parameters: MemFile = name of memory variable file  *
*******************************************************

PARAMETERS MemFile

PUBLIC VFunc2, VFunc3, VFunc4, VFunc5, VFunc6
PUBLIC VFunc7, VFunc8, VFunc9, VFunc10

RESTORE FROM &MemFile ADDITIVE
SET FUNCTION  2 TO VFunc2
SET FUNCTION  3 TO VFunc3
SET FUNCTION  4 TO VFunc4
SET FUNCTION  5 TO VFunc5
SET FUNCTION  6 TO VFunc6
SET FUNCTION  7 TO VFunc7
SET FUNCTION  8 TO VFunc8
SET FUNCTION  9 TO VFunc9
SET FUNCTION 10 TO VFunc10

RETURN

