.386
.model flat, stdcall
option casemap :none

include MicroBattle.inc

; #########################################################################

.code 

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax

    ;###### Random initiate
    invoke GetTickCount
    invoke pseed, eax, 2342347, 63452, eax

    ;###### Extract images from exe's resource file
    invoke LoadGraphics

    invoke GetCommandLine 
    mov CommandLine, eax

    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

    ;====================
    ; Put LOCALs on stack
    ;====================

    LOCAL wc    :WNDCLASSEX
    LOCAL msg   :MSG
    LOCAL Wwd   :DWORD
    LOCAL Wht   :DWORD
    LOCAL Wtx   :DWORD
    LOCAL Wty   :DWORD

    LOCAL Ps    :PAINTSTRUCT

    ;==================================================
    ; Fill WNDCLASSEX structure with required variables
    ;==================================================

    invoke LoadIcon,hInst,500    ; icon ID
    mov hIcon, eax

    szText szClassName,"Project_Class"

    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_BYTEALIGNWINDOW
    mov wc.lpfnWndProc,    offset WndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInst
    mov wc.hbrBackground,  COLOR_BTNFACE+1
    mov wc.lpszMenuName,   NULL
    mov wc.lpszClassName,  offset szClassName
    m2m wc.hIcon,          hIcon
    invoke LoadCursor,NULL,IDC_ARROW
    mov wc.hCursor,        eax
    m2m wc.hIconSm,        hIcon

    invoke RegisterClassEx, ADDR wc

    ;================================
    ; Centre window at following size
    ;================================

    mov Wwd, 1015
    mov Wht, 780

    invoke GetSystemMetrics,SM_CXSCREEN
    invoke TopXY,Wwd,eax
    mov Wtx, eax

    invoke GetSystemMetrics,SM_CYSCREEN
    invoke TopXY,Wht,eax
    mov Wty, eax

    invoke CreateWindowEx,WS_EX_LEFT,
        ADDR szClassName,
        ADDR gameDisplayName,
        WS_OVERLAPPEDWINDOW,
        Wtx,Wty,Wwd,Wht,
        NULL,NULL,
        hInst,NULL
    mov   hWnd,eax

    invoke LoadMenu,hInst,600  ; menu ID
    invoke SetMenu,hWnd,eax

    invoke SetupScene

    invoke ShowWindow,hWnd,SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

    ;===================================
    ; Set the Timer Event
    ;===================================

    invoke SetTimer,hWnd,NULL,GameTimerValue,NULL

    m2m hWin,hWnd


    ;===================================
    ; Loop until PostQuitMessage is sent
    ;===================================

    StartLoop:
        invoke GetMessage,ADDR msg,NULL,0,0
        cmp eax, 0
        je ExitLoop
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage,  ADDR msg
        jmp StartLoop
    ExitLoop:

    mov eax, msg.wParam
    ret

WinMain endp

; #########################################################################

WndProc proc    hWinL  :DWORD,
                uMsg   :DWORD,
                wParam :DWORD,
                lParam :DWORD

    LOCAL Ps	:PAINTSTRUCT

    .if uMsg == WM_COMMAND
    ;======== menu commands ========
    .elseif uMsg == WM_CREATE

    .elseif uMsg == WM_SIZE

    .elseif uMsg == WM_PAINT
        invoke BeginPaint, hWin, addr Ps
        mov hDC, eax
        invoke Paint_Proc
        invoke EndPaint, hWin, addr Ps
        mov eax, 0
        ret

    .elseif uMsg == WM_TIMER
    	invoke GameTimer
    	invoke RedrawWindow, hWin, NULL, NULL, RDW_INVALIDATE

    .elseif uMsg == WM_KEYDOWN
    	.if wParam == VK_A && GameStatus < 3
			mov ebx, players.Players[0].state
            ;Player 1 presses the key
            .if ebx == 0            
    			invoke FireBullet, 0
            .elseif ebx == 1
                mov eax, players.Players[0].speed
                neg eax
                mov players.Players[0].speed, eax
            .elseif ebx == 2
            .endif
    	.elseif wParam == VK_L && GameStatus < 3
            ;Player 2 presses the key
			mov ebx, players.Players[SIZEOF Player].state
            .if ebx == 0
        		invoke FireBullet, 1
            .elseif ebx == 1
                mov eax, players.Players[SIZEOF Player].speed
                neg eax
                mov players.Players[SIZEOF Player].speed, eax
            .elseif ebx == 2
            .endif
	.elseif wParam == VK_R && GameStatus > 2
	    mov GameStatus, 0
        .elseif wParam == VK_ESCAPE
            invoke PostQuitMessage,NULL
            return 0
    	.endif
    .endif

    invoke DefWindowProc, hWinL, uMsg, wParam, lParam

    ret
	
WndProc endp

; #########################################################################

LoadGraphics proc

    ;#### background
    invoke LoadBitmap, hInstance, RC_BACKGROUND
    mov hBmpBackround, eax

    ;#### player1
    invoke LoadBitmap, hInstance, RC_PLAYER1
    mov hPlayer1, eax
    ;#### player1Mask
    invoke LoadBitmap, hInstance, RC_PLAYER1MASK
    mov hPlayer1Mask, eax
    ;#### player1Shot
    invoke LoadBitmap, hInstance, RC_PLAYER1_SHOT
    mov hPlayer1Shot, eax
    ;#### player1 Shot mask
    invoke LoadBitmap, hInstance, RC_PLAYER1_SHOTMASK
    mov hPlayer1ShotMask, eax
    ;#### player1 idle
    invoke LoadBitmap, hInstance, RC_PLAYER1_IDLE
    mov hPlayer1Idle, eax
    ;#### player1 idle mask
    invoke LoadBitmap, hInstance, RC_PLAYER1_IDLEMASK
    mov hPlayer1IdleMask, eax
    ;#### player1 idle shot
    invoke LoadBitmap, hInstance, RC_PLAYER1_IDLESHOT
    mov hPlayer1IdleShot, eax
    ;#### player1 idle shot mask
    invoke LoadBitmap, hInstance, RC_PLAYER1_IDLESHOTMASK
    mov hPlayer1IdleShotMask, eax
    ;#### player1 dead
    invoke LoadBitmap, hInstance, RC_PLAYER1_DIE
    mov hPlayer1Dead, eax
    ;#### player1 dead mask
    invoke LoadBitmap, hInstance, RC_PLAYER1_DIEMASK
    mov hPlayer1DeadMask, eax

    ;#### player2
    invoke LoadBitmap, hInstance, RC_PLAYER2
    mov hPlayer2, eax
    ;#### player2Mask
    invoke LoadBitmap, hInstance, RC_PLAYER2MASK
    mov hPlayer2Mask, eax
    ;#### player2 shot
    invoke LoadBitmap, hInstance, RC_PLAYER2_SHOT
    mov hPlayer2Shot, eax
    ;#### player2 shot mask
    invoke LoadBitmap, hInstance, RC_PLAYER2_SHOTMASK
    mov hPlayer2ShotMask, eax
    ;#### player2 idle
    invoke LoadBitmap, hInstance, RC_PLAYER2_IDLE
    mov hPlayer2Idle, eax
    ;#### player2 idle mask
    invoke LoadBitmap, hInstance, RC_PLAYER2_IDLEMASK
    mov hPlayer2IdleMask, eax
    ;#### player2 idle shot
    invoke LoadBitmap, hInstance, RC_PLAYER2_IDLESHOT
    mov hPlayer2IdleShot, eax
    ;#### player2 idle shot mask
    invoke LoadBitmap, hInstance, RC_PLAYER2_IDLESHOTMASK
    mov hPlayer2IdleShotMask, eax
    ;#### player2 dead
    invoke LoadBitmap, hInstance, RC_PLAYER2_DIE
    mov hPlayer2Dead, eax
    ;#### player2 dead mask
    invoke LoadBitmap, hInstance, RC_PLAYER2_DIEMASK
    mov hPlayer2DeadMask, eax

    ;#### Scores
    mov esi, OFFSET hScore
    invoke LoadBitmap, hInstance, RC_SCORE_0
    mov [esi], eax
    add esi, 4
    invoke LoadBitmap, hInstance, RC_SCORE_1
    mov [esi], eax
    add esi, 4
    invoke LoadBitmap, hInstance, RC_SCORE_2
    mov [esi], eax
    add esi, 4
    invoke LoadBitmap, hInstance, RC_SCORE_3
    mov [esi], eax
    add esi, 4
    invoke LoadBitmap, hInstance, RC_SCORE_4
    mov [esi], eax
    add esi, 4
    invoke LoadBitmap, hInstance, RC_SCORE_5
    mov [esi], eax
    
    

    ;#### bullet
    invoke LoadBitmap, hInstance, RC_BULLET
    mov hBullet, eax
    ;#### bullet mask
    invoke LoadBitmap, hInstance, RC_BULLETMASK
    mov hBulletMask, eax
    ;#### bucket
    invoke LoadBitmap, hInstance, RC_BUCKET
    mov hBucket, eax
    ;#### bucket mask
    invoke LoadBitmap, hInstance, RC_BUCKETMASK
    mov hBucketMask, eax
    ;#### stone
    invoke LoadBitmap, hInstance, RC_STONE
    mov hStone, eax
    ;#### stone mask
    invoke LoadBitmap, hInstance, RC_STONEMASK
    mov hStoneMask, eax

    ;#### smoke
    invoke LoadBitmap, hInstance, RC_SMOKE
    mov hSmoke, eax

    ;#### cactus
    invoke LoadBitmap, hInstance, RC_CACTUS
    mov hCactus, eax
    ;#### cactus mask
    invoke LoadBitmap, hInstance, RC_CACTUSMASK
    mov hCactusMask, eax
    ;#### cactus gone 
    invoke LoadBitmap, hInstance, RC_CACTUSGONE
    mov hCactusGone, eax
    ;#### cactus gone mask
    invoke LoadBitmap, hInstance, RC_CACTUSGONEMASK
    mov hCactusGoneMask, eax

    ;#### reseticon
    invoke LoadBitmap, hInstance, RC_RESET
    mov hReset, eax

    ;#### win title
    invoke LoadBitmap, hInstance, RC_WIN
    mov hUWin, eax 

    ;#### lose title
    invoke LoadBitmap, hInstance, RC_LOSE
    mov hLose, eax

    ret
    
LoadGraphics endp

; #########################################################################

Paint_Proc proc

    LOCAL memDC:DWORD
    LOCAL hBmp:DWORD

    pushad

	invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke CreateCompatibleBitmap, hDC, WindowWidth, WindowHeight
    mov hBmp, eax

    invoke SelectObject, memDC, hBmp

    m2m hDC2, memDC

    ;#### Paint BackGround
    invoke PaintBMP, hBmpBackround, 0, 0, WindowWidth, WindowHeight

    ;#### Paint Scores
    .if GameStatus < 3
	mov esi, OFFSET  players.Players[0]
	mov edi, esi
	add edi, SIZEOF Player
	mov eax, (Player PTR [esi]).lives
	mov ebx, (Player PTR [edi]).lives
	sub eax, 5
	neg eax
	sub ebx, 5
	neg ebx
	mov ecx, 4
	mul ecx
	mov esi, OFFSET hScore
	add esi, eax
	invoke PaintBMP, [esi], ScorePanel2PositionX, ScorePanelPositionY, ScorePanelWidth, ScorePanelHeight
	mov eax, ebx
	mul ecx
	mov esi, OFFSET hScore
	add esi, eax
	invoke PaintBMP, [esi], ScorePanel1PositionX, ScorePanelPositionY, ScorePanelWidth, ScorePanelHeight
    .endif

    ;#### Paint player1
    mov ecx, 2

    mov ebx, OFFSET (players.Players)[0]
L1:
    ;#### chose image handle for player given its state
    mov eax, (Player PTR [ebx]).state
    ;### for player1
    .if ecx == 2
    ;## if normal
	.if eax == 0
	    m2m (Player PTR [ebx]).hPlayer, hPlayer1
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer1Mask
	    m2m (Player PTR [ebx]).playerWidth, PlayerWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerHeight
	;## if player are idle
	.elseif eax == 1
	    m2m (Player PTR [ebx]).hPlayer, hPlayer1Idle
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer1IdleMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerIdleWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerIdleHeight
	;## if player got shot
	.elseif eax == 2
	    m2m (Player PTR [ebx]).hPlayer, hPlayer1Shot
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer1ShotMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerHeight
	;## if player got idle shot
	.elseif eax == 3
	    m2m (Player PTR [ebx]).hPlayer, hPlayer1IdleShot
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer1IdleShotMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerIdleWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerIdleHeight
	;## if dead
	.elseif eax == 4
	    m2m (Player PTR [ebx]).hPlayer, hPlayer1Dead
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer1DeadMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerDeadWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerDeadHeight
	.endif
	;### for player2
	.elseif ecx == 1
	;## if normal
	.if eax == 0
	    m2m (Player PTR [ebx]).hPlayer, hPlayer2
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer2Mask
	    m2m (Player PTR [ebx]).playerWidth, PlayerWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerHeight
	;## if player is idle
	.elseif eax == 1
	    m2m (Player PTR [ebx]).hPlayer, hPlayer2Idle
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer2IdleMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerIdleWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerIdleHeight
	;## if player got shot
	.elseif eax == 2
	    m2m (Player PTR [ebx]).hPlayer, hPlayer2Shot
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer2ShotMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerHeight
	;## if player got idle shot
	.elseif eax == 3
	    m2m (Player PTR [ebx]).hPlayer, hPlayer2IdleShot
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer2IdleShotMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerIdleWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerIdleHeight
	;## if dead
	.elseif eax == 4
	    m2m (Player PTR [ebx]).hPlayer, hPlayer2Dead
	    m2m (Player PTR [ebx]).hPlayerMask, hPlayer2DeadMask
	    m2m (Player PTR [ebx]).playerWidth, PlayerDeadWidth
	    m2m (Player PTR [ebx]).playerHeight, PlayerDeadHeight
	.endif
    .endif

    invoke PaintBMPMask,
        (Player PTR [ebx]).hPlayer,
        (Player PTR [ebx]).hPlayerMask,
        (Player PTR [ebx]).p_x,
        (Player PTR [ebx]).p_y,
        (Player PTR [ebx]).playerWidth,
        (Player PTR [ebx]).playerHeight
    add ebx, SIZEOF Player
    
    dec ecx
    .if ecx > 0
	jmp L1
    .endif

    ;#### Paint bullets
    mov ecx, bullets.len
    mov ebx, OFFSET bullets.Bullets[0]
    .while ecx > 0
    ;### choose direction of the bullet
    mov eax, (Bullet PTR [ebx]).speed_x
    mov edx, (Bullet PTR [ebx]).speed_y
    ;## x direction is positive
    .if eax > 0 && eax < 4000
	.if edx > 0 && edx < 4000
	    mov eax, 4
	.elseif edx == 0
	    mov eax, 3
	.else 
	    mov eax, 2
	.endif
    .else
	.if edx == 0
	    mov eax, 0
	.elseif edx > 0 && edx < 4000
	    mov eax, 5
	.else
	    mov eax, 1
	.endif
    .endif
    mov edx, BulletWidth
    mul edx
	
        invoke PaintBMPMaskEx,
			hBullet,
			hBulletMask,
            (Bullet PTR [ebx]).b_x,
            (Bullet PTR [ebx]).b_y,
			BulletWidth,
			BulletHeight,
			eax,
			0
        add ebx, SIZEOF Bullet
        dec ecx
    .endw

    ;#### Paint Smoke
    mov ecx, cloud.len
    mov ebx, OFFSET cloud.smoke[0]

    .while ecx > 0
		mov eax, (Smoke PTR [ebx]).stage
		mul smokeWidth
        invoke PaintBMPEx, hSmoke,
            (Smoke PTR [ebx]).smoke_x,
            (Smoke PTR [ebx]).smoke_y,
            smokeWidth, smokeHeight,
			eax, 0
        add ebx, SIZEOF Smoke
        dec ecx
    .endw

    ;#### Paint Item
    mov ecx, 14
    mov esi, OFFSET items.Items[0]

    .while ecx > 0
	mov eax, (Item PTR [esi]).state
	mov ebx, (Item PTR [esi]).itemWidth
	mul ebx
	mov edx, (Item PTR [esi]).category
	.if edx == CACTUS
	    mov edx, CacusOffsetY
	    mov ebx, CacusOffsetX
	.elseif edx == STONE
	    add edx, StoneOffsetX
	    mov ebx, StoneOffsetY
	.elseif edx == BUCKET
	    add edx, BucketOffsetX
	    mov ebx, BucketOffsetY
	.endif
	sub (Item PTR [esi]).i_x, ebx
	sub (Item PTR [esi]).i_y, edx
	invoke PaintBMPMaskEx, (Item PTR [esi]).hItem,
	    (Item PTR [esi]).hItemMask,
	    (Item PTR [esi]).i_x,
	    (Item PTR [esi]).i_y,
	    (Item PTR [esi]).itemWidth,
	    (Item pTR [esi]).itemHeight,
	    eax,
	    0
	add (Item PTR [esi]).i_x, ebx
	add (Item PTR [esi]).i_y, edx
	add esi, SIZEOF Item
	dec ecx
    .endw

    ;#### Paint reset title
    .if GameStatus > 2
	invoke PaintBMP, hReset, ResetPositionX, ResetPositionY, ResetWidth, ResetHeight
	.if GameStatus == 3 ;blue player win
	    invoke PaintBMP, hUWin, BlueWinPositionX, BlueWinPositionY, WinWidth, WinHeight
	    invoke PaintBMP, hLose, RedLosePositionX, RedLosePositionY, LoseWidth, LoseHeight
	.elseif GameStatus == 4 ;red player win
	    invoke PaintBMP, hUWin, RedWinPositionX, RedWinPositionY, WinWidth, WinHeight
	    invoke PaintBMP, hLose, BlueLosePositionX, BlueLosePositionY, LoseWidth,LoseHeight
	.endif
    .endif
	

    popad

    invoke BitBlt,hDC,0,0,WindowWidth,WindowHeight,memDC,0,0,SRCCOPY

    invoke DeleteDC, memDC
    invoke DeleteObject,hBmp

    ret  

Paint_Proc endp

; #########################################################################

PaintBMPEx proc uses ecx edi,
		  BmpHandle :DWORD,
	      PosX :DWORD,
	      PosY :DWORD,
	      BmpW :DWORD,
	      BmpH :DWORD,
		  SrcX :DWORD,
		  SrcY :DWORD

    LOCAL memDC:DWORD

    invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke SelectObject, memDC, BmpHandle
    invoke BitBlt, hDC2, PosX, PosY, BmpW, BmpH, memDC, SrcX, SrcY, SRCCOPY
    invoke DeleteDC, memDC

    mov eax, 0
	ret

PaintBMPEx endp

; #########################################################################

PaintBMP proc uses ecx edi,
		  BmpHandle :DWORD,
	      PosX :DWORD,
	      PosY :DWORD,
	      BmpW :DWORD,
	      BmpH :DWORD,

    LOCAL memDC:DWORD

    invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke SelectObject, memDC, BmpHandle
    invoke BitBlt, hDC2, PosX, PosY, BmpW, BmpH, memDC, 0, 0, SRCCOPY
    invoke DeleteDC, memDC

    mov eax, 0
	ret

PaintBMP endp

; #########################################################################

ResetGame proc
    mov GameStatus, 1
    
    mov esi, OFFSET players.Players[0]
    mov edi, SIZEOF Player
    add edi, esi
    mov (Player PTR [esi]).state, 0
    mov (Player PTR [esi]).lives, 5
    mov (Player PTR [edi]).state, 0
    mov (Player PTR [edi]).lives, 5

    mov MusicTimer, 1

    mov bullets.len, 0
    mov cloud.len, 0

    invoke SetupScene

    ret

ResetGame endp
    
; #########################################################################

GameTimer proc
    pushad
    
    .if GameStatus == 1
	invoke RefreshState
	invoke MoveBullets
	invoke MoveSmoke
	invoke MovePlayers
	invoke BulletCollide
	invoke AnimFunc
	invoke SetItems
    .elseif GameStatus == 0
		invoke ResetGame
    .elseif GameStatus > 2
		.if MusicTimer > 0
			invoke sndPlaySound, addr finishMini, SND_ASYNC
			dec MusicTimer
		.endif
    .endif

    popad
    ret
GameTimer endp

; #########################################################################
; Check if each bullet collide into items

BulletCollide proc

    pushad

    mov ecx, bullets.len
    mov esi, 0
    .while ecx > 0
	invoke DetectCollision, esi 
	mov eax, CollisionDetect

	; collide into items
	.if eax >= 0 && eax <= 13
	    mov ebx, SIZEOF Item
	    mul ebx
	    mov edi, OFFSET items.Items[0]
	    add edi, eax
	    
	    mov eax, (Item PTR [edi]).category
	    .if eax == 1	; cacus
		invoke CollideIntoGrass, esi, CollisionDetect
	    .elseif eax == 2	; bucket 
		invoke CollideIntoTrash, esi, CollisionDetect
	    .elseif eax == 3	; stone 
		invoke CollideIntoStone, esi, CollisionDetect
	    .endif
	
	; collide into players1
	.elseif eax == 50 
	    invoke CollideIntoPlayers, esi, 0
	; collide into players2
	.elseif eax == 51
	    invoke CollideIntoPlayers, esi, 1

	.endif 
	inc esi
	dec ecx
    .endw

    popad
    ret

BulletCollide endp

; #########################################################################
; Deal with animation of the collide

AnimFunc proc

    pushad

    mov esi, OFFSET items.Items[0]
    mov ecx, 14

    L1:
	mov eax, (Item PTR [esi]).state
	mov ebx, (Item PTR [esi]).disappear
	.if eax == 0 && ebx
	    mov (Item PTR [esi]).category, 0
	    mov (Item PTR [esi]).state, ANIMBEGIN
	    mov (Item PTR [esi]).disappear, 0
	.elseif eax == 0
	    mov (Item PTR [esi]).state, ANIMBEGIN
	.elseif eax < ANIMBEGIN
	    dec (Item PTR [esi]).state
	.endif
	add esi, SIZEOF Item
	Loop L1
	    

    popad
    ret

AnimFunc endp

; #########################################################################
; Refresh the state of the game
; Apply all the change only when players are both idle
; and there is no bulllet on the screen
; Exception: remove the got shot state instantly

RefreshState proc

    pushad

    mov edi, OFFSET players.Players[0]
    mov esi, SIZEOF Player
    add esi, edi

    mov eax, (Player PTR [edi]).state
    mov ebx, (Player PTR [esi]).state
    mov ecx, (Player PTR [edi]).remainAni
    mov edx, (Player PTR [esi]).remainAni
    ; remove the got shot state
    ; remain the state for 3 time slot
    .if eax == 2 || eax == 3
	.if ecx > 0
	    dec (Player PTR [edi]).remainAni
	.else
	    sub (Player PTR [edi]).state, 2
	.endif
    .endif
    .if ebx == 2 || ebx == 3
	.if edx > 0
	    dec (Player PTR [esi]).remainAni
	.else
	    sub (Player PTR [esi]).state, 2
	.endif
    .endif

    mov ecx, bullets.len
    .if ecx != 0
	jmp Fin
    .endif
    
    ;#### Reload the gun if two players are idle

    .if eax == 1 && ebx == 1 
	mov (Player PTR [edi]).state, 0
	mov (Player PTR [esi]).state, 0		
    .else 
	jmp Fin
    .endif

    ;#### Random a missed item
    ;#### mostly it will be a cacus
    mov ecx, 14
    mov esi, OFFSET items.Items[0]

    L1:
	mov ebx, (Item PTR [esi]).category
	.if ebx == 0
	    push ecx
	    invoke FakeRandom, 3
	    pop ecx
	    .if eax == 0
		mov (Item PTR [esi]).category, 2
	    .elseif eax == 1
		mov (Item PTR [esi]).category, 3
	    .else 
		mov (Item PTR [esi]).category, 1
	    .endif
	.endif
	add esi, SIZEOF Item
	Loop L1

Fin:
    popad
    ret

RefreshState endp

; #########################################################################

MoveSmoke proc
        LOCAL stage :DWORD
    pushad

    mov ecx, cloud.len
    mov edi, OFFSET cloud.smoke

    .while ecx > 0
        mov eax, (Smoke PTR [edi]).smoke_x
        mov ebx, (Smoke PTR [edi]).smoke_y
        mov edx, (Smoke PTR [edi]).stage
        mov stage, edx
        ; check if the particle is out of range
        .if (eax < PlaygroundLeft) || (eax > PlaygroundRight) \
                || (edx == 0)
                ; TODO
            mov esi, OFFSET cloud.smoke
            mov eax, cloud.len
            dec eax
			mov ebx, SIZEOF Smoke
            mul ebx
            add esi, eax

            m2m (Smoke PTR [edi]).smoke_x, (Smoke PTR [esi]).smoke_x
            m2m (Smoke PTR [edi]).smoke_y, (Smoke PTR [esi]).smoke_y
            m2m (Smoke PTR [edi]).speed_x, (Smoke PTR [esi]).speed_x
            m2m (Smoke PTR [edi]).speed_y, (Smoke PTR [esi]).speed_y
            m2m (Smoke PTR [edi]).stage, (Smoke PTR [esi]).stage

            dec cloud.len

            jmp Con
        .endif

		shr edx, 2
        mov edx, (Smoke PTR [edi]).speed_x
        .if edx < 0fffffffh
            sub edx, SmokeSpeedDecay
            add eax, stage
        .elseif edx > 0fffffffh
            add edx, SmokeSpeedDecay
            sub eax, stage
        .endif
		mov (Smoke PTR [edi]).speed_x, edx

        mov edx, (Smoke PTR [edi]).speed_y
        .if edx < 0fffffffh
            sub edx, SmokeSpeedDecay
            add ebx, stage
        .elseif edx > 0fffffffh
            add edx, SmokeSpeedDecay
            sub ebx, stage
        .endif
        mov (Smoke PTR [edi]).speed_y, edx

        mov (Smoke PTR [edi]).smoke_x, eax
        mov (Smoke PTR [edi]).smoke_y, ebx
        dec (Smoke PTR [edi]).stage

        add edi, SIZEOF Smoke
Con:
        dec ecx
    .endw

    popad
    ret

MoveSmoke endp

; #########################################################################

MoveBullets proc
    pushad
    mov ecx, bullets.len
    mov edi, OFFSET bullets.Bullets[0]

	.while ecx > 0
		mov eax, (Bullet PTR [edi]).b_x
        .if (eax > BulletOutrangeR) || (eax < BulletOutrangeL)
            ; check if the bullet is out of range
            mov esi, OFFSET bullets.Bullets[0]
            mov eax, SIZEOF Bullet
	    mov ebx, bullets.len
	    dec ebx
            mul ebx
            add esi, eax

	    ;################################
	    ; delete the outrange bullet and move the 
	    ; data of the tail of the bullet array to delete-position
	    ;################################
            m2m (Bullet PTR [edi]).hBullet, (Bullet PTR [esi]).hBullet
            m2m (Bullet PTR [edi]).b_x, (Bullet PTR [esi]).b_x

            m2m (Bullet PTR [edi]).b_y, (Bullet PTR [esi]).b_y
            m2m (Bullet PTR [edi]).speed_x, (Bullet PTR [esi]).speed_x
            m2m (Bullet PTR [edi]).speed_y, (Bullet PTR [esi]).speed_y
            dec bullets.len

            jmp Con

        .endif

		add eax, (Bullet PTR [edi]).speed_x
		mov (Bullet PTR [edi]).b_x, eax

		mov eax, (Bullet PTR [edi]).b_y
        mov ebx, (Bullet PTR [edi]).speed_y
		add eax, ebx
        .if (eax < PlaygroundTop) || (eax > PlaygroundBottom)
            ; if the bullet hit the top or the bottom
            neg ebx
            mov (Bullet PTR [edi]).speed_y, ebx
	    add eax, ebx
	    add eax, ebx
	    pushad
	    invoke sndPlaySound, addr cacusMini, SND_ASYNC
	    popad
        .endif

		mov (Bullet PTR [edi]).b_y, eax


        invoke AddSmoke,
                (Bullet PTR [edi]).b_x,
                eax,
                (Bullet PTR [edi]).speed_x, 
                (Bullet PTR [edi]).speed_y

        add edi, SIZEOF Bullet
Con:
		dec ecx
    .endw

    popad
    ret

MoveBullets endp

; #########################################################################

AddSmoke proc start_x :DWORD, start_y :DWORD, direction_x :DWORD, direction_y :DWORD
    pushad

    ; add smoke cubes
    mov eax, cloud.len

    .if eax > 195
        jmp Fin
    .endif
	mov ebx, SIZEOF Smoke
    mul ebx
    mov edi, OFFSET cloud.smoke[0]
    add edi, eax

    mov ecx, 1
    .while ecx > 0
		m2m (Smoke PTR [edi]).stage, BulletStageNumber
        mov eax, direction_y
        mov (Smoke PTR [edi]).speed_y, eax
		mov eax, direction_x
        mov (Smoke PTR [edi]).speed_x, eax

        mov ebx, start_x
        mov edx, start_y
		.if eax > 0fffffffh
            mov eax, direction_y
            .if eax > 0fffffffh
                add ebx, 28
                add edx, 28
            .elseif eax == 0
                add ebx, BulletWidth
                add edx, 12
            .else
                add ebx, 28
                ; add edx, 4
            .endif
		.else
            mov eax, direction_y
			.if eax > 0fffffffh
                ; add ebx, 4
                add edx, 28
            .elseif eax == 0
                add edx, 12 
            .else
                ;add ebx, 4
                ;add edx, 4
            .endif
		.endif
        mov (Smoke PTR [edi]).smoke_y, edx
        mov (Smoke PTR [edi]).smoke_x, ebx

        add edi, SIZEOF Smoke
		inc cloud.len
        dec ecx
    .endw

Fin:
    popad
    ret

AddSmoke endp

; #########################################################################

FireBullet  proc player :DWORD
    pushad
    mov edi, OFFSET bullets.Bullets[0]
    mov eax, SIZEOF Bullet
    mul bullets.len
    add edi, eax

    .if player == 0
	mov ecx, offset players.Players[0]
	mov ebx, (Player PTR [ecx]).state

	mov eax, Player1Position
	add eax, PlayerWidth
	m2m (Bullet PTR [edi]).speed_x, BulletInitSpeed
	mov (Player PTR [ecx]).state, 1
    .else
	mov ecx, offset players.Players[SIZEOF Player]
	mov ebx, (Player PTR [ecx]).state

	mov eax, Player2Position
	sub eax, BulletWidth
	m2m (Bullet PTR [edi]).speed_x, BulletInitSpeed
	neg (Bullet PTR [edi]).speed_x
	mov (Player PTR [ecx]).state, 1
    .endif

    mov (Bullet PTR [edi]).speed_y, 0

    mov (Bullet PTR [edi]).b_x, eax

    mov eax, (Player PTR [ecx]).p_y
    add eax, PlayerGunHeight
    mov (Bullet PTR [edi]).b_y, eax

    inc bullets.len
    invoke sndPlaySound, addr shootMini, SND_ASYNC

Fin:
    popad
    ret
FireBullet  endp

; #########################################################################

MovePlayers proc uses ebx edi ecx
	mov edi, OFFSET players.Players[0]
	mov ecx, 2

L1: 
	mov eax, (Player PTR [edi]).speed
       mov ebx, (Player PTR [edi]).p_y
	add ebx, eax
	.if (ebx < PlaygroundTop) || (ebx > PlaygroundBottom)
		neg eax
		mov (Player PTR [edi]).speed, eax
		add ebx, eax
		add ebx, eax
	.endif
	mov (Player PTR [edi]).p_y, ebx
	add edi, SIZEOF Player
	loop L1

	ret
MovePlayers endp

; ######################################################################### 

SetItems proc

    pushad

    mov esi, OFFSET items.Items[0]
    mov items.len, 0
    mov ecx, 14

L1:
    mov eax, (Item PTR [esi]).category
    mov ebx, (Item PTR [esi]).disappear
    .if eax == 0
	mov (Item PTR [esi]).hItem, 0
	mov (Item PTR [esi]).hItemMask, 0
	m2m (Item PTR [esi]).itemWidth, 0
	m2m (Item PTR [esi]).itemHeight, 0
    .elseif eax == CACTUS
	.if ebx
	    m2m (Item PTR [esi]).hItem, hCactusGone
	    m2m (Item PTR [esi]).hItemMask, hCactusGoneMask
	.else
	    m2m (Item PTR [esi]).hItem, hCactus
	    m2m (Item PTR [esi]).hItemMask, hCactusMask
	.endif
	m2m (Item PTR [esi]).itemWidth, CactusWidth
	m2m (Item PTR [esi]).itemHeight, CactusHeight
	inc items.len
    .elseif eax == BUCKET
	m2m (Item PTR [esi]).hItem, hBucket
	m2m (Item PTR [esi]).hItemMask, hBucketMask
	m2m (Item PTR [esi]).itemWidth, BucketWidth
	m2m (Item PTR [esi]).itemHeight, BucketHeight
	inc items.len
    .elseif eax == STONE
	m2m (Item PTR [esi]).hItem, hStone
	m2m (Item PTR [esi]).hItemMask, hStoneMask
	m2m (Item PTR [esi]).itemWidth, StoneWidth
	m2m (Item PTR [esi]).itemHeight, StoneHeight
	inc items.len
    .endif
    add esi, SIZEOF Item
    dec ecx
    .if ecx > 0
	jmp L1
    .endif

    popad
    ret

SetItems endp

; ######################################################################### 
TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    mov eax, sDim
	ret

TopXY endp

; ######################################################################### 

PaintBMPMask proc BmpHandle:DWORD,
            BmpHandleMask:DWORD, 
            PosX:DWORD,
            PosY:DWORD,
            BmpW:DWORD,
            BmpH:DWORD
    

    LOCAL memDC:DWORD

    pushad

    invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke SelectObject, memDC, BmpHandleMask
    invoke BitBlt, hDC2, PosX, PosY, BmpW, BmpH, memDC, 0, 0, SRCAND
    invoke SelectObject, memDC, BmpHandle
    invoke BitBlt, hDC2, PosX, PosY, BmpW, BmpH, memDC, 0, 0, SRCPAINT

    invoke DeleteDC, memDC

    popad

    return 0

PaintBMPMask endp

; ######################################################################### 

PaintBMPMaskEx proc BmpHandle:DWORD, 
		    BmpHandleMask:DWORD,
		    PosX:DWORD,
		    PosY:DWORD,
		    BmpW:DWORD,
		    BmpH:DWORD,
		    SrcX:DWORD,
		    SrcY:DWORD

    LOCAL memDC:DWORD

    pushad


    invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke SelectObject, memDC, BmpHandleMask
    invoke BitBlt, hDC2, PosX, PosY, BmpW, BmpH, memDC, SrcX, SrcY, SRCAND
    invoke SelectObject, memDC, BmpHandle
    invoke BitBlt, hDC2, PosX, PosY, BmpW, BmpH, memDC, SrcX, SrcY, SRCPAINT

    invoke DeleteDC, memDC

    popad

    return 0

PaintBMPMaskEx endp

; ######################################################################### 
; return the index of the collision thing

DetectCollision PROC bulletNum:DWORD

    pushad
    mov ecx, 14
    mov edi, OFFSET items.Items[0]
	mov esi, OFFSET bullets.Bullets[0]
    mov eax, bulletNum
    mov ebx, SIZEOF Bullet
    mul ebx
    add esi, eax

    ; check if bullet collide some items
    .while ecx > 0
	mov eax, (Item PTR [edi]).category
	mov ebx, (Item PTR [edi]).state
	.if eax > 0 && ebx == ANIMBEGIN
	    push ecx
	    mov ebx, (Item PTR [edi]).i_x
	    mov edx, (Item PTR [edi]).i_y
	    mov eax, (Bullet PTR [esi]).b_x
	    add eax, 18
	    mov ecx, (Bullet PTR [esi]).b_y
	    add ecx, 9
	    .if (eax >= ebx) && (ecx >= edx)
		add ebx, 30
		add edx, 60
		.if (eax <= ebx) && (ecx <= edx)
		    pop ecx
		    mov eax, ecx
		    sub eax, 14
		    neg eax
		    jmp Fin
		.else 
		    pop ecx
		.endif
	    .else 
		pop ecx
	    .endif
	.endif
        add edi,SIZEOF Item
	dec ecx
    .endw

    ; check if bullet collide the player1
    mov edi, OFFSET players.Players[0]
    mov ebx, (Player PTR [edi]).p_x
    mov edx, (Player PTR [edi]).p_y
    mov eax, (Bullet PTR [esi]).b_x
    add eax, 18
    mov ecx, (Bullet PTR [esi]).b_y
    add ecx, 9
    .if (eax >= ebx) && (ecx >= edx)
	add ebx, (Player PTR [edi]).playerWidth
	add edx, (Player PTR [edi]).playerHeight
	.if (eax <= ebx) && (ecx <= edx)
	    mov eax, Player1Shot
	    jmp Fin
	.endif
    .endif

    ; check if bullet collide the player2
    mov edi, OFFSET players.Players[0]
    add edi, SIZEOF Player
    mov ebx, (Player PTR [edi]).p_x
    mov edx, (Player PTR [edi]).p_y
    mov eax, (Bullet PTR [esi]).b_x
    add eax, 18
    mov ecx, (Bullet PTR [esi]).b_y
    add ecx, 9
    .if (eax >= ebx) && (ecx >= edx)
	add ebx, (Player PTR [edi]).playerWidth
	add edx, (Player PTR [edi]).playerHeight
	.if (eax <= ebx) && (ecx <= edx)
	    mov eax, Player2Shot
	    jmp Fin
	.endif
    .endif
NoCollisonDetected:
    mov eax,NoCollisionDetected

Fin:
    mov CollisionDetect,eax
    popad
    ret

DetectCollision ENDP

; ######################################################################### 

CollideIntoTrash PROC bulletNum:DWORD,itemNum:DWORD
    pushad
    mov edi,OFFSET items.Items[0]
    mov eax,itemNum
    mov ebx,SIZEOF Item
    mul ebx
    add edi,eax
    mov esi,OFFSET bullets.Bullets[0]
    mov eax,bulletNum
    mov ebx,SIZEOF Bullet
    mul ebx
    add esi,eax
    mov ecx,TrashSlowDown


    ; slow down the bullet
    mov edx,(Bullet PTR [esi]).speed_x
    .if edx > 0 && edx < 4000
        mov (Bullet PTR [esi]).speed_x,ecx
    .elseif edx > 4000
        neg ecx
        mov (Bullet PTR [esi]).speed_x,ecx
        neg ecx
    .endif

    mov edx,(Bullet PTR [esi]).speed_y
    .if edx > 0 && edx < 4000
        mov (Bullet PTR [esi]).speed_y,ecx
    .elseif edx > 4000
        neg ecx
        mov (Bullet PTR [esi]).speed_y,ecx
        neg ecx
    .endif

    dec (Item PTR [edi]).state
    mov (Item PTR [edi]).disappear, 1

    invoke sndPlaySound, addr bucketMini, SND_ASYNC
    
    popad
    ret
CollideIntoTrash ENDP

; ######################################################################### 

CollideIntoGrass PROC bulletNum:DWORD,itemNum:DWORD
    pushad
    mov edi,OFFSET items.Items[0]
    mov eax,itemNum
    mov ebx,SIZEOF Item
    mul ebx
    add edi,eax
    mov esi,OFFSET bullets.Bullets[0]
    mov eax,bulletNum
    mov ebx,SIZEOF Bullet
    mul ebx
    add esi,eax

    ; change the direction of bullet randomly
    invoke FakeRandom,0FFFFFFFFh
    mov edx, 0
    mov ecx,5
    div ecx

    ; 0 is opposite direction
    .if edx == 0
        mov ebx,(Bullet PTR [esi]).speed_x
        neg ebx
        mov (Bullet PTR [esi]).speed_x,ebx
        mov (Bullet PTR [esi]).speed_y,0
        jmp Fin
    .endif
    ; 1 is right down
    .if edx == 1
        mov ebx,(Bullet PTR [esi]).speed_x
        neg ebx
        mov (Bullet PTR [esi]).speed_x,ebx
        mov ebx,(Bullet PTR [esi]).speed_y
		.if ebx == 0
        mov ebx,BulletInitSpeed
        mov (Bullet PTR [esi]).speed_y,ebx
		.endif
        jmp Fin
    .endif
    ; 2 is left down
    .if edx == 2
		mov ebx,(Bullet PTR [esi]).speed_y
		.if ebx == 0
        mov ebx,BulletInitSpeed
        mov (Bullet PTR [esi]).speed_y,ebx
		.endif
        jmp Fin
    .endif
    ; 3 is left up
    .if edx == 3
        mov ebx,(Bullet PTR [esi]).speed_y
		.if ebx == 0
		mov ebx,BulletInitSpeed
        neg ebx
        mov (Bullet PTR [esi]).speed_y,ebx
		.else
		neg ebx
        mov (Bullet PTR [esi]).speed_y,ebx
		.endif
        jmp Fin
    .endif
    ; 4 is right up
    .if edx == 4
		mov ebx,(Bullet PTR [esi]).speed_y
		.if ebx == 0
        mov ebx,BulletInitSpeed
        neg ebx
        mov (Bullet PTR [esi]).speed_y,ebx
		.else
        neg ebx
        mov (Bullet PTR [esi]).speed_y,ebx
		.endif
        mov ebx,(Bullet PTR [esi]).speed_x
        neg ebx
        mov (Bullet PTR [esi]).speed_x,ebx
        jmp Fin
    .endif

Fin:
    mov ecx,BulletSpeedUp
    mov edx,(Bullet PTR [esi]).speed_x
    .if edx > 0 && edx < 4000
        add edx,ecx
        mov (Bullet PTR [esi]).speed_x,edx
    .elseif edx > 4000
        sub edx,ecx
        mov (Bullet PTR [esi]).speed_x,edx
    .else
    .endif

    mov edx,(Bullet PTR [esi]).speed_y
    .if edx > 0 && edx < 4000
        add edx,ecx
        mov (Bullet PTR [esi]).speed_x,edx
    .elseif edx > 4000
        sub edx,ecx
        mov (Bullet PTR [esi]).speed_x,edx
    .else

    .endif
    ;decide whether clear the grass
    invoke FakeRandom, 3
    .if eax == 0
       mov (Item PTR [edi]).disappear,1
    .endif

    dec (Item PTR [edi]).state

    invoke sndPlaySound, addr cacusMini, SND_ASYNC
    popad
    ret
CollideIntoGrass ENDP

; ######################################################################### 

CollideIntoStone PROC bulletNum:DWORD,itemNum:DWORD
LOCAL temp_x:DWORD, temp_y:DWORD
    pushad
    mov edi,OFFSET items.Items[0]
    mov eax,itemNum
    mov ebx,SIZEOF Item
    mul ebx
    add edi,eax
    mov esi,OFFSET bullets.Bullets[0]
    mov eax,bulletNum
    mov ebx,SIZEOF Bullet
    mul ebx
    add esi,eax
    mov ecx,(Bullet PTR [esi]).speed_x
	m2m temp_x,(Bullet PTR [esi]).b_x
	m2m temp_y,(Bullet PTR [esi]).b_y

    mov edx,BulletInitSpeed
    mov (Bullet PTR [esi]).speed_y,edx

    ; new bullet
    inc bullets.len
    mov esi,OFFSET bullets.Bullets[0]
	mov eax, bullets.len
	dec eax
	mov ebx, SIZEOF Bullet
	mul ebx
	add esi, eax
    mov (Bullet PTR [esi]).speed_x,ecx
    mov edx,BulletInitSpeed
    neg edx
    mov (Bullet PTR [esi]).speed_y,edx
	m2m (Bullet PTR [esi]).b_x,temp_x
	m2m (Bullet PTR [esi]).b_y,temp_y


    dec (Item PTR [edi]).state
    mov (Item PTR [edi]).disappear, 1

    invoke sndPlaySound, addr stoneMini, SND_ASYNC    

    popad
    ret
CollideIntoStone ENDP

; ######################################################################### 

CollideIntoPlayers PROC bulletNum:DWORD,playerNum:DWORD
    pushad

    ; clear the bullet
    mov edi,OFFSET bullets.Bullets[0]
    mov eax,bulletNum
    mov ebx,SIZEOF Bullet
    mul ebx
    add edi,eax

    mov esi, OFFSET bullets.Bullets[0]
    mov eax, SIZEOF Bullet
    mov ebx, bullets.len
    dec ebx
    mul ebx
    add esi, eax

    m2m (Bullet PTR [edi]).hBullet, (Bullet PTR [esi]).hBullet
    m2m (Bullet PTR [edi]).hBulletMask, (Bullet PTR [esi]).hBulletMask
    m2m (Bullet PTR [edi]).b_x, (Bullet PTR [esi]).b_x
    m2m (Bullet PTR [edi]).b_y, (Bullet PTR [esi]).b_y
    m2m (Bullet PTR [edi]).speed_x, (Bullet PTR [esi]).speed_x
    m2m (Bullet PTR [edi]).speed_y, (Bullet PTR [esi]).speed_y
    dec bullets.len

    ; decrease player's lives
    mov edi,OFFSET players.Players[0]
    mov eax,playerNum
    mov ebx,SIZEOF Player
    mul ebx
    add edi,eax
    dec (Player PTR [edi]).lives

    ; change player's state
    mov eax, (Player PTR [edi]).lives
    .if eax == 0
	mov (Player PTR [edi]).state, 4
	.if playerNum == 0	    ; player2 win
	    mov GameStatus, 4
	.else			    ; player1 win
	    mov GameStatus, 3
	.endif

    .else
	mov eax, (Player PTR [edi]).state
	.if eax == 0
	mov (Player PTR [edi]).state, 2
	mov (Player PTR [edi]).remainAni, 3
	.elseif eax == 1
	mov (Player PTR [edi]).state, 3
	mov (Player PTR [edi]).remainAni, 3
	.endif
    .endif



Fin:
    invoke sndPlaySound, addr shotMini, SND_ASYNC
    popad
    ret
CollideIntoPlayers ENDP

; ######################################################################### 

SetupScene proc
        LOCAL m: DWORD
    pushad

    ;#### initiate the position of player
    mov eax, PlaygroundTop
    add eax, PlaygroundBottom
    shr eax, 1
    mov m, eax

    mov edi, OFFSET players.Players[0]
    m2m (Player PTR [edi]).p_x, Player1Position
    m2m (Player PTR [edi]).p_y, m

    add edi, SIZEOF Player
    m2m (Player PTR [edi]).p_x, Player2Position
    m2m (Player PTR [edi]).p_y, m

    ;#### initiate the position of the items
    mov esi, OFFSET ItemX
    mov edi, OFFSET ItemY
    mov ebx, OFFSET items.Items[0]
    mov ecx, 14

    L1:
	m2m (Item PTR [ebx]).i_x, [esi]
	m2m (Item PTR [ebx]).i_y, [edi]
	push ebx
	push ecx
	invoke FakeRandom, 15
	pop ecx
	pop ebx
	.if eax == 1
	    mov (Item PTR [ebx]).category, 3
	.elseif eax == 0
	    mov (Item PTR [ebx]).category, 2
	.else 
		mov (Item PTR [ebx]).category, 1
	.endif
	mov (Item PTR [ebx]).state, ANIMBEGIN

	add esi, 4
	add edi, 4
	add ebx, SIZEOF Item
	Loop L1

    popad
    ret

SetupScene endp

; ########################################################################

FakeRandom proc MaskWord:DWORD
    
    push edi

    ;invoke GetTickCount
    ;mov edi ,MaskWord
    ;and eax,edi

    invoke prand,435345345
    mov edi ,MaskWord
    and eax,edi

    pop edi 
    return eax
FakeRandom Endp

; ########################################################################

;RANDOM ROUTINE FROM http://www.masm32.com/board/index.php?PHPSESSID=b552497e20a62c0d96a7bd80a889b3bb&topic=4895.0

pseed PROC s1:DWORD,s2:DWORD,s3:DWORD,s4:DWORD

    mov eax,s1 ;if s1 = 0 then use default value
    .if eax!=0
        mov seed1,eax
    .endif
    mov eax,s2 ;if s2 = 0 then use default value
    .if eax!=0
        mov seed2,eax
    .endif
    mov eax,s3 ;if s3 = 0 then use default value
    .if eax!=0
        mov seed3,eax
    .endif
    mov eax,s4 ;if s4 = 0 then use default value
    .if eax!=0
        mov seed4,eax
    .endif
    ret

pseed ENDP

; ######################################################################### 

prand PROC base:DWORD
    ;seed1 = AAAABBBB
    ;seed2 = CCCCDDDD
    ;seed3 = EEEEFFFF
    ;seed4 = 11112222

    mov eax,seed1 ;AAAABBBB
    mov ebx,seed2 ;CCCCDDDD
    mov ecx,seed3 ;EEEEFFFF
    mov edx,seed4 ;11112222
    ;start shifting
    xchg ax,bx    ;eax = AAAADDDD, ebx = CCCCBBBB
    xchg cx,dx   ;ecx = EEEE2222, edx = 1111FFFF
    xchg al,cl   ;eax = AAAADD22, ecx = EEEE22DD
    xchg bl,dl   ;ebx = CCCCBBFF, edx = 1111FFBB
    push eax   ;AAAADD22
    push ecx      ;EEEE22DD
    shl eax,8   ;AADD2200
    shr ecx,24   ;000000EE
    add eax,ecx   ;AADD22EE
    mov seed1,eax   ;s1 = AADD22EE
    pop ecx   ;EEEE22DD
    pop eax   ;AAAADD22
    push ecx   ;EEEE22DD
    shr eax,24   ;000000AA
    push edx   ;1111FFBB
    shl edx,8   ;11FFBB00
    add edx,eax   ;11FFBBAA
    mov seed2,edx    ;s2 = 11FFBBAA
    pop edx   ;1111FFBB
    shr edx,24   ;00000011
    push ebx   ;CCCCBBFF
    shl ebx,8   ;CCBBFF11
    mov seed3,ebx   ;s3 = CCBBFF11
    pop ebx   ;CCCCBBFF
    shr ebx,24   ;000000CC
    pop ecx   ;EEEE22DD
    shl ecx,8   ;EE22DD00
    add ecx,ebx   ;EE22DDCC
    mov seed4,ecx    ;s4 = EE22DDCC
    ;start calculating
    mov eax,seed1
    mov ecx,16587
    xor edx,edx
    div ecx   ;AADD22EE / 16587, result in eax, remainder in edx
    mov ebx,seed2    ;11FFBBAA
    xchg ebx,eax 
    sub eax,ebx   ;11FFBBAA - remainder
    mov ecx,edx
    xor edx,edx
    mul ecx
    mov seed2,eax    ;seed2 = (s1 / 16587)*(s2 - (s1 % 16587))

    mov ecx,29753
    xor edx,edx
    div ecx ; (s2 / 29753)
    mov ebx,seed3   ;CCBBFF11
    xchg ebx,eax
    sub eax,ebx  ;CCBBFF11 - remainder
    mov ecx,edx
    xor edx,edx
    mul ecx
    mov seed3,eax   ;seed3 = (s2 / 29753)*(s3 - (s2 % 29753))

    mov ecx,39744
    xor edx,edx
    div ecx ; (s3 / 39744)
    mov ebx,seed4   ;EE22DDCC
    xchg ebx,eax
    sub eax,ebx  ;EE22DDCC - remainder
    mov ecx,edx
    xor edx,edx
    mul ecx
    mov seed4,eax   ;seed4 = (s3 / 39744)*(s4 - (s3 % 39744))

    mov ecx,59721
    xor edx,edx
    div ecx ; (s4 / 59721)
    mov ebx,seed1   ;AADD22EE
    xchg ebx,eax
    sub eax,ebx  ;AADD22EE - remainder
    mov ecx,edx
    xor edx,edx
    mul ecx
    mov seed1,eax   ;seed1 = (s4 / 59721)*(s1 - (s4 % 59721))
    ;use every last byte of each new seed
    shl eax,24
    mov ebx,seed2
    shl ebx,24
    shr ebx,8
    add eax,ebx
    mov ebx,seed3
    shl ebx,24
    shr ebx,16
    add eax,ebx
    mov ebx,seed4
    add al,bl
    mov ebx,seed1
    xor eax,ebx
    xor edx,edx
    div base
    mov eax,edx
    ret

prand ENDP

; ######################################################################### 

END start
