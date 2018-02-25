# Description:
#   Notifications for botgt
# Commands:
#   hubot notify <message> - notify everyone with something
#   hubot notify "@group1 ... @groupn" "#medium1 ... #mediumn" <message>  - notify certain groups with something groups and mediums are optional but order matters (do not mix groups and mediums)
# Author:
#   Jacob Zipper

gqlReq = require "graphql-request"

query = '{
  send_message(message: ${msg}, plugins: {
    console: {
      groups: ${groups}
    }
  })
  {
    console {
      error
      key
      message
    }
  }
}'

vars = {
  "msg": null,
  "groups": null
}

processTemplateStr = (template, vars) ->
  Object.keys vars
  .forEach (key) ->
    template = template.replace "${" + key + "}", JSON.stringify vars[key]
  return template

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
    vars["msg"] = msg
    vars["groups"] = groups
    query = processTemplateStr query, vars
    gqlReq.request "http://localhost:3000/graphql", query
    .then (ret) ->
      res.reply ret["send_message"]["console"]["message"]
