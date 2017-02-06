# Description:
#   Get/set the Jargonfile word of the week!
# Commands:
#   hubot jargon set <word> - Set the current Jargon File word
#   hubot jargon get - Get the current Jargon File word
# Author:
#   Ehsan Asdar

module.exports = (robot) ->
    robot.respond /jargon set (.*)/i, (res) ->
        word = res.match[1]
        robot.http("http://www.catb.org/jargon/html/" + word[0].toUpperCase() + '/' + word + '.html')
            .get() (e, r, b) ->
                if r.statusCode isnt 200
                    res.reply "Word not found :("
                    return
                robot.brain.set 'jargonfile-word', word
                res.reply "Set #{word}"
       
    robot.respond /jargon get/i, (res) ->
        word = robot.brain.get('jargonfile-word')
        unless word?
            res.reply "No word set!"
            return
        res.reply 'The word of the week is *' +  word + '*: ' + "http://www.catb.org/jargon/html/" + word[0].toUpperCase() + '/' + word + '.html'