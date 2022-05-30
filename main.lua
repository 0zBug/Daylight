
local Client = {}

local Callbacks = {}
local Socket, Connected

local HttpService = game:GetService("HttpService")

local function Endpoint(Method, Path, Data)
    local Request = Method == "GET" and {
        Method = Method,
        Url = "https://discord.com/api/v8" .. Path,
        Headers = {
            ["Authorization"] = "Bot " .. Client.token
        }
    } or {
        Method = Method,
        Url = "https://discord.com/api/v8" .. Path,
        Body = HttpService:JSONEncode(Data),
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bot " .. Client.token
        }
    }

    return HttpService:JSONDecode(syn.request(Request).Body)
end

local Classes
Classes = {
    ["User"] = function(User)
        if tonumber(User) then
            return Endpoint("GET", "/users/" .. User)
        end
    
        return User
    end,
    ["Channel"] = function(Channel)
        if tonumber(Channel) then
            return Classes.Channel(Endpoint("GET", "/channels/" .. Channel))
        end

        function Channel:Send(Message, Embed, TTS)
            return Classes.Message(Endpoint("POST", "/channels/" .. self.id .. "/messages", {
                content = Message,
                tts = TTS,
                embed = Embed
            }))
        end
    
        return Channel
    end,
    ["Message"] = function(Message, Channel)
        if Message.r then
            local message = Endpoint("GET", "/channels/" .. Message.channel .. "/messages/" .. Message.message)
            return Classes.Message(message, Channel)
        end
    
        Message.id = Message.guild_id
        Message.channel = Channel or Classes.Channel(Message.channel_id)
        Message.author = Classes.User(Message.author)

        return Message
    end
}

local Listeners = {
    ["READY"] = {
        Name = "Connected",
        Callback = true
    },
    ["MESSAGE_CREATE"] = {
        Name = "Message",
        Callback = function(Data, Callback)
            Callback(Classes.Message(Data))
        end
    }
}

function Client:Start(Token)
    Socket = syn.websocket.connect("ws://localhost:8787")
    self.token = Token

    Socket.OnMessage:Connect(function(Message)
        local Payload = HttpService:JSONDecode(Message)
        
        coroutine.resume(coroutine.create(function()
            if Payload.op == 0 then
                local Listener = Listeners[Payload.t]

                if Listener then
                    if Listener.Callback == true then 
                        if Callbacks[Listener.Name] then
                            for _, Callback in pairs(Callbacks[Listener.Name]) do
                                coroutine.resume(coroutine.create(function()
                                    Callback()
                                end))
                            end
                        end
                    else
                        Listener.Callback(Payload.d, function(...)
                            if Callbacks[Listener.Name] then
                                local args = {...}

                                for _, Callback in pairs(Callbacks[Listener.Name]) do
                                    coroutine.resume(coroutine.create(function()
                                        Callback(unpack(args))
                                    end))
                                end
                            end
                        end)
                    end
                end
            elseif Payload.op == 10 then
                Socket:Send(HttpService:JSONEncode({
                    op = 2,
                    d = {
                        token = Client.token,
                        intents = 513,
                        properties = {
                            ["$os"] = "win",
                            ["$browser"] = "roblox",
                            ["$device"] = "roblox"
                        },
                        compress = false,
                        shard = {0, 1}
                    }
                }))

                Connected = true
                spawn(function()
                    while wait(35) and Connected do
                        Socket:Send(HttpService:JSONEncode({
                            op = 1,
                            d = Payload.s or function() end
                        }))
                    end
                end)
            end
        end))
    end)

    Socket.OnClose:Connect(function()
        Connected = false
    end)
end

function Client:Close()
    Socket:Close()
end

function Client:Connect(Event, Callback)
    local Connections = Callbacks[Event]

    if not EventCallback then
        Callbacks[Event] = {}
        Connections = Callbacks[Event]
    end

    table.insert(Connections, Callback)
end

return Client
