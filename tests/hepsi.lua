-- tests/hepsi.lua
-- Bütün testleri çalıştırır. Repo kökünden:  luajit tests/hepsi.lua

local T = dofile("tests/yardimci.lua")

dofile("tests/atlas_test.lua")
dofile("tests/planlayici_test.lua")
dofile("tests/adaptor_test.lua")

T.ozet()
