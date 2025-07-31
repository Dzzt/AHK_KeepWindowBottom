#Requires Aut

; Alacritty target position (adjust to your environment's coordinates)
Global AlacrittyTargetX := 1970
Global AlacrittyTargetY := 30

; Windows API constants
Global GW_HWNDNEXT := 2  ; Retrieves the next window in the Z-order (below)
Global GW_HWNDPREV := 3  ; (Not used in this script)

; ==== Timer Routine to Keep Window at Bottom ====
; Check the operation and adjust to the optimal interval (e.g., 100ms, 200ms, 500ms, 1000ms)
SetTimer KeepAlacrittyBelow, 500 ; Set to 500ms as an example

KeepAlacrittyBelow() {
    try {
        FoundHwnd := 0
        for hwnd in WinGetList("ahk_exe alacritty.exe") {
            WinGetPos(&x, &y, &width, &height, hwnd)
            if (x == AlacrittyTargetX && y == AlacrittyTargetY) {
                FoundHwnd := hwnd
                break
            }
        }

        if (!FoundHwnd) { 
            Return ; Do nothing if window is not found
        }
        
        if (!IsWindowTrulyAtBottom(FoundHwnd)) {
            WinMoveBottom(FoundHwnd)
        } else {
            ; Do nothing (as it's already determined to be at the bottom)
        }

    } catch as e {
        ; Log error only (for integration into other scripts)
        OutputDebug("ERROR: An error occurred in KeepAlacrittyBelow: " . e.Message)
    }
}

; ==== Helper Function: GetNextSignificantWindow (non-IME/non-desktop) ====
; Traverses the Z-order downwards from the given window,
; skipping IME and desktop-related windows,
; and returns the HWND of the first encountered "normal application window".
; Returns 0 if no such window is found.
GetNextSignificantWindow(startHwnd) {
    Local currentHwnd := startHwnd

    ; List of window classes to skip (lowercase)
    ; These windows are considered "transparent" for Z-order determination.
    Local SkipClassesLowerCase := ["ime", "msctfime ui", "progman", "workerw", "shelldll_defview", "#32769", "shell_traywnd"] 

    Loop {
        currentHwnd := DllCall("GetWindow", "Ptr", currentHwnd, "UInt", GW_HWNDNEXT, "Ptr") ; Get the window one level below

        if (currentHwnd == 0) { 
            Return 0
        }

        Local winClass := WinGetClass(currentHwnd)
        Local winTitle := WinGetTitle(currentHwnd) 
        Local trimmedWinClass := StrLower(Trim(winClass))
        
        Local isSkipped := false
        for i, skipClass in SkipClassesLowerCase {
            if (trimmedWinClass == skipClass) {
                isSkipped := true
                break
            }
        }

        if (isSkipped) {
            Continue ; This window should be skipped, so continue searching further down
        }
        
        Return currentHwnd ; A non-skipped (normal application) window was found
    }
}


; ==== Function: Determines if the window is at the "bottommost" of the Z-order ====
; Checks if the window directly below the target window is desktop-related.
IsWindowTrulyAtBottom(hwnd) {
    if (!WinExist(hwnd)) {
        Return true ; If the window does not exist, consider it already at the bottom
    }

    HwndNextSignificant := GetNextSignificantWindow(hwnd)

    if (HwndNextSignificant == 0) {
        Return true ; If no application window is found below it, it's at the bottom
    }
    
    Return false ; An application window is found below it, so it's not at the bottom
}oHotkey v2.0