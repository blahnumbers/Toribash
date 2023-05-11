-- Network class manager based on 5.41+ network hooks
require("toriui.uielement")

do
	-- **Ver 1.2 updates:**
	-- * Use pcall() to run on success/error functions
	-- * Fixed bug with active request not getting finalized from network_error hook
	-- * Added EmmyLua supported annotations
	--
	-- **Ver 1.1 updates:**
	-- * Check for active task before queueing a new request to ensure we don't get data from the previous request
	Request = { ver = 1.2 }
	Request.__index = Request
	local cln = {}
	setmetatable(cln, Request)

	-- Table that gets updated once network response is finalized. Works somewhat similarly to [JavaScript Promise type](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Global_Objects/Promise).
	---@class RequestPromise
	---@field ready boolean True if associated network response has been finalized
	---@field failed boolean True if network responded with a http error
	---@field id string Unique ID of a request

	-- Table that holds main information about the network request
	---@class RequestData
	---@field name string Name of the network request
	---@field response RequestPromise Request promise associated with current network request
	---@field success function Function that will be executed on network_complete callback
	---@field error function Function that will be executed on network_error callback
	---@field netcall function Function that will be executed instantly after network listener hooks are spawned

	---Spawns network listener hooks to handle network responses. \
	---*You likely want to use `Request:queue()` instead*.
	---@param name string|nil Request name - may come in handy when debugging to be able to tell different requests from each other
	---@param success? function Function to execute on successful network response
	---@param error? function Function to execute on network response failure
	---@param response? RequestPromise A preexisting RequestPromise to use for return value
	---@return RequestPromise response
	function Request:new(name, success, error, response)
		local response = response or { ready = false }
		local name = name or "netrequest"
		local success = success or function(r) end
		local error = error or function(r) end

		TB_NETWORK_LASTREQUEST = response.id
		add_hook("network_error", name, function()
				if (TB_MENU_DEBUG) then print(get_network_error()) end
				Request:finalize(name)
				response.failed = true
				error(response)
				response.ready = true
			end)
		add_hook("network_complete", name, function()
				if (TB_MENU_DEBUG) then print(get_network_response()) end
				Request:finalize(name)
				success(response)
				response.ready = true
			end)

		return response
	end

	-- Queues a network request to execute once network state is ready
	---@param netcall function Function that should be executed instantly after we start listening to network response hooks
	---@param name string|nil Request name - may come in handy when debugging to be able to tell different requests from each other
	---@param success? function Function to execute on successful network response
	---@param error? function Function to execute on network response failure
	---@return RequestPromise response
	function Request:queue(netcall, name, success, error)
		if (type(netcall) ~= "function") then
			if (TB_MENU_DEBUG) then
				print("Usage Request:queue(function netCall, string callName, function onSuccess, function onError)")
			end
			return { ready = true, failed = true, id = "" }
		end

		---@type RequestPromise
		local response = { ready = false, id = generate_uid() }
		local name = name or "netrequest"
		local success = success or function() end
		local error = error or function() end

		local request = { name = name, success = success, error = error, response = response, netcall = netcall }
		table.insert(TB_NETWORK_REQUEST_QUEUE, request)

		if (#TB_NETWORK_REQUEST_QUEUE > 1) then
			if (TB_MENU_DEBUG) then
				print("Queueing a request (guid " .. request.response.id .. ")")
			end
		else
			if (TB_MENU_DEBUG) then
				print("Launching a request (guid " .. request.response.id .. ")")
			end
			Request:finalize('netrequest')
		end
		return response
	end

	-- Finalizes the request and launches the next request if queue isn't empty
	---@param name string Name of a request to finalize
	---@return nil
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
							print("Queueing next request")
							print(request)
						end
						Request:new(request.name, request.success, request.error, request.response)
						local completed, msg = pcall(request.netcall)
						if (not completed) then
							if (TB_MENU_DEBUG) then
								print("netcall error: " .. (type(msg) == "string" and msg or ''))
							end
							Request:cancelCurrentRequest()
						end
					end
				end)
		end
	end

	-- Emergency exit for currently active network request
	---@return RequestData|nil
	function Request:cancelCurrentRequest()
		for _ ,v in pairs(TB_NETWORK_REQUEST_QUEUE) do
			if (v.response.id == TB_NETWORK_LASTREQUEST) then
				Request:finalize(v.name)
				return v
			end
		end
	end
end
