class UISL_ImplantsRemoval extends UIScreenListener;

var localized string mStr_RemoveImplantLabel;
var localized string mStr_NeedBreakthrough;

event OnInit(UIScreen Screen)
{
	AddImplantRemove(UIInventory_Implants(Screen));
	AddImplantRemoveNothing(UIArmory_MainMenu(Screen));
}

event OnReceiveFocus(UIScreen Screen)
{
	AddImplantRemoveNothing(UIArmory_MainMenu(Screen));
}

simulated function AddImplantRemoveNothing(UIArmory_MainMenu ArmoryScreen)
{
	local UIButton RemoveButton;
	local XComGameState_Unit Unit;
	local array<XComGameState_Item> EquippedImplants;
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bShouldShowRemoveItem;

	if (ArmoryScreen == none)
		return;

	Unit = ArmoryScreen.GetUnit();

	if (Unit == none)
		return;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);

	bShouldShowRemoveItem = !XComHQ.HasCombatSimsInInventory() && EquippedImplants.Length > 0 && XComHQ.bReusePCS;

	RemoveButton = UIButton(ArmoryScreen.GetChild('RemovePCSButton', false));

	if (bShouldShowRemoveItem)
	{
		if (RemoveButton == none)
		{
			RemoveButton = ArmoryScreen.Spawn(class'UIButton', ArmoryScreen).InitButton('RemovePCSButton', mStr_RemoveImplantLabel, RemoveImplantsFromArmory);
			RemoveButton.SetPosition(125, 800);
			RemoveButton.AnimateIn(0);
		}
	}
	else if (RemoveButton != none) {
		RemoveButton.Remove();
	}
}

simulated function AddImplantRemove(UIInventory_Implants ImplantScreen)
{
	local UIButton RemoveButton;
	local XComGameState_Unit Unit;
	local array<XComGameState_Item> EquippedImplants;

	if (ImplantScreen == none)
		return;

	Unit = UIArmory_MainMenu(`SCREENSTACK.GetScreen(class'UIArmory_MainMenu')).GetUnit();

	if (Unit == none)
		return;

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);

	if (EquippedImplants.Length > 0)
	{
		RemoveButton = ImplantScreen.Spawn(class'UIButton', ImplantScreen).InitButton('RemovePCSButton', mStr_RemoveImplantLabel, RemoveImplant);
		RemoveButton.SetPosition(125, 960);
		RemoveButton.AnimateIn(0);
		if (!ImplantScreen.XComHQ.bReusePCS)
		{
			RemoveButton.DisableButton(mStr_NeedBreakthrough);
		}
	}
}

simulated function RemoveImplant(UIButton btn_clicked)
{
	local UIInventory_Implants ImplantScreen;

	ImplantScreen = UIInventory_Implants(btn_clicked.Screen);

	if (ImplantScreen != none)
	{
		ImplantScreen.RemoveImplant();
		ImplantScreen.CloseScreen();
	}
}



simulated function RemoveImplantsFromArmory(UIButton btn_clicked)
{
	local int SlotIndex;	
	local XComGameState UpdatedState;
	local StateObjectReference UnitRef;
	local XComGameState_Unit UpdatedUnit;
	local array<XComGameState_Item> EquippedImplants;
	local UIArmory_MainMenu ArmoryScreen;
	local XComGameState_HeadquartersXCom XComHQ;

	ArmoryScreen = UIArmory_MainMenu(btn_clicked.Screen);
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (ArmoryScreen != none)
	{
		UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Personal Combat Sim");

		UnitRef = ArmoryScreen.GetUnit().GetReference();
		UpdatedUnit = XComGameState_Unit(UpdatedState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		EquippedImplants = UpdatedUnit.GetAllItemsInSlot(eInvSlot_CombatSim);

		SlotIndex = 0;

		if(UpdatedUnit.RemoveItemFromInventory(EquippedImplants[SlotIndex], UpdatedState)) 
		{
			if (XComHQ.bReusePCS) // Breakthrough research is letting us reuse PCS, so put it back into the inventory
			{
				XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.PutItemInInventory(UpdatedState, EquippedImplants[SlotIndex]);
			}
			else
			{
				UpdatedState.RemoveStateObject(EquippedImplants[SlotIndex].ObjectID); // Combat sims cannot be reused
			}

			`GAMERULES.SubmitGameState(UpdatedState);
			`HQPRES.UIInventory_Implants();
		}
		else
			`XCOMHISTORY.CleanupPendingGameState(UpdatedState);

	}
}