# Description:
#   Notifications for botgt
# Commands:
#   hubot notify <message> - notify everyone with something
#   hubot notify "@group1 ... @groupn" "#medium1 ... #mediumn" <message>  - notify certain groups with something groups and mediums are optional but order matters (do not mix groups and mediums)
# Author:
#   Jacob Zipper
module.exports = (robot) ->
  robot.respond /notify (.*)/i, (res) ->
    tokens = res.match[1].split " "
    i = 0
    groups = []
    mediums = []
    msg = []
    foundGroups = false
    foundMediums = false
    while i < tokens.length
      if !foundGroups
        if tokens[i][0] == "@"
          groups.push tokens[i].substr 1
        else
          foundGroups = true
      if foundGroups
        if !foundMediums
          if tokens[i][0] == "#"
            mediums.push tokens[i].substr 1
          else
            foundMediums = true
      if foundGroups && foundMediums
        msg.push tokens[i]
      i++
    msg = msg.join " "
    res.reply groups + " " + mediums + " " + msg
