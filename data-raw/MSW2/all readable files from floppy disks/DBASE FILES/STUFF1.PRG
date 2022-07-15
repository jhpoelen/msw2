set talk off
clear
FLD=space(10)
OLDSTR=space(20)
NEWSTR=space(20)
@ 6,17 say 'Enter field to be changed:     ' get FLD picture 'xxxxxxxxxx'
read
@ 9,1 say 'Current value:  '+&FLD
@ 12,17 say 'Enter string to be changed:    ' get OLDSTR picture ;
  'xxxxxxxxxxxxxxxxxxxx'
read
@ 14,17 say 'Enter new replacement string:  ' get NEWSTR picture ;
  'xxxxxxxxxxxxxxxxxxxx'
read
MCOL=at(trim(OLDSTR),&FLD)
if MCOL=0
   @ 17,17 say 'ERROR:  '+trim(OLDSTR)+' not found in field '+FLD
else
   replace &FLD with stuff(&FLD,MCOL,len(trim(OLDSTR)),trim(NEWSTR))
   @ 17,1 say 'New value:      '+&FLD
endif
set talk on
return
