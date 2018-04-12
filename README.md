# Color slide tutorial

Welcome to the Colorslide game tutorial where you will learn how to build a GUI flow for a multi level game. This tutorial assumes that you know your way around the editor. Please check out one of our beginner tutorials if you are new to Defold and want to learn the basics.

The starting point for this tutorial is this project that contains the following:

- A simple but fully playable game where the player needs to slide the bricks to the correct position.
- 4 levels included of various difficulty. Each level is built in its own collection.
- Assets so you can build any number of levels, using the built in tile editor.
- The bricks have some personality coded into them.
- When the player completes a level, the bricks jump happily and the player cannot slide them anymore.

What you will do in this tutorial is the following:

- Add a start screen.
- Add a level selection screen allowing the player to select and play any of the 4 levels.
- Add navigation buttons between the screens.

Start by [trying the game](defold://build), then open ["main.collection"](defold://open?path=/main/main.collection) to see how the game is set up.

<img src="doc/main_collection.png" srcset="doc/main_collection@2x.png 2x">

The whole game is contained in the subcollection inside "main.collection". Currently, "level" references the file "/main/level_2/level_2.collection". Inside the subcollection are two game objects:

1. One game object (with id "board") holds the tilemap. Notice that there are two layers on the tilemap, one is the actual playfield ("board") and one contains the intitial setup for the bricks ("setup"). The game clears "setup" on start and replaces the brick tiles with separate game objects that can be animated freely.

2. One game object (with id "level") contains the game logic script and a factory used to spawn bricks on game start. This game object is stored in a separate file called "/main/level.go" so it can be referenced in each separate level.

Now mark "level" in "main.collection" and change its reference in the *Path* property to "/main/level_3/level_3.collection". Build and run the game again (<kbd>Project ▸ Build</kbd>) and try playing that level.

## Loading collections via proxy

What you need is a way to select what collection to load and play during runtime. Defold contains two mechanisms for loading collections dynamically:

1. Collection factories. This is a good choice for spawning hierarchies of objects into a running game. Any spawned object will be part of the startup main collection world and live until the game shuts down, unless you explicitly delete the objects yourself.

2. Collection proxies. This is a good choice when you want to load larger chunks of a game dynamically, for instance a game level. With a proxy you create a new "world" based on the collection. Any object that is spawned from the collection content will be part of the created world and be destroyed when the collection is unloaded from the proxy. The new world comes with an overhead so you should not use proxies to load many collections simultaneously.

For this game, proxies will be the best choice.

Open "main.collection" and remove the "level" collection reference. Instead, add a new game object and give it id "loader".

Add a collection proxy component to the game object and set its *Collection* property to "/main/level_1/level_1.collection".

Add a new script file called "loader.script" and add it as a script component to the "loader" game object.

<img src="doc/main_proxy.png" srcset="doc/main_proxy@2x.png 2x">

Open "loader.script" and change its content to the following:

```lua
function init(self)
    msg.post("#proxy_level_1", "load")                      -- [1]
end

function on_message(self, message_id, message, sender)
    if message_id == hash("proxy_loaded") then              -- [2]
        msg.post(sender, "init")
        msg.post(sender, "enable")
    end
end
```
1. Send a message to the proxy component telling it to load its collection.
2. When the proxy component is done loading, it sends a "proxy_loaded" message back, then it is fine to init and enable the collection. These messages can be sent to "sender" which is the proxy component.

Now try to run the game.

Unfortunately there is an instant error in the console:

```
ERROR:GAMEOBJECT: The collection 'default' could not be created since there is already a socket with the same name.
WARNING:RESOURCE: Unable to create resource: /main/level_1/level_1.collectionc
ERROR:GAMESYS: The collection /main/level_1/level_1.collectionc could not be loaded.
```

The error occurs because the proxy tries to create a new world (socket) named "default". One such world already exists - the one created from "main.collection" att engine boot. The socket name is set in the properties of the collection root so it's easy to fix:

<img src="doc/socket_name.png" srcset="doc/socket_name@2x.png 2x">

Open the file "/main/level_1/level_1.collection", mark the root of the collection and set the *Id* property to "level_1". Save the file.

Try try running the game again.

The level should show up, but if you try to click on the board and move a tile, nothing happens. Why?

The problem is that the script that deals with input is now inside the proxied world. The input system works so that it sends input to game objects in the bootstrap collection that listens to input. If one of these listeners contains a proxy, input is directed to any listeners in the collection behind the proxy. So in order to get input into the proxy collection, simply add a line to the loader script's `init()` function:

```
function init(self)
    msg.post("#proxy_level_1", "load")
    msg.post(".", "acquire_input_focus")                -- [1]
end
```
1. Since this game object holds the proxy for the collection that needs input, this game object needs to acquire input focus too.

Run the game again. Now everything should work as expected.

The game contains four levels so you need to add proxies for the remaining three levels. That is a matter of just repeating what you just did. Don't forget to change the *Id* property to a unique name for each level collection.

<img src="doc/main_proxies.png" srcset="doc/main_proxies@2x.png 2x">

Test each level by altering the proxy component you send the "load" message (`msg.post("#proxy_level_2", "load")` for instance) before moving on.

## The level selection screen

Now you have the setup required to load any level and it is time to construct an interface to the level loading.

Create a new GUI file and call it "level_select.gui".

Add "headings" to the *Font* section and the "bricks" atlas to the *Textures* section of the gui.

Construct an interface with 4 buttons, one for each level. It's practical to create one root node for each button and put the graphics and text as children to each root node:

<img src="doc/level_select.png" srcset="doc/level_select@2x.png 2x">

Create a new GUI script file and call it "level_select.gui_script".

Open "level_select.gui" and set the *Script* property on the root node to the new script.

Open "level_select.gui_script" and change the script to the following:

```lua
function init(self)
    msg.post("#", "show_select_level")                                  -- [1]
end

function on_message(self, message_id, message, sender)
    if message_id == hash("show_select_level") then                     -- [2]
        msg.post(".", "acquire_input_focus")
        msg.post(".", "enable")
    elseif message_id == hash("hide_select_level") then                 -- [2]
        msg.post(".", "release_input_focus")
        msg.post(".", "disable")
    end
end

function on_input(self, action_id, action)
    if action_id == hash("touch") and action.pressed then               -- [3]
        for n = 1,4 do                                                  -- [4]
            local node = gui.get_node("level_" .. n)
            if gui.pick_node(node, action.x, action.y) then             -- [5]
                msg.post("/loader#loader", "load_level", { level = n }) -- [6]
                msg.post("#", "hide_select_level")                      -- [7]
            end
        end
    end
end
```
1. Set up the GUI.
2. Showing and hiding the gui is triggered via messaging so it can be done from other scripts.
3. React to the pressing of touch input (as set up in the input bindings).
4. The button nodes are named "level_1" to "level_4" so you can loop this.
5. Check if the touch action happens within the boundaries of level_n, i.e. the button is pressed.
6. Send a message to the loader script to load level n. Notice that a "load" message is not sent directly to the proxy from here since this script does not deal with the rest of the proxy loading logic (reaction to "proxy_loaded).
7. Hide this GUI.

The loader script needs a bit of new code to react to the "load_level" message. Open "loader.script" and change the `on_message()` function:

```lua
function on_message(self, message_id, message, sender)
    if message_id == hash("load_level") then
        local proxy = "#proxy_level_" .. message.level                  -- [1]
        msg.post(proxy, "load")
    elseif message_id == hash("proxy_loaded") then
        msg.post(sender, "init")
        msg.post(sender, "enable")
    end
end
```
1. Construct which proxy to load based on message data.

Run the game and test the flow. You should be able to click any of the level buttons and the corresponding level will load and be playable.



----

Check out [the documentation pages](https://defold.com/learn) for examples, tutorials, manuals and API docs.

If you run into trouble, help is available in [our forum](https://forum.defold.com).

Happy Defolding!

---