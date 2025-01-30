--!strict
local DateTime = require("@lune/DateTime")
local Result = require("./Result")

export type Severity = "Log"|"Warning"|"Panic"|"Info"
export type PipeResultErrorMode = "None"|"Threading"|"Main"|"All"

export type StackInfo = typeof(setmetatable({}::{
	Source: string,
	Line: number,
	Name: string?,
	IsC: boolean,
	FileSource: string?,
	RepeatCount: number,
	TruncationMarker: boolean,
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
	PipeResultErrorMode: PipeResultErrorMode,
	Fn: (argc: number, argv: {string}) -> Result.Result<T, E>,
	StackAllowlist: {[string]: true},
	FileNameAssoc: {[string]: string}, -- Not used yet
	Threading: any,

	Exports: {
		Write: <A...>(A...) -> (),
		WriteLine: <A...>(A...) -> (),
		Warn: <A...>(A...) -> (),
		Panic: <A>(msg: A?) -> (),
		Result: typeof(Result()),
		Threading: {
			Spawn: <T,E,A...>(fnOrThread: (A...) -> Result.Result<T, E>|thread, A...) -> thread,
			Defer: <T,E,A...>(fnOrThread: (A...) -> Result.Result<T, E>|thread, A...) -> thread,
			Delay: <T,E,A...>(duration: number, fnOrThread: (A...) -> Result.Result<T, E>|thread, A...) -> thread,
			Create: <T,E,A...>(duration: number, fnOrThread: (A...) -> Result.Result<T, E>) -> thread,		
		},
	},
	
	Run: (BookstrapRunner<T, E>) -> Result.Result<T, E>
}

return nil