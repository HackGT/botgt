# Description:
#   Get time left till HackGT
# Commands:
#   hubot countdown - Get countdown
# Author:
#   Ehsan Asdar
module.exports = (robot) ->
    robot.respond /countdown/i, (res) ->
        now = new Date()
        eventTime = new Date("2020-10-16T21:00:00Z")
        delta = Math.abs(eventTime.getTime() - now.getTime())/1000
        days = Math.floor(delta / 86400);
        delta -= days * 86400;

        hours = Math.floor(delta / 3600) % 24;
        delta -= hours * 3600;

        minutes = Math.floor(delta / 60) % 60;
        delta -= minutes * 60;
        seconds = delta % 60;   
        res.reply "#{days} days, #{hours} hours and #{minutes} minutes left till HackGT 7! :thisisfine: :ehsandb:"
