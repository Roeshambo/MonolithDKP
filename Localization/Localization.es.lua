if GetLocale() == "esES" or GetLocale() == "esMX" then
  local _, core = ...;
  local MonDKP = core.MonDKP;
  
  core.BossList = {
    MC = {
      "Lucifron", "Magmadar", "Gehennas",
      "Garr", "Barón Geddon", "Shazzrah", "Presagista Sulfuron", 
      "Golemagg el Incinerador", "Mayordomo Executus", "Ragnaros"
    },
    BWL = {
      "Sangrevaja el Indomable", "Vaelastrasz el Corrupto", "Señor de linaje Capazote",
      "Faucefogo", "Ebonorroca", "Flamagor", "Chromaggus", 
      "Nefarian"
    },
    AQ = {
      "El profeta Skeram", "Guardia de batalla Sartura", "Fankriss el Implacable",
      "Princesa Huhuran", "Los Emperadores Gemelos", "C'Thun", 
      "Realeza silítida", "Viscidus", "Ouro"
    },
    NAXX = {
      "Anub'Rekhan", "Gran Viuda Faerlina", "Maexxna",
      "Noth el Pesteador", "Heigan el Impuro", "Loatheb", 
      "Instructor Razuvious", "Gothik el Cosechador", "Los Cuatro Jinetes",
      "Remendejo", "Grobbulus", "Gluth", "Thaddius",
      "Sapphiron", "Kel'Thuzad"
    },
    ZG = {
      "Señor sangriento Mandokir", "Gahz'ranka", "Hakkar", "Sumo sacerdote Thekal", "Sumo sacerdote Venoxis", "Suma sacerdotisa Arlokk",
      "Suma sacerdotisa Jeklik", "Jin'do el Aojador", "Suma sacerdotisa Mar'li", "Blandón de la Locura"
    },
    AQ20 = {
      "Ayamiss el Cazador", "Buru el Manducador", "General Rajaxx", "Kurinnaxx", "Moam", "Osirio el Sinmarcas"
    },
    ONYXIA = {"Onyxia"},
    WORLD = {
      "Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Ysondre", "Taerar"
    }
  }
  
  core.ZoneList = {
    "Nucleo fundido", "Guarida de alas negras", "Templo de Ahn'Qiraj", "Naxxramas", "Zul'Gurub", "Ruinas de Ahn'Qiraj", "Guarida de Onyxia", "Jefes del mundo"
  }
end