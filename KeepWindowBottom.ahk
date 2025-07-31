#Requires AutoHotkey v2.0

; 対象のアプリケーション
Global TargetWindow := "ahk_exe alacritty.exe"

; TargetWindowのターゲット位置 (あなたの環境の座標に修正)
Global TargetWindowCondX := 1970
Global TargetWindowCondY := 30

; Windows APIの定数
Global GW_HWNDNEXT := 2  ; Zオーダーにおける次のウィンドウ (すぐ下) を取得

;処理の頻度
Global Frequency := 50

; ==== 最背面に保つタイマールーチン ====
SetTimer KeepTargetWindowBelow, Frequency 
Return

KeepTargetWindowBelow() {
    try {
        FoundHwnd := 0
        for hwnd in WinGetList(TargetWindow) {
            WinGetPos(&x, &y, &width, &height, hwnd)
            if (x == TargetWindowCondX && y == TargetWindowCondY) {
                FoundHwnd := hwnd
                break
            }
        }

        if (!FoundHwnd) { 
            ;OUtputDebug("KeepTargetWindowBelow: [INFO] TargetWindowウィンドウが指定位置に見つかりません。WinMoveBottomをスキップします。")
            Return
        } else {
            ;OUtputDebug("KeepTargetWindowBelow: [INFO] TargetWindowウィンドウ (HWND: " . FoundHwnd . ") がターゲット位置に見つかりました。")
        }
        
        if (!IsWindowTrulyAtBottom(FoundHwnd)) {
            ;OUtputDebug("KeepTargetWindowBelow: [ACTION] TargetWindowは最背面ではありません。WinMoveBottom()を呼び出します。")
            WinMoveBottom(FoundHwnd)
        } else {
            ;OUtputDebug("KeepTargetWindowBelow: [STATUS] TargetWindowは既に最背面と判定されました。WinMoveBottom()はスキップ。")
            ;OUtputDebug("KeepTargetWindowBelow: [DEBUG] IsWindowTrulyAtBottom()がTrueを返しました。TargetWindowは本当に最背面ですか？")
        }

    } catch as e {
        ;OUtputDebug("ERROR: タイマールーチンでエラー発生 (Catchブロックから): " . e.Message)
    }
}

; ==== ヘルパー関数: 次の「意味のある」ウィンドウ (非IME/非デスクトップ) を取得する ====
; 与えられたウィンドウのすぐ下からZオーダーをたどり、
; IMEウィンドウやデスクトップ関連のウィンドウをスキップして、
; 最初に見つかった「通常のアプリケーションウィンドウ」のHWNDを返します。
; もしそのようなウィンドウが見つからなければ 0 を返します。
GetNextSignificantWindow(startHwnd) {
    Local currentHwnd := startHwnd

    ; スキップすべきウィンドウクラスのリスト (小文字)
    SkipClassesLowerCase := ["ime", "msctfime ui", "progman", "workerw", "shelldll_defview", "#32769", "shell_traywnd"] 
    ;OUtputDebug("--- GetNextSignificantWindow START (from: " . startHwnd . ") ---")

    Loop {
        currentHwnd := DllCall("GetWindow", "Ptr", currentHwnd, "UInt", GW_HWNDNEXT, "Ptr") ; 1つ下のウィンドウを取得

        if (currentHwnd == 0) { ; もうこれ以上ウィンドウがない
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
        ;    . ", Class: '" . winClass . "' (Trimmed Lower: '" . trimmedWinClass . "')"
        ;    . ", Title: '" . winTitle . "'"
        ;    . ", Is Skipped? " . (isSkipped ? "True" : "False")
        ;)

        if (isSkipped) {
            ;OUtputDebug("GetNextSignificantWindow Debug:   --> SKIPPING. Continue searching.")
            Continue ; このウィンドウはスキップすべきなので、次のループでさらに下のウィンドウを探す
        }
        
        ;OUtputDebug("GetNextSignificantWindow Debug:   --> FOUND significant window. Returning " . currentHwnd)
        Return currentHwnd ; ここまで来たということは、スキップすべきでない（通常のアプリ）ウィンドウが見つかった
    }
}


; ==== ウィンドウがZオーダーの「最下層」にあるかを判定する関数 ====
; (この関数の中身はGetNextSignificantWindow の修正に伴い変更なし)
IsWindowTrulyAtBottom(hwnd) {
    if (!WinExist(hwnd)) {
        ;OUtputDebug("IsWindowTrulyAtBottom: HWND " . hwnd . " does not exist.")
        Return true ; ウィンドウが存在しない場合は、既に最背面と見なす
    }

    HwndNextSignificant := GetNextSignificantWindow(hwnd)

    if (HwndNextSignificant == 0) {
        Return true ; 下にアプリウィンドウがないので、最背面である
    }
    
    Return false ; 下にアプリウィンドウがある。最背面ではない。
}