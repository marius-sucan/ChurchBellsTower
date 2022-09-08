/*
Scientific MATHS LIBRARY ( Filename = Maths.ahk )
by Avi Aryan v3.43
Thanks to hd0202, smorgasbord, Uberi and sinkfaze
Special thanks to smorgasbord for the factorial function
------------------------------------------------------------------------------
DOCUMENTATION - http://avi-aryan.github.io/ahk/functions/smaths.html
Math-Functions.ahk - https://github.com/avi-aryan/Avis-Autohotkey-Repo/blob/master/Functions/Math-Functions.ahk
##############################################################################
FUNCTIONS
##############################################################################
* NOTES ARE PROVIDED WITH EACH FUNCTION IN THE FORM OF COMMENTS. EXPLORE
* SM_Solve(Expression, AHK=false) --- Solves a Mathematical expression. (with extreme capabilites)
* SM_Add(number1, number2) --- +/- massive numbers . Supports Real Nos (Everything)
* SM_Multiply(number1, number2) --- multiply two massive numbers . Supports everything
* SM_Divide(Dividend, Divisor, length) --- Divide two massive numbers . Supports everything . length is number of decimals smartly rounded.
* SM_Greater(number1, number2, trueforequal=false) --- compare two massive numbers 
* SM_Prefect(number) --- convert a number to most suitable form. like ( 002 to 2 ) and ( 000.5600 to 0.56 )
* SM_fact(number) --- factorial of a number . supports large numbers 
* SM_toExp(number, decimals) --- Converts a number to Scientific notation format
* SM_FromExp(sci_num) --- Converts a scientific type formatted number to a real number
* SM_Pow(number, power) --- power of a number . supports large numbers and powers
* SM_Mod(Dividend, Divisor) --- Mod() . Supports large numbers
* SM_Round(number, decimals) --- Round() . Large numbers
* SM_Floor(number) --- Floor() . large numbers
* SM_Ceil(number)  --- Ceil() . large number
* SM_e(N, auto=1) --- returns e to the power N . Recommend auto=1 for speed
* SM_Number2base(N, base) --- Converts N to base 'base'
* SM_Base2Number(H, base) --- Converts H in base 'base' to a real number
* SM_UniquePmt(pattern, ID, Delimiter=",")   ;gives the unique permutation possible .
################################################################################
READ
################################################################################
* Pass the numbers as strings in each of these functions. This is done to avoid number trimming due to Internal AHK Limit
* For a collection of general Math functions, see  < Math-functions.ahk >
*/

;msgbox % SM_Solve("%sin(1.59)% e %log(1000)%")  ;is equal to  sin(1.59) e log(1000)  = 999.816
;msgbox % SM_Solve("4 + ( 2*( 3+(4-2)*round(2.5) ) ) + (5c2)**(4c3)")
;msgbox % "The gravity on earth is: " SM_Solve("(6.67e-11 * 5.978e24) / 6.378e6^2")
;msgbox % Sm_fact(40) ;<--try puttin one more zero here
;msgbox,% SM_Mod( SM_Pow(3,77), 79)
;msgbox,% SM_Round("124389438943894389430909430438098232323.427239238023823923984",4)
;msgbox,% SM_ToExp("328923823982398239283923.238239238923", 3)
;msgbox,% SM_Divide("43.034934034904334", "89.3467436743", 10)
;msgbox,% SM_UniquePmt("abcdefghijklmnopqrstuvwxyz0123456789",12367679898956098)
;msgbox,% SM_Mod("-22","-7")
;msgbox % SM_fromexp("6.45423e10")
;msgbox,% SM_Divide("48.45","19.45",2)
;msgbox,% SM_UniquePmt("avi,annat,koiaur,aurkoi")
;msgbox,% SM_Solve("(28*45) - (45*28)")
;msgbox,% SM_Add("1280232382372012010120325634", "-12803491201290121201212.98")
;MsgBox,% SM_Solve("23898239238923.2382398923 + 2378237238.238239 - (989939.9939 * 892398293823)")
;msgbox,% SM_ToExp("0.1004354545")

;var = sqrt(10!) - ( 2**5 + 5*8 )
;msgbox,% SM_Solve(var)

;Msgbox,% SM_Greater(18.789, 187)
;msgbox,% SM_Divide("434343455677690909087534208967834434444.5656", "8989998989898909090909009909090909090908656454520", 100)
;MsgBox,% SM_Multiply("111111111111111111111111111111111111111111.111","55555555555555555555555555555555555555555555.555")
;MsgBox,% SM_Prefect("00.002000")
;msgbox % t:=SM_Number2Base("10485761048", 2)  ;base 2
;msgbox % f:=SM_Number2base("10485761048", 32) ;base 32
;msgbox % SM_Base2Number(t, 2) "`n" SM_Base2Number(f, 32)
;return

;###################################################################################################################################################################

;#Include, Maths.ahk

/*
SM_Solve(expression, ahk=false)
Solves the expression in string. SM_Solve() uses the powerful functions present in the library for processing
ahk = true will make SM_Solve() use Ahk's +-/* for processing. Will be faster
* You can use global variables in expressions . To make SM_Solve see them as global vars, surround them by %..%
* To nest expressions with brackets , you can use the obvious ( ) brackets
* You can use numbers in sci notation directly in this function . ("6.67e-11 * 4.23223e24")
* You can use ! to calulate factorial ( 48! ) ( log(1000)! )
* You can use ^ or ** to calculate power ( 2.2321^12 ) ( 4**14 )
* You can use p or c for permutation or combination
* Use %...% to use functions with e, c, p . ("4**sin(3.14) + 5c%log(100)% + %sin(1.59)%e%log(1000)% + log(1000)!")
Example
   global someglobalvar := 26
   msgbox,% SM_Solve("Sqrt(%someglobalvar%) * 4! * log(100) * ( 3.43e3 - 2^5 )")
*/

SM_Solve(expression, ahk=false){
static fchars := "e- e+ **- ** **+ ^- ^+ + - * / \" , rchars := "#< #> ^< ^> ^> ^< ^> ¢ ¤ ¥ ¦ ¦"
;Reject invalid
if expression=
   return

;Check Expression for invalid
if expression is alpha
{
   temp2 := %expression%
   return %temp2%          ;return value of expression if it is a global variable or nothing
}
else if expression is number
{
   if !Instr(expression, "e")
      return expression
}


;Fix Expression
StringReplace,expression,expression,%A_space%,,All
StringReplace,expression,expression,%A_tab%,,All
expression := SM_Fixexpression(expression)

; Solving Brackets first
while b_pos := RegexMatch(expression, "i)[\+\-\*\\\/\^]\(")
{
   b_count := {"(": 1, ")": 0}
   b_temp := Substr(expression, b_pos+2)
   loop, parse, b_temp
   {
      b_count[A_LoopField] += 1
      if b_count["("] = b_count[")"]
      {
         end_pos := A_index
         break
      }
   }
   expression := Substr(expression, 1, b_pos) SM_Solve( Substr(expression, b_pos+2, end_pos-1) ) Substr(expression, end_pos+b_pos+2)
}
;Changing +,-,e-,e+ and all signs to different things
expression := SM_FixExpression(expression)       ;FIX again after solving brackets

loop,
{
   if !(Instr(expression, "(")){
      expression := SM_PowerReplace(expression, fchars, rchars, "All")          ;power replaces replaces those characters
      reserve .= expression
      break
   }
   temp := Substr(expression, 1, Instr(expression, "("))          ;till  4+2 + sin(
      temp := SM_PowerReplace(temp, fchars, rchars, "All")       ;we dont want to replace +- inside functions
   temp2 := SubStr(expression, Instr(expression, "(") + 1, Instr(expression, ")") - Instr(expression, "("))
   reserve .= temp . temp2
   expression := Substr(expression,Instr(expression, ")")+ 1)
}
;
expression := reserve
; The final solving will be done now
loop, parse, expression,¢¤¥¦
{

;Check for functions --
   if RegExMatch(A_LoopField, "iU)^[a-z0-9_]+\(.*\)$")             ;Ungreedy ensures throwing cases like sin(45)^sin(95)
   {
      fname := Substr(A_LoopField, 1, Instr(A_loopfield,"(") - 1)   ;extract func
      ffeed := Substr(A_loopfield, Instr(A_loopfield, "(") + 1, Instr(A_loopfield, ")") - Instr(A_loopfield, "(") - 1)   ;extract func feed
      loop, parse, ffeed,`,
      {
         StringReplace,feed,A_loopfield,",,All
         feed%A_index% := SM_Solve(feed)
         totalfeeds := A_index
      }

      if fname = SM_toExp
         outExp := 1             ; now output will be in Exp , set feed1 as the number
         , number := feed1

      else if totalfeeds = 1
         number := %fname%(feed1)
      else if totalfeeds = 2
         number := %fname%(feed1, feed2)
      else if totalfeeds = 3
         number := %fname%(feed1, feed2, feed3)
      else if totalfeeds = 4
         number := %fname%(feed1, feed2, feed3, feed4)   ;Add more like this if needed

      function := 1
   }
   else
      number := A_LoopField , function := 0

;Perform the previous assignment routine
if (char != "") {
   ;The order is important here
   if (!function) {
   while match_pos := RegExMatch(number, "iU)%.*%", output_var)
      output_var := Substr(output_var, 2 , -1)
      , number := Substr(number, 1, match_pos-1)   SM_Solve(Instr(output_var, "(") ? output_var : %output_var%)   Substr(number, match_pos+Strlen(output_var)+2)

   if Instr(number, "#") or Instr(number, "^")
      number := SM_PowerReplace(number, "#< #> ^> ^<", "e- e ^ ^-", "All")    ;replace #,^ back to e and ^
   ;Symbols
   ;As all use SM_Solve() , else-if is OK
   if ( p := Instr(number, "c") ) or ( p := p + Instr(number, "p") )       ;permutation or combination
      term_n := Substr(number, 1, p-1) , term_r := Substr(number,p+1)
      , number := SM_Solve( term_n "!/" term_r "!" ( Instr(number, "c") ? "/(" term_n "-" term_r ")!" : "" ) )

   else if Instr(number, "^")
      number := SM_Pow( SM_Solve( SubStr(number, 1, posofpow := Instr(number, "^")-1 ) )   ,   SM_Solve( Substr(number, posofpow+2) ) )
   else if Instr(number, "!")
      number := SM_fact( SM_Solve( Substr(number, 1, -1) ) )
   else if Instr(number, "e")             ; solve e
      number := SM_fromExp( number )
   }

   if (Ahk){
   if char = ¢
      solved := solved + (number)
   else if char = ¤
      solved := solved - (number)
   else if char = ¦
   {
      if !number
         return
      solved := solved / (number)
   }
   else if char = ¥
      solved := solved * (number)
   }else{

   if char = ¢
      solved := SM_Add(solved, number)
   else if char = ¤
      solved := SM_Add(solved,"-" . number)
   else if char = ¦
   {
      if !number
         return
      solved := SM_Divide(solved, number)
   }
   else if char = ¥
      solved := SM_Multiply(solved, number)
   }
}
if solved =
   solved := number

char := Substr(expression, Strlen(A_loopfield) + 1,1)
expression := Substr(expression, Strlen(A_LoopField) + 2)   ;Everything except number and char

}
return, outExp ? SM_ToExp( solved ) : SM_Prefect( solved )
}

;###############################################################################################################################

/*
SM_Add(number1, number2, prefect=true)
Adds or subtracts 2 numbers
To subtract A and B , do like       SM_Add(A, "-" B)   i.e. append a minus
*/

SM_Add(number1, number2, prefect=true){   ;Dont set Prefect false, Just forget about it.
;Processing
IfInString,number2,--
   count := 2
else IfInString,number2,-
   count := 1
else
   count := 0
IfInString,number1,-
   count+=1
;
n1 := number1
n2 := number2
StringReplace,number1,number1,-,,All
StringReplace,number2,number2,-,,All
;Decimals
dec1 := Instr(number1,".") ? StrLen(number1) - InStr(number1, ".") : 0
dec2 := Instr(number2,".") ? StrLen(number2) - InStr(number2, ".") : 0 

if (dec1 > dec2){
   dec := dec1
   loop,% (dec1 - dec2)
      number2 .= "0"
}
else if (dec2 > dec1){
   dec := dec2
   loop,% (dec2 - dec1) 
      number1 .= "0"
}
else
   dec := dec1
StringReplace,number1,number1,.
StringReplace,number2,number2,.
;Processing
;Add zeros
if (Strlen(number1) >= StrLen(number2)){
   loop,% (Strlen(number1) - strlen(number2))
      number2 := "0" . number2
}
else
   loop,% (Strlen(number2) - strlen(number1))
      number1 := "0" . number1

n := strlen(number1)
;
if count not in 1,3      ;Add
{
loop,
{
   digit := SubStr(number1,1 - A_Index, 1) + SubStr(number2, 1 - A_index, 1) + (carry ? 1 : 0)
   
   if (A_index == n){
      sum := digit . sum
      break
   }
   
   if (digit > 9){
      carry := true
      digit := SubStr(digit, 0, 1)
   }
   else
      carry := false
   
   sum := digit . sum
   }
   ;Giving sign
   if (Instr(n2,"-") and Instr(n1, "-"))
      sum := "-" . sum
}
;SUBTRACT ******************
elsE
{
;Compare numbers for suitable order
numbercompare := SM_Greater(number1, number2, true)
if !(numbercompare){
   mid := number2
   number2 := number1
   number1 := mid
}
loop,
{
   digit := SubStr(number1,1 - A_Index, 1) - SubStr(number2, 1 - A_index, 1) + (borrow ? -1 : 0)
   
   if (A_index == n){
      StringReplace,digit,digit,-
      sum := digit . sum
      break
   }
   
   if Instr(digit, "-")
      borrow:= true , digit := 10 + digit      ;4 - 6 , then 14 - 6 = 10 + (-2) = 8
   else
      borrow := false
   
   sum := digit sum
   }
   ;End of loop ;Giving Sign
   ;
   If InStr(n2,"--"){
      if (numbercompare)
         sum := "-" . sum
   }else If InStr(n2,"-"){
      if !(numbercompare)
         sum := "-" . sum
   }else IfInString,n1,-
      if (numbercompare)
         sum := "-" . sum
}
;End of Subtract - Sum
;End
if ((sum == "-"))      ;Ltrim(sum, "0") == ""
   sum := 0
;Including Decimal
If (dec)
   if (sum)
      sum := SubStr(sum,1,StrLen(sum) - dec) . "." . SubStr(sum,1 - dec)
;Prefect
return, Prefect ? SM_Prefect(sum) : sum
}

;###################################################################################################################

/*
SM_Multiply(number1, number2)
Multiplies any two numbers
*/

SM_Multiply(number1, number2){
;Getting Sign
positive := true
if Instr(number2, "-")
   positive := false
if Instr(number1, "-")
   positive := !positive
number1 := Substr(number1, Instr(number1, "-") ? 2 : 1)
number2 := Substr(number2, Instr(number2, "-") ? 2 : 1)
; Removing Dot
dec := InStr(number1,".") ? StrLen(number1) - InStr(number1, ".") : 0
If n2dotpos := Instr(number2, ".")
   dec := dec + StrLen(number2) - n2dotpos
StringReplace,number1,number1,.
StringReplace,number2,number2,.
; Multiplying
loop,% Strlen(number2)
   number2temp .= Substr(number2, 1-A_Index, 1)
number2 := number2temp
;Reversing for suitable order
product := "0"
Loop,parse,number2
{
;Getting Individual letters
row := "0"
zeros := ""
if (A_loopfield)
   loop,% (A_loopfield)
      row := SM_Add(row, number1, 0)
else
   loop,% (Strlen(number1) - 1)   ;one zero is already 5 lines above
      row .= "0"

loop,% (A_index - 1)   ;add suitable zeroes to end
   zeros .= "0"
row .= zeros
product := SM_Add(product, row, false)
}
;Give Dots
if (dec){
   product := SubStr(product,1,StrLen(product) - dec) . "." . SubStr(product,1 - dec)
   product := SM_Prefect(product)
}
;Give sign
if !(positive)
   product := "-" . product
return, product
}

;######################################################################################################################################
/*
SM_Divide(number1, number2, length=10)
Divide any two numbers
   length = defines the number of decimal places in the result
   
*/

SM_Divide(number1, number2, length:=15){
;Getting Sign
positive := true
if (Instr(number2, "-"))
   positive := false
if (Instr(number1, "-"))
   positive := !positive
StringReplace,number1,number1,-
StringReplace,number2,number2,-
;Perfect them
number1 := SM_Prefect(number1) , number2 := SM_Prefect(number2)

;Cases
;if !number1 && !number2
;   return 1
if !number2          ; return blank if denom is 0
   return

;Remove Decimals
dec := 0
if Instr(number1, ".")
   dec := - (Strlen(number1) - Instr(number1, "."))   ;-ve as when the num is multiplied by 10, 10 is divided
if Instr(number2, ".")
   dec := Strlen(number2) - Instr(number2, ".") + dec + 0
StringReplace,number1,number1,.
StringReplace,number2,number2,.

number1 := Ltrim(number1, "0") , number2 := Ltrim(number2, "0")
decimal := dec , num1 := number1 , num2 := number2   ;These wiil be used to handle point insertion

n1 := Strlen(number1) , n2 := StrLen(number2) ;Stroring n1 & n2 as they will be used heavily below
;Widen number1
loop,% n2 + length
   number1 .= "0"
coveredlength := 0 , dec := dec - n2 - length , takeone := false , n1f := n1 + n2 + length
;Start
while(number1 != "")
{
   times := 0 , below := "" , lendivide := 0 , n1fromleft := (takeone) ? Substr(number1, 1, n2+1) : Substr(number1, 1, n2)

   if SM_Greater(n1fromleft, number2, true)
   {
      todivide := n1fromleft
      loop, 10
      {
         num2temp%A_index% := SM_Multiply(number2, A_index)
         if !(SM_Greater(todivide, num2temp%A_index%, true)){
            lendivide := (takeone) ? n2 + 1 : n2
            times := A_index - 1 , below := num2temp%times%
            break
         }
      }
      res .= zeroes_r
   }
   else
   {
      todivide := SubStr(number1, 1, n2+1)   ; :-P (takeone) will not be needed here
      loop, 10
      {
         num2temp%A_index% := SM_Multiply(number2, A_index)
         if !(SM_Greater(todivide, num2temp%A_index%, true)){
            lendivide := n2 + 1
            times := A_index - 1 , below := num2temp%times%
            break
         }
      }
      if (coveredlength != 0)
            res .= zeroes_r "0"
   }
   res .= times , coveredlength+=(lendivide - Strlen(remainder))   ;length of previous remainder will add to number1 and so is not counted
   remainder := SM_Add(todivide, "-" below)

   if remainder = 0
      remainder := ""
   number1 := remainder . Substr(number1, lendivide + 1)

   if SM_Greater("0", remainder, true)
   {
      zeroes_k := ""
      loop,% Strlen(number1)
         zeroes_k .= "0"
      if (number1 == zeroes_k){
         StringTrimRight,number1,number1,1
         number1 := "1" . number1
         res := SM_Multiply(res, number1)
         break
      }
   }
   if times = 0
      break

   zeroes_r := "" , takeone := false
   if (remainder == "") {
      loop,
         if (Instr(number1, "0") == 1)
            zeroes_r .= "0" , number1 := Substr(number1, 2) , coveredlength+=1
         else
            break
   }
   if (Strlen(remainder) == n2)
      takeone := true
   else
      loop,% n2 - StrLen(remainder) - 1
         zeroes_r .= "0"
}
;Putting Decimal points"

if (dec < 0)
{
   oldformat := A_formatfloat
   SetFormat,float,0.16e
   Divi := Substr(num1,1,15) / Substr(num2,1,15) ; answer in decimals
   decimal := decimal + Strlen(Substr(num1,16)) - Strlen(Substr(num2,16))

   if (Instr(divi,"-"))
      decimal := decimal - Substr(divi,-1) + 1
   else
      decimal := decimal + Substr(divi,-1) + 1

   if (decimal > 0)
      res := Substr(res, 1, decimal) . "." . Substr(res, decimal + 1)
   else if (decimal < 0){
      loop,% Abs(decimal)
         zeroes_e .= "0"
      res := "0." zeroes_e res
   }
   else
      res := "0." res

   SetFormat,float,%oldformat%
}
else
{
   num := "1"
   loop,% dec
      num .= "0"
   res := SM_Multiply(SM_Prefect(res), num)
}
return, ( (positive) ? "" : "-" ) . SM_Round(SM_Prefect(res), decimal < 0 ? Abs(decimal)+length : length)
}

;##########################################################################################################################################

/*
SM_UniquePmt(series, ID="", Delimiter=",")
Powerful Permutation explorer function that uses an unique algorithm made by the author to give a unique sequence linked to a number.
For example, the word "abc" has 6 permutations . So, SM_UniquePmt("abc", 1) gives a different sequence,  ("abc", 2) a different till ("abc", 6)
As the function is powered by the the specialist Mod, Division and Multiply functions, it can handle series larger series too.
Examples --
msgbox,% SM_UniquePmt("abcd")   ;leaving ID = "" gives all permutations
msgbox,% SM_UniquePmt("abcdefghijklmnopqrstuvwxyz123456789", 23322323323)   ;<----- That's called huge numbers
*/

SM_UniquePmt(series, ID="", Delimiter=","){

if Instr(series, Delimiter)
   loop, parse, series,%Delimiter%
      item%A_index% := A_LoopField , last := lastbk := A_Index
else{
   loop, parse, series
      item%A_index% := A_loopfield
   last := lastbk := Strlen(series) , Delimiter := ""
}

if (ID == "")         ;Return all possible permutations
{
   fact := SM_fact(last)
   loop,% fact
      toreturn .= SM_UniquePmt(series, A_index) . "`n"
   return, Rtrim(toreturn, "`n")
}

posfactor := (SM_Mod(ID, last) == "0") ? last : SM_Mod(ID, last)
incfactor := (SM_Mod(ID, last) == "0") ? SM_Floor(SM_Divide(ID,last)) : SM_Floor(SM_Divide(ID,last)) + 1

loop,% last
{
   tempmod := SM_Mod(posfactor + incfactor - 1, last)   ;should be faster
   posfactor := (tempmod == "0") ? last : tempmod    ;Extraction point
   res .= item%posfactor% . Delimiter , item%posfactor% := ""
   
   loop,% lastbk
      if (item%A_index% == "")
         plus1 := A_index + 1 , item%A_index% := item%plus1% , item%plus1% := ""

   last-=1
   if (posfactor > last)
      posfactor := 1
}
return, Rtrim(res, Delimiter)
}

;####################################################################################################################################
/*
SM_Greater(number1, number2, trueforqual=false)
Evaluates to true if number1 > number2
If the "trueforequal" param is true , the function will also evaluate to true if number1 = number2
*/

SM_Greater(number1, number2, trueforequal=false){
   
IfInString,number2,-
   IfNotInString,number1,-
      return, true
IfInString,number1,-
   IfNotInString,number2,-
      return, false

if (Instr(number1, "-") and Instr(number2, "-"))
   bothminus := true
number1 := SM_Prefect(number1) , number2 := SM_Prefect(number2)
; Manage Decimals
dec1 := (Instr(number1,".")) ? ( StrLen(number1) - InStr(number1, ".") ) : (0)
dec2 := (Instr(number2,".")) ? ( StrLen(number2) - InStr(number2, ".") ) : (0)

if (dec1 > dec2)
   loop,% (dec1 - dec2)
      number2 .= "0"
else if (dec2 > dec1)
   loop,% (dec2 - dec1) 
      number1 .= "0"

StringReplace,number1,number1,.
StringReplace,number2,number2,.
; Compare Lengths
if (Strlen(number1) > Strlen(number2))
   return,% (bothminus) ? (false) : (true)
else if (Strlen(number2) > Strlen(number1))
   return,% (bothminus) ? (true) : (false)
else   ;The final way out
{
   stop := StrLen(number1)
   loop,
   {
      if (SubStr(number1,A_Index, 1) > Substr(number2,A_index, 1))
         return bothminus ? 0 : 1
      else if (Substr(number2,A_index, 1) > SubStr(number1,A_Index, 1))
         return bothminus ? 1 : 0
   
      if (a_index == stop)
         return, (trueforequal) ? 1 : 0
   }
}

}

;#########################################################################################################################################
/*
SM_Prefect(number)
Converts any number to Perfect form i.e removes extra zeroes and adds reqd. ones. eg > SM_Prefect(000343453.4354500000)
*/

SM_Prefect(number){
number .= ""   ;convert to string if needed

number := RTrim(number, "+-")
if (number="")
   return 0

if Instr(number, "-")
   number := Substr(number, 2) , negative := true

if Instr(number, "."){
   number := Trim(number, "0")
   if (Substr(number,1,1) == ".")   ;if num like   .6767
      number := "0" number
   if (Substr(number, 0) == ".")   ;like 456.
      number := Substr(number, 1, -1)
   return,% (negative) ? ("-" . number) : (number)
} ; Non-decimal below
else
{
   if Trim(number, "0")
      return negative ? ("-" . Ltrim(number, "0")) : (Ltrim(number, "0"))
   else
      return 0
}
}

;###########################################################################################################################################
/*
SM_Mod(dividend, divisor)
Gives remanider when dividend is divided by divisor
*/

SM_Mod(dividend, divisor){
;Signs
positive := true
if Instr(divisor, "-")
   positive := false
if (Instr(dividend, "-"))
   positive := !positive
dividend := Substr(dividend, Instr(dividend, "-") ? 2 : 1) , divisor := Substr(divisor, Instr(divisor, "-") ? 2 : 1) , Remainder := dividend

;Calculate no of occurances
if SM_Greater(dividend, divisor, true){
   div := SM_Divide(dividend, divisor)
   div := Instr(div, ".") ? SubStr(div, 1, Instr(div, ".") - 1) : 0
   
   if ( div == "0" )
      Remainder := 0
   else
      Remainder := SM_Add(dividend, "-" SM_Multiply(Divisor, div))
}
return, ( (Positive or Remainder=0) ? "" : "-" ) . Remainder
}

;############################################################################################################################################
/*
SM_ToExp(number, decimals="") // SM_Exp
Gives exponential form of representing a number.
If decimals param is omitted , it is automatically detected.
? SM_Exp was the function's name in old versions and so a dummy function has been created
*/

SM_Exp(number, decimals=""){
   return SM_ToExp(number, decimals)
}

SM_ToExp(number, decimals=""){

   if (dec_pos := Instr(number, "."))
   {
      number := SM_Prefect(number) , number := Substr(number, Instr(number, "0")=1 ? 2 : 1)
      Loop, parse, number
      {
         if A_loopfield > 0
            break
         tempnum .= A_LoopField
      }
      number := Substr(number, Strlen(tempnum)+1) , power := dec_pos-Strlen(tempnum)-2
      number2 := Substr(number, 2)
      StringReplace,number2,number2,.
      number := Substr(number, 1, 1) "." number2
      decimals := ( decimals="" or decimals>Strlen(number2) ) ? Strlen(number2) : decimals
      return SM_Round(number, decimals) "e" power
   }
   else
   {
      number := SM_Prefect(number) , decimals := ( decimals="" or decimals>Strlen(Substr(number,2)) ) ? Strlen(Substr(number,2)) : decimals
      return SM_Round( Substr(number, 1, 1) "." Substr(number, 2), decimals ) "e" Strlen(number)-1
   }
}

/*
SM_FromExp(expnum)
Converts exponential form to number
*/

SM_FromExp(expnum){
   if !Instr(expnum, "e")
      return expnum
   n1 := Substr(expnum, 1, t := Instr(expnum, "e")-1) , n2 := Substr(expnum, t+2)
   return SM_ShiftDecimal(n1, n2)
}

;#######################################################################################################################################

/*
SM_Round(number, decimals)
Rounds a infinitely sized number to given number of decimals
*/

SM_Round(number, decimals){
if Instr(number,".")
{
   nofdecimals := StrLen(number) - ( Instr(number, ".") = 0 ? Strlen(number) : Instr(number, ".") )

   if (nofdecimals > decimals)
   {
      secdigit := Substr(number, Instr(number,".")+decimals+1, 1)
      if secdigit >= 5
         loop,% decimals-1
            zeroes .= "0"
      number := SM_Add(Substr(number, 1, Instr(number, ".")+decimals), (secdigit >= 5) ? "0." zeroes "1" : "0")
   }
   else
   {
      loop,% decimals - nofdecimals
         zeroes .= "0"
      number .= zeroes
   }
   return, Rtrim(number, ".")
}
else
   return, number
}

;###################################################################################################################################################

/*
SM_Floor(number)
Floor function with extended support. Refer to Ahk documentation for Floor()
*/

SM_Floor(number){
   number := SM_Prefect(number)

   if Instr(number, "-")
      if Instr(number,".")
         return, SM_Add(Substr(number, 1, Instr(number, ".") - 1), -1)
      else
         return, number
   else
      return, Instr(number, ".") ? Substr(number, 1, Instr(number, ".") - 1) : number
}

;##################################################################################################################################################

/*
SM_Ceil(number)
Ceil function with extended support. Refer to Ahk documentation for Ceil()
*/

SM_Ceil(number){
   
   number := SM_Prefect(number)
   if Instr(number, "-")
   {
      if Instr(number,".")
         return, Substr(number, 1, Instr(number, ".") - 1)
      else
         return, number
   }
   else
      return, Instr(number, ".") ? SM_Add( Substr(number, 1, Instr(number, ".") - 1), 1) : number
}

;#################################################################################################################################################

/*
SM_fact(number)
Gives factorial of number of any size. Try SM_fact(200)    :-;
;--- Edit
Now SM_Fact() uses smorgasboard method for faster results
   http://ahkscript.org/boards/viewtopic.php?f=22&t=176&p=4786#p4781
*/

SM_fact(N){
   res := 1 , k := 1 , carry := 0

   N -= 1
   loop % N
   {
      StringSplit, l_times, res
      index := l_times0
      k := A_index + 1

      Loop %index%
      {
         digit := k * l_times%index% + carry
         if ( digit > 9 )
         {
             carry := RegExReplace(digit, "(.*)(\d)", "$1")
             digit := RegExReplace(digit, "(.*)(\d)", "$2")
         }
         else
             carry := 0
         r := digit r
         index --
      }

      if ( carry != 0 )
         final := carry r
      else
          final := r

      res := final

      digit := index := final := r =
      r := ""
      carry := 0
   }

   return final ? final : 1
}

/*
SM_Pow(number, power)
Gives the power of a number . Uses SM_Multiply() for the purpose
*/

SM_Pow(number, power){

   if (power < 1)
   {
      if !power          ;0
         return 1
      if power Between -1 and 1
         return number ** power

      power := -power , I := Floor(power) , D := Mod(power, 1) 

      if Instr(number, "-") && D          ;if number is - and power is - in decimals , it doesnt exist ... -4 ** -2.5
         return

      D_part := number ** D             ;The power of decimal part
      I_part := SM_Pow(number, I)       ;Now I will always be >=1 . So it will fall in the below else part

      return SM_Prefect( SM_Divide(1, SM_Multiply(I_part, D_part)) )
   }
   else
   {
      if power > 6
      {
         sqrt_c := Floor(Sqrt(power))
         x_c := SM_Iterate(number, sqrt_c) , loopc := Floor(power/sqrt_c)
         x_c_loop := SM_iterate(x_c, loopc) , remPow := power - (sqrt_c*loopc)
         x_remPow := SM_iterate(number, remPow)
         return SM_Multiply(x_c_loop, x_remPow)
      }
      else x_7_pow7 := 1

      a := 1
      loop % Mod(power, 7)
         a := SM_Multiply(number, a)

      return SM_Multiply(x_7_pow7, a)
   }
}

/*
SM_e(N, auto=1)
   Gives the power of e to N
   auto = 1 enables smart rounding for faster results
   Call auto as false (0) for totally accurate results. (may be slow)
*/

SM_e(N, auto=1){
   static e := 2.71828182845905 , d := 14       ;rendering precise results with speed .

   if (N > 5) and auto
      e := SM_Round("2.71828182845905", (F := d-N+5)>2 ? F : 2)
   return SM_Pow(e, N)
}

/*
SM_ base Conversion functions
via Base to Number and Number to Base conversion
Base = 16 for HexaDecimal , 2 for Binary, 8 for Octal and 10 for our own number system
*/

SM_Number2Base(N, base=16){

   baseLen:=base<10 ? SM_Ceil((10/base)*Strlen(N)) : Strlen(N)

   if SM_checkformat(N) && SM_Checkformat(base**(baseLen-1))             ;check if N and base**base (used below) is compatitible
      loop % baseLen
         D:=Floor(N/(T:=base**(baseLen-A_index))),H.=!D?0:(D>9?Chr(D+87):D),N:=N-D*T
   else
      loop % baseLen
         D:=SM_Floor( SM_Divide(N , T:= SM_Pow(base, baselen-A_index)) ) , H.=!D?0:(D>9?Chr(D+87):D) , N:=SM_Add( N, "-" SM_Multiply(D,T) )

   return Ltrim(H,"0")
}

SM_Base2Number(H, base=16){
   StringLower, H, H          ;convert to lowercase for Asc to work
   S:=Strlen(H),N:=0
   loop,parse,H
      N := SM_Add(  N, SM_Multiply( (A_LoopField*1="")?Asc(A_LoopField)-87:A_LoopField , SM_Pow(base, S-A_index) )  )
   return N
}


;################# NON - MATH FUNCTIONS #######################################
;################# RESERVED ###################################################

; Checks if n is within AHK range
SM_Checkformat(n){
   static ahk_ct := 9223372036854775807
   if n < 0
      return 0
   if ( ahk_ct > n+0 )
      return 1
}

;Shifts the decimal point
;specify -<dec_shift> to shift in left direction

SM_ShiftDecimal(number, dec_shift=0){

   if Instr(number, "-")
      number := Substr(number,2) , minus := 1
   dec_pos := Instr(number, ".") , numlen := StrLen(number)

   loop % Abs(dec_shift)    ;create zeroes
      zeroes .= "0"
   if !dec_pos             ;add decimal to integers
      number .= ".0"
   number := dec_shift>0 ? number zeroes : zeroes number          ;append zeroes

   dec_pos := Instr(number, ".")       ;get dec_pos in the new number
   StringReplace, number, number, % "."

   number := Substr(number, 1, dec_pos+dec_shift-1) "." Substr(number, dec_pos+dec_shift)
   return ( minus ? "-" : "" ) SM_Prefect(number)
}

; powers a number n times
SM_Iterate(number, times){
   x := 1
   loop % times
      x := SM_Multiply(x, number)
   return x
}

; fast string replace
SM_PowerReplace(input, find, replace, options="All"){
   StringSplit, rep, replace, % A_space
   loop, parse, find, % A_Space
      StringReplace, input, input, % A_LoopField, % rep%A_index%, % options
   return Input
}


SM_FixExpression(expression){
expression := Rtrim(expression, "+-=*/\^")
StringReplace,expression,expression,--,+,All
StringReplace,expression,expression,-+,-,All
StringReplace,expression,expression,+-,-,All
StringReplace,expression,expression,++,+,All

;Reject invalid
if expression=
   return

;if (Substr(expression, 1, 1) != "+") or (Substr(expression, 1, 1) != "-")
if Substr(expression, 1, 1) == "-"
    expression := "0" expression          ;make it 0 - 10
else expression := "+" expression

loop,
{
if Instr(expression, "*-"){
   fromleft := Substr(expression, 1, Instr(expression, "*-"))
   StringGetPos,posplus,fromleft,+,R
   StringGetPos,posminus,fromleft,-,R
   if (posplus > posminus)
      fromleft := Substr(fromleft, 1, posplus) "-" Substr(fromleft, posplus + 2)
   else
      fromleft := Substr(fromleft, 1, posminus) "+" Substr(fromleft, posminus + 2)
   expression := fromleft . Substr(expression, Instr(expression, "*-") + 2)
}else if Instr(expression, "/-"){
   fromleft := Substr(expression, 1, Instr(expression, "/-"))
   StringGetPos,posplus,fromleft,+,R
   StringGetPos,posminus,fromleft,-,R
   if (posplus > posminus)
      fromleft := Substr(fromleft, 1, posplus) "-" Substr(fromleft, posplus + 2)
   else
      fromleft := Substr(fromleft, 1, posminus) "+" Substr(fromleft, posminus + 2)
   expression := fromleft . Substr(expression, Instr(expression, "/-") + 2)
}else if Instr(expression, "\-"){
   fromleft := Substr(expression, 1, Instr(expression, "\-"))
   StringGetPos,posplus,fromleft,+,R
   StringGetPos,posminus,fromleft,-,R
   if (posplus > posminus)
      fromleft := Substr(fromleft, 1, posplus) "-" Substr(fromleft, posplus + 2)
   else
      fromleft := Substr(fromleft, 1, posminus) "+" Substr(fromleft, posminus + 2)
   expression := fromleft . Substr(expression, Instr(expression, "\-") + 2)
}else if Instr(expression, "x-"){
   fromleft := Substr(expression, 1, Instr(expression, "x-"))
   StringGetPos,posplus,fromleft,+,R
   StringGetPos,posminus,fromleft,-,R
   if (posplus > posminus)
      fromleft := Substr(fromleft, 1, posplus) "-" Substr(fromleft, posplus + 2)
   else
      fromleft := Substr(fromleft, 1, posminus) "+" Substr(fromleft, posminus + 2)
   expression := fromleft . Substr(expression, Instr(expression, "x-") + 2)
}else
   break
}
StringReplace,expression,expression,--,+,All
StringReplace,expression,expression,-+,-,All
StringReplace,expression,expression,+-,-,All
StringReplace,expression,expression,++,+,All

return, expression
}


;<-------------------------------------------    BYE      -------------------------------------------------------------------------------->


/*
++++++++++++++++++++++
Math_Functions v0.13  +
-----------------------
by Avi Aryan          +
++++++++++++++++++++++

Math_Functions is a collection of useful mathematical functions for general usage.

++++++++++++++++++++++++++++
CREDITS  (Alphabetically)  +
++++++++++++++++++++++++++++
A v i
Lazzlo

############################
Scientific Maths (Maths.ahk) - https://github.com/Avi-Aryan/Avis-Autohotkey-Repo/blob/master/Functions/Maths.ahk
*/

/*
SolveQuadratic(x1, x2, a, b, c) // cubic(x1, x2, x3, a, b, c, d)     BY Lazzlo

   x1 = Byref variable to store 1st root
   x2 = Byref variable to store 2nd root
   x3 = Byref variable to store 3rd root
   
   a = first coefficient in the eqn
   .....
   d = fourth coefficient in the eqn

Returns >
   Returns the number of roots possible
*/

SolveQuadratic(ByRef x1, ByRef x2, a,b,c) { ; -> #real roots {x1,x2} of ax**2+bx+c
   i := fcmp(b*b,4*a*c,63) ; 6 LS bit tolerance
   If (i = -1) {
      x1 := x2 := ""
      Return 0
   }
   If (i = 0) {
      x1 := x2 := -b/2/a
      Return 1
   }
   d := sqrt(b*b - 4*a*c)
   x1 := (-b-d)/2/a
   x2 := x1 + d/a
   Return 2
}

SolveCubic(ByRef x1, ByRef x2, ByRef x3, a,b,c,d) { ; -> #real roots {x1,x2,x3} of ax**3+bx**2+cx+d
   Static pi23:=2.094395102393195492, pi43:=4.188790204786390985
   x := -b/3/a                                 ; Nickalls method
   y := ((a*x+b)*x+c)*x+d
   E2:= (b*b-3*a*c)/9/a/a
   H2:= 4*a*a*E2*E2*E2
   i := fcmp(y*y,H2, 63)
   If (i = 1) { ; 1 real root
      q := sqrt(y*y-H2)
      x1 := x + SolveNthRoot((-y+q)/2/a, 3) + SolveNthRoot((-y-q)/2/a, 3)
      x2 := x3 := ""
      Return 1
   }
   If (i = 0) { ; 3 real roots (1 or 2 different)
      If (fcmp(H2,0, 63) = 0) { ; root1 is triple...
         x1 := x2 := x3 := x
         Return 1
      } ; h <> 0                : root2 is double...
      E := SolveNthRoot(y/2/a, 3) ; with correct sign
      x1 := x - E - E
      x2 := x3 := x + E
      Return 2
   } ; i = -1   : 3 real roots (different)...
   t := acos(-y/sqrt(H2)) / 3
   E := 2*sqrt(E2)
   x1 := x + E*cos(t)
   x2 := x + E*cos(t+pi23)
   x3 := x + E*cos(t+pi43)
   Return 3
}

;##################################################

/*
SolveRoots(expression)     BY Avi Aryan

   expression = STRING containing CSV of coefficients in a polynomial

Returns >
   the Comma - separated roots of (expression)

Notes >
   * Requires Scientific Maths lib (Maths.ahk) .
   * Not dependable at all as it uses a smart loop to find roots.
     Use quadratic() and cubic() functions where they are possible.
*/

SolveRoots(expression){      ;Enter a, b, c for quad. eqn ------  a, b, c, d for cubic eqn. and so on
   StringReplace,expression,expression,%A_space%,,All
   StringReplace,expression,expression,%A_tab%,,All
   ;eqn, limit
   limit := 0
   loop, parse, expression,`,   ;get individual coffs
   {
      if !(Instr(A_Loopfield, "+") or Instr(A_loopfield, "-"))
         coff%A_index% := "+" A_loopfield
      else
         coff%A_index% := A_loopfield
   
      limit := limit + Abs(A_loopfield) , nofterms := A_index
   }

   loop % (nofterms - 1)   ;not including contsant
      term .= Substr(coff%A_index%, 1, 1) "(" Substr(coff%A_index%,2) . " * SM_Pow(x, " . (nofterms - A_index) . ")" ")"
   
   term .= coff%nofterms% , plot := limit
   
   if (limit / (nofterms-1) < 8)   ;if roots are within short range, slow down
      speed := defaultspeed := 0.2 , incomfac := "0.00" , lessfac := "0.01"
   else
      speed := defaultspeed := 1 , incomfac := "0.0" , lessfac := "0.05"

   positive := true
   StringReplace,expression,term,x,%plot%,All   ;getting starting value

   if Instr(SM_Solve(expression, 1), "-")
      positive := false

   while (plot >= -limit)   ;My theorem - Safe Range
   {
      StringReplace,expression,term,x,%plot%,All
      fx := SM_Solve(expression, true)   ;Over here ... Uses the AHK processes for faster results
   
      if (speed == defaultspeed){
         if (fx == "0"){
            roots .= SM_Prefect(plot) . ","
            positive := !positive , plot-=speed
            if (Instr(roots, ",", false, 1, nofterms - 1))   ;if all roots have already been found, go out
               break
            continue
         }
      }
      else{
         compare := Substr(Ltrim(fx, "-"),1,4)
         if ((Instr(compare,incomfac) == 1) or compare+0 < lessfac+0)
            {
            roots .= SM_Prefect(plot) . ","
            speed := defaultspeed , positive := !positive , plot-=speed
            if (Instr(roots, ",", false, 1, nofterms - 1))
               break
            continue
            }
         }

      if (positive){
         if (Instr(fx,"-")){
            plot+=defaultspeed , positive := !positive , speed := 0.01   ;Lower the value, more the time and accurateness
            continue
         }
      }else{
         if !(Instr(fx, "-")){
            plot+=defaultspeed , positive := !positive , speed := 0.01
            continue
         }
      }
      plot-=speed
   }
   return, Rtrim(roots, ",")
}

;##################################################

/*
SolveNthRoot(number, n)      BY Avi Aryan

   number = The number whose root is to extracted
   n = which root to be extracted
   
Returns >
   the (n)-th root of (number)
*/

SolveNthRoot(number, n){
   if Instr(number, "-")
   {
      number := Substr(number,2)
      if !Mod(n, 2)      ;check for even
         return
      sign := "-"
   }
   return sign . Round(number**(1/n))
}

;##################################################

/*
dec2frac(number)                    by Avi Aryan
   Converts decimal to fraction

Returns >
   space separated values of numerator and denominator
*/

dec2frac(number){
   if !( dec_pos := Instr(number, ".") )
      return number

   n_dec_digits := Strlen(number) - dec_pos , dec_num := Substr(number, dec_pos+1)
   , base_num := Substr(number, 1, dec_pos-1)

   t := 1
   loop % n_dec_digits   
      t .= "0"

   numerator := base_num*t + dec_num , denominator := t
   HCF := SolveGCD(numerator, denominator)
   numerator /= HCF , denominator /= HCF

   return Round(numerator) " " Round(denominator)
}

;##################################################

/*
SolveGCD(a,b)           BY Lazzlo

   a = first number
   b = second number

Returns >
   the Greatest Common Divisor/Highest common factor of the two numbers
*/

SolveGCD(a,b) {
   Return b=0 ? Abs(a) : SolveGCD(b, mod(a,b))
}

;##################################################

/*
Antilog(number, base)       BY Avi Aryan

   number = Number for which antilog is to be found
   base = base to be used in the process
   
Returns >
   the antilog of number (number) calculated by using base (base)
*/

Antilog(number, basetouse:=10){
   oldformat := A_FormatFloat
   SetFormat, float, 0.16

   if (basetouse="e")
      basetouse := 2.71828182845905
   else if (basetouse="pi")
      basetouse := 3.14159265358979

   toreturn := basetouse ** number ; why not use SM_Pow() ?
   SetFormat, floatfast, %oldformat%
   return, toreturn
}

;#################################################

/*
IsPrime(N)        By Avi

   Returns 1 if the number is prime 
*/

IsPrime(n) {         ;by kon
    if (n < 2)
        return, 0
    else if (n < 4)
        return, 1
    else if (!Mod(n, 2))
        return, 0
    else if (n < 9)
        return 1
    else if (!Mod(n, 3))
        return, 0
    else {
        r := Floor(Sqrt(n))
        f := 5
        while (f <= r) {
            if (!Mod(n, f))
                return, 0
            if (!Mod(n, (f + 2)))
                return, 0
            f += 6
        }
        return, 1
    }
}

;IsPrime(N){
;   if N in 2,3,5,7
;      return 1
;   else if !Mod(Lst := Substr(N, 0), 2) or (Lst = 5) or !Mod(N,3) or ( Mod(N-1, 6) && Mod(N+1, 6) )
;      return 0

;   Frt := Floor( Floor(Sqrt(N)) / 10 )

;   loop % Frt+1
;   {
;      if !Mod(N, A_index*10-7)  ;-10+3
;         return 0
;      if !Mod(N, A_index*10-3)  ;-10+7
;         return 0
;      if !Mod(N, A_index*10-9)   ;-10+1
;        if A_index >1
;          return 0
;   }
;   return 1
;}


;##################################################

Choose(n,k) {   ; Binomial coefficient BY Lazzlo
   p := 1, i := 0, k := k < n-k ? k : n-k
   Loop %k%                   ; Recursive (slower): Return k = 0 ? 1 : Choose(n-1,k-1)*n//k
      p *= (n-i)/(k-i), i+=1  ; FOR INTEGERS: p *= n-i, p //= ++i
   Return Round(p)
}

;##################################################

/*
FibonacciNthTerm(n)            BY Lazzlo
   n = nth term in fibonacci series

Returns >
   The (n)-th number in fibonacci series (The series starts from 1)
*/

FibonacciNthTerm(n) {        ; n-th Fibonacci number (n < 0 OK, iterative to avoid globals)
   a := 0, b := 1
   Loop % abs(n)-1
      c := b, b += a, a := c
   Return n=0 ? 0 : n>0 || n&1 ? b : -b
}
;##################################################

/*
SM_SimpleFactorial(n)          BY Lazzlo
   Also see Sm_fact() for any size.

Returns >
   The factorial of (n)
*/

SM_SimpleFactorial(n) {
   Return (n<2) ? 1 : n * SM_SimpleFactorial(n-1)
}

;##################################################

/*
LogB(number, base)          BY Avi Aryan

   number = number
   base = base of log

Returns >
   Log of (number) to the base (base)
*/

LogB(number, base){
   if ( number >= 0 AND base > 0 )
      return Round(log(number) / log(base))
}

;##################################################

/*
Trigometric_Functions(x)        BY Lazzlo

   x = angle in radians
   
Returns >
   The corresponding Trignometric value
*/

cot(x) {        ; cotangent
   Return 1/tan(x)
}
acot(x) {       ; inverse cotangent
   Return 1.57079632679489662 - atan(x)
}
atan2(x,y) {    ; 4-quadrant atan
   Return dllcall("msvcrt\atan2","Double",y, "Double",x, "CDECL Double")
}

sinh(x) {       ; hyperbolic sine
   Return dllcall("msvcrt\sinh", "Double",x, "CDECL Double")
}
cosh(x) {       ; hyperbolic cosine
   Return dllcall("msvcrt\cosh", "Double",x, "CDECL Double")
}
tanh(x) {       ; hyperbolic tangent
   Return dllcall("msvcrt\tanh", "Double",x, "CDECL Double")
}
coth(x) {       ; hyperbolic cotangent
   Return 1/dllcall("msvcrt\tanh", "Double",x, "CDECL Double")
}

asinh(x) {      ; inverse hyperbolic sine
   Return ln(x + sqrt(x*x+1))
}
acosh(x) {      ; inverse hyperbolic cosine
   Return ln(x + sqrt(x*x-1))
}
atanh(x) {      ; inverse hyperbolic tangent
   Return 0.5*ln((1+x)/(1-x))
}
acoth(x) {      ; inverse hyperbolic cotangent
   Return 0.5*ln((x+1)/(x-1))
}

;############################################################################################################################################################

fcmp(x,y,tol) {
   Static f
   If (f = "") {
      VarSetCapacity(f,162)
      Loop 324
         NumPut("0x"
. SubStr("558bec83e4f883ec148b5510538b5d0c85db568b7508578b7d148974241889542410b9000000807f"
. "137c0485f6730d33c02bc68bd91b5d0c89442418837d14007f137c0485d2730d33c02bc28bf91b7d1489442410"
. "8b7424182b7424108b45188bcb1bcff7d8993bd17f187c043bc677128b4518993bca7f0a7c043bf0770433c0eb"
. "183bdf7f117c0a8b44241039442418730583c8ffeb0333c0405f5e5b8be55dc3"
, 2*A_Index-1,2), f, A_Index-1, "Char")
   }
   Return DllCall(&f, "double",x, "double",y, "Int",tol, "CDECL Int")
}



