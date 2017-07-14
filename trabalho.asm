
;----------------------------------------- SISTEMAS EMBARCADOS I 2013/2 -----------------------------------------------
;---------------------------------- PROJETO DE ELEVADOR (Modelo Acrílico Antigo) ------------------------------------------------
;     GRUPO: Aline Cristina Dias de Oliveira 
;			 Michiel Laranja Bassul 
;            Thiago Valfré Lecchi 

;----------------------------------------------------------------------------------------------------------------------
;      												INICIALIZAÇÕES
;----------------------------------------------------------------------------------------------------------------------

segment code
..start:
    		mov 	ax,data
    		mov 	ds,ax
    		mov 	ax,stack
    		mov 	ss,ax
    		mov 	sp,stacktop
	
; Salvar modo de video
            mov  	ah,0Fh 				;Comando para salvar modo de vídeo
    		int  	10h 				;Interrupção para salvar modo de vídeo
    		mov  	[modo_anterior],al   ; salva modo de video atual no anterior

; Moda modo de vídeo para 640x480 (16 cores)
			mov     al,12h   ; alterna o modo de video
			mov     ah,0
			int     10h	
				
; Interupção do teclado   ; teck both
			xor		ax,ax
		    mov		es,ax
		    mov     ax,[es:int9*4]				;Carregou AX com offset anterior
		    mov     [offset_dos],ax        		;offset_dos guarda o end. para qual ip de int 9 estava apontando anteriormente
		    mov     ax,[es:int9*4+2]     		
		    mov     [cs_dos],ax					;cs_dos guarda o endereço anterior de CS

; Tabela de interupção
		    cli     
		    mov     [es:int9*4+2],cs         ; ponteiro
		    mov     word[es:int9*4],keyint  ;interrupção esta nesse endereço de memoria
		    sti		
;----------------------------------------------------------------------------------------------------------------------
			
;-------------------------------------------- Programa ----------------------------------------------------------------

			call	mov_inicial					;Manda o elevador subir para a posição inicial de funcionamento = 4º Andar
			call  	mensagem_fixa 				;Chamar a interface fixa 
infinito:         			
			cmp 	byte[tecla_u],90h           ;Loop que verifica se "Q" = Sair do Programa foi clicado
			jne 	j76							;vai para a outra função
			jmp 	sair_programa				;caso apertado, sai do programa
j76:  
			cmp 	byte[tecla_u],01h        	;Verifica como/quando foi apertado o botão ESC de Emergência
			jne 	fim_emergencia				;se nao foi apertado, vai para o fim_emergencia
			jmp 	emergencia					;caso apertado, vai para emergencia 
		
fim_emergencia:	
			call 	verifica_botao				; obter os botoes externos e ajustar suas flags
			call  	verifica_tecla        		; obter as teclas e ajustar suas flags
			call 	acende_led             		; acender os leds dos andares pendentes
            call 	verifica_andar   			; saber em qual andar o elevador está
			call 	interface_status
			call 	interface_interna
			call 	interface_andar
			call 	interface_externa
			call 	decide           			; decidir o que o elevador deve fazer
			jmp     infinito

emergencia:
            mov 	byte[status_emergencia],1 	;Status para imprimir mensagem de EMERGÊNCIA na tela
			call 	interface_emergencia		;chama a função
            cmp 	byte[status],0             	;Verifica se ao acionar a Emergência o elevador estava parado
			je 		emergencia_parado			;se estiver parado, segue para a funcao
			mov 	ax,word[contador]  			;Armazena a volta quando entrou na emergencia

espera_volta:	
			call 	conta_volta
			cmp 	ax,word[contador] 			;Olhar se ainda estou na mesma volta
			je 		espera_volta 				; verificar se ainda está na mesma volta(motor só para depois de completar a volta atual)//nao gera acúmulo de erro//

emergencia_parado:			
			mov 	dx,318h						;coloca a saida em dx
			mov 	bl,byte[pendentes]			;coloca em bl as ações pendentes
			mov 	al,0						;zera al
			or 		al,bl						
			out 	dx,al           			;Motor parado sem alterar condição dos leds
			cmp 	byte[tecla_u],81h			; compara tecla esc
			jne 	emergencia_parado       	;Espera soltar a tecla esc
			mov 	byte[tecla_u],0         	;Zero o valor 81h que estava salva em tecla_u

espera_soltar:		
			cmp 	byte[tecla_u],81h        	;Espera clicar de novo na tecla ESC para liberar o programa novamente
			jne 	espera_soltar
			mov 	al,byte[status]				;coloca em al o status
			mov 	bl,byte[pendentes]			;coloca em bl os comandos pendentes
			or 		al,bl						; porta ou
			mov 	dx,318h						;coloca a saida em dx
			out 	dx,al						; al em dx
			mov 	byte[status_emergencia],0	;zera o status de emergencia
			call 	interface_emergencia		;chama a interface emergencia printando de preto a palavra
			jmp 	fim_emergencia

sair_programa:
			mov 	dx,318h						;coloca em dx a saida
			mov 	ax,0						;zera ax
			out 	dx,ax  						; zerar a porta 318 H (apaga os leds e desliga o motor)
			
			mov 	dx,319h						;coloca em dx a entrada
			mov 	al,1						
			out 	dx,al   					; apaga o led de porta aberta
			
			mov  	ah,0   						; set video mode
			mov  	al,byte[modo_anterior]   	; modo anterior
			int  	10h                         ;salva modo de video
			
			cli           						; limpar a interupção
			xor     ax,ax
			mov     es,ax
			mov     ax,[cs_dos]
			mov     [es:int9*4+2], AX
			mov     ax,[offset_dos]
			mov     [es:int9*4], AX 
			mov     ah,4Ch
			int     21h       					; finaliza o programa
;----------------------------------------------------------------------------------------------------------------------

;______________________________________________________________________________________________________________________			
;________________________________________________ Funções _____________________________________________________________	

;--------------------------------------- POSIÇÃO INICIAL - 4º ANDAR ------------------------------------------------			

mov_inicial: 									;Rotina que ajusta corretamente o elevador no 4º Andar
			pusha
			pushf
			call 	mensagem_inicial			;funcao da que possui a mensagem iniciall vista 
			call 	interface_predio			;interface do predio mostrada na tela
			mov		dx,318h      				;move para dx a saida 
			xor		al,al						;Zera AL
			out		dx,al	                    ;Faz a porta 318H receber 0
			mov		dx,319h						;move para dx a entrada
			inc		al							;Apaga o LED da porta 319H e define a porta 318H como porta de saída
			out		dx,al						;al passa par dx
			mov		dx,318h						;move a saida para dx 	
			mov		al,01000000b                ;Comando que manda o elevador SUBIR
			out		dx,al						;comanda a saida	
 
L2:
			cmp		byte[tecla_u],99h			;Compara com a tecla "P" que indica o elevador no 4º Andar. P foi lido em "keyint" 
			jne		L2							;Looping infinito até entrar a letra P
			mov   	word[contador],267          ;Contador de giros no máximo para levar o elevador todo pra cima
			mov		dx,318h						;coloca a saida em dx	
			mov		al,10000000b                ;Estando no 4º Andar, ele terá de descer
			out		dx,al						;coloca na saida o movimento descer
			mov 	byte[status],10000000b	    ;Status "DESCENDO"
			
L3:
			call    conta_volta                 ;Função para contar as voltas do sensor
			cmp 	word[contador],264          ;Espera o elevador voltar tres voltas do sensor
			jne   	L3							;continua na funcao ate atingir 264 voltas

parar:
			mov   	word[contador],267          ;Novo parâmetro de altura máxima (foi implementado devido ao erro de travamento do sensor no teto do 4º andar)
			mov   	byte[status],0              ;Status "parado" - Elevador na posição certa no 4º Andar
			mov     dx,318H						;coloca a saida em dx
			mov		al,00000000b				;zera al	
			out		dx,al			            ;Manda uma sinal para 318H mandar parar o motor
			popf
			popa
			ret
;----------------------------------------------------------------------------------------------------------------------
		
;-------------------------------------------- Interupção do teclado ---------------------------------------------------	

keyint:
			push    ax							; A porta 60h é a porta de entrada do teclado, 
			push    bx							;as informações do que foi apertado vão pra essa porta
			push    ds
			mov     ax,data
			mov     ds,ax
			
			in      al,kb_data					; Le a porta 60h(teclado)
			mov    	byte[tecla_u],al  			; salva em tecla_u valor lido pelo interupção
			inc     word[p_i]
			and     word[p_i],7
			mov     bx,[p_i]
			mov     [bx+tecla],al

			in      al,kb_ctl					; Le a porta 61h(configuração reset, prepara para nova interrupção)
			or      al,80h						; Seta o bit 7 de AL
			out     kb_ctl,al					; Imprime em 61h - AL or 1000 0000
			
			and     al,7Fh						; Limpa o bit 7 de AL
			out     kb_ctl,al					; Imprime em 61h - AL and 0111 1111
			
			mov     al,eoi                      ; valor 20h
			out     pictrl,al					; Imprime em 20h - 0010 0000
			
			pop     ds
			pop     bx
			pop     ax
			iret
;----------------------------------------------------------------------------------------------------------------------

;------------------------------ Função para obter as entradas já tratando o debounce ----------------------------------

entrada:   
			pushf
			pusha
			mov		dx,319h						;coloca a entrada em dx
l_dbce1:
			in		al,dx						;passa dx para al
			and		al,01111111b				;Seta o bit mais significativo em 0
			mov		ah,al						;
			in		al,dx                       ;
			and		al,01111111b				;seta o bit mais significativo em 0	
			cmp		al,ah
			jne		l_dbce1                     ;Fica no loop até o valor de duas entradas seguidas serem iguais
			mov		cx,30						;define o loop
l_dbce2:	
			in		al,dx
			and		al,01111111b				;Seta o bit mais significativo em 0
			cmp		al,ah
			jne		l_dbce1                                 
			loop	l_dbce2                     ;Verifica 30 vezes se as entradas são iguais (dentro do loop)
			mov		byte[entrada_atual],al		;coloca na entrada atual o valor de al
			
			popa
			popf
			ret
;---------------------------------------------------------------------------------------------------------------------

;-------------------------------------- Função para contar o numero de voltas ----------------------------------------

conta_volta:
			pushf
			pusha
			cmp     byte[status],0        		;Não conta volta se o elevador estiver parado
			je      sair_conta_volta			;se estiver parado, sai da rotina
			call    entrada               		;Pega todoas as entradas já com debounce
			mov		bl,byte[entrada_atual]		;coloca em bl o valor da entrada atual	
			and		bl,01000000b				;Para verificar o bit do sensor
			cmp		bl,00000000b				;Sensor = 0, 'buraco'
			jne		sair_conta_volta			;sendo igual, entra na função "buraco"
buraco:	
			call	entrada						;chama as entradas com o debounce
			mov		bl,byte[entrada_atual]		;coloca em bl a entrada atual	
			and		bl,01000000b				;verifica o bit do sensor
			cmp		bl,00000000b				;compara se esta no "buraco"		
			je		buraco						;verifica se saiu do 'buraco'
			cmp 	byte[status],01000000b  	;verifica se esta subindo
			jne     el_descendo					;observa se o mesmo esta descendo	
			inc     word[contador]     			;contagem deve ser feita incrementando o contador caso esteja subindo
			jmp 	sair_conta_volta			;sai da rotina
el_descendo:
			dec   	word[contador]	  			; contagem deve ser feita decrementando o contador caso esteja descendo
sair_conta_volta:	
			popa
			popf
			ret
;----------------------------------------------------------------------------------------------------------------------

;----------------------------- Função para verificar se algum botão externo foi apertado ------------------------------

verifica_botao:
			pusha
			pushf
			call 	entrada   					;chama a funcao entrada
			mov 	al, byte[entrada_atual]		;coloca em al a entrada atual
			and 	al,00000001b				
			cmp 	al,00000001b      			; verifica se o botão B1 foi apertado
			jne 	Botão_B2					; caso contrario, vai para B2 direto
			mov 	byte[B1],1					; seta B1
  
Botão_B2:  
			mov 	al, byte[entrada_atual]		;coloca a entrada atual em al
			and 	al,00001000b				
			cmp 	al,00001000b    			; verifica se o botão B2 foi apertado
			jne 	Botão_B3					; caso contrario, vai para B3
			mov 	byte[B2],1 
  
Botão_B3:	
			mov 	al, byte[entrada_atual]
			and 	al,00000010b
			cmp 	al,00000010b     			; verifica se o botão B3 foi apertado
			jne 	Botão_B4
			mov 	byte[B3],1  
			
Botão_B4:
			mov 	al, byte[entrada_atual]
			and 	al,00010000b
			cmp 	al,00010000b     			; verifica se o botão B4 foi apertado
			jne 	Botão_B5
			mov 	byte[B4],1  
    
Botão_B5:	
			mov 	al, byte[entrada_atual]
			and 	al,00000100b
			cmp 	al,00000100b      			; verifica se o botão B5 foi apertado
			jne 	Botão_B6
			mov 	byte[B5],1   
		   
Botão_B6:	
			mov 	al, byte[entrada_atual]
			and 	al,00100000b
			cmp 	al,00100000b    			; verifica se o botão B6 foi apertado
			jne 	sem_botoes
			mov 	byte[B6],1 
    	
sem_botoes:
			popf
			popa
			ret
;----------------------------------------------------------------------------------------------------------------------

;------------------------------- Função para verifica se alguma tecla foi apertada ------------------------------------

verifica_tecla:
			pushf
			pusha
			cmp		byte[tecla_u],02h			; 1° andar
			jne		ver_tecla2					;caso nao seja igual, vai para a segunda tecla
			mov 	byte[tecla_1],1				;seta a tecla 1
ver_tecla2:		
			cmp		byte[tecla_u],03h			; 2° andar
			jne		ver_tecla_03				;mesmo procedimento que no anterior
			mov    	byte[tecla_2],1
ver_tecla_03:		
			cmp		byte[tecla_u],04h			; 3° andar
			jne		ver_tecla_04
			mov    	byte[tecla_3],1
ver_tecla_04:		 
			cmp		byte[tecla_u],05h			; 4° andar
			jne		gerar_tecla_pendente
			mov    	byte[tecla_4],1
gerar_tecla_pendente:	
			mov 	ax,0						;zera ax
			cmp 	byte[tecla_4],1             ;verifica se tecla 4 esta setada   
			jne 	verificar_tecla3			;se nao estiver, vai para a tecla 3
			inc 	al							; se estiver, incrementa al
verificar_tecla3:			
			shl 	al,1                        ;desloca al        	
			cmp 	byte[tecla_3],1				;verifica se a tecla 3 esta apertada
			jne 	verificar_tecla2			;se nao estiver, vai para a tecla 2
			inc 	al							; se estiver , incrementa al
verificar_tecla2:			
			shl 	al,1						;desloca al
			cmp 	byte[tecla_2],1				; mesmo procedimento que nos anteriores
			jne 	verificar_tecla1
			inc 	al				
verificar_tecla1:			
			shl 	al,1
			cmp 	byte[tecla_1],1
			jne 	sair_tecla
			inc 	al
sair_tecla:
			mov 	byte[tecla_pendente],al    	; tecla pendente tem as flags das teclas nos bits 4,3,2 e 1, respectivamente
			popa
			popf
			ret
;----------------------------------------------------------------------------------------------------------------------

;------------------------------- Função para verificar qual o andar o elevador está ----------------------------------- 

verifica_andar:
            pusha
			pushf
            call    conta_volta              	; função para contar as voltas do sensor
	        cmp		word[contador],267 			;numero de voltas maxima = 4º andar
            jne   	terceiro_andar				;caso contrario, verifica se esta no terceiro andar
            mov   	byte[andar],4				;seta o "andar" com o 4
terceiro_andar:
            cmp 	word[contador],178			;numero de voltas para o terceiro andar
			jne 	segundo_andar				;como nos procedimento anterior
            mov  	byte[andar],3
segundo_andar:
            cmp 	word[contador],89			;numero de voltas para o segundo andar
			jne 	primeiro_andar
            mov  	byte[andar],2
primeiro_andar
            cmp 	word[contador],0			;numero de voltas para o primeiro andar
			jne 	exit
            mov  	byte[andar],1
exit:
            popf
			popa			
			ret  
;----------------------------------------------------------------------------------------------------------------------

;------------------------------ Acendes os LED's e mantem o status do motor -------------------------------------------

acende_led:
			pusha
			pushf
			mov 	ax,0						;zera ax
			mov 	bx,0						;zera bx
			mov 	bl,byte[B6]   				; verifica se B6 está pendente
			cmp 	bl,1						;observa se B6 foi setado
			jne 	A							;se nao foi, vai para a funcao a 
			inc 	al           				; se estiver, salva a posição do led L6 inicialmente no bit 0
A:
			shl 	al,1         				; desloca a posição para esquerda ( apos 5 deslocamentos o led L6, que estava no bit0, vai estar no bit5)
			mov 	bl,byte[B4]   				; verifica se B4 esta pendente ( B4 deve ser o bit 4 ao final da função)
			cmp 	bl,1						;observa se b4 foi setado
			jne 	B							;caso nao tenha sido, vai para a funcao b
			inc 	al							; caso tenha, incrementa al
B:	 
			shl 	al,1						; desloca para a esquerda ( no final, estara no bit 4 )
			mov 	bl,byte[B2]					;mesmo procedimento que nos anteriores
			cmp 	bl,1
			jne 	C
			inc 	al 
C:
			shl 	al,1					
			mov 	bl,byte[B5]
			cmp 	bl,1
			jne 	D
			inc 	al	
D:
			shl 	al,1
			mov 	bl,byte[B3]
			cmp 	bl,1
			jne 	E
			inc 	al	
E:
			shl 	al,1
			mov 	bl,byte[B1]
			cmp 	bl,1
			jne 	F
			inc 	al	
F:
			mov 	dx,318h						; dx recebe a saida 
			mov 	byte[pendentes],al			;coloca em pendentes as condicoes dos botoes
			mov 	bl,byte[status]				;bl recebe o status
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al		  				; acende os leds pendentes e mantem o status do motor (parado,descendo ou subindo)
			popf
			popa
			ret
;----------------------------------------------------------------------------------------------------------------------

;-------------------------------------- Função para abrir a porta -----------------------------------------------------

porta:  
			pushf
			pusha
			mov 	word[delay],0
			mov		dx,319h
			mov		al,00000000b
			out		dx,al						; acende o led que indica a porta aberta
			
espera:
			inc 	word[delay]
			cmp 	word[delay],0x3fff
			je 		passou
			call 	verifica_botao
			call 	acende_led
			call 	interface_externa
			call 	verifica_tecla
			call 	interface_interna
			cmp 	byte[tecla_u],01h
			jne 	espera
			jmp 	emergencia_porta
emergencia_porta:	
            mov 	byte[status_emergencia],1
			call 	interface_emergencia    
			cmp 	byte[tecla_u],81h
			jne 	emergencia_porta
			mov 	byte[tecla_u],0
espera_emergencia_porta:		
			cmp 	byte[tecla_u],81h
			jne 	espera_emergencia_porta
			mov 	byte[status_emergencia],0
			call 	interface_emergencia
		    jmp 	espera

passou:
			mov		al,00000001b
			mov     dx,319h
			out		dx,al						; apaga o led indicando porta fechada
			popa
			popf
			ret
;----------------------------------------------------------------------------------------------------------------------

;------------------------------ Função para decidir o que fazer com o elevador ----------------------------------------

decide:
		    push 	ax
			push 	bx
			push 	cx
			pushf
			mov		ax,0
			mov 	al,byte[status]   			; inicialmente verifica qual o status do elevador
			cmp 	al,0
			je 		elv_parado
			cmp 	al,01000000b
			jne 	j1
			jmp 	elv_subindo
j1:  
			jmp 	elv_descendo
elv_parado:
			mov 	al,byte[andar]   			; segunda verificação é com relação ao andar que o elevador está
			cmp 	al,4
			je 		p4
			cmp 	al,3
			jne 	j2
			jmp 	p3
j2:	
			cmp 	al,2
			jne 	j3
			jmp 	p2
j3:		
			jmp 	p1
p4:
			cmp 	byte[B6],1  				; terceira verificação é com relação aos botões
			je 		abrir_porta4
			cmp 	byte[tecla_4],1
			jne 	j26 
			jmp 	abrir_porta_tecla4
j26 :	   
		    mov 	al,byte[pendentes]
		    and 	al,00011111b 				; verificar se tem botao abaixo apertado
		    cmp 	al,0
		    ja  	mandar_descer  				; qualquer botao abaixo manda o elevador descer
		    mov 	al,byte[tecla_pendente]
		    and 	al,00000111b
		    cmp 	al,0
		    ja 		mandar_descer
		    jmp 	exit_decide	   

abrir_porta4:
			call 	porta  	   					; função para abrir a porta
			mov 	byte[B6],0   				; botao foi atendido
			cmp 	byte[tecla_4],1
			jne 	j27
			mov 	byte[tecla_4],0
j27:   
			jmp 	exit_decide	   
mandar_descer:	
			mov 	byte[status],10000000b 		; indica o elevador deve descer ( função acende led vai dar o out na porta e mandar descer)
			jmp 	exit_decide
elv_descendo:
			mov 	al,byte[andar]
			cmp 	al,4
			jne 	j4
			jmp 	exit_decide
j4:	
			cmp 	al,3
			je 		d3		
        
			cmp 	al,2
			jne  	d1
			jmp 	d2
d1:		
			cmp 	byte[B1],1
			je  	j5
			cmp 	byte[tecla_1],1
			jne 	j41
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[tecla_1],0
j41:	
			jmp 	exit_decide
j5:	
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B1],0
			cmp 	byte[tecla_1],1
			jne 	j42 
			mov 	byte[tecla_1],0
j42:	 
			jmp 	exit_decide
d3:
			cmp 	byte[B4],1
			jne 	j13
			jmp 	j6
j13:	
			cmp 	byte[tecla_3],1
			jne 	j68
			jmp 	abrir_porta_tecla_3_d_3
j68:
			mov 	al,byte[pendentes]
			and 	al,00001011b
			cmp 	al,0
			je 		j43
			jmp 	mandar_descer
j43:	
			mov 	al,byte[tecla_pendente]
			and 	al,00000011b
			cmp 	al,0
			je  	j71
			jmp 	mandar_descer
j71:
			cmp 	byte[B5],1
			je 		abrir_porta3_B5
			jmp 	exit_decide
abrir_porta3_B5:
			mov 	ax,word[contador]
			cmp 	ax,178
			je 		atende_B5d
			jmp 	exit_decide
atende_B5d:	 
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B5],0
			cmp 	byte[tecla_3],1
			jne 	j72
			mov 	byte[tecla_3],0
j72:	 
			jmp 	exit_decide
		
j6:	
			mov 	ax,word[contador]
			cmp 	ax,178
			je 		atende_B4d
			jmp 	exit_decide
atende_B4d:	
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B4],0
			cmp 	byte[tecla_3],1
			jne 	j67
			mov 	byte[tecla_3],0
j67:	 
			mov 	al,byte[pendentes]
			and 	al,00001011b
			cmp 	al,0
			je 		ver_teclas_1_2_d3
			jmp 	mandar_descer
ver_teclas_1_2_d3:
			mov 	al,byte[tecla_pendente]
			and 	al,00000011b		 
			cmp 	al,0
			je 		ficar_parado
			jmp 	mandar_descer
			 
ficar_parado:
			mov 	byte[status],0
			jmp 	exit_decide		  
			  
d2:		 
			cmp 	byte[B2],1
			jne  	j15
			jmp 	j10
j15:
			cmp 	byte[tecla_2],1
			jne 	j46
			jmp 	abrir_porta_tecla2d
j46:	
			cmp 	byte[B1],1
			jne 	ver_tecla_1d2
			jmp 	mandar_descer
ver_tecla_1d2:
			cmp 	byte[tecla_1],1
			jne 	ver_B3d	
			jmp 	mandar_descer
ver_B3d:
			cmp 	byte[B3],1
			je  	abrir_porta_B3
			jmp 	exit_decide
abrir_porta_B3:
			mov 	ax,word[contador]
			cmp 	ax,89
			je 		atendende_B3d
			jmp 	exit_decide
atendende_B3d:		
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B3],0
			cmp 	byte[tecla_2],1
			jne 	j49
			mov 	byte[tecla_2],0
j49:	 
			jmp 	exit_decide
j10:	
			mov 	ax,word[contador]
			cmp 	ax,89
			je 		atende_B2_d
			jmp 	exit_decide
atende_B2_d:		
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B2],0
			cmp 	byte[tecla_2],1
			jne 	j44
			mov 	byte[tecla_2],0
j44: 
			cmp 	byte[B1],1
			jne 	ver_tecla_1d2_2
			jmp 	mandar_descer
ver_tecla_1d2_2:
			cmp 	byte[tecla_1],1
			jne 	j45
			jmp 	mandar_descer
j45:
			jmp 	exit_decide		 
p1:       
			cmp 	byte[B1],1
			je 		abrir_porta1
			cmp 	byte[tecla_1],1
			jne 	j30
			jmp 	abrir_porta_tecla1
j30:	   
			mov 	al,byte[pendentes]
			and 	al,00111110b 				; verificar se tem botao acima apertado
			cmp 	al,0
			ja  	mandar_subir  				; qualquer botao acima manda subir
			mov 	al,byte[tecla_pendente]
			and 	al,00001110b
			cmp 	al,0
			ja  	mandar_subir
			jmp 	exit_decide
abrir_porta1:
			call 	porta
			mov 	byte[B1],0
			cmp 	byte[tecla_1],1
			jne 	j29
			mov 	byte[tecla_1],0
j29:   
			jmp 	exit_decide	 
mandar_subir:
			mov 	byte[status],01000000b 		; indica o elevador deve subir ( função acende led vai dar o out na porta e mandar subir)
			jmp 	exit_decide

elv_subindo:
			mov 	al,byte[andar]
			cmp 	al,1
			jne  	j7
			jmp 	exit_decide
j7:
		
			cmp 	al,2
			jne 	j8
			jmp 	s2		  
j8:
			cmp 	al,3
			jne 	s4
			jmp 	s3
s4:	
			cmp 	byte[B6],1
			je  	j9
			cmp 	byte[tecla_4],1
			jne 	j40
			mov 	ax,word[contador]
			cmp 	ax,267
			je 		atende_tecla4s
			jmp 	exit_decide
atende_tecla4s:
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[tecla_4],0  
j40:	
			jmp 	exit_decide 
j9:  
			mov 	ax,word[contador]
			cmp 	ax,267
			je 		atende_B6s
			jmp 	exit_decide

atende_B6s:	   
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B6],0
			cmp 	byte[tecla_4],1
			jne 	j39
			mov 	byte[tecla_4],0
j39:	 
			jmp 	exit_decide
 s2:
			mov 	al,byte[B3]
			cmp 	al,1
			je 		j11
			
			cmp 	byte[tecla_2],1
			jne 	j62
			jmp 	abrir_porta_tecla_2_s_2
j62:	
			mov 	al,byte[pendentes]
			and 	al,00110100b   				; olhar B6,B5,B4
			cmp 	al,0
			je  	ver_teclas_3_4_s_2
			jmp 	mandar_subir
ver_teclas_3_4_s_2:
			mov 	al,byte[tecla_pendente]	
			and 	al,00001100b
			cmp 	al,0
			je 		ver_B2s
			jmp 	mandar_subir	
ver_B2s:
            cmp 	byte[B2],1
			je 		abrir_porta_B2s
			jmp 	exit_decide
abrir_porta_B2s:
			mov 	ax,word[contador]
			cmp 	ax,89
			je 		atende_B2s
			jmp 	exit_decide
atende_B2s:	
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B2],0
			cmp 	byte[tecla_2],1
			jne 	j65
			mov 	byte[tecla_2],0
j65:	 
			jmp 	exit_decide
j11:
			mov 	ax,word[contador]
			cmp 	ax,89
			je 		atende_B3s
			jmp 	exit_decide
atende_B3s:		   
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B3],0
			cmp 	byte[tecla_2],1
			jne 	j60
			mov 	byte[tecla_2],0
j60:	  
			mov 	al,byte[pendentes]
			and 	al,00110100b
			cmp 	al,0
			je 		ver_tecla_3_4_s2
			jmp 	mandar_subir	
ver_tecla_3_4_s2:
			mov 	al,byte[tecla_pendente]
			and 	al,00001100b
			cmp 	al,0
			je 		j66
			jmp 	mandar_subir
j66:
			jmp 	exit_decide		
 
ficar_parado2:
			mov 	byte[status],0
			jmp 	exit_decide

s3:
			mov 	al,byte[B5]
			cmp 	al,1
			je  	j12
			cmp 	byte[tecla_3],1
			jne 	j55
			jmp 	abrir_porta_tecla_3s3
j55:	
			cmp 	byte[B6],1
			jne 	ver_tecla_4s3
			jmp 	mandar_subir
ver_tecla_4s3:
			cmp 	byte[tecla_4],1
			jne 	j58
			jmp 	mandar_subir		
j58:	
			cmp 	byte[B4],1
			je 		abrir_porta_B4s
			jmp 	exit_decide
abrir_porta_B4s:	
			mov 	ax,word[contador]
			cmp 	ax,178
			je 		atendende_B4s
			jmp 	exit_decide
atendende_B4s:		
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B4],0
			cmp 	byte[tecla_3],1
			jne 	j59
			mov 	byte[tecla_3],0
j59:
			jmp 	exit_decide 
j12:
			mov 	ax,word[contador]
			cmp 	ax,178
			je 		atende_B5s
			jmp 	exit_decide
atende_B5s:		 
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[B5],0
			cmp 	byte[tecla_3],1
			jne  	j53
			mov 	byte[tecla_3],0
j53:		 
			cmp 	byte[B6],1
			jne 	ver_tecla_4s3_2
			jmp 	mandar_subir 
ver_tecla_4s3_2:
			cmp 	byte[tecla_4],1
			jne 	j54		 
			jmp 	mandar_subir
j54:
			jmp 	exit_decide
p3:
			cmp 	byte[B4],1
			jne 	j16
			jmp 	abrir_portaB4p
j16: 
			cmp 	byte[B5],1
			jne 	j17
			jmp 	abrir_portaB5p
j17:	 
			cmp 	byte[tecla_3],1
			jne 	j38
			call 	porta
			mov 	byte[tecla_3],0
j38:	 
			mov 	al,byte[pendentes]
			and 	al,00001011b
			cmp 	al,0
			je 		verificar_tecla_abaixo3
			jmp 	mandar_descer
verificar_tecla_abaixo3:
			mov 	al,byte[tecla_pendente]
			and 	al,00000011b
			cmp 	al,0		 
			je 		verificar_acima3
			jmp 	mandar_descer
			 
verificar_acima3:
			cmp 	byte[B6],1
			je  	j19
			cmp 	byte[tecla_4],1
			je 		j19
			jmp 	exit_decide
j19:	 
			jmp 	mandar_subir

abrir_portaB4p: 
			call 	porta
			mov 	byte[B4],0
			cmp 	byte[tecla_3],1
			jne 	j32
			mov 	byte[tecla_3],0
j32:	 
			mov 	al,byte[pendentes]
			and 	al,00001011b
			cmp 	al,0
			je  	ver_teclas_1_2
			jmp 	mandar_descer
ver_teclas_1_2:
			mov 	al,byte[tecla_pendente]
			and 	al,00000011b
			cmp 	al,0
			je 		j36		 
			jmp 	mandar_descer
j36:
			jmp 	exit_decide

abrir_portaB5p:
          
			call 	porta 
			mov 	byte[B5],0
			cmp 	byte[tecla_3],1
			jne 	j35
			mov 	byte[tecla_3],0
j35:	
			cmp 	byte[B6],1
			jne 	ver_tecla_4
			jmp 	mandar_subir

ver_tecla_4:
			cmp 	byte[tecla_4],1
			jne 	j37
			jmp 	mandar_subir		 
j37:
			jmp 	exit_decide
    		 
verificar_abaixo3:        
			mov 	al,byte[pendentes]
			and 	al,00001011b
			cmp 	al,0
			je 		j25
			jmp 	mandar_descer			
j25:
			jmp 	exit_decide
p2:
			cmp 	byte[B2],1
			jne 	j23
			jmp 	abrir_portaB2p
j23: 
			cmp 	byte[B3],1
			jne 	j20
			jmp 	abrir_portaB3p
j20:	 
			cmp 	byte[tecla_2],1
			je 		abrir_porta_tecla_2p2
			jmp 	verificar_abaixo2
abrir_porta_tecla_2p2:	 
			call 	porta
			mov 	byte[tecla_2],0
			jmp 	exit_decide
		 
verificar_abaixo2:		 
			cmp 	byte[B1],1
			jne 	verificar_tecla_1p2
			jmp 	mandar_descer

verificar_tecla_1p2:
			cmp 	byte[tecla_1],1
			jne 	verificar_acima2
			jmp 	mandar_descer
		
verificar_acima2:
			mov 	al,byte[pendentes]
			and 	al,00110100b
			cmp 	al,1
			jae 	j21
			mov 	al,byte[tecla_pendente]
			and 	al,00001100b
			cmp 	al,1
			jae 	j21
			jmp 	exit_decide
j21:	 
			jmp 	mandar_subir

abrir_portaB2p:
			call 	porta 
			mov 	byte[B2],0
			cmp 	byte[tecla_2],1
			jne 	j50
			mov 	byte[tecla_2],0
j50:
			cmp 	byte[B1],0
			je 		ver_tecla_1_p2
			jmp 	mandar_descer
	
ver_tecla_1_p2:
			cmp 	byte[tecla_1],1
			jne 	j51
			jmp 	mandar_descer
j51:	  		 
			jmp 	exit_decide

abrir_portaB3p:
			call 	porta 
			mov 	byte[B3],0
			mov 	al,byte[pendentes]
			and 	al,00110100b
			cmp 	al,0
			je 		ver_teclas_3_4p
			jmp 	mandar_subir
ver_teclas_3_4p:
			mov 	al,byte[tecla_pendente]
			and 	al,00001100b
			cmp 	al,0
			je 		j52
			jmp 	mandar_subir
j52:
			jmp 	exit_decide

abrir_porta_tecla4:
            call 	porta
			mov 	byte[tecla_4],0
		    cmp 	byte[B4],1
			jne 	j28
			mov 	byte[B4],0
j28:
			jmp 	exit_decide
		
abrir_porta_tecla1:
            call 	porta
            mov 	byte[tecla_1],0
            cmp 	byte[B1],1
            jne 	j31
            mov 	byte[B1],0
j31:
            jmp 	exit_decide		

abrir_porta_tecla2d:	      
			mov 	ax,word[contador]
			cmp 	ax,89
			je 		atende_tecla_2d
			jmp 	exit_decide
atende_tecla_2d:		
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[tecla_2],0
			cmp 	byte[tecla_1],1
			jne 	j47
			jmp 	mandar_descer
j47:
			cmp 	byte[B1],1
			jne 	j48		 
			jmp 	mandar_descer
j48:
			jmp 	exit_decide	
		 
abrir_porta_tecla_3s3:
			mov 	ax,word[contador]
			cmp 	ax,178
			je 		atende_tecla_3s3
			jmp 	exit_decide
atende_tecla_3s3:		
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[tecla_3],0
			cmp 	byte[tecla_4],1
			jne 	j56
			jmp 	mandar_subir
j56:
			cmp 	byte[B6],1
			jne 	j57		 
			jmp 	mandar_subir
j57:
			jmp 	exit_decide	
			
abrir_porta_tecla_2_s_2:
			mov 	ax,word[contador]
			cmp 	ax,89
			je 		atende_tecla_2_s_2
			jmp 	exit_decide
atende_tecla_2_s_2:		
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[tecla_2],0
			mov 	al,byte[pendentes]
			and 	al,00110100b
			cmp 	al,0
			je 		j63
			jmp 	mandar_subir
j63:
			mov 	al,byte[tecla_pendente]
			and 	al,00001100b
			cmp 	al,0
			je 		j64
			jmp 	mandar_subir
j64:
			jmp 	exit_decide
        
abrir_porta_tecla_3_d_3:          
			mov 	ax,word[contador]
			cmp 	ax,178
			je 		atende_tecla_3_d_3
			jmp 	exit_decide
atende_tecla_3_d_3:		
			mov 	byte[status],0
			mov 	dx,318h
			mov 	al,byte[pendentes]
			mov 	bl,byte[status]
			or 		al,bl         				; junta informação do motor com a informação do led
			out 	dx,al	
			call 	porta
			mov 	byte[tecla_3],0
			mov 	al,byte[pendentes]
			and 	al,00001011b
			cmp 	al,0
			je 		j69
			jmp 	mandar_descer
j69:
			mov 	al,byte[tecla_pendente]
			and 	al,00000011b
			cmp 	al,0
			je 		j70
			jmp 	mandar_descer
j70:
			jmp 	exit_decide
		
exit_decide:	  
			popf
			pop cx
			pop bx
			pop ax
			ret
;----------------------------------------------------------------------------------------------------------------------

;----------------------------------------------INTERFACES----------------------------------------------------------------

;----------------------------------------------------------- interface do predio ------------------


; desenhar borda da tela

interface_predio:	
			pushf
			pusha 
		
		mov		byte[cor],branco_intenso
		mov		ax,20
		push		ax
		mov		ax,460
		push		ax
		mov		ax,622
		push		ax
		mov		ax,460
		push		ax
		call		line

mov		byte[cor],branco_intenso		
		mov		ax,20
		push		ax
		mov		ax,20
		push		ax
		mov		ax,622
		push		ax
		mov		ax,20
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,20
		push		ax
		mov		ax,20
		push		ax
		mov		ax,20
		push		ax
		mov		ax,460
		push		ax
		call		line
		
mov		byte[cor],branco_intenso		
		mov		ax,622
		push		ax
		mov		ax,20
		push		ax
		mov		ax,622
		push		ax
		mov		ax,460
		push		ax
		call		line
		
; desenhar predio
mov		byte[cor],branco_intenso
		mov		ax,50
		push		ax
		mov		ax,430
		push		ax
		mov		ax,300
		push		ax
		mov		ax,430
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,50
		push		ax
		mov		ax,50
		push		ax
		mov		ax,300
		push		ax
		mov		ax,50
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,50
		push		ax
		mov		ax,50
		push		ax
		mov		ax,50
		push		ax
		mov		ax,430
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,300
		push		ax
		mov		ax,50
		push		ax
		mov		ax,300
		push		ax
		mov		ax,430
		push		ax
		call		line	
		
; desenhar divisórias dos andares
mov		byte[cor],branco_intenso
		mov		ax,50
		push		ax
		mov		ax,145
		push		ax
		mov		ax,300
		push		ax
		mov		ax,145
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,50
		push		ax
		mov		ax,240
		push		ax
		mov		ax,300
		push		ax
		mov		ax,240
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,50
		push		ax
		mov		ax,335
		push		ax
		mov		ax,300
		push		ax
		mov		ax,335
		push		ax
		call		line
		
; desenhar botões
mov		byte[cor],vermelho	
		mov		ax,100
		push		ax
		mov		ax,95
		push		ax
		mov		ax,15
		push		ax
		call	circle
		
mov		byte[cor],verde_claro		
		mov		ax,100
		push		ax
		mov		ax,173
		push		ax
		mov		ax,15
		push		ax
		call	circle
		
mov		byte[cor],vermelho		
		mov		ax,100
		push		ax
		mov		ax,212
		push		ax
		mov		ax,15
		push		ax
		call	circle
		
mov		byte[cor],verde_claro
		mov		ax,100
		push		ax
		mov		ax,268
		push		ax
		mov		ax,15
		push		ax
		call	circle
		
mov		byte[cor],vermelho
		mov		ax,100
		push		ax
		mov		ax,307
		push		ax
		mov		ax,15
		push		ax
		call	circle
		
mov		byte[cor],verde_claro		
		mov		ax,100
		push		ax
		mov		ax,380
		push		ax
		mov		ax,15
		push		ax
		call	circle
		
; desenhar setinhas

mov		byte[cor],branco_intenso
		mov		ax,100
		push		ax
		mov		ax,85
		push		ax
		mov		ax,100
		push		ax
		mov		ax,105
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,105
		push		ax
		mov		ax,95
		push		ax
		mov		ax,100
		push		ax
		mov		ax,105
		push		ax
		call		line

mov		byte[cor],branco_intenso
		mov		ax,95
		push		ax
		mov		ax,95
		push		ax
		mov		ax,100
		push		ax
		mov		ax,105
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,100
		push		ax
		mov		ax,163
		push		ax
		mov		ax,100
		push		ax
		mov		ax,183
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,105
		push		ax
		mov		ax,173
		push		ax
		mov		ax,100
		push		ax
		mov		ax,163
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,95
		push		ax
		mov		ax,173
		push		ax
		mov		ax,100
		push		ax
		mov		ax,163
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,100
		push		ax
		mov		ax,202
		push		ax
		mov		ax,100
		push		ax
		mov		ax,222
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,105
		push		ax
		mov		ax,212
		push		ax
		mov		ax,100
		push		ax
		mov		ax,222
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,95
		push		ax
		mov		ax,212
		push		ax
		mov		ax,100
		push		ax
		mov		ax,222
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,100
		push		ax
		mov		ax,258
		push		ax
		mov		ax,100
		push		ax
		mov		ax,278
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,105
		push		ax
		mov		ax,268
		push		ax
		mov		ax,100
		push		ax
		mov		ax,258
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,95
		push		ax
		mov		ax,268
		push		ax
		mov		ax,100
		push		ax
		mov		ax,258
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,100
		push		ax
		mov		ax,297
		push		ax
		mov		ax,100
		push		ax
		mov		ax,317
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,105
		push		ax
		mov		ax,307
		push		ax
		mov		ax,100
		push		ax
		mov		ax,317
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,95
		push		ax
		mov		ax,307
		push		ax
		mov		ax,100
		push		ax
		mov		ax,317
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,100
		push		ax
		mov		ax,370
		push		ax
		mov		ax,100
		push		ax
		mov		ax,390
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,105
		push		ax
		mov		ax,380
		push		ax
		mov		ax,100
		push		ax
		mov		ax,370
		push		ax
		call		line
		
mov		byte[cor],branco_intenso
		mov		ax,95
		push		ax
		mov		ax,380
		push		ax
		mov		ax,100
		push		ax
		mov		ax,370
		push		ax
		call		line
		
			popa
			popf
			ret

	
;--------------------------------------------- Mensagem inicial -------------------------------------------------------

mensagem_inicial:
			pushf
			pusha
			mov     cx,8						; número de caracteres
			mov     bx,0
			mov     dh,0						; linha 0-29
			mov     dl,35						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco

l4:			call	cursor                      ;define a posição a ser escrita
			mov     al,[bx+mens1]   			; mens1: Elevador
			call	caracter                     ;pega caracter acima e escreve na tela
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l4		
					
			mov		cx,48
			mov 	bx,0
			mov     dh,2						; linha 0-29
			mov     dl,15						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco

l5:			call	cursor
			mov     al,[bx+mens2]  				; mens2: Pressione " P " quando o elevador estiver na posição
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l5			

			mov		cx,16
			mov 	bx,0
			mov     dh,6						; linha 0-29
			mov     dl,45						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco

m5:			call	cursor
			mov     al,[bx+mens2a]				; mens2a: Inicializando...
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    m5			
			
			popa
			popf
			ret
;----------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------- Mensagem Fixa -----------------------------------------------------

mensagem_fixa:
			pusha
			pushf
		   
		    mov		cx,4						;quantidade de caracteres
			mov 	bx,0						;zera bx
			mov     dh,6						; linha 0-29
			mov     dl,61						; coluna 0-79
			mov		byte[cor],10    			; cor texto = verde

m6:			call	cursor
			mov     al,[bx+mens2b]   			; mens2b: OK!!
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    m6		

            mov		cx,9						;quantidade de caracteres
			mov 	bx,0
			mov     dh,8						; linha 0-29
			mov     dl,40						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco

l6:			call	cursor
			mov     al,[bx+mens3]    			; mens3:Chamadas
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l6	
			
			mov		cx,7
			mov 	bx,0
			mov     dh,10						; linha 0-29
			mov     dl,40						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco
l7:			call	cursor
			mov     al,[bx+mens4]      			; mens4: Painel
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l7	

            mov		cx,8						;quantidade de caracteres
			mov 	bx,0
			mov     dh,12						; linha 0-29
			mov     dl,40						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco
l8:			call	cursor
			mov     al,[bx+mens5]      			; mens5: Externa
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l8				
			
            mov		cx,13						;quantidade de caracteres
			mov 	bx,0
			mov     dh,14						; linha 0-29
			mov     dl,40						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco
l9:			call	cursor 
			mov     al,[bx+mens6]      			; mens6: Andar Atual
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l9							

			
	        mov		cx,20						;quantidade de caracteres
			mov 	bx,0
			mov     dh,16						; linha 0-29
			mov     dl,40						; coluna 0-79
			mov		byte[cor],15    			; cor texto = branco
l10:		call	cursor
			mov     al,[bx+mens7]        		; mens7: Status do Elevador
			call	caracter            
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l10				

			popf			
			popa
			ret	
;----------------------------------------------------------------------------------------------------------------------   	   

;---------------------------------------------- Interface Emergência --------------------------------------------------

interface_emergencia:       
			pusha
			pushf
		  
		    mov		cx,13						;quantidade de caracteres
			mov		bx,0
			mov    	dh,22						;Linha 0-29
			mov    	dl,49						;Coluna 0-79
			cmp		byte[status_emergencia],1	;compara se o botao de emergencia foi pressionado
			jne		pula4						;caso nao tenha sido, printa da cor preta.
			mov		byte[cor],4    				; cor texto = vermelho
			jmp		l10d						;pula para a funcao
pula4:		
            mov		byte[cor],0    				; cor texto = preto
l10d:			
            call	cursor						;chama cursor
			mov     al,[bx+status4]				;Plota mensagem "EMERGÊNCIA!!!"
			call	caracter					;chama funcao caracter
			inc     bx							;Próximo caracter
			inc		dl							;Avança a coluna
			loop    l10d	
		  
			popf
			popa
			ret
;----------------------------------------------------------------------------------------------------------------------

;------------------------------------------------ Interface Status ----------------------------------------------------

interface_status:
            pusha
			pushf			
			mov		cx,6						;quantidade de caracteres
			mov 	bx,0
			mov    	dh,16						; linha 0-29
			mov    	dl,60						; coluna 0-79
			
			mov 	al,byte[ultimo_status]		;coloca em al o ultimo status registrado
			cmp 	al,byte[status]				; e compara com o status atual
			jne 	j74							; nao sendo iguais, vai para a funcao
			jmp 	exit_interface_status		; sendo iguais, sai da rotina
j74:	
    		cmp		byte[status],00000000b      ; elevador parado
			jne		pula1						; se nao for, printa de preto
			mov		byte[cor],15    			; cor texto = branco
			jmp 	l10a
pula1:		
            mov		byte[cor],0    				; cor texto = preto
l10a:		
            call	cursor
			mov     al,[bx+status1]     		; "Parado"
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l10a	
			
			mov		cx,8						;quantidade de caracteres
			mov 	bx,0
			mov     dh,18						; linha 0-29
			mov     dl,60						; coluna 0-79
			cmp		byte[status],10000000b 		; elevador descendo	
			jne		pula2						;printa de preto	
			mov		byte[cor],15    			; cor texto = branco
			jmp		l10b
pula2:		
            mov		byte[cor],0    				; cor texto = preto
l10b:		
            call	cursor
			mov     al,[bx+status2]    			; "Descendo"
			call	caracter				
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l10b	
			
		    mov		cx,7						;quantidade de caracteres
			mov 	bx,0
			mov     dh,20						; linha 0-29
			mov     dl,60						; coluna 0-79
			cmp		byte[status],01000000b 		; elevador subindo	
			jne		pula3						; printa de preto
			mov		byte[cor],15    			; cor texto = branco
			jmp		l10c
pula3:		
            mov		byte[cor],0    				; cor texto = preto
l10c:		
            call	cursor
			mov     al,[bx+status3]    			;"Subindo"
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l10c	
			
			mov 	al,byte[status]				;coloca em al o status atual
			mov 	byte[ultimo_status],al		;atualiza a variavel "ultimo_status"
			
exit_interface_status:			
			popf
			popa
			ret
;----------------------------------------------------------------------------------------------------------------------

;---------------------------------------------- Interface Teclado -----------------------------------------------------

interface_interna:   
            pusha
			pushf
 
			mov 	al,byte[tecla_anterior]		;coloca em al a tecla anterior
			cmp 	al,byte[tecla_pendente]		;compara com a pensente
			jne 	j75							;nao sendo igual, vai para a funcao
			jmp 	exit_interface_interna		;sendo igual, sai da rotina
j75:	 
			mov		cx,2						;quantidade de caracteres
			mov 	bx,0
			mov     dh,10						; linha 0-29
			mov     dl,47						; coluna 0-79
			cmp		byte[tecla_1],1 			;observa se a tecla 1 foi apertada
			je		aparece1					;se foi, printa de branco
			mov		byte[cor],0    				; cor texto = preto
			jmp		l7a
aparece1:	
            mov		byte[cor],15    			; cor texto = branco
l7a:		
            call	cursor
			mov     al,[bx+um]					;printa na tela
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l7a
		
			mov		cx,2						
			mov 	bx,0
			mov     dh,10						; linha 0-29
			mov     dl,49						; coluna 0-79
			cmp		byte[tecla_2],1 
			je		aparece2
			mov		byte[cor],0    				; cor texto = preto
			jmp		l7b
aparece2:	
            mov		byte[cor],15    			; cor texto = branco
l7b:		
            call	cursor
			mov     al,[bx+dois]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l7b

			mov		cx,2
			mov 	bx,0
			mov     dh,10						; linha 0-29
			mov     dl,51						; coluna 0-79
			cmp		byte[tecla_3],1 
			je		aparece3
			mov		byte[cor],0    				; cor texto = preto
			jmp		l7c
aparece3:	
            mov		byte[cor],15    			; cor texto = branco
l7c:		
            call	cursor
			mov     al,[bx+tres]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l7c

			mov		cx,2
			mov 	bx,0
			mov     dh,10						; linha 0-29
			mov     dl,53						; coluna 0-79
			cmp		byte[tecla_4],1 
			je		aparece4
			mov		byte[cor],0    				; cor texto = preto
			jmp		l7d
aparece4:	
            mov		byte[cor],15    			; cor texto = branco
l7d:		
            call	cursor
			mov     al,[bx+quatro]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l7d
				 
exit_interface_interna:
			mov 	al,byte[tecla_pendente]		;coloca em al as teclas pendentes	
			mov 	byte[tecla_anterior],al		;atualiza a variavel
				 
			popf
			popa
			ret
;----------------------------------------------------------------------------------------------------------------------

;------------------------------------------------ Interface Andar -----------------------------------------------------

interface_andar:
			pusha
			pushf
			 
			mov 	al,byte[ultimo_andar]			;coloca em al o ultimo registro
			cmp 	al,byte[andar]					; compara o ultimo registro com o atual
			jne 	j78								;caso sejam diferentes, vai para a guncao
			jmp 	exit_interface_andar   
j78:		   
			mov		cx,2
			mov 	bx,0
			mov     dh,14						; linha 0-29
			mov     dl,53						; coluna 0-79
			cmp		byte[andar],1 				; observa se o andar foi setado com 1 
			jne		outroand1					; caso nao seja, printado de preto
			mov		byte[cor],15    			; cor texto = branco
			jmp		l9a
outroand1:	
            mov		byte[cor],0    				; cor texto = preto
l9a:		
            call	cursor						;mesmo procedimento
			mov     al,[bx+um]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l9a

			mov		cx,2
			mov 	bx,0
			mov     dh,14						; linha 0-29
			mov     dl,55						; coluna 0-79
			cmp		byte[andar],2 
			jne		outroand2
			mov		byte[cor],15    			; cor texto = branco
			jmp		l9b
outroand2:  
            mov		byte[cor],0    				; cor texto = preto
l9b:		
            call	cursor
			mov     al,[bx+dois]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l9b				

			mov		cx,2
			mov 	bx,0
			mov     dh,14						; linha 0-29
			mov     dl,57						; coluna 0-79
			cmp		byte[andar],3 
			jne		outroand3
			mov		byte[cor],15    			; cor texto = branco
			jmp		l9c
outroand3:  
            mov		byte[cor],0    				; cor texto = preto
l9c:		
            call	cursor
			mov     al,[bx+tres]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l9c

			mov		cx,2
			mov 	bx,0
			mov     dh,14						; linha 0-29
			mov     dl,59						; coluna 0-79
			cmp		byte[andar],4 
			jne		ultimoand
			mov		byte[cor],15    			; cor texto = branco
			jmp		l9d
ultimoand:	
            mov		byte[cor],0    				; cor texto = preto		
l9d:		
            call	cursor
			mov     al,[bx+quatro]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l9d	
			
exit_interface_andar:			   
			mov 	al,byte[andar]				;coloca em al a variavel "andar"
			mov 	byte[ultimo_andar],al		;atualiza o ultimo andar
			      
			popf
			popa
			ret
;----------------------------------------------------------------------------------------------------------------------

;------------------------------------------------ Interface Botões ----------------------------------------------------

interface_externa:
            pusha
			pushf
				 
			mov 	al,byte[ultimo_botao]		;coloca em al o ultimo botao
			cmp 	al,byte[pendentes]			;compara com os pendentes
			jne 	j80							;nao sendo igual, vai para a funcao	
			jmp 	exit_interface_externa		;se for igual, nao há mais pendencia
				 
		j80:		 
		    mov		cx,3
			mov 	bx,0
			mov     dh,12						; linha 0-29
			mov     dl,48						; coluna 0-79
			cmp		byte[B1],1 					;observa se B1 foi setado
			je		apareceB1					; sendo igual, printa de branco	
			mov		byte[cor],0    				; cor texto = preto
			jmp		l8a							
apareceB1:	
            mov		byte[cor],15    			; cor texto = branco
l8a:		
            call	cursor
			mov     al,[bx+externa1]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l8a	
			
			mov		cx,3						;mesmo procedimento que nos anteriores
			mov 	bx,0
			mov     dh,12						; linha 0-29
			mov     dl,51						; coluna 0-79
			cmp		byte[B2],1 
			je		apareceB2
			mov		byte[cor],0    				; cor texto = preto
			jmp		l8b
apareceB2:	
            mov		byte[cor],15    			; cor texto = branco
l8b:		
            call	cursor
			mov     al,[bx+externa2]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l8b	
			
			mov		cx,3
			mov 	bx,0
			mov     dh,12						; linha 0-29
			mov     dl,54						; coluna 0-79
			cmp		byte[B3],1 
			je		apareceB3
			mov		byte[cor],0    				; cor texto = preto
			jmp		l8c
apareceB3:	
             mov	byte[cor],15    			; cor texto = branco
l8c:		
            call	cursor
			mov     al,[bx+externa3]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l8c	
			
			mov		cx,3
			mov 	bx,0
			mov     dh,12						; linha 0-29
			mov     dl,57						; coluna 0-79
			cmp		byte[B4],1 
			je		apareceB4
			mov		byte[cor],0    				; cor texto = preto
			jmp		l8d
apareceB4:	
            mov		byte[cor],15    			; cor texto = branco
l8d:		
            call	cursor
			mov     al,[bx+externa4]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l8d	
	
			mov		cx,3
			mov 	bx,0
			mov     dh,12						; linha 0-29
			mov     dl,60						; coluna 0-79
			cmp		byte[B5],1 
			je		apareceB5
			mov		byte[cor],0    				; cor texto = preto
			jmp		l8e
apareceB5:	
            mov		byte[cor],15    			; cor texto = branco
l8e:		
            call	cursor
			mov     al,[bx+externa5]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l8e
			
			mov		cx,3
			mov 	bx,0
			mov     dh,12						; linha 0-29
			mov     dl,63						; coluna 0-79
			cmp		byte[B6],1 
			je		apareceB6
			mov		byte[cor],0    				; cor texto = preto
			jmp		l8f
apareceB6:	
            mov		byte[cor],15    			; cor texto = branco
l8f:		
            call	cursor
			mov     al,[bx+externa6]
			call	caracter
			inc     bx							; proximo caracter
			inc		dl							; avanca a coluna
			loop    l8f	
			
exit_interface_externa:				 
			mov 	al,byte[pendentes]			;coloca em al os botoes pendentes
			mov 	byte[ultimo_botao],al		;atualiza a variavel
			popf
			popa
			ret
			

;----------------------------------------------------------------------------------------------------------------------

;--------------------------------------- Funções para impressão em tela -----------------------------------------------


;----------------------------------------


;função circle
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
	mov		dx,0  	;dx será a variável x. cx é a variavel y
	
;aqui em cima a lógica foi invertida, 1-r => r-1
;e as comparações passaram a ser jl => jg, assim garante 
;valores positivos para d

stay:				;loop
	mov		si,di
	cmp		si,0
	jg		inf       ;caso d for menor que 0, seleciona pixel superior (não  salta)
	mov		si,dx		;o jl é importante porque trata-se de conta com sinal
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
	call plot_xy		;toma conta do sétimo octante
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
	jb		fim_circle  ;se cx (y) está abaixo de dx (x), termina     
	jmp		stay		;se cx (y) está acima de dx (x), continua no loop
	
	
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
;_________________________________________________________________________________________________
;
;   função line
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
; comparar módulos de deltax e deltay sabendo que cx>ax
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
		
;_________________________________________________________________________________________________________
;
;   função plot_xy
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
		

;________________________________________________________
; Função cursor
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
;________________________________________________________

;________________________________________________________
;   Função caracter escrito na posição do cursor
; al= caracter a ser escrito
; Cor definida na variável cor
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
;________________________________________________________

;------------------------------------------------- Fim das funções ----------------------------------------------------



;-------------------------------------------------- Variáveis ---------------------------------------------------------

segment data
;------------------------------------------- Referente ao TECBUF ------------------------------------------------------

kb_data 			equ 	60h					; PORTA DE LEITURA DE TECLADO
kb_ctl  			equ 	61h					; PORTA DE RESET PARA PEDIR NOVA INTERRUPCAO
pictrl  			equ 	20h
eoi     			equ 	20h
int9    			equ 	9h
cs_dos  			dw  	1
offset_dos  		dw 		1
tecla_u 			db 		0
tecla   			resb	8 
p_i     			dw  	0					; ponteiro p/ interrupcao (qnd pressiona tecla)  
p_t     			dw  	0					; ponterio p/ interrupcao (qnd solta tecla)    
teclasc 			db  	0,0,13,10,'$'
;----------------------------------------------------------------------------------------------------------------------

entrada_atual 		db 		0           		; variavel com a entrada ja com debounce
contador      		dw 		0           		; contar voltas do sensor
status        		db 		0           		; indica se o elevador esta parado,subindo ou descendo
andar         		db 		0           		; indicar o andar do elevador
B1            		db 		0           		; flag para identificar botao pendente
B2            		db 		0           		; flag para identificar botao pendente
B3            		db 		0           		; flag para identificar botao pendente
B4            		db 		0           		; flag para identificar botao pendente
B5            		db 		0           		; flag para identificar botao pendente
B6            		db 		0          			; flag para identificar botao pendente
pendentes     		db 		0      				; identificar quais botoes externos ainda esperam adentimento
tecla_pendente 		db 		0	
delay         		dw 		0
salva_status   		db 		0
tecla_1        		db 		0
tecla_2        		db 		0
tecla_3        		db 		0
tecla_4        		db 		0
     
;--------------------------------------------- Dados para imprimir ----------------------------------------------------

cor					db		branco_intenso

preto				equ		0
vermelho			equ		4
verde_claro			equ		10
branco_intenso		equ		15
mens1    			db  	'Elevador'
mens2 				db		'Tecle " P " quando o elevador chegar ao ANDAR 4!'
mens2a				db		'Inicializando...'
mens2b				db		' OK!'
mens3				db		'Chamadas:'
mens4				db		'PAINEL:'
mens5				db		'EXTERNA:'
mens6				db		'ANDAR ATUAL: '
mens7				db		'STATUS DO ELEVADOR: '
status4				db		'EMERGENCIA!!!'
status1				db		'PARADO'
status2				db		'DESCENDO'
status3				db		'SUBINDO'
um					db		' 1'				; Chamada do Painel
dois				db		' 2'				;		  e
tres				db		' 3'				;    Andar atual
quatro				db		' 4'
externa1			db		' B1'
externa2			db		' B2'
externa3			db		' B3'
externa4			db		' B4'
externa5			db		' B5'
externa6			db		' B6'
deltax				dw		0
deltay				dw		0

modo_anterior		db		0
status_emergencia   db      0
tecla_anterior      db      0
ultimo_status       db      1
ultimo_andar        db      0
ultimo_botao        db      0
;----------------------------------------------------------------------------------------------------------------------
segment stack stack
    		resb 		256
stacktop:	