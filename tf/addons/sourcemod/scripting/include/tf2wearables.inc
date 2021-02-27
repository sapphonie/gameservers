native int TF2Wear_CreateWearable(int client, bool is_viewmodel, const char[] model);
native int TF2Wear_EquipWearable(int client, int wear);
native int TF2Wear_RemoveWearable(int client, int wear);
native int TF2Wear_CreateWeaponTiedWearable(int weapon, bool is_viewmodel, const char[] model);
native int TF2Wear_RemoveAllTiedWearables(int weapon);

native void TF2Wear_SetModel(int entity, const char[] model);
native int TF2Wear_ParseEquipRegionString(const char[] string);

native void TF2Wear_SetEntPropFloatOfWeapon(int weapon, PropType type, const char[] propname, float value, int children = 0);


#define TFEquip_WholeHead 		(1<<0)
#define TFEquip_Hat 			(1<<1)
#define TFEquip_Face 			(1<<2)
#define TFEquip_Glasses 		(1<<3)
#define TFEquip_Lenses 			(1<<4)
#define TFEquip_Pants 			(1<<5)
#define TFEquip_Beard 			(1<<6)
#define TFEquip_Shirt 			(1<<7)
#define TFEquip_Medal 			(1<<8)
#define TFEquip_Arms 			(1<<9)
#define TFEquip_Back 			(1<<10)
#define TFEquip_Feet 			(1<<11)
#define TFEquip_Necklace 		(1<<12)
#define TFEquip_Grenades 		(1<<13)
#define TFEquip_ArmTatoos 		(1<<14)
#define TFEquip_Flair 			(1<<15)
#define TFEquip_HeadSkin 		(1<<16)
#define TFEquip_Ears 			(1<<17)
#define TFEquip_LeftShoulder 	(1<<18)
#define TFEquip_BeltMisc 		(1<<19)
#define TFEquip_Floating 		(1<<20)
#define TFEquip_Zombie 			(1<<21)
#define TFEquip_Sleeves 		(1<<22)
#define TFEquip_RightShoulder	(1<<23)

#define TFEquip_PyroSpikes		(1<<24)
#define TFEquip_ScoutBandages	(1<<24)
#define TFEquip_EngineerPocket	(1<<24)
#define TFEquip_HeavyBeltBack	(1<<24)
#define TFEquip_DemoEyePatch	(1<<24)
#define TFEquip_SoldierGloves	(1<<24)
#define TFEquip_SpyGloves		(1<<24)
#define TFEquip_SniperHeadband	(1<<24)

#define TFEquip_ScoutBack 	 	(1<<25)
#define TFEquip_HeavyPocket	 	(1<<25)
#define TFEquip_EngineerBelt 	(1<<25)
#define TFEquip_SoldierPocket 	(1<<25)
#define TFEquip_DemoBelt 		(1<<25)
#define TFEquip_SniperQuiver	(1<<25)

#define TFEquip_PyroWings 		(1<<26)
#define TFEquip_SniperBullets	(1<<26)
#define TFEquip_MediAccessories	(1<<26)
#define TFEquip_SoldierCoat		(1<<26)
#define TFEquip_HeavyHip 		(1<<26)
#define TFEquip_ScoutHands 		(1<<26)

#define TFEquip_EngineerLeftArm	(1<<27)
#define TFEquip_PyroTail	 	(1<<27)
#define TFEquip_SniperLegs	 	(1<<27)
#define TFEquip_MedicGloves 	(1<<27)
#define TFEquip_SoldierCigar 	(1<<27)
#define TFEquip_DemomanCollar 	(1<<27)
#define TFEquip_HeavyTowel 		(1<<27)

#define TFEquip_EngineerWings	(1<<28)
#define TFEquip_PyroHead		(1<<28)
#define TFEquip_ScoutWings		(1<<28)
#define TFEquip_HeavyHair		(1<<28)
#define TFEquip_MedicPipe		(1<<28)
#define TFEquip_SoldierLegs 	(1<<28)

#define TFEquip_ScoutPants		(1<<29)
#define TFEquip_HeavyBullets	(1<<29)
#define TFEquip_EngineerHair	(1<<29)
#define TFEquip_SniperVest		(1<<29)
#define TFEquip_MedigunBackpack	(1<<29)
#define TFEquip_SniperPocketLeft (1<<29)

#define TFEquip_SniperPocket	(1<<30)
#define TFEquip_HeavyHipPouch	(1<<30)
#define TFEquip_SpyCoat			(1<<30)
#define TFEquip_MedicHip		(1<<30)