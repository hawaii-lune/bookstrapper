local Types = require("./Types")
local stdio = require("@lune/stdio")
local DateTime = require("@lune/DateTime")

local function writeLog(
	self: Types.Logger,
	message: string,
	severity: Types.Severity?,
	pipe: boolean?,
	timestamp: DateTime.DateTime?
)
	local log = {
		Message = message,
		Time = timestamp or DateTime.now(),
		Severity = severity or "Log"
	}
	table.freeze(log)
	table.insert(self.history, log)

	if pipe == true then
		if severity == "Panic" then
			stdio.ewrite(message)
		else
			stdio.write(message)
		end
	end
end

return function(
	logname: string,
	stdout_fn: (Types.Logger, Types.Logpoint) -> ()?
): Types.Logger
	local logfile = {
		logname = logname,
		stdout_fn = stdout_fn,
		history = {},
		write = writeLog
	}

	table.freeze(logfile)
	return logfile
end