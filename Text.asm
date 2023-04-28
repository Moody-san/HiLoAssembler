INCLUDE Irvine32.inc
INCLUDE macros.inc
BUFFER_SIZE = 1000

.data
buffer BYTE BUFFER_SIZE DUP(?)
fileHandle HANDLE ?
arr byte "ace.txt",0
byte "2.txt",0
byte "3.txt",0
byte "4.txt",0
byte "5.txt",0
byte "6.txt",0
byte "7.txt",0
byte "8.txt",0
byte "9.txt",0
byte "10.txt",0
byte "j.txt",0
byte "q.txt",0
byte "k.txt",0
empty byte "empty.txt",0
start byte "start.txt",0
over byte "over.txt",0
shelf_card dword ?
shelf_card_offset dword ?
shelf_card_length dword ?
first_card dword ?
second_card dword ?
choice dword ?
hearts dword ?
points dword ?
print_card proto,
adr:dword,
sze:dword



;highscore data
;-----------------------------------------
buf byte 50 dup(?)
first byte "first.txt",0
second byte "second.txt",0
third byte "third.txt",0
fname byte "fname.txt",0
sname byte "sname.txt",0
tname byte "tname.txt",0
new_score byte 10 dup(?)
rev_new_score byte 10 dup(?)
current_score dword ?
cnt dword ?
current_name byte 10 dup(?)
convert_int proto,
x:dword,
y:dword
convert_str proto,
x:dword,
y:dword
reverse_str proto,
x:dword,
y:dword
read_high_scr proto,
x:dword,
y:dword
create_new_hs_file proto,
x:dword,
y:dword
.code

main PROC
l1:
call clrscr
call game_cycle
cmp eax,1
jne l100
jmp l1
l100:
exit
main ENDP


;main fucntion calls
game_cycle proc
invoke print_card,offset start,sizeof start   ;printing start game
call crlf
call waitmsg
mov hearts,3								;start of game set lives to 3
mov points,0								;start of game set points to 0
l2:
call clrscr
mwrite "							   HI-LOW"
;-----------------------------displaying lives left
mov esi,hearts		
mov ecx,esi
mov  dl,55 ;column
mov  dh,2 ;row
call Gotoxy
mwrite "LIVES:- "
l4:
	mov al,3
	call writechar
	mov al,32
	call writechar
loop l4
call crlf
;----------------------------displaying first card
call randomize				;set seed
call random_card			;get on deck card number
mov shelf_card,eax			;store its  value
;---------------------------game brain finds the file name from string array and calls other functions to print the card
call game_brain
;---------------------------displaying empty card
invoke print_card,offset empty,sizeof empty
;---------------------------user choice and process
call crlf
mwrite "				   IS THE SECOND CARD HIGHER OR LOWER THAN FIRST CARD ?"
CALL CRLF
mov ecx,2
l1:
mov  dl,0  ;column
mov  dh,23  ;row
call Gotoxy
;-------------------------- get user choice is empty card higher or lower ??
CALL get_Choice
cmp eax,1
je j3
cmp eax,2
je j3
jmp l1
j3:
mov choice,eax
;-----------------------clearing screen after choice made to print both the values of first and second card
call clrscr
;------------------------storing first card value
mov eax,shelf_card
mov first_card,eax
;------------------------getting empty card value (second card value)
call get_empty
;------------------------displaying first card
mov eax,first_card
mov shelf_card,eax
call game_brain
mov eax,second_card
mov shelf_card,eax
;-----------------------determining empty card value and printing it
call game_brain
;-----------------------all the processing involving reducing lives, assigning score and printing out weather the user made the correct choice is done here
call output
mov esi,hearts			;if heart 0 end round
cmp esi,0
je l100
call waitmsg
jmp l2
l100:
call clrscr
invoke print_card,offset over,sizeof over				;print game over
call crlf
mov eax,points											;display user score
mwrite "						    YOU SCORED : "
call writedec
call crlf												;check to see if a new high score is made 
call handle_highscore
mwrite "				TO RESTART GAME ENTER 1 (ANY OTHER INPUT QUITS THE GAME) : "
CALL readint
ret
game_cycle endp

;PRINT CARD FUNCTION
print_card proc,address:dword,_size:dword
mov edx,address
mov ecx,_size
call OpenInputFile
mov fileHandle,eax
; Read the file into a buffer.
mov edx,OFFSET buffer
mov ecx,BUFFER_SIZE
call ReadFromFile
mov buffer[eax],0 ; insert null terminator
; Display the buffer.
mov edx,OFFSET buffer ; display the buffer
call WriteString
call Crlf
mov eax,fileHandle
call CloseFile
ret
print_card endp

;RANDOM CARD FUNCTION
random_card proc
mov eax,13
call randomrange
ret
random_card endp

;GET EMPTY CARD VALUE FUNCTION
get_empty proc
l1:
call random_card
cmp eax,first_card
je l1
mov second_card,eax
ret
get_empty endp

;GET CHOICE
get_choice proc
mwrite "							1 :- HIGHER"
CALL CRLF
mwrite "							2 :- LOWER"
CALL CRLF
mwrite "							CHOICE: "
CALL READINT
ret
get_choice endp

;STRING LENGTH FUNCTION
string_length proc
mov esi,edx
mov edi,0
l1:
cmp [esi],byte ptr 0
je j3
inc esi
inc edi
jmp l1
j3:
ret
string_length endp

;GAME BRAIN FUNCTION
game_brain proc
mov eax,shelf_card
mov esi,offset arr
mov ebx,0
l1:
cmp eax,0
je j3
	l2:	
		cmp [arr+ebx],0
		je j2
		inc ebx
	jmp l2
j2:
inc ebx
dec eax
jmp l1
j3:
add esi,ebx
mov edx,esi
call string_length
mov shelf_card_offset,edx
mov shelf_card_length,edi
invoke print_card,edx,edi
ret
game_brain endp

;OUTPUT SCORE AND PROCESSES
output proc
mov eax,choice
mov ebx,second_card
mov edx,first_card
cmp eax,1
jne j3
cmp ebx,edx
jb j4
CALL CRLF
mwrite "							CORRECT ANSWER!"
mov esi,points
add esi,50
mov points,esi
JMP exitt
j3:
cmp ebx,edx
jb j5
CALL CRLF
mwrite "							WRONG ANSWER!"
mov esi,hearts
dec esi
mov hearts,esi
JMP exitt
j4:
CALL CRLF
mwrite "							WRONG ANSWER!"
mov esi,hearts
dec esi
mov hearts,esi
jmp exitt
j5:
CALL CRLF
mwrite "							CORRECT ANSWER!"
mov esi,points
add esi,50
mov points,esi
exitt:
call crlf
call crlf
ret
output endp

;highscore functions
;-----------------------------------------------

;get highscore from file
read_high_scr proc,_address:dword,_size:dword
mov edx,_address
mov ecx,_size
call OpenInputFile
mov fileHandle,eax
mov edx,OFFSET buf
mov ecx,49
call ReadFromFile
mov buf[eax],0
mov cnt,eax
mov eax,fileHandle
call closeFile
ret
read_high_scr endp

;convert highscore to integer
convert_int proc,_address:dword,_length:dword
mov ecx,_length
mov esi,_address
xor edx, edx            
xor eax, eax            
count:
imul edx,10; Multiply prev digits by 10 
lodsb; Load next char to al
sub al,48; Convert to number
add edx,eax; Add new number
loop count; Move to next digit
exitt:
mov eax,edx
ret
convert_int endp

;need to use this after converting from int to string
reverse_str proc,_address1:dword,_address2:dword
mov esi,_address1
mov edi,_address2
mov ecx,cnt
add esi,ecx
dec esi
l1:
mov al,[esi]
mov [edi],al
inc edi
dec esi
loop l1
mov [edi],byte ptr 0
ret
reverse_str endp 

;converts int to string but string is in reverse order so need to use above function
convert_str proc,_address:dword,_scr:dword
mov eax,_scr
mov ecx,cnt
mov esi,_address
l1:
cdq
mov ebx,10
div ebx
push eax
mov ebx,edx
add ebx,48
mov [esi],bl
pop eax
inc esi
loop l1
mov [esi],byte ptr 0
ret
convert_str endp 

;create new updated highscore file
create_new_hs_file proc,_address:dword,_string
mov edx,_address
call createOutputFile ;create new updated highscore file
mov fileHandle,eax
mov edx,_string
mov ecx,cnt
call writetofile
mov eax,fileHandle
call closeFile
ret
create_new_hs_file endp

;get len of highscore string 
get_len proc
push eax
mov ebx,10
mov esi,1
cmp eax,0
je exitt
l1:
cdq
div ebx
cmp eax,0
je exitt
inc esi
jmp l1
exitt:
pop eax
mov cnt,esi
ret
get_len endp

;logic to detemine if highscore is broken then it updates file with new name and new score
handle_highscore proc
mov current_score,eax
invoke read_high_scr,offset first,sizeof first ;get first player score
invoke convert_int,offset buf,cnt ;convert score to integer
mov ebx,current_score
cmp ebx,eax
jg j1
invoke read_high_scr,offset second,sizeof second
invoke convert_int,offset buf,cnt
mov ebx,current_score
cmp ebx,eax
jg j2
invoke read_high_scr,offset third,sizeof third
invoke convert_int,offset buf,cnt
mov ebx,current_score
cmp ebx,eax
jg j3
jmp exitt
j1:
push ebx
invoke read_high_scr,offset second,sizeof second
invoke create_new_hs_file,offset third,offset buf
invoke read_high_scr,offset first,sizeof first
invoke create_new_hs_file,offset second,offset buf
pop ebx
mov eax,ebx
call get_len
invoke convert_str,offset rev_new_score,eax
invoke reverse_str,offset rev_new_score,offset new_score
invoke create_new_hs_file,offset first,offset new_score

invoke read_high_scr,offset sname,sizeof sname
invoke create_new_hs_file,offset tname,offset buf
invoke read_high_scr,offset fname,sizeof fname
invoke create_new_hs_file,offset sname,offset buf

;; take input here
mwrite "ENTER NAME: "
mov edx,offset current_name
mov ecx,sizeof current_name
call readstring
mov ecx,eax
mov cnt,ecx
invoke create_new_hs_file,offset fname,offset current_name

jmp exitt
j2:
push ebx
invoke read_high_scr,offset second,sizeof second
invoke create_new_hs_file,offset third,offset buf
pop ebx
mov eax,ebx
call get_len
invoke convert_str,offset rev_new_score,eax
invoke reverse_str,offset rev_new_score,offset new_score
invoke create_new_hs_file,offset second,offset new_score

invoke read_high_scr,offset sname,sizeof sname
invoke create_new_hs_file,offset tname,offset buf

;; take input here
mwrite "ENTER NAME: "
mov edx,offset current_name
mov ecx,sizeof current_name
call readstring
mov ecx,eax
mov cnt,ecx
invoke create_new_hs_file,offset sname,offset current_name
jmp exitt
j3:
mov eax,ebx
call get_len
invoke convert_str,offset rev_new_score,eax
invoke reverse_str,offset rev_new_score,offset new_score
invoke create_new_hs_file,offset third,offset new_score

;;; take input here
mwrite "ENTER NAME: "
mov edx,offset current_name
mov ecx,sizeof current_name
call readstring
mov ecx,eax
mov cnt,ecx
invoke create_new_hs_file,offset tname,offset current_name
exitt:
call display_highscore
ret
handle_highscore endp

;display the current highscore 
display_highscore proc
call crlf
mwrite "					  |\|   HIGH    SCORE    TABLE   |\|"
call crlf
call crlf
mwrite"						    NAME         SCORE"
call crlf
call crlf
mwrite "					       1:->"
invoke read_high_scr,offset fname,sizeof fname
mov edx,offset buf
call writestring
invoke read_high_scr,offset first,sizeof first
mwrite"	 "
mov edx,offset buf
call writestring
call crlf
call crlf
mwrite "					       2:->"
invoke read_high_scr,offset sname,sizeof sname
mov edx,offset buf
call writestring
invoke read_high_scr,offset second,sizeof second
mwrite"	 "
mov edx,offset buf
call writestring
call crlf
call crlf
mwrite "					       3:->"
invoke read_high_scr,offset tname,sizeof tname
mov edx,offset buf
call writestring
invoke read_high_scr,offset third,sizeof third
mwrite"	 "
mov edx,offset buf
call writestring
call crlf
call crlf
ret
display_highscore endp
END main
