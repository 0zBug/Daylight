import asyncio, websockets

discord_socket, client_socket = None, None
gateway = "wss://gateway.discord.gg/?v=8&encoding=json"

async def listener(socket: websockets.WebSocketClientProtocol, path):
    global client_socket, discord_socket
    client_socket = socket

    if discord_socket != None:
        await socket.close()
        return
      
    asyncio.get_event_loop().create_task(sender())
    while not discord_socket: await asyncio.sleep(1)

    while True:
        try:
            message = await socket.recv()
            await discord_socket.send(message)
        except Exception as e:
            await discord_socket.close()
            discord_socket = None
            break

async def sender():
    global discord_socket
    async with websockets.connect(gateway) as socket:
        discord_socket = socket
        while True:
            try:
                message = await socket.recv()
                await client_socket.send(message)
            except Exception as e:
                break

asyncio.get_event_loop().run_until_complete(websockets.serve(listener, "localhost", 8787))
asyncio.get_event_loop().run_forever()
