# Description:
#   Fun HackGT Stuff
# Author:
#   Ehsan Asdar
module.exports = (robot) ->
    robot.hear /(lekha)|(lsurasani)/i, (res) ->
        robot.adapter.client.web.reactions.add("lekha-eyes", {channel: res.message.room, timestamp: res.message.id})
        robot.adapter.client.web.reactions.add("hang-in-there-lekha", {channel: res.message.room, timestamp: res.message.id})
