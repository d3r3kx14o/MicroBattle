.386
.model flat, stdcall
option casemap :none

include MicroBattle.inc

; #########################################################################

.code 

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax

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

    m2m Wwd, WindowWidth
    m2m Wht, WindowHeight

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
    	.if wParam == VK_A
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
    	.elseif wParam == VK_L
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

    ;#### player2
    invoke LoadBitmap, hInstance, RC_PLAYER2
    mov hPlayer2, eax
    ;#### player2Mask
    invoke LoadBitmap, hInstance, RC_PLAYER2MASK
    mov hPlayer2Mask, eax

    ;#### bullet
    invoke LoadBitmap, hInstance, RC_BULLET
    mov hBullet, eax
    ;#### bullet mask
    invoke LoadBitmap, hInstance, RC_BULLETMASK
    mov hBulletMask, eax

    ;#### smoke
    invoke LoadBitmap, hInstance, RC_SMOKE
    mov hSmoke, eax

    ret
    
LoadGraphics endp

; #########################################################################

Paint_Proc proc

    LOCAL memDC:DWORD
    LOCAL hBmp:DWORD

	invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke CreateCompatibleBitmap, hDC, WindowWidth, WindowHeight
    mov hBmp, eax

    invoke SelectObject, memDC, hBmp

    m2m hDC2, memDC

    ;#### Paint BackGround
    invoke PaintBMP, hBmpBackround, 0, 0, WindowWidth, WindowHeight
    invoke PaintBMP, hSmoke, 0, 0, 8, 8

    ;#### Paint player1
    push ecx
    push ebx
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
    ;## if player has shot
    ;.elseif eax == 1
    ;## if player got shot
    ;.elseif eax == 2
    ;## if dead
    ;.elseif eax == 3
    .endif
    ;### for player2
    .elseif ecx == 1
    ;## if normal
    .if eax == 0
        m2m (Player PTR [ebx]).hPlayer, hPlayer2
        m2m (Player PTR [ebx]).hPlayerMask, hPlayer2Mask
    ;## if player has shot
    ;.elseif eax == 1
    ;## if player got shot
    ;.elseif eax == 2
    ;## if dead
    ;.elseif eax == 3
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
    loop L1

    ;#### Paint bullets
    mov ecx, bullets.len
    mov ebx, OFFSET bullets.bullets[0]

    .while ecx > 0
        invoke PaintBMPMask,
            (Bullet PTR [ebx]).hBullet,
            hBulletMask,
            (Bullet PTR [ebx]).b_x,
            (Bullet PTR [ebx]).b_y,
            (Bullet PTR [ebx]).bulletWidth,
            (Bullet PTR [ebx]).bulletHeight
        add ebx, SIZEOF Bullet
        dec ecx
    .endw

    ;#### Paint Smoke
    mov ecx, cloud.len
    mov ebx, OFFSET cloud.smoke[0]

    .while ecx > 0
        invoke PaintBMP, hSmoke,
            (Smoke PTR [ebx]).smoke_x,
            (Smoke PTR [ebx]).smoke_y,
            smokeWidth, smokeHeight
        add ebx, SIZEOF Smoke
        dec ecx
    .endw

    pop ebx
    push ecx

    invoke BitBlt,hDC,0,0,WindowWidth,WindowHeight,memDC,0,0,SRCCOPY

    invoke DeleteDC, memDC
    invoke DeleteObject,hBmp

    ret  

Paint_Proc endp

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
    
GameTimer proc
    invoke MoveBullets
    invoke MoveSmoke
	invoke MovePlayers
	ret
GameTimer endp

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
    mov edi, OFFSET bullets.bullets[0]

	.while ecx > 0
		mov eax, (Bullet PTR [edi]).b_x
        .if (eax > PlaygroundRight) || (eax < PlaygroundLeft)
            ; check if the bullet is out of range
            mov esi, OFFSET bullets.bullets[0]
            mov eax, SIZEOF Bullet
			mov ebx, bullets.len
			dec ebx
            mul ebx
            add esi, eax

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
		.if eax > 0fffffffh
			mov ebx, start_x
			add ebx, BulletWidth
			mov (Smoke PTR [edi]).smoke_x, ebx
		.else
			m2m (Smoke PTR [edi]).smoke_x, start_x
		.endif
        m2m (Smoke PTR [edi]).smoke_y, start_y


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
    .if bullets.len == 10
        jmp Fin
    .endif
    invoke sndPlaySound, addr shootMini, SND_ASYNC
    mov edi, OFFSET bullets.bullets[0]
    mov eax, SIZEOF Bullet
    mul bullets.len
    add edi, eax
	.if player == 0
		mov ecx, offset players.Players[0]
        mov eax, PlaygroundLeft
        m2m (Bullet PTR [edi]).speed_x, BulletInitSpeed
	.elseif
		mov ecx, offset players.Players[SIZEOF Player]
        mov eax, PlaygroundRight
        m2m (Bullet PTR [edi]).speed_x, BulletInitSpeed
		neg (Bullet PTR [edi]).speed_x
	.endif

	mov (Bullet PTR [edi]).speed_y, 15

	mov (Bullet PTR [edi]).b_x, eax

    mov eax, (Player PTR [ecx]).p_y
    add eax, PlayerGunHeight
	;mov eax, PlaygroundBottom
    mov (Bullet PTR [edi]).b_y, eax
    m2m (Bullet PTR [edi]).hBullet, hBullet	

    inc bullets.len

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

SetupScene proc
        LOCAL m: DWORD
	pushad

    mov eax, PlaygroundTop
    add eax, PlaygroundBottom
    shr eax, 1
    mov m, eax

	mov edi, OFFSET players.Players[0]
    m2m (Player PTR [edi]).p_x, PlaygroundLeft
    m2m (Player PTR [edi]).p_y, m

    add edi, SIZEOF Player
    m2m (Player PTR [edi]).p_x, PlaygroundRight
    m2m (Player PTR [edi]).p_y, m

	popad
	ret

SetupScene endp

; ######################################################################### 

END start