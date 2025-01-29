local Types = require("./Types")
local Exports = require("./Exports")
local Logger = require("./Logger")
local Result = require("./Result")
local Threading = require("./Threading")
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
	runner.FileNameAssoc = {}
	runner.Threading = Threading(runner)

	function runner.Run(self: Types.BookstrapRunner<T, E>): Result.Result<T, E>
		local args = process.args
		return self.Fn(#args, args)
	end

	runner.Exports = Exports(runner)
	runner.Fn = runner.Threading.createRunner(name, true, true, tryFn)

	return runner
end