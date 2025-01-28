--!strict
local DateTime = require("@lune/DateTime")
local Result = require("./Result")

export type Severity = "Log"|"Warning"|"Panic"|"Info"

export type StackInfo = typeof(setmetatable({}::{
	Source: string,
	Line: number,
	Name: string?,
	IsC: boolean
}, {}::{
	__tostring: (StackInfo) -> string
}))

export type Logpoint = {
	Message: string,
	Time: DateTime.DateTime,
	Severity: Severity
}

export type Logger = {
	logname: string,
	stdout_fn: (Logger, Logpoint) -> ()?,
	write: (Logger, s: string, severity: Severity?, pipeout: boolean?, timestamp: DateTime.DateTime?) -> (),
	history: {Logpoint},
}

export type BookstrapRunner<T, E> = {
	Name: string,
	Log: Logger,
	DefaultCatchForward: (Result.Result<T, E>) -> ()?,
	PipeResultErrors: boolean,
	Fn: (argc: number, argv: {string}) -> Result.Result<T, E>,
	StackAllowlist: {[string]: true},

	Exports: {
		Write: <A...>(A...) -> (),
		WriteLine: <A...>(A...) -> (),
		Warn: <A...>(A...) -> (),
		Panic: (string|Result.Result<T, E>?) -> (),
		Result: typeof(Result)
	},
	
	Run: (BookstrapRunner<T, E>) -> Result.Result<T, E>
}

return nil