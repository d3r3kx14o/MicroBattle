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

	RC_BACKGROUND 				equ 	1

	RC_PLAYER1 					equ 	2
	RC_PLAYER2 					equ 	3
	RC_PLAYER1MASK 				equ 	4
	RC_PLAYER2MASK 				equ 	5
	RC_PLAYER1_DIE				equ 	6
	RC_PLAYER2_DIE				equ 	7
	RC_PLAYER1_DIEMASK			equ 	8
	RC_PLAYER2_DIEMASK			equ 	9
	RC_PLAYER1_IDLE				equ 	10
	RC_PLAYER2_IDLE				equ 	11
	RC_PLAYER1_IDLEMASK		equ 	12
	RC_PLAYER2_IDLEMASK		equ 	13

	RC_SCORE_0				equ	14
	RC_SCORE_1				equ	15
	RC_SCORE_2				equ	16
	RC_SCORE_3				equ	17
	RC_SCORE_4				equ	18
	RC_SCORE_5				equ	19

	RC_PLAYER1_IDLESHOT			equ	20
	RC_PLAYER1_SHOT				equ	21
	RC_PLAYER2_IDLESHOT			equ	22
	RC_PLAYER2_SHOT				equ	23
	RC_PLAYER1_SHOTMASK			equ	24
	RC_PLAYER1_IDLESHOTMASK			equ	25
	RC_PLAYER2_SHOTMASK			equ	26
	RC_PLAYER2_IDLESHOTMASK			equ	27

	RC_BULLET					equ		114
	RC_BULLETMASK				equ		115
	RC_SMOKE					equ		116
	RC_CACTUS 					equ 	117
	RC_CACTUSMASK				equ 	118
	RC_CACTUSGONE				equ	119
	RC_CACTUSGONEMASK			equ	120
	RC_BUCKET 					equ 	121
	RC_BUCKETMASK				equ 	122
	RC_STONE					equ 	125
	RC_STONEMASK				equ 	126

	RC_RESET				equ	130
	RC_WIN					equ	131
	RC_LOSE					equ	132

	MICROBATTLE_ICON 			equ 	500

	CACTUS					equ	1
	BUCKET					equ	2
	STONE					equ	3

	ANIMBEGIN				equ	32
	

	;=================
	; Local prototypes
	;=================
	WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
	WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
	TopXY PROTO :DWORD, :DWORD

	LoadGraphics PROTO
	Paint_Proc PROTO
	PaintBMP PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
	PaintBMPEx PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
	PaintBMPMask PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
	PaintBMPMaskEx PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
	AnimFunc PROTO
	GameTimer PROTO
	BulletCollide PROTO
	MovePlayers PROTO
	MoveBullets PROTO
	MoveSmoke PROTO
	FireBullet  PROTO :DWORD
	AddSmoke PROTO :DWORD, :DWORD, :DWORD, :DWORD
	SetupScene PROTO
	SetItems PROTO
	DetectCollision PROTO :DWORD
	CollideIntoTrash PROTO :DWORD, :DWORD
	CollideIntoGrass PROTO :DWORD, :DWORD
	CollideIntoStone PROTO :DWORD, :DWORD
	CollideIntoPlayers PROTO :DWORD, :DWORD
	RefreshState PROTO
	ResetGame PROTO
	FakeRandom PROTO :DWORD
	prand PROTO :DWORD
	pseed PROTO  :DWORD,:DWORD,:DWORD,:DWORD

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

	return MACRO rev
		mov eax, rev
		ret
	ENDM

	xchgM MACRO M1, M2
		push M1
		m2m M1, M2
		pop M2
	ENDM
	
	;=============
	; Local struct
	;=============

	;#### bullet
	Bullet struct
		hBullet			dd		0
		hBulletMask		dd		0
		b_x	    		dd 		0
		b_y	    		dd 		0
		speed_x   		SDWORD 		0
		speed_y   		SDWORD 		0
	Bullet ends

	;#### bullets
	BulletsArray struct
		Bullets 		Bullet 	4 DUP(<>)
		len dd 0
	BulletsArray ends

	;#### item
	Item struct
		hItem			dd		0
		hItemMask		dd		0
		i_x	    		dd 		0
		i_y	    		dd 		0
		itemWidth		dd		0
		itemHeight		dd		0
		category		dd		0			; 0 for nothing
										; 1 for cactus 
										; 2 for bucket
										; 3 for stone
		disappear		dd		0
		state			dd		ANIMBEGIN
	Item ends

	;#### items
	ItemArray struct
		Items 			Item 	14 DUP(<>)
		len 			dd 		0
	ItemArray ends

	;#### player
	Player struct
		hPlayer			dd 		0
		hPlayerMask		dd 		0
		state			dd 		0				; 0: has gun
												; 1: idle
												; 2: got shot
												; 3: idle got shot
												; 4: dead
		playerHeight	dd 		84
		playerWidth		dd 		85
		p_x				dd 		0
		p_y				dd 		20				; equal PlaygroundTop
		lives			dd 		5
		speed			dd 		2
		remainAni		dd	0
	Player ends

	;#### players
	PlayersArray struct
		Players			Player 	2 DUP(<>)
	PlayersArray ends

	;#### smoke
	Smoke struct
		smoke_x 		dd 		0
		smoke_y			dd 		0
		speed_x			dd 		0
		speed_y 		dd 		0
		stage 			dd 		0
	Smoke ends

	SmokeArray struct
		smoke 			Smoke 	200 DUP(<>)
		len 			dd 		0
	SmokeArray ends

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
	hReset		    dd		0
	hUWin		    dd		0
	hLose		    dd		0
	hPlayer1	    	dd 		0
	hPlayer1Mask	    dd 		0
	hPlayer1Shot	    dd		0
	hPlayer1ShotMask    dd		0
	hPlayer1Dead	    dd 		0
	hPlayer1DeadMask    dd 		0
	hPlayer1Idle	    dd 		0
	hPlayer1IdleMask    dd 		0
	hPlayer1IdleShot    dd		0
	hPlayer1IdleShotMask	dd	0
	hPlayer2	    	dd 		0
	hPlayer2Mask	    dd 		0
	hPlayer2Shot	    dd		0
	hPlayer2ShotMask    dd		0
	hPlayer2Dead	    dd 		0
	hPlayer2DeadMask    dd 		0
	hPlayer2Idle	    dd 		0
	hPlayer2IdleMask    dd 		0
	hPlayer2IdleShot    dd		0
	hPlayer2IdleShotMask	dd	0
	hBullet				dd 		0
	hBulletMask			dd 		0
	hSmoke				dd 		0
	hCactus 			dd 		0
	hCactusMask			dd 		0
	hCactusGone			dd		0
	hCactusGoneMask			dd		0
	hBucket				dd 		0
	hBucketMask			dd 		0
	hStone 				dd 		0
	hStoneMask			dd 		0
	hScore				dd		6 DUP (0)

	; Game parameter
	GameTimerValue	    dd 		17
	WindowWidth	    	dd 		1000
	WindowHeight	    dd 		750
	PlaygroundTop		dd 		20
	PlaygroundBottom 	dd 		400
	PlaygroundLeft 		dd  	50
	PlaygroundRight		dd 		800
	PlaygroundBorder	dd		10

	ResetPositionX		dd	435
	ResetPositionY		dd	600
	ResetWidth		dd	161
	ResetHeight		dd	126
	WinWidth		dd	257
	WinHeight		dd	39 
	LoseWidth		dd	302
	LoseHeight		dd	35
	BlueWinPositionX	dd	75
	BlueWinPositionY	dd	625
	BlueLosePositionX	dd	50 
	BlueLosePositionY	dd	625
	RedWinPositionX		dd	675
	RedWinPositionY		dd	625
	RedLosePositionX	dd	650
	RedLosePositionY	dd	625

	Player1Position		dd	31
	Player2Position		dd	883
	ScorePanel1PositionX	dd	250
	ScorePanel2PositionX	dd	700
	ScorePanelPositionY	dd	600
	ScorePanelWidth		dd	49
	ScorePanelHeight	dd	57
	PlayerWidth	    	dd 		85
	PlayerIdleWidth		dd		64
	PlayerDeadWidth		dd		84
	PlayerHeight 		dd 		84
	PlayerIdleHeight 	dd 		84
	PlayerDeadHeight	dd		68
	PlayerGunHeight		dd		30
	smokeWidth 			dd 		8
	smokeHeight			dd 		8
	SmokeSpeedDecay 	dd 		3
	BulletInitSpeed		dd 		10
	BulletSpeedUp		dd		5
	BulletStageNumber	dd		8
	BulletWidth			dd 		36
	BulletHeight		dd		17
	CactusWidth 		dd 		55
	CactusHeight		dd 		81
	CacusOffsetX		dd		0
	CacusOffsetY		dd		0
	BucketWidth		dd		168
	BucketHeight		dd		192
	BucketOffsetX		dd		61
	BucketOffsetY		dd		52
	StoneWidth		dd		144
	StoneHeight		dd		192
	StoneOffsetX		dd		48
	StoneOffsetY		dd		48
	BulletOutrangeR		dd		1000
	BulletOutrangeL		dd		0

	Player1X	    	dd 		20
	Player1Y	    	dd 		10
	Player2X	    	dd 		900
	Player2Y			dd 		10
	Player1Lives	    db 		5
	Player2Lives	    db 		5
	Player1Speed		dd 		2
	Player2Speed		dd 		2

	ItemX	dd  250, 350, 600, 500, 750, 700, 825, 200, 425, 700, 325, 825, 175, 500
	ItemY	dd  100, 250, 175, 375, 100, 450, 175, 350, 100, 300, 450, 400, 175, 250

	NoCollisionDetected	dd		49
	TrashSlowDown		dd		6
	Player1Shot		dd		50  
	Player2Shot		dd		51
	CollisionDetect		dd		0


	GameStatus			dd 		0				;0->New Game
												;1->Playing
												;2->Pause

												;3->Blue win
												;4->Red Win
	players 			PlayersArray <>
	bullets 			BulletsArray <>
	cloud 				SmokeArray <>
	items 				ItemArray <>
	
	;=================
	; Local mini
	;=================
	shootMini	    	db "res/shoot.wav", 	0
	cacusMini		db "res/cacus.wav",	0
	stoneMini		db "res/stone.wav",	0
	bucketMini		db "res/bucket.wav",	0
	shotMini		db "res/shot.wav",	0
	finishMini		db "res/Finish.wav",	0
	MusicTimer		db			1

	;=================
	; Random Seeds
	;=================
	seed1  dd 0AAAABBBBh
	seed2  dd 0CCCCDDDDh
	seed3  dd 0EEEEFFFFh
	seed4  dd 11112222h

; ########################### Inserted modules ############################


; #########################################################################

