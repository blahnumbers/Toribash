---@alias StoreDiscountPaymentType
---| 1	In-game currency purchases
---| 2	PayPal purchases
---| 3	In-game + PayPal
---| 4	Steam purchases
---| 5	In-game + Steam
---| 6	PayPal + Steam
---| 7	In-game + PayPal + Steam

---@class StoreDiscount
---@field itemid integer
---@field discount number Item discount in percents
---@field discountMax number Maximum amount that can be discounted (absolute value)
---@field paymentType StoreDiscountPaymentType
---@field expiryTime integer Timestamp when this offer becomes obsolete

---@class StoreItemCategory
---@field name string

---@class StoreModel
---@field itemid integer
---@field bodyid integer
---@field colorid integer
---@field alpha number
---@field dynamic boolean
---@field partless boolean
---@field level integer
---@field upgradeable boolean
---@field levels integer
---@field textured boolean

---@class StoreItemIcon
---@field path string
---@field itemid integer
---@field element UIElement

if (Store == nil) then
	---**Toribash Store manager class**
	---
	---**Version 5.70**
	---* Added `HookName` and `HookNameVanilla` fields
	---
	---**Version 5.65**
	---* Class renamed to `Store` with old name retained for compatibility
	---* Updates to support bonus TC / ST display for VIP subscribers
	---* Internal updates to match modern code style
	---* Introduced proper versioning
	---* Removed unused legacy functions
	---* Added a separate information and purchase screen for Prime
	---@class Store
	---@field LastUpdate number Last data update time
	---@field StalePeriod number Minimum delay between Store data updates (in seconds)
	---@field Ready boolean	Whether data has been populated
	---@field Items StoreItem[] Store items cache
	---@field Categories StoreItemCategory[] Store categories cache
	---@field Models StoreModel[]|nil Store models cache
	---@field Discounts StoreDiscount[] Current user discounts data
	---@field ItemView UIElement? Selected store item information holder
	---@field LastSection integer? Last viewed store section
	---@field LastSectionId integer? Last viewed store category's internal section id
	---@field IconDownloadQueue StoreItemIcon[] Icons download queue
	---@field InventoryListShift number[] Current inventory list shift
	---@field InventoryLastListShift number Last inventory list shift before entering set view
	---@field Inventory InventoryItem[]? User inventory data
	---@field InventoryCurrentItem InventoryItem? Currently displayed inventory item
	---@field InventorySelectedItems InventoryItem[] List of selected inventory items
	---@field InventoryItemView UIElement? Selected inventory item information holder
	---@field InventoryView UIElement? Inventory view holder
	---@field InventoryPage integer[] Inventory pagination data
	---@field InventoryMode InventoryDisplayMode Active inventory display mode
	---@field InventoryShowEmptySets boolean Whether to show empty sets in inventory list
	Store = {
		LastUpdate = 0,
		StalePeriod = 5,
		Ready = false,
		Items = { },
		Categories = { },
		Models = { },
		HairCache = { },
		Discounts = { },
		ItemView = nil,
		LastSection = nil,
		LastSectionId = nil,
		IconDownloadQueue = { },
		InventoryListShift = { 0 },
		InventoryLastListShift = 0,
		Inventory = nil,
		InventoryCurrentItem = nil,
		InventorySelectedItems = { },
		InventoryItemView = nil,
		InventoryView = nil,
		InventoryPage = { },
		InventoryMode = 0,
		InventoryShowEmptySets = false,
		HookNameVanilla = "__tbStoreManagerVanilla",
		HookName = "__tbStoreManager",
		ver = 5.70
	}
	Store.__index = Store


	---**Toribash store item class**
	---
	---**Version 5.65**
	---* Updated to be a proper class rather than a regular table
	---@class StoreItem
	---@field catid integer Item's category ID
	---@field catname string Item's category name
	---@field itemid integer
	---@field itemname string
	---@field shortname string
	---@field description string
	---@field on_sale boolean Whether the item is currently on sale
	---@field now_tc_price integer Current TC price of an item
	---@field now_usd_price integer Current ST or USD price of an item
	---@field price integer Default TC price of an item
	---@field price_usd integer Default ST or USD price of an item
	---@field sale_time integer Time left before the sale on this item is over
	---@field sale_promotion boolean Whether the sale item should be featured in shop
	---@field qi integer Qi requirement for the item
	---@field tier integer Tier ID of the item
	---@field subscriptionid integer Subscription ID of an item
	---@field ingame boolean Whether the item can be equipped on a character
	---@field colorid integer Color ID of the item
	---@field hidden boolean Whether the item is currently hidden from the shop
	---@field locked boolean Whether the item is currently unavailable for purchase
	---@field contents integer[] Itemids inside a pack item
	StoreItem = {
		ver = Store.ver
	}
	StoreItem.__index = StoreItem

	---**Toribash inventory item class**
	---
	---**Version 5.65**
	---* Updated to be a proper class rather than a regular table
	---@class InventoryItem
	---@field inventid integer
	---@field itemid integer
	---@field name string
	---@field iconElement UIElement?
	---@field upgrade_level integer
	---@field activateable boolean
	---@field active boolean
	---@field tradeable boolean
	---@field customizable boolean
	---@field uploadable boolean
	---@field flamename string
	---@field flameid integer
	---@field bodypartname string
	---@field setid integer
	---@field parentset InventoryItem?
	---@field setname string
	---@field contents InventoryItem[]?
	---@field unpackable boolean
	---@field games_played integer
	---@field upgradeable boolean
	---@field upgrade_games integer
	---@field upgrade_price integer
	---@field upgrade_max_level integer
	---@field effectid integer
	---@field glow_colorid integer
	---@field voronoi_colorid integer
	---@field shift_colorid integer
	InventoryItem = {
		ver = Store.ver
	}
	InventoryItem.__index = InventoryItem
end
---Legacy name support
Torishop = Store

---@alias StoreCategory
---| 1	BloodColors
---| 2	RelaxColors
---| 3	Winnings
---| 4	Textures
---| 5	TorsoColors
---| 6	Transfer
---| 7	Secret
---| 8	Withdrawn
---| 9	Vouchers
---| 10	Avatars
---| 11	GhostColors
---| 12	DQRings
---| 13	Gradients
---| 14	SpecialItem
---| 15	BodyText
---| 18	Collectibles
---| 19	Tournament
---| 20	PrimaryGradients
---| 21	SecondaryGradients
---| 22	ForceColors
---| 23	CustomBelt
---| 24	Timers
---| 25	Mobile
---| 26	ArtOfWar
---| 27	RightHandMotionTrail
---| 28	LeftHandMotionTrail
---| 29	RightLegMotionTrail
---| 30	LeftLegMotionTrail
---| 31	Referrals
---| 32	ScratchCard
---| 33	AdvancedGhosts
---| 34	UserTextColour
---| 35	RightHandTextureTrail
---| 36	LeftHandTextureTrail
---| 37	RightLegTextureTrail
---| 38	LeftLegTextureTrail
---| 39	Market
---| 40	Bank
---| 41	GripColors
---| 42	Boosters
---| 43	EmoteColors
---| 44	ColorPacks
---| 45	Toricredits
---| 46	TierPacks
---| 47	Secret2
---| 48	TexturePacks
---| 49	PremiumPacks
---| 50	Flames
---| 52	Survey
---| 53	paybycash
---| 54	BodyTextures
---| 55	MiscTextures
---| 56	BumpmapTextures
---| 57	TrailTextures
---| 58	GUITextures
---| 59	Sets
---| 60	TradingCards
---| 61	Fun
---| 62	FlameForge
---| 63	robbery
---| 64	Bounty
---| 65	Duel
---| 66	Bets
---| 67	Tournament2
---| 68	Qi
---| 69	Chrome
---| 70	ToriPets
---| 71	Sounds
---| 72	HairStyles
---| 73	HairColor
---| 74	JointTextures
---| 75	Music
---| 76	Uncategorized
---| 77	Tokens
---| 78	Objects3D
---| 79	Subscriptions
---| 80	FullToris
---| 81	ShiaiItems
---| 82	ComicEffects
---| 83	CollectorsCards
---| 84	ShiaiTokens
---| 85	Randomitempacks
---| 86	LotteryTickets
---| 87	ItemEffects
_G.StoreCategory = {
	Colors = 0,
	BloodColors = 1,
	RelaxColors = 2,
	Winnings = 3,
	Textures = 4,
	TorsoColors = 5,
	Transfer = 6,
	Secret = 7,
	Withdrawn = 8,
	Vouchers = 9,
	Avatars = 10,
	GhostColors = 11,
	DQRings = 12,
	Gradients = 13,
	SpecialItem = 14,
	BodyText = 15,
	Collectibles = 18,
	Tournament = 19,
	PrimaryGradients = 20,
	SecondaryGradients = 21,
	ForceColors = 22,
	CustomBelt = 23,
	Timers = 24,
	Mobile = 25,
	ArtOfWar = 26,
	RightHandMotionTrail = 27,
	LeftHandMotionTrail = 28,
	RightLegMotionTrail = 29,
	LeftLegMotionTrail = 30,
	Referrals = 31,
	ScratchCard = 32,
	AdvancedGhosts = 33,
	UserTextColour = 34,
	RightHandTextureTrail = 35,
	LeftHandTextureTrail = 36,
	RightLegTextureTrail = 37,
	LeftLegTextureTrail = 38,
	Market = 39,
	Bank = 40,
	GripColors = 41,
	Boosters = 42,
	EmoteColors = 43,
	ColorPacks = 44,
	Toricredits = 45,
	TierPacks = 46,
	Secret2 = 47,
	TexturePacks = 48,
	PremiumPacks = 49,
	Flames = 50,
	Survey = 52,
	paybycash = 53,
	BodyTextures = 54,
	MiscTextures = 55,
	BumpmapTextures = 56,
	TrailTextures = 57,
	GUITextures = 58,
	Sets = 59,
	TradingCards = 60,
	Fun = 61,
	FlameForge = 62,
	robbery = 63,
	Bounty = 64,
	Duel = 65,
	Bets = 66,
	Tournament2 = 67,
	Qi = 68,
	Chrome = 69,
	ToriPets = 70,
	Sounds = 71,
	HairStyles = 72,
	HairColor = 73,
	JointTextures = 74,
	Music = 75,
	Uncategorized = 76,
	Tokens = 77,
	Objects3D = 78,
	Subscriptions = 79,
	FullToris = 80,
	ShiaiItems = 81,
	ComicEffects = 82,
	CollectorsCards = 83,
	ShiaiTokens = 84,
	Randomitempacks = 85,
	LotteryTickets = 86,
	ItemEffects = 87
}

---Returns a template empty StoreItem object
---@return StoreItem
function StoreItem.New()
	---@type StoreItem
	local item = {
		catid = 0,
		catname = "undef",
		itemid = 0,
		itemname = "undefined",
		description = "",
		on_sale = false,
		now_tc_price = 0,
		now_usd_price = 0,
		price = 0,
		price_usd = 0,
		sale_time = 0,
		sale_promotion = false,
		qi = 0,
		tier = 0,
		subscriptionid = 0,
		ingame = false,
		colorid = 0,
		hidden = true,
		locked = true,
		contents = {}
	}
	setmetatable(item, StoreItem)
	return item
end

---@class StoreItemEffect
---@field id RenderEffectId
---@field name string
---@field colorid ColorId
---@field use_colorid boolean?

---**Helper class for Store manager**
---@class StoreInternal
---@field IAPInterfaceReady boolean Whether mobile in-app purchase interface is ready
---@field InAppIdentifiersReady boolean Whether mobile in-app purchases data has been populated
---@field ItemEffects StoreItemEffect[] Item effects data to use for Store displays
---@field EmptyItem StoreItem Template store item information
local StoreInternal = {
	IAPInterfaceReady = true,
	InAppIdentifiersReady = not is_mobile(),
	ItemEffects = {
		{ id = 1, name = "Toon Shaded", colorid = 11 },
		{ id = 2, name = " Glow", colorid = 0, use_colorid = true },
		{ id = 4, name = "Dithering", colorid = 135 },
		{ id = 8, name = " Ripples", colorid = 0, use_colorid = true },
		{ id = 16, name = " Shift", colorid = 0, use_colorid = true }
	},
	EmptyItem = StoreItem.New(),
	ItemFields = {
		{ "catid", numeric = true },
		{ "catname" },
		{ "itemid", numeric = true },
		{ "itemname" },
		{ "on_sale", boolean = true },
		{ "now_tc_price", numeric = true },
		{ "now_usd_price", numeric = true },
		{ "price", numeric = true },
		{ "price_usd", numeric = true },
		{ "sale_time", numeric = true },
		{ "sale_promotion", boolean = true },
		{ "qi", numeric = true },
		{ "tier", numeric = true },
		{ "subscriptionid", numeric = true },
		{ "ingame", boolean = true },
		{ "colorid", numeric = true },
		{ "hidden", boolean = true },
		{ "locked", boolean = true },
		{ "description" },
		{ "contents" }
	},
	InventoryItemFields = {
		{ "inventid", numeric = true },
		{ "itemid", numeric = true },
		{ "upgrade_level", numeric = true },
		{ "flamename" },
		{ "activateable", boolean = true },
		{ "flameid", numeric = true },
		{ "bodypartname" },
		{ "setname" },
		{ "active", boolean = true },
		{ "tradeable", boolean = true },
		{ "uploadable", boolean = true },
		{ "setid", numeric = true },
		{ "__deprecated", boolean = true },
		{ "__deprecated", numeric = true },
		{ "unpackable", boolean = true },
		{ "games_played", numeric = true },
		{ "upgrade_games", numeric = true },
		{ "upgrade_price", numeric = true },
		{ "upgrade_max_level", numeric = true },
		{ "effectid", numeric = true },
		{ "glow_colorid", numeric = true },
		{ "voronoi_colorid", numeric = true },
		{ "shift_colorid", numeric = true }
	},
	Categories = {
		Colors = {
			StoreCategory.ColorPacks,
			StoreCategory.ForceColors,
			StoreCategory.RelaxColors,
			StoreCategory.PrimaryGradients,
			StoreCategory.SecondaryGradients,
			StoreCategory.BloodColors,
			StoreCategory.TorsoColors,
			StoreCategory.GhostColors,
			StoreCategory.DQRings,
			StoreCategory.Timers,
			StoreCategory.RightHandMotionTrail,
			StoreCategory.LeftHandMotionTrail,
			StoreCategory.RightLegMotionTrail,
			StoreCategory.LeftLegMotionTrail,
			StoreCategory.UserTextColour,
			StoreCategory.GripColors,
			StoreCategory.EmoteColors,
			StoreCategory.HairColor
		},
		Textures = {
			StoreCategory.BodyTextures,
			StoreCategory.MiscTextures,
			StoreCategory.TrailTextures,
			StoreCategory.GUITextures,
			StoreCategory.JointTextures
		},
		Advanced = {
			StoreCategory.Objects3D,
			StoreCategory.HairStyles,
			StoreCategory.ItemEffects,
			StoreCategory.FullToris,
			StoreCategory.BodyTextures,
			StoreCategory.JointTextures,
			StoreCategory.MiscTextures,
			StoreCategory.TrailTextures,
			StoreCategory.TexturePacks
		},
		Account = {
			StoreCategory.Toricredits,
			StoreCategory.ShiaiTokens,
			StoreCategory.Qi,
			StoreCategory.Subscriptions
		},
		Hidden = {
			StoreCategory.Winnings,
			StoreCategory.Textures,
			StoreCategory.Transfer,
			StoreCategory.Withdrawn,
			StoreCategory.Vouchers,
			StoreCategory.SpecialItem,
			StoreCategory.BodyText,
			StoreCategory.Mobile,
			StoreCategory.Referrals,
			StoreCategory.ScratchCard,
			StoreCategory.AdvancedGhosts,
			StoreCategory.Market,
			StoreCategory.Bank,
			StoreCategory.Boosters,
			StoreCategory.Survey,
			StoreCategory.paybycash,
			StoreCategory.FlameForge,
			StoreCategory.robbery,
			StoreCategory.Bounty,
			StoreCategory.Duel,
			StoreCategory.Bets,
			StoreCategory.Tournament,
			StoreCategory.Uncategorized,
			StoreCategory.Tokens
		}
	},
	Tabs = {
		Colors = 1,
		FlameForge = 2,
		Advanced = 3,
		Account = 4
	},
	InventoryActions = {
		Deactivate = 1,
		Activate = 2,
		AddSet = 3,
		RemoveSet = 4,
		Unpack = 5,
		Upgrade = 6,
		TextureReset = 7,
		EffectFuse = 8,
		EffectUpgrade = 9,
		EffectPurge = 10
	}
}

---@param item InventoryItem
---@param effect StoreItemEffect
---@return ColorId
function StoreInternal.GetItemEffectColorid(item, effect)
	local targetColorid = effect.colorid
	if (effect.use_colorid) then
		if (effect.id == 2) then
			targetColorid = item.glow_colorid
		elseif (effect.id == 8) then
			targetColorid = item.voronoi_colorid
		elseif (effect.id == 16) then
			targetColorid = item.shift_colorid
		end
	end
	return targetColorid
end

---Creates a new StoreItem instance from a datafile line
---@param ln string
---@return StoreItem?
function StoreItem.FromDataLine(ln)
	local _, segments = ln:gsub("\t", "")
	if (segments < #StoreInternal.ItemFields + 1) then
		return nil
	end
	local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }

	---@type StoreItem
	local item = { }
	for i, v in pairs(StoreInternal.ItemFields) do
		item[v[1]] = data_stream[i + 1]
		if (v.numeric) then
			item[v[1]] = tonumber(item[v[1]])
		end
		if (v.boolean) then
			item[v[1]] = item[v[1]] == "1"
		end
	end

	---@type string
	---@diagnostic disable-next-line: assign-type-mismatch
	local contents = item.contents
	item.contents = {}
	while (string.len(contents) > 0) do
		local match = string.match(contents, "%d+")
		table.insert(item.contents, tonumber(match))
		contents = contents:gsub("^%d+ ?", "")
	end

	item.itemname = item.itemname:gsub("&amp;", "&")
	item.shortname = item.itemname:gsub("Motion Trail", "Trail")
	if (item.locked) then
		item.now_tc_price = 0
		item.now_usd_price = 0
	end
	if (not in_array(item.catid, StoreInternal.Categories.Account)) then
		item.now_usd_price = math.ceil(item.now_usd_price)
	end

	setmetatable(item, StoreItem)
	return item
end

---Returns a copy of the current StoreItem object
---@return StoreItem
function StoreItem:getCopy()
	---@type StoreItem
	local item = {}
	for i, v in pairs(self) do
		if (type(v) == "table") then
			item[i] = table.clone(v)
		else
			item[i] = v
		end
	end
	setmetatable(item, StoreItem)
	return item
end

---Returns whether current item is a texture
---@return boolean
function StoreItem:isTexture()
	return in_array(self.catid, StoreInternal.Categories.Textures)
end

---Returns item icon path
---@return string
function StoreItem:getIconPath()
	return "../textures/store/items/" .. self.itemid .. ".tga"
end

---Returns whether item supports effects
---@return boolean
function StoreItem:supportsEffects()
	return in_array(self.catid, { 2, 20, 22 }) or in_array(self.itemid, { 1337, 1566, 1567, 2888 })
end

---Refreshes store data after some checks to prevent download spam
function Store.Download()
	local clock = os.clock_real()
	if (clock - Store.LastUpdate < Store.StalePeriod) then
		return false
	end

	local downloads = get_downloads()
	for _, v in pairs(downloads) do
		if (v:find("store(_obj)?.txt$")) then
			return false
		end
	end
	Store.LastUpdate = clock
	download_torishop()
	Store.GetPlayerOffers()
	return true
end

---Queues a network request to fetch available player store discounts and other special offers
function Store.GetPlayerOffers()
	Store.Discounts = { }
	Request:queue(function()
			download_server_info("store_discounts&username=" .. TB_MENU_PLAYER_INFO.username)
		end, "store_discounts", function()
			local response = get_network_response()
			Store.Discounts.Prime = false
			if (response:find("^DISCOUNT")) then
				for ln in response:gmatch("[^\n]+\n?") do
					local data = { ln:match(("([^\t]*)\t"):rep(6)) }
					---@type StoreDiscount
					local storeDiscount = {
						itemid = tonumber(data[2]) or 0,
						discount = tonumber(data[3]) or 0,
						discountMax = tonumber(data[4]) or 0,
						---@diagnostic disable-next-line: assign-type-mismatch
						paymentType = tonumber(data[5]) or 0,
						expiryTime = os.clock_real() + (tonumber(data[6]) or 0)
					}
					table.insert(Store.Discounts, storeDiscount)
				end
			elseif (response:find("^PRIME")) then
				Store.Discounts.Prime = true
				Store.Discounts.PrimeBonus = response:gsub("PRIME 0;", "")
				Store.Discounts.PrimeBonus = tonumber(Store.Discounts.PrimeBonus) or 0
			end
		end)
end

---Parses store datafile and populates items information
function Store.GetItems()
	Store.Items = { }
	Store.Categories = { }
	Store.Categories[-1] = { name = "Colors" }
	Store.Ready = false

	local file = Files.Open("../data/store.txt")
	if (not file.data) then
		if (not file:isDownloading()) then
			Store.Download()
		end
		return
	end
	local lines = file:readAll()
	file:close()

	for _, ln in pairs(lines) do
		if string.match(ln, "^PRODUCT") then
			pcall(function()
				local item = StoreItem.FromDataLine(ln)
				if (item ~= nil) then
					Store.Categories[item.catid] = { name = item.catname }
					Store.Items[item.itemid] = item
				end
			end)
		end
	end

	StoreInternal.RegisterIAPItems()
	Store.Ready = true
end

function StoreInternal.RegisterIAPItems()
	if (not is_mobile() or not StoreInternal.IAPInterfaceReady or StoreInternal.InAppIdentifiersReady) then return end

	---@type integer[]
	local usdItems = {}
	for _, v in pairs(Store.Items) do
		if (in_array(v.catid, StoreInternal.Categories.Account) and not v.locked) then
			table.insert(usdItems, v.itemid)
		end
	end
	if (#usdItems > 0) then
		register_platform_mtx(usdItems)
		StoreInternal.InAppIdentifiersReady = true
	end
end

---Parses store models datafile and populates obj items information
function Store.GetModelsData()
	Store.Models = { }
	local file = Files.Open("../data/store_obj.txt")
	if (not file.data) then return end

	local fileData = file:readAll()
	file:close()

	local data_types = {
		{ "itemid", numeric = true },
		{ "bodyid", numeric = true },
		{ "colorid", numeric = true },
		{ "alpha", numeric = true },
		{ "dynamic", boolean = true },
		{ "partless", boolean = true },
		{ "level", numeric = true },
		{ "textured", boolean = true },
		{ "level_name" }
	}
	for _, ln in pairs(fileData) do
		pcall(function()
			if string.match(ln, "^OBJ") then
				local _, segments = ln:gsub("\t", "")
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local item = {}
				for i, v in pairs(data_types) do
					if (v.numeric) then
						item[v[1]] = tonumber(data_stream[i + 1])
					elseif (v.boolean) then
						item[v[1]] = data_stream[i + 1] == '1' and true or false
					else
						item[v[1]] = data_stream[i + 1]
					end
				end
				if (item.level > 0) then
					Store.Models[item.itemid] = Store.Models[item.itemid] or { itemid = item.itemid, levels = 0, upgradeable = true }
					Store.Models[item.itemid][item.level] = item
					Store.Models[item.itemid].levels = Store.Models[item.itemid].levels + 1
				else
					Store.Models[item.itemid] = item
				end
			end
		end)
	end
end

---@class StoreCategoryDisplayInfo
---@field name string
---@field list integer[]

---Returns main information about store sections
---@param sectionid integer
---@return StoreCategoryDisplayInfo
function Store.GetStoreSection(sectionid)
	if (sectionid == StoreInternal.Tabs.Colors) then
		return { name = TB_MENU_LOCALIZED.STORECOLORSNAME, list = StoreInternal.Categories.Colors }
	elseif (sectionid == StoreInternal.Tabs.FlameForge) then
		return { name = TB_MENU_LOCALIZED.STOREFLAMEFORGENAME, list = { } }
	elseif (sectionid == StoreInternal.Tabs.Advanced) then
		return { name = TB_MENU_LOCALIZED.STOREADVANCEDNAME, list = StoreInternal.Categories.Advanced }
	elseif (sectionid == StoreInternal.Tabs.Account) then
		return { name = TB_MENU_LOCALIZED.STOREACCOUNT, list = StoreInternal.Categories.Account }
	end
	return { name = TB_MENU_LOCALIZED.UNDEF, list = { } }
end

---Returns item information from Store cache. \
---If information for the specified item ID is missing, returns empty item info.
---@param itemid integer
---@return StoreItem
function Store:getItemInfo(itemid)
	local itemid = tonumber(itemid)
	if (not self.Ready) then
		self.GetItems()
	end
	if (self.Items[itemid]) then
		return self.Items[itemid]:getCopy()
	end

	self.Download()
	return StoreInternal.EmptyItem:getCopy()
end

---Returns information about a Store category if it's defined
---@param catid integer
---@return StoreItemCategory
function Store:getCategoryInfo(catid)
	if (Store.Categories[catid] == nil) then
		return { name = TB_MENU_LOCALIZED.UNDEF }
	end
	return table.clone(Store.Categories[catid])
end

---Returns whether the item with the specified itemid is a texture
function Store:isTextureItem(itemid)
	return Store:getItemInfo(itemid):isTexture()
end

---Returns item icon path for the specified StoreItem object or by its itemid \
---***Important:** if you know you're operating with a **StoreItem** object, use its `getIconPath()` method directly for better performance*
---@param item StoreItem
---@return string
---@overload fun(self: Store, itemid: integer):string
function Store:getItemIcon(item)
	if (getmetatable(item) == StoreItem) then
		return item:getIconPath()
	end
	return "../textures/store/items/" .. tostring(item) .. ".tga"
end

---Returns whether the specified StoreItem object or item with the provided itemid supports effects \
---***Important:** if you know you're operating with a **StoreItem** object, use its `supportsEffects()` method directly for better performance*
---@param item StoreItem
---@return boolean
---@overload fun(self: Store, itemid: integer):boolean
function Store:itemSupportsEffects(item)
	if (getmetatable(item) == StoreItem) then
		return item:supportsEffects()
	end
	---@diagnostic disable-next-line: param-type-mismatch
	return Store:getItemInfo(item):supportsEffects()
end

---Returns featured sale item
---@return StoreItem?
function Store:getSaleFeatured()
	for _, v in pairs(Store.Items) do
		if (v.on_sale and v.sale_promotion) then
			return v:getCopy()
		end
	end
	return nil
end

---Returns list of items that are currently on sale
---@return StoreItem[]
function Store:getSaleItems()
	---@type StoreItem[]
	local saleItems = { }
	for _, v in pairs(Store.Items) do
		if (v.on_sale) then
			table.insert(saleItems, v:getCopy())
		end
	end
	return saleItems
end

---Creates a new InventoryItem instance from a datafile line
---@param ln string
---@return InventoryItem?
function InventoryItem.FromDataLine(ln)
	local _, segments = ln:gsub("\t", "")
	if (segments < #StoreInternal.InventoryItemFields + 1) then
		return nil
	end
	local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }

	---@type InventoryItem
	local item = { }
	for i, v in pairs(StoreInternal.InventoryItemFields) do
		item[v[1]] = data_stream[i + 1]
		if (v.numeric) then
			item[v[1]] = tonumber(item[v[1]])
		end
		if (v.boolean) then
			item[v[1]] = item[v[1]] == "1"
		end
	end
	local storeItem = Store:getItemInfo(item.itemid)
	item.name = storeItem.itemname
	item.upgradeable = item.upgrade_level > 0
	item.customizable = item.upgradeable or item.uploadable or storeItem:supportsEffects()

	if (item.itemid == ITEM_SET) then
		item.contents = { }
	end

	setmetatable(item, InventoryItem)
	return item
end

---Returns a copy of the current StoreInventory object
---@return InventoryItem
function InventoryItem:getCopy()
	---@type InventoryItem
	local item = {}
	for i, v in pairs(self) do
		item[i] = v
	end
	setmetatable(item, InventoryItem)
	return item
end

---Returns inventory item icon path. Checks for custom icon existence on user device by default.
---@param forceCustom boolean?
---@return string
function InventoryItem:getIconPath(forceCustom)
	local customIconPath = "textures/store/inventory/" .. self.inventid .. ".tga"
	if (forceCustom or Files.Exists("../data/" .. customIconPath)) then
		return "../" .. customIconPath
	end
	return "../textures/store/items/" .. self.itemid .. ".tga"
end

---Marks inventory item (and all items inside in case of sets) inactive. \
---*This does **not** fire a network request to actually deactivate items and is only used for local inventory manipulations.*
function InventoryItem:deactivate()
	self.active = false
	if (self.contents ~= nil) then
		for _, v in pairs(self.contents) do
			v.active = false
		end
	end
end

---Parses user inventory datafile and returns a list of InventoryItem objects reflecting it. \
---When used without arguments, parses current user's inventory data and caches it in **Store** class for later use.
---@param path string Inventory datafile path
---@return InventoryItem[]?
---@overload fun()
function Store.ParseInventory(path)
	local file = Files.Open(path or "../data/inventory.txt")
	if (not file.data) then return end

	---@type InventoryItem[]
	local inventory = { }
	local itemUpdated = path == nil or Store.InventoryCurrentItem == nil
	local lines = file:readAll()
	file:close()

	for _, ln in pairs(lines) do
		if string.match(ln, "^INVITEM") then
			local res, err = pcall(function()
				local item = InventoryItem.FromDataLine(ln)
				if (item) then
					if (not itemUpdated) then
						if (item.inventid == Store.InventoryCurrentItem.inventid) then
							Store.InventoryCurrentItem = item
							itemUpdated = true
						end
					end
					if (item.itemid ~= ITEM_SHIAI_TOKEN) then
						table.insert(inventory, item)
					end
				end
			end)
			if (res == false) then
				Files.LogError(err)
			end
		end
	end

	for _, v in pairs(inventory) do
		if (v.setid ~= 0) then
			for _, k in pairs(inventory) do
				if (v.setid == k.inventid) then
					v.parentset = k
					table.insert(k.contents, v)
					break
				end
			end
		end
	end

	if (path ~= nil) then
		return inventory
	end

	if (not itemUpdated) then
		Store.InventoryCurrentItem = nil
	end
	Store.Inventory = inventory

	if (#Store.InventorySelectedItems > 0) then
		local selectedInvids = {}
		for _, v in pairs(Store.InventorySelectedItems) do
			table.insert(selectedInvids, v.inventid)
		end
		Store.ClearInventorySelectedItems()
		for _, v in pairs(Store.Inventory) do
			if (in_array(v.inventid, selectedInvids)) then
				table.insert(Store.InventorySelectedItems, v)
			end
		end
	end
	Request:queue(check_color_achievement, "checkColorAchievements")
end

---Returns list of inventory items with the specified itemid
---@param itemid integer
---@return InventoryItem[]
function Store:getInventoryItems(itemid)
	local items = {}
	for _, v in pairs(Store.Inventory or {}) do
		if (v.itemid == itemid) then
			table.insert(items, v:getCopy())
		end
	end
	return items
end

---Returns filtered and sorted inventory information to be used in Inventory UI. \
---*If you're looking for base inventory manipulations, see references listed below.*
---@see Store.Inventory
---@see Store.getInventoryItems
---@see Store.ParseInventory
---@param mode InventoryDisplayMode
---@return InventoryItem[]
function Store:getInventory(mode)
	if (Store.Inventory == nil) then
		return { }
	end

	local inventory = { }

	for _, v in pairs(Store.Inventory) do
		if (v.setid == 0) then
			if 	(mode == INVENTORY_ACTIVATED and v.active) or
				(mode == INVENTORY_DEACTIVATED and not v.active) or
				(mode == INVENTORY_ALL) then
				table.insert(inventory, v)
			end
		elseif (v.active and mode == INVENTORY_ACTIVATED and (v.parentset and not v.parentset.active)) then
			table.insert(inventory, v)
		end
	end
	return table.qsort(inventory, "name", SORT_ASCENDING)
end

---Exits Store or Inventory and unsets the required menu overrides
function Store.Quit()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu:clearNavSection()
	if (not is_mobile() and STORE_VANILLA_PREVIEW) then
		STORE_VANILLA_PREVIEW = false
		remove_hooks(Store.HookNameVanilla)
		set_option("uke", 1)
		set_option("tooltip", STORE_VANILLA_TOOLTIP)
		TBMenu.HideButton:show()
		Store.VanillaPreviewer:kill()
		STORE_VANILLA_POST = true
		start_new_game()
	end
	TBMenu:showNavigationBar()
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

---Returns list of buttons to use in navigation while viewing Store sections
---@param viewElement UIElement
---@return MenuNavButton[]
function Store:getNavigation(viewElement)
	local buttons = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
			action = Store.Quit,
		},
		{
			text = TB_MENU_LOCALIZED.STOREPRIME,
			action = function() Store:showPrime() end,
			right = true,
			bgColor = TB_MENU_DEFAULT_ORANGE,
			hoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			pressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			uiColor = { 0, 0, 0, 0.6 }
		},
		{
			text = TB_MENU_LOCALIZED.STOREACCOUNT,
			action = function() Store:showStoreSection(viewElement, 4) end,
			sectionId = StoreInternal.Tabs.Account,
			right = true,
		},
		{
			text = TB_MENU_LOCALIZED.STOREADVANCED,
			action = function() Store:showStoreSection(viewElement, 3) end,
			sectionId = StoreInternal.Tabs.Advanced,
			right = true,
		},
		{
			text = TB_MENU_LOCALIZED.STORECOLORS,
			action = function() Store:showStoreSection(viewElement, 1) end,
			sectionId = StoreInternal.Tabs.Colors,
			right = true,
		}
	}
	return buttons
end

---Returns list of buttons to use in navigation while in Inventory
---@param showBack boolean?
---@return MenuNavButton[]
function Store:getInventoryNavigation(showBack)
	local navigation = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = Store.Quit
		},
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
			action = function()
				if (Store.InventorySearch ~= nil and Store.InventorySearch ~= "") then
					Store.InventorySearch = nil
				else
					Store.InventoryListShift[1] = Store.InventoryLastListShift
					if (Store.InventoryCurrentItem ~= nil) then
						Store.InventoryCurrentItem = Store.InventoryCurrentItem.parentset
					end
				end
				Store:showInventory(TBMenu.CurrentSection, nil, Store.InventoryShowEmptySets)
			end,
			hidden = not showBack
		}
	}
	return navigation
end

---Displays provided list of inventory items' icons in a UIElement viewport
---@param viewElement UIElement
---@param items InventoryItem[]
function Store:showSetDetailsItems(viewElement, items)
	local itemScale = math.min(viewElement.size.h / 2, 64)
	local line = 1
	local itemsPerLine = math.floor(viewElement.size.w / itemScale)
	local horizontalShift = (viewElement.size.w - itemsPerLine * itemScale) / 2
	for i, v in pairs(items) do
		if (line * itemScale > viewElement.size.h) then
			break
		end
		local iconHolder = viewElement:addChild({
			pos = { horizontalShift + ((i - 1) % itemsPerLine) * itemScale, (line - 1) * itemScale },
			size = { itemScale, itemScale }
		})
		iconHolder:addChild({
			shift = { 2, 2 },
			bgImage = v:getIconPath()
		})
		if (i % itemsPerLine == 0) then
			line = line + 1
		end
	end
end

---Returns information about an item that's going to be deactivated in case specified item will be activated in user's inventory
---@param item InventoryItem
---@return InventoryItem?
function Store:getItemToDeactivate(item)
	if (item.itemid == 0) then
		return nil
	end
	local targetItem = self:getItemInfo(item.itemid)
	if (targetItem.itemid == 0) then
		return nil
	end

	local noCheckCategories = {
		StoreCategory.Flames,
		StoreCategory.Sets,
		StoreCategory.Sounds,
		StoreCategory.JointTextures,
		StoreCategory.Music,
		StoreCategory.ComicEffects
	}
	local textureCategories = {
		StoreCategory.BodyTextures,
		StoreCategory.MiscTextures,
		StoreCategory.BumpmapTextures,
		StoreCategory.TrailTextures,
		StoreCategory.GUITextures
	}
	local targetModel = Store.Models[item.itemid]
	if (targetModel and item.upgradeable) then
		targetModel = targetModel[item.upgrade_level]
	end
	for _, v in pairs(Store.Inventory or {}) do
		if (v.active) then
			local res, item = pcall(function()
				if (targetItem.catid == Store.Items[v.itemid].catid) then
					if (targetModel and targetItem.catid == StoreCategory.Objects3D and Store.Models[v.itemid]) then
						local modelInfo = v.upgradeable and Store.Models[v.itemid][v.upgrade_level] or Store.Models[v.itemid]
						if (targetModel.bodyid == modelInfo.bodyid) then
							return v
						end
					elseif (in_array(targetItem.catid, textureCategories)) then
						if (item.bodypartname == v.bodypartname) then
							return v
						end
					elseif (not in_array(targetItem.catid, noCheckCategories)) then
						return v
					end
				end
			end)
			if (res and item ~= nil) then
				return item
			end
		end
	end
	return nil
end

---Clears `Store.InventorySelectedItems` list
function Store.ClearInventorySelectedItems()
	for i = #Store.InventorySelectedItems, 1, -1 do
		table.remove(Store.InventorySelectedItems, i)
	end
end

---Displays information about the specified inventory item
---@param item InventoryItem?
function Store:showInventoryItem(item)
	Store.InventoryItemView:kill(true)
	Store.InventoryCurrentItem = item

	TBMenu:addBottomBloodSmudge(Store.InventoryItemView, 2)

	if (item == nil) then return end
	local itemData = Store:getItemInfo(item.itemid)

	local itemName = Store.InventoryItemView:addChild({
		pos = { 10, 0 },
		size = { Store.InventoryItemView.size.w - 20, 50 }
	})
	if (item.itemid == ITEM_SET) then
		local numItemsStr = "(" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
		if (item.contents) then
			if (#item.contents == 1) then
				numItemsStr = "(1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
			elseif (#item.contents > 1) then
				numItemsStr = "(" .. #item.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
			end
		end

		itemName:addAdaptedText(true, item.name .. " " .. numItemsStr, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
		local setName = Store.InventoryItemView:addChild({
			pos = { 0, itemName.size.h },
			size = { Store.InventoryItemView.size.w, 20 }
		})
		setName:addAdaptedText(true, item.setname)
		local inventoryViewHeight = Store.InventoryItemView.size.h / 2 - itemName.size.h - setName.size.h
		inventoryViewHeight = math.min(inventoryViewHeight, 100)
		local inventoryView = Store.InventoryItemView:addChild({
			pos = { 10, itemName.size.h + setName.size.h + 10 },
			size = { Store.InventoryItemView.size.w - 20, inventoryViewHeight }
		})
		if (item.contents and #item.contents > 0) then
			Store:showSetDetailsItems(inventoryView, item.contents)
		else
			inventoryView:addAdaptedText(true, itemData.description, nil, nil, 4, LEFTMID, 0.7)
		end
	elseif (item.itemid == ITEM_FLAME) then
		itemName:addAdaptedText(true, item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
		local flameName = Store.InventoryItemView:addChild({
			pos = { 0, itemName.size.h },
			size = { Store.InventoryItemView.size.w, 20 }
		})
		flameName:addAdaptedText(true, item.flamename)
		local itemInfoHeight = Store.InventoryItemView.size.h / 2 - itemName.size.h - flameName.size.h
		itemInfoHeight = math.min(itemInfoHeight, 100)
		local itemInfo = Store.InventoryItemView:addChild({
			pos = { 10, itemName.size.h + flameName.size.h + 10 },
			size = { Store.InventoryItemView.size.w - 20, itemInfoHeight }
		})
		itemInfo:addChild({
			pos = { 0, (itemInfo.size.h - 64) / 2 },
			size = { 64, 64 },
			bgImage = item:getIconPath()
		})
		local itemDescription = itemInfo:addChild({
			pos = { 69, 0 },
			size = { itemInfo.size.w - 69, itemInfo.size.h }
		})
		itemDescription:addAdaptedText(true, TB_MENU_LOCALIZED.STOREFLAMEBODYPART .. " ".. utf8.lower(item.bodypartname) .. "\n" .. TB_MENU_LOCALIZED.STOREFLAMEID .. ": " .. item.flameid, nil, nil, 4, LEFTMID, 0.7)
	else
		local itemNameStr = itemData.itemname
		if (itemData.catid == StoreCategory.Objects3D) then
			if (item.setname ~= '0') then
				itemNameStr = item.setname
			elseif (item.upgrade_level > 0) then
				itemNameStr = itemNameStr.. " (LVL " .. item.upgrade_level .. ")"
			end
		end
		if (item.parentset ~= nil) then
			itemName:addAdaptedText(false, itemNameStr, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
			local setCaption = Store.InventoryItemView:addChild({
				pos = { 10, 50 },
				size = { Store.InventoryItemView.size.w - 20, 20 }
			})
			setCaption:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMINSIDESET .. ": " .. item.parentset.setname)
		else
			itemName.size.h = 70
			itemName:addAdaptedText(false, itemNameStr, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
		end

		local itemInfoHeight = Store.InventoryItemView.size.h / 2 - 80
		itemInfoHeight = math.min(itemInfoHeight, 100)
		local itemInfo = Store.InventoryItemView:addChild({
			pos = { 10, 80 },
			size = { Store.InventoryItemView.size.w - 20, itemInfoHeight }
		})
		itemInfo:addChild({
			pos = { 0, (itemInfo.size.h - 64) / 2 },
			size = { 64, 64 },
			bgImage = Store:getItemIcon(item.itemid)
		})
		local itemDescription = itemInfo:addChild({
			pos = { 69, 0 },
			size = { itemInfo.size.w - 69, itemInfo.size.h }
		})
		local modelBodypartStr = ''
		if (item.bodypartname ~= '0') then
			modelBodypartStr = (item.uploadable and TB_MENU_LOCALIZED.STOREITEMRETEXTURABLE .. " " or "" ) .. TB_MENU_LOCALIZED.STOREOBJITEMBODYPART .. " " .. item.bodypartname:lower()
		end
		itemDescription:addAdaptedText(true, itemData.description .. "\n" .. modelBodypartStr, nil, nil, 4, LEFTMID, 0.7)
	end

	local buttonHeight = math.min(Store.InventoryItemView.size.h / 10, 55)
	local buttonYPos = -buttonHeight * 1.1
	if (item.itemid ~= ITEM_SET) then
		local addSetButton = Store.InventoryItemView:addChild({
			pos = { 10, buttonYPos },
			size = { Store.InventoryItemView.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		if (item.parentset ~= nil) then
			addSetButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMGOTOSET)
			addSetButton:addMouseUpHandler(function()
					Store.InventoryLastListShift = Store.InventoryListShift[1]
					Store.InventoryListShift[1] = 0
					Store:showInventoryPage(item.parentset.contents, nil, nil, TB_MENU_LOCALIZED.STORESETITEMNAME .. ": " .. item.parentset.setname, "invid" .. item.parentset.inventid, nil, true)
				end)
		elseif (item.setid == 0) then
			addSetButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMADDTOSET)
			addSetButton:addMouseUpHandler(function()
					Store:showSetSelection(item)
				end)
		else
			addSetButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMREMOVEFROMSET)
			addSetButton:addMouseUpHandler(function()
					Store:spawnInventoryUpdateWaiter(Store.ClearInventorySelectedItems)
					local dialogMessage = TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 .. "?")
					show_dialog_box(StoreInternal.InventoryActions.RemoveSet, dialogMessage, "0 " .. item.inventid)
				end)
		end
		buttonYPos = buttonYPos - buttonHeight * 1.2
	elseif (item.contents and #item.contents > 0) then
		local viewSet = Store.InventoryItemView:addChild({
			pos = { 10, buttonYPos },
			size = { Store.InventoryItemView.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		viewSet:addAdaptedText(false, TB_MENU_LOCALIZED.STOREVIEWSETITEMS)
		viewSet:addMouseUpHandler(function()
				Store.InventoryLastListShift = Store.InventoryListShift[1]
				Store.InventoryListShift[1] = 0
				Store.InventoryCurrentItem = nil
				Store:showInventoryPage(item.contents, nil, nil, TB_MENU_LOCALIZED.STOREITEMSINSET .. ": " .. item.setname, "invid" .. item.inventid, nil, true)
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end
	if (Market:itemEligible(itemData)) then
		local marketSellButton = Store.InventoryItemView:addChild({
			pos = { 10, buttonYPos },
			size = { Store.InventoryItemView.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		marketSellButton:addAdaptedText(false, TB_MENU_LOCALIZED.STORESELLMARKET)
		marketSellButton:addMouseUpHandler(function()
				Market:showSellInventoryItem({ item })
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end
	if (item.customizable) then
		local customizeButton = Store.InventoryItemView:addChild({
			pos = { 10, buttonYPos },
			size = { Store.InventoryItemView.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		customizeButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMSCUSTOMIZE)
		customizeButton:addMouseUpHandler(function()
				Store:showInventoryItemCustomize(item)
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end
	if (item.activateable and not item.unpackable) then
		local activateButton = Store.InventoryItemView:addChild({
			pos = { 10, buttonYPos },
			size = { Store.InventoryItemView.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		if (item.active) then
			activateButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMDEACTIVATE)
			activateButton:addMouseUpHandler(function()
					Store:spawnConfirmationWaiter(function()
						item:deactivate()
						Store:showInventory(TBMenu.CurrentSection, nil, Store.InventoryShowEmptySets)
						update_tc_balance()
					end)
					show_dialog_box(StoreInternal.InventoryActions.Deactivate, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), tostring(item.inventid))
				end)
		else
			local itemToDeactivate = Store:getItemToDeactivate(item)
			activateButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMACTIVATE)
			activateButton:addMouseUpHandler(function()
					Store:spawnInventoryUpdateWaiter()
					show_dialog_box(StoreInternal.InventoryActions.Activate, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?") .. "\n" .. (itemToDeactivate and itemToDeactivate.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGITEMCONFLICTDEACTIVATE or TB_MENU_LOCALIZED.STOREDIALOGCONFLICTSDEACTIVATE), tostring(item.inventid))
				end)
		end
	elseif (item.unpackable) then
		local unpackButton = Store.InventoryItemView:addChild({
			pos = { 10, buttonYPos },
			size = { Store.InventoryItemView.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		unpackButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMUNPACK)
		unpackButton:addMouseUpHandler(function()
				Store:spawnInventoryUpdateWaiter()
				show_dialog_box(StoreInternal.InventoryActions.Unpack, TB_MENU_LOCALIZED.STOREDIALOGUNPACK1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, tostring(item.inventid))
			end)
	end
end

---Displays an inventory item level mass change window
---@param items InventoryItem[]
function Store:showInventoryItemsChangeLevel(items)
	local overlay = TBMenu:spawnWindowOverlay(true)

	local changeLevelHolder = overlay:addChild({
		pos = { WIN_W / 2 - 300, WIN_H / 2 - 100 },
		size = { 600, 200 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	TBMenu:spawnCloseButton(changeLevelHolder, { x = -50, y = 10, h = 40, w = 40 }, overlay.btnUp)

	local changeLevelTitle = changeLevelHolder:addChild({
		pos = { 60, 10 },
		size = { changeLevelHolder.size.w - 120, 50 }
	})
	changeLevelTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STORECHANGELEVELWINDOWTITLE, nil, nil, FONTS.BIG)

	local maxLevel = items[1].upgrade_max_level
	local currentLevel = items[1].upgrade_level
	local levelNames = { }
	for i = 1, maxLevel do
		pcall(function()
			if (Store.Models[items[1].itemid][i].level_name ~= '') then
				levelNames[i] = Store.Models[items[1].itemid][i].level_name
			end
		end)
	end
	local invidsList = {}
	for _, item in pairs(items) do
		maxLevel = math.min(maxLevel, item.upgrade_max_level)
		table.insert(invidsList, item.inventid)
		if (currentLevel ~= nil) then
			if (currentLevel ~= item.upgrade_level) then
				---@diagnostic disable-next-line: cast-local-type
				currentLevel = nil
			end
		end
		for i = 1, maxLevel do
			pcall(function()
				if (levelNames[i] ~= Store.Models[item.itemid][i].level_name) then
					levelNames[i] = ""
				end
			end)
		end
	end

	local currentUpgradesList = { }
	if (currentLevel == nil) then
		table.insert(currentUpgradesList, {
			text = TB_MENU_LOCALIZED.STORECHANGELEVELSELECT,
			default = true,
			selected = true
		})
	end
	for i = 1, maxLevel do
		local levelName = levelNames[i] ~= "" and levelNames[i] or (TB_MENU_LOCALIZED.STOREITEMLEVEL .. " " .. i)
		table.insert(currentUpgradesList, {
			text = levelName,
			action = function()
				Store:spawnInventoryUpdateWaiter(overlay.btnUp)
				show_dialog_box(StoreInternal.InventoryActions.Upgrade, TB_MENU_LOCALIZED.STOREDIALOGCHANGELEVEL1 .. " " .. levelName .. " " .. TB_MENU_LOCALIZED.STOREDIALOGCHANGELEVELMULTIPLE, table.implode(invidsList, ";") .. ";0;" .. i)
			end,
			selected = i == currentLevel
		})
	end

	local upgradesChangeTitle = changeLevelHolder:addChild({
		pos = { 20, 80 },
		size = { changeLevelHolder.size.w - 40, 50 }
	})
	upgradesChangeTitle:addAdaptedText(true, TB_MENU_LOCALIZED.INVENTORYCHOOSEITEMUPGRADELEVEL, nil, nil, nil, LEFTMID)
	local upgradesDropdownHolder = changeLevelHolder:addChild({
		pos = { upgradesChangeTitle.shift.x, upgradesChangeTitle.shift.y + upgradesChangeTitle.size.h },
		size = { upgradesChangeTitle.size.w, 50 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}, true)
	TBMenu:spawnDropdown(upgradesDropdownHolder, currentUpgradesList, upgradesDropdownHolder.size.h, nil, nil, { scale = 0.7, fontid = 4 }, { scale = 0.65, fontid = 4 })
end

---Displays inventory item customization window
---@param item InventoryItem
function Store:showInventoryItemCustomize(item)
	local overlay = TBMenu:spawnWindowOverlay(true)

	local customizeSize = { x = 600, y = 500 }
	local customizeHolder = overlay:addChild({
		pos = { (WIN_W - customizeSize.x) / 2, (WIN_H - customizeSize.y) / 2},
		size = { customizeSize.x, customizeSize.y },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	TBMenu:spawnCloseButton(customizeHolder, { x = -40, y = 10, h = 30, w = 30 }, overlay.btnUp)

	local customizeTitle = customizeHolder:addChild({
		pos = { 50, 10 },
		size = { customizeHolder.size.w - 100, 40 }
	})
	customizeTitle:addAdaptedText(true, TB_MENU_LOCALIZED.INVENTORYCUSTOMIZING .. " " .. item.name, nil, nil, FONTS.BIG)

	local customizeSectionHolder = customizeHolder:addChild({
		pos = { 20, 105 },
		size = { customizeHolder.size.w - 40, customizeHolder.size.h - 120 }
	}, true)

	---@type function, function, function
	local customizeItemTexture, customizeItemLevel, customizeItemEffect
	---@param forceReload boolean?
	customizeItemTexture = function(forceReload)
		local customImagePath = item:getIconPath(true)
		customizeSectionHolder:kill(true)

		local topOffset = 0
		if (Store:getItemInfo(item.itemid).catid == StoreCategory.JointTextures) then
			local dropdownOverlay
			local function submitRenderMode(mode)
				local dropdownLoadIndicator = TBMenu:displayLoadingMark(dropdownOverlay.selectedElement, nil, 16)
				dropdownOverlay.selectedElement:deactivate()

				Request:queue(function()
					submit_texture_item_mode(item.inventid, mode)
				end, "set_texture_mode" .. item.inventid, function()
					local response = get_network_response()
					dropdownLoadIndicator:kill()
					dropdownOverlay.selectedElement:activate()
					if (response == "GATEWAY 0; 0 0") then
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.INVENTORYTEXTUREMODECHANGED)
						item.upgrade_level = mode
						update_tc_balance()
						return
					end
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
				end, function()
					dropdownLoadIndicator:kill()
					dropdownOverlay.selectedElement:activate()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASESERVERERROR .. "\n" .. get_network_error())
				end)
			end
			local renderModes = {
				{
					text = TB_MENU_LOCALIZED.INVENTORYTEXTUREMODEDEFAULT,
					action = function() submitRenderMode(0) end,
					selected = item.upgrade_level == 0
				}
			}
			for i = 2, 8 do
				table.insert(renderModes,{
					text = TB_MENU_LOCALIZED["INVENTORYTEXTUREMODE" .. i],
					action = function() submitRenderMode(i) end,
					selected = item.upgrade_level == i
				})
			end
			topOffset = topOffset + 50
			local renderModeLegend = customizeSectionHolder:addChild({
				pos = { 0, 0 },
				size = { customizeSectionHolder.size.w * 0.33 - 10, 40 }
			})
			renderModeLegend:addAdaptedText(TB_MENU_LOCALIZED.INVENTORYTEXTUREDISPLAYMODE, nil, nil, nil, LEFTMID)
			local renderModeDropdownHolder = customizeSectionHolder:addChild({
				pos = { renderModeLegend.size.w + 10, renderModeLegend.shift.y },
				size = { customizeSectionHolder.size.w * 0.667, renderModeLegend.size.h },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			dropdownOverlay = TBMenu:spawnDropdown(renderModeDropdownHolder, renderModes, renderModeDropdownHolder.size.h * 0.8, nil, nil, {
				fontid = 4,
				alignment = CENTERMID,
				scale = 0.8,
				uppercase = true
			}, {
				fontid = 4,
				alignment = CENTERMID,
				scale = 0.65,
				uppercase = false
			})
		end

		local itemImage = customizeSectionHolder:addChild({
			pos = { 0, topOffset + (customizeSectionHolder.size.h - topOffset - 256) / 2 },
			size = { 256, 256 },
			bgImage = {customImagePath, "../textures/store/inventory/noise.tga" }
		})
		itemImage.requireReload = itemImage.requireReload
		itemImage:addCustomDisplay(false, function()
				if (itemImage.requireReload and item.iconElement) then
					item.iconElement:updateImage(nil)
					itemImage:updateImage(customImagePath, "../textures/store/inventory/noise.tga")
					item.iconElement:updateImage(customImagePath, "../textures/store/inventory/noise.tga")
					itemImage.requireReload = false
					itemImage:addCustomDisplay(false, function() end)
				end
			end)

		local itemImageRefreshing = itemImage:addChild({
			bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
		})
		TBMenu:displayLoadingMark(itemImageRefreshing)
		TBMenu:addOuterRounding(itemImage)

		local hookName = self.HookName .. "Inv" .. item.inventid
		local onImageDownloaded = function()
			itemImageRefreshing:kill()
			remove_hooks(hookName)
			itemImage.requireReload = true
		end

		Request:queue(function()
				download_server_file("customtexture&invid=" .. item.inventid, 0)
			end, "torishop_inventory_" .. item.inventid .. "_texture_prepare", function()
				if (itemImage.destroyed) then return end
				local response = get_network_response()
				if (not response:find("^ERROR")) then
					if (not forceReload) then
						if (Files.Exists(item:getIconPath(true))) then
							onImageDownloaded()
							return
						end
					end
					-- Wasn't there, wait for downloader
					add_hook("downloader_complete", hookName, function(name)
						if (name:match("^.*/store/inventory/" .. item.inventid .. ".tga")) then
							Downloader.SafeCall(onImageDownloaded)
						end
					end)
					-- get_downloads() doesn't get updated until after this code is run, add a pre_draw hook to check on next frame
					add_hook("pre_draw", hookName, function()
							if (#get_downloads() == 0) then
								onImageDownloaded()
							end
						end)
				else
					itemImageRefreshing:kill()
					itemImage:addAdaptedText(false, TB_MENU_LOCALIZED.INVENTORYNOTEXTUREUPLOADED, nil, nil, FONTS.BIG, nil, 0.6)
				end
			end, function()
				itemImageRefreshing:kill()
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
			end)

		local uploadTextureButton = customizeSectionHolder:addChild({
			pos = { 270, itemImage.shift.y + itemImage.size.h - 154 },
			size = { customizeSectionHolder.size.w - 270, 70 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		local function doShowUploadFile(filename)
			local filenameNoPath = filename:gsub(".*[%\\%/](.+%.%w+)$", "%1")
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.INVENTORYUPLOADTEXTURECONFIRM1 .. " " .. filenameNoPath .. " " .. TB_MENU_LOCALIZED.INVENTORYUPLOADTEXTURECONFIRM2 .. " " .. item.name .. "?\n" .. TB_MENU_LOCALIZED.INVENTORYUPLOADTEXTUREOVERWRITENOTICE, function()
					local uploadInProgress = customizeHolder:addChild({
						bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
						interactive = true
					})
					TBMenu:displayLoadingMark(uploadInProgress, TB_MENU_LOCALIZED.INVENTORYUPLOADINGFILE)
					Request:queue(function()
							upload_item_texture(item.inventid, filename)
						end, "upload_texture", function()
							if (not uploadInProgress or uploadInProgress.destroyed) then return end
							uploadInProgress:kill()
							local response = get_network_response()
							if (response:find("success")) then
								customizeItemTexture(true)
							else
								if (response:match("^.*; 0 1$")) then
									TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
								else
									local error = response:gsub("^GATEWAY 0; (.*) %d", "%1")
									TBMenu:showStatusMessage(error)
								end
							end
						end, function()
							uploadInProgress:kill()
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
						end)
				end)
		end
		uploadTextureButton.killAction = function() remove_hook("dropfile", self.HookName) end
		add_hook("dropfile", self.HookName, function(filename)
				local fileext = string.gsub(filename, "^.*%.([a-zA-Z0-9]+)$", "%1")
				if (in_array(fileext, { 'jpg', 'jpeg', 'png', 'tga', 'gif', 'bmp' })) then
					doShowUploadFile(filename)
				end
			end)
		uploadTextureButton:addAdaptedText(false, TB_MENU_LOCALIZED.INVENTORYUPLOADNEWTEXTURE)
		uploadTextureButton:addMouseUpHandler(function()
				if (open_file_browser("Image Files", "jpg;jpeg;png;tga;gif;bmp", "All Files", "*")) then
					add_hook("filebrowser_select", self.HookName, function(filename)
							if (filename ~= "") then
								doShowUploadFile(filename)
							end
							remove_hook("filebrowser_select", self.HookName)
							return 1
						end)
				end
			end)

		local resetTextureButton = customizeSectionHolder:addChild({
			pos = { 270, itemImage.shift.y + itemImage.size.h - 70 },
			size = { customizeSectionHolder.size.w - 270, 70 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		resetTextureButton:addAdaptedText(false, TB_MENU_LOCALIZED.INVENTORYRESETTEXTURE)
		resetTextureButton:addMouseUpHandler(function()
				local uploadInProgress = customizeHolder:addChild({
					bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
					interactive = true
				})
				TBMenu:displayLoadingMark(uploadInProgress, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT)
				Request:queue(function()
					Store:spawnConfirmationWaiter(nil, function()
						Request:finalize("inventory_tex" .. item.inventid .. "_reset")
						uploadInProgress:kill()
					end)
					show_dialog_box(StoreInternal.InventoryActions.TextureReset, TB_MENU_LOCALIZED.INVENTORYTEXTURERESETCONFIRM, tostring(item.inventid), true)
				end, "inventory_tex" .. item.inventid .. "_reset", function()
					uploadInProgress:kill()
					customizeItemTexture(true)
				end, function()
					uploadInProgress:kill()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
				end)
			end)
	end

	customizeItemLevel = function()
		customizeSectionHolder:kill(true)

		local shiftY = 0
		if (item.upgrade_max_level > 1) then
			local onTargetLevelChange
			local currentUpgradesList = { }
			local targetLevel = item.upgrade_level
			for i = 1, item.upgrade_max_level do
				local levelName = TB_MENU_LOCALIZED.STOREITEMLEVEL .. " " .. i
				pcall(function()
					if (Store.Models[item.itemid][i].level_name ~= '') then
						levelName = Store.Models[item.itemid][i].level_name
					end
				end)
				table.insert(currentUpgradesList, {
					text = levelName,
					action = function()
							targetLevel = i
							onTargetLevelChange()
						end,
					locked = targetLevel == i
				})
			end

			local upgradesChangeTitle = customizeSectionHolder:addChild({
				size = { customizeSectionHolder.size.w, 30 }
			})
			upgradesChangeTitle:addAdaptedText(true, TB_MENU_LOCALIZED.INVENTORYCHOOSEITEMUPGRADELEVEL, nil, nil, nil, LEFTMID)
			local upgradesDropdownHolder = customizeSectionHolder:addChild({
				pos = { 0, 40 },
				size = { customizeSectionHolder.size.w / 3 * 2 - 5, 40 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			}, true)
			TBMenu:spawnDropdown(upgradesDropdownHolder, currentUpgradesList, upgradesDropdownHolder.size.h, customizeSectionHolder.size.h, currentUpgradesList[targetLevel], { scale = 0.7, fontid = 4 }, { scale = 0.65, fontid = 4 })
			local setUpgradeButton = customizeSectionHolder:addChild({
				pos = { upgradesDropdownHolder.size.w + 10, upgradesDropdownHolder.shift.y },
				size = { customizeSectionHolder.size.w - upgradesDropdownHolder.size.w - 10, upgradesDropdownHolder.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
			}, true)
			setUpgradeButton:addAdaptedText(false, TB_MENU_LOCALIZED.INVENTORYAPPLYUPGRADE)
			setUpgradeButton:deactivate()
			onTargetLevelChange = function()
					setUpgradeButton:activate()
				end
			setUpgradeButton:addMouseUpHandler(function()
					Store:spawnInventoryUpdateWaiter(overlay.btnUp)
					show_dialog_box(StoreInternal.InventoryActions.Upgrade, TB_MENU_LOCALIZED.STOREDIALOGCHANGELEVEL1 .. " " .. targetLevel .. " " .. TB_MENU_LOCALIZED.STOREDIALOGCHANGELEVEL2 .. " " .. item.name .. "?", item.inventid .. ";0;" .. targetLevel)
				end)
			shiftY = shiftY + upgradesDropdownHolder.shift.y + upgradesDropdownHolder.size.h + 20
		end

		if (Store.Models[item.itemid] and item.upgrade_max_level < Store.Models[item.itemid].levels) then
			local upgradeNextLevel = customizeSectionHolder:addChild({
				pos = { 0, shiftY },
				size = { customizeSectionHolder.size.w, 30 }
			})
			upgradeNextLevel:addAdaptedText(true, TB_MENU_LOCALIZED.INVENTORYUPGRADEITEMNEXTLEVEL, nil, nil, nil, LEFTMID)
			local upgradeLevelButton = customizeSectionHolder:addChild({
				pos = { 0, shiftY + 35 },
				size = { customizeSectionHolder.size.w, 40 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
			}, true)
			upgradeLevelButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMUPGRADEFOR .. " " .. (item.upgrade_price > 0 and (item.upgrade_price .. " TC") or TB_MENU_LOCALIZED.STOREITEMUPGRADEPRICEFREE))
			upgradeLevelButton:addMouseUpHandler(function()
					Store:spawnInventoryUpdateWaiter(overlay.btnUp)
					show_dialog_box(StoreInternal.InventoryActions.Upgrade, TB_MENU_LOCALIZED.STOREDIALOGUPGRADE1 .. "\n" .. item.name .. " ".. TB_MENU_LOCALIZED.STOREDIALOGUPGRADE2 .. " " .. (item.upgrade_level + 1) .. "?", item.inventid .. ";" .. item.upgrade_price .. ";0")
				end)
			if (item.upgrade_games > item.games_played) then
				upgradeLevelButton:deactivate(true)
				local upgradeLevelNotice = customizeSectionHolder:addChild({
					pos = { 20, upgradeLevelButton.shift.y + upgradeLevelButton.size.h + 5 },
					size = { customizeSectionHolder.size.w - 40, 50 }
				})
				upgradeLevelNotice:addAdaptedText(true, TB_MENU_LOCALIZED.STOREYOUNEEDTOPLAYGAMES1 .. " " .. (item.upgrade_games - item.games_played) .. " " .. TB_MENU_LOCALIZED.STOREYOUNEEDTOPLAYGAMES2, nil, nil, 4, CENTER, 0.7)
			end
		end
	end

	customizeItemEffect = function()
		customizeSectionHolder:kill(true)

		local displayEffects = function(effectOptions, generalInfo)
			local shiftY = 0
			if (item.effectid > 0) then
				local effectUpdateRequirements = {
					chosenEffects = { },
					gamesPlayed = { },
					upgradePrice = { }
				}
				local onUpdateEffectSettings = function() end
				local effectCustomizeDropdownOptions, effectCustomizeDropdownActiveIds = {}, {}
				for i = 1, #StoreInternal.ItemEffects do
					effectCustomizeDropdownOptions[i] = {}
					if (effectOptions[i]) then
						for _, v in pairs(effectOptions[i]) do
							table.insert(effectCustomizeDropdownOptions[i], {
									text = v.upgradeName,
									action = function()
											effectUpdateRequirements.gamesPlayed[i] = not v.isActive and v.gamesPlayed or nil
											effectUpdateRequirements.chosenEffects[i] = not v.isActive and v.effectId or nil
											effectUpdateRequirements.upgradePrice[i] = item.games_played > v.gamesPlayed and 0 or math.ceil((v.gamesPlayed - item.games_played) / 100)
											onUpdateEffectSettings()
										end,
									locked = v.isActive
								})
							if (v.isActive) then
								effectCustomizeDropdownActiveIds[i] = #effectCustomizeDropdownOptions[i]
							end
						end
					end
				end

				local appliedEffectsHolder = customizeSectionHolder:addChild({
					size = { customizeSectionHolder.size.w, customizeSectionHolder.size.h / 3 * 2 }
				}, true)
				local appliedEffectsTitle = appliedEffectsHolder:addChild({
					size = { appliedEffectsHolder.size.w, 25 }
				})
				shiftY = appliedEffectsTitle.size.h + 5
				appliedEffectsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STOREAPPLIEDITEMEFFECTS, nil, nil, nil, LEFTMID)
				for i = 1, #StoreInternal.ItemEffects do
					if (bit.band(item.effectid, StoreInternal.ItemEffects[i].id) ~= 0) then
						local effectHolder = appliedEffectsHolder:addChild({
							pos = { 0, shiftY },
							size = { appliedEffectsHolder.size.w, 34 }
						})
						local effectNameHolder = effectHolder:addChild({
							size = { #effectCustomizeDropdownOptions[i] > 0 and effectHolder.size.w * 0.4 or effectHolder.size.w, effectHolder.size.h },
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							shapeType = ROUNDED,
							rounded = 4
						})
						local effectName = effectHolder:addChild({ shift = { 10, 5 } })
						local res, color = pcall(get_color_info, StoreInternal.GetItemEffectColorid(item, StoreInternal.ItemEffects[i]))
						if (res == false) then
							color = { name = "???", game_name = "???" }
						end
						color.name = color.game_name:gsub("^%l", string.upper)
						effectName:addAdaptedText(true, (StoreInternal.ItemEffects[i].use_colorid and color.name or "") .. StoreInternal.ItemEffects[i].name, nil, nil, 4, LEFTMID, 0.8)

						if (#effectCustomizeDropdownOptions[i] > 0) then
							local effectCustomizeDropdownHolder = effectHolder:addChild({
								pos = { effectNameHolder.size.w + 6, 0 },
								size = { effectHolder.size.w - effectNameHolder.size.w - 6, effectHolder.size.h },
								bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
								shapeType = ROUNDED,
								rounded = 4
							})
							TBMenu:spawnDropdown(effectCustomizeDropdownHolder, effectCustomizeDropdownOptions[i], effectHolder.size.h, appliedEffectsHolder.size.h, effectCustomizeDropdownActiveIds[i], { scale = 0.6, fontid = 4 }, { scale = 0.55, fontid = 4 })
						end

						shiftY = shiftY + effectHolder.size.h + 5
					end
				end
				local updateEffectSettingsButton = appliedEffectsHolder:addChild({
					pos = { 46, shiftY },
					size = { appliedEffectsHolder.size.w - 46, 40 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				local updateEffectInfo = appliedEffectsHolder:addChild({
					pos = { 0, shiftY },
					size = { 40, 40 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				updateEffectInfo:addCustomDisplay(false, function()
						TB_MENU_POPUPS_DISABLED = updateEffectInfo.hoverState == BTN_NONE
					end)
				shiftY = shiftY + 55
				updateEffectSettingsButton:hide()
				updateEffectInfo:hide()
				onUpdateEffectSettings = function()
						updateEffectSettingsButton:show()
						local buttonText = TB_MENU_LOCALIZED.STOREITEMUPGRADEFOR
						local upgradePrice = 0
						local maxRequirement = math.max(table.unpack_all(effectUpdateRequirements.gamesPlayed))
						for _, v in pairs(effectUpdateRequirements.upgradePrice) do
							upgradePrice = upgradePrice + v
						end
						if (upgradePrice > 0) then
							buttonText = buttonText .. " " .. upgradePrice .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS
							updateEffectInfo:show()
							if (updateEffectInfo.hint) then
								updateEffectInfo.hint:kill()
							end
							updateEffectInfo.hint = TBMenu:displayHelpPopup(updateEffectInfo, TB_MENU_LOCALIZED.STOREUPGRADEORPLAYGAMES .. " " .. (maxRequirement - item.games_played) .. " " .. TB_MENU_LOCALIZED.STOREYOUNEEDTOPLAYGAMES2)
							if (updateEffectInfo.hint ~= nil) then
								updateEffectInfo.hint:moveTo(44, nil, true)
							end
							updateEffectSettingsButton:moveTo(46)
							updateEffectSettingsButton.size.w = appliedEffectsHolder.size.w - 46
						else
							updateEffectInfo:hide()
							if (updateEffectInfo.hint) then
								updateEffectInfo.hint:kill()
								updateEffectInfo.hint = nil
							end
							buttonText = buttonText .. " " .. TB_MENU_LOCALIZED.STOREITEMUPGRADEPRICEFREE
							updateEffectSettingsButton:moveTo(0)
							updateEffectSettingsButton.size.w = appliedEffectsHolder.size.w
						end
						updateEffectSettingsButton:addAdaptedText(false, buttonText)
					end
				updateEffectSettingsButton:addMouseUpHandler(function()
						local requestInProgress = customizeHolder:addChild({
							bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
							interactive = true
						})
						TBMenu:displayLoadingMark(requestInProgress, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT)
						Request:queue(function()
							Store:spawnConfirmationWaiter(nil, function() requestInProgress:kill() Request:finalize("inventory_fuse_effect") end)
							local payload = ""
							for i, v in pairs(effectUpdateRequirements.chosenEffects) do
								payload = payload .. item.inventid .. ";" .. v .. ";" .. effectUpdateRequirements.upgradePrice[i] .. "|"
							end
							show_dialog_box(StoreInternal.InventoryActions.EffectUpgrade, TB_MENU_LOCALIZED.INVENTORYSETEFFECTCONFIRM .. " " .. item.name .. "?\n" .. TB_MENU_LOCALIZED.INVENTORYSETEFFECTNOTICE, payload, true)
						end, "inventory_fuse_effect", function()
							requestInProgress:kill()
							customizeItemEffect()
							update_tc_balance()
						end, function()
							requestInProgress:kill()
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
						end)
					end)
			end

			local selectedEffect
			local availableEffectsDropdown = {}
			for _, v in pairs(Store:getInventory(INVENTORY_DEACTIVATED)) do
				if (Store:getItemInfo(v.itemid).catid == 87 and bit.band(item.effectid, v.effectid) == 0) then
					table.insert(availableEffectsDropdown, {
						text = v.name,
						action = function() selectedEffect = v end
					})
				end
			end
			if (#availableEffectsDropdown > 0) then
				availableEffectsDropdown[1].action()
			end

			local fuseEffectTitle = customizeSectionHolder:addChild({
				pos = { 0, shiftY },
				size = { customizeSectionHolder.size.w, 25 }
			})
			fuseEffectTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STOREFUSENEWEFFECT, nil, nil, nil, LEFTMID)
			shiftY = shiftY + 35

			if (#availableEffectsDropdown == 0) then
				local getInShopButton = customizeSectionHolder:addChild({
					pos = { 0, shiftY },
					size = { customizeSectionHolder.size.w, 40 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				getInShopButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREPURCHASEINSTORE)
				getInShopButton:addMouseUpHandler(function()
						overlay:kill()
						Store:showStoreSection(TBMenu.CurrentSection, 3, 3)
					end)
				shiftY = shiftY + getInShopButton.size.h + 20
			else
				local fuseEffectDropdownHolder = customizeSectionHolder:addChild({
					pos = { 0, shiftY },
					size = { customizeSectionHolder.size.w / 2 - 5, 40 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				}, true)
				TBMenu:spawnDropdown(fuseEffectDropdownHolder, availableEffectsDropdown, fuseEffectDropdownHolder.size.h - 5, 300, nil, { scale = 0.7, fontid = 4 }, { scale = 0.65, fontid = 4 })
				local fuseEffectButton = customizeSectionHolder:addChild({
					pos = { fuseEffectDropdownHolder.size.w + 6, fuseEffectDropdownHolder.shift.y },
					size = { customizeSectionHolder.size.w - fuseEffectDropdownHolder.size.w - 6, fuseEffectDropdownHolder.size.h },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
				}, true)
				if (generalInfo.fuseCost > TB_MENU_PLAYER_INFO.data.tc) then
					fuseEffectButton:deactivate(true)
				end
				fuseEffectButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREFUSEEFFECTFOR .. " " .. (generalInfo.fuseCost > 0 and ((generalInfo.fuseCost / 1000) .. "K " .. TB_MENU_LOCALIZED.WORDTC) or TB_MENU_LOCALIZED.STOREITEMUPGRADEPRICEFREE))
				fuseEffectButton:addMouseUpHandler(function()
						Store:spawnInventoryUpdateWaiter(overlay.btnUp)
						show_dialog_box(StoreInternal.InventoryActions.EffectFuse, TB_MENU_LOCALIZED.INVENTORYFUSECONFIRM1 .. " " .. selectedEffect.name .. " " .. TB_MENU_LOCALIZED.INVENTORYFUSECONFIRM2 .. " " .. item.name .. "?\n" .. TB_MENU_LOCALIZED.INVENTORYFUSECONFIRMPRICE .. " " .. generalInfo.fuseCost .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. ".\n\n^09" .. TB_MENU_LOCALIZED.INVENTORYFUSECONFIRMINFO, item.inventid .. ";" .. selectedEffect.inventid .. ";" .. generalInfo.fuseCost)
					end)
				shiftY = shiftY + fuseEffectDropdownHolder.size.h + 20
			end

			if (item.effectid > 0) then
				local purgeEffectsTitle = customizeSectionHolder:addChild({
					pos = { 0, shiftY },
					size = { customizeSectionHolder.size.w, 25 }
				})
				purgeEffectsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STOREPURGEEFFECT, nil, nil, nil, LEFTMID)
				shiftY = shiftY + 35
				local purgeEffectsButton = customizeSectionHolder:addChild({
					pos = { 0, shiftY },
					size = { customizeSectionHolder.size.w, 40 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				purgeEffectsButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREPURGEEFFECT)
				purgeEffectsButton:addMouseUpHandler(function()
						Store:spawnInventoryUpdateWaiter(overlay.btnUp)
						show_dialog_box(StoreInternal.InventoryActions.EffectPurge, TB_MENU_LOCALIZED.INVENTORYPURGEEFFECTCONFIRM .. " ^16" .. item.name .. "?\n\n^09" .. TB_MENU_LOCALIZED.CONFIRMACTIONCANNOTBEUNDONE, tostring(item.inventid))
					end)
			end
		end

		TBMenu:displayLoadingMark(customizeSectionHolder, TB_MENU_LOCALIZED.INVENTORYLOADINGEFFECTS)
		Request:queue(function()
				download_server_info("effect_fuse_details&invid=" .. item.inventid)
			end, "store_item_effect_upgrades", function()
				local response = get_network_response()
				local effectState, effectOptions, generalInfo = {}, {}, {}
				for ln in response:gmatch("[^\n]+\n") do
					if (ln:match("^EFFECTID")) then
						local enabled = ln:gsub("^EFFECTID %d;(%d+).*$", "%1") == "1"
						table.insert(effectState, enabled)
					elseif (ln:match("^EFFECTUPGRADE")) then
						ln = ln:gsub("^EFFECTUPGRADE %d+;", "")
						local _, segments = ln:gsub("\t", "")
						local data = { ln:match(("([^\t]*)\t?"):rep(segments + 1)) }
						if (effectOptions[#effectState] == nil) then
							effectOptions[#effectState] = {}
						end
						table.insert(effectOptions[#effectState], {
							effectId = tonumber(data[1]),
							isActive = tonumber(data[2]) == 1,
							gamesPlayed = tonumber(data[3]),
							upgradeName = data[4]
						})
					elseif (ln:match("^FUSECOST")) then
						local cost = ln:gsub("^FUSECOST 0;(%d+).*$", "%1")
						generalInfo.fuseCost = tonumber(cost)
					end
				end
				customizeSectionHolder:kill(true)
				displayEffects(effectOptions, generalInfo)
			end, function()
				customizeSectionHolder:kill(true)
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
			end)
	end

	local sections = {}

	-- Cache whether the item is a texture slot
	-- For textures we want to prioritize on Texture upload, for other items on effects/levels
	local isTexture = Store:isTextureItem(item.itemid)
	if (isTexture and item.uploadable) then
		table.insert(sections, { name = "Texture", action = customizeItemTexture })
	end
	if (item.upgradeable and Store:getItemInfo(item.itemid).catid ~= StoreCategory.JointTextures) then
		table.insert(sections, { name = "Level", action = customizeItemLevel })
	end
	if (Store:itemSupportsEffects(item.itemid)) then
		table.insert(sections, { name = "Effects", action = customizeItemEffect })
	end
	if (not isTexture and item.uploadable) then
		table.insert(sections, { name = "Texture", action = customizeItemTexture })
	end

	local sectionButtonWidth = (customizeHolder.size.w - 20) / #sections - 10
	local selectedButton = nil
	for i, v in pairs(sections) do
		local sectionButton = customizeHolder:addChild({
			pos = { 15 + (sectionButtonWidth + 10) * (i - 1), 55 },
			size = { sectionButtonWidth, 35 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		v.button = sectionButton
		sectionButton:addAdaptedText(false, v.name)
		sectionButton:addMouseUpHandler(function()
				if (selectedButton) then
					selectedButton.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
				end
				selectedButton = sectionButton
				selectedButton.bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
				v.action()
			end)
	end
	sections[1].button:btnUp()
end

---Spawns a generic built-in confirmation prompt waiter
---@param confirmAction function?
---@param cancelAction function?
function Store:spawnConfirmationWaiter(confirmAction, cancelAction)
	local overlay = TBMenu:spawnWindowOverlay()
	overlay:addMouseMoveHandler(function(x)
		---Kill overlay first, then do anything else
		overlay:kill()
		if (x > WIN_W / 2) then
			if (confirmAction) then
				confirmAction()
			end
		elseif (cancelAction) then
			cancelAction()
		end
	end)
end

---Spawns a generic inventory updater waiter to use with built-in confirmation prompts
---@param confirmAction function?
function Store:spawnInventoryUpdateWaiter(confirmAction)
	Store:spawnConfirmationWaiter(function()
			Store.InventoryListShift[1] = 0
			update_tc_balance()
			if (TB_MENU_MAIN_ISOPEN == 1 and TB_MENU_SPECIAL_SCREEN_ISOPEN == 1) then
				Store:prepareInventory(TBMenu.CurrentSection, true)
			else
				download_inventory()
			end
			if (confirmAction) then
				confirmAction()
			end
		end)
end

---Displays set selection window for operations on the specified inventory item or all selected items if none is specified
---@param item InventoryItem?
function Store:showSetSelection(item)
	local overlay = TBMenu:spawnWindowOverlay(true)

	local sets = { }
	for _, v in pairs(Store.Inventory or { }) do
		if (v.itemid == ITEM_SET) then
			table.insert(sets, v)
		end
	end
	sets = table.qsort(sets, "setname")

	local windowSize = { w = math.clamp(700, WIN_W / 2, WIN_W * 0.9), h = math.clamp(450, WIN_H / 3, WIN_H * 0.7) }
	local selectionWindow = overlay:addChild({
		pos = { (WIN_W - windowSize.w) / 2, (WIN_H - windowSize.h) / 2 },
		size = { windowSize.w, windowSize.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local elementHeight = math.clamp(WIN_H / 18, 45, 55)
	local toReload, topBar, _, _, listingHolder = TBMenu:prepareScrollableList(selectionWindow, math.max(elementHeight, 50), elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	topBar:addChild({ shift = { 50, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.STORESETSELECT, nil, nil, FONTS.BIG, nil, 0.65, nil, 0.5)

	local closeButton = TBMenu:spawnCloseButton(topBar, {
		x = -topBar.size.h + 5, y = 5,
		w = topBar.size.h - 10, h = topBar.size.h - 10
	}, overlay.btnUp)
	if (closeButton.roundedInternal) then
		closeButton:setRounded(closeButton.roundedInternal[1])
	end

	local listElements = { }
	for _, v in pairs(sets) do
		local elementHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, elementHolder)
		local elementButton = elementHolder:addChild({
			pos = { 10, 2 },
			size = { elementHolder.size.w - 10, elementHolder.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			shapeType = ROUNDED,
			rounded = 4
		})
		elementButton:addMouseUpHandler(function()
				Store:spawnInventoryUpdateWaiter(function() overlay.btnUp() Store.ClearInventorySelectedItems() end)
				if (item) then
					show_dialog_box(StoreInternal.InventoryActions.AddSet, TB_MENU_LOCALIZED.STOREDIALOGADDTOSET1 .. " " .. item.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGADDTOSET2 .. "?", v.inventid .. " " .. item.inventid)
				else
					local inventidStr = ""
					for _, v in pairs(Store.InventorySelectedItems) do
						inventidStr = inventidStr == "" and tostring(v.inventid) or inventidStr .. ";" .. v.inventid
					end
					local itemsStr = #Store.InventorySelectedItems == 1 and Store.InventorySelectedItems[1].name or #Store.InventorySelectedItems .. " " .. TB_MENU_LOCALIZED.STOREITEMS
					show_dialog_box(StoreInternal.InventoryActions.AddSet, TB_MENU_LOCALIZED.STOREDIALOGADDTOSET1 .. " " .. itemsStr .. " " .. TB_MENU_LOCALIZED.STOREDIALOGADDTOSET2 .. "?", v.inventid .. " " .. inventidStr)
				end
			end)
		elementButton:addChild({
			pos = { 3, 3 },
			size = { elementButton.size.h - 6, elementButton.size.h - 6 },
			bgImage = "../textures/store/items/" .. ITEM_SET .. ".tga"
		})
		local setName = elementButton:addChild({
			pos = { elementButton.size.h, 0 },
			size = { elementButton.size.w - elementButton.size.h, elementButton.size.h }
		})
		local itemsStr
		if (#v.contents == 0) then
			itemsStr = "(" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
		elseif (#v.contents == 1) then
			itemsStr = "(1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
		else
			itemsStr = "(" .. #v.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
		end
		setName:addAdaptedText(true, v.setname .. " " .. itemsStr, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7, 0.7)
	end

	for _, v in pairs(listElements) do
		v:hide()
	end

	listingHolder.scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
end

---Displays selected items and available controls in inventory item view holder
function Store:showSelectionControls()
	Store.InventoryItemView:kill(true)

	TBMenu:addBottomBloodSmudge(Store.InventoryItemView, 2)
	local controlsName = Store.InventoryItemView:addChild({
		pos = { 10, 0 },
		size = { Store.InventoryItemView.size.w - 20, 50 }
	})
	controlsName:addAdaptedText(true, TB_MENU_LOCALIZED.STORESETSELECTIONCONTROLS, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
	local controlsInfo = Store.InventoryItemView:addChild({
		pos = { 10, 50 },
		size = { Store.InventoryItemView.size.w - 20, 20 }
	})
	controlsInfo:addAdaptedText(true, #Store.InventorySelectedItems == 1 and Store.InventorySelectedItems[1].name or (#Store.InventorySelectedItems .. " " .. TB_MENU_LOCALIZED.STOREITEMS))

	local selectionViewHeight = Store.InventoryItemView.size.h / 2 - controlsName.size.h - controlsInfo.size.h
	selectionViewHeight = math.min(selectionViewHeight, 100)
	local selectionView = Store.InventoryItemView:addChild({
		pos = { 10, controlsName.size.h + controlsInfo.size.h + 10 },
		size = { Store.InventoryItemView.size.w - 20, selectionViewHeight }
	})
	Store:showSetDetailsItems(selectionView, Store.InventorySelectedItems)

	local buttonHeight = math.min(Store.InventoryItemView.size.h / 10, 55)
	local buttonYPos = -buttonHeight * 1.1

	local showAddSet, showActivate, showDeactivate, showRemoveSet, showSellMarket, showChangeLevel = true, false, false, false, true, true
	for _, v in pairs(Store.InventorySelectedItems) do
		if (v.active) then
			showDeactivate = true
		else
			showActivate = true
		end
		if (v.setid ~= 0) then
			showRemoveSet = true
		end
		if (showSellMarket or showChangeLevel) then
			local itemInfo = Store:getItemInfo(v.itemid)
			if (showSellMarket and not Market:itemEligible(itemInfo)) then
				showSellMarket = false
			end
			if (showChangeLevel and (itemInfo.catid ~= StoreCategory.Objects3D or not v.upgradeable or v.upgrade_max_level == 1)) then
				showChangeLevel = false
			end
		end
	end

	local itemsStr = #Store.InventorySelectedItems == 1 and Store.InventorySelectedItems[1].name or #Store.InventorySelectedItems .. " " .. TB_MENU_LOCALIZED.STOREITEMS

	local buttonsHolder = Store.InventoryItemView:addChild({
		shift = { 10, 0 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local cleanSelection = buttonsHolder:addChild({
		pos = { 0, buttonYPos },
		size = { buttonsHolder.size.w, buttonHeight },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	cleanSelection:addAdaptedText(TB_MENU_LOCALIZED.STOREITEMSCLEANSELECTION)
	cleanSelection:addMouseUpHandler(function()
			Store.ClearInventorySelectedItems()
			Store:showInventory(TBMenu.CurrentSection)
			Store:showInventoryItem(Store.InventoryCurrentItem)
		end)
	buttonYPos = buttonYPos - buttonHeight * 1.2
	if (showRemoveSet) then
		local removeSetButton = buttonsHolder:addChild({
			pos = { 0, buttonYPos },
			size = { buttonsHolder.size.w, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		removeSetButton:addAdaptedText(TB_MENU_LOCALIZED.STOREITEMREMOVEFROMSET)
		removeSetButton:addMouseUpHandler(function()
				Store:spawnInventoryUpdateWaiter(Store.ClearInventorySelectedItems)
				local inventidStr = ""
				for _, v in pairs(Store.InventorySelectedItems) do
					inventidStr = inventidStr == "" and tostring(v.inventid) or inventidStr .. ";" .. v.inventid
				end
				show_dialog_box(StoreInternal.InventoryActions.RemoveSet, TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET1 .. " " .. itemsStr .. " " .. TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 .. "?", "0 " .. inventidStr)
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end

	if (showAddSet) then
		local addSetButton = buttonsHolder:addChild({
			pos = { 0, buttonYPos },
			size = { buttonsHolder.size.w, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		addSetButton:addAdaptedText(TB_MENU_LOCALIZED.STOREITEMADDTOSET)
		addSetButton:addMouseUpHandler(function()
				Store:showSetSelection()
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end

	if (showSellMarket) then
		local marketSellButton = buttonsHolder:addChild({
			pos = { 0, buttonYPos },
			size = { buttonsHolder.size.w, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		marketSellButton:addAdaptedText(TB_MENU_LOCALIZED.STORESELLMARKET)
		marketSellButton:addMouseUpHandler(function()
				Market:showSellInventoryItem(Store.InventorySelectedItems)
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end

	if (showChangeLevel) then
		local changeLevelButton = buttonsHolder:addChild({
			pos = { 0, buttonYPos },
			size = { buttonsHolder.size.w, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		changeLevelButton:addAdaptedText(TB_MENU_LOCALIZED.STORECHANGELEVEL)
		changeLevelButton:addMouseUpHandler(function()
				Store:showInventoryItemsChangeLevel(Store.InventorySelectedItems)
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end

	if (showDeactivate) then
		local deactivateButton = buttonsHolder:addChild({
			pos = { 0, buttonYPos },
			size = { buttonsHolder.size.w, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		deactivateButton:addAdaptedText(TB_MENU_LOCALIZED.STOREITEMDEACTIVATE)
		deactivateButton:addMouseUpHandler(function()
				Store:spawnConfirmationWaiter(function()
					for _, v in pairs(Store.InventorySelectedItems) do
						v:deactivate()
					end
					Store:showInventory(TBMenu.CurrentSection, nil, Store.InventoryShowEmptySets)
					update_tc_balance()
				end)

				local inventidStr = ""
				for _, v in pairs(Store.InventorySelectedItems) do
					inventidStr = inventidStr == "" and tostring(v.inventid) or inventidStr .. ";" .. v.inventid
				end
				show_dialog_box(StoreInternal.InventoryActions.Deactivate, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. itemsStr .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), inventidStr)
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
	end

	if (showActivate) then
		local activateButton = buttonsHolder:addChild({
			pos = { 0, buttonYPos },
			size = { buttonsHolder.size.w, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		activateButton:addAdaptedText(TB_MENU_LOCALIZED.STOREITEMACTIVATE)
		activateButton:addMouseUpHandler(function()
				Store:spawnInventoryUpdateWaiter()
				local inventidStr = ""
				for _, v in pairs(Store.InventorySelectedItems) do
					inventidStr = inventidStr == "" and tostring(v.inventid) or inventidStr .. ";" .. v.inventid
				end
				show_dialog_box(StoreInternal.InventoryActions.Activate, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. itemsStr .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGCONFLICTSDEACTIVATE, inventidStr)
			end)
	end
end

---Displays item's fused effects in a viewport
---@param item InventoryItem
---@param viewElement UIElement
---@param capsuleHeight number?
---@param extraDataShift Vector2Base?
function Store:showItemEffectCapsules(item, viewElement, capsuleHeight, extraDataShift)
	if (getmetatable(item) ~= InventoryItem or item.effectid <= 0 or Store:getItemInfo(item.itemid).catid == 87) then return end

	capsuleHeight = capsuleHeight or 20
	extraDataShift = extraDataShift or { x = 0, y = (viewElement.size.h - capsuleHeight) / 2 }

	local initialDataShift = { x = extraDataShift.x, y = extraDataShift.y }
	local collapsed = { }

	for j = 1, #StoreInternal.ItemEffects do
		if (bit.band(item.effectid, StoreInternal.ItemEffects[j].id) ~= 0) then
			local res, color = pcall(get_color_info, StoreInternal.GetItemEffectColorid(item, StoreInternal.ItemEffects[j]))
			if (res == false) then
				color = { r = 0, g = 0, b = 0, name = "???", game_name = "???" }
			end
			color.name = color.game_name:gsub("^%l", string.upper)
			local itemEffect = viewElement:addChild({
				pos = { extraDataShift.x, extraDataShift.y },
				size = { viewElement.size.w, capsuleHeight },
				bgColor = { color.r, color.g, color.b, 1 },
				shapeType = ROUNDED,
				rounded = capsuleHeight / 2,
				uiColor = get_color_contrast_ratio({ color.r, color.g, color.b }) > 0.5 and UICOLORBLACK or UICOLORWHITE
			})
			itemEffect:addAdaptedText(false, (StoreInternal.ItemEffects[j].use_colorid and color.name or "") .. StoreInternal.ItemEffects[j].name, 10, nil, 4, LEFTMID, 0.6)
			local effectTextLen = get_string_length(itemEffect.dispstr[1], itemEffect.textFont) * itemEffect.textScale + 20
			itemEffect.size.w = effectTextLen
			if (extraDataShift.x + effectTextLen + 5 + capsuleHeight * 2 + initialDataShift.x > viewElement.size.w) then
				table.insert(collapsed, itemEffect.str)
				itemEffect:kill()
			else
				extraDataShift.x = extraDataShift.x + effectTextLen + 5
			end
		end
	end
	if (#collapsed > 0) then
		local itemEffect = viewElement:addChild({
			pos = { extraDataShift.x, extraDataShift.y },
			size = { capsuleHeight * 2, capsuleHeight },
			bgColor = UICOLORWHITE,
			shapeType = ROUNDED,
			rounded = capsuleHeight / 2,
			uiColor = UICOLORBLACK
		})
		itemEffect:addAdaptedText(false, "+" .. #collapsed, nil, nil, 4, nil, 0.6)
		local popupString = collapsed[1]
		for i = 2, #collapsed do
			popupString = popupString .. "\n" .. collapsed[i]
		end
		local popup = TBMenu:displayHelpPopup(itemEffect, popupString, true, true)
		if (popup ~= nil) then
			popup:moveTo(itemEffect.size.w + 5, -itemEffect.size.h - (popup.size.h - itemEffect.size.h) / 2 )
		end
	end
end

---@alias InventoryDisplayMode
---| 0 INVENTORY_STARTUP
---| 1 INVENTORY_DEACTIVE
---| 2 INVENTORY_ACTIVE
---| 3 INVENTORY_ALL

---Displays an inventory page in its viewport
---@param inventoryItems InventoryItem[]
---@param page integer?
---@param mode InventoryDisplayMode?
---@param title string?
---@param pageid integer|string
---@param itemScale number?
---@param showBack boolean?
---@param search string?
function Store:showInventoryPage(inventoryItems, page, mode, title, pageid, itemScale, showBack, search)
	showBack = showBack or false
	itemScale = itemScale or 100

	local inventoryModes = {
		{
			text = TB_MENU_LOCALIZED.STOREDEACTIVATEDINVENTORY,
			action = function()
				Store.InventoryListShift[1] = 0
				Store:showInventory(TBMenu.CurrentSection, INVENTORY_DEACTIVATED)
			end
		},
		{
			text = TB_MENU_LOCALIZED.STOREACTIVATEDINVENTORY,
			action = function()
				Store.InventoryListShift[1] = 0
				Store:showInventory(TBMenu.CurrentSection, INVENTORY_ACTIVATED)
			end
		},
		{
			text = TB_MENU_LOCALIZED.STOREINVENTORYALLITEMS,
			action = function()
				Store.InventoryListShift[1] = 0
				Store:showInventory(TBMenu.CurrentSection, INVENTORY_ALL)
			end
		}
	}

	Store.InventoryPage[pageid] = Store.InventoryPage[pageid] or 1
	Store.InventorySearch = search

	if (search ~= nil) then
		showBack = true
	end
	TBMenu.NavigationBar:kill(true)
	TBMenu:showNavigationBar(Store:getInventoryNavigation(showBack), true)

	Store.InventoryView:kill(true)

	local elementHeight = math.clamp(WIN_H / 18, 45, 55)
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(Store.InventoryView, 56, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	local matchingItems = search == nil and inventoryItems or { }
	if (search ~= nil) then
		for _, v in pairs(inventoryItems) do
			local itemName = utf8.safe_lower(Store:getItemInfo(v.itemid).itemname)
			local setName = utf8.safe_lower(v.setname)
			local flameName = utf8.safe_lower(v.flamename)
			local search = utf8.safe_lower(search)
			if (not pcall(function()
				if (utf8.find(itemName, search) or utf8.find(setName, search) or utf8.find(flameName, search)) then
					table.insert(matchingItems, v)
				end
			end)) then
				if (string.find(itemName, search) or string.find(setName, search) or string.find(flameName, search)) then
					table.insert(matchingItems, v)
				end
			end
		end
	end

	local itemsPerPage = 100
	local maxPages = math.ceil(#matchingItems / itemsPerPage)

	page = page or Store.InventoryPage[pageid]
	page = page < 1 and maxPages or page
	Store.InventoryPage[pageid] = page > maxPages and 1 or page

	local invStartShift = 1 + (Store.InventoryPage[pageid] - 1) * itemsPerPage

	local inventoryTitle = topBar:addChild({
		pos = { 10, 10 },
		size = { topBar.size.w / 2 > 400 and topBar.size.w - 410 or topBar.size.w / 2 - 10, topBar.size.h - 15 }
	})
	if (mode) then
		local dropdownBG = inventoryTitle:addChild({
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local dropdown = TBMenu:spawnDropdown(dropdownBG, inventoryModes, inventoryTitle.size.h, nil, inventoryModes[mode], { fontid = FONTS.MEDIUM }, { scale = 0.7 })
		if (search ~= nil) then
			dropdown.selectedElement:deactivate(true)
		end
	else
		inventoryTitle:addAdaptedText(true, title, nil, nil, FONTS.BIG, LEFTMID, 0.6, 0.55, 0.5)
	end

	if (maxPages > 1) then
		local pagesCount = topBar:addChild({
			pos = { inventoryTitle.size.w + 10, 10 },
			size = { topBar.size.w - inventoryTitle.size.w - 20, topBar.size.h - 15 }
		})
		local pagesText = utf8.upper(TB_MENU_LOCALIZED.PAGINATIONPAGE .. " " .. Store.InventoryPage[pageid] .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. maxPages)
		pagesCount:addAdaptedText(true, pagesText, nil, nil, 4, LEFTMID, 0.6)
		local strlen = get_string_length(pagesCount.dispstr[1], pagesCount.textFont) * pagesCount.textScale
		local pagesButtonsHolder = pagesCount:addChild({
			pos = { strlen + 10, 0 },
			size = { pagesCount.size.w - strlen - 10, pagesCount.size.h }
		})
		local buttonWidth = pagesButtonsHolder.size.h / 6 * 5
		local maxButtons = math.floor(pagesButtonsHolder.size.w / (buttonWidth + 5))
		local paginationData = TBMenu:generatePaginationData(maxPages, maxButtons, Store.InventoryPage[pageid])

		local pageButtons = {}
		for i = #paginationData, 1, -1 do
			local buttonHolder = pagesButtonsHolder:addChild({
				pos = { pagesButtonsHolder.size.w - (#pageButtons + 1) * buttonWidth, 5 },
				size = { buttonWidth, pagesButtonsHolder.size.h - 10 }
			})
			table.insert(pageButtons, buttonHolder)
			local button = buttonHolder:addChild({
				pos = { 5, 0 },
				size = { buttonHolder.size.w - 5, buttonHolder.size.h },
				interactive = paginationData[i] ~= Store.InventoryPage[pageid],
				bgColor = paginationData[i] == Store.InventoryPage[pageid] and TB_MENU_DEFAULT_LIGHTER_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			button:addAdaptedText(false, tostring(paginationData[i]), nil, nil, 4, nil, 0.6)
			button:addMouseHandlers(nil, function()
					Store.InventoryListShift[1] = 0
					Store:showInventoryPage(inventoryItems, paginationData[i], mode, title, pageid, itemScale, showBack, search)
				end)
		end
		pagesCount:addAdaptedText(pagesText, {
			padding = { x = 0, y = 0, w = #pageButtons * buttonWidth + 5, h = 0 },
			font = FONTS.LMEDIUM, align = RIGHTMID, maxscale = 0.6
		}, true)
	end

	local emptySetsToggleHolder = botBar:addChild({
		pos = { 10, 10 },
		size = { botBar.size.w / 2 - 20, botBar.size.h - 10 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local emptySetsToggle = TBMenu:spawnToggle(emptySetsToggleHolder, 0, 0, 25, 25, Store.InventoryShowEmptySets, function()
			Store:showInventory(TBMenu.CurrentSection, nil, not Store.InventoryShowEmptySets)
			call_hook("mouse_move", MOUSE_X, MOUSE_Y)
		end)
	emptySetsToggle.clickThrough = true
	local showEmptySetsText = emptySetsToggleHolder:addChild({
		parent = emptySetsToggleHolder,
		size = { emptySetsToggleHolder.size.w, 25 },
		interactive = true,
		bgColor = UICOLORWHITE,
		hoverColor = TB_MENU_DEFAULT_YELLOW,
		pressedColor = TB_MENU_DEFAULT_ORANGE
	})
	emptySetsToggle:addCustomDisplay(function()
			showEmptySetsText.hoverState = math.max(emptySetsToggle.hoverState, showEmptySetsText.hoverState)
			showEmptySetsText.hoverClock = math.max(emptySetsToggle.hoverClock, showEmptySetsText.hoverClock)
			emptySetsToggle.hoverState = showEmptySetsText.hoverState
			emptySetsToggle.hoverClock = showEmptySetsText.hoverClock
		end, true)
	showEmptySetsText:addAdaptedText(true, TB_MENU_LOCALIZED.STORESHOWEMPTYSETS, 35, nil, nil, LEFTMID)
	showEmptySetsText:addCustomDisplay(true, function()
			showEmptySetsText:uiText(TB_MENU_LOCALIZED.STORESHOWEMPTYSETS, 35, nil, nil, LEFTMID, nil, nil, nil, showEmptySetsText:getButtonColor())
		end)
	showEmptySetsText.size.w = get_string_length(showEmptySetsText.dispstr[1], showEmptySetsText.textFont) * showEmptySetsText.textScale + 45
	showEmptySetsText:addMouseUpHandler(emptySetsToggle.btnUp)

	local refreshButtonWidth = math.min(botBar.size.w / 3, 350)
	local refreshInventory = botBar:addChild({
		pos = { botBar.size.w - refreshButtonWidth, 5 },
		size = { refreshButtonWidth - 20, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	refreshInventory:addAdaptedText(false, TB_MENU_LOCALIZED.STOREINVENTORYRELOAD, nil, nil, nil, nil, 0.9)
	refreshInventory:addMouseUpHandler(function()
			Store:prepareInventory(TBMenu.CurrentSection, true)
		end)

	Store:showInventorySearchBar(search, inventoryItems, mode, title, itemScale, showBack)

	local selectedItemButton = nil
	local listElements = { }
	for i = invStartShift, math.min(#matchingItems, invStartShift + itemsPerPage - 1) do
		local inventoryItem = listingHolder:addChild({
			pos = { 10, #listElements * elementHeight },
			size = { listingHolder.size.w - 10, elementHeight }
		})
		table.insert(listElements, inventoryItem)
		local invItemHolder = inventoryItem:addChild({
			shift = { 0, 3 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		if (Store.InventoryCurrentItem == matchingItems[i]) then
			invItemHolder.bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
			selectedItemButton = invItemHolder
		end
		invItemHolder.lastClick = 0
		invItemHolder:addMouseUpHandler(function()
				if (selectedItemButton ~= nil) then
					selectedItemButton.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				end
				invItemHolder.bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
				selectedItemButton = invItemHolder

				Store:showInventoryItem(matchingItems[i])
				if (matchingItems[i].itemid == ITEM_SET and #matchingItems[i].contents > 0) then
					local clock = os.clock_real()
					if (invItemHolder.lastClick + 0.5 > clock) then
						Store.InventoryLastListShift = Store.InventoryListShift[1]
						Store.InventoryListShift[1] = 0
						Store.InventoryCurrentItem = nil
						Store:showInventoryPage(matchingItems[i].contents, nil, nil, TB_MENU_LOCALIZED.STOREITEMSINSET .. ": " .. matchingItems[i].setname, "invid" .. matchingItems[i].inventid, nil, true)
					end
					invItemHolder.lastClick = clock
				end
			end)
		local item = Store:getItemInfo(matchingItems[i].itemid)
		local itemIcon = invItemHolder:addChild({
			pos = { 8, 2 },
			size = { invItemHolder.size.h - 4, invItemHolder.size.h - 4 }
		})
		if (item:isTexture()) then
			itemIcon:updateImage(matchingItems[i]:getIconPath())
		else
			itemIcon:updateImage(item:getIconPath())
		end
		matchingItems[i].iconElement = itemIcon

		local lShift = 0
		if (matchingItems[i].itemid ~= ITEM_SET) then
			local itemSelected = false
			for _, v in pairs(Store.InventorySelectedItems) do
				if (v.inventid == matchingItems[i].inventid) then
					itemSelected = true
					break
				end
			end
			invItemHolder.size.w = invItemHolder.size.w - invItemHolder.size.h - 5
			local selectBox = invItemHolder.parent:addChild({
				pos = { -invItemHolder.size.h, invItemHolder.shift.y },
				size = { invItemHolder.size.h, invItemHolder.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local selectIcon = selectBox:addChild({
				shift = { selectBox.size.h / 8, selectBox.size.h / 8 },
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
			})
			if (not itemSelected) then
				selectIcon:hide(true)
			end
			lShift = invItemHolder.size.h + 5

			selectBox:addMouseHandlers(nil, function()
					for j,v in pairs(Store.InventorySelectedItems) do
						if (v.inventid == matchingItems[i].inventid) then
							table.remove(Store.InventorySelectedItems, j)
							selectIcon:hide(true)
							if (#Store.InventorySelectedItems == 0) then
								Store:showInventoryItem(Store.InventoryCurrentItem)
							else
								Store:showSelectionControls()
							end
							return
						end
					end
					table.insert(Store.InventorySelectedItems, matchingItems[i])
					Store:showSelectionControls()
					selectIcon:show(true)
				end)
		end

		local buttonWidth = math.min(get_string_length(matchingItems[i].active and TB_MENU_LOCALIZED.STOREITEMDEACTIVATE or TB_MENU_LOCALIZED.STOREITEMACTIVATE, FONTS.MEDIUM) + 60, invItemHolder.size.w / 7)
		if (matchingItems[i].activateable and not matchingItems[i].unpackable) then
			invItemHolder.size.w = invItemHolder.size.w - buttonWidth -  5
			local activateButton = invItemHolder.parent:addChild({
				pos = { -buttonWidth - lShift, invItemHolder.shift.y },
				size = { buttonWidth, invItemHolder.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local activateText = activateButton:addChild({ shift = { 10, 5 }})
			activateText:addAdaptedText(true, matchingItems[i].active and TB_MENU_LOCALIZED.STOREITEMDEACTIVATE or TB_MENU_LOCALIZED.STOREITEMACTIVATE)
			activateButton:addMouseUpHandler(function()
					if (matchingItems[i].active) then
						Store:spawnConfirmationWaiter(function()
							matchingItems[i]:deactivate()
							Store:showInventory(TBMenu.CurrentSection, nil, Store.InventoryShowEmptySets)
							update_tc_balance()
						end)
						show_dialog_box(StoreInternal.InventoryActions.Deactivate, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. matchingItems[i].name .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), tostring(matchingItems[i].inventid))
					else
						Store:spawnInventoryUpdateWaiter()
						show_dialog_box(StoreInternal.InventoryActions.Activate, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. matchingItems[i].name .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), tostring(matchingItems[i].inventid))
					end
				end)
			lShift = lShift + buttonWidth + 5
		elseif (matchingItems[i].unpackable) then
			invItemHolder.size.w = invItemHolder.size.w - buttonWidth -  5
			local unpackButton = invItemHolder.parent:addChild({
				pos = { -buttonWidth - lShift, invItemHolder.shift.y },
				size = { buttonWidth, invItemHolder.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local unpackText = unpackButton:addChild({ shift = { 10, 5 }})
			unpackText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREITEMUNPACK)
			unpackButton:addMouseUpHandler(function()
					Store:spawnInventoryUpdateWaiter()
					show_dialog_box(StoreInternal.InventoryActions.Unpack, TB_MENU_LOCALIZED.STOREDIALOGUNPACK1 .. " " .. matchingItems[i].name .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, tostring(matchingItems[i].inventid))
				end)
			lShift = lShift + buttonWidth + 5
		end

		local itemInfoHolder = invItemHolder:addChild({
			pos = { invItemHolder.size.h + 15, 2 },
			size = { invItemHolder.size.w - itemIcon.shift.x * 2 - itemIcon.size.w - 15, invItemHolder.size.h - 4 }
		})
		local itemNameString = item.itemname
		if (item.catid == StoreCategory.Objects3D and matchingItems[i].upgrade_level > 0) then
			itemNameString = itemNameString .. " (LVL " .. matchingItems[i].upgrade_level .. ")"
		end
		if (matchingItems[i].flamename ~= '0') then
			itemNameString = itemNameString .. ": " .. matchingItems[i].flamename
		end
		if (matchingItems[i].setname ~= '0') then
			itemNameString = matchingItems[i].setname
		end
		local itemName = nil
		if (in_array(item.catid, { StoreCategory.Sets, StoreCategory.Flames, StoreCategory.Objects3D })) then
			itemName = itemInfoHolder:addChild({
				size = { itemInfoHolder.size.w, itemInfoHolder.size.h / 3 * 2 }
			})
			itemName:addAdaptedText(true, itemNameString, nil, nil, FONTS.BIG, LEFTMID, nil, nil, 0.2)
			local itemExtra = itemInfoHolder:addChild({
				pos = { 0, itemName.size.h },
				size = { itemInfoHolder.size.w, itemInfoHolder.size.h - itemName.size.h }
			})
			if (matchingItems[i].bodypartname ~= '0') then
				local bodypartString = (Store.Models[item.itemid] and TB_MENU_LOCALIZED.INVENTORY3DITEMFOR or TB_MENU_LOCALIZED.STOREFLAMEBODYPART) .. " " .. matchingItems[i].bodypartname
				itemExtra:addAdaptedText(true, bodypartString, nil, nil, 4, LEFTMID)
			elseif (matchingItems[i].contents ~= nil) then
				local numItemsStr = TB_MENU_LOCALIZED.STORESETEMPTY .. " " .. TB_MENU_LOCALIZED.STORESETITEMNAME
				if (#matchingItems[i].contents == 1) then
					numItemsStr = "1 " .. TB_MENU_LOCALIZED.STOREITEMSINSET:lower()
				elseif (#matchingItems[i].contents > 1) then
					numItemsStr = #matchingItems[i].contents .. " " .. TB_MENU_LOCALIZED.STOREITEMSINSET:lower()
				end
				itemExtra:addAdaptedText(true, numItemsStr, nil, nil, 4, LEFTMID)
			end
		else
			itemName = itemInfoHolder:addChild({ shift = { 0, itemInfoHolder.size.h / 6 } })
			itemName:addAdaptedText(true, itemNameString, nil, nil, FONTS.BIG, LEFTMID, nil, nil, 0.2)
		end
		if (matchingItems[i].effectid > 0 and Store.Items[matchingItems[i].itemid].catid ~= 87) then
			local nameLength = get_string_length(itemName.dispstr[1], itemName.textFont) * itemName.textScale
			local itemEffectsHolder = itemInfoHolder:addChild({
				pos = { nameLength + 10, 0 },
				size = { itemInfoHolder.size.w - nameLength - 20, itemInfoHolder.size.h }
			})
			Store:showItemEffectCapsules(matchingItems[i], itemEffectsHolder, 20)
		end
	end

	if (#listElements > 0) then
		if (#listElements * elementHeight > listingHolder.size.h) then
			for _, v in pairs(listElements) do
				v:hide()
			end
			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			listingHolder.scrollBar = scrollBar
			scrollBar:makeScrollBar(listingHolder, listElements, toReload, Store.InventoryListShift)
		end
	else
		listingHolder:addAdaptedText(false, TB_MENU_LOCALIZED.STOREINVENTORYEMPTY)
	end

	if (#Store.InventorySelectedItems == 0) then
		Store:showInventoryItem(Store.InventoryCurrentItem or matchingItems[invStartShift])
	else
		Store:showSelectionControls()
	end
end

---Prepares inventory screen and shows it when all required downloads are complete
---@param viewElement UIElement
---@param reload boolean?
function Store:prepareInventory(viewElement, reload)
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 1
	viewElement:kill(true)

	TBMenu.NavigationBar:kill(true)
	TBMenu:showNavigationBar(Store:getInventoryNavigation(), true)

	if (reload or Store.Inventory == nil) then
		Store.Inventory = nil
		local inventoryLoader = viewElement:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(inventoryLoader)
		TBMenu:displayLoadingMark(inventoryLoader, TB_MENU_LOCALIZED.STOREINVENTORYLOADING)

		inventoryLoader:addCustomDisplay(false, function()
				if (Store.Inventory ~= nil) then
					inventoryLoader:kill()
					Store:showInventory(viewElement)
				end
			end)
		download_inventory()
	else
		Store:showInventory(viewElement)
	end
end

---Displays user inventory in a specified UIElement viewport
---@param viewElement UIElement
---@param mode InventoryDisplayMode?
---@param showSets boolean?
function Store:showInventory(viewElement, mode, showSets)
	usage_event("storeinventory")
	viewElement:kill(true)
	if (mode and mode ~= Store.InventoryMode) then
		Store.InventoryCurrentItem = nil
	end
	mode = mode or Store.InventoryMode

	local playerInventory
	if (mode == INVENTORY_STARTUP) then
		mode = INVENTORY_DEACTIVATED
		playerInventory = Store:getInventory(INVENTORY_DEACTIVATED)
		if (#playerInventory == 0) then
			mode = INVENTORY_ACTIVATED
			playerInventory = Store:getInventory(INVENTORY_ACTIVATED)
		end
	else
		playerInventory = Store:getInventory(mode)
	end
	Store.InventoryMode = mode

	if (showSets ~= nil) then
		Store.InventoryShowEmptySets = showSets
	end
	if (Store.InventoryShowEmptySets == false) then
		for i = #playerInventory, 1, -1 do
			if (playerInventory[i].itemid == ITEM_SET and #playerInventory[i].contents == 0) then
				table.remove(playerInventory, i)
			end
		end
	end

	local itemViewWidth = math.min(viewElement.size.w * 0.3, 400) - 10
	Store.InventoryView = viewElement:addChild({
		pos = { 5, 0 },
		size = { viewElement.size.w - itemViewWidth - 20, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	Store.InventoryItemView = viewElement:addChild({
		pos = { Store.InventoryView.shift.x + Store.InventoryView.size.w + 10, 0 },
		size = { itemViewWidth, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	Store:showInventoryPage(playerInventory, nil, mode, nil, "page" .. mode, nil, nil, Store.InventorySearch)
end

---Displays a store item preview in a 3D viewport
---@param viewElement UIElement
---@param item StoreItem
---@param noReload boolean?
---@param updateOverride boolean?
---@param updatedFunc function?
---@param level integer?
---@return boolean
function Store:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level)
	local viewport = viewElement:addChild({
		pos = { (viewElement.size.w - viewElement.size.h) / 2, 0 },
		size = { viewElement.size.h, viewElement.size.h },
		viewport = true
	})
	local background = viewElement:addChild({
		pos = { math.ceil(viewport.shift.x), 1 },
		size = { viewport.size.w - 1, viewElement.size.h - 2 },
		bgColor = UICOLORWHITE,
		bgImage = "../textures/store/presets/previewbgshade.tga"
	})
	local viewport3D = UIElement3D.new({
		globalid = TB_MENU_MAIN_GLOBALID,
		shapeType = VIEWPORT,
		parent = viewport,
		pos = { 0, 0, 0 },
		size = { 0, 0, 0 },
		rot = { 0, 0, 0 },
		viewport = true
	})
	table.insert(viewport.child, viewport3D)

	local previewHolder = viewport3D:addChild({ pos = { 0, 0, 10 } })
	viewElement.mouseDelta = 0
	previewHolder:addCustomDisplay(true, function()
			if (viewElement.hoverState ~= BTN_DN) then
				previewHolder:rotate(0, 0, 0.2)
			elseif (viewElement.mouseDelta ~= 0) then
				previewHolder:rotate(0, 0, viewElement.mouseDelta)
				viewElement.pressedPos.x = MOUSE_X
				viewElement.mouseDelta = 0
			end
		end)
	viewElement:addMouseHandlers(function()
			viewElement.pressedPos.x = MOUSE_X
		end, nil, function()
			if (viewElement.hoverState == BTN_DN) then
				viewElement.mouseDelta = viewElement.pressedPos.x - MOUSE_X
			end
		end)

	local previewMain = previewHolder:addChild({ })
	local trans = get_option("shaders") == 1 and 1 or 0.99
	local heightMod = 0
	local iconScale = viewElement.size.w > viewElement.size.h and viewElement.size.h or viewElement.size.w
	iconScale = math.min(item.itemid > 4300 and 128 or 64, iconScale)

	local color = (item.colorid > 0 and item.colorid < _G.COLORS.NUM_COLORS) and get_color_rgba(item.colorid) or { 1, 1, 1, 0 }
	local pcolor = get_color_rgba(TB_MENU_PLAYER_INFO.items.colors.pgrad)
	local scolor = get_color_rgba(TB_MENU_PLAYER_INFO.items.colors.sgrad)
	local fcolor = get_color_rgba(TB_MENU_PLAYER_INFO.items.colors.force)
	local rcolor = get_color_rgba(TB_MENU_PLAYER_INFO.items.colors.relax)

	local forceEffect = table.clone(TB_MENU_PLAYER_INFO.items.effects.force)
	local relaxEffect = table.clone(TB_MENU_PLAYER_INFO.items.effects.relax)
	local headEffect = table.clone(TB_MENU_PLAYER_INFO.items.effects.head)
	local bodyEffect = table.clone(TB_MENU_PLAYER_INFO.items.effects.body)
	bodyEffect.voronoiScale = 1
	bodyEffect.voronoiFresnel = false
	bodyEffect.shiftScale = 0.45

	if (item.catid == 2 or item.catid == 22) then
		-- Relax and Force items
		forceEffect.voronoiScale = (forceEffect.voronoiScale or 7) / 5.5
		forceEffect.shiftScale = 0.45
		relaxEffect.voronoiScale = (relaxEffect.voronoiScale or 7) / 4
		relaxEffect.shiftScale = 0.5625
		local force = previewMain:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/force",
			size = { 2, 2, 2 },
			rot = { 15, 0, 40 },
			bgColor = item.catid == 22 and color or fcolor,
			---@diagnostic disable-next-line: assign-type-mismatch
			effects = item.catid == 2 and forceEffect
		})
		local relax = previewMain:addChild({
			shapeType = SPHERE,
			size = { 0.8, 0.8, 0.8 },
			rot = { 0, 0, 0 },
			bgColor = item.catid == 2 and color or rcolor,
			---@diagnostic disable-next-line: assign-type-mismatch
			effects = item.catid == 22 and relaxEffect
		})
		return true
	elseif (item.catid == 1) then
		-- Blood Items
		previewMain:addChild({
			parent = previewHolder,
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/blood",
			pos = { 0, 0, -0.3 },
			size = { 1.6, 1.6, 1.6 },
			rot = { -90, 80, 0 },
			bgColor = color,
		})
		return true
	elseif (item.catid == 20 or item.catid == 21) then
		-- Gradient Items
		local tricepsBody = previewMain:addChild({
			shapeType = CUBE,
			pos = { 0, 0.2, -0.3 },
			size = { 2, 0.65, 0.65 },
			rot = { 0, 0, 90 },
			bgGradient = item.catid == 20 and { color, scolor } or { pcolor, color },
			bgGradientMode = BODYPARTS.L_TRICEPS,
			---@diagnostic disable-next-line: assign-type-mismatch
			effects = item.catid == 21 and bodyEffect
		})
		local handBody = previewMain:addChild({
			shapeType = CUBE,
			pos = { 0.2, -1.53, -0.3 },
			size = { 1.2, 1.2, 1.2 },
			rot = { 0, 0, 90 },
			bgGradient = item.catid == 20 and { color, scolor } or { pcolor, color },
			bgGradientMode = BODYPARTS.L_HAND,
			---@diagnostic disable-next-line: assign-type-mismatch
			effects = item.catid == 21 and bodyEffect
		})
		forceEffect.voronoiScale = (forceEffect.voronoiScale or 7) / 3.5
		forceEffect.shiftScale = 0.9
		local elbowJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, 1.2, -0.3 },
			size = { 0.6, 0.6, 0.6 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local wristJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, -0.8, -0.3 },
			size = { 0.5, 0.5, 0.5 },
			bgColor = fcolor,
			effects = forceEffect
		})
		previewHolder:moveTo(0, 1, 0)
		previewMain:rotate(10, 40, 100)
		return true
	elseif (item.catid == 11) then
		-- Ghost Colors
		local cubeBody = previewMain:addChild({
			pos = { 0, 0.2, -0.3 },
			size = { 1, 1, 1 },
			rot = { 10, 60, 40 },
			bgGradient = { pcolor, scolor },
			---@diagnostic disable-next-line: assign-type-mismatch
			effects = bodyEffect
		})
		local ghost = cubeBody:addChild({
			size = { cubeBody.size.x, cubeBody.size.y, cubeBody.size.z },
			bgColor = { color[1], color[2], color[3], 0.5 },
		})
		local ticks = 0
		ghost:addCustomDisplay(false, function()
				if (ghost.bgColor[4] <= 0) then
					ghost:moveTo(-ghost.shift.x, -ghost.shift.y, 0)
					ghost:resetRotation()
					ghost.bgColor[4] = 0.5
					ticks = 0
					return
				end
				ghost:moveTo(0.02, -0.005, 0)
				ghost:rotate(0.4)
				if (ticks > 50) then
					ghost.bgColor[4] = ghost.bgColor[4] - 0.01
				end
				ticks = ticks + 1
			end, true)
		return true
	elseif (item.catid == 12) then
		-- DQ colors
		headEffect.voronoiScale = (headEffect.voronoiScale or 7) / 5.6
		headEffect.shiftScale = 0.5625
		forceEffect.voronoiScale = headEffect.voronoiScale * 0.56
		forceEffect.shiftScale = 0.3125
		local headBody = previewMain:addChild({
			shapeType = SPHERE,
			pos = { -0.3, 0, 0 },
			size = { 0.8, 0, 0 },
			rot = { 170, 20, -190 },
			bgColor = { 1, 1, 1, 1 },
			bgImage = TB_MENU_PLAYER_INFO.items.textures.head.equipped and "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head.tga" or "../../custom/tori/head.tga",
			effects = headEffect
		})
		local neckJoint = headBody:addChild({
			shapeType = SPHERE,
			pos = { 0, headBody.size.x / 9 * 1.8, -headBody.size.x / 9 * 5.8 },
			size = { headBody.size.x / 9 * 5, 0, 0 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local dqRing = previewMain:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/dq",
			size = { 7, 7, 7 },
			pos = { -0.3, 0, -0.8 },
			rot = { 0, 0, 0 },
			bgColor = color
		})
		return true
	elseif (item.catid == 5) then
		-- Torso Items
		forceEffect.voronoiScale = (forceEffect.voronoiScale or 7) / 4.67
		forceEffect.shiftScale = 0.675
		local chestJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, 0, -0.4 },
			size = { 0.7, 0.7, 0.7 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local lumbarJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, 0.2, -1.2 },
			size = { 0.7, 0.7, 0.7 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local rpecsJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0.55, -0.15, 0.4 },
			size = { 0.7, 0.7, 0.7 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local lpecsJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { -0.55, -0.15, 0.4 },
			size = { 0.7, 0.7, 0.7 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local torsoneck = previewMain:addChild({
			pos = { 0, 0, 0.8 },
			size = { 0.7, 0.4, 0.6 },
			bgColor = color,
			effects = bodyEffect
		})
		local torsorpec = previewMain:addChild({
			pos = { -1, 0, 0.35 },
			size = { 1, 0.7, 0.95 },
			bgColor = color,
			effects = bodyEffect
		})
		local torsolpec = previewMain:addChild({
			pos = { 1, 0, 0.35 },
			size = { 1, 0.7, 0.95 },
			bgColor = color,
			effects = bodyEffect
		})
		local torsochest = previewMain:addChild({
			pos = { 0, 0.05, -0.6 },
			size = { 2.2, 0.7, 1 },
			bgColor = color,
			effects = bodyEffect
		})
		local torsostomachp = previewMain:addChild({
			pos = { 0, 0.2, -1.6 },
			size = { 1.4, 0.7, 1.1 },
			rot = { 0, 0, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgGradient = { pcolor, scolor },
			bgGradientMode = BODYPARTS.STOMACH,
			effects = bodyEffect
		})
		previewHolder:moveTo(0, 1, 0.2)
		return true
	elseif (item.catid == 41) then
		-- Grip items
		forceEffect.voronoiScale = (forceEffect.voronoiScale or 7) / 3.5
		forceEffect.shiftScale = 0.9
		local handBody = previewMain:addChild({
			pos = { 0, 0.3, 0 },
			size = { 1, 1, 1 },
			rot = { -45, 90, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgGradient = { pcolor, scolor },
			bgGradientMode = BODYPARTS.R_HAND,
			effects = bodyEffect
		})
		local wristJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, 0.6, -0.6 },
			size = { 0.45, 0.45, 0.45 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local tricepsBody = previewMain:addChild({
			pos = { 0, 0.4, -1.3 },
			size = { 1.1, 0.4, 0.4 },
			rot = { 25, 90, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgGradient = { pcolor, scolor },
			bgGradientMode = BODYPARTS.R_TRICEPS,
			effects = bodyEffect
		})
		local grip = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0.2, -0.3, 0.4 },
			size = { 0.4, 0.4, 0.4 },
			bgColor = { color[1], color[2], color[3], 0.5 }
		})
		previewMain:rotate(0, 0, 40)
		return true
	elseif (item.catid == 27 or item.catid == 28) then
		-- Hand Trail items
		forceEffect.voronoiScale = (forceEffect.voronoiScale or 7) / 1.75
		forceEffect.shiftScale = 1.8
		local handBody = previewMain:addChild({
			pos = { 0, 0.3, 0.7 },
			size = { 0.5, 0.5, 0.5 },
			rot = { -25, -90, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgGradient = { pcolor, scolor },
			bgGradientMode = BODYPARTS.R_HAND,
			effects = bodyEffect
		})
		local wristJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, 0.4, 0.4 },
			size = { 0.25, 0.25, 0.25 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local tricepsBody = previewMain:addChild({
			pos = { 0, 0.58, 0 },
			size = { 1.1, 0.25, 0.25 },
			rot = { -25, 90, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgGradient = { pcolor, scolor },
			bgGradientMode = BODYPARTS.R_TRICEPS,
			effects = bodyEffect
		})
		local elbowJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, 0.9, -0.7 },
			size = { 0.3, 0.3, 0.3 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local trailObj = previewMain:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/trails",
			pos = { 0, -0.4, -0.2 },
			size = { 3.2, 3.2, 3.2 },
			rot = { 80, 90, 0 },
			bgColor = color
		})
		previewMain:rotate(0, 0, item.catid == 27 and -130 or 50)
		return true
	elseif (item.catid == 29 or item.catid == 30) then
		-- Leg Trail items
		forceEffect.voronoiScale = (forceEffect.voronoiScale or 7) / 1.75
		forceEffect.shiftScale = 1.8
		local footBody = previewMain:addChild({
			pos = { 0, -0.3, -0.95 },
			size = { 0.5, 1.2, 0.15 },
			rot = { 0, 10, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgGradient = { pcolor, scolor },
			bgGradientMode = BODYPARTS.L_FOOT,
			effects = bodyEffect
		})
		local ankleJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, 0, -0.7 },
			size = { 0.28, 0.28, 0.28 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local legBody = previewMain:addChild({
			shapeType = CAPSULE,
			pos = { 0, -0.25, 0 },
			size = { 0.3, 1, 0.3 },
			rot = { -25, 0, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgGradient = { pcolor, scolor },
			bgGradientMode = BODYPARTS.L_LEG,
			effects = bodyEffect
		})
		local kneeJoint = previewMain:addChild({
			shapeType = SPHERE,
			pos = { 0, -0.52, 0.72 },
			size = { 0.32, 0.32, 0.32 },
			bgColor = fcolor,
			effects = forceEffect
		})
		local trailObj = previewMain:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/trails",
			pos = { 0, 0.8, 0 },
			size = { 3.2, 3.2, 3.2 },
			rot = { -90, 90, 0 },
			bgColor = color
		})
		previewMain:rotate(0, 0, item.catid == 30 and -60 or 50)
		return true
	elseif (item.catid == 73) then
		-- Hair Colors
		headEffect.voronoiScale = (headEffect.voronoiScale or 7) / 5.6
		headEffect.shiftScale = 0.5625
		local headBody = previewMain:addChild({
			shapeType = SPHERE,
			size = { 0.8, 0.8, 0.8 },
			rot = { 0, 0, -40 },
			bgImage = TB_MENU_PLAYER_INFO.items.textures.head.equipped and "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head.tga" or "../../custom/tori/head.tga",
			bgColor = { 1, 1, 1, 1 },
			effects = headEffect
		})
		local hairObj = headBody:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/hair",
			size = { 8, 8, 8 },
			bgColor = color
		})
		previewHolder:moveTo(0, 0, -0.3)
		return true
	elseif (item.catid == 44 and item.colorid ~= 0) then
		-- Color Packs
		local boxObj = previewMain:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/box",
			pos = { 0, 0, -0.1 },
			size = { 1.3, 1.3, 1.3 },
			rot = { -90, 0, 0 },
			bgColor = { 0.7, 0.7, 0.7, 1 }
		})
		local logoObj = boxObj:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/logo",
			size = { 1.3, 1.3, 1.3 },
			bgColor = { 0.222, 0.137, 0.064, 1 },
		})
		local itemsObj = previewMain:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/colourobjs",
			size = { 1.3, 1.3, 1.3 },
			rot = { -90, 0, 0 },
			bgColor = color,
		})
		local jointsModel = previewMain:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/colourobjs_joints",
			size = { 1.3, 1.3, 1.3 },
			rot = { -90, 0, 0 },
			bgColor = { 0.66, 0.66, 0.66, 1 }
		})
		local colorGlow = boxObj:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/glow",
			size = { 1.3, 1.3, 1.3 },
			bgColor = color
		})
		previewHolder:moveTo(0, 0, -0.2)
		previewMain:rotate(-15, 0, 0)
		return true
	elseif (item.catid == 78) then
		-- 3D Items
		if (Store:showObjPreview(item, viewElement, previewMain, 2, trans, nil, level, noReload, updateOverride, updatedFunc)) then
			if (Store.Models[item.itemid].upgradeable) then
				local level = level or 1
				local buttonScale = viewport.shift.x - 5 > 32 and 32 or viewport.shift.x - 5
				if (Store.Models[item.itemid].levels > 1) then
					if (level < Store.Models[item.itemid].levels) then
						local nextLevel = viewElement:addChild({
							pos = { -(viewport.shift.x - buttonScale) / 2 - buttonScale, viewElement.size.h / 2 - buttonScale },
							size = { buttonScale, buttonScale * 2 },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							bgImage = "../textures/menu/general/buttons/arrowright.tga"
						})
						nextLevel:addMouseUpHandler(function()
								viewElement:kill(true)
								Store:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level + 1)
							end)
					end
					if (level > 1) then
						local prevLevel = viewElement:addChild({
							pos = { (viewport.shift.x - buttonScale) / 2, viewElement.size.h / 2 - buttonScale },
							size = { buttonScale, buttonScale * 2 },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							bgImage = "../textures/menu/general/buttons/arrowleft.tga"
						})
						prevLevel:addMouseUpHandler(function()
								viewElement:kill(true)
								Store:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level - 1)
							end)
					end
				end
			end
			return true
		else
			heightMod = 30
			if (get_option("autoupdate") == 0 and not updateOverride) then
				local downloadButton = viewElement:addChild({
					pos = { 0, iconScale + 5 },
					size = { viewElement.size.w, heightMod },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					interactive = true
				})
				downloadButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOAD)
				downloadButton:addMouseUpHandler(function()
						Store:showStoreItemInfo(item, noReload, true)
					end)
			else
				local updaterNotice = viewElement:addChild({
					pos = { 0, iconScale + 5 },
					size = { viewElement.size.w, heightMod },
					bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				updaterNotice:addChild({ shift = { 10, 0 } }):addAdaptedText(true, TB_MENU_LOCALIZED.STOREDOWNLOADINGMODEL)
			end
		end
	elseif (item.catid == 80) then
		-- Full Toris
		item.objs = {}
		for _, v in pairs(item.contents) do
			if (Store.Models[v] and not Store.Models[item.itemid]) then
				if (Store.Models[v].upgradeable) then
					item.upgradeable = true
					Store.Models[item.itemid] = table.clone(Store.Models[v])
				end
			end
			local newItem = Store:getItemInfo(v)
			if (newItem.catid == 78) then
				table.insert(item.objs, newItem)
			end
		end
		if (#item.objs > 0) then
			if (Store:showObjPreview(item, viewElement, previewMain, 2, trans, nil, level, noReload, updateOverride, updatedFunc)) then
				if (item.upgradeable) then
					local level = level or 1
					local buttonScale = viewport.shift.x - 5 > 32 and 32 or viewport.shift.x - 5
					if (Store.Models[item.itemid].levels > 1) then
						if (level < Store.Models[item.itemid].levels) then
							local nextLevel = viewElement:addChild({
								pos = { -(viewport.shift.x - buttonScale) / 2 - buttonScale, viewElement.size.h / 2 - buttonScale },
								size = { buttonScale, buttonScale * 2 },
								interactive = true,
								bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
								hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
								pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
								bgImage = "../textures/menu/general/buttons/arrowright.tga"
							})
							nextLevel:addMouseUpHandler(function()
									viewElement:kill(true)
									Store:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level + 1)
								end)
						end
						if (level > 1) then
							local prevLevel = viewElement:addChild({
								pos = { (viewport.shift.x - buttonScale) / 2, viewElement.size.h / 2 - buttonScale },
								size = { buttonScale, buttonScale * 2 },
								interactive = true,
								bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
								hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
								pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
								bgImage = "../textures/menu/general/buttons/arrowleft.tga"
							})
							prevLevel:addMouseUpHandler(function()
									viewElement:kill(true)
									Store:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level - 1)
								end)
						end
					end
				end
				return true
			else
				heightMod = 30
				if (get_option("autoupdate") == 0 and not updateOverride) then
					local downloadButton = viewElement:addChild({
						pos = { 0, iconScale + 5 },
						size = { viewElement.size.w, heightMod },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						interactive = true
					})
					downloadButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOAD)
					downloadButton:addMouseUpHandler(function()
							Store:showStoreItemInfo(item, noReload, true)
						end)
				else
					local updaterNotice = viewElement:addChild({
						pos = { 0, iconScale + 5 },
						size = { viewElement.size.w, heightMod },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
					})
					updaterNotice:addChild({ shift = { 10, 0 } }):addAdaptedText(true, TB_MENU_LOCALIZED.STOREDOWNLOADINGSET)
				end
			end
		end
	elseif (item.catid == 87) then
		-- Effects items
		local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
		local effectid = 0
		if (item.colorid > 0) then
			if (string.find(item.itemname, " Glow")) then
				effectid = EFFECT_TYPE.FRESNEL
			elseif (string.find(item.itemname, " Ripples")) then
				effectid = EFFECT_TYPE.VORONOI
			elseif (string.find(item.itemname, " Shift")) then
				effectid = EFFECT_TYPE.COLORSHIFT
			end
		elseif (item.colorid == -1) then
			effectid = EFFECT_TYPE.CELSHADED
		elseif (item.colorid == -2) then
			effectid = EFFECT_TYPE.DITHERING
		end

		local force = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUSTOMOBJ,
			objModel = "../models/store/presets/force",
			pos = { 0, 0, 0 },
			size = { 2, 2, 2 },
			rot = { 10, 90, 40 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true,
			effects = {
				id = bit.bor(forceEffect.id or EFFECT_TYPE.NONE, effectid),
				glowIntensity = effectid == EFFECT_TYPE.FRESNEL and 20 or forceEffect.glowIntensity,
				glowColor = effectid == EFFECT_TYPE.FRESNEL and item.colorid or forceEffect.glowColor,
				ditherPixelSize = effectid == EFFECT_TYPE.DITHERING and 1 or forceEffect.ditherPixelSize,
				voronoiScale = effectid == EFFECT_TYPE.VORONOI and 1 or (forceEffect.voronoiScale or 0) / 7,
				voronoiColor = effectid == EFFECT_TYPE.VORONOI and item.colorid or forceEffect.voronoiColor,
				shiftColor = effectid == EFFECT_TYPE.COLORSHIFT and item.colorid or forceEffect.shiftColor,
				shiftPeriod = effectid == EFFECT_TYPE.COLORSHIFT and 1 or forceEffect.shiftPeriod,
				shiftScale = 0.45
			}
		})
		local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
		if (TB_MENU_PLAYER_INFO.items.textures.head.equipped) then
			headTexture[1] = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head.tga"
		end
		local head = UIElement3D.new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0, 0, 0 },
			size = { 0.8, 0.8, 0.8 },
			rot = { 0, 0, -10 },
			bgColor = { 1, 1, 1, 1 },
			viewport = true,
			bgImage = headTexture,
			effects = {
				id = bit.bor(headEffect.id or 0, effectid),
				glowIntensity = effectid == EFFECT_TYPE.FRESNEL and 20 or headEffect.glowIntensity,
				glowColor = effectid == EFFECT_TYPE.FRESNEL and item.colorid or headEffect.glowColor,
				ditherPixelSize = effectid == EFFECT_TYPE.DITHERING and 1 or headEffect.ditherPixelSize,
				voronoiScale = effectid == EFFECT_TYPE.VORONOI and 1.25 or (headEffect.voronoiScale or 0) / 5.6,
				voronoiColor = effectid == EFFECT_TYPE.VORONOI and item.colorid or headEffect.voronoiColor,
				shiftColor = effectid == EFFECT_TYPE.COLORSHIFT and item.colorid or headEffect.shiftColor,
				shiftPeriod = effectid == EFFECT_TYPE.COLORSHIFT and 1 or headEffect.shiftPeriod,
				shiftScale = 0.5625
			}
		})
		return true
	end
	viewport:kill()
	background:kill()

	local iconScale = viewElement.size.w > viewElement.size.h and viewElement.size.h or viewElement.size.w
	iconScale = math.min(item.itemid > 4300 and 128 or 64, iconScale)
	viewElement.size.h = iconScale + heightMod + 10
	local itemIcon = viewElement:addChild({
		pos = { (viewElement.size.w - iconScale) / 2, 0 },
		size = { iconScale, iconScale },
		bgImage = Store:getItemIcon(item.itemid)
	})
	if (heightMod > 0) then
		return true
	end
	return false
end

---@class StoreCustomTexture : PlayerCustomTexture
---@field path string

---This is the same as `PlayerInfoCustomTextures` except it has `StoreCustomTexture` as fields
---@class StoreCustomTextures
---@field head StoreCustomTexture
---@field breast StoreCustomTexture
---@field chest StoreCustomTexture
---@field stomach StoreCustomTexture
---@field groin StoreCustomTexture
---@field r_pec StoreCustomTexture
---@field r_bicep StoreCustomTexture
---@field r_tricep StoreCustomTexture
---@field l_pec StoreCustomTexture
---@field l_bicep StoreCustomTexture
---@field l_tricep StoreCustomTexture
---@field r_hand StoreCustomTexture
---@field l_hand StoreCustomTexture
---@field r_butt StoreCustomTexture
---@field l_butt StoreCustomTexture
---@field r_thigh StoreCustomTexture
---@field l_thigh StoreCustomTexture
---@field r_leg StoreCustomTexture
---@field l_leg StoreCustomTexture
---@field r_foot StoreCustomTexture
---@field l_foot StoreCustomTexture

---@class StorePlayerPreviewBody : UIElement3D
---@field linked StorePlayerPreviewBody[]

---@class StorePlayerPreview
---@field bodypart StorePlayerPreviewBody[]
---@field joint StorePlayerPreviewBody[]

---Spawns a player preview in a 3D viewport
---@param previewHolder UIElement3D
---@param trans any
---@param customTextures StoreCustomTextures?
---@return StorePlayerPreview
function Store:showPlayerBody(previewHolder, trans, customTextures)
	local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
	local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
	local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
	local tcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.torso)
	---@type StoreCustomTextures
	---@diagnostic disable-next-line: assign-type-mismatch
	local textures = TB_MENU_PLAYER_INFO.items.textures
	local customPath = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/"
	if (customTextures) then
		for i, _ in pairs(textures) do
			for j, k in pairs(customTextures) do
				if (i == j) then
					textures[i] = k
				end
			end
		end
	end

	local bodyhead = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0, 0, 0 },
		size = { 0.8, 0.8, 0.8 },
		viewport = true,
		bgImage = textures.head.equipped and (textures.head.path or (customPath .. "head.tga")) or "../../custom/tori/head.tga",
		bgColor = { 1, 1, 1, 1 }
	})
	local bodybreast = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 0, 0.2, -1.8 },
		size = { 0.8, 0.4, 1.2 },
		bgColor = textures.breast.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
		viewport = true
	})
	if (textures.breast.equipped) then
		bodybreast:updateImage(textures.breast.path or (customPath .. "breast.tga"))
	end
	local lbodypecs = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 1, 0.2, -2 },
		size = { 0.8, 0.6, 0.8 },
		bgColor = textures.l_pec.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
		viewport = true
	})
	if (textures.l_pec.equipped) then
		lbodypecs:updateImage(textures.l_pec.path or (customPath .. "l_pec.tga"))
	end
	local rbodypecs = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -1, 0.2, -2 },
		size = { 0.8, 0.6, 0.8 },
		bgColor = textures.r_pec.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
		viewport = true
	})
	if (textures.r_pec.equipped) then
		rbodypecs:updateImage(textures.r_pec.path or (customPath .. "r_pec.tga"))
	end
	local bodychest = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 0, 0.2, -2.8 },
		size = { 2, 0.6, 0.8 },
		bgColor = textures.chest.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
		viewport = true
	})
	if (textures.chest.equipped) then
		bodychest:updateImage(textures.chest.path or (customPath .. "chest.tga"))
	end
	local bodystomach = UIElement3D.new({
		parent = previewHolder,
		pos = { 0, 0.4, -3.6 },
		size = { 1.4, 0.8, 0.6 },
		shapeType = CUBE,
		viewport = true
	})
	local bodystomachp, bodystomachs = nil, nil
	if (textures.stomach.equipped) then
		bodystomach.bgColor = { 1, 1, 1, 1 }
		bodystomach:updateImage(textures.stomach.path or (customPath .. "stomach.tga"))
	else
		bodystomach:addCustomDisplay(true, function() end)
		bodystomachp = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0, 0.4, -3.6 },
			size = { 0.6, 0.8, 1.4 },
			bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = "../textures/store/presets/prgrad.tga",
			rot = { 90, 90, 0 },
			viewport = true
		})
		bodystomachs = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0, 0.4, -3.6 },
			size = { 0.6, 0.8, 1.4 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 90, 90, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local bodygroin = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 0, 0.6, -4.4 },
		size = { 0.8, 0.6, 0.8 },
		viewport = true
	})
	local bodygroinp, bodygroins = nil, nil
	if (textures.groin.equipped) then
		bodygroin.bgColor = { 1, 1, 1, 1 }
		bodygroin:updateImage(textures.groin.path or (customPath .. "groin.tga"))
	else
		bodygroin:addCustomDisplay(true, function() end)
		bodygroinp = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0, 0.6, -4.4 },
			size = { 0.8, 0.6, 0.8 },
			bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = "../textures/store/presets/prgrad.tga",
			rot = { 90, 90, 0 },
			viewport = true
		})
		bodygroins = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0, 0.6, -4.4 },
			size = { 0.8, 0.6, 0.8 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 90, 90, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local lbodythigh = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { 0.8, 0.6, -6.2 },
		size = { 0.48, 0.48, 2.16 },
		viewport = true
	})
	lbodythigh:addCustomDisplay(true, function() end)
	local lbodythighp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { 0.8, 0.6, -6.2 },
		size = { 0.48, 1.2, 0 },
		bgColor = textures.l_thigh.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.l_thigh.equipped and (textures.l_thigh.path or (customPath .. "l_thigh.tga")) or "../textures/store/presets/gradient1.tga",
		rot = { 0, 0, 0 },
		viewport = true
	})
	local lbodythighs = nil
	if (not textures.l_thigh.equipped) then
		lbodythighs = UIElement3D.new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { 0.8, 0.6, -6.2 },
			size = { 0.48, 1.2, 0 },
			bgImage = "../textures/store/presets/gradient2.tga",
			rot = { 0, 0, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local rbodythigh = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { -0.8, 0.6, -6.2 },
		size = { 0.48, 0.48, 2.16 },
		viewport = true
	})
	rbodythigh:addCustomDisplay(true, function() end)
	local rbodythighp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { -0.8, 0.6, -6.2 },
		size = { 0.48, 1.2, 0 },
		bgColor = textures.r_thigh.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.r_thigh.equipped and (textures.r_thigh.path or (customPath .. "r_thigh.tga")) or "../textures/store/presets/gradient1.tga",
		rot = { 0, 0, 0 },
		viewport = true
	})
	local rbodythighs = nil
	if (not textures.r_thigh.equipped) then
		rbodythighs = UIElement3D.new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { -0.8, 0.6, -6.2 },
			size = { 0.48, 1.2, 0 },
			bgImage = "../textures/store/presets/gradient2.tga",
			rot = { 0, 0, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local lbodyleg = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { 0.8, 0.6, -8.6 },
		size = { 0.52, 0.52, 2.24 },
		viewport = true
	})
	lbodyleg:addCustomDisplay(true, function() end)
	local lbodylegp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { 0.8, 0.6, -8.6 },
		size = { 0.52, 1.2, 0 },
		bgColor = textures.l_leg.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.l_leg.equipped and (textures.l_leg.path or (customPath .. "l_leg.tga")) or "../textures/store/presets/gradient1.tga",
		rot = { 0, 0, 0 },
		viewport = true
	})
	local lbodylegs = nil
	if (not textures.l_leg.equipped) then
		lbodylegs = UIElement3D.new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { 0.8, 0.6, -8.6 },
			size = { 0.52, 1.2, 0 },
			bgImage = "../textures/store/presets/gradient2.tga",
			rot = { 0, 0, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local rbodyleg = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { -0.8, 0.6, -8.6 },
		size = { 0.52, 0.52, 2.24 },
		viewport = true
	})
	rbodyleg:addCustomDisplay(true, function() end)
	local rbodylegp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CAPSULE,
		pos = { -0.8, 0.6, -8.6 },
		size = { 0.52, 1.2, 0 },
		bgColor = textures.r_leg.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.r_leg.equipped and (textures.r_leg.path or (customPath .. "r_leg.tga")) or "../textures/store/presets/gradient1.tga",
		rot = { 0, 0, 0 },
		viewport = true
	})
	local rbodylegs = nil
	if (not textures.r_leg.equipped) then
		rbodylegs = UIElement3D.new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { -0.8, 0.6, -8.6 },
			size = { 0.52, 1.2, 0 },
			bgImage = "../textures/store/presets/gradient2.tga",
			rot = { 0, 0, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local lbodyfoot = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 0.8, 0.2, -10.2 },
		size = { 0.8, 2, 0.32 },
		viewport = true
	})
	lbodyfoot:addCustomDisplay(true, function() end)
	local lbodyfootp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 0.8, 0.2, -10.2 },
		size = { 2, 0.32, 0.8 },
		bgColor = textures.l_foot.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.l_foot.equipped and (textures.l_foot.path or (customPath .. "l_foot.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 90, 90, 0 },
		viewport = true
	})
	local lbodyfoots = nil
	if (not textures.l_foot.equipped) then
		lbodyfoots = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0.8, 0.2, -10.2 },
			size = { 2, 0.32, 0.8 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 90, 90, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local rbodyfoot = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -0.8, 0.2, -10.2 },
		size = { 0.8, 2, 0.32 },
		viewport = true
	})
	rbodyfoot:addCustomDisplay(true, function() end)
	local rbodyfootp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -0.8, 0.2, -10.2 },
		size = { 2, 0.32, 0.8 },
		bgColor = textures.r_foot.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.r_foot.equipped and (textures.r_foot.path or (customPath .. "r_foot.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 90, 90, 0 },
		viewport = true
	})
	local rbodyfoots = nil
	if (not textures.r_foot.equipped) then
		rbodyfoots = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -0.8, 0.2, -10.2 },
			size = { 2, 0.32, 0.8 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 90, 90, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local lbodybicep = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 2.2, 0.2, -1.4 },
		size = { 1.6, 0.8, 0.8 },
		viewport = true
	})
	lbodybicep:addCustomDisplay(true, function() end)
	local lbodybicepp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 2.2, 0.2, -1.4 },
		size = { 1.6, 0.8, 0.8 },
		bgColor = textures.l_bicep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.l_bicep.equipped and (textures.l_bicep.path or (customPath .. "l_biceps.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 0, 0, 180 },
		viewport = true
	})
	local lbodybiceps = nil
	if (not textures.l_bicep.equipped) then
		lbodybiceps = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 2.2, 0.2, -1.4 },
			size = { 1.6, 0.8, 0.8 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 0, 0, 180 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local rbodybicep = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -2.2, 0.2, -1.4 },
		size = { 1.6, 0.8, 0.8 },
		viewport = true
	})
	rbodybicep:addCustomDisplay(true, function() end)
	local rbodybicepp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -2.2, 0.2, -1.4 },
		size = { 1.6, 0.8, 0.8 },
		bgColor = textures.r_bicep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.r_bicep.equipped and (textures.r_bicep.path or (customPath .. "r_biceps.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 0, 0, 0 },
		viewport = true
	})
	local rbodybiceps = nil
	if (not textures.r_bicep.equipped) then
		rbodybiceps = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -2.2, 0.2, -1.4 },
			size = { 1.6, 0.8, 0.8 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 0, 0, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local lbodytricep = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 3.8, 0.2, -1.4 },
		size = { 1.6, 0.4, 0.4 },
		viewport = true
	})
	lbodytricep:addCustomDisplay(true, function() end)
	local lbodytricepp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 3.8, 0.2, -1.4 },
		size = { 1.6, 0.4, 0.4 },
		bgColor = textures.l_tricep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.l_tricep.equipped and (textures.l_tricep.path or (customPath .. "l_triceps.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 0, 0, 180 },
		viewport = true
	})
	local lbodytriceps = nil
	if (not textures.l_tricep.equipped) then
		lbodytriceps = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 3.8, 0.2, -1.4 },
			size = { 1.6, 0.4, 0.4 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 0, 0, 180 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local rbodytricep = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -3.8, 0.2, -1.4 },
		size = { 1.6, 0.4, 0.4 },
		viewport = true
	})
	rbodytricep:addCustomDisplay(true, function() end)
	local rbodytricepp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -3.8, 0.2, -1.4 },
		size = { 1.6, 0.4, 0.4 },
		bgColor = textures.r_tricep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.r_tricep.equipped and (textures.r_tricep.path or (customPath .. "r_triceps.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 0, 0, 0 },
		viewport = true
	})
	local rbodytriceps = nil
	if (not textures.r_tricep.equipped) then
		rbodytriceps = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -3.8, 0.2, -1.4 },
			size = { 1.6, 0.4, 0.4 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 0, 0, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local lbodyhand = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 5.4, 0, -1.4 },
		size = { 0.88, 0.88, 0.88 },
		viewport = true
	})
	lbodyhand:addCustomDisplay(true, function() end)
	local lbodyhandp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 5.4, 0, -1.4 },
		size = { 0.88, 0.88, 0.88 },
		bgColor = textures.l_hand.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.l_hand.equipped and (textures.l_hand.path or (customPath .. "l_hand.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 0, 0, 180 },
		viewport = true
	})
	local lbodyhands = nil
	if (not textures.l_hand.equipped) then
		lbodyhands = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 5.4, 0, -1.4 },
			size = { 0.88, 0.88, 0.88 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 0, 0, 180 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local rbodyhand = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -5.4, 0, -1.4 },
		size = { 0.88, 0.88, 0.88 },
		viewport = true
	})
	rbodyhand:addCustomDisplay(true, function() end)
	local rbodyhandp = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -5.4, 0, -1.4 },
		size = { 0.88, 0.88, 0.88 },
		bgColor = textures.r_hand.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
		bgImage = textures.r_hand.equipped and (textures.r_hand.path or (customPath .. "r_hand.tga")) or "../textures/store/presets/prgrad.tga",
		rot = { 0, 0, 0 },
		viewport = true
	})
	local rbodyhands = nil
	if (not textures.r_hand.equipped) then
		rbodyhands = UIElement3D.new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -5.4, 0, -1.4 },
			size = { 0.88, 0.88, 0.88 },
			bgImage = "../textures/store/presets/secgrad.tga",
			rot = { 0, 0, 0 },
			bgColor = { scolor.r, scolor.g, scolor.b, trans },
			viewport = true
		})
	end
	local rbodybutt = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { -0.8, 0.6, -4.8 },
		size = { 0.4, 0.4, 0.4 },
		viewport = true
	})
	local lbodybutt = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUBE,
		pos = { 0.8, 0.6, -4.8 },
		size = { 0.4, 0.4, 0.4 },
		viewport = true
	})

	local neck = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0, 0.2, -0.6 },
		size = { 0.44, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lpecs = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0.6, 0, -1.8 },
		size = { 0.72, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local rpecs = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -0.6, 0, -1.8 },
		size = { 0.72, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lshoulder = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 1.4, 0.2, -1.4 },
		size = { 0.72, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local rshoulder = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -1.4, 0.2, -1.4 },
		size = { 0.72, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lelbow = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 3, 0.2, -1.4 },
		size = { 0.64, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local relbow = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -3, 0.2, -1.4 },
		size = { 0.64, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lwrist = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 4.8, 0.2, -1.4 },
		size = { 0.44, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local rwrist = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -4.8, 0.2, -1.4 },
		size = { 0.44, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local chest = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0, 0.2, -2.4 },
		size = { 0.72, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lumbar = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0, 0.4, -3.2 },
		size = { 0.64, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local abs = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0, 0.6, -4 },
		size = { 0.56, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lglute = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0.4, 1, -4.56 },
		size = { 0.64, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local rglute = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -0.4, 1, -4.56 },
		size = { 0.64, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lhip = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0.84, 0.6, -5 },
		size = { 0.64, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local rhip = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -0.84, 0.6, -5 },
		size = { 0.64, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lknee = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0.8, 0.6, -7.4 },
		size = { 0.56, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local rknee = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -0.8, 0.6, -7.4 },
		size = { 0.56, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local lankle = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { 0.8, 0.8, -9.6 },
		size = { 0.44, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})
	local rankle = UIElement3D.new({
		parent = previewHolder,
		shapeType = SPHERE,
		pos = { -0.8, 0.8, -9.6 },
		size = { 0.44, 0, 0 },
		bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
		viewport = true
	})

	bodystomach.linked = { bodystomachp, bodystomachs }
	bodygroin.linked = { bodygroinp, bodygroins }
	lbodythigh.linked = { lbodythighp, lbodythighs }
	rbodythigh.linked = { rbodythighp, rbodythighs }
	lbodyleg.linked = { lbodylegp, lbodylegs }
	rbodyleg.linked = { rbodylegp, rbodylegs }
	lbodyfoot.linked = { lbodyfootp, lbodyfoots }
	rbodyfoot.linked = { rbodyfootp, rbodyfoots }
	lbodybicep.linked = { lbodybicepp, lbodybiceps }
	rbodybicep.linked = { rbodybicepp, rbodybiceps }
	lbodytricep.linked = { lbodytricepp, lbodytriceps }
	rbodytricep.linked = { rbodytricepp, rbodytriceps }
	lbodyhand.linked = { lbodyhandp, lbodyhands }
	rbodyhand.linked = { rbodyhandp, rbodyhands }

	-- neck.linked = { jneck }
	-- lpecs.linked = { jlpecs }
	-- rpecs.linked = { jrpecs }
	-- lshoulder.linked = { jlshoulder }
	-- rshoulder.linked = { jrshoulder }
	-- lelbow.linked = { jlelbow }
	-- relbow.linked = { jrelbow }
	-- lwrist.linked = { jlwrist }
	-- rwrist.linked = { jrwrist }
	-- chest.linked = { jchest }
	-- lumbar.linked = { jlumbar }
	-- abs.linked = { jabs }
	-- lglute.linked = { jlglute }
	-- rglute.linked = { jrglute }
	-- lhip.linked = { jlhip }
	-- rhip.linked = { jrhip }
	-- lknee.linked = { jlknee }
	-- rknee.linked = { jrknee }
	-- lankle.linked = { jlankle }
	-- rankle.linked = { jrankle }

	local bodyparts = { bodyhead, bodybreast, bodychest, bodystomach, bodygroin, rbodypecs, rbodybicep, rbodytricep, lbodypecs, lbodybicep, lbodytricep, rbodyhand, lbodyhand, rbodybutt, lbodybutt, rbodythigh, lbodythigh, lbodyleg, rbodyleg, rbodyfoot, lbodyfoot }
	local joints = { neck, chest, lumbar, abs, rpecs, rshoulder, relbow, lpecs, lshoulder, lelbow, rwrist, lwrist, rglute, lglute, rhip, lhip, rknee, lknee, rankle, lankle }
	return { bodypart = bodyparts, joint = joints }
end

---Displays a 3D item in a viewport
---@param item StoreItem
---@param previewHolder UIElement3D
---@param scaleMultiplier number
---@param objPath string
---@param bodyInfos StorePlayerPreview
---@param cameraMove boolean
---@param level integer?
---@return UIElement3D?
function Store:drawObjItem(item, previewHolder, scaleMultiplier, objPath, bodyInfos, cameraMove, level)
	if (not Store.Models[item.itemid]) then
		if (get_option("autoupdate") ~= 0) then
			Store.Download()
		end
		return
	end
	local modelInfo = Store.Models[item.itemid].upgradeable and Store.Models[item.itemid][level or 1] or Store.Models[item.itemid]
	local color = get_color_info(modelInfo.colorid)

	scaleMultiplier = scaleMultiplier * (modelInfo.dynamic and 1 or 5)
	local modelData = { pos = { 0, 0, 0 }, rot = { 0, 0, 0 } }
	local scale = { 0.8, 0.8, 0.8 }
	if (modelInfo.bodyid < 21) then
		local body = bodyInfos.bodypart[modelInfo.bodyid + 1]
		modelData.pos = { body.shift.x, body.shift.y, body.shift.z }
		if (cameraMove) then
			local pos = body.pos
			---@diagnostic disable-next-line: param-type-mismatch
			previewHolder.parent:rotate(0, 0, -previewHolder.parent.rotXYZ.z)
			previewHolder:moveTo(-pos.x, -pos.y, -pos.z + 10)
		end
	elseif (modelInfo.bodyid < 41) then
		local joint = bodyInfos.joint[modelInfo.bodyid - 20]
		modelData.pos = { joint.shift.x, joint.shift.y, joint.shift.z }
		if (cameraMove) then
			local pos = joint.pos
			---@diagnostic disable-next-line: param-type-mismatch
			previewHolder.parent:rotate(0, 0, -previewHolder.parent.rotXYZ.z)
			previewHolder:moveTo(-pos.x, -pos.y, -pos.z + 10)
		end
	else
		modelData.pos = { 0, 0, -11 }
		if (cameraMove) then
			---@diagnostic disable-next-line: param-type-mismatch
			previewHolder.parent:moveTo(0, 7, 4)
		end
	end

	---Some overrides to show stone relaxes nicer in shop
	local stonerelax = { 3140, 3143, 3144, 3145, 3146, 3147, 3148, 3149, 3150, 3151, 3152, 3153, 3154, 3155, 3156, 3157, 3158, 3159, 3160, 3161 }
	if (in_array(item.itemid, stonerelax)) then
		modelInfo.partless = true
	end

	if (modelInfo.dynamic) then
		if (modelInfo.bodyid < 21) then
			local mScale = bodyInfos.bodypart[modelInfo.bodyid + 1].size
			scale = { mScale.x, mScale.y, mScale.z }
		elseif (modelInfo.bodyid < 41) then
			local mScale = bodyInfos.joint[modelInfo.bodyid - 20].size
			scale = { mScale.x, mScale.x, mScale.x }
		end
	end
	if (modelInfo.partless) then
		if (modelInfo.bodyid < 21) then
			if (bodyInfos.bodypart[modelInfo.bodyid + 1].linked) then
				for _, v in pairs(bodyInfos.bodypart[modelInfo.bodyid + 1].linked) do
					v:kill()
				end
			else
				bodyInfos.bodypart[modelInfo.bodyid + 1]:kill()
			end
		elseif (modelInfo.bodyid < 41) then
			if (bodyInfos.joint[modelInfo.bodyid - 20].linked) then
				for _, v in pairs(bodyInfos.joint[modelInfo.bodyid - 20].linked) do
					v:kill()
				end
			else
				bodyInfos.joint[modelInfo.bodyid - 20]:kill()
			end
		end
	end
	local model = UIElement3D.new({
		parent = previewHolder,
		shapeType = CUSTOMOBJ,
		objModel = objPath,
		pos = modelData.pos,
		size = { scale[1] * scaleMultiplier, scale[2] * scaleMultiplier, scale[3] * scaleMultiplier },
		rot = modelData.rot,
		bgColor = { color.r, color.g, color.b, modelInfo.alpha / 255 },
		viewport = true
	})
	return model
end

---Triggers display of the specified 3D objects
---@param items StoreItem[]
---@param viewElement UIElement
---@param previewHolder UIElement3D
---@param scaleMultiplier number
---@param trans number
---@param textures StoreCustomTextures?
---@param level integer?
---@param noReload boolean?
---@param updateOverride boolean?
---@param updatedFunc function?
---@return boolean
function Store:showObjPreview(items, viewElement, previewHolder, scaleMultiplier, trans, textures, level, noReload, updateOverride, updatedFunc)
	level = level or 1
	viewElement.scrollEnabled = true
	viewElement:addMouseHandlers(function(s, x, y)
			if (s >= 4 and viewElement.hoverState == BTN_HVR) then
				previewHolder.parent:moveTo(0, -0.3 * y)
			else
				viewElement.pressedPos.x = MOUSE_X
			end
		end)
	local itemslist = {}
	if (not items.objs) then
		table.insert(itemslist, items)
	else
		for _, v in pairs(items.objs) do
			table.insert(itemslist, v)
		end
		items.objs = nil
		table.insert(itemslist, items)
	end

	local modelDrawn = false
	local bodyInfos = Store:showPlayerBody(previewHolder, trans, textures)
	local cameraMove = true
	if (#itemslist > 1) then
		previewHolder.parent:moveTo(0, 10, 4.5)
		cameraMove = false
	end

	local itemHolder = nil
	for _, item in pairs(itemslist) do
		local objPath = "../models/store/" .. item.itemid .. (level > 1 and ("_" .. level) or '')
		local objModel = Files.Open("../data/models/store/" .. item.itemid .. (level > 1 and ("_" .. level) or '') .. ".obj")
		if (objModel.data) then
			objModel:close()
			itemHolder = Store:drawObjItem(item, previewHolder, scaleMultiplier, objPath, bodyInfos, cameraMove, level)
			modelDrawn = itemHolder and true or false
		end
	end
	if (noReload) then
		return modelDrawn
	end

	local function downloadFile(i)
		if (i > #itemslist) then
			if (Store.ItemView == nil or Store.ItemView.destroyed or Store.ItemView.itemid ~= itemslist[1].itemid) then
				return
			end
			local sectionTime = (Store.ItemView and not Store.ItemView.destroyed) and Store.ItemView.updated or 0
			if (updatedFunc) then
				updatedFunc()
			elseif (sectionTime > 0) then
				if (sectionTime == Store.ItemView.updated) then
					Store:showStoreItemInfo(items, true)
				end
			end
			return
		end

		local load = itemslist[i].itemid
		if (Store.Models[itemslist[i].itemid] and level > 1 and Store.Models[itemslist[i].itemid].upgradeable) then
			load = load .. "_" .. level
		end

		Request:queue(function()
				download_server_file(load, 1)
			end, "store_obj_downloader", function()
				downloadFile(i + 1)
			end)
	end

	if (updateOverride or get_option("autoupdate") == 1) then
		downloadFile(1)
	end
	return modelDrawn
end

---@alias StorePurchaseMode
---| 0 MODE_TC
---| 1 MODE_ST

---Triggers default item purchase flow
---@param item StoreItem
---@param mode StorePurchaseMode
function Store:buyItem(item, mode)
	local overlay = TBMenu:spawnWindowOverlay()
	local purchasing = overlay:addChild({
		pos = { overlay.size.w / 7 * 2, overlay.size.h / 2 - 75 },
		size = { overlay.size.w / 7 * 3, 150 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	purchasing:addAdaptedText(false, TB_MENU_LOCALIZED.STOREPURCHASINGITEM)

	Request:queue(function()
			if (mode == MODE_TC) then
				buy_tc(item.itemid .. ":" .. item.now_tc_price)
			else
				buy_st(item.itemid .. ":" .. item.now_usd_price)
			end
		end, "torishop_purchase", function()
			overlay:kill()
			Store:showPostPurchaseScreen(item)
		end, function()
			overlay:kill()
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASESERVERERROR)
		end)
end

---Displays a generic post item purchase screen to inform of purchase status and offer some quick actions with new items
---@param item StoreItem
---@param forceRefreshItem boolean?
function Store:showPostPurchaseScreen(item, forceRefreshItem)
	local response = get_network_response()
	if (response:find("^ERROR 0;")) then
		response = response:gsub("^ERROR 0;", "")
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERROR .. ": " .. response)
	elseif (response:find("^SUCCESS 0;")) then
		local invid = response:gsub("^SUCCESS 0;", "")
		if (forceRefreshItem) then
			local overlay = TBMenu:spawnWindowOverlay()
			local purchasing = overlay:addChild({
				pos = { overlay.size.w / 7 * 2, overlay.size.h / 2 - 75 },
				size = { overlay.size.w / 7 * 3, 150 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			TBMenu:displayLoadingMark(purchasing, TB_MENU_LOCALIZED.STORESTEAMPURCHASELOADING)
			Request:queue(function()
					download_server_info("getitemid&invid=" .. invid)
				end, "torishop_refresh_inventory_itemid", function()
					overlay:kill()
					local response = get_network_response()
					if (response:find("^ITEMID 0;")) then
						local itemid = response:gsub("^ITEMID 0;", "")
						local item = Store:getItemInfo(tonumber(itemid) or 0)
						update_tc_balance()
						download_inventory()
						if (#item.contents > 0) then
							Store:spawnInventoryUpdateWaiter()
							show_dialog_box(StoreInternal.InventoryActions.Unpack, TB_MENU_LOCALIZED.STOREPURCHASECONGRATULATIONSRECEIVED .. " " .. item.itemname .. "!\n\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKPURCHASE1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACKPURCHASE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKPURCHASE2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, invid)
						elseif (item.ingame) then
							if (in_array(item.catid, StoreInternal.Categories.Colors)) then
								Request:queue(function() check_color_achievement(item.colorid) end, "checkColorAchievements")
							end
							show_dialog_box(StoreInternal.InventoryActions.Activate, TB_MENU_LOCALIZED.STOREPURCHASECONGRATULATIONSRECEIVED .. " "  .. item.itemname .. "!\n\n" .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATEPURCHASE1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATEPURCHASE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATEPURCHASE2 .. "?"), invid)
						else
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREYOUHAVEPURCHASEDITEM .. " " .. item.itemname .. "!\n" .. TB_MENU_LOCALIZED.STOREPURCHASEDITEMPLACEDININVENTORY)
						end
					else
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERROR)
					end
				end, function()
					overlay:kill()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERRORUNDEF)
				end)
			return
		end
		update_tc_balance()
		download_inventory()
		if (#item.contents > 0) then
			Store:spawnInventoryUpdateWaiter()
			show_dialog_box(StoreInternal.InventoryActions.Unpack, TB_MENU_LOCALIZED.STOREPURCHASECONGRATULATIONS .. "\n" .. TB_MENU_LOCALIZED.STOREPURCHASEWOULDYOULIKETOUNPACK1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREPURCHASEWOULDYOULIKETOUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREPURCHASEWOULDYOULIKETOUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, invid)
		elseif (item.ingame) then
			if (in_array(item.catid, StoreInternal.Categories.Colors)) then
				Request:queue(function() check_color_achievement(item.colorid) end, "checkColorAchievements")
			end
			Store:spawnInventoryUpdateWaiter()
			show_dialog_box(StoreInternal.InventoryActions.Activate, TB_MENU_LOCALIZED.STOREPURCHASECONGRATULATIONS .. "\n" .. TB_MENU_LOCALIZED.STOREPURCHASEWOULDYOULIKETOACTIVATE1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREPURCHASEWOULDYOULIKETOACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREPURCHASEWOULDYOULIKETOACTIVATE2 .. "?"), invid)
		else
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREYOUHAVEPURCHASEDITEM .. " " .. item.itemname .. "!\n" .. TB_MENU_LOCALIZED.STOREPURCHASEDITEMPLACEDININVENTORY)
		end
	else
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERRORUNDEF)
	end
end

---Displays a hair item on a player in game
---@param item StoreItem
function Store:previewHairVanilla(item)
	if (Store.HairCache[item.itemid]) then
		for i = 0, 15 do
			local hr = Store.HairCache[item.itemid][i] or { i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
			set_hair_settings(0, hr[1], hr[2], hr[3], hr[4], hr[5], hr[6], hr[7], hr[8], hr[9], hr[10], hr[11], hr[12], hr[13], hr[14], hr[15], hr[16], hr[17])
		end
		reset_hair(0)
		set_hair_color(0, 0)
		return
	end
	TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STORELOADING, 10000)
	Request:queue(function() download_server_info("get_hair&itemid=" .. item.itemid) end, "storevanillahair" .. item.itemid, function()
			local response = get_network_response()
			TBMenu.StatusMessage.endTime = UIElement.clock
			Store.HairCache[item.itemid] = { }
			if (response:find("ERROR")) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREREQUESTNOTHAIRSTYLE)
				return
			end
			local id = 0
			for ln in response:gmatch("[^\n]+\n?") do
				local hr = { ln:match(("(%d+) ?"):rep(17)) }
				for i = 1, #hr do
					hr[i] = tonumber(hr[i]) or 0
				end
				set_hair_settings(0, hr[1], hr[2], hr[3], hr[4], hr[5], hr[6], hr[7], hr[8], hr[9], hr[10], hr[11], hr[12], hr[13], hr[14], hr[15], hr[16], hr[17])
				Store.HairCache[item.itemid][id] = hr
				id = id + 1
			end
			for i = id, 15 do
				set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
			reset_hair(0)
			set_hair_color(0, 0)
		end, function()
			TBMenu.StatusMessage.endTime = UIElement.clock
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR .. ": " .. get_network_error())
		end)
end

---Displays an item on a player in game
---@param item StoreItem
---@param parentItem StoreItem?
function Store:doItemPreviewVanilla(item, parentItem)
	if (item.catid == 1) then
		set_blood_color(0, item.colorid)
	elseif (item.catid == 2) then
		set_joint_relax_color(0, item.colorid)
	elseif (item.catid == 5) then
		set_torso_color(0, item.colorid)
	elseif (item.catid == 11) then
		set_ghost_color(0, item.colorid)
	elseif (item.catid == 12) then
		set_ground_impact_color(0, item.colorid)
		draw_ground_impact(0)
	elseif (item.catid == 20) then
		set_gradient_primary_color(0, item.colorid)
	elseif (item.catid == 21) then
		set_gradient_secondary_color(0, item.colorid)
	elseif (item.catid == 22) then
		set_joint_force_color(0, item.colorid)
	elseif (item.catid == 24) then
		local rgb = get_color_info(item.colorid)
		Store.VanillaPreviewer.Timer.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
	elseif (item.catid == 27) then
		set_separate_trail_color(0, 1, item.colorid)
	elseif (item.catid == 28) then
		set_separate_trail_color(0, 0, item.colorid)
	elseif (item.catid == 29) then
		set_separate_trail_color(0, 3, item.colorid)
	elseif (item.catid == 30) then
		set_separate_trail_color(0, 2, item.colorid)
	elseif (item.catid == 34) then
		local rgb = get_color_info(item.colorid)
		Store.VanillaPreviewer.Score.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
		Store.VanillaPreviewer.Name.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
	elseif (item.catid == 41) then
		-- Add a draw3d hook for grip manually; quicker than adding a full UIElement3D object
		add_hook("draw3d", self.HookNameVanilla, function()
				set_grip_info(0, 11, 1)
				local rHand = get_body_info(0, BODYPARTS.R_HAND)
				local rgb = get_color_info(item.colorid)
				set_color(rgb.r, rgb.g, rgb.b, 0.7)
				draw_sphere(rHand.pos.x - 0.12, rHand.pos.y - 0.07, rHand.pos.z + 0.02, 0.08)
			end)
	elseif (item.catid == 43) then
		runCmd("em " .. (item.colorid > 99 and ("%" .. item.colorid) or (item.colorid > 9 and ("^" .. item.colorid) or ("^0" .. item.colorid))) .. item.itemname)
	elseif (item.catid == 44) then
		set_blood_color(0, item.colorid)
		set_joint_relax_color(0, item.colorid)
		set_torso_color(0, item.colorid)
		set_ghost_color(0, item.colorid)
		set_ground_impact_color(0, item.colorid)
		draw_ground_impact(0)
		set_gradient_color(0, item.colorid, item.colorid)
		set_joint_force_color(0, item.colorid)
		local rgb = get_color_info(item.colorid)
		Store.VanillaPreviewer.Timer.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
		set_separate_trail_color(0, 1, item.colorid)
		set_separate_trail_color(0, 0, item.colorid)
		set_separate_trail_color(0, 3, item.colorid)
		set_separate_trail_color(0, 2, item.colorid)
		Store.VanillaPreviewer.Score.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
		Store.VanillaPreviewer.Name.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
		add_hook("draw3d", self.HookNameVanilla, function()
				set_grip_info(0, 11, 1)
				local rHand = get_body_info(0, BODYPARTS.R_HAND)
				set_color(rgb.r, rgb.g, rgb.b, 0.7)
				draw_sphere(rHand.pos.x + 0.12, rHand.pos.y + 0.07, rHand.pos.z + 0.02, 0.08)
			end)
		runCmd("em " .. (item.colorid > 99 and ("%" .. item.colorid) or (item.colorid > 9 and ("^" .. item.colorid) or ("^0" .. item.colorid))) .. item.itemname)
	elseif (item.catid == 72) then
		Store:previewHairVanilla(item)
	elseif (item.catid == 73) then
		set_hair_color(0, item.colorid)
	elseif (item.catid == 78) then
		local modelInfo = table.clone(Store.Models[item.itemid])
		if (not modelInfo) then
			-- Store.Models is missing data, redownload torishop data and refresh models table
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STORELOADING)
			Store.Download()
			return
		end
		if (not Files.Exists("../data/models/store/" .. item.itemid .. ".obj") or
			(modelInfo.textured and not Files.Exists("../data/models/store/" .. item.itemid .. "_obj.tga"))) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STORELOADING, 10000)
			download_server_file(tostring(item.itemid), 1)
			add_hook("pre_draw", self.HookNameVanilla, function()
					local downloads = get_downloads()
					if (#downloads > 0 and not parentItem) then
						for _, v in pairs(downloads) do
							if (v:find(item.itemid)) then
								return
							end
						end
					else
						TBMenu.StatusMessage.endTime = UIElement.clock
					end
					remove_hook("pre_draw", self.HookNameVanilla)
					Store:doItemPreviewVanilla(parentItem or item)
				end)
			return
		end
		if (modelInfo.upgradeable) then
			modelInfo = modelInfo[1]
		end
		if (modelInfo.bodyid < 21) then
			runCmd("obj load data/models/store/" .. item.itemid .. ".obj 0 " .. modelInfo.bodyid .. " " .. modelInfo.colorid .. " " .. modelInfo.alpha .. " " .. (modelInfo.textured and 1 or 0) .. " " .. (modelInfo.dynamic and 1 or 0) .. " " .. (modelInfo.partless and 1 or 0), false, CMD_ECHO_FORCE_DISABLED)
		elseif (modelInfo.bodyid < 41) then
			runCmd("objjoint load data/models/store/" .. item.itemid .. ".obj 0 " .. (modelInfo.bodyid - 21) .. " " .. modelInfo.colorid .. " " .. modelInfo.alpha .. " " .. (modelInfo.textured and 1 or 0) .. " " .. (modelInfo.dynamic and 1 or 0) .. " " .. (modelInfo.partless and 1 or 0), false, CMD_ECHO_FORCE_DISABLED)
		else
			runCmd("objfloor load data/models/store/" .. item.itemid .. ".obj 0 " .. (modelInfo.bodyid - 41), false, CMD_ECHO_FORCE_DISABLED)
		end
	elseif (item.catid == 80) then
		for _, v in pairs(item.contents) do
			if (Store.Models[v]) then
				Store:doItemPreviewVanilla({ catid = 78, itemid = v }, item)
			end
		end
	end
end

---Prepares vanilla item preview mode \
---*This functionality will be removed in future releases in favor of a proper player preview in a 3D viewport*
function Store:preparePreviewVanilla()
	STORE_VANILLA_PREVIEW = true
	set_option("uke", 0)
	set_option("hud", 0)
	STORE_VANILLA_TOOLTIP = tonumber(get_option("tooltip")) or 0
	set_option("tooltip", 0)
	chat_input_deactivate()
	open_replay("system/torishop.rpl", 0)
	load_player(0, TB_MENU_PLAYER_INFO.username)
	add_hook("draw2d", self.HookNameVanilla, function()
			if (UIElement.WorldState.match_frame >= 15) then
				add_hook("leave_game", self.HookNameVanilla, TBMenu.HideButton.btnUp)
				edit_game()
				dismember_joint(0, 3)
				dismember_joint(0, 2)
				run_frames(12)
				add_hook("draw2d", self.HookNameVanilla, function()
						if (UIElement.WorldState.match_frame >= 20) then
							remove_hook("draw2d", self.HookNameVanilla)
							for i = 0, 19 do
								local jointstate = math.floor(math.random(1, 4))
								set_joint_state(0, i, jointstate)
							end
						end
					end)
			end
		end)
end

---Spawns item category view in a vanilla previewer
---@param catid integer
function Store:spawnVanillaSectionView(catid)
	if (Store.VanillaPreviewer == nil) then return end
	if (Store.VanillaPreviewer.Section) then
		Store.VanillaPreviewer.Section:kill()
	end
	Store.VanillaPreviewer.Section = Store.VanillaPreviewer:addChild({
		pos = { 10, 10 },
		size = { 450, WIN_H - 100 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local elementHeight = 40
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(Store.VanillaPreviewer.Section, elementHeight + 10, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	local previewableSectionIds = {
		44, 22, 2, 20, 21, 1, 5, 11, 12, 24, 27, 28, 29, 30, 34, 41, 43, 73, 78, 72, 80
	}
	local previewableSections = {}
	local displaysectionid = 1
	for i, v in pairs(previewableSectionIds) do
		if (v == catid) then
			displaysectionid = i
		end
		table.insert(previewableSections, { text = Store:getCategoryInfo(v).name, action = function() Store:spawnVanillaSectionView(v) end })
	end
	local sectionsDropdownBG = topBar:addChild({
		shift = { 5, 5 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local sectionsDropdown = sectionsDropdownBG:addChild({
		shift = { 1, 1 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	TBMenu:spawnDropdown(sectionsDropdown, previewableSections, 25, nil, previewableSections[displaysectionid], nil, { scale = 0.7 })

	local resetButton = botBar:addChild({
		shift = { 10, 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	resetButton:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSRESETTODEFAULT)
	resetButton:addMouseHandlers(nil, function()
			load_player(0, TB_MENU_PLAYER_INFO.username)
		end)

	local listElements = Store:showVanillaSectionItems(listingHolder, elementHeight, catid)
	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

---Spawns vanilla item previewer controls and displays an item
---@param item StoreItem
function Store:spawnVanillaControls(item)
	Store.VanillaPreviewer = TBMenu.MenuMain:addChild({
		pos = { 0, -WIN_H * 2 },
		size = { WIN_W, WIN_H }
	})
	Store.VanillaPreviewer.killAction = function() Store.VanillaPreviewer = nil end
	Store.VanillaPreviewer.Score = Store.VanillaPreviewer:addChild({
		pos = { WIN_W / 2, 3 },
		size = { WIN_W / 2 - 10, 60 },
		uiColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	Store.VanillaPreviewer.Score:addAdaptedText(true, math.random(0, 10000000) .. "", nil, nil, FONTS.BIG, RIGHT, nil, nil, 0)
	Store.VanillaPreviewer.Name = Store.VanillaPreviewer:addChild({
		pos = { WIN_W / 2, Store.VanillaPreviewer.Score.size.h + Store.VanillaPreviewer.Score.shift.y - 10 },
		size = { WIN_W / 2 - 10, 30 },
		uiColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	Store.VanillaPreviewer.Name:addAdaptedText(true, TB_MENU_PLAYER_INFO.username, nil, nil, nil, RIGHT, nil, nil)
	Store.VanillaPreviewer.Timer = Store.VanillaPreviewer:addChild({
		pos = { WIN_W / 2, 43 },
		size = { 40, 40 },
		uiColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	Store.VanillaPreviewer.Timer:addCustomDisplay(true, function()
			set_color(unpack(Store.VanillaPreviewer.Timer.uiColor))
			draw_disk(Store.VanillaPreviewer.Timer.pos.x, Store.VanillaPreviewer.Timer.pos.y, Store.VanillaPreviewer.Timer.size.w - 20, Store.VanillaPreviewer.Timer.size.w, 15, 1, 180, -150, 0)
		end)

	Store:spawnVanillaSectionView(item.catid)
end

---Enables a vanilla preview for the specified item
---@param item StoreItem
function Store:itemPreviewVanilla(item)
	if (not STORE_VANILLA_PREVIEW) then
		Store:preparePreviewVanilla()
		Store:spawnVanillaControls(item)
	else
		Store:spawnVanillaSectionView(item.catid)
	end
	TBMenu.HideButton:show()
	TBMenu.HideButton.btnUp()
	for _, v in pairs(TBMenu.HideButton.child) do
		v:hide()
	end
	close_menu()

	Store:doItemPreviewVanilla(item)
end

---Generic function to initiate a USD purchase
---@param item StoreItem
---@param onSuccess function?
function Store.InitUSDPurchase(item, onSuccess)
	local overlay = TBMenu:spawnWindowOverlay()
	local purchaseWindow = overlay:addChild({
		pos = { WIN_W / 2 - 200, WIN_H / 2 - 75 },
		size = { 400, 150 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local initResult = buy_platform_mtx(item.itemid)
	if (initResult == nil) then
		if (is_steam()) then
			---No error handling with runCmd
			initResult = 0
			runCmd("steam purchase " .. item.itemid)
		else
			open_url("http://forum.toribash.com/tori_shop.php?action=process&item=" .. item.itemid, true)
			purchaseWindow:addChild({
				pos = { 20, 20 },
				size = { purchaseWindow.size.w - 40, purchaseWindow.size.h / 2 - 30 }
			}):addAdaptedText(TB_MENU_LOCALIZED.STORECOMPLETEPURCHASEINBROWSER)
			local okButton = purchaseWindow:addChild({
				pos = { 70, purchaseWindow.size.h / 2 },
				size = { purchaseWindow.size.w - 140, purchaseWindow.size.h / 2 - 20 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			okButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONOK)
			okButton:addMouseUpHandler(function()
					overlay:kill()
					Store.GetPlayerOffers()
					TBMenu.UserPaymentHistory = nil
				end)
			return
		end
	end

	if (initResult ~= 0) then
		purchaseWindow:addChild({
			pos = { 20, 20 },
			size = { purchaseWindow.size.w - 40, purchaseWindow.size.h / 2 - 30 }
		}):addAdaptedText(TB_MENU_LOCALIZED.STOREERRORPURCHASEMTXINIT)
		local okButton = purchaseWindow:addChild({
			pos = { 70, purchaseWindow.size.h / 2 },
			size = { purchaseWindow.size.w - 140, purchaseWindow.size.h / 2 - 20 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		okButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONOK)
		okButton:addMouseUpHandler(function() overlay:kill() end)
		return
	end

	TBMenu:displayLoadingMark(purchaseWindow, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT)
	if (is_steam()) then
		---With steam our client will keep rendering UI but no longer receive mouse inputs until the purchase is over.
		---We just spawn a mouse move event listener and wait for it to get the first hit to check on purchase status.
		local purchaseComplete = false
		local purchaseProgressMonitor = overlay:addChild({ interactive = true })
		purchaseProgressMonitor:addCustomDisplay(function()
				if (purchaseComplete) then
					if (overlay and not overlay.destroyed) then
						overlay:kill()
					end
					if (get_purchase_done() == 1) then
						TBMenu:showStatusMessage(item.itemname .. " " .. TB_MENU_LOCALIZED.STOREITEMPURCHASESUCCESSFUL)
						Notifications:getTotalNotifications(true)
						Store.GetPlayerOffers()
						if (onSuccess) then
							onSuccess()
						end
						TBMenu.UserPaymentHistory = nil
					else
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASECANCELLED)
					end
				end
			end)
		purchaseProgressMonitor:addMouseMoveHandler(function() purchaseComplete = true end)
	else
		---Mobile platforms, we have a dedicated hook that we will be listening to
		add_hook("purchase_status", Store.HookName .. item.itemid, function(result, error_code)
				---Make sure we ignore hook call from IAP status updates
				if (result == true and error_code ~= 0) then return end

				remove_hook("purchase_status", Store.HookName .. item.itemid)
				if (result == true) then
					if (purchaseWindow and not purchaseWindow.destroyed) then
						purchaseWindow:kill(true)
						TBMenu:displayLoadingMark(purchaseWindow, TB_MENU_LOCALIZED.STOREPURCHASEFINALIZING)
						local purchaseProgressMonitor = purchaseWindow:addChild({})
						purchaseProgressMonitor:addCustomDisplay(true, function()
								if (get_purchase_done() ~= 0) then
									if (overlay and not overlay.destroyed) then
										overlay:kill()
									end
									if (get_purchase_done() == 1) then
										local purchaseMsg = get_purchase_message()
										if (purchaseMsg == "finalized") then
											TBMenu:showStatusMessage(item.itemname .. " " .. TB_MENU_LOCALIZED.STOREITEMPURCHASESUCCESSFUL)
											update_tc_balance()
											Notifications:getTotalNotifications(true)
											Store.GetPlayerOffers()
										else
											TBMenu:showStatusMessage(purchaseMsg)
										end
										if (onSuccess) then
											onSuccess()
										end
									else
										if (_G.PLATFORM == "ANDROID") then
											---Android will automatically refund the payment if we don't acknowledge it by server, display a separate error
											TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERRORANDROID)
										else
											TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERRORCONTACTSUPPORT)
										end
									end
								end
							end)
					end
				else
					if (overlay and not overlay.destroyed) then
						overlay:kill()
					end
					if (_G.PLATFORM == "IPHONEOS") then
						if (error_code == 2) then
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASECANCELLED)
						else
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERROR .. " err " .. tostring(error_code))
						end
					elseif (_G.PLATFORM == "ANDROID") then
						if (error_code == 1) then
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASECANCELLED)
						elseif (error_code == 2 or error_code == 3 or error_code == 12) then
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREERRORPURCHASEMTXINIT)
						else
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREPURCHASEERROR .. " err " .. tostring(error_code))
						end
					end
				end
			end)
	end
end

---Displays information about a store item
---@param item StoreItem?
---@param noReload boolean?
---@param updateOverride boolean?
function Store:showStoreItemInfo(item, noReload, updateOverride)
	usage_event("storeitem")
	Store.ItemView:kill(true)
	Store.ItemView.updated = os.clock_real()
	Store.ItemView.itemid = item and item.itemid or nil
	TBMenu:addBottomBloodSmudge(Store.ItemView, 3)

	if (not item) then
		-- Placeholder for an empty item, don't show anything
		local infoMessage = Store.ItemView:addChild({
			pos = { Store.ItemView.size.w / 8, Store.ItemView.size.h / 5 },
			size = { Store.ItemView.size.w * 0.75, Store.ItemView.size.h * 0.6}
		})
		infoMessage:addAdaptedText(true, TB_MENU_LOCALIZED.STORESELECTITEMTOVIEWDETAILS)
		return
	end

	local saleBackground
	if (item.on_sale) then
		saleBackground = Store.ItemView:addChild({
			size = { Store.ItemView.size.w, Store.ItemView.size.w },
			bgImage = "../textures/store/sale.tga"
		})
	end
	local itemName = Store.ItemView:addChild({
		pos = { 10, 5 },
		size = { Store.ItemView.size.w - 20, 44 },
		uiShadowColor = TB_MENU_DEFAULT_BG_COLOR
	})
	itemName:addAdaptedText(true, item.itemname, nil, nil, FONTS.BIG, nil, nil, nil, nil, item.on_sale and 2 or 0)

	local scale = math.min(Store.ItemView.size.w - 50, Store.ItemView.size.h / 3)
	local itemPreviewAdvanced = Store.ItemView:addChild({
		pos = { 0, 54 },
		size = { Store.ItemView.size.w, scale },
		interactive = true
	})
	Store:showStoreAdvancedItemPreview(itemPreviewAdvanced, item, noReload, updateOverride)

	local itemInfo = Store.ItemView:addChild({
		pos = { 10, itemPreviewAdvanced.shift.y + itemPreviewAdvanced.size.h + 5 },
		size = { Store.ItemView.size.w - 20, Store.ItemView.size.h - 10 - (itemPreviewAdvanced.shift.y + itemPreviewAdvanced.size.h) },
		shapeType = ROUNDED,
		rounded = 3
	})
	local itemDesc = itemInfo:addChild({
		size = { itemInfo.size.w, item.on_sale and itemInfo.size.h / 5 or itemInfo.size.h / 3 }
	})
	if (item.qi <= TB_MENU_PLAYER_INFO.data.qi) then
		itemDesc.size.h = itemDesc.size.h + itemInfo.size.h / 8
	end
	local desc = item.description
	if (Store.Discounts.Prime == true) then
		if (item.catid == StoreCategory.Toricredits or item.catid == StoreCategory.ShiaiTokens) then
			local value = string.gsub(item.itemname, "^(%d+)%D.*$", "%1")
			local bonus = math.ceil((tonumber(value) or 0) / 100 * Store.Discounts.PrimeBonus)
			if (bonus > 0) then
				local bonusInfo = TB_MENU_LOCALIZED.STOREPRIMEBONUSINFO .. " " .. numberFormat(bonus) .. " " .. (item.catid == StoreCategory.Toricredits and TB_MENU_LOCALIZED.WORDTORICREDITS or TB_MENU_LOCALIZED.WORDSHIAITOKENS) .. " " .. TB_MENU_LOCALIZED.STOREPRIMEBONUSINFO2
				bonusInfo = bonusInfo:gsub(" ", " ^16")
				desc = desc .. "\n\n^16" .. bonusInfo
			end
		end
	end
	itemDesc:addAdaptedText(true, desc, nil, nil, 4, CENTERMID, nil, 0.6)

	if (item.on_sale) then
		local discountInfo = itemInfo:addChild({
			pos = { 10, itemDesc.size.h },
			size = { itemInfo.size.w - 20, itemInfo.size.h / 6 },
			uiColor = TB_MENU_DEFAULT_ORANGE
		})
		local percentageTC, percentageST = item.now_tc_price == 0 and 0 or 1 - item.now_tc_price / item.price, item.now_usd_price == 0 and 0 or 1 - item.now_usd_price / item.price_usd
		local percentage = percentageTC > percentageST and math.floor(percentageTC * 100) or math.floor(percentageST * 100)
		if (percentage > 0) then
			discountInfo:addAdaptedText(true, TB_MENU_LOCALIZED.STOREDISCOUNTCHEAPER1 .. " " .. percentage .. "%" .. (TB_MENU_LOCALIZED.STOREDISCOUNTCHEAPER2:len() > 0 and (" " .. TB_MENU_LOCALIZED.STOREDISCOUNTCHEAPER2) or "") .. "!", nil, nil, FONTS.BIG)
		else
			saleBackground:kill()
			discountInfo:kill()
		end
	end

	if (TB_MENU_PLAYER_INFO.username == '') then
		return
	end

	local buttonH = math.min(itemInfo.size.h / 7, 55)
	local iconScale = math.min(buttonH, 32)
	local buttonPos = -buttonH * 1.1
	if (item.qi > TB_MENU_PLAYER_INFO.data.qi) then
		local getMoreQi = itemInfo:addChild({
			pos = { 0, buttonPos },
			size = { itemInfo.size.w, buttonH },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		local getMoreQiText = getMoreQi:addChild({
			pos = { 10, 0 },
			size = { getMoreQi.size.w - 20 - getMoreQi.size.h, getMoreQi.size.h }
		})
		local getMoreQiIcon = getMoreQi:addChild({
			pos = { -getMoreQi.size.h + (getMoreQi.size.h - iconScale) / 2 - 5, (getMoreQi.size.h - iconScale) / 2 },
			size = { iconScale, iconScale },
			bgImage = "../textures/store/qi_tiny.tga"
		})
		getMoreQiText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " Qi", nil, nil, nil, LEFTMID)
		getMoreQi:addMouseUpHandler(function()
			Store:showStoreSection(TBMenu.CurrentSection, 4, 3)
		end)
		buttonPos = buttonPos - buttonH * 1.2
	end
	if (item.now_usd_price > 0) then
		local buyWithSt = itemInfo:addChild({
			pos = { 0, buttonPos },
			size = { itemInfo.size.w, buttonH },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
		}, true)
		buttonPos = buttonPos - buttonH * 1.2
		local buyWithStText = buyWithSt:addChild({
			pos = { 10, 0 },
			size = { buyWithSt.size.w - 20 - buyWithSt.size.h, buyWithSt.size.h }
		})
		if (not in_array(item.catid, StoreInternal.Categories.Account)) then
			local buyWithStIcon = buyWithSt:addChild({
				pos = { -buyWithSt.size.h + (buyWithSt.size.h - iconScale) / 2 - 5, (buyWithSt.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/store/shiaitoken.tga"
			})
			if (item.now_usd_price > TB_MENU_PLAYER_INFO.data.st) then
				buyWithStText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " ST", nil, nil, nil, LEFTMID)
				buyWithSt:addMouseUpHandler(function()
						Store:showStoreSection(TBMenu.CurrentSection, 4, 2)
					end)
			else
				buyWithStText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYFOR .. " " .. numberFormat(item.now_usd_price) .. " ST", nil, nil, nil, LEFTMID)
				buyWithSt:addMouseUpHandler(function()
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. numberFormat(item.now_usd_price) .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 ..  " " .. numberFormat(TB_MENU_PLAYER_INFO.data.st - item.now_usd_price) .. " ST " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
								Store:buyItem(item, MODE_ST)
							end)
					end)
			end
		else
			local purchaseIconImage = "../textures/menu/logos/paypal.tga"
			local displayPrice = "$" .. numberFormat(item.now_usd_price, 2)
			if (is_steam()) then
				purchaseIconImage = "../textures/menu/logos/steam.tga"
			elseif (_G.PLATFORM == "IPHONEOS") then
				buyWithSt.bgColor = table.clone(UICOLORBLACK)
				buyWithSt.uiColor = table.clone(UICOLORWHITE)
				purchaseIconImage = "../textures/menu/logos/apple.tga"
				displayPrice = utf8.gsub(get_platform_item_price(item.itemid), "%s", " ")
			elseif (_G.PLATFORM == "ANDROID") then
				buyWithSt.bgColor = { 0.004, 0.527, 0.371, 1 }
				buyWithSt.uiColor = table.clone(UICOLORWHITE)
				purchaseIconImage = "../textures/menu/logos/googleplay.tga"
				displayPrice = utf8.gsub(get_platform_item_price(item.itemid), "%s", " ")
			end
			local buyWithUSDIcon = buyWithSt:addChild({
				pos = { -buyWithSt.size.h + (buyWithSt.size.h - iconScale) / 2 - 5, (buyWithSt.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = purchaseIconImage
			})
			if (displayPrice ~= "") then
				buyWithStText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYFOR .. " " .. displayPrice, nil, nil, nil, LEFTMID)
				buyWithSt:addMouseUpHandler(function()
						Store.InitUSDPurchase(item)
					end)
			else
				buyWithStText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREITEMUNAVAILABLE, nil, nil, nil, LEFTMID)
				buyWithSt:deactivate()
			end

			if (Store.Discounts.Prime == false) then
				local primePurchaseButton = itemInfo:addChild({
					pos = { 0, buttonPos },
					size = { itemInfo.size.w, buttonH },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_ORANGE,
					hoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
					uiColor = UICOLORBLACK
				}, true)
				buttonPos = buttonPos - buttonH * 1.2
				local primePurchaseButtonText = primePurchaseButton:addChild({
					pos = { 10, 0 },
					size = { buyWithSt.size.w - 20, buyWithSt.size.h }
				})
				primePurchaseButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMOREWITHPRIME)
				primePurchaseButton:addMouseUpHandler(function()
						Store:showPrime()
					end)
			end
		end
	end
	if (item.now_tc_price > 0 and item.qi <= TB_MENU_PLAYER_INFO.data.qi) then
		local buyWithTc = itemInfo:addChild({
			pos = { 0, buttonPos },
			size = { itemInfo.size.w, buttonH },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		buttonPos = buttonPos - buttonH * 1.2
		local buyWithTcText = buyWithTc:addChild({
			pos = { 10, 0 },
			size = { buyWithTc.size.w - 20 - buyWithTc.size.h, buyWithTc.size.h }
		})
		local buyWithTcIcon = buyWithTc:addChild({
			pos = { -buyWithTc.size.h + (buyWithTc.size.h - iconScale) / 2 - 5, (buyWithTc.size.h - iconScale) / 2 },
			size = { iconScale, iconScale },
			bgImage = "../textures/store/toricredit.tga"
		})
		if (item.now_tc_price > TB_MENU_PLAYER_INFO.data.tc) then
			buyWithTcText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " TC", nil, nil, nil, LEFTMID)
			buyWithTc:addMouseUpHandler(function()
				Store:showStoreSection(TBMenu.CurrentSection, 4, 1)
			end)
		else
			buyWithTcText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYFOR .. " " .. numberFormat(item.now_tc_price) .. " TC", nil, nil, nil, LEFTMID)
			buyWithTc:addMouseUpHandler(function()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. numberFormat(item.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. numberFormat(TB_MENU_PLAYER_INFO.data.tc - item.now_tc_price) .. " TC " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
						Store:buyItem(item, MODE_TC)
					end)
			end)
		end
	end

	if (not is_mobile() and in_array(item.catid, { 1, 2, 5, 11, 11, 20, 21, 22, 24, 27, 28, 29, 30, 34, 41, 43, 44, 72, 73, 78, 80 })) then
		local itemPreview = itemInfo:addChild({
			pos = { 0, buttonPos },
			size = { itemInfo.size.w, buttonH },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		buttonPos = buttonPos - buttonH * 1.2
		itemPreview:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMPREVIEW)
		itemPreview:addMouseUpHandler(function()
				if (get_world_state().game_type == 1) then
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREVANILLAENTERMP, function() Store:itemPreviewVanilla(item) end)
					return
				end
				Store:itemPreviewVanilla(item)
			end)
	end

	if (item.qi > TB_MENU_PLAYER_INFO.data.qi) then
		local qiReq = itemInfo:addChild({
			pos = { -itemInfo.size.w - 10, buttonPos },
			size = { itemInfo.size.w + 20, buttonH },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local qiReqText = qiReq:addChild({
			pos = { 10, qiReq.size.h / 10 },
			size = { qiReq.size.w - 20, qiReq.size.h * 0.8 }
		})
		qiReqText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREREQUIRES .. " " .. (item.qi - TB_MENU_PLAYER_INFO.data.qi) .. " " .. TB_MENU_LOCALIZED.STOREREQUIRESQI, nil, nil, 4, nil, 0.8)
	end
end

---Adds a missing store icon to the download queue
---@param item StoreItem
---@param path string
---@param element UIElement
---@overload fun(self: Store, itemid: integer, path: string, element: UIElement)
function Store:addIconToDownloadQueue(item, path, element)
	---Don't do anything if they have autoupdate off
	if (get_option("autoupdate") == 0 or item == nil) then return end
	local itemid = type(item) == "number" and item or item.itemid

	table.insert(Store.IconDownloadQueue, { path = path, itemid = itemid, element = element })
	add_hook("downloader_complete", self.HookName, function(load)
			local fileName = load:gsub("^.* ", '')
			for i, v in pairs(Store.IconDownloadQueue) do
				if (fileName:find(".*/store/items/" .. v.itemid .. "%.tga$")) then
					---These reference *will* be invalid after we remove data from table
					---Make sure we cache both the itemid and UIElement we're going to modify
					local itemid = Store.IconDownloadQueue[i].itemid
					local element = Store.IconDownloadQueue[i].element
					Downloader.SafeCall(function()
						if (element ~= nil and not element.destroyed) then
							element:updateImage(Store:getItemIcon(itemid))
						end
					end)
					table.remove(Store.IconDownloadQueue, i)
					if (#Store.IconDownloadQueue == 0) then
						remove_hook("downloader_complete", self.HookName)
					end
					return
				end
			end
		end)
	Request:queue(function()
			download_server_file("get_icon&itemid=" .. itemid, 0)
		end, "store_icon_downloader_prepare", function()
			local response = get_network_response()
			if (response:len() == 0 or response:find("^ERROR")) then
				table.remove(Store.IconDownloadQueue)
				if (#Store.IconDownloadQueue == 0) then
					remove_hooks("store_icon_downloader")
				end
			end
		end, function()
			table.remove(Store.IconDownloadQueue)
			if (#Store.IconDownloadQueue == 0) then
				remove_hooks("store_icon_downloader")
			end
		end)
end

---Displays a store item in a section view list
---@param listingHolder UIElement
---@param listElements UIElement[]
---@param elementHeight number
---@param item StoreItem
---@param stItem boolean?
---@param locked boolean?
---@return boolean
function Store:showStoreListItem(listingHolder, listElements, elementHeight, item, stItem, locked)
	local itemHolder = listingHolder:addChild({
		pos = { 0, #listElements * elementHeight },
		size = { listingHolder.size.w, elementHeight }
	})
	table.insert(listElements, itemHolder)
	local itemSection = itemHolder:addChild({
		pos = { 10, 2 },
		size = { itemHolder.size.w - 10, itemHolder.size.h - 4 },
		interactive = true,
		clickThrough = true,
		hoverThrough = true,
		bgColor = item.on_sale and TB_MENU_DEFAULT_ORANGE or TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = item.on_sale and TB_MENU_DEFAULT_DARKER_ORANGE or TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		uiColor = item.on_sale and TB_MENU_DEFAULT_DARKEST_COLOR or itemHolder.uiColor
	})
	local itemIconPath = Store:getItemIcon(item.itemid)
	local itemIconFilePath = itemIconPath:gsub("^%.%./", "../data/")
	local hasIcon = Files.Exists(itemIconFilePath)

	local itemIcon = itemSection:addChild({
		pos = { 10, (itemSection.size.h - 50) / 2 },
		size = { 50, 50 },
		bgImage = itemIconPath
	})
	if (not hasIcon) then
		Store:addIconToDownloadQueue(item, itemIconPath, itemIcon)
	end
	local iconOverlay = nil
	if (locked) then
		iconOverlay = itemIcon:addChild({ bgColor = itemSection.animateColor })
		iconOverlay:addCustomDisplay(true, function()
				set_color(iconOverlay.bgColor[1], iconOverlay.bgColor[2], iconOverlay.bgColor[3], 0.6)
				draw_quad(iconOverlay.pos.x, iconOverlay.pos.y, iconOverlay.size.w, iconOverlay.size.h)
			end)
	end
	itemSection:addMouseHandlers(function()
			if (iconOverlay) then
				iconOverlay.bgColor = table.clone(itemSection.pressedColor)
			end
		end, function()
			Store:showStoreItemInfo(item)
			---@diagnostic disable-next-line: undefined-field
			listingHolder.scrollBar.toReload:reload()
			if (iconOverlay) then
				iconOverlay.bgColor = itemSection.animateColor
			end
		end)
	local itemName = nil
	if (locked) then
		itemName = itemSection:addChild({
			pos = { 70, 5 },
			size = { (itemSection.size.w - 80) / 3 * 2, itemSection.size.h - 25 }
		})
		local itemLocked = itemSection:addChild({
			pos = { 70, itemSection.size.h - 22 },
			size = { itemName.size.w, 15 }
		})
		local itemLockedIcon = itemSection:addChild({
			size = { 32, 32 },
			bgImage = "../textures/menu/general/buttons/locked.tga"
		})

		if (item.qi > TB_MENU_PLAYER_INFO.data.qi and not item.locked) then
			itemLocked:addAdaptedText(true, TB_MENU_LOCALIZED.STOREREQUIRES .. " " .. item.qi .. " Qi", nil, nil, 4, LEFTMID)
		else
			itemLocked:addAdaptedText(true, TB_MENU_LOCALIZED.STOREITEMUNAVAILABLE, nil, nil, 4, LEFTMID)
		end
	else
		itemName = itemSection:addChild({
			pos = { 70, 10 },
			size = { (itemSection.size.w - 80) / 3 * 2, itemSection.size.h - 20 }
		})
	end
	itemName:addAdaptedText(true, item.shortname, nil, nil, FONTS.BIG, LEFTMID, 0.55, nil, 0.4)
	local itemPrice = itemSection:addChild({
		pos = { itemName.shift.x + itemName.size.w, 0 },
		size = { itemSection.size.w - (itemName.shift.x + itemName.size.w) - 10, itemSection.size.h }
	})
	local pricesString, hasTCPrice = '', false
	if (item.now_tc_price > 0) then
		pricesString = numberFormat(item.now_tc_price) .. " TC"
		hasTCPrice = true
	end
	if (item.now_usd_price > 0) then
		if (hasTCPrice) then
			pricesString = pricesString .. "\n"
		end
		if (not stItem) then
			if (_G.PLATFORM == "IPHONEOS" or _G.PLATFORM == "ANDROID") then
				pricesString = utf8.gsub(get_platform_item_price(item.itemid), "%s", " ")
				if (string.len(pricesString) == 0) then
					---Price length is 0, this means the item is not available on this platform (or in current location)
					---Don't show it in the list, just exit
					itemHolder:kill()
					table.remove(listElements)
					return false
				end
			else
				pricesString = "$" .. numberFormat(item.now_usd_price, 2)
			end
		else
			pricesString = pricesString .. numberFormat(item.now_usd_price) .. " ST"
		end
	end
	itemPrice:addAdaptedText(true, pricesString, nil, nil, nil, RIGHTMID)
	return true
end

---Displays section items for the vanilla previewer
---@param viewElement UIElement
---@param height integer
---@param catid integer
---@return UIElement[]
function Store:showVanillaSectionItems(viewElement, height, catid)
	local sectionItems = { }
	for _, v in pairs(Store.Items) do
		if (v.catid == catid and (v.now_tc_price > 0 or v.now_usd_price > 0) and not v.hidden) then
			table.insert(sectionItems, v)
		end
	end
	sectionItems = table.qsort(sectionItems, {'qi', 'now_usd_price', 'now_tc_price', 'itemname'}, SORT_ASCENDING, true)
	local listElements = {}
	for _, item in pairs(sectionItems) do
		local itemHolder = viewElement:addChild({
			pos = { 0, #listElements * height },
			size = { viewElement.size.w, height }
		})
		table.insert(listElements, itemHolder)
		local itemButton = itemHolder:addChild({
			pos = { 10, 2 },
			size = { itemHolder.size.w - 10, itemHolder.size.h - 4 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		local shiftX = 0
		if (not in_array(item.catid, { 72, 78, 80 })) then
			local rgb = get_color_info(item.colorid)
			local itemColor = itemButton:addChild({
				pos = { 13, 5 },
				size = { itemButton.size.h - 10, itemButton.size.h - 10 },
				shapeType = ROUNDED,
				rounded = 5,
				bgColor = { rgb.r, rgb.g, rgb.b, 1 }
			})
			shiftX = itemButton.size.h
		end
		local itemName = itemButton:addChild({
			pos = { 15 + shiftX, 2 },
			size = { itemButton.size.w - 70 - shiftX, itemButton.size.h - 4 }
		})
		itemButton:addMouseUpHandler(function()
				Store:doItemPreviewVanilla(item)
			end)
		itemName:addAdaptedText(true, item.itemname, nil, nil, nil, LEFTMID)
		if (item.qi > TB_MENU_PLAYER_INFO.data.qi and (item.now_usd_price > TB_MENU_PLAYER_INFO.data.st or item.now_usd_price == 0)) then
			local itemLockedIcon = itemButton:addChild({
				pos = { -itemButton.size.h - 15, 0 },
				size = { itemButton.size.h, itemButton.size.h },
				bgImage = "../textures/menu/general/buttons/locked.tga"
			})
		end
	end
	return listElements
end

---Displays store section items
---@param viewElement UIElement
---@param catid integer
---@param searchString string?
---@param itemsList StoreItem[]?
---@param itemShown boolean?
function Store:showSectionItems(viewElement, catid, searchString, itemsList, itemShown)
	viewElement:kill(true)

	if (pcall(function() searchString = utf8.lower(searchString or "") end) == false) then
		searchString = ""
	end
	itemShown = itemShown or false

	local sectionItems = { }
	if (itemsList) then
		sectionItems = itemsList
	else
		for _, item in pairs(Store.Items) do
			if (item.catid == catid and (item.now_tc_price > 0 or item.now_usd_price > 0) and not (item.locked and item.hidden)) then
				local v = item:getCopy()
				for _, k in pairs(Store.Discounts) do
					if (type(k) == "table" and k.expiryTime > UIElement.clock + 60 and (k.itemid == 0 or k.itemid == v.itemid)) then
						if ((bit.band(k.paymentType, 2) > 0 or bit.band(k.paymentType, 4) > 0) and in_array(v.catid, StoreInternal.Categories.Account)) then
							v.on_sale = true
							v.now_usd_price = math.max(v.now_usd_price / 100 * (100 - k.discount), k.discountMax > 0 and v.now_usd_price - k.discountMax / 100 or 0)
						elseif (bit.band(k.paymentType, 1) > 0) then
							v.on_sale = true
							v.now_tc_price = math.max(v.now_tc_price / 100 * (100 - k.discount), k.discountMax > 0 and v.now_tc_price - k.discountMax or 0)
						end
					end
				end
				table.insert(sectionItems, v)
			end
		end
	end

	if (#sectionItems == 0) then
		-- We are viewing an empty section, don't let the UI crash
		local nothingToShow = viewElement:addChild({
			pos = { viewElement.size.w / 10, viewElement.size.h / 5 },
			size = { viewElement.size.w * 0.8, viewElement.size.h * 0.6 }
		})
		nothingToShow:addAdaptedText(true, TB_MENU_LOCALIZED.STORENOITEMSTODISPLAY, nil, nil, FONTS.BIG, nil, 0.6)
		TBMenu:addBottomBloodSmudge(viewElement, 2)
		Store:showStoreItemInfo(nil)
		return
	end

	local sectionItemsDesc = table.qsort(sectionItems, { 'itemname', 'now_usd_price', 'now_tc_price', 'on_sale' }, { SORT_ASCENDING, SORT_DESCENDING, SORT_DESCENDING, SORT_DESCENDING }, true)
	local sectionItemsQi = table.qsort(sectionItems, { 'itemname', 'now_usd_price', 'now_tc_price', 'qi', 'on_sale' }, { SORT_ASCENDING, SORT_DESCENDING, SORT_DESCENDING, SORT_ASCENDING, SORT_DESCENDING }, true)
	sectionItems = table.qsort(sectionItems, { 'itemname', 'now_usd_price', 'now_tc_price', 'on_sale' }, { SORT_ASCENDING, SORT_ASCENDING, SORT_ASCENDING, SORT_DESCENDING }, true)

	local elementHeight = 64
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(viewElement, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	local sectionTitle = topBar:addChild({ shift = { 10, 10 } })
	sectionTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STOREVIEWING .. " " .. Store:getCategoryInfo(catid).name, nil, nil, FONTS.BIG)

	local stItems = not in_array(sectionItems[1].catid, StoreInternal.Categories.Account)
	local listElements = { }
	local cnt = 0
	for _, item in pairs(sectionItemsDesc) do
		if (((item.qi <= TB_MENU_PLAYER_INFO.data.qi and (item.now_tc_price > 0 and item.now_tc_price <= TB_MENU_PLAYER_INFO.data.tc)) or (stItems and item.now_usd_price > 0 and item.now_usd_price <= TB_MENU_PLAYER_INFO.data.st)) and (not item.locked and not item.hidden)) then
			if (cnt == 0) then
				local separatorAffordable = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, separatorAffordable)
				local separatorAffordableText = UIElement:new({
					parent = separatorAffordable,
					pos = { 10, -elementHeight / 7 * 5 - 2.5 },
					size = { separatorAffordable.size.w - 10, elementHeight / 7 * 5 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				separatorAffordableText:addAdaptedText(false, TB_MENU_LOCALIZED.STOREAVAILABLEITEMS)
			end
			local itemDisplayed = Store:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems)
			if (not itemShown and itemDisplayed) then
				itemShown = true
				Store:showStoreItemInfo(item)
			end
			cnt = cnt + 1
		end
	end

	cnt = 0
	if (stItems) then
		for _, item in pairs(sectionItems) do
			if (((item.qi <= TB_MENU_PLAYER_INFO.data.qi and item.now_tc_price > TB_MENU_PLAYER_INFO.data.tc and (item.now_usd_price == 0 or item.now_usd_price > TB_MENU_PLAYER_INFO.data.st)) or ((item.qi > TB_MENU_PLAYER_INFO.data.qi or item.now_tc_price == 0) and item.now_usd_price > TB_MENU_PLAYER_INFO.data.st)) and (not item.locked and not item.hidden)) then
				if (cnt == 0) then
					local separatorUnavailable = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					table.insert(listElements, separatorUnavailable)
					local separatorUnavailableText = UIElement:new({
						parent = separatorUnavailable,
						pos = { 10, -elementHeight / 7 * 5 - 2.5 },
						size = { separatorUnavailable.size.w - 10, elementHeight / 7 * 5 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					})
					separatorUnavailableText:addAdaptedText(false, TB_MENU_LOCALIZED.STOREEXPENSIVEITEMS)
				end
				local itemDisplayed = Store:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems)
				if (not itemShown and itemDisplayed) then
					itemShown = true
					Store:showStoreItemInfo(item)
				end
				cnt = cnt + 1
			end
		end
	else
		for _, item in pairs(sectionItems) do
			if (item.now_tc_price == 0 and item.now_usd_price > 0 and (not item.locked and not item.hidden)) then
				if (cnt == 0) then
					local separatorUnavailable = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					table.insert(listElements, separatorUnavailable)
					local separatorUnavailableText = UIElement:new({
						parent = separatorUnavailable,
						pos = { 10, -elementHeight / 7 * 5 - 2.5 },
						size = { separatorUnavailable.size.w - 10, elementHeight / 7 * 5 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					})
					separatorUnavailableText:addAdaptedText(false, TB_MENU_LOCALIZED.STOREUSDITEMS)
				end
				local itemDisplayed = Store:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems)
				if (not itemShown and itemDisplayed) then
					itemShown = true
					Store:showStoreItemInfo(item)
				end
				cnt = cnt + 1
			end
		end
	end

	cnt = 0
	for _, item in pairs(sectionItemsQi) do
		if ((item.qi > TB_MENU_PLAYER_INFO.data.qi and item.now_usd_price == 0 and item.now_tc_price > 0 and (not item.hidden and not item.locked) or (searchString ~= "" and (item.hidden or item.locked)))) then
			if (cnt == 0) then
				local separatorLocked = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, separatorLocked)
				local separatorLockedText = UIElement:new({
					parent = separatorLocked,
					pos = { 10, -elementHeight / 7 * 5 - 2.5 },
					size = { separatorLocked.size.w - 10, elementHeight / 7 * 5 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				separatorLockedText:addAdaptedText(false, TB_MENU_LOCALIZED.STORELOCKEDITEMS)
			end
			local itemDisplayed = Store:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems, true)
			if (not itemShown and itemDisplayed) then
				itemShown = true
				Store:showStoreItemInfo(item)
			end
			cnt = cnt + 1
		end
	end

	for _ ,v in pairs(listElements) do
		v:hide()
	end

	local storeListingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = storeListingScrollBar
	storeListingScrollBar:makeScrollBar(listingHolder, listElements, toReload)
	storeListingScrollBar.toReload = toReload

	TBMenu:addBottomBloodSmudge(botBar, 2)
end

---Returns category displayid for an item
---@param item StoreItem
---@return integer?
function Store:getItemMainSection(item)
	if (in_array(item.catid, StoreInternal.Categories.Colors)) then
		return StoreInternal.Tabs.Colors
	elseif (in_array(item.catid, StoreInternal.Categories.Advanced)) then
		return StoreInternal.Tabs.Advanced
	elseif (in_array(item.catid, StoreInternal.Categories.Account)) then
		return StoreInternal.Tabs.Account
	end
end

---Used for result filtering in search \
---@see Store.getSearchSections
---@param catid integer
---@return integer?
function Store:getSearchCategory(catid)
	if (in_array(catid, StoreInternal.Categories.Colors)) then
		return -1
	end
	if (in_array(catid, StoreInternal.Categories.Hidden)) then
		return nil
	end
	return catid
end

---Performs item search and returns a table with results
---@param searchString string
---@param isSale any
---@return StoreItem[][]
function Store:getSearchSections(searchString, isSale)
	searchString = utf8.safe_lower(searchString)

	---@type StoreItem[][]
	local searchResults = { }
	if (utf8.safe_len(searchString) < 3) then
		return searchResults
	end

	for _, v in pairs(Store.Items) do
		local name = utf8.safe_lower(v.itemname)
		if (string.find(name, searchString) and not string.find(name, "test") and (not isSale and true or v.on_sale)) then
			local catid = Store:getSearchCategory(v.catid)
			if (catid ~= nil) then
				if (searchResults[catid] == nil) then
					searchResults[catid] = { }
				end
				table.insert(searchResults[catid], v)
			end
		end
	end
	return searchResults
end

---Displays search results
---@param viewElement UIElement
---@param searchResults StoreItem[][]
---@param searchString string
function Store:showSearchResults(viewElement, searchResults, searchString)
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar(Store:getNavigation(viewElement), true)
	Store:showSearchBar(viewElement, searchString)

	if (table.empty(searchResults)) then
		local emptyMessage = viewElement:addChild({
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		emptyMessage:addAdaptedText(false, utf8.len(searchString) >= 3 and TB_MENU_LOCALIZED.STORESEARCHNOITEMS or TB_MENU_LOCALIZED.STORESEARCHSTRINGSHORT, nil, nil, FONTS.BIG)
		TBMenu:addBottomBloodSmudge(emptyMessage, 1)
		return
	end
	local sectionsHolder = viewElement:addChild({
		pos = { 5, 0 },
		size = { viewElement.size.w / 4 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local elementHeight = math.clamp(WIN_H / 18, 45, 55)
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(sectionsHolder, 64, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	local searchTitle = topBar:addChild({ shift = { 10, 10 } })
	searchTitle:addAdaptedText(true, TB_MENU_LOCALIZED.SEARCHRESULTS1 .. "'" .. searchString .. "' " .. TB_MENU_LOCALIZED.SEARCHRESULTS2, nil, nil, FONTS.BIG)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	Store.ItemView = viewElement:addChild({
		pos = { -viewElement.size.w / 4 + 5, 0 },
		size = { viewElement.size.w / 4 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local sectionItemsView = viewElement:addChild({
		pos = { sectionsHolder.shift.x + sectionsHolder.size.w + 10, 0 },
		size = { viewElement.size.w / 2 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local listElements = { }
	local first = true
	for i, v in pairs(searchResults) do
		if (first) then
			Store:showSectionItems(sectionItemsView, i, searchString, v)
			first = false
		end
		local section = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		table.insert(listElements, section)
		section:addAdaptedText(false, Store:getCategoryInfo(i).name)
		section:addMouseUpHandler(function()
				Store:showSectionItems(sectionItemsView, i, searchString, v)
			end)
	end
	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

function Store:showPrime()
	local primeItemInfo = Store:getItemInfo(4342)
	if (primeItemInfo.itemid == 0) then return end

	Store:showStoreSection(TBMenu.CurrentSection, 4)
	local overlay = TBMenu:spawnWindowOverlay(true)
	local windowSize = { math.min(WIN_W * 0.8, 900), math.min(WIN_H * 0.7, 420) }
	local viewHolder = overlay:addChild({
		pos = { (WIN_W - windowSize[1]) / 2, (WIN_H - windowSize[2]) / 2 },
		size = windowSize,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local windowTitle = viewHolder:addChild({
		pos = { 55, 0 },
		size = { viewHolder.size.w - 110, 55 }
	})
	windowTitle:addAdaptedText(primeItemInfo.itemname, nil, nil, FONTS.BIG, CENTERMID, 0.7, nil, 0.5)
	TBMenu:spawnCloseButton(viewHolder, { x = -50, y = 5, w = 45, h = 45 }, overlay.btnUp)

	local primeIconSize = viewHolder.size.h - windowTitle.size.h - 50
	local primeIconHolder = viewHolder:addChild({
		pos = { 30, windowTitle.size.h + 20 },
		size = { primeIconSize, primeIconSize }
	})
	primeIconHolder:addChild({
		pos = { (primeIconSize - 256) / 2, (primeIconSize - 256) / 2 },
		size = { 256, 256 },
		bgImage = primeItemInfo:getIconPath()
	})
	local primeDescription = viewHolder:addChild({
		pos = { primeIconHolder.size.w + primeIconHolder.shift.x * 2, primeIconHolder.shift.y },
		size = { viewHolder.size.w - primeIconHolder.size.w - primeIconHolder.shift.x * 3, primeIconHolder.size.h - 70 }
	})
	local description = string.gsub(primeItemInfo.description, ":\\n", ":\n\n")
	primeDescription:addAdaptedText(description, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.9)
	local primePurchaseButton = viewHolder:addChild({
		pos = { primeDescription.shift.x, primeDescription.shift.y + primeDescription.size.h + 10 },
		size = { primeDescription.size.w, primeIconHolder.size.h - primeDescription.size.h - 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
	}, true)
	primePurchaseButton:addMouseUpHandler(function()
			Store.InitUSDPurchase(primeItemInfo, function()
				if (overlay ~= nil and not overlay.destroyed) then
					overlay:kill()
				end
			end)
		end)

	local iconScale = primePurchaseButton.size.h * 0.7
	local purchaseIconImage = "../textures/menu/logos/paypal.tga"
	local displayPrice = "$" .. numberFormat(primeItemInfo.now_usd_price, 2)
	if (is_steam()) then
		purchaseIconImage = "../textures/menu/logos/steam.tga"
	elseif (_G.PLATFORM == "IPHONEOS") then
		primePurchaseButton.bgColor = table.clone(UICOLORBLACK)
		primePurchaseButton.uiColor = table.clone(UICOLORWHITE)
		purchaseIconImage = "../textures/menu/logos/apple.tga"
		displayPrice = utf8.gsub(get_platform_item_price(primeItemInfo.itemid), "%s", " ")
	elseif (_G.PLATFORM == "ANDROID") then
		primePurchaseButton.bgColor = { 0.004, 0.527, 0.371, 1 }
		primePurchaseButton.uiColor = table.clone(UICOLORWHITE)
		purchaseIconImage = "../textures/menu/logos/googleplay.tga"
		displayPrice = utf8.gsub(get_platform_item_price(primeItemInfo.itemid), "%s", " ")
	end
	if (displayPrice ~= "") then
		primePurchaseButton:addChild({
			pos = { -primePurchaseButton.size.h + (primePurchaseButton.size.h - iconScale) / 2 - 5, (primePurchaseButton.size.h - iconScale) / 2 },
			size = { iconScale, iconScale },
			bgImage = purchaseIconImage
		})
		primePurchaseButton:addAdaptedText(TB_MENU_LOCALIZED.STOREBUYFOR .. " " .. displayPrice, nil, nil, FONTS.BIG, nil, 0.6)
	else
		primePurchaseButton:addAdaptedText(TB_MENU_LOCALIZED.STOREITEMUNAVAILABLE, nil, nil, FONTS.BIG, nil, 0.6)
		primePurchaseButton:deactivate()
	end
end

---Displays store item section
---@param viewElement UIElement
---@param section integer?
---@param sectionid integer?
---@param itemid integer?
function Store:showStoreSection(viewElement, section, sectionid, itemid)
	usage_event("storesection")
	local itemInfo = itemid and Store:getItemInfo(itemid)
	section = section or (itemInfo and Store:getItemMainSection(itemInfo)) or 1
	local sectionInfo = Store.GetStoreSection(section)
	sectionid = sectionid or 1
	if (itemInfo) then
		for i, v in pairs(sectionInfo.list) do
			if (itemInfo.catid == v) then
				sectionid = i
				break
			end
		end
	end

	Store.LastSection = section
	Store.LastSectionId = sectionid
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar(Store:getNavigation(viewElement), true, true, Store.LastSection)

	local sectionsHolder = viewElement:addChild({
		pos = { 5, 0 },
		size = { viewElement.size.w / 4 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local elementHeight = math.clamp(WIN_H / 18, 45, 55)
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(sectionsHolder, 64, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	local sectionTitle = topBar:addChild({ shift = { 10, 10 } })
	sectionTitle:addAdaptedText(true, sectionInfo.name, nil, nil, FONTS.BIG)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	Store.ItemView = viewElement:addChild({
		pos = { -viewElement.size.w / 4 + 5, 0 },
		size = { viewElement.size.w / 4 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local sectionItemsView = viewElement:addChild({
		pos = { sectionsHolder.shift.x + sectionsHolder.size.w + 10, 0 },
		size = { viewElement.size.w / 2 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	Store:showSectionItems(sectionItemsView, sectionInfo.list[sectionid], nil, nil, itemid and true or false)
	if (itemid) then
		Store:showStoreItemInfo(itemInfo)
	end

	if (not sectionInfo) then
		Store:showSearchBar(viewElement)
		return
	end

	local listElements = {}
	local selectedSection = nil
	for i, v in pairs(sectionInfo.list) do
		local section = listingHolder:addChild({
			pos = { 5, #listElements * elementHeight },
			size = { listingHolder.size.w - 5, elementHeight },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		table.insert(listElements, section)
		local sectionText = section:addChild({ shift = { 10, 2 } })
		sectionText:addAdaptedText(true, Store:getCategoryInfo(v).name, nil, nil, nil, LEFTMID)
		section:addMouseUpHandler(function()
				selectedSection.bgColor = TB_MENU_DEFAULT_BG_COLOR
				selectedSection = section
				section.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				Store:showSectionItems(sectionItemsView, v)
				Store.LastSectionId = i
			end)
	end
	selectedSection = listElements[sectionid]
	selectedSection.bgColor = TB_MENU_DEFAULT_DARKER_COLOR

	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)

	Store:showSearchBar(viewElement)
end

---Displays search bar
---@param viewElement UIElement
---@param searchString string?
function Store:showSearchBar(viewElement, searchString)
	if (not TBMenu.BottomLeftBar) then
		TBMenu:showBottomBar()
	end
	local searchInput = TBMenu:spawnSearchBar(searchString or "", TB_MENU_LOCALIZED.STORESEARCHHINT)
	searchInput:addEnterAction(function(inputText)
			if (string.gsub(inputText, "%s", "") == '') then
				Store:showStoreSection(viewElement, Store.LastSection)
			else
				Store:showSearchResults(viewElement, Store:getSearchSections(inputText), inputText)
			end
		end)
end

function Store:showInventorySearchBar(searchString, inventoryItems, mode, title, itemScale, showBack)
	if (not TBMenu.BottomLeftBar) then
		TBMenu:showBottomBar()
	end
	local searchInput = TBMenu:spawnSearchBar(searchString or "", TB_MENU_LOCALIZED.STORESEARCHHINT)
	searchInput:addEnterAction(function(inputText)
		local doSearch = string.len(inputText) > 0
		Store.InventoryListShift[1] = 0
		Store:showInventoryPage(inventoryItems, doSearch and 1 or nil, mode, title, "page" .. (doSearch and inputText or tostring(mode)), itemScale, showBack, doSearch and inputText or nil)
	end)
end

---Displays active personal user discount for the item
---@param item StoreDiscount
function Store:showPersonalDiscount(item)
	local itemInfo = Store:getItemInfo(item.itemid)
	local discountView = TBMenu.CurrentSection:addChild({
		pos = { TBMenu.BottomLeftBar.shift.x + TBMenu.BottomLeftBar.size.w, TBMenu.CurrentSection.size.h + (WIN_H - TBMenu.CurrentSection.size.h - TBMenu.CurrentSection.pos.y) - TBMenu.BottomLeftBar.size.h * 1.5 },
		size = { TBMenu.CurrentSection.size.w - (TBMenu.BottomLeftBar.shift.x + TBMenu.BottomLeftBar.size.w) * 2, math.ceil(TBMenu.BottomLeftBar.size.h * 1.25) },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	if (not is_mobile()) then
		TBMenu.HideButton:hide()
		discountView.killAction = function() TBMenu.HideButton:show() end
	end

	local sideWidth = math.min(discountView.size.w / 3, math.max(discountView.size.w / 4 - 15, 150))
	local discountTitle = discountView:addChild({
		pos = { 10, 5 },
		size = { sideWidth, discountView.size.h - 10 }
	})
	discountTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STORELIMITEDOFFER)
	local endsIn = discountView:addChild({
		pos = { -sideWidth - 10, discountTitle.shift.y },
		size = { sideWidth, discountTitle.size.h }
	})
	endsIn:addAdaptedText(true, TBMenu:getTime(item.expiryTime - UIElement.clock, 1) .. " " .. TB_MENU_LOCALIZED.TIMELEFT)
	endsIn:addCustomDisplay(true, function()
			endsIn:uiText(TBMenu:getTime(item.expiryTime - UIElement.clock, 1) .. " " .. TB_MENU_LOCALIZED.TIMELEFT, nil, nil, endsIn.textFont, nil, endsIn.textScale)
		end)
	local itemInfoBG = discountView:addChild({
		shift = { 15 + sideWidth, 5 },
		bgColor = TB_MENU_DEFAULT_ORANGE,
		shapeType = ROUNDED,
		rounded = 10
	})
	local itemInfoHolder = itemInfoBG:addChild({
		shift = { 15, 5 },
		uiColor = UICOLORBLACK
	})
	local itemInfoIcon = itemInfoHolder:addChild({
		pos = { 0, 0 },
		size = { itemInfoHolder.size.h, itemInfoHolder.size.h },
		bgImage = item.itemid > 0 and itemInfo:getIconPath() or Store:getItemIcon(1538) -- 5000 TC itemid
	})
	local itemInfoName = itemInfoHolder:addChild({
		pos = { itemInfoIcon.size.w + 10, 5 },
		size = { (itemInfoHolder.size.w - itemInfoIcon.size.w - 20) / 2, itemInfoHolder.size.h - 10 }
	})
	local itemInfoPrice = itemInfoHolder:addChild({
		pos = { -itemInfoName.size.w - 5, 5 },
		size = { itemInfoName.size.w - 5, itemInfoName.size.h }
	})
	if (item.itemid > 0) then
		itemInfo.on_sale = true
		itemInfoName:addAdaptedText(true, itemInfo.itemname, nil, nil, nil, LEFTMID)
		if (bit.band(item.paymentType, 2) > 0 or bit.band(item.paymentType, 4) > 0) then
			itemInfo.now_usd_price = math.max(itemInfo.now_usd_price / 100 * (100 - item.discount), item.discountMax > 0 and itemInfo.now_usd_price - item.discountMax / 100 or 0)
			itemInfoPrice:addAdaptedText(true, "$" .. numberFormat(itemInfo.now_usd_price, 2), nil, nil, nil, RIGHTMID)
		else
			itemInfo.now_tc_price = math.max(itemInfo.now_tc_price / 100 * (100 - item.discount), itemInfo.now_tc_price - item.discountMax)
			itemInfoPrice:addAdaptedText(true, numberFormat(itemInfo.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, nil, RIGHTMID)
		end
		discountView:addMouseUpHandler(function()
				Store:showStoreSection(TBMenu.CurrentSection, nil, nil, itemInfo.itemid)
				Store:showStoreItemInfo(itemInfo)
			end)
	else
		if (bit.band(item.paymentType, 4) > 0) then -- Allows steam purchases
			itemInfoName:addAdaptedText(true, TB_MENU_LOCALIZED.STORENEXTUSDPURCHASE, nil, nil, nil, LEFTMID)
			discountView:addMouseUpHandler(function()
					Store:showStoreSection(TBMenu.CurrentSection, nil, nil, 1538)
				end)
		elseif (bit.band(item.paymentType, 2) > 0 and not is_steam()) then -- No steam but allows PayPal purchases
			itemInfoName:addAdaptedText(true, TB_MENU_LOCALIZED.STORENEXTPAYPALPURCHASE, nil, nil, nil, LEFTMID)
			discountView:addMouseUpHandler(function()
					Store:showStoreSection(TBMenu.CurrentSection, nil, nil, 1538)
				end)
		elseif (bit.band(item.paymentType, 1) > 0) then
			itemInfoName:addAdaptedText(true, TB_MENU_LOCALIZED.STORENEXTITEMPURCHASE, nil, nil, nil, LEFTMID)
			discountView:addMouseUpHandler(function()
					Store:showStoreSection(TBMenu.CurrentSection, 1)
				end)
		else
			-- This can be either a paypal only discount shown to a steam user or a newly added payment type
			-- Don't want to show an offer in this case, so destroy the discount view and exit
			discountView:kill()
			return
		end
		itemInfoPrice:addAdaptedText(true, item.discount .. "% " .. TB_MENU_LOCALIZED.STOREDISCOUNTOFF .. "!", nil, nil, nil, RIGHTMID)
	end
end

---Displays main Store view
---@param viewElement UIElement
function Store:showMain(viewElement)
	viewElement:kill(true)
	if (not Store.Ready) then
		local shopLoading = viewElement:addChild({
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(shopLoading, 1)
		local shopLoadingText = shopLoading:addChild({
			pos = { shopLoading.size.w / 6, shopLoading.size.h / 3 },
			size = { shopLoading.size.w / 3 * 2, shopLoading.size.h / 3 }
		})
		TBMenu:displayLoadingMark(shopLoadingText, TB_MENU_LOCALIZED.STORELOADING)
		shopLoading:addCustomDisplay(false, function()
				if (Store.Ready) then
					Store:showMain(viewElement)
				end
			end)
		return
	end

	usage_event("store")
	local saleItems = Store:getSaleItems()
	local saleFeatured, saleColor = nil, {}
	for _, v in pairs(saleItems) do
		if (v.sale_promotion) then
			saleFeatured = v
		elseif (in_array(v.catid, StoreInternal.Categories.Colors)) then
			table.insert(saleColor, v)
		end
	end
	saleColor = table.qsort(saleColor, 'catid') --Do this to prevent incorrect name detection when first item is a pack
	local saleColorInfo = #saleColor > 0 and { colorid = saleColor[1].colorid, colorname = saleColor[1].itemname:gsub(" " .. Store:getCategoryInfo(saleColor[1].catid).name:sub(1, -8) .. ".*$", "") } or false

	local storeButtons = {
		featured = {
			title = TB_MENU_LOCALIZED.STOREGOTOINVENTORY,
			subtitle = TB_MENU_LOCALIZED.STOREINVENTORYDESC,
			image = "../textures/menu/inventory.tga",
			ratio = 0.435,
			disableUnload = true,
			action = function()
					if (Store.Ready) then
						Store:prepareInventory(TBMenu.CurrentSection)
					else
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREDATALOADERROR)
					end
				end
		},
		salecolor = {
			title = saleColorInfo and (TB_MENU_LOCALIZED.STORESALE1 .. " " .. saleColorInfo.colorname .. (TB_MENU_LOCALIZED.STORESALE2:len() > 0 and (" " .. TB_MENU_LOCALIZED.STORESALE2 .. "!") or "!")) or TB_MENU_LOCALIZED.STORENOCOLORSALE,
			image = "../textures/menu/store/colorsale.tga",
			ratio = 0.5,
			disableUnload = true,
			action = function() if (saleColorInfo) then Store:showSearchResults(viewElement, Store:getSearchSections(saleColorInfo.colorname, true), saleColorInfo.colorname) end end
		},
		dailysale = {
			title = saleFeatured and saleFeatured.itemname or TB_MENU_LOCALIZED.STORENOSALE,
			image = "../textures/menu/store/sale.tga",
			ratio = 0.5,
			disableUnload = true,
			action = function() if (saleFeatured) then Store:showStoreSection(TBMenu.CurrentSection, nil, nil, saleFeatured.itemid) end end
		},
		storecolors = {
			title = TB_MENU_LOCALIZED.STORECOLORS,
			subtitle = TB_MENU_LOCALIZED.STORECOLORSDESC,
			image = "../textures/menu/store/colors-big.tga",
			image2 = "../textures/menu/store/colors-small.tga",
			ratio = 0.75,
			ratio2 = 0.449,
			disableUnload = true,
			action = function() Store:showStoreSection(viewElement, 1) end
		},
		storeadvanced = {
			title = TB_MENU_LOCALIZED.STOREADVANCED,
			subtitle = TB_MENU_LOCALIZED.STOREADVANCEDDESC,
			image = "../textures/menu/store/advanced2-big.tga",
			image2 = "../textures/menu/store/advanced2-small.tga",
			ratio = 0.75,
			ratio2 = 0.449,
			disableUnload = true,
			action = function() Store:showStoreSection(viewElement, 3) end
		},
		storetextures = {
			title = TB_MENU_LOCALIZED.STOREFLAMEFORGE,
			subtitle = TB_MENU_LOCALIZED.STOREFLAMEFORGEDESC,
			image = "../textures/menu/store/flameforge-big.tga",
			image2 = "../textures/menu/store/flameforge-small.tga",
			ratio = 0.75,
			ratio2 = 0.449,
			disableUnload = true,
			action = function() close_menu() if (Flames.MainElement == nil) then dofile("system/flames.lua") end end
		},
		storeaccount = {
			title = TB_MENU_LOCALIZED.STOREACCOUNT,
			subtitle = TB_MENU_LOCALIZED.STOREACCOUNTDESC,
			image = "../textures/menu/store/account-big.tga",
			image2 = "../textures/menu/store/account-small.tga",
			ratio = 0.75,
			ratio2 = 0.449,
			disableUnload = true,
			action = function() Store:showStoreSection(viewElement, 4) end
		},
	}
	local featuredItem = viewElement:addChild({
		pos = { 5, 0 },
		size = { viewElement.size.w * 0.45 - 10, viewElement.size.h / 5 * 3 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	TBMenu:showHomeButton(featuredItem, storeButtons.featured)

	local weeklySale = viewElement:addChild({
		pos = { 5, viewElement.size.h / 5 * 3 + 5 },
		size = { viewElement.size.w * 0.225 - 10, viewElement.size.h / 5 * 2 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	if (saleColorInfo) then
		local colorRGB = get_color_info(saleColorInfo.colorid)
		local colorDiscountHolder = weeklySale:addChild({
			pos = { 0, 10 + weeklySale.size.h * 0.15 * storeButtons.salecolor.ratio },
			size = { weeklySale.size.w / 3, weeklySale.size.h * 0.4 * storeButtons.salecolor.ratio },
			bgColor = weeklySale.animateColor
		})

		-- 0, 0 for shifts in getImageDimensions is unreliable, ideally need to put actual height values
		local w, h = unpack(TBMenu:getImageDimensions(weeklySale.size.w, weeklySale.size.h, storeButtons.salecolor.ratio, 0, 0))
		weeklySale:addChild({
			pos = { (weeklySale.size.w - w) / 2, 10 },
			size = { w, h },
			bgColor = { colorRGB.r, colorRGB.g, colorRGB.b, 1 }
		})

		TBMenu:showHomeButton(weeklySale, storeButtons.salecolor, 1, { colorDiscountHolder })
		colorDiscountHolder:reload()
		local saleDiscount = colorDiscountHolder:addChild({
			pos = { 5, 0 },
			size = { colorDiscountHolder.size.w - 10, colorDiscountHolder.size.h }
		})
		local percentageTC, percentageST = saleColor[1].now_tc_price == 0 and 0 or 1 - saleColor[1].now_tc_price / saleColor[1].price, saleColor[1].now_usd_price == 0 and 0 or 1 - saleColor[1].now_usd_price / saleColor[1].price_usd
		local percentage = percentageTC > percentageST and math.floor(percentageTC * 100) or math.floor(percentageST * 100)
		saleDiscount:addAdaptedText(true, "-" .. percentage .. "%")
	else
		local w, h = unpack(TBMenu:getImageDimensions(weeklySale.size.w, weeklySale.size.h, storeButtons.salecolor.ratio, 0, 0))
		weeklySale:addChild({
			pos = { (weeklySale.size.w - w) / 2, 10 },
			size = { w, h },
			bgColor = { 1, 1, 1, 1 }
		})
		TBMenu:showHomeButton(weeklySale, storeButtons.salecolor, 1)
	end

	local dailySale = viewElement:addChild({
		pos = { viewElement.size.w * 0.225 + 5, viewElement.size.h / 5 * 3 + 5 },
		size = { viewElement.size.w * 0.225 - 10, viewElement.size.h / 5 * 2 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	if (saleFeatured) then
		local dailyDiscountHolder = dailySale:addChild({
			pos = { 0, 10 + dailySale.size.h * 0.15 * storeButtons.dailysale.ratio },
			size = { dailySale.size.w / 3, dailySale.size.h * 0.4 * storeButtons.dailysale.ratio },
			bgColor = dailySale.animateColor
		})
		TBMenu:showHomeButton(dailySale, storeButtons.dailysale, 2, { dailyDiscountHolder })
		dailyDiscountHolder:reload()
		local dailyDiscount = dailyDiscountHolder:addChild({
			pos = { 5, 0 },
			size = { dailyDiscountHolder.size.w - 10, dailyDiscountHolder.size.h }
		})
		local percentageTC, percentageST = saleFeatured.now_tc_price == 0 and 0 or 1 - saleFeatured.now_tc_price / saleFeatured.price, saleFeatured.now_usd_price == 0 and 0 or 1 - saleFeatured.now_usd_price / saleFeatured.price_usd
		local percentage = percentageTC > percentageST and math.floor(percentageTC * 100) or math.floor(percentageST * 100)
		dailyDiscount:addAdaptedText(true, "-" .. percentage .. "%")
		local saleItemIconHolder = dailySale:addChild({
			pos = { -10 - (dailySale.size.w - 20) * 0.55, dailySale.size.h * 0.3 * storeButtons.dailysale.ratio },
			size = { (dailySale.size.w - 20) * 0.3, (dailySale.size.w - 20) * 0.3 }
		})
		local iconScale = saleItemIconHolder.size.w --saleItemIconHolder.size.w > 64 and 64 or saleItemIconHolder.size.w
		local saleItemIcon = saleItemIconHolder:addChild({
			pos = { (saleItemIconHolder.size.w - iconScale) / 2, (saleItemIconHolder.size.h - iconScale) / 2 },
			size = { iconScale, iconScale },
			bgImage = saleFeatured:getIconPath()
		})
	else
		TBMenu:showHomeButton(dailySale, storeButtons.dailysale, 2)
	end

	local storeColors = viewElement:addChild({
		pos = { viewElement.size.w * 0.45 + 5, 0 },
		size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	TBMenu:showHomeButton(storeColors, storeButtons.storecolors)

	local storeAdvanced = viewElement:addChild({
		pos = { viewElement.size.w * 0.725 + 5, 0 },
		size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	TBMenu:showHomeButton(storeAdvanced, storeButtons.storeadvanced)

	local storeTextures = viewElement:addChild({
		pos = { viewElement.size.w * 0.45 + 5, viewElement.size.h / 2 + 5 },
		size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	TBMenu:showHomeButton(storeTextures, storeButtons.storetextures, 3)

	local storeAccount = viewElement:addChild({
		pos = { viewElement.size.w * 0.725 + 5, viewElement.size.h / 2 + 5 },
		size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	TBMenu:showHomeButton(storeAccount, storeButtons.storeaccount, 4)

	if (Store.Discounts and #Store.Discounts > 0) then
		local discountItem = Store.Discounts[math.random(1, #Store.Discounts)]
		Store:showPersonalDiscount(discountItem)
	end
end

if (_G.PLATFORM == "ANDROID") then
	add_hook("purchase_status", Store.HookName, function(result, code)
		---Calls we want to listen will always return result=true and a non-zero code
		if (result ~= true or code == 0) then return end

		if (code == 1000) then
			StoreInternal.IAPInterfaceReady = true
			if (Store.Ready) then
				StoreInternal.RegisterIAPItems()
			end
		elseif (code >= 1010) then
			StoreInternal.IAPInterfaceReady = false
			StoreInternal.InAppIdentifiersReady = false
		end
	end)
end
