set talk off
clear
FLD=space(10)
OLDSTR=space(20)
NEWSTR=space(20)
CNT=0
RN=recno()
@ 6,17 say 'Enter field to be changed:     ' get FLD picture 'xxxxxxxxxx'
read
@ 9,17 say 'Enter string to be changed:    ' get OLDSTR picture ;
  'xxxxxxxxxxxxxxxxxxxx'
read
@ 12,17 say 'Enter new replacement string:  ' get NEWSTR picture ;
  'xxxxxxxxxxxxxxxxxxxx'
read
go top
do while .not. eof()
   MCOL=at(trim(OLDSTR),&FLD)
   if MCOL<>0
      replace &FLD with stuff(&FLD,MCOL,len(trim(OLDSTR)),trim(NEWSTR))
      CNT=CNT+1
   endif
   skip
enddo
@ 16,17 say str(CNT,5)+' records modified.'
go RN
set talk on
return
