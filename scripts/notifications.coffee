# Description:
#   Notifications for botgt
# Commands:
#   hubot notify <message> - notify everyone with something
#   hubot notify "@group1 ... @groupn" "#medium1 ... #mediumn" <message>  - notify certain channels with something channels and mediums are optional but order matters (do not mix channels and mediums)
# Author:
#   Jacob Zipper

gqlReq = require "graphql-request"
adminKey = (new Buffer process.env.BUZZER_ADMIN_KEY_SECRET).toString 'base64'
client = new gqlReq.GraphQLClient("http://buzzer.hack.gt/graphql", {
  headers: {
    Authorization: adminKey,
  },
})



module.exports = (robot) ->
  robot.respond /notify (.*)/i, (res) ->
    tokens = res.match[1].split " "
    i = 0
    channels = []
    mediums = []
    msg = []
    vars = {
      msg: "",
      mediums: [],
      twitterConfig: {},
      facebookConfig: {},
      slackConfig: {
        channels: [],
      },
      livesiteConfig: {}
    }
    query = '{
      send_message(message: $msg, plugins: {\n'
    midQuery = '
      })
      {\n'
    pluginReturn = ' {\nerror\nkey\nmessage\n}'
    endQuery = '}\n}'
    foundChannels = false
    foundMediums = false
    while i < tokens.length
      if !foundChannels
        if tokens[i][0] == "@"
          channels.push tokens[i].substr 1
        else
          foundChannels = true
      if foundChannels
        if !foundMediums
          if tokens[i][0] == "#"
            mediums.push tokens[i].substr 1
          else
            foundMediums = true
      if foundChannels && foundMediums
        msg.push tokens[i]
      i++
    msg = msg.join " "
    vars["msg"] = msg
    vars["slackConfig"]["channels"] = channels
    for medium in mediums
      query += medium + ": $" + medium + "Config,\n"
    if mediums.length != 0
      query = query.slice 0, query.length - 2
      query += '\n'
    query += midQuery
    for m in mediums
      query += m + pluginReturn + ",\n"
    if mediums.length != 0
      query = query.slice 0, query.length - 2
      query += '\n'
    query += endQuery
    console.log query
    console.log vars
    client.request query, vars
    .then (ret) ->
      res.reply ret["send_message"]["console"]["message"]
