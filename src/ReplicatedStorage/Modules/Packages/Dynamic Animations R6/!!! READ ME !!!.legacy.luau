--+==+--

--+= !!! YOU NEED TO READ THIS SCRIPT TO UNDERSTAND HOW TO SET UP THE SCRIPTS SO THAT THE ANIMATIONS WORK !!! =+--

--+==+--


--+= Script Info =+--

-- Made by DarkFire_Ninja (@AwesomePeleTDM) and a lot of help from ChatGPT
-- Thank you for picking this script.
-- This is a Dynamic Animation System for R6 with Directional Movement, Camera Based Animations (Head and Torso Turn with Camera)
---- And foot placement (also called foot ik)
-- These animations are multiplayer compatible, which means you will see these animations on other players, not just your own player.
-- Link to this asset: https://create.roblox.com/store/asset/112751297190553
-- !!! IT WILL NOT WORK WITH THE NEW VERSION OF R6 WHICH USES R15 BUT JUST WITH R6 ANIMATIONS !!!

--+==+--



--+= !!! WHERE TO PUT ALL THE SCRIPTS !!! =+--

-- [AnimateWork] > StarterPlayer > StarterCharacterScripts
-- [Camera1] > StarterPlayer > StarterPlayerScripts
-- [Camera2] > ServerScriptService
-- [AnimationSettings] > ReplicatedStorage
-- [OnClient] > ReplicatedStorage
-- [OnServer] > ReplicatedStorage

--+==+--


--+= !! WHAT TO DO IF YOU HAVE CUSTOM WALKING/RUNNING ANIMATIONS !! =+--

-- The module script called AnimationSettings has a folder called animation ReversableAnimations inside of it
-- ReversableAnimations has instances inside of it.
-- If you have custom animation/s you use for walking/running (or something like that),
---- then you need to copy the AnimationId of those animations and put them into the AnimationId of the animation instances.
-- There are two animation instances by default, you can add more if you have more than two of these walking/running animations.
-- Any animation which has an ID, which is also inside of an animation instance, will get reversed when the player walks backwards,
---- This makes it look like the player is actually stepping backwards instead of moonwalking.

--+==+--



--+= !! WHAT TO DO IF YOU HAVE CUTSCENES WHICH EFFECT THE CAMERA !! =+--

-- Inside of each player's AnimateWork folder there is a value called "CameraBasedEffects",
---- All you have to do is dissable the CameraBasedEffects for the players who are going through cutscenes which effect the camera.
---- The way to dissable CameraBasedEffects is by dissabling the property called "Value" which is inside of the CameraBasedEffects.

--+==+--



--+= ! CUSTOM ANIMATIONS FOR BEST LOOKING RESULT ! =+--

-- It is recomended to use a custom walking animation with this script, because the default walking animation doesn't look great.
-- Below are some good animations I found in the toolbox
---- RUNNING ANIMATIONS: https://create.roblox.com/store/asset/87814744900538/NEW-Run-Animations-Running-Fast-R6-Rp
---- WALKING + OTHER ANIMATIONS: https://create.roblox.com/store/asset/14879742898/walkjumpfallcrouchcrouchwalk-anims



--+= ! WHAT DO ALL THE PARTS OF THIS SCRIPT DO ! =+--
-- AnimateWork >> Contains 2 scripts (MainWork and CameraWork) and a value instance (CameraBasedEffects)
-- CameraBasedEffects >> If this is enabled then the head and torso of the player moves too look where the camera is looking.
---- You can dissable CameraBasedEffects of players which are going through cutscenes so that the cutscenes look better.
---- This is because cutscenes that effect the camera will in turn effect the rotation of the player's head and torso.
-- MainWork >> Animates the local player.
-- CameraWork >> Sends Local Player's animation data to the server.
-- Camera2 >> Recieves the animation data from CameraWork and sends it off to all the other players.
-- Camera1 >> Recieves the animation data from Camera2 and animates the other players.
-- AnimationSettings >> Has variables which you can change to tweak the animations to your liking.
-- OnClient and OnServer are needed for the local sided scripts to send data to the server sided scripts.

--+==---



--+==+--