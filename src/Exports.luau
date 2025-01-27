local Types = require("./Types")
local Common = require("./Common")
local TryCatch = require("./TryCatch")
local Threading = require("./Threading")

local function flattenArgs(...)
	local buffer = {}
	for _, key in {...} do
		table.insert(buffer, tostring(key))
	end
	return table.concat(buffer, "  ")
end

local exports = {}
exports.Threading = Threading.Exported

exports.Exception = setmetatable({
	Extend = function<A>(kind: A)
		return function(msg: string?): Types.Exception<A>
			return Common.getBookstrapperFromThread():Exception(kind, msg)
		end
	end
}, {
	__call = function(self, msg: string?): Types.Exception
		return Common.getBookstrapperFromThread():Exception("Exception", msg)
	end
})

local ThreadPanicException = exports.Exception.Extend("ThreadPanicException")

function exports.SetExceptionHandler(fn: (Types.Exception) -> ())
	Common.getBookstrapperFromThread().DefaultCatchForward = fn
end

function exports.Throw<A>(ex: string|Types.Exception<A>)
	local bk = Common.getBookstrapperFromThread()
	local catch = Common.getTryCatchTop(bk)
	if not catch then Common.G_PANIC("Throw executed outside bookstrapped TryCatch") end

	if catch.FinallyExec then
		local finally = catch.FinallyExec
		catch.FinallyExec = nil -- stop recursive throws

		finally()
	end

	catch.TryCatch._ex = if type(ex) == "string" then exports.Exception(ex) else ex
	error() -- so that external catches dont get the export table but instead just a message
end

function exports.Try<ErrUnion>(tryFn: () -> ()): Types.TryCatch<ErrUnion>
	return TryCatch(tryFn)
end

function exports.Write(...: any)
	Common.getBookstrapperFromThread().Log:write(`{flattenArgs(...)}`, "Log", true)
end

function exports.WriteLine(...: any)
	Common.getBookstrapperFromThread().Log:write(`{flattenArgs(...)}\n`, "Log", true)
end

function exports.Warn(...: any)
	Common.getBookstrapperFromThread().Log:write(`{flattenArgs(...)}\n`, "Warning", true)
end

function exports.Panic(msg: string|Types.Exception<"ThreadPanicException">)
	exports.Throw(if type(msg) == "string" then ThreadPanicException(msg) else msg)
end

table.freeze(exports)
table.freeze(exports.Exception)
return exports