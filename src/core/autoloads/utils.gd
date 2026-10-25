extends Node

#region SpecialChars
const ARROW_LEFT: String = "🡆"
#endregion

#region PrettyPrintNumbers

## Keys are powers of ten (and therefore the number of zeroes in each group).
## 10^306 is the largest three-digit group that fits in a finite 64-bit float.
const PRETTY_PRINT_NUM: Dictionary[int, String] = {
	0: "",
	3: "K", # Thousand
	6: "M", # Million
	9: "B", # Billion
	12: "T", # Trillion
	15: "Q", # Quadrillion
	18: "QI", # Quintillion
	21: "SX", # Sextillion
	24: "SP", # Septillion
	27: "O", # Octillion
	30: "N", # Nonillion
	33: "D", # Decillion
	36: "UD",
	39: "DD",
	42: "TD",
	45: "QD",
	48: "QID",
	51: "SXD",
	54: "SPD",
	57: "OD",
	60: "ND",
	63: "V",
	66: "UV",
	69: "DV",
	72: "TV",
	75: "QV",
	78: "QIV",
	81: "SXV",
	84: "SPV",
	87: "OV",
	90: "NV",
	93: "TG",
	96: "UTG",
	99: "DTG",
	102: "TTG",
	105: "QTG",
	108: "QITG",
	111: "SXTG",
	114: "SPTG",
	117: "OTG",
	120: "NTG",
	123: "QAG",
	126: "UQAG",
	129: "DQAG",
	132: "TQAG",
	135: "QQAG",
	138: "QIQAG",
	141: "SXQAG",
	144: "SPQAG",
	147: "OQAG",
	150: "NQAG",
	153: "QIG",
	156: "UQIG",
	159: "DQIG",
	162: "TQIG",
	165: "QQIG",
	168: "QIQIG",
	171: "SXQIG",
	174: "SPQIG",
	177: "OQIG",
	180: "NQIG",
	183: "SXG",
	186: "USXG",
	189: "DSXG",
	192: "TSXG",
	195: "QSXG",
	198: "QISXG",
	201: "SXSXG",
	204: "SPSXG",
	207: "OSXG",
	210: "NSXG",
	213: "SPG",
	216: "USPG",
	219: "DSPG",
	222: "TSPG",
	225: "QSPG",
	228: "QISPG",
	231: "SXSPG",
	234: "SPSPG",
	237: "OSPG",
	240: "NSPG",
	243: "OG",
	246: "UOG",
	249: "DOG",
	252: "TOG",
	255: "QOG",
	258: "QIOG",
	261: "SXOG",
	264: "SPOG",
	267: "OOG",
	270: "NOG",
	273: "NG",
	276: "UNG",
	279: "DNG",
	282: "TNG",
	285: "QNG",
	288: "QING",
	291: "SXNG",
	294: "SPNG",
	297: "ONG",
	300: "NNG",
	303: "C",
	306: "UC",
}

func pretty_print_num(number: float) -> String:
	if is_nan(number): return "NaN"
	if is_inf(number): return "Inf"

	var absolute_number: float = absf(number)
	if absolute_number < 1_000.0:
		return _format_pretty_number(number)

	var exponent: int = floori(log(absolute_number) / log(10.0))
	exponent -= exponent % 3
	var scaled_number: float = number / pow(10.0, exponent)

	# Keep rounding from producing values such as 1000K.
	if absf(scaled_number) >= 999.995 and exponent < 306:
		exponent += 3
		scaled_number /= 1_000.0

	return _format_pretty_number(scaled_number) + PRETTY_PRINT_NUM[exponent]

func _format_pretty_number(number: float) -> String:
	return ("%.2f" % number).rstrip("0").rstrip(".")

#endregion

#region WeightedRNG
class WeightedRNG extends RefCounted:
	## Weighted random-pick table with "luck" bias.
	##
	## Assumption on `luck`: uniformly scaling every weight by the same factor
	## would NOT change relative odds at all, so that's not useful. Instead,
	## `luck` is applied as an exponent (weight ^ (1 / luck)):
	##   - luck == 1.0  -> weights unchanged.
	##   - luck  > 1.0  -> compresses the gap between weights, boosting the
	##                     relative chance of rarer (lower-weight) entries.
	##   - luck  < 1.0  -> amplifies the gap, favoring already-common entries.
	## Adjust `_adjust_weight()` if a different luck curve is desired.
	##
	## Storage uses packed arrays (no boxing) and a sorted cumulative-weight
	## array so picks are O(log n) via binary search, with O(n) one-time build.
	var _ids: PackedInt32Array
	var _cumulative_weights: PackedFloat64Array
	var _total_weight: float = 0.0
	
	
	func _init(items: Dictionary[int, int], luck: float = 1.0) -> void:
		var count: int = items.size()
		_ids.resize(count)
		_cumulative_weights.resize(count)
	
		var inv_luck: float = 1.0 / maxf(luck, 0.0001)
		var running_total: float = 0.0
		var index: int = 0
	
		for id: int in items:
			var base_weight: float = float(items[id])
			var adjusted_weight: float = pow(base_weight, inv_luck) if base_weight > 0.0 else 0.0
			running_total += adjusted_weight
			_ids[index] = id
			_cumulative_weights[index] = running_total
			index += 1
	
		_total_weight = running_total
	
	
	## Returns a random item id according to its adjusted weight,
	## or -1 if the table is empty / all weights are zero.
	## Pass a shared `rng` to avoid relying on the global RNG state.
	func pick(rng: RandomNumberGenerator = null) -> int:
		if _total_weight <= 0.0:
			return -1
	
		var roll: float = (rng.randf() if rng else randf()) * _total_weight
	
		# Binary search for the first cumulative weight >= roll.
		var low: int = 0
		var high: int = _cumulative_weights.size() - 1
		while low < high:
			var mid: int = (low + high) >> 1
			if _cumulative_weights[mid] < roll:
				low = mid + 1
			else:
				high = mid
	
		return _ids[low]
	
	
	## Draws `amount` picks (with repeats allowed, weights untouched between draws).
	func pick_many(amount: int, rng: RandomNumberGenerator = null) -> PackedInt32Array:
		var results: PackedInt32Array = PackedInt32Array()
		results.resize(amount)
		for i: int in amount:
			results[i] = pick(rng)
		return results
	
	
	func size() -> int:
		return _ids.size()
	
	
	func total_weight() -> float:
		return _total_weight

#endregion