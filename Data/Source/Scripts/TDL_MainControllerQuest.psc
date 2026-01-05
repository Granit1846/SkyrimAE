;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 237
Scriptname TDL_MainControllerQuest Extends Quest Hidden

;BEGIN ALIAS PROPERTY TDL_ChaosAlias
;ALIAS PROPERTY TYPE ReferenceAlias
ReferenceAlias Property Alias_TDL_ChaosAlias Auto
;END ALIAS PROPERTY

;BEGIN ALIAS PROPERTY TDL_HunterCallerToken
;ALIAS PROPERTY TYPE ReferenceAlias
ReferenceAlias Property Alias_TDL_HunterCallerToken Auto
;END ALIAS PROPERTY

;BEGIN ALIAS PROPERTY EscortAlias
;ALIAS PROPERTY TYPE ReferenceAlias
ReferenceAlias Property Alias_EscortAlias Auto
;END ALIAS PROPERTY

;BEGIN FRAGMENT Fragment_162
Function Fragment_162()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 42

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_182
Function Fragment_182()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 70

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_231
Function Fragment_231()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 94

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_225
Function Fragment_225()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 114

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_168
Function Fragment_168()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 43

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_194
Function Fragment_194()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 80

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_229
Function Fragment_229()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 92

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_226
Function Fragment_226()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 119

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_233
Function Fragment_233()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 96

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_160
Function Fragment_160()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 41

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_155
Function Fragment_155()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 40

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_106
Function Fragment_106()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 1

Debug.Notification("[TDL] Stage " + STAGE_NUM + " fired")
Debug.MessageBox("[TDL] Stage " + STAGE_NUM + " fired")

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " OK")
Else
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_196
Function Fragment_196()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 81

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_197
Function Fragment_197()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 50

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_172
Function Fragment_172()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 45

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_215
Function Fragment_215()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 100

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_113
Function Fragment_113()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 10

Debug.Notification("[TDL] Stage " + STAGE_NUM + " fired")
Debug.MessageBox("[TDL] Stage " + STAGE_NUM + " fired")

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " OK")
Else
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_198
Function Fragment_198()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 51

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_115
Function Fragment_115()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 11

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_213
Function Fragment_213()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 123

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_136
Function Fragment_136()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 30

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_135
Function Fragment_135()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 20

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_212
Function Fragment_212()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 122

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_214
Function Fragment_214()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 124

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_171
Function Fragment_171()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 44

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_178
Function Fragment_178()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 47

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_117
Function Fragment_117()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 12

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_222
Function Fragment_222()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 111

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_199
Function Fragment_199()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 52

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_173
Function Fragment_173()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 46

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_236
Function Fragment_236()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 99

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_210
Function Fragment_210()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 120

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_221
Function Fragment_221()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 110

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_189
Function Fragment_189()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 71

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_232
Function Fragment_232()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 95

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_133
Function Fragment_133()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 13

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_223
Function Fragment_223()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 112

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_228
Function Fragment_228()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 91

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_227
Function Fragment_227()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 90

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_211
Function Fragment_211()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 121

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_216
Function Fragment_216()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 101

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_208
Function Fragment_208()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 53

Debug.MessageBox("¬ыполните квест или будете наказаны")

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_234
Function Fragment_234()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 97

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_217
Function Fragment_217()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 102

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_230
Function Fragment_230()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 93

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_224
Function Fragment_224()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 113

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;BEGIN FRAGMENT Fragment_235
Function Fragment_235()
;BEGIN AUTOCAST TYPE TDL_MainController
Quest __temp = self as Quest
TDL_MainController kmyQuest = __temp as TDL_MainController
;END AUTOCAST
;BEGIN CODE
Int STAGE_NUM = 98

TDL_MainController ctrl = kmyQuest
Bool ok = False

If ctrl
	ok = ctrl.RunStage(STAGE_NUM)
Else
	Debug.Notification("[TDL] ERROR controller script not attached")
EndIf

If !ok
	Debug.Notification("[TDL] Stage " + STAGE_NUM + " ERROR")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
