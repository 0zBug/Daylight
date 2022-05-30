# Daylight
**A module to create a simple discord bot in lua. Since most exploits don't support the wss websocket protocol you will have to use wss.py to use the module.**

# Documentation
### Start
**Start a connection between your bot and discord.**
```html
<void> Daylight:Start(<string> Token)
```
### Close
**Closes the connection between your bot and discord.**
``` html
<void> Daylight:Close(<void)
```
### Connect
**Connects the the specified event**
```html
<void> Daylight:Connect(<string> Event, <function> Callback)
```
