local ContentProvider = game:GetService("ContentProvider")

local animationsFolder = game:GetService("ReplicatedStorage").Animations :: Folder -- Example folder
ContentProvider:PreloadAsync(animationsFolder:GetDescendants())
