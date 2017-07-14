

;----------------------------------	 		 SISTEMAS EMBARCADOS I 2017/1             -------------------------------------
;---------------------------------- 	   ELEVADOR - MODELO ACRILICO VELHO            -------------------------------------
;
;
;										      DOUGLAS FUNAYAMA TAVARES
;											 GABRIEL GIORISATTO DE ANGELO
;											LUIZ OTAVIO GERHARDT FERNANDES
;
;
;										UNIVERSIDADE FEDERAL DO ESPIRITO SANTO
;										DEPARTAMENTO DE ENGENHARIA ELETRICA
;											       VITORIA - ES
;
;----------------------------------------------------------------------------------------------------------------------
;
;----------------------------------------------------------------------------------------------------------------------

;-------------------------------------------MACROS-------------------------------------------------------
%macro drawLine 5 		;x1,y1,x2,y2,color
	mov		ax,%1
	push	ax
	mov		ax,%2
	push	ax
	mov		ax,%3
	push	ax
	mov		ax,%4
	push	ax
	mov		byte[cor],%5
	call	line
%endmacro

%macro drawSquare 5 ; x1,x2,y1,y2,cor
	drawLine %1, %3, %2, %3, %5
	drawLine %1, %3, %1, %4, %5
	drawLine %1, %4, %2, %4, %5
	drawLine %2, %4, %2, %3, %5
%endmacro

%macro drawWord 4	;word,line,column,color
	mov	byte[cor], %4
	mov		bx,0
	mov		dh,%2		;line 0-29
	mov		dl,%3		;column 0-79
%%local:
	call	cursor
	mov		al,[bx+%1]
	cmp		al, '$'
	je		%%exit
	call	caracter
	inc		bx		;next char
	inc		dl		;next column
	jmp		%%local
%%exit:
%endmacro

%macro drawChar 4 ;char,line,column,color
	mov	byte[cor], %4
	mov		bx,0
	mov		dh,%2		;line 0-29
	mov		dl,%3		;column 0-79
	call	cursor
	mov		al,[bx+%1]
	call	caracter
%endmacro

;------------------------------------------INICIO DO CÓDIGO-------------------------------------------------------

segment code
..start:
    		mov 	ax,data
    		mov 	ds,ax
    		mov 	ax,stack
    		mov 	ss,ax
    		mov 	sp,stacktop

;Interrupcao
				xor     AX, AX
				mov     ES, AX
				mov     AX, [ES:int9*4];carregou AX com offset anterior
				mov     [offset_dos], AX        ; offset_dos guarda o end. para qual ip de int 9 estava apontando anteriormente
				mov     AX, [ES:int9*4+2]     ; cs_dos guarda o end. anterior de CS
				mov     [cs_dos], AX
				cli
				mov     [ES:int9*4+2], CS
				mov     WORD [ES:int9*4],keyint
				sti

; Salvar modo de video
        mov  	ah,0Fh
    		int  	10h
    		mov  	[modo_anterior],al

; Troca modo de v�deo para 640x480
			mov     al,12h
			mov     ah,0
			int     10h


			call tela_inicial
			call calibra
			call tela_elevador


			infinito:
			jmp infinito

			fimprograma:
			mov  	ah,0   						; set video mode
			mov  	al,byte[modo_anterior]   	; modo anterior
			int  	10h       					;salva modo de video
			mov     ah,4Ch
			cli
			xor     ax, ax
			mov     es, ax
			mov     ax, [cs_dos]
			mov     [es:int9*4+2], ax
			mov     ax, [offset_dos]
			mov     [es:int9*4], ax
			mov     AH, 4Ch
			int     21h


;-------------------------------------------FUNCOES----------------------------------------------------

	tela_inicial:
		;Margem
		drawSquare	10,630,10,470,branco_intenso
		drawSquare	11,629,11,469,branco_intenso
		drawSquare	12,628,12,468,branco_intenso
		drawSquare	13,627,13,467,branco_intenso
		;Mensagens da tela inicial
		drawWord		mens_calibrando,10,25,branco_intenso
		drawWord		mens_espaco,12,25,branco_intenso
		;Mensagens sair,titulo e nome dos integrantes do grupo
		drawWord		mens_sair,23,3,branco_intenso
		drawWord		mens_titulo,24,3,branco_intenso
		drawWord		mens_nome1,25,3,branco_intenso
		drawWord		mens_nome2,26,3,branco_intenso
		drawWord		mens_nome3,27,3,branco_intenso
		ret

	tela_elevador:
		;Limpa mensagens da tela inicial
		drawWord		mens_calibrando,10,25,preto
		drawWord		mens_espaco,12,25,preto
		;Mensagens andar atual,estado e modo do elevador
		drawWord		mens_andar,3,3,branco_intenso
		drawWord		mens_estado,4,3,branco_intenso
		drawWord		mens_modo,5,3,branco_intenso
		;Divisórias dos andares para chamadas internas
		drawSquare	390,490,360,460,branco_intenso
		drawSquare	390,490,257,357,branco_intenso
		drawSquare	390,490,154,254,branco_intenso
		drawSquare	390,490,51,151,branco_intenso
		drawSquare	390,490,10,50,branco_intenso
		drawWord		mens_chamadas,27,51,branco_intenso
		drawWord		mens_internas,28,51,branco_intenso
		;Divisórias dos andares para chamadas externas
		drawSquare	520,620,360,460,branco_intenso
		drawSquare	520,620,257,357,branco_intenso
		drawSquare	520,620,154,254,branco_intenso
		drawSquare	520,620,51,151,branco_intenso
		drawSquare	520,620,10,50,branco_intenso
		drawWord		mens_chamadas,27,67,branco_intenso
		drawWord		mens_externas,28,67,branco_intenso
		;Setinhas Chamada internas
		;Para baixo
		drawLine	440,450,440,370,branco_intenso
		drawLine	450,420,440,370,branco_intenso
		drawLine	430,420,440,370,branco_intenso
		;Para cima e para baixo
		drawLine	440,347,440,267,branco_intenso;var_seta dupla
		drawLine	450,297,440,267,branco_intenso
		drawLine	430,297,440,267,branco_intenso
		drawLine	440,347,450,307,branco_intenso
		drawLine	440,347,430,307,branco_intenso
		;Para cima e para baixo
		drawLine	440,244,440,164,branco_intenso;var_seta dupla
		drawLine	450,194,440,164,branco_intenso
		drawLine	430,194,440,164,branco_intenso
		drawLine	440,244,450,204,branco_intenso
		drawLine	440,244,430,204,branco_intenso
		;Para cima
		drawLine	440,140,440,60,branco_intenso
		drawLine	440,140,450,90,branco_intenso
		drawLine	440,140,430,90,branco_intenso
		;Setinhas Chamada externas
		;Para baixo
		drawLine	570,450,570,370,branco_intenso
		drawLine	580,420,570,370,branco_intenso
		drawLine	560,420,570,370,branco_intenso
		;Para cima e para baixo
		drawLine	550,347,550,267,branco_intenso;baixo
		drawLine	560,317,550,267,branco_intenso
		drawLine	540,317,550,267,branco_intenso
		drawLine	590,347,590,267,branco_intenso;cima
		drawLine	590,347,600,297,branco_intenso
		drawLine	590,347,580,297,branco_intenso
		;Para cima e para baixo
		drawLine	550,244,550,164,branco_intenso;baixo
		drawLine	560,214,550,164,branco_intenso
		drawLine	540,214,550,164,branco_intenso
		drawLine	590,244,590,164,branco_intenso;cima
		drawLine	590,244,600,194,branco_intenso
		drawLine	590,244,580,194,branco_intenso
		;Para cima
    drawLine	570,140,570,60,branco_intenso
		drawLine	570,140,580,90,branco_intenso
		drawLine	570,140,560,90,branco_intenso
		;

		drawChar	quatro,3,15,branco_intenso
		call estado_parado
		call modo_funcionando
		ret

		muda_andar:
		push ax
		add	ax,30h
		mov [andar],ax
		drawChar	andar,3,15,branco_intenso
		pop ax
		ret

		estado_parado:
		drawWord	buffer,4,22,preto
		drawWord	estado1,4,22,branco_intenso
		ret

		estado_subindo:
		drawWord	buffer,4,22,preto
		drawWord	estado2,4,22,verde
		ret

		estado_descendo:
		drawWord	buffer,4,22,preto
		drawWord	estado3,4,22,amarelo
		ret

		modo_funcionando:
		drawWord	buffer,5,20,preto
		drawWord	modo1,5,20,branco_intenso
		ret

		modo_emergencia:
		drawWord	buffer,5,20,preto
		drawWord	modo2,5,20,vermelho
		ret

		muda_cor_seta:		;;recebe em ax o numero da var_seta que terá a cor alterada e em bx a cor
		push ax
		push bx
		mov word[var_seta],ax
		mov byte[cor],bl
		cmp ax,4
		jne seta2
		drawLine	440,450,440,370,bl
		drawLine	450,420,440,370,bl
		drawLine	430,420,440,370,bl
		seta2:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,3
		jne seta3
		drawLine	440,347,440,267,bl
		drawLine	450,297,440,267,bl
		drawLine	430,297,440,267,bl
		drawLine	440,347,450,307,bl
		drawLine	440,347,430,307,bl
		seta3:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,2
		jne seta4
		drawLine	440,244,440,164,bl
		drawLine	450,194,440,164,bl
		drawLine	430,194,440,164,bl
		drawLine	440,244,450,204,bl
		drawLine	440,244,430,204,bl
		seta4:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,1
		jne seta5
		drawLine	440,140,440,60,bl
		drawLine	440,140,450,90,bl
		drawLine	440,140,430,90,bl
		seta5:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,10
		jne seta6
		drawLine	570,450,570,370,bl
		drawLine	580,420,570,370,bl
		drawLine	560,420,570,370,bl
		seta6:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,9
		jne seta7
		drawLine	550,347,550,267,bl
		drawLine	560,317,550,267,bl
		drawLine	540,317,550,267,bl
		seta7:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,8
		jne seta8
		drawLine	590,347,590,267,bl
		drawLine	590,347,600,297,bl
		drawLine	590,347,580,297,bl
		seta8:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,7
		jne seta9
		drawLine	550,244,550,164,bl
		drawLine	560,214,550,164,bl
		drawLine	540,214,550,164,bl
		seta9:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,6
		jne seta10
		drawLine	590,244,590,164,bl
		drawLine	590,244,600,194,bl
		drawLine	590,244,580,194,bl
		seta10:
		mov ax,word[var_seta]
		mov bl,byte[cor]
		cmp ax,5
		jne fim_mudacorseta
		drawLine	570,140,570,60,bl
		drawLine	570,140,580,90,bl
		drawLine	570,140,560,90,bl
		fim_mudacorseta:
		pop bx
		pop ax
		ret

		emergencia:
		mov		byte[bot_g],0
    mov 	byte[bot_emergencia],1
		call 	modo_emergencia		;chama a fun��o
		call estado_parado
		mov ax,0
		mov	[parado],ax
		;loopemergencia:
		;mov	ax,[bot_g]
		;cmp ax,1
		;jne loopemergencia
		;call modo_funcionando
		;mov 	byte[bot_emergencia],0
  ;  cmp 	byte[status],0             	;Verifica se ao acionar a Emerg�ncia o elevador estava parado
		;je 		emergencia_parado			;se estiver parado, segue para a funcao
	;	mov 	ax,word[contador]  			;Armazena a volta quando entrou na emergencia
		ret

		calibra:
				push ax
				push dx
				mov		dx,318h
				xor		al,al
				out		dx,al
				mov		dx,319h
				inc		al
				out		dx,al
				mov		dx,318h
				mov		al,01000000b
				out		dx,al
				apertaespaco:
				cmp		byte[tecla_u],39h				;Verifica se apertou espaco
				jne		apertaespaco
				mov   	word[contador_giros],267          ;3x89 = 267, que indica o quarto andar
				mov		dx,318h
				call conta_giros
				mov   	byte[parado],0              ;Elevador no quarto andar
				mov     dx,318H
				mov		al,00000000b							;Para o motor
				out		dx,al
				pop dx
				pop ax
				ret

		obtem_input:				;Obtem as entradas e faz debounce
				push ax
				push cx
				push dx
				mov		dx,319h
				debounce1:
				in		al,dx
				and		al,01111111b
				mov		ah,al
				in		al,dx
				and		al,01111111b
				cmp		al,ah
				jne		debounce1                    ;Fica em loop até o valor de duas entradas seguidas serem iguais
				mov		cx,40
				debounce2:
				in		al,dx
				and		al,01111111b
				cmp		al,ah
				jne		debounce1
				loop	debounce2                   ;Verifica se sao iguais
				mov		byte[entrada_atual],al
				pop dx
				pop cx
				pop ax
				ret

		conta_giros:
			push ax
			push bx
			mov  	ax,[parado]
			cmp   ax,0
			je		fim_contagiros			;Sai da funcao se o elevador esta parado
			call	obtem_input
			mov		bl,[entrada_atual]		;coloca em bl o valor da entrada atual
			and		bl,01000000b
			cmp		bl,0									;Verifica se o elevador esta num buraco
			jne		fim_contagiros
		buraco:
			call	obtem_input
			mov		bl,byte[entrada_atual]
			and		bl,01000000b
			cmp		bl,00000000b
			je		buraco
			cmp		byte[subindo],1
			jne		desce
			inc		word[contador_giros]     			;Se o elevador estiver subindo incrementa o contador de giros
			jmp		fim_contagiros
		desce:
			dec		word[contador_giros]	  			;Se o elevador estiver descendo decrementa o contador de giros
		fim_contagiros:
			pop bx
			pop ax
			ret

;-----------------------------------KEYINT----------------------------------------------------
keyint:
		push    ax
		push    bx
		push    ds
		mov     ax,data
		mov     ds,ax

		in      al,kb_data
		mov    	byte[tecla_u],al

		in      al,kb_ctl
		or      al,80h
		out     kb_ctl,al

		and     al,7Fh
		out     kb_ctl,al

		mov     al,eoi
		out     pictrl,al

		cmp		byte[tecla_u],02h
		jne		pressionou2
		mov 	byte[chamada_interna1],1
		mov ax,1
		mov bx,vermelho
		call muda_cor_seta
		pressionou2:
		cmp		byte[tecla_u],03h
		jne		pressionou3
		mov 	byte[chamada_interna2],1
		mov ax,2
		mov bx,vermelho
		call muda_cor_seta
		pressionou3:
		cmp		byte[tecla_u],04h
		jne		pressionou4
		mov 	byte[chamada_interna3],1
		mov ax,3
		mov bx,vermelho
		call muda_cor_seta
		pressionou4:
		cmp		byte[tecla_u],05h
		jne		pressionoug
		mov 	byte[chamada_interna4],1
		mov ax,4
		mov bx,vermelho
		call muda_cor_seta
		pressionoug:
		cmp		byte[tecla_u],22h
		jne 	pressionouq
		mov		byte[bot_g],1
		pressionouq:
		cmp		byte[tecla_u],10h
		jne 	pressionouesc
		call fimprograma
		pressionouesc:
		cmp		byte[tecla_u],01h
		jne	 fimkeyint
		call emergencia


		fimkeyint:
		pop     ds
		pop     bx
		pop     ax
		iret


;-----------------------------------FUNCOES GRAFICAS----------------------------------------------------
;
;   LINE
;
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
		push		bp
		mov		bp,sp
		pushf                        ;coloca os flags na pilha
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		mov		ax,[bp+10]   ; resgata os valores das coordenadas
		mov		bx,[bp+8]    ; resgata os valores das coordenadas
		mov		cx,[bp+6]    ; resgata os valores das coordenadas
		mov		dx,[bp+4]    ; resgata os valores das coordenadas
		cmp		ax,cx
		je		line2
		jb		line1
		xchg		ax,cx
		xchg		bx,dx
		jmp		line1
line2:		; deltax=0
		cmp		bx,dx  ;subtrai dx de bx
		jb		line3
		xchg		bx,dx        ;troca os valores de bx e dx entre eles
line3:	; dx > bx
		push		ax
		push		bx
		call 		plot_xy
		cmp		bx,dx
		jne		line31
		jmp		fim_line
line31:		inc		bx
		jmp		line3
;deltax <>0
line1:
; comparar m�dulos de deltax e deltay sabendo que cx>ax
	; cx > ax
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		ja		line32
		neg		dx
line32:
		mov		[deltay],dx
		pop		dx

		push		ax
		mov		ax,[deltax]
		cmp		ax,[deltay]
		pop		ax
		jb		line5

	; cx > ax e deltax>deltay
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx

		mov		si,ax
line4:
		push		ax
		push		dx
		push		si
		sub		si,ax	;(x-x1)
		mov		ax,[deltay]
		imul		si
		mov		si,[deltax]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar1
		add		ax,si
		adc		dx,0
		jmp		arc1
ar1:		sub		ax,si
		sbb		dx,0
arc1:
		idiv		word [deltax]
		add		ax,bx
		pop		si
		push		si
		push		ax
		call		plot_xy
		pop		dx
		pop		ax
		cmp		si,cx
		je		fim_line
		inc		si
		jmp		line4

line5:		cmp		bx,dx
		jb 		line7
		xchg		ax,cx
		xchg		bx,dx
line7:
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx



		mov		si,bx
line6:
		push		dx
		push		si
		push		ax
		sub		si,bx	;(y-y1)
		mov		ax,[deltax]
		imul		si
		mov		si,[deltay]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar2
		add		ax,si
		adc		dx,0
		jmp		arc2
ar2:		sub		ax,si
		sbb		dx,0
arc2:
		idiv		word [deltay]
		mov		di,ax
		pop		ax
		add		di,ax
		pop		si
		push		di
		push		si
		call		plot_xy
		pop		dx
		cmp		si,dx
		je		fim_line
		inc		si
		jmp		line6

fim_line:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		8

;----------------------------------------------------------------------------------------------------------------------------------
;   PLOT XY
;
; push x; push y; call plot_xy;  (x<639, y<479)
; cor definida na variavel cor
plot_xy:
		push		bp
		mov		bp,sp
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
	    mov     	ah,0ch
	    mov     	al,[cor]
	    mov     	bh,0
	    mov     	dx,479
		sub		dx,[bp+4]
	    mov     	cx,[bp+6]
	    int     	10h
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		4


;---------------------------------------------------------------------------------------------------------
; CURSOR
; dh = linha (0-29) e  dl = coluna  (0-79)
cursor:
			pushf
			push 	ax
			push 	bx
			push	cx
			push	dx
			push	si
			push	di
			push	bp
			mov     ah,2
			mov     bh,0
			int     10h
			pop		bp
			pop		di
			pop		si
			pop		dx
			pop		cx
			pop		bx
			pop		ax
			popf
			ret

;---------------------------------------------------------------------------------------------------------
;   Fun��o caracter escrito na posi��o do cursor
; al= caracter a ser escrito
; Cor definida na vari�vel cor
caracter:
			pushf
			push 	ax
			push 	bx
			push	cx
			push	dx
			push	si
			push	di
			push	bp
			mov     ah,9
			mov     bh,0
			mov     cx,1
			mov     bl,[cor]
			int     10h
			pop		bp
			pop		di
			pop		si
			pop		dx
			pop		cx
			pop		bx
			pop		ax
			popf
			ret

;----------------------------------------------------------------------------------------------------------------------------
;CIRCLE
;	 push xc; push yc; push r; call circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor
circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r

	mov 	dx,bx
	add		dx,cx       ;ponto extremo superior
	push    ax
	push	dx
	call plot_xy

	mov		dx,bx
	sub		dx,cx       ;ponto extremo inferior
	push    ax
	push	dx
	call plot_xy

	mov 	dx,ax
	add		dx,cx       ;ponto extremo direita
	push    dx
	push	bx
	call plot_xy

	mov		dx,ax
	sub		dx,cx       ;ponto extremo esquerda
	push    dx
	push	bx
	call plot_xy

	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y

;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante
;valores positivos para d

stay:				;loop
	mov		si,di
	cmp		si,0
	jg		inf       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar
inf:
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)

plotar:
	mov		si,dx
	add		si,ax
	push    si			;coloca a abcisa x+xc na pilha
	mov		si,cx
	add		si,bx
	push    si			;coloca a ordenada y+yc na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,dx
	push    si			;coloca a abcisa xc+x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do s�timo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc+x na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do oitavo octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	add		si,cx
	push    si			;coloca a ordenada yc+y na pilha
	call plot_xy		;toma conta do terceiro octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do sexto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quinto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quarto octante

	cmp		cx,dx
	jb		fim_circle  ;se cx (y) est� abaixo de dx (x), termina
	jmp		stay		;se cx (y) est� acima de dx (x), continua no loop


fim_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6



;-----------------------------------OUTRAS FUNCOES----------------------------------------------------

	delay:
	push cx
    mov cx, 1500; Carrega o valor 3 no registrador cx (contador para loop)  ;120
	del2:
		push cx; Coloca cx na pilha para usa-lo em outro loop
		mov cx, 0; Zera cx
	del1:
		loop del1; No loop del1, cx eh decrementado seguidamente ate que volte a ser zero
		pop cx; Recupera cx da pilha
		loop del2; No loop del2, cx eh decrementado seguidamente ate que seja zero
	pop cx
	ret
;*******************************************************************
segment data

;------------------------------------------- linec ------------------------------------------------------
cor							db		branco_intenso
preto						equ		0
azul						equ		1
verde						equ		2
cyan						equ		3
vermelho				equ		4
magenta					equ		5
marrom					equ		6
branco					equ		7
cinza						equ		8
azul_claro			equ		9
verde_claro			equ		10
cyan_claro			equ		11
rosa						equ		12
magenta_claro		equ		13
amarelo					equ		14
branco_intenso	equ		15
modo_anterior		db		0
linha						dw		0
coluna					dw		0
deltax					dw		0
deltay					dw		0

;------------------------------------------- tecbuf ------------------------------------------------------

kb_data 			equ 	60h		; PORTA DE LEITURA DE TECLADO
kb_ctl  			equ 	61h		; PORTA DE RESET PARA PEDIR NOVA INTERRUPCAO
pictrl  			equ 	20h
eoi     			equ 	20h
int9    			equ 	9h
cs_dos  			dw  	1
offset_dos  	dw 		1
tecla_u 			db 		0
tecla   			resb	8
p_i     			dw  	0			; ponteiro p/ interrupcao (qnd pressiona tecla)
p_t     			dw  	0			; ponterio p/ interrupcao (qnd solta tecla)
teclasc 			db  	0,0,13,10,'$'
;----------------------------------------------------------------------------------------------------------------------

mens_calibrando	db		'Calibrando...$'
mens_espaco			db		'Aperte ESPACO no quarto andar.$'
mens_sair				db		'Pressione Q para sair do programa$'
mens_titulo			db		'Projeto Final de Sistemas Embarcados 2017-1$'
mens_nome1			db		'Douglas Funayama Tavares$'
mens_nome2			db		'Gabriel Giorisatto de Angelo$'
mens_nome3			db		'Luiz Otavio Gerhardt Fernandes$'
mens_andar			db		'Andar atual: $'
mens_estado			db		'Estado do elevador: $'
mens_modo				db		'Modo de operacao: $'
mens_chamadas		db		'Chamadas$'
mens_internas		db		'INTERNAS$'
mens_externas		db		'EXTERNAS$'
var_seta				dw		0
buffer					db		'                   $'
estado1					db		'Parado$'
estado2					db		'Subindo$'
estado3					db		'Descendo$'
modo1						db		'Funcionando$'
modo2						db		'EMERGENCIA!!!$'
andar						db		'0'
um							db		'1'
dois						db		'2'
tres						db		'3'
quatro					db		'4'
chamada_interna1	db		'0'
chamada_interna2	db		'0'
chamada_interna3	db		'0'
chamada_interna4	db		'0'
parado						db		'0'
subindo						db		'0'
bot_emergencia		db		'0'
bot_g							db		'0'
contador_giros		db		'0'
entrada_atual			db		'0'

;*************************************************************************
segment stack stack
resb 		512
stacktop:
