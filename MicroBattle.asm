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
	mov edi, offset players.Players[0]
    invoke LoadBitmap, hInstance, RC_PLAYER1
    mov (Player PTR [edi]).hPlayer, eax

    ;#### player2
	add edi, SIZEOF Player
    invoke LoadBitmap, hInstance, RC_PLAYER2
    mov (Player PTR [edi]).hPlayer, eax

    ;#### bullet
    invoke LoadBitmap, hInstance, RC_BULLET
    mov hBullet, eax

    ret
    
LoadGraphics endp

; #########################################################################

Paint_Proc proc

    LOCAL memDC     :DWORD
    LOCAL hBmp      :DWORD
	LOCAL playerX   :DWORD

invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke CreateCompatibleBitmap, hDC, WindowWidth, WindowHeight
    mov hBmp, eax

    invoke SelectObject, memDC, hBmp

    m2m hDC2, memDC

    ;#### Paint BackGround
    invoke PaintBMP, hBmpBackround, 0, 0, WindowWidth, WindowHeight

    ;#### Paint players
    push ecx
    push ebx
    mov ecx, 2
    mov playerX, 0
    mov ebx, OFFSET (players.Players)[0]
L1:
    invoke PaintBMP,
        (Player PTR [ebx]).hPlayer,
        playerX,
        (Player PTR [ebx]).p_y,
        (Player PTR [ebx]).playerWidth,
        (Player PTR [ebx]).playerHeight
    add ebx, SIZEOF Player
    m2m playerX, PlaygroundWidth
    loop L1

    ;#### Paint bullets
    mov ecx, bullets.len
    mov ebx, OFFSET bullets.bullets[0]

    .while ecx > 0
        invoke PaintBMP,
            (Bullet PTR [ebx]).hBullet,
            (Bullet PTR [ebx]).b_x,
            (Bullet PTR [ebx]).b_y,
            (Bullet PTR [ebx]).bulletWidth,
            (Bullet PTR [ebx]).bulletHeight
        add ebx, SIZEOF Bullet
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
	invoke MovePlayers
	ret
GameTimer endp

; #########################################################################

MoveBullets proc
    pushad
    mov ecx, bullets.len
    mov edi, OFFSET bullets.bullets[0]

	.while ecx > 0
		mov eax, (Bullet PTR [edi]).b_x
		add eax, (Bullet PTR [edi]).speed_x
		mov (Bullet PTR [edi]).b_x, eax

		mov eax, (Bullet PTR [edi]).b_y
		add eax, (Bullet PTR [edi]).speed_y
		mov (Bullet PTR [edi]).b_y, eax
		dec ecx
    .endw

    popad
    ret

MoveBullets endp

; #########################################################################

FireBullet  proc player :DWORD
    pushad
    mov edi, OFFSET bullets.bullets[0]
    mov eax, SIZEOF Bullet
    mul bullets.len
    add edi, eax
	.if player == 0
		mov ecx, offset players.Players[0]
	.elseif
		mov ecx, offset players.Players[SIZEOF Player]
	.endif

    m2m (Bullet PTR [edi]).hBullet, hBullet
	mov eax, (Player PTR [ecx]).p_y
    mov (Bullet PTR [edi]).b_y, eax
	mov eax, (Player PTR [ecx]).p_x
    mov (Bullet PTR [edi]).b_x, eax
    .if eax > 500
        mov (Bullet PTR [edi]).speed_x, -5
    .endif

    inc bullets.len

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

END start