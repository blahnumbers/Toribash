-- Network class based on 5.41+ network hooks
do
	Request = {}
	Request.__index = Request
	local cln = {}
	setmetatable(cln, Request)
	
	-- returns a table that gets updated once player info is loaded
	-- works somewhat similarly to JavaScript Promise type
	-- https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Global_Objects/Promise
	function Request:new(name, success, error)
		local response = { ready = false }
		
		local name = name or "netrequest"
		local success = success or function() if (TB_MENU_DEBUG) then echo(get_network_response()) end end
		local error = error or function() if (TB_MENU_DEBUG) then echo(get_network_error()) end response.failed = true response.ready = true end
		add_hook("network_error", name, function()
				if (TB_MENU_DEBUG) then echo(get_network_error()) end
				error(response)
				response.failed = true
				response.ready = true
				remove_hooks(name)
			end)
		add_hook("network_complete", name, function()
				if (TB_MENU_DEBUG) then echo(get_network_response()) end
				success(response)
				response.ready = true
				remove_hooks(name)
			end)
			
		return response
	end
end
