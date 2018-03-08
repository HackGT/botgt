# Description:
#   Notifications for botgt
# Commands:
#   hubot notify #channel1 ... #channeln !medium1 ... !mediumn <message>  - notify certain channels with something channels and mediums are optional but order matters (do not mix channels and mediums)
#   hubot notify mediums
# Author:
#   Jacob Zipper

request = require "request-promise"

# CONSTANTS
QUERY = """
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

MEDIUMS = ['slack', 'live_site', 'twitter']

GRAFANA = {
  hackgtmetricsversion: 1,
  serviceName: "botgt-buzzer"
  values: {},
  tags: {}
}

PRESETS = ['buildgt', 'mediums']

# Set up request
adminKey = (Buffer.from process.env.BUZZER_ADMIN_KEY_SECRET).toString 'base64'
options = {
  uri: 'https://buzzer.hack.gt/graphql',
  qs: {
    query: QUERY,
    variables: ''
  },
  headers: {
    'Authorization': 'Basic ' + adminKey
  },
  json: true
}

validMedium = (medium) ->
  return medium in MEDIUMS

grafana = (res, mediums, msg) ->
  GRAFANA.tags.name = res.message.user.name
  GRAFANA.values.query = res.message.text
  GRAFANA.tags.mediums = mediums
  GRAFANA.values.message = msg
  console.log JSON.stringify GRAFANA

doRequest = (vars, res) ->
  options.qs.variables = JSON.stringify vars
  request options
  .then (ret) ->
    errored = false
    for plugin in ret.data.send_message
      for errors in plugin.errors
        if errors.error
          errored = true
          res.reply "There was an error with " + plugin.plugin + "\n" + errors.message
    if ret.errors != undefined
      res.reply "There were some graphql errors"
      for error in ret.errors
        res.reply error.message
      res.reply "Here is some debug output\n\n" + JSON.stringify ret
    else if not errored
      res.reply "Your notification has sent successfully!\nHere's some debug output\n\n" + JSON.stringify ret
  .catch (err) ->
    res.reply "Due to a server error, your notification didn't send :(\nHere's some debug output\n\n" + JSON.stringify err

module.exports = (robot) ->

  robot.respond /notify (.*)/i, (res) ->
    msg = res.match[1]
    for preset in PRESETS
      if preset == 'mediums'
        continue
      if msg.trim().lower() == preset
        res.reply "Please provide a message for your command"
        return
  robot.respond /notify mediums/i, (res) ->
    res.reply MEDIUMS.join ", "

  robot.respond /notify buildgt (.*)/i, (res) ->
    # Initialize buildgt config
    vars = {
      msg: res.match[1],
      plugins: {
        twitter: {}
        live_site: {}
        slack: {
          at_channel: true,
          at_here: false,
          channels: []
        }
      }
    }

    # Grafana vars
    grafana(res, ['twitter', 'live_site', 'slack'], vars.msg)


    # Check for bad query
    if vars.msg.length == 0
      res.reply "Please supply a message.\nType botgt help if you need documentation for the bot."
      return

    # Do the request
    doRequest(vars, res)

  robot.respond /notify (.*)/i, (res) ->

    # Tokenize query
    tokens = res.match[1].split " "

    if tokens[0] in PRESETS
      return
    # Initialize necessary variables for processing query
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
        at_channel: true,
        at_here: false,
      },
      live_site: {}
    }
    foundChannels = false
    foundMediums = false

    # Iterate through tokens to parse query for channels/mediums/message
    for token in tokens
      if !foundChannels
        if token[0] == "#"
          varsTemp.slack.channels.push token.substr 1
        else
          foundChannels = true
      if foundChannels && !foundMediums
        if token[0] == "!"
          mediums.push token.substr 1
        else
          foundMediums = true
      if foundChannels && foundMediums
        vars.msg.push token
    vars.msg = vars.msg.join " "

    # Log for Grafana
    grafana(res, mediums, vars.msg)

    # Checking for malformed query
    if vars.msg.length == 0
      res.reply "Please supply a message.\nType botgt help if you need documentation for the bot."
      return
    if mediums.length == 0
      res.reply "Please supply a medium.\nType botgt notify mediums for a list of valid mediums.\nType botgt help if you need documentation for the bot."
      return
    for medium in mediums
      if not validMedium(medium)
        res.reply medium + " is not a valid medium.\nType botgt notify mediums for a list of valid mediums.\nType botgt help if you need documentation for the bot."
        return

      # Add necessary configurations to vars
      vars.plugins[medium] = varsTemp[medium]

    doRequest(vars, res)