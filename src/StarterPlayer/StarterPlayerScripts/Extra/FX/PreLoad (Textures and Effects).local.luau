local ContentProvider = game:GetService("ContentProvider")

local VfxFolder = game:GetService("ReplicatedStorage").FX.VFX :: Folder
ContentProvider:PreloadAsync(VfxFolder:GetDescendants())

local materialsFolder = game:GetService("MaterialService")["Ultimate Material Pack (PBR 8K)"] :: Folder
ContentProvider:PreloadAsync(materialsFolder:GetDescendants())


