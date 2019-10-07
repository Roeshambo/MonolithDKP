if GetLocale() == "deDE" then
  local _, core = ...;
  local MonDKP = core.MonDKP;
  
  core.BossList = {
    MC = {
      "Lucifron", "Magmadar", "Gehennas",
      "Garr", "Baron Geddon", "Shazzrah", "Sulfuronherold", 
      "Golemagg der Verbrenner", "Majordomus Exekutus", "Ragnaros"
    },
    BWL = {
      "Feuerkralle der Ungezähmte", "Vaelastrasz der Verdorbene", "Brutwächter Dreschbringer",
      "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", 
      "Nefarian"
    },
    AQ = {
      "Der Prophet Skeram", "Schlachtwache Sartura", "Fankriss der Unnachgiebige",
      "Prinzessin Huhuran", "Twin Emperors", "C'Thun", 
      "Adel der Silithiden", "Viscidus", "Ouro"
    },
    NAXX = {
      "Anub'Rekhan", "Großwitwe Faerlina", "Maexxna",
      "Noth der Seuchenfürst", "Heigan der Unreine", "Loatheb", 
      "Instrukteur Razuvious", "Gothik der Ernter", "Die vier Reiter",
      "Flickwerk", "Grobbulus", "Gluth", "Thaddius",
      "Saphiron", "Kel'Thuzad"
    },
    ZG = {
      "Bloodlord Mandokir", "Gahz'ranka", "Hakkar", "High Priest Thekal", "High Priest Venoxis", "High Priestess Arlokk",
      "High Priestess Jeklik", "Jin'do the Hexxer", "High Priestess Mar'li", "Edge of Madness"
    },
    AQ20 = {
      "Ayamiss der Jäger", "Buru der Verschlinger", "General Rajaxx", "Kurinnaxx", "Moam", "Ossirian der Narbenlose"
    },
    ONYXIA = {"Onyxia"},
    WORLD = {
      "Azuregos", "Lord Kazzak", "Smariss", "Lethon", "Ysondre", "Taerar"
    }
  }

  core.ZoneList = {
    "Geschmolzener Kern", "Pechschwingenhort", "Tempel von Ahn'Qiraj", "Naxxramas", "Zul'Gurub", "Ruinen von Ahn'Qiraj", "Onyxias Versteck", "Weltbosse"
  }
end