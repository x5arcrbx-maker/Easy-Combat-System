local ContentProvider = game:GetService("ContentProvider")

local FX_folder = game:GetService("ReplicatedStorage"):WaitForChild("FX") :: Folder
ContentProvider:PreloadAsync(FX_folder:GetDescendants())

local MaterialService = game:GetService("MaterialService")
ContentProvider:PreloadAsync(MaterialService:GetDescendants())
