# Description:
#   Fun HackGT Stuff
# Author:
#   Ehsan Asdar
module.exports = (robot) ->
    robot.hear /(lekha)|(lsurasani)/i, (res) ->
        robot.adapter.client.web.reactions.add("lekha-eyes", {channel: res.message.room, timestamp: res.message.id})
        robot.adapter.client.web.reactions.add("hang-in-there-lekha", {channel: res.message.room, timestamp: res.message.id})
    robot.hear /(ellie)/i, (res) ->
        robot.adapter.client.web.reactions.add("ellielaser", {channel: res.message.room, timestamp: res.message.id})
    robot.react (res) ->
        mattEmojis = ["angrymatt", "congamatt", "goofymatt", "handsomematt", "happymatt", "surprisedmatt", "youngmatt"]
        if res.message.type == "added" and res.message.reaction == "mattrandom"
            robot.adapter.client.web.reactions
            .get({channel: res.message.item.channel, timestamp: res.message.item.ts})
            .then((msg) -> 
                alreadyReacted = msg.message.reactions
                filteredList = mattEmojis.filter (item) ->
                    for emoji in alreadyReacted
                        if item == emoji.name
                            return false
                    return true
                randomChoice = filteredList[Math.floor(Math.random() * filteredList.length)]
                if randomChoice
                    robot.adapter.client.web.reactions.add(randomChoice, {channel: res.message.item.channel, timestamp: res.message.item.ts})
            )