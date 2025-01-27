# Bookstrapper

Try-Catch based Luau bootstrapper based loosely off C#. This is used as the
bootstrapper for Hawaii.

## Usage

At a base level, all Bookstrapper code is executed in a stack of `Try-Catch`
blocks. The most basic way to open a Bookstrapper stack, is to just require
it and call it directly, then use `Run` to start the stack.

```luau
local Bookstrapper = require("Bookstrapper")
local Http = require("BookstrapperHttp")

local worker = Bookstrapper("YourCode", function()
	local request

	worker.Exports.Try(function()
		request = Http:Request("https://www.google.com/")
	end)
	:Catch(Http.HttpException, function(ex)
		worker.Exports.Throw(ex)
	end)()
end)

worker.StackAllowList[debug.info(1, "s")] = true -- required for the file to
-- be included in traces, this is done so internal code doesn't flood the
-- trace
worker:Run()

```

If you want to capture the final Exception, you should define a custom catch
handler on the bookstrapper directly. The default handler will continue to work,
but can be surpressed.

```luau
Bookstrapper.LogSuppressionType = "All"
-- alternatively, you can set this to Root to only silence the root,
-- this can be useful for debugging thread errors

Bookstrapper.DefaultCatchHandler = function(ex)
	print(`Oh noes, the code failed with {ex}`)
end
```

This method is fairly primitive since its meant to be for logging more than
handling explicit cases. Your code should handle exceptions within the main
block if possible.

> If the DefaultCatchHandler fails, the default logger will run, regardless
> of suppression.