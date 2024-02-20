local export = {}

 -- Load this only if needed.
local function is_positive_integer(val)
	-- Redefine the "global local" variable in which this function is stored.
	is_positive_integer = require("table").isPositiveInteger
	return is_positive_integer(val)
end

local function serialise_frame(title, args)
	local result = { "{{", title }
	
	local use_equals = false
	local greatest_i = 0
	for i, value in ipairs(args) do
		greatest_i = i
		if use_equals or value:find("=") then
			value = i .. "=" .. value
			use_equals = true
		end
		table.insert(result, "|" .. value)
	end
	
	for key, value in pairs(args) do
		if type(key) == "string"
		or (type(key) == "number" and (key > greatest_i or not is_positive_integer(key))) then
			table.insert(result, "|" .. key .. "=" .. value)
		end
	end
	
	table.insert(result, "}}")
	return table.concat(result)
end
export.serialise_frame = serialise_frame

function export.unsubst_module(entry_point)
	local frame = mw.getCurrentFrame()
	return serialise_frame(
		((parent:getTitle() == mw.title.getCurrentTitle().fullText) and 'safesubst:' or '') ..
		'#invoke:' .. frame:getTitle():gsub('^Module:', '') .. '|' .. entry_point, frame.args	
	)
end

function export.unsubst_template(entry_point)
	local frame = mw.getCurrentFrame()
	local parent = frame:getParent()
	if parent:getTitle() == mw.title.getCurrentTitle().fullText then
		return serialise_frame('safesubst:#invoke:' .. frame:getTitle():gsub('^Module:', '') .. '|' .. entry_point, frame.args)
	end
	return serialise_frame(parent:getTitle():gsub('^Template:', ''), parent.args)
end

-- invokables

function export.me(frame)
	local parent = frame:getParent()

	if mw.isSubsting() then
		return export.unsubst_template('me')
	end

	-- "manual substitution"?
	if not frame.args.nocheck then
		if (frame ~= parent) and not parent:getTitle():find("^Template:") then
			return '<strong class="error">It appears that you have copied template code from a template page. ' ..
				'You should transclude the template instead, by putting its name in curly brackets, like so: ' ..
				'<code>{{template-name}}</code>.</strong>' -- XXX: maintenance category?
		end
	end

	return frame.args['']
end

return export