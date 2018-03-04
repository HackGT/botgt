# Description:
#   Notifications for botgt
# Commands:
#   hubot notify <message> - notify everyone with something
#   hubot notify "@group1 ... @groupn" "#medium1 ... #mediumn" <message>  - notify certain channels with something channels and mediums are optional but order matters (do not mix channels and mediums)
# Author:
#   Jacob Zipper

request = require "request-promise"
adminKey = (new Buffer process.env.BUZZER_ADMIN_KEY_SECRET).toString 'base64'
options = {
  uri: 'https://buzzer.hack.gt/graphql',
  qs: {
    query: '',
    variables: ''
  },
  headers: {
    'Authorization': 'Basic ' + adminKey
  },
  json: true
}

module.exports = (robot) ->
  robot.respond /notify (.*)/i, (res) ->
    tokens = res.match[1].split " "
    i = 0
    channels = []
    mediums = []
    msg = []
    vars = {
      msg: "",
      plugins: {}
    }
    varsTemp = {
      twitter: {},
      facebook: {},
      slack: {
        channels: [],
      },
      live_site: {}
    }
    query = 'query ($msg: String!, $plugins: PluginMaster!){send_message(message: $msg, plugins: $plugins){plugin errors {error key message}}}'
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
    varsTemp["slack"]["channels"] = channels
    for medium in mediums
      vars["plugins"][medium] = varsTemp[medium]
    options["qs"]["query"] = query
    options["qs"]["variables"] = JSON.stringify vars
    console.log JSON.stringify vars
    request options
    .then (ret) ->
      res.reply JSON.stringify ret
    .catch (err) ->
      res.reply JSON.stringify err
