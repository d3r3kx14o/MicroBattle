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

      LOCAL wc   :WNDCLASSEX
      LOCAL msg  :MSG
      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD

      LOCAL Ps     :PAINTSTRUCT

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

        

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWinL  :DWORD,
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
	return 0
    .elseif uMsg == WM_TIMER
	invoke GameTimer
	invoke RedrawWindow, hWin, NULL, NULL, RDW_INVALIDATE

    .elseif uMsg == WM_KEYDOWN
    	.if wParam == VK_A
	    mov eax, players.Players[0].state
	    .if eax == 0
		invoke sndPlaySound, addr shootMini, SND_ASYNC
	    .endif
	    ;Player 1 presses the key
	    mov eax, players.Players[0].speed
	    neg eax
	    mov players.Players[0].speed, eax
    	.elseif wParam == VK_L
	    mov eax, players.Players[SIZEOF Player].state
	    .if eax == 0
		invoke sndPlaySound, addr shootMini, SND_ASYNC
	    .endif
	    ;Player 2 presses the key
	    mov eax, players.Players[SIZEOF Player].speed
	    neg eax
	    mov players.Players[SIZEOF Player].speed, eax
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

    ret
    
LoadGraphics endp

; #########################################################################

Paint_Proc proc

    LOCAL memDC:DWORD
    LOCAL hBmp:DWORD
	LOCAL playerX: DWORD

invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke CreateCompatibleBitmap, hDC, WindowWidth, WindowHeight
    mov hBmp, eax

    invoke SelectObject, memDC, hBmp

    m2m hDC2, memDC

    ;#### Paint BackGround
    invoke PaintBMP, hBmpBackround, 0, 0, WindowWidth, WindowHeight

    ;#### Paint player1
    push ecx
    push ebx
    mov ecx, 2
    mov playerX, 0
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
		playerX,
        (Player PTR [ebx]).p_y,
        (Player PTR [ebx]).playerWidth,
        (Player PTR [ebx]).playerHeight
    add ebx, SIZEOF Player
    m2m playerX, PlaygroundWidth
    loop L1

    pop ebx
    push ecx

  invoke BitBlt,hDC,0,0,WindowWidth,WindowHeight,memDC,0,0,SRCCOPY

  invoke DeleteDC, memDC
  invoke DeleteObject,hBmp

	ret  

Paint_Proc endp

; #########################################################################

PaintBMP proc uses ecx edi,
		  BmpHandle:DWORD,
	      PosX:DWORD,
	      PosY:DWORD,
	      BmpW:DWORD,
	      BmpH:DWORD,

    LOCAL memDC:DWORD

    invoke CreateCompatibleDC, hDC
    mov memDC, eax

    invoke SelectObject, memDC, BmpHandle
    invoke BitBlt, hDC2, PosX, PosY, BmpW, BmpH, memDC, 0, 0, SRCCOPY
    invoke DeleteDC, memDC

    return 0

PaintBMP endp

; #########################################################################
    
GameTimer proc
	invoke MovePlayers

	ret
GameTimer endp

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


END start
