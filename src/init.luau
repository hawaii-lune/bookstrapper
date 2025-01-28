local Types = require("./Types")
local Exports = require("./Exports")
local Logger = require("./Logger")
local Result = require("./Result")
local MessageHandler = require("./MessageHandler")
local process = require("@lune/process")

-- we need to set the root log here as its how we can tell if we're working with
-- the init file or a shorthand
-- if its a shorthand then all log info is pointless

return function<T,E>(name: string, tryFn: (argc: number, argv: {string}) -> Result.Result<T, E>): Types.BookstrapRunner<T,E>
	local runner = {}::Types.BookstrapRunner<T,E>
	runner.Name = name
	runner.Log = Logger(name)
	runner.PipeResultErrors = true
	runner.StackAllowlist = {}

	function runner.Run(self: Types.BookstrapRunner<T, E>): Result.Result<T, E>
		local args = process.args
		local r = Result.try(tryFn, #args, args)
		r = if r:isOk() then r:unwrap() else r

		if not r or type(r) ~= "table" or not r.isErr then
			MessageHandler.panicInternal(`Bookstrapper likely did not return a Result<T, E>`, runner)
		end

		if r:isErr() and self.PipeResultErrors then
			MessageHandler.result(r, self)
		end

		return r
	end

	runner.Exports = Exports(runner)
	runner.Fn = tryFn

	return runner
end