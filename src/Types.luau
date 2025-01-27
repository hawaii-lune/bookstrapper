local DateTime = require("@lune/DateTime")

export type StackInfo = typeof(setmetatable({}::{
	Source: string,
	Line: number,
	Name: string?,
	IsC: boolean
}, {}::{
	__tostring: (StackInfo) -> string
}))

export type Severity = "Log"|"Warning"|"Panic"|"Info"

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

export type Exception<Kind = unknown> = {
	Kind: Kind,
	Message: string?,
	Stack: {StackInfo}
}

export type TryCatch<ErrUnion = string> = typeof(setmetatable({}::{
	_try: () -> (),
	_finally: () -> ()?,
	_defaultcatch: (Exception<ErrUnion>) -> ()?,
	_catches: {[ErrUnion]: (Exception<ErrUnion>) -> ()},
	_ex: Exception?,

	Catch: (TryCatch<ErrUnion>, ex: ErrUnion?, fn: (Exception<ErrUnion>) -> ()) -> TryCatch<ErrUnion>,
	Finally: (TryCatch<ErrUnion>, fn: () -> ()) -> TryCatch<ErrUnion>,
}, {}::{
	__call: (TryCatch<ErrUnion>) -> ()
}))

export type BookstrapRunner = {
	Name: string,
	RootHandle: TryCatch<any>,
	TryCatchStack: {[thread]: {TryCatch}},
	ExecuteTryCatch: (BookstrapRunner, TryCatch<string>, ...any) -> boolean,
	Log: Logger,
	StackAllowList: {[string]: true},
	CreateStackTrace: (BookstrapRunner, tracegenMode: "Allowlist"|"All"|"C"?) -> {StackInfo},
	Exception: <A>(BookstrapRunner, kind: A, msg: string?) -> Exception<A>,
	DefaultCatchForward: <A>(Exception<A>) -> ()?,

	Exports: {
		Exception: typeof(setmetatable({}::{
			Extend: <A>(kind: A) -> (message: string?) -> Exception<A>
		}, {}::{
			__call: (any, message: string) -> Exception
		})),

		SetExceptionHandler: (fn: (Exception) -> ()) -> (),
		Throw: <A>(ex: string|Exception<A>) -> (),
		Try: <ErrUnion>(tryFn: () -> ()) -> TryCatch<ErrUnion>,
		Write: <A...>(A...) -> (),
		WriteLine: <A...>(A...) -> (),
		Warn: <A...>(A...) -> (),
		Panic: (string?) -> ()
	},
	Run: (BookstrapRunner) -> boolean
}

return nil