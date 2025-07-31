#Requires AutoHotkey v2.0

#Requires AutoHotkey v2.0

; Target application
Global TargetWindow := "ahk_exe alacritty.exe"

; Target position of the TargetWindow (adjust to your environment's coordinates)
Global TargetWindowCoordX := 1970
Global TargetWindowCoordY := 30

; Windows API constants
Global GW_HWNDNEXT := 2  ; Retrieves the next window in the Z-order (below)

; Processing frequency
Global Frequency := 50

; ==== Timer Routine to Keep Window at Bottom ====
SetTimer KeepTargetWindowBelow, Frequency 
Return

KeepTargetWindowBelow() {
    try {
        FoundHwnd := 0
        for hwnd in WinGetList(TargetWindow) {
            WinGetPos(&x, &y, &width, &height, hwnd)
            if (x == TargetWindowCoordX && y == TargetWindowCoordY) {
                FoundHwnd := hwnd
                break
            }
        }

        if (!FoundHwnd) { 
            ;OUtputDebug("KeepTargetWindowBelow: [INFO] TargetWindow window not found at specified position. Skipping WinMoveBottom.")
            Return
        } else {
            ;OUtputDebug("KeepTargetWindowBelow: [INFO] TargetWindow window (HWND: " . FoundHwnd . ") found at target position.")
        }
        
        if (!IsWindowTrulyAtBottom(FoundHwnd)) {
            ;OUtputDebug("KeepTargetWindowBelow: [ACTION] TargetWindow is not at the bottommost layer. Calling WinMoveBottom().")
            WinMoveBottom(FoundHwnd)
        } else {
            ; Do nothing (as it's already determined to be at the bottom)
        }

    } catch as e {
        ;OUtputDebug("ERROR: An error occurred in the timer routine (from Catch block): " . e.Message)
    }
}

; ==== Helper Function: Get Next "Meaningful" Window (non-IME/non-desktop) ====
; Traverses the Z-order downwards from the given window,
; skipping IME and desktop-related windows,
; and returns the HWND of the first encountered "normal application window".
; Returns 0 if no such window is found.
GetNextSignificantWindow(startHwnd) {
    Local currentHwnd := startHwnd

    ; List of window classes to skip (lowercase)
    SkipClassesLowerCase := ["ime", "msctfime ui", "progman", "workerw", "shelldll_defview", "#32769", "shell_traywnd"] 
    ;OUtputDebug("--- GetNextSignificantWindow START (from: " . startHwnd . ") ---")

    Loop {
        currentHwnd := DllCall("GetWindow", "Ptr", currentHwnd, "UInt", GW_HWNDNEXT, "Ptr") ; Get the window one level below

        if (currentHwnd == 0) { ; No more windows below
            ;OUtputDebug("GetNextSignificantWindow Debug: END (Reached 0). Returning 0.")
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

        ;OUtputDebug("GetNextSignificantWindow Debug:   Checking HWND " . currentHwnd 
        ;   . ", Class: '" . winClass . "' (Trimmed Lower: '" . trimmedWinClass . "')"
        ;   . ", Title: '" . winTitle . "'"
        ;   . ", Is Skipped? " . (isSkipped ? "True" : "False")
        ;)

        if (isSkipped) {
            ;OUtputDebug("GetNextSignificantWindow Debug:   --> SKIPPING. Continue searching.")
            Continue ; This window should be skipped, so continue searching further down
        }
        
        ;OUtputDebug("GetNextSignificantWindow Debug:   --> FOUND significant window. Returning " . currentHwnd)
        Return currentHwnd ; A non-skipped (normal application) window was found
    }
}


; ==== Function: Determines if the window is at the "bottommost" of the Z-order ====
; (The content of this function remains unchanged from GetNextSignificantWindow's fix)
IsWindowTrulyAtBottom(hwnd) {
    if (!WinExist(hwnd)) {
        ;OUtputDebug("IsWindowTrulyAtBottom: HWND " . hwnd . " does not exist.")
        Return true ; If the window does not exist, consider it already at the bottom
    }

    HwndNextSignificant := GetNextSignificantWindow(hwnd)

    if (HwndNextSignificant == 0) {
        Return true ; If no application window is found below it, it's at the bottom
    }
    
    Return false ; An application window is found below it, so it's not at the bottom
}