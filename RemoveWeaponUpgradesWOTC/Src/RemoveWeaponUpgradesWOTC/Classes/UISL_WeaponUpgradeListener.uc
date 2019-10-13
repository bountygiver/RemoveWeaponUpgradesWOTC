class UISL_WeaponUpgradeListener extends UIScreenListener;

var localized string m_strStripUpgrades;
var localized string m_strStripUpgradesTooltip;
var localized string m_strStripUpgradesConfirm;
var localized string m_strStripUpgradesConfirmDesc;

event OnInit(UIScreen Screen)
{
	RefreshSS(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	RefreshSS(Screen);
}

simulated function AddHelp()
{
	local UISquadSelect Screen;
	local UINavigationHelp NavHelp;

	Screen = UISquadSelect(`SCREENSTACK.GetCurrentScreen());

	if (Screen != none)
	{
		NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
		if(NavHelp.m_arrButtonClickDelegates.Length > 0 && NavHelp.m_arrButtonClickDelegates.Find(OnStripUpgrades) == INDEX_NONE)
		{
			NavHelp.AddCenterHelp(m_strStripUpgrades,, OnStripUpgrades, false, m_strStripUpgradesTooltip);
		}
		Screen.SetTimer(1.0f, false, nameof(AddHelp), self);
	}
}

simulated function RefreshSS(UIScreen Screen)
{
	local UISquadSelect SquadSelectScrn;

	SquadSelectScrn = UISquadSelect(Screen);

	if (SquadSelectScrn != none && (`XCOMHQ != none && `XCOMHQ.bReuseUpgrades))
	{
		AddHelp();
	}
}

simulated function OnStripUpgrades()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = m_strStripUpgradesConfirm;
	DialogData.strText = m_strStripUpgradesConfirmDesc;
	DialogData.fnCallback = OnStripUpgradesDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	`HQPRES.UIRaiseDialog(DialogData);
}

simulated function OnStripUpgradesDialogCallback(Name eAction)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Item ItemState, UpgradeItem;
	local int idx;
	local array<X2WeaponUpgradeTemplate> EquippedUpgrades;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local array<StateObjectReference> Inventory;
	local StateObjectReference ItemRef;
	local XComGameState UpdateState;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2WeaponTemplate WeaponTemplate;
	local EInventorySlot Slot;

	if(eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Upgrades");
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class' XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		Inventory = XComHQ.Inventory;

		foreach Inventory(ItemRef)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if (WeaponTemplate != none && ItemState.GetMyTemplate().iItemSize > 0 && 
				class'X2DownloadableContentInfo_RemoveWeaponUpgradesWOTC'.default.SlotsToRemove.Find(WeaponTemplate.InventorySlot) != INDEX_NONE && 
				WeaponTemplate.NumUpgradeSlots > 0 && ItemState.HasBeenModified() &&
				(ItemState.Nickname == "" || !class'X2DownloadableContentInfo_RemoveWeaponUpgradesWOTC'.default.DontRemoveUpgradesFromNamedWeapons ))
			{
				ItemState = XComGameState_Item(UpdateState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
				EquippedUpgrades = ItemState.GetMyWeaponUpgradeTemplates();
				ItemState.WipeUpgradeTemplates();
				foreach EquippedUpgrades(UpgradeTemplate)
				{
					UpgradeItem = UpgradeTemplate.CreateInstanceFromTemplate(UpdateState);
					XComHQ.PutItemInInventory(UpdateState, UpgradeItem);
				}

				if (!ItemState.HasBeenModified() && !WeaponTemplate.bAlwaysUnique)
				{
					if (WeaponTemplate.bInfiniteItem)
					{
						XComHQ.Inventory.RemoveItem(ItemRef);
					}
				}
			}
		}

		Soldiers = XComHQ.GetSoldiers(true, true);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			if (UnitState != none)
			{
				foreach class'X2DownloadableContentInfo_RemoveWeaponUpgradesWOTC'.default.SlotsToRemove(Slot)
				{
					ItemState = UnitState.GetItemInSlot(Slot);
					WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
					if (WeaponTemplate != none && WeaponTemplate.NumUpgradeSlots > 0 &&
						(ItemState.Nickname == "" || !class'X2DownloadableContentInfo_RemoveWeaponUpgradesWOTC'.default.DontRemoveUpgradesFromNamedWeapons ))
					{
						ItemState = XComGameState_Item(UpdateState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
						EquippedUpgrades = ItemState.GetMyWeaponUpgradeTemplates();
						ItemState.WipeUpgradeTemplates();
						foreach EquippedUpgrades(UpgradeTemplate)
						{
							UpgradeItem = UpgradeTemplate.CreateInstanceFromTemplate(UpdateState);
							XComHQ.PutItemInInventory(UpdateState, UpgradeItem);
						}
					}
				}
			}
		}

		`GAMERULES.SubmitGameState(UpdateState);
	}
}