# Description:
#   Notifications for botgt
# Commands:
#   hubot notify <message> - notify everyone with something
#   hubot notify "@group1 ... @groupn" <message>  - notify certain groups with something
# Author:
#   Jacob Zipper
module.exports = (robot) ->
  robot.respond /notify (.*)/i, (res) ->
    tokens = res.match[1].split " "
    i = 0
    groups = []
    msg = []
    foundGroups = false
    while i < tokens.length
      if !foundGroups
        if tokens[i][0] == "@"
          groups.push tokens[i].substr 1
        else
          foundGroups = true
      if foundGroups
        msg.push tokens[i]
      i++
    res.reply groups + " " + msg.join " "
