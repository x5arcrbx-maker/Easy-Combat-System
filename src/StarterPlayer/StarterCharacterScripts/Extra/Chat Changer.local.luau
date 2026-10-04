--//:SERVICES
local TextChatService = game:GetService("TextChatService")

--//:VARIABLES
local toxicWords = {
	-- General insults
	"idiot",
	"stupid",
	"dumb",
	"moron",
	"loser",
	"trash",
	"garbage",
	"pathetic",
	"clown",
	"noob",
	"mutt",
	"mut",

	-- Skill / gameplay toxicity
	"you suck",
	"bad player",
	"get better",
	"learn to play",
	"skill issue",
	"ez",
	"too easy",
	"free win",
	"carried",
	"buns",

	-- Taunting / provocation
	"cry about it",
	"stay mad",
	"cope",
	"seethe",
	"keep crying",
	"mad cuz bad",

	-- Targeted harassment
	"kill yourself",
	"kys",
	"go die",
	"nobody likes you",
	"no one cares",
	"you are useless",
	"worthless",

	-- Mocking / belittling
	"shut up",
	"shut ur mouth",
	"shut the hell up",
	"sit down",
	"sit kid",
	"child",
	"baby",

	-- Rage / hostility
	"i hate you",
	"hate this game",
	"this game is trash",
	"worst game ever",
	"devs are stupid",

	-- Bypasses / variations
	"1diot",
	"stup1d",
	"d u m b",
	"l o s e r",
	"n00b",
}

local kindWords = {	
	-- Friendly / Casual
	"gg",
	"gg wp",
	"nice",
	"cool",
	"awesome",
	"well played",
	"good luck",
	"have fun",
	
	-- Encouraging
	"Great job!",
	"Nice work!",
	"You did amazing!",
	"You're getting better!",
	"Keep it up!",
	"Don't give up!",
	"You've got this!",
	"That was impressive!",
	"I aspire to be like you someday!",

	-- Compliments
	"You're super cool.",
	"You're awesome!",
	"You're really good at this!",
	"You're super cool.",
	"You're talented!",
	"You're smart!",
	"You're cracked!",
	"You're goated!",
	"You're a legend!",
	"You're awesome!",

	-- Teamwork / Sportsmanship
	"Thanks for helping!",
	"Nice teamwork!",
	"Good call!",
	"Great strategy!",
	"We make a good team!",
	"Let's win this!",
	"Teamwork makes the dream work!",
	"We're best friends.",

	-- Friendly humor / lighthearted
	"That was funny ??",
	"Dattebayo!",
	"LOL nice one",
	"That was wild",
	"You're built different",
	"Main character energy",
	"Never back down never what?",
	"Such a sigma",
	"Spoken like a sigma",
	"Spoken like an alpha",
	"Heh ??",
	
	-- Positive vibes
	"All love",
	"Good vibes only",
	"Stay positive!",
	"Spread kindness!",
	"Peace",
	"Much respect",
	"They say treat others how you want to be treated!",

	-- Wholesome / Supportive
	"I believe in you!",
	"You matter.",
	"You're doing great.",
	"Proud of you!",
	"Keep being you!",
	"You belong here.",

	-- Fun / Roblox-style
	"W game",
	"Based",
	"Valid",
	"Common W",
	"Absolute W",
	"This game is fun!",
	"Best lobby ever",
	"This is such a fun game",
}

-- Anti-Bypass Normalization function
-- Helper
local function normalizeMessage(message: string): string
	message = string.lower(message)

	-- Replace common bypass characters
	local replacements = {
		["0"] = "o",
		["1"] = "i",
		["3"] = "e",
		["4"] = "a",
		["5"] = "s",
		["7"] = "t",
		["@"] = "a",
		["$"] = "s",
		["!"] = "i",
	}

	for char, replacement in pairs(replacements) do
		message = message:gsub(char, replacement)
	end

	-- Remove punctuation/symbols
	message = message:gsub("[^%w%s]", "")

	-- Normalize spaces
	message = message:gsub("%s+", " ")

	-- Create no-space version for spaced bypasses
	local noSpaces = message:gsub("%s+", "")

	-- Combine both versions for detection
	return message .. " " .. noSpaces
end

-- Toxicity Check  function
-- Main function
local function containsToxicWord(message: string): boolean
	local normalizedMessage = normalizeMessage(message)

	for _, word in ipairs(toxicWords) do
		if string.find(normalizedMessage, word, 1, true) then
			return true
		end
	end

	return false
end

-- Chat Interception
TextChatService.OnIncomingMessage = function(message)
	if containsToxicWord(message.Text) then
		local overrideProperties = Instance.new("TextChatMessageProperties")
		overrideProperties.Text = kindWords[math.random(1, #kindWords)]
		return overrideProperties
	end

	return nil
end --End of OnIncomingMessage
