ScriptName TDL_MCM_Inventory extends Quest

Quest Property MainControllerQuest Auto
GlobalVariable Property InvSpam_RollsGV Auto
GlobalVariable Property InvSpam_CountMinGV Auto
GlobalVariable Property InvSpam_CountMaxGV Auto
GlobalVariable Property InvSpam_RadiusGV Auto

GlobalVariable Property InvDrop_BatchSizeGV Auto
GlobalVariable Property InvDrop_IntervalGV Auto
GlobalVariable Property InvProtectTokensByNameGV Auto
GlobalVariable Property InvDrop_ShowProgressGV Auto
GlobalVariable Property InvDrop_TimeoutGV Auto

Int FLAG_HAS_DEFAULT = 16

Int OID_StartDropAll
Int OID_StartScatter

Int OID_ExactCount
Int OID_MinCount
Int OID_MaxCount
Int OID_Radius

Int OID_DropBatch
Int OID_DropInterval
Int OID_ProtectTokens
Int OID_ShowProgress
Int OID_Timeout

Function BuildPage(SKI_ConfigBase mcm)
	mcm.SetCursorFillMode(mcm.TOP_TO_BOTTOM)

	mcm.SetCursorPosition(0)
	mcm.AddHeaderOption("$InventoryHeaderScatter")
	OID_StartScatter = mcm.AddTextOption("$InventoryActionScatter", "$ActionActivate")
	OID_ExactCount = mcm.AddSliderOption("$InventoryExactCount", InvSpam_RollsGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_MinCount = mcm.AddSliderOption("$InventoryMinCount", InvSpam_CountMinGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_MaxCount = mcm.AddSliderOption("$InventoryMaxCount", InvSpam_CountMaxGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_Radius = mcm.AddSliderOption("$InventoryRadius", InvSpam_RadiusGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)

	mcm.SetCursorPosition(1)
	mcm.AddHeaderOption("$InventoryHeaderDropAll")
	OID_StartDropAll = mcm.AddTextOption("$InventoryActionDropAll", "$ActionActivate")
	OID_DropBatch = mcm.AddSliderOption("$InventoryDropBatch", InvDrop_BatchSizeGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
	OID_DropInterval = mcm.AddSliderOption("$InventoryDropInterval", InvDrop_IntervalGV.GetValue(), "{2}", FLAG_HAS_DEFAULT)
	OID_ProtectTokens = mcm.AddToggleOption("$InventoryProtectTokens", (InvProtectTokensByNameGV.GetValueInt() == 1))
	OID_ShowProgress = mcm.AddToggleOption("$InventoryShowProgress", (InvDrop_ShowProgressGV.GetValueInt() == 1))
	OID_Timeout = mcm.AddSliderOption("$InventoryTimeout", InvDrop_TimeoutGV.GetValue(), "{0}", FLAG_HAS_DEFAULT)
EndFunction

Bool Function HandleOptionSelect(SKI_ConfigBase mcm, Int option)
	If option == OID_StartScatter
		MainControllerQuest.SetStage(80)
		Return True
	EndIf
	If option == OID_StartDropAll
		MainControllerQuest.SetStage(81)
		Return True
	EndIf
	If option == OID_ProtectTokens
		Int nv = 1
		If InvProtectTokensByNameGV.GetValueInt() == 1
			nv = 0
		EndIf
		InvProtectTokensByNameGV.SetValueInt(nv)
		mcm.SetToggleOptionValue(OID_ProtectTokens, (nv == 1))
		Return True
	EndIf
	If option == OID_ShowProgress
		Int nv2 = 1
		If InvDrop_ShowProgressGV.GetValueInt() == 1
			nv2 = 0
		EndIf
		InvDrop_ShowProgressGV.SetValueInt(nv2)
		mcm.SetToggleOptionValue(OID_ShowProgress, (nv2 == 1))
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderAccept(SKI_ConfigBase mcm, Int option, Float value)
	If option == OID_ExactCount
		InvSpam_RollsGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_MinCount
		InvSpam_CountMinGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_MaxCount
		InvSpam_CountMaxGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_Radius
		InvSpam_RadiusGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_DropBatch
		InvDrop_BatchSizeGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	If option == OID_DropInterval
		InvDrop_IntervalGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{2}")
		Return True
	EndIf
	If option == OID_Timeout
		InvDrop_TimeoutGV.SetValue(value)
		mcm.SetSliderOptionValue(option, value, "{0}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleOptionDefault(SKI_ConfigBase mcm, Int option)
	If option == OID_ExactCount
		InvSpam_RollsGV.SetValue(0)
		mcm.SetSliderOptionValue(option, 0, "{0}")
		Return True
	EndIf
	If option == OID_MinCount
		InvSpam_CountMinGV.SetValue(150)
		mcm.SetSliderOptionValue(option, 150, "{0}")
		Return True
	EndIf
	If option == OID_MaxCount
		InvSpam_CountMaxGV.SetValue(200)
		mcm.SetSliderOptionValue(option, 200, "{0}")
		Return True
	EndIf
	If option == OID_Radius
		InvSpam_RadiusGV.SetValue(800)
		mcm.SetSliderOptionValue(option, 800, "{0}")
		Return True
	EndIf
	If option == OID_DropBatch
		InvDrop_BatchSizeGV.SetValue(10)
		mcm.SetSliderOptionValue(option, 10, "{0}")
		Return True
	EndIf
	If option == OID_DropInterval
		InvDrop_IntervalGV.SetValue(0.20)
		mcm.SetSliderOptionValue(option, 0.20, "{2}")
		Return True
	EndIf
	If option == OID_Timeout
		InvDrop_TimeoutGV.SetValue(30)
		mcm.SetSliderOptionValue(option, 30, "{0}")
		Return True
	EndIf
	Return False
EndFunction

Bool Function HandleSliderOpen(SKI_ConfigBase mcm, Int option)

	; ===== SCATTER (Stage 80) =====
	If option == OID_ExactCount
		mcm.SetSliderDialogRange(0, 2000)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_MinCount || option == OID_MaxCount
		mcm.SetSliderDialogRange(1, 2000)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_Radius
		mcm.SetSliderDialogRange(100, 5000)
		mcm.SetSliderDialogInterval(50)
		Return True
	EndIf

	; ===== DROP ALL (Stage 81) =====
	If option == OID_DropBatch
		mcm.SetSliderDialogRange(1, 100)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	If option == OID_DropInterval
		mcm.SetSliderDialogRange(0.05, 1.0)
		mcm.SetSliderDialogInterval(0.01)
		Return True
	EndIf

	If option == OID_Timeout
		mcm.SetSliderDialogRange(5, 120)
		mcm.SetSliderDialogInterval(1)
		Return True
	EndIf

	Return False
EndFunction