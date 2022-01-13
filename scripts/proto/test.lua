----------------------------------------
local proto = proto
local OPT, REQ, REP  = proto.OPT, proto.REQ, proto.REP
local bool  = proto.bool 
local enum  = proto.enum 
local int32 = proto.int32
local int64 = proto.int64
local uint32 = proto.uint32
local uint64 = proto.uint64
local sint32  = proto.sint32 
local sint64  = proto.sint64 
local fixed32  = proto.fixed32 
local fixed64  = proto.fixed64 
local sfixed32  = proto.sfixed32 
local sfixed64  = proto.sfixed64 
local double  = proto.double 
local string  = proto.string 
local bytes  = proto.bytes 
local float  = proto.float 
local _map  = proto.Map 
----------------------------------------
local syntax = "proto3"
local _P = proto.package("protos",syntax)
local _M  = _P.Message
local _E  = _P.Enum

local TestEnum = _E{
	MONDAY = 0;
	SUNDAY = 1;
}
_P.TestEnum = TestEnum

local TestChild = _M{--child
	{OPT, sint64, "fsint64", 1},
}

local TT2 = _M{--child--child
	{OPT, sint64, "Fsint64", 1},
}

local TTT = _M{--child
	{OPT, sint64, "fsint64", 1},
	TT2 = TT2,
	{OPT, TT2, "Fzzz", 2},
}

local TestType = _M{
	{OPT, int32, "Fint32", 1}, --注释 default
	{OPT, int64, "Fint64", 2},
	{OPT, uint32, "Fuint32", 3},
	{OPT, uint64, "Fuint64", 4},
	{OPT, sint32, "Fsint32", 5},
	{OPT, sint64, "Fsint64", 6},
	{OPT, fixed32, "Ffixed32", 7},
	{OPT, fixed64, "Ffixed64", 8},
	{OPT, double, "Fdouble", 9},
	{OPT, float, "Ffloat", 10},
	{OPT, bool, "Fbool", 11},
	{OPT, TestEnum, "Fenum", 12},
	{OPT, _map(int64,int32), "Fmap", 14},
	{REP, bool, "Frepeatbool", 15},
	{OPT, string, "Fstring", 16},
	{OPT, bytes, "Fbytes", 17},
	{OPT, sfixed32, "Fsfixed32", 18},
	{OPT, sfixed64, "Fsfixed64", 19},
	{REP, int32, "Frepeatint", 20},
	{REP, bool, "Frepeatbool2", 21},
	{REP, int32, "Frepeatint2", 22},
	{REP, string, "Fstring2", 23},
	TestChild = TestChild,
	{OPT, TestChild, "Fmessage", 24},
	{REP, TestChild, "Frepc", 25},
	{OPT, TestChild, "Fzzz", 26},
	TTT = TTT,
	{OPT, TTT, "Fzzz", 27},
}
_P.TestType = TestType
local TTT = _M{
	{OPT, sint64, "fsint64", 1},
}
_P.TTT = TTT

return _P
