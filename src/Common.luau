local Types = require("./Types")

local Common = {}

function Common.sliceDebugName(s: string): string
	return string.match(s, "%[string \"(.-)\"%]") or s
end

local stackInfo_MT = {
	__tostring = function(self: Types.StackInfo)
		if self.IsC then
			return if self.Name ~= "" then `[C] {self.Name}` else "[C]"
		end

		if self.Line ~= -1 then
			return if self.Name ~= "" then `{self.Source}:{self.Name}:{self.Line}` else `{self.Source}:{self.Line}`
		end

		return if self.Name ~= "" then `{self.Source}:{self.Name}` else `{self.Source}`
	end
}

function Common.StackInfo(s: string, line: number, name: string?): Types.StackInfo
	local isC = s == "[C]"
	if not isC then
		s = string.match(s, "%[string \"(.-)\"%]") or s
	end
	local stackInfo = {
		Source = s,
		Line = line,
		Name = name,
		IsC = isC
	}
	setmetatable(stackInfo, stackInfo_MT)
	table.freeze(stackInfo)
	return stackInfo
end

function Common.GenerateStackTrace(filtermode: "Allowlist"|"All"|"C", filter: {[string]: true}?): {Types.StackInfo}
	local stack = {}
	local level = 0

	repeat
		level += 1
		local s, l, n = debug.info(level, "sln")
		if s then
			if s == "[C]" and filtermode == "Allowlist" then
				continue
			elseif filter and not filter[s] and filtermode ~= "All" then
				continue
			end

			table.insert(stack, Common.StackInfo(s, l, n))
		end
	until not s

	return stack
end

return Common