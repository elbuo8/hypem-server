
###
Module dependencies.
###
express = require("express")
http = require("http")
path = require("path")
hypem = require 'hypem-scrapper'
app = express()


rtg = require("url").parse process.env.REDISTOGO_URL
redis = (require "redis").createClient rtg.port, rtg.hostname
redis.auth rtg.auth.split(":")[1]

app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(path.join(__dirname, "public"))

app.configure "development", ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  redis.get req.query.metaid, (error, reply) ->
    if reply
      res.send reply
    else
      hypem.getUrl req.query.metaid, (error, url) ->
        if url
          res.send url
          redis.set req.query.metaid, url
        else
          res.send error

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
