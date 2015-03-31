; #########################################################################

;     include files
;     ~~~~~~~~~~~~~
	include windows.inc
	include masm32.inc
	include gdi32.inc
	include user32.inc
	include kernel32.inc
	include Comctl32.inc
	include comdlg32.inc
	include shell32.inc
	include oleaut32.inc
	include ole32.inc
	include winmm.inc

;   libraries
;   ~~~~~~~~~
	includelib masm32.lib
	includelib gdi32.lib
	includelib user32.lib
	includelib kernel32.lib
	includelib Comctl32.lib
	includelib comdlg32.lib
	includelib shell32.lib
	includelib oleaut32.lib
	includelib ole32.lib
	includelib winmm.lib


; #########################################################################

	RC_BACKGROUND 		equ 	1
	RC_PLAYER1 			equ 	2
	RC_PLAYER2 			equ 	3
	RC_BULLET			equ		114

	;=================
	; Local prototypes
	;=================
	WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
	WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
	TopXY PROTO :DWORD, :DWORD

	LoadGraphics PROTO
	Paint_Proc PROTO
	PaintBMP PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
	GameTimer PROTO
	MovePlayers PROTO
	MoveBullets PROTO
	FireBullet  PROTO :DWORD

	;=============
	; Local macros
	;=============
	m2m MACRO M1, M2
		push M2
		pop  M1
	ENDM

	szText MACRO Name, Text:VARARG
		LOCAL lbl
		jmp lbl
		Name db Text,0
		lbl:
	ENDM
	
	;=============
	; Local struct
	;=============

	;#### bullet
	Bullet struct
		hBullet			dd		0
		b_x	    		dd 		0
		b_y	    		dd 		0
		speed_x   		dd 		5
		speed_y   		dd 		0
		bulletHeight	dd 		17
		bulletWidth		dd 		36
	Bullet ends

	;#### bullets
	BulletsArray struct
		bullets 		Bullet 	10 DUP(<>)
		len dd 0
	BulletsArray ends

	;#### item
	Item struct
		i_x	    		db 		0
		i_y	    		db 		0
		category  		db 		0
		state	    	db 		0
	Item ends

	;#### player
	Player struct
		hPlayer			dd 		0
		state			dd 		0				; 0: has gun
												; 1: idle
												; 2: dead
		playerHeight	dd 		84
		playerWidth		dd 		85
		p_x				dd 		0
		p_y				dd 		10
		lives			dd 		5
		speed			dd 		2
	Player ends

	;#### players
	PlayersArray struct
		Players			Player 	2 DUP(<>)
	PlayersArray ends

.data
	; Windows variable
	gameDisplayName	    db 		"MicroBattle - by DoGame", 0
	CommandLine	    	dd 		0
	hWnd		    	dd 		0
	hInstance	    	dd 		0
	hIcon		    	dd 		0
	hDC		    		dd		0
	hDC2		    	dd 		0
	hWin				dd 		0

	; Image handle variable
	hBmpBackround	    dd 		0
	hPlayer1	    	dd 		0
	hPlayer1Dead	    dd 		0
	hPlayer1Idle	    dd 		0				;there is 3 state of player
	hPlayer2	    	dd 		0
	hPlayer2Dead	    dd 		0
	hPlayer2Idle	    dd 		0
	hBullet				dd 		0

	; Game parameter
	GameTimerValue	    dd 		17
	WindowWidth	    	dd 		1000
	WindowHeight	    dd 		750
	PlaygroundTop		dd 		0
	PlaygroundBottom 	dd 		50
	PlaygroundWidth 	dd  	800
	PlayerWidth	    	dd 		85
	playerHeight 		dd 		84

	Player1X	    	dd 		20
	Player1Y	    	dd 		10
	Player2X	    	dd 		900
	Player2Y			dd 		10
	Player1Lives	    db 		5
	Player2Lives	    db 		5
	Player1Speed		dd 		2
	Player2Speed		dd 		2

	GameStatus			dd 		0				;0->New Game
												;1->Playing
												;2->Pause

	players 			PlayersArray <>
	bullets 			BulletsArray <>

; ########################### Inserted modules ############################


; #########################################################################

