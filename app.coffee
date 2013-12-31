(require 'coffee-script')
###
Module dependencies.
###
express = require("express")
http = require("http")
path = require("path")
hypem = require 'hypem-scrapper'
async = require 'async'
cors = require('cors')
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
  app.use cors()
  app.use app.router
app.use express.static(path.join(__dirname, "public"))

app.configure "development", ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  if req.query.mediaid
    redis.get req.query.mediaid, (error, reply) ->
      if reply
        res.json 200, {url: reply}
      else
        hypem.getUrl req.query.mediaid, (error, url) ->
          if url
            res.json 200, {url: url}
            redis.set req.query.mediaid, url
          else
            res.json 404, {error: 'No Url found'}
  else
    res.json 404, {error: 'No mediaid key provided'}

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
