
export type Result<T, E> = typeof(setmetatable(
	{} :: {
		_ok: boolean,
		_v: T,
		_e: E,
	},
	{} :: ResultImpl
))

export type ResultImpl = {
	__index: ResultImpl,
	__tostring: <T, E>(self: Result<T, E>) -> string,
	__eq: <T, E>(self: Result<T, E>, other: Result<T, E>) -> boolean,

	Ok: <T>(value: T) -> Result<T, any>,
	Err: <E>(err: E) -> Result<any, E>,
	try: <T, U...>(f: (U...) -> T, U...) -> Result<T, unknown>,
	is: (value: any) -> boolean,
	isOk: <T, E>(self: Result<T, E>) -> boolean,
	isOkAnd: <T, E>(self: Result<T, E>, f: (T) -> boolean) -> boolean,
	isErr: <T, E>(self: Result<T, E>) -> boolean,
	isErrAnd: <T, E>(self: Result<T, E>, f: (E) -> boolean) -> boolean,
	map: <T, E, U>(self: Result<T, E>, f: (T) -> U) -> Result<U, E>,
	mapOr: <T, E, U>(self: Result<T, E>, default: U, f: (T) -> U) -> U,
	mapOrElse: <T, E, U>(self: Result<T, E>, default: (E) -> U, f: (T) -> U) -> U,
	mapErr: <T, E, F>(self: Result<T, E>, f: (E) -> F) -> Result<T, F>,
	expect: <T, E>(self: Result<T, E>, msg: string) -> T,
	unwrap: <T, E>(self: Result<T, E>) -> T,
	expectErr: <T, E>(self: Result<T, E>, msg: string) -> E,
	unwrapErr: <T, E>(self: Result<T, E>) -> E,
	andRes: <T, E, U>(self: Result<T, E>, res: Result<U, E>) -> Result<U, E>,
	andThen: <T, E, U>(self: Result<T, E>, f: (T) -> Result<U, E>) -> Result<U, E>,
	orRes: <T, E, F>(self: Result<T, E>, res: Result<T, F>) -> Result<T, F>,
	orElse: <T, E, F>(self: Result<T, E>, f: (E) -> Result<T, F>) -> Result<T, F>,
	unwrapOr: <T, E>(self: Result<T, E>, default: T) -> T,
	unwrapOrElse: <T, E>(self: Result<T, E>, f: (E) -> T) -> T,
	match: <T, E, U>(self: Result<T, E>, f: { Ok: (T) -> U, Err: (E) -> U }) -> U,
	unpack: <T, E>(self: Result<T, E>) -> (T, E),
}

return function(panicker)
	local Result = {} :: ResultImpl
	Result.__index = Result

	function Result.Ok(value)
		local self = setmetatable({ _ok = true :: true, _v = value }, Result)
		return table.freeze(self) :: any
	end

	function Result.Err(err)
		local self = setmetatable({ _ok = false :: false, _e = err }, Result)
		return table.freeze(self) :: any
	end

	function Result.try(f, ...)
		local ok, res = pcall(f :: any, ...)
		if ok then
			return Result.Ok(res)
		end
		return Result.Err(res)
	end

	function Result.is(value)
		return typeof(value) == "table" and getmetatable(value) == Result
	end

	function Result.isOk(self)
		return self._ok
	end

	function Result.isOkAnd(self, f)
		return self._ok and f(self._v)
	end

	function Result.isErr(self)
		return not self._ok
	end

	function Result.isErrAnd(self, f)
		return not self._ok and f(self._e)
	end

	function Result.map(self, f)
		if not self._ok then
			return self :: Result<any, any>
		end
		return Result.Ok((f :: any)(self._v))
	end

	function Result.mapOr(self, default, f)
		if not self._ok then
			return default
		end
		return f(self._v)
	end

	function Result.mapOrElse(self, default, f)
		if not self._ok then
			return default(self._e)
		end
		return f(self._v)
	end

	function Result.mapErr(self, f)
		if self._ok then
			return self :: Result<any, any>
		end
		return Result.Err((f :: any)(self._e))
	end

	function Result.expect(self, msg)
		if not self._ok then
			panicker(msg)
		end
		return self._v
	end

	function Result.unwrap(self)
		if not self._ok then
			panicker(self._e :: any)
		end
		return self._v
	end

	function Result.expectErr(self, msg)
		if self._ok then
			panicker(msg)
		end
		return self._e
	end

	function Result.unwrapErr(self)
		if self._ok then
			panicker(self._v :: any)
		end
		return self._e
	end

	function Result.andRes(self, res)
		if self._ok then
			return res
		end
		return self :: Result<any, any>
	end

	function Result.andThen(self, f)
		if self._ok then
			return f(self._v)
		end
		return self :: Result<any, any>
	end

	function Result.orRes(self, res)
		if not self._ok then
			return res
		end
		return self :: Result<any, any>
	end

	function Result.orElse(self, f)
		if not self._ok then
			return f(self._e)
		end
		return self :: Result<any, any>
	end

	function Result.unwrapOr(self, default)
		if self._ok then
			return self._v
		end
		return default
	end

	function Result.unwrapOrElse(self, f)
		if self._ok then
			return self._v
		end
		return f(self._e)
	end

	function Result.match(self, f)
		if self._ok then
			return f.Ok(self._v)
		end
		return f.Err(self._e)
	end

	function Result.unpack(self)
		return self._v, self._e
	end

	if _G.UTIL_TARGET == "lune" then
		-- use `stdio.format` on Lune which pretty-prints tables

		local stdio = require("@lune/stdio")
		function Result.__tostring(self)
			if self._ok then
				if typeof(self._v) == "string" then
					return string.format("Result::Ok(%q)", self._v)
				else
					return `Result::Ok({stdio.format(self._v)})`
				end
			end

			if typeof(self._e) == "string" then
				return string.format("Result::Err(%q)", self._e)
			else
				return `Result::Err({stdio.format(self._e)})`
			end
		end
	else
		function Result.__tostring(self)
			if self._ok then
				if typeof(self._v) == "string" then
					return string.format("Result::Ok(%q)", self._v)
				else
					return `Result::Ok({self._v})`
				end
			end

			if typeof(self._e) == "string" then
				return string.format("Result::Err(%q)", self._e)
			else
				return `Result::Err({self._e})`
			end
		end
	end

	function Result.__eq(self, other)
		if Result.is(other) then
			if self._ok and other._ok then
				return self._v == other._v
			elseif not self._ok and not other._ok then
				return self._e == other._e
			end
		end
		return false
	end

	return Result
end