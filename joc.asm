.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "BOMBERMAN",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include bomberman.inc


button_x_w EQU 490
button_y_w EQU 280
button_size EQU 45

button_x_s EQU 490
button_y_s EQU 325

button_x_d EQU 535
button_y_d EQU 325

button_x_a EQU 445
button_y_a EQU 325

matrix dd 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	   dd 1,4,4,1,4,4,4,4,4,4,1,4,1,4,1
	   dd 1,4,4,1,4,4,4,4,4,4,2,2,4,4,1
	   dd 1,4,2,4,1,1,4,1,4,4,4,4,4,2,1
	   dd 1,4,4,4,4,4,4,4,1,1,4,4,4,4,1
	   dd 1,4,2,4,1,1,2,4,4,4,1,4,2,4,1
	   dd 1,4,4,4,1,4,4,2,4,4,4,1,2,4,1
	   dd 1,4,4,4,4,4,4,4,4,4,1,1,4,4,1
	   dd 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	   
lungime_matrice EQU 15
inaltime_matrice EQU 9

y dd 0
x dd 0

coord_i_player dd 1			; asta e calculatul si miscarea 		i si j
coord_j_player dd 1


coord_x_player dd 0					;x si y sunt pe afisast 					x si y
coord_y_player dd 0



adresa_omulet dd 0



.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_negru
	mov dword ptr [edi], 0FFFFFFh			;cul alb la scris
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0				;fundal la scris negru
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x,y,len,color
local bucla_line
	mov eax, y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
bucla_line:
	mov dword ptr [eax],color
	add eax,4
	loop bucla_line
endm

line_vertical macro x,y,len,color
local bucla_line
	mov eax, y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
bucla_line:
	mov dword ptr [eax],color
	add eax,4*area_width
	loop bucla_line
endm

show_symbol proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	lea esi,bomberman
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_negru
	cmp byte ptr [esi], 1
	je simbol_pixel_alb
	cmp byte ptr [esi], 2
	je simbol_pixel_gri
	cmp byte ptr [esi], 3
	je simbol_pixel_rosu
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0					;fundal la scris negru
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh					
	jmp simbol_pixel_next
simbol_pixel_gri:
	mov dword ptr [edi], 0808080h				
	jmp simbol_pixel_next
simbol_pixel_rosu:
	mov dword ptr [edi], 0FF0000h				
	jmp simbol_pixel_next
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
	show_symbol endp
	
afisare_simbol_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call show_symbol
	add esp, 16
endm	
	
parcurgere_matrice macro
local for_1
local for_2
mov edx, inaltime_matrice
mov y,20
lea ebp,matrix					
for_1:
add y,20					;inaltimea e 20
mov x,40
mov ecx,lungime_matrice				
for_2:
add x,10					;lungimea e 10
afisare_simbol_macro [ebp],area,x,y
add ebp,4
loop for_2
dec edx
cmp edx,0
jne for_1

endm

adresa macro 					;calculez miscarea in matrice cu adresa	
mov ecx,symbol_height
mov eax, coord_j_player
mul ecx
mov ecx,symbol_width
add eax,40
mov coord_y_player,eax
mov eax,coord_i_player
mul ecx
add eax,50
mov coord_x_player,eax
endm

adresa_in_matrice macro		;le pun in matrice
mov ecx,lungime_matrice
mov eax,coord_j_player
mul ecx
add eax,coord_i_player
shl eax,2
mov adresa_omulet,eax
endm




; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2 
	push eax
	push 0					;background negru 
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
								;cand apesi pe w
	mov eax,[ebp+arg2]
	cmp eax,button_x_w
	jl incearca_jos
	cmp eax, button_x_w+button_size
	jg incearca_jos 
	mov eax,[ebp+arg3]
	cmp eax,button_y_w
	jl incearca_jos 
	cmp eax,button_y_w+button_size
	jg incearca_jos
	jmp miscare_sus
	
	
	
	
								;cand apesi pe s
	incearca_jos:
	mov eax,[ebp+arg2]
	cmp eax,button_x_s
	jl incearca_stanga 
	cmp eax, button_x_s+button_size
	jg incearca_stanga 
	mov eax,[ebp+arg3]
	cmp eax,button_y_s
	jl incearca_stanga 
	cmp eax,button_y_s+button_size
	jg incearca_stanga
	jmp miscare_jos
	
	
	
								;cand apesi pe a
	incearca_stanga:
	mov eax,[ebp+arg2]
	cmp eax,button_x_a
	jl incearca_dreapta 
	cmp eax, button_x_a+button_size
	jg incearca_dreapta 
	mov eax,[ebp+arg3]
	cmp eax,button_y_a
	jl incearca_dreapta 
	cmp eax,button_y_a+button_size
	jg incearca_dreapta	
	jmp miscare_stanga
	
	
								;cand apesi pe d
	incearca_dreapta:
	mov eax,[ebp+arg2]
	cmp eax,button_x_d
	jl button_fail 
	cmp eax, button_x_d+button_size
	jg button_fail 
	mov eax,[ebp+arg3]
	cmp eax,button_y_d
	jl button_fail 
	cmp eax,button_y_d+button_size
	jg button_fail
	jmp miscare_dreapta
	
	
	miscare_sus:
	adresa
	adresa_in_matrice
	lea eax,matrix
	add eax,adresa_omulet
	mov ecx,[eax-4*lungime_matrice]
	cmp ecx,1
	je evt_timer
	cmp ecx,2
	je evt_timer
	lea eax,matrix
	add eax,adresa_omulet
	mov ebx,[eax-4*lungime_matrice]
	mov ebx,[eax]
	cmp ebx,1
	je afisare_litere
	cmp ebx,2
	je afisare_litere
	dec coord_j_player
	jmp afisare_litere
	
	miscare_jos:
	adresa
	adresa_in_matrice
	lea eax,matrix
	add eax,adresa_omulet
	mov ecx,[eax+4*lungime_matrice]
	cmp ecx,1
	je evt_timer
	cmp ecx,2
	je evt_timer
	lea eax,matrix
	add eax,adresa_omulet
	mov ebx,[eax+4*lungime_matrice]
	mov ecx,[eax]
	cmp ebx,1
	je afisare_litere
	cmp ebx,2
	je afisare_litere
	inc coord_j_player
	jmp afisare_litere
	
	miscare_stanga:
	adresa
	adresa_in_matrice
	lea eax,matrix
	add eax,adresa_omulet
	mov edx,[eax-4]
	cmp edx,1
	je evt_timer
	cmp edx,2
	je evt_timer
	lea eax,matrix
	add eax,adresa_omulet
	mov ecx,[eax-4]
	mov edx,[eax]
	cmp ecx,1
	je afisare_litere
	cmp ecx,2
	je afisare_litere
	dec coord_i_player
	jmp afisare_litere
	
	miscare_dreapta:
	adresa
	adresa_in_matrice
	lea eax,matrix
	add eax,adresa_omulet
	mov ecx,[eax+4]
	cmp ecx,1
	je evt_timer
	cmp ecx,2
	je evt_timer
	lea eax,matrix
	add eax,adresa_omulet
	mov ebx,[eax+4]
	mov ecx,[eax]
	cmp ebx,1
	je afisare_litere
	cmp ebx,2
	je afisare_litere
	inc coord_i_player
	jmp afisare_litere
	 
	
	
	
button_fail:
	;jmp afisare_litere
	
evt_timer:
	; inc counter
	; parcurgere_matrice
	adresa
	adresa_in_matrice
	parcurgere_matrice
	afisare_simbol_macro 0,area,coord_x_player,coord_y_player
	
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 80, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 70, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 60, 10
	
	;scriem un mesaj
	make_text_macro 'T', area, 10, 10			;timpul
	make_text_macro 'I', area, 20, 10
	make_text_macro 'M', area, 30, 10
	make_text_macro 'E', area, 40, 10
	
	make_text_macro 'S', area, 110, 10
	make_text_macro 'C', area, 120, 10
	make_text_macro 'O', area, 130, 10
	make_text_macro 'R', area, 140, 10
	make_text_macro 'E', area, 150, 10
												;afisarea scorului
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 170, 10
	
	
	line_horizontal button_x_w,button_y_w,button_size,0FF0000h				;butonul de w
	line_horizontal button_x_w,button_y_w+button_size,button_size,0FF0000h
	line_vertical button_x_w,button_y_w,button_size,0FF0000h
	line_vertical button_x_w + button_size,button_y_w,button_size,0FF0000h	
	make_text_macro 'W', area, 508, 292
	
	line_horizontal button_x_s,button_y_s,button_size,0FF0000h				;butonul de s
	line_horizontal button_x_s,button_y_s+button_size,button_size,0FF0000h
	line_vertical button_x_s,button_y_s,button_size,0FF0000h
	line_vertical button_x_s + button_size,button_y_s,button_size,0FF0000h
	make_text_macro 'S', area, 508, 335
	
	line_horizontal button_x_d,button_y_d,button_size,0FF0000h				;butonul de d
	line_horizontal button_x_d,button_y_d+button_size,button_size,0FF0000h
	line_vertical button_x_d,button_y_d,button_size,0FF0000h
	line_vertical button_x_d + button_size,button_y_d,button_size,0FF0000h
	make_text_macro 'D', area, 552, 335
	
	line_horizontal button_x_a,button_y_a,button_size,0FF0000h				;butonul de a
	line_horizontal button_x_a,button_y_a+button_size,button_size,0FF0000h
	line_vertical button_x_a,button_y_a,button_size,0FF0000h
	line_vertical button_x_a + button_size,button_y_a,button_size,0FF0000h
	make_text_macro 'A', area, 463, 335
	
	

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
