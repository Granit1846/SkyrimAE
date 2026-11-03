ScriptName TDL_MCMConfig extends SKI_ConfigBase

TDL_MCM_Chaos     Property ChaosModule Auto
TDL_MCM_Inventory Property InventoryModule Auto
TDL_MCM_Wrath     Property WrathModule Auto
TDL_MCM_System    Property SystemModule Auto
TDL_MCM_Hunter    Property HunterModule Auto
TDL_MCM_Gigant    Property GigantModule Auto
TDL_MCM_Comedy    Property ComedyModule Auto
TDL_MCM_Virus Property VirusModule Auto
TDL_MCM_Teleport Property TeleportModule Auto
TDL_MCM_About Property AboutModule Auto

Int Function GetVersion()
    Return 27
EndFunction

Event OnConfigInit()
    ModName = "TDL"
    
	Pages = new String[10]
	Pages[0] = "$TDL_PageChaos"
	Pages[1] = "$TDL_PageInventory"
	Pages[2] = "$TDL_PageWrath"
	Pages[3] = "$TDL_PageSystem"
	Pages[4] = "$TDL_PageHunter"
	Pages[5] = "$TDL_PageGigant"
	Pages[6] = "$TDL_PageComedy"
	Pages[7] = "$TDL_PageVirus"
	Pages[8] = "$TDL_PageTeleport"
	Pages[9] = "$TDL_PageAbout"
    
    Quest q = Self as Quest
    If q
        If ChaosModule == None
            ChaosModule = q as TDL_MCM_Chaos
        EndIf
        If InventoryModule == None
            InventoryModule = q as TDL_MCM_Inventory
        EndIf
        If WrathModule == None
            WrathModule = q as TDL_MCM_Wrath
        EndIf
        If SystemModule == None
            SystemModule = q as TDL_MCM_System
        EndIf
        If HunterModule == None
            HunterModule = q as TDL_MCM_Hunter
        EndIf
        If GigantModule == None
            GigantModule = q as TDL_MCM_Gigant
        EndIf
        If ComedyModule == None
            ComedyModule = q as TDL_MCM_Comedy
        EndIf
	 If VirusModule == None
            VirusModule = q as TDL_MCM_Virus
        EndIf
	 If TeleportModule == None
	      TeleportModule = q as TDL_MCM_Teleport
	 EndIf
	 If AboutModule == None
	      AboutModule = q as TDL_MCM_About
	 EndIf
    EndIf
    Parent.OnConfigInit()
EndEvent

Event OnPageReset(String page)
    Parent.OnPageReset(page)

    If page == "$TDL_PageChaos" && ChaosModule
        ChaosModule.BuildPage(Self)
        Return
    EndIf
    If page == "$TDL_PageInventory" && InventoryModule
        InventoryModule.BuildPage(Self)
        Return
    EndIf
    If page == "$TDL_PageWrath" && WrathModule
        WrathModule.BuildPage(Self)
        Return
    EndIf
    If page == "$TDL_PageSystem" && SystemModule
        SystemModule.BuildPage(Self)
        Return
    EndIf
    If page == "$TDL_PageHunter" && HunterModule
        HunterModule.BuildPage(Self)
        Return
    EndIf
    If page == "$TDL_PageGigant" && GigantModule
        GigantModule.BuildPage(Self)
        Return
    EndIf
    If page == "$TDL_PageComedy" && ComedyModule
        ComedyModule.BuildPage(Self)
        Return
    EndIf
    If page == "$TDL_PageVirus" && VirusModule
	 VirusModule.BuildPage(Self)
	 Return
    EndIf
    If page == "$TDL_PageTeleport" && TeleportModule
	 TeleportModule.BuildPage(Self)
	 Return
    EndIf
	If page == "$TDL_PageAbout" && AboutModule
		AboutModule.BuildPage(Self)
		Return
	EndIf
EndEvent

Event OnOptionSelect(Int option)
    If CurrentPage == "$TDL_PageChaos" && ChaosModule
        ChaosModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageInventory" && InventoryModule
        InventoryModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageWrath" && WrathModule
        WrathModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageSystem" && SystemModule
        SystemModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageHunter" && HunterModule
        HunterModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageGigant" && GigantModule
        GigantModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageComedy" && ComedyModule
        ComedyModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageVirus" && VirusModule
        VirusModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageTeleport" && TeleportModule
        TeleportModule.HandleOptionSelect(Self, option)
    ElseIf CurrentPage == "$TDL_PageAbout" && AboutModule
        AboutModule.HandleOptionSelect(Self, option)
    EndIf
EndEvent

Event OnOptionSliderAccept(Int option, Float value)
    If CurrentPage == "$TDL_PageChaos" && ChaosModule
        ChaosModule.HandleSliderAccept(Self, option, value)
    ElseIf CurrentPage == "$TDL_PageInventory" && InventoryModule
        InventoryModule.HandleSliderAccept(Self, option, value)
    ElseIf CurrentPage == "$TDL_PageWrath" && WrathModule
        WrathModule.HandleSliderAccept(Self, option, value)
    ElseIf CurrentPage == "$TDL_PageHunter" && HunterModule
        HunterModule.HandleSliderAccept(Self, option, value)
    ElseIf CurrentPage == "$TDL_PageGigant" && GigantModule
        GigantModule.HandleSliderAccept(Self, option, value)
    ElseIf CurrentPage == "$TDL_PageComedy" && ComedyModule
        ComedyModule.HandleSliderAccept(Self, option, value)
    ElseIf CurrentPage == "$TDL_PageVirus" && VirusModule
        VirusModule.HandleSliderAccept(Self, option, value)
    ElseIf CurrentPage == "$TDL_PageTeleport" && TeleportModule
        TeleportModule.HandleSliderAccept(Self, option, value)
    EndIf
EndEvent

Event OnOptionSliderOpen(Int option)
    If CurrentPage == "$TDL_PageChaos" && ChaosModule
        ChaosModule.HandleSliderOpen(Self, option)
    ElseIf CurrentPage == "$TDL_PageInventory" && InventoryModule
        InventoryModule.HandleSliderOpen(Self, option)
    ElseIf CurrentPage == "$TDL_PageWrath" && WrathModule
        WrathModule.HandleSliderOpen(Self, option)
    ElseIf CurrentPage == "$TDL_PageHunter" && HunterModule
        HunterModule.HandleSliderOpen(Self, option)
    ElseIf CurrentPage == "$TDL_PageGigant" && GigantModule
        GigantModule.HandleSliderOpen(Self, option)
    ElseIf CurrentPage == "$TDL_PageComedy" && ComedyModule
        ComedyModule.HandleSliderOpen(Self, option)
    ElseIf CurrentPage == "$TDL_PageVirus" && VirusModule
        VirusModule.HandleSliderOpen(Self, option)
    ElseIf CurrentPage == "$TDL_PageTeleport" && TeleportModule
        TeleportModule.HandleSliderOpen(Self, option)
    EndIf
EndEvent

Event OnOptionDefault(Int option)
    If CurrentPage == "$TDL_PageChaos" && ChaosModule
        ChaosModule.HandleOptionDefault(Self, option)
    ElseIf CurrentPage == "$TDL_PageInventory" && InventoryModule
        InventoryModule.HandleOptionDefault(Self, option)
    ElseIf CurrentPage == "$TDL_PageWrath" && WrathModule
        WrathModule.HandleOptionDefault(Self, option)
    ElseIf CurrentPage == "$TDL_PageHunter" && HunterModule
        HunterModule.HandleOptionDefault(Self, option)
    ElseIf CurrentPage == "$TDL_PageGigant" && GigantModule
        GigantModule.HandleOptionDefault(Self, option)
    ElseIf CurrentPage == "$TDL_PageComedy" && ComedyModule
        ComedyModule.HandleOptionDefault(Self, option)
    ElseIf CurrentPage == "$TDL_PageVirus" && VirusModule
        VirusModule.HandleOptionDefault(Self, option)
    ElseIf CurrentPage == "$TDL_PageTeleport" && TeleportModule
        TeleportModule.HandleOptionDefault(Self, option)
    EndIf
EndEvent

