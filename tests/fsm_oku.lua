-- tests/fsm_oku.lua
-- Hocanın Util.toGraph() yönteminin karşılığı: .fsm dosyasını grafa çevirir.
-- Satır biçimi:  durum -- girdi / çıktı -> sonrakiDurum     (ör. "0 -- 1 / 0 -> 1")
-- Kaynağı 0 olan kenarlar başlangıç kenarıdır.

return function(ns, dosya)
    local graf = ns.Graf.yeni()
    for satir in io.lines(dosya) do
        local durum, girdi, cikti, sonraki = satir:match("^(%d+)%s%-%-%s(%d+)%s/%s(%d+)%s%->%s(%d+)")
        if durum then
            durum, girdi, cikti, sonraki = tonumber(durum), tonumber(girdi), tonumber(cikti), tonumber(sonraki)
            local etiket = graf:kenarEkle(durum, sonraki, girdi, cikti, 1)
            if durum == 0 then
                graf:baslangicEkle(etiket)
            end
        end
    end
    return graf
end
