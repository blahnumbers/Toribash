-- Store data class

do
	Store = {}
	Store.__index = Store
	local cln = {}
	setmetatable(cln, Store)
		
	function Store:getSaleItem()
		itemData = {
			id = 0,
		 	name = "",
			tcOld = nil,
			tc = nil,
			usdOld = nil,
			usd = nil
		}
		local file = io.open("Store/Store.txt")
		if (not file) then
			return itemData
		end
		for ln in file:lines() do
			if string.match(ln, "^PRODUCT") then
				local segments = 19
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				if (data_stream[6] == "1") then
					itemData.id = data_stream[4]
					itemData.name = data_stream[5]
					itemData.tcOld = tonumber(data_stream[9])
					itemData.tc = tonumber(data_stream[7])
					itemData.usdOld = tonumber(data_stream[10])
					itemData.usd = tonumber(data_stream[8])
					return itemData
				end
			end
		end
		file:close()
	end
	
end