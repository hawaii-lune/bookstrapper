local TryCatch = require("./TryCatch")

local TEST_OUTWARDS_PROPEGATION = false

return function(fn, runner)
	local tc = TryCatch(fn):Catch(nil, function(ex)
		if runner.DefaultCatchForward then
			TryCatch(runner.DefaultCatchForward)
			:Catch(nil,	function(err)
				ex = err
			end)();
		end
		-- default exception handler
		-- should print the exception to log directly
		local stackSize = #ex.Stack + 3
		local stack = table.create(stackSize)
		table.insert(stack, `\x07\27[91mThread {coroutine.running()} threw with \27[37m\27[44m\27[1m {ex.Kind} \27[22m\27[49m:\27[91m\27[22m {ex.Message}\27[39m`)
		table.insert(stack, "[\27[94mStack Begin\27[39m]")

		for i, stackInfo in ex.Stack do
			stack[i+2] = `   \27[92m{tostring(stackInfo)}\27[39m`
		end
		table.insert(stack, "[\27[94mStack End\27[39m]\n")
		runner.Log:write(table.concat(stack, "\n"), "Panic", true)
	end)

	if TEST_OUTWARDS_PROPEGATION then
		tc:Finally(function()
			print("OUTWARDS PROPEGATION TEST", runner.TryCatchStack[coroutine.running()])
		end)
	end

	return tc
end