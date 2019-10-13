class NewWeapUpgradeItem extends UIArmory_WeaponUpgradeItem;

var UIButton DropItemButton;
var bool bCanBeCleared;
var int DropTooltipID;

var localized string m_strDropUpgrade;
var localized string m_strCannotDropUpgrade;
var localized string m_strError;

simulated function UIArmory_WeaponUpgradeItem InitUpgradeItem(XComGameState_Item InitWeapon, optional X2WeaponUpgradeTemplate InitUpgrade, optional int SlotNum = -1, optional string InitDisabledReason)
{	
	local bool bShowClearButton;	

	super.InitUpgradeItem(InitWeapon, InitUpgrade, SlotNum, InitDisabledReason);

	//`log("Upgrade Slot index=" $ SlotNum $", name=" $ UpgradeTemplate.DataName,, 'RemoveUpgrades');

	if (InitUpgrade != none && !bIsDisabled && SlotNum >= 0)
	{
		//`log("Upgrade Slot has upgrades and not in locker",, 'RemoveUpgrades');
		bShowClearButton = (Weapon != none) && (class'UIUtilities_Strategy'.static.GetXComHQ().bReuseUpgrades);

		bCanBeCleared = bShowClearButton;
		if(Movie.IsMouseActive()) //should not show the PC button to clear item if in console mode
		{
			//`log("Showing clear button...",, 'RemoveUpgrades');
			if (bShowClearButton) {
				DropTooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(m_strDropUpgrade, 0, 0, MCPath $ ".DropItemButton.bg");
			}
			else {
				DropTooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(m_strCannotDropUpgrade, 0, 0, MCPath $ ".DropItemButton.bg");
			}
			MC.SetBool("showClearButton", true);
			MC.FunctionVoid("realize");
		}
	}

	return self;
}

simulated function OnCommand(string cmd, string arg)
{
	if(cmd == "DropItemClicked")
		OnDropItemClicked(DropItemButton);
}

simulated function RemoveUpgradeError()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Warning;
	DialogData.strTitle = m_strError;
	DialogData.strText = m_strCannotDropUpgrade;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	`HQPRES.UIRaiseDialog(DialogData);
}

function OnDropItemClicked(UIButton kButton)
{
	local XComGameState_Item UpgradeItem;
	local XComGameState_Item NewWeapon;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState ChangeState;
	local array<X2WeaponUpgradeTemplate> EquippedUpgrades;
	local int i;

	local UIArmory_WeaponUpgrade UpgradeScreen;

	if (!bCanBeCleared)
	{
		RemoveUpgradeError();
		return;
	}


	if (UpgradeTemplate != none && Weapon != none)
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Weapon Upgrade Removal");
		ChangeState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
		NewWeapon = XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', Weapon.ObjectID));
		EquippedUpgrades = NewWeapon.GetMyWeaponUpgradeTemplates();
		for (i = 0; i < EquippedUpgrades.Length; i++)
		{
			if (EquippedUpgrades[i].DataName == UpgradeTemplate.DataName)
			{
				EquippedUpgrades.Remove(i, 1);
				break;
			}
		}
		NewWeapon.WipeUpgradeTemplates();
		for (i = 0; i < EquippedUpgrades.Length; i++)
		{
			NewWeapon.ApplyWeaponUpgradeTemplate(EquippedUpgrades[i], i);
		}

		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ = XComGameState_HeadquartersXCom(ChangeState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		UpgradeItem = UpgradeTemplate.CreateInstanceFromTemplate(ChangeState);
		XComHQ.PutItemInInventory(ChangeState, UpgradeItem);
		`GAMERULES.SubmitGameState(ChangeState);

		UpgradeScreen = UIArmory_WeaponUpgrade(Screen);

		if (UpgradeScreen != none)
		{
			UpgradeScreen.UpdateSlots();
			UpgradeScreen.WeaponStats.PopulateData(Weapon);

			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade_Select");
		}

		Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Weapon.ObjectID));
	}
}

defaultproperties
{
	bProcessesMouseEvents = false;
}