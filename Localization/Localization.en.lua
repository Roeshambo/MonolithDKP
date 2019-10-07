if GetLocale() == "enUS" or GetLocale() == "enGB" then
  local _, core = ...;
  local MonDKP = core.MonDKP;
  
  core.BossList = {
    MC = {
      "Lucifron", "Magmadar", "Gehennas",
      "Garr", "Baron Geddon", "Shazzrah", "Sulfuron Harbinger", 
      "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros"
    },
    BWL = {
      "Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer",
      "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", 
      "Nefarian"
    },
    AQ = {
      "The Prophet Skeram", "Battleguard Sartura", "Fankriss the Unyielding",
      "Princess Huhuran", "Twin Emperors", "C'Thun", 
      "Bug Family", "Viscidus", "Ouro"
    },
    NAXX = {
      "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna",
      "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", 
      "Instructor Razuvious", "Gothik the Harvester", "The Four Horsemen",
      "Patchwerk", "Grobbulus", "Gluth", "Thaddius",
      "Sapphiron", "Kel'Thuzad"
    },
    ZG = {
      "Bloodlord Mandokir", "Gahz'ranka", "Hakkar", "High Priest Thekal", "High Priest Venoxis", "High Priestess Arlokk",
      "High Priestess Jeklik", "Jin'do the Hexxer", "High Priestess Mar'li", "Edge of Madness"
    },
    AQ20 = {
      "Ayamiss the Hunter", "Buru the Gorger", "General Rajaxx", "Kurinnaxx", "Moam", "Ossirian the Unscarred"
    },
    ONYXIA = {"Onyxia"},
    WORLD = {
      "Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Ysondre", "Taerar"
    }
  }
  
  core.ZoneList = {
    "Molten Core", "Blackwing Lair", "Temple of Ahn'Qiraj", "Naxxramas", "Zul'Gurub", "Ruins of Ahn'Qiraj", "Onyxia's Lair", "World Bosses"
  }
end