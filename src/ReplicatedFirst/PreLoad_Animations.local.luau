local ContentProvider = game:GetService("ContentProvider")

local animationsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Animations") :: Folder -- Example folder
ContentProvider:PreloadAsync(animationsFolder:GetDescendants())
