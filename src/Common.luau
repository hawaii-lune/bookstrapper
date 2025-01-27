local Types = require("./Types")
local task = require("@lune/task")

local Common = {}
Common.BookstrappedThreads = {}
Common.ExternalFiles = {}

function Common.sliceDebugName(s: string): string
	return string.match(s, "%[string \"(.-)\"%]") or s
end

function Common.getBookstrapperFromThread()
	return Common.BookstrappedThreads[coroutine.running()] or Common.G_PANIC(`Attempt to use a Bookstrapper method outside of a Bookstrapper tracked thread`)
end

function Common.getTryCatchTop(bookstrapper: Types.BookstrapRunner)
	local catchState = bookstrapper.TryCatchStack[coroutine.running()]
	if not catchState then Common.G_PANIC("Attempt to use a Bookstrapper method outside of a Bookstrapper tracked thread.") end
	local top = catchState[#catchState]
	if not top then Common.G_PANIC("TryCatch stack is empty, this is likely an internal bug") end
	return top
end

-- this cant depend on other methods because it causes an infininte recursion
function Common.G_PANIC(msg: string?)
	-- calls panic in the loaded bookstrapper, or just errors if no bookstrapped found
	-- for thread

	local co = coroutine.running()
	local bk: Types.BookstrapRunner = Common.BookstrappedThreads[co]
	if not bk then error(`[WARN: PANIC CALLED FROM UNTRACKED THREAD]; {msg}`) end
	local catchState = bk.TryCatchStack[coroutine.running()]
	local catch = catchState and catchState[#catchState]
	if not catch then error(`[WARN: PANIC CALLED OUTSIDE TRYCATCH]; {msg}`) end
	local ex = bk:Exception("ThreadPanicException", msg)
	bk.Exports.Panic(ex)
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

function Common.disposeRunningThread()
	task.defer(task.cancel, coroutine.running())
	coroutine.yield()
end

return Common