ScriptName TDL_StreamBridge extends Quest

; ===============================
; PROPERTIES
; ===============================
Quest Property MainControllerQuest Auto
GlobalVariable Property TDL_DebugEnabled Auto

String Property EventFilePath = "Data\\TDL\\stream_event.json" Auto
String Property AckFilePath   = "Data\\TDL\\stream_ack.json" Auto

; ===============================
; INTERNAL STATE
; ===============================
Int _lastNonce = -1


; ===============================
; INIT
; ===============================
Event OnInit()
	Debug.Notification("[TDL] StreamBridge INIT")
	Debug.Trace("[TDL] StreamBridge INIT")

	; ===== INIT STORAGEUTIL ROOT (ÎÁßÇÀÒÅËÜÍÎ) =====
	If JsonUtil.GetIntValue(EventFilePath, "nonce", -999) == -999
		JsonUtil.SetIntValue(EventFilePath, "nonce", 0)
		JsonUtil.SetStringValue(EventFilePath, "action", "")
		JsonUtil.SetIntValue(EventFilePath, "source", 0)
		JsonUtil.Save(EventFilePath)
		Debug.Trace("[TDL] stream_event.json initialized")
	EndIf

	; ===== STABLE STREAM TICK =====
	RegisterForUpdate(0.5)
EndEvent

; ===============================
; ACTION > STAGE MAP
; ===============================
Int Function _MapActionToStage(String actionID)

	; ===== SYSTEM =====
	If actionID == "SYSTEM_HEALING"
		Return 20
	EndIf

	If actionID == "SYSTEM_BLESSING"
		Return 30
	EndIf

	; ===== SUMMONING =====
	If actionID == "SYSTEM_SUMMON_ANY"
		Return 40
	EndIf

	; ===== CHAOS =====
	If actionID == "CHAOS_LOWG"
		Return 70
	EndIf

	If actionID == "CHAOS_BACKFIRE"
		Return 71
	EndIf

	; ===== INVENTORY =====
	If actionID == "INVENTORY_SCATTER"
		Return 80
	EndIf

	If actionID == "INVENTORY_DROPALL"
		Return 81
	EndIf

	; ===== VIRUS =====
	If actionID == "VIRUS_INFECT"
		Return 100
	EndIf

	Return -1
EndFunction


; ===============================
; ACK WRITER
; ===============================
Function _WriteAck(Int nonce, Int stage, Bool ok)

	JsonUtil.ClearAll(AckFilePath)

	JsonUtil.SetIntValue(AckFilePath, "nonce", nonce)
	JsonUtil.SetIntValue(AckFilePath, "stage", stage)
	JsonUtil.SetIntValue(AckFilePath, "timestamp", Utility.GetCurrentGameTime() as Int)

	If ok
		JsonUtil.SetStringValue(AckFilePath, "status", "ok")
	Else
		JsonUtil.SetStringValue(AckFilePath, "status", "rejected")
	EndIf

	JsonUtil.Save(AckFilePath)
EndFunction