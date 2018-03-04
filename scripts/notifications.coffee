# Description:
#   Notifications for botgt
# Commands:
#   hubot notify <message> - notify everyone with something
#   hubot notify #channel1 ... #channeln !medium1 ... !mediumn <message>  - notify certain channels with something channels and mediums are optional but order matters (do not mix channels and mediums)
# Author:
#   Jacob Zipper

request = require "request-promise"
adminKey = (Buffer.from process.env.BUZZER_ADMIN_KEY_SECRET).toString 'base64'
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
    mediums = []
    vars = {
      msg: [],
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
    query = """
    query ($msg: String!, $plugins: PluginMaster!) {
      send_message(message: $msg, plugins: $plugins) {
        plugin
        errors {
          error
          key
          message
        }
      }
    }
    """
    foundChannels = false
    foundMediums = false
    for i in [0 ... tokens.length]
      if !foundChannels
        if tokens[i][0] == "#"
          varsTemp.slack.channels.push tokens[i].substr 1
        else
          foundChannels = true
      if foundChannels && !foundMediums
        if tokens[i][0] == "!"
          mediums.push tokens[i].substr 1
        else
          foundMediums = true
      if foundChannels && foundMediums
        vars.msg.push tokens[i]
      i++
    vars.msg = vars.msg.join " "
    for medium in mediums
      vars.plugins[medium] = varsTemp[medium]
    options.qs.query = query
    options.qs.variables = JSON.stringify vars
    console.log JSON.stringify vars
    request options
    .then (ret) ->
      res.reply "Your notification has sent! Here's some debug output.\n\n" + JSON.stringify ret
    .catch (err) ->
      res.reply "Your notification didn't send :(. Here's some debug output.\n\n" + JSON.stringify err
