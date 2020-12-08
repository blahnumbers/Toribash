-- Network class based on 5.41+ network hooks
do
	-- Ver 1.1 updates:
	-- * Check for active task before queueing a new request to ensure we don't get data
	--   that the previous request should have received
	Request = { ver = 1.1 }
	Request.__index = Request
	local cln = {}
	setmetatable(cln, Request)
	
	-- returns a table that gets updated once player info is loaded
	-- works somewhat similarly to JavaScript Promise type
	-- https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Global_Objects/Promise
	function Request:new(name, success, error, response)
		local response = response or { ready = false }
		local name = name or "netrequest"
		local success = success or function() end
		local error = error or function() end
		
		TB_NETWORK_LASTREQUEST = response.id
		add_hook("network_error", name, function()
				if (TB_MENU_DEBUG) then echo(get_network_error()) end
				Request:finalize()
				response.failed = true
				error(response)
				response.ready = true
			end)
		add_hook("network_complete", name, function()
				if (TB_MENU_DEBUG) then echo(get_network_response()) end
				Request:finalize(name)
				success(response)
				response.ready = true
			end)
			
		return response
	end
	
	function Request:queue(netcall, name, success, error)
		if (type(netcall) ~= "function") then
			if (TB_MENU_DEBUG) then
				UIElement:debugEcho("Usage Request:queue(function netCall, string callName, function onSuccess, function onError)")
			end
			return false
		end
		
		local response = { ready = false, id = Guid() }
		local name = name or "netrequest"
		local success = success or function() end
		local error = error or function() end
		
		local request = { name = name, success = success, error = error, response = response, netcall = netcall }
		table.insert(TB_NETWORK_REQUEST_QUEUE, request)
		
		if (#TB_NETWORK_REQUEST_QUEUE > 1) then
			if (TB_MENU_DEBUG) then
				UIElement:debugEcho("Queueing a request (guid " .. request.response.id .. ")")
			end
		else
			if (TB_MENU_DEBUG) then
				UIElement:debugEcho("Launching a request (guid " .. request.response.id .. ")")
			end
			Request:finalize('netrequest')
		end
		return response
	end
	
	function Request:finalize(name)
		remove_hooks(name)
		for i = #TB_NETWORK_REQUEST_QUEUE, 1, -1 do
			if (TB_NETWORK_REQUEST_QUEUE[i].response.id == TB_NETWORK_LASTREQUEST) then
				table.remove(TB_NETWORK_REQUEST_QUEUE, i)
			end
		end
		
		if (#TB_NETWORK_REQUEST_QUEUE ~= 0) then
			add_hook("draw2d", "netrequest_wait", function()
					if (get_network_task() == 0) then
						remove_hook("draw2d", "netrequest_wait")
						local request = TB_NETWORK_REQUEST_QUEUE[1]
						if (TB_MENU_DEBUG) then
							UIElement:debugEcho("Queueing next request")
							UIElement:debugEcho(request)
						end
						Request:new(request.name, request.success, request.error, request.response)
						local completed, msg = pcall(request.netcall)
						if (not completed) then
							if (TB_MENU_DEBUG) then
								UIElement:debugEcho("netcall error: " .. (type(msg) == "string" and msg or ''))
							end
							Request:cancelCurrentRequest()
						end
					end
				end)
		end
	end
	
	function Request:cancelCurrentRequest()
		for i,v in pairs(TB_NETWORK_REQUEST_QUEUE) do
			if (v.response.id == TB_NETWORK_LASTREQUEST) then
				Request:finalize(v.name)
				return v
			end
		end
	end
end
