# Description:
#   Notifications for botgt
# Commands:
#   botgt notify mediums - returns list of possible mediums
#   botgt notify help - more instructions on how to use general notifications
#   botgt notify --<option1> op1arg1 op1arg2 --<option2> op2arg1
#   botgt notify hackers - preset for slack, twitter, live site
# Author:
#   Jacob Zipper / Joel Ye

###
    TODO: fuzzy match options
    TODO: forbid repeated arguments (currently most recent args overwrites)
###

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

MEDIUMS = ['slack', 'live_site', 'twitter', 'twilio']

BUZZER_OPTIONS = ['channel', 'group', 'medium', 'message', 'end']

GRAFANA = {
  hackgtmetricsversion: 1,
  serviceName: "botgt-buzzer"
  values: {},
  tags: {}
}

PRESETS = ['hackers', 'mediums', 'help', 'approve', 'abort']

CONTROL_CHANNEL_NAME = '#hackgt5_announcements'

HELP_STR = """Available options: [channel, group, medium, message]
--channel: For slack/channel based notifiers, name of the channels you want to notify
--group: For registration group based notifiers (e.g. Twilio), name of the groups you want to notify, e.g. volunteers
--medium: specify which mediums to use
--message: Notification content here
e.g. --message Hello World --channel general tech --> "Hello World" used as --message arg for #general, #tech
    """

# Set up request
adminKey = (Buffer.from process.env.BUZZER_ADMIN_KEY_SECRET).toString 'base64'
options = {
  uri: process.env.BUZZER_URI,
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
  GRAFANA.tags.name = res.envelope.user.name
  GRAFANA.values.query = res.message.text
  GRAFANA.tags.mediums = mediums
  GRAFANA.values.message = msg
  console.log JSON.stringify GRAFANA

configToLog = (logDict) ->
  log = "Message: " + logDict.msg + "\t";
  log += "Media: " + logDict.mediums + "\t";
  if logDict.groups
    log += "Groups:" + logDict.groups + "\t";
  if logDict.channels
    log += "Channels: " + logDict.channels + "\t";
  return log

failStr = " Type botgt notify help if you need documentation for Buzzer."
doFail = (msg, res) ->
  res.reply msg + failStr

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
      res.reply "Your notification has sent successfully!" # \nHere's some debug output\n\n" + JSON.stringify ret
  .catch (err) ->
    res.reply "Due to a server error, your notification didn't send :(\nHere's some debug output\n\n" + JSON.stringify err.message

module.exports = (robot) ->

  robot.respond /notify (.*)/i, (res) ->
    msg = res.match[1]
    for preset in PRESETS
      if preset == 'mediums' || preset == 'help' || preset == 'approve' || preset == 'abort'
        continue
      if msg.trim().toLowerCase() == preset
        res.reply "Please provide a message for your command"
        return
  robot.respond /notify mediums/i, (res) ->
    res.reply MEDIUMS.join ", "
  robot.respond /notify help/i, (res) ->
    res.reply HELP_STR
  robot.respond /notify approve/i, (res) ->
    message = robot.brain.get('pending')
    if !message
      doFail 'No pending message.', res
      return
    sender = robot.brain.get('sender')
    approver = res.envelope.user.name
    if sender == approver
      doFail 'Cannot approve your own message.', res
      return
    else 
      doRequest(JSON.parse(message), res)
      robot.messageRoom CONTROL_CHANNEL_NAME, "Message approved by " + approver + ". Sending notification..."
      robot.brain.set('pending', '')
      robot.brain.set('sender', '')

  robot.respond /notify abort/i, (res) ->
    message = robot.brain.get('pending')
    if !message
      doFail 'No pending message.', res
      return
    robot.brain.set('pending', '')
    robot.brain.set('sender', '')
    aborter = res.envelope.user.name
    robot.messageRoom CONTROL_CHANNEL_NAME, "Message aborted by " + aborter

  # Presets and general below
  requestApproval = (vars, logDict, res) -> 
    pendingStr = ""
    if (robot.brain.get('pending'))
      pendingStr += '(Discarding old message) '
    pendingStr += "New notification pending. (type `botgt notify approve` or `botgt notify abort`)" 
    robot.brain.set('pending', JSON.stringify(vars))
    robot.messageRoom CONTROL_CHANNEL_NAME, pendingStr
    robot.messageRoom CONTROL_CHANNEL_NAME, configToLog(logDict)
    robot.brain.set('sender', res.envelope.user.name)

  robot.respond /notify hackers (.*)/i, (res) ->
    # Initialize hackers config
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

    logDict = {
      msg: vars.msg,
      mediums: ['slack', 'twitter', 'live_site']
    }
    # Grafana vars
    grafana(res, ['twitter', 'live_site', 'slack'], vars.msg)

    # Check for bad query
    if vars.msg.length == 0
      doFail "Please supply a message.", res
      return

    # robot.messageRoom CONTROL_CHANNEL_NAME, "[Hackers Preset]"
    requestApproval(vars, logDict, res)

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
      live_site: {},
      twilio: {
        groups: []
      }
    }

    # Iterate through tokens to parse query for channels/mediums/message    
    activeOption = null
    aggregateList = []
    logDict = {}
    tokens.push('--end') # End flag to simplify parsing, ensure final option list get parsed
    for token in tokens
      if token.length > 1 && token.substr(0, 2) == "--"
        optionStr = token.substr 2
        if not optionStr in BUZZER_OPTIONS
          doFail optionStr + " is not a valid option.", res
          return
        else 
          if activeOption # Should be impossible to have aggregate list and no option, but be safe
            switch activeOption
              when 'message' 
                vars.msg = aggregateList.join " "
                logDict.msg = vars.msg
              when 'channel' # All channel consumers here
                varsTemp.slack.channels = aggregateList
                logDict.channels = aggregateList
              when 'group' # All group consumers here
                varsTemp.twilio.groups = aggregateList
                logDict.groups = aggregateList
              when 'mediums'
                mediums = aggregateList
                logDict.mediums = aggregateList
          activeOption = optionStr
          aggregateList = []
      else
        if not activeOption
          doFail "Floating arguments.", res
          return
        aggregateList.push token
      
    # Log for Grafana
    grafana(res, mediums, vars.msg)

    # Checking for malformed query
    if vars.msg.length == 0
      doFail "Please supply a message.", res
      return
    if mediums.length == 0
      doFail "Please supply a medium. Type botgt notify mediums for a list of valid mediums.", res
      return
    for medium in mediums
      if not validMedium(medium)
        doFail medium + " is not a valid medium. Type botgt notify mediums for a list of valid mediums.", res
        return

      # Add necessary configurations to vars
      vars.plugins[medium] = varsTemp[medium]

    requestApproval(vars, logDict, res)
    