util = require 'util'
restify = require 'restify'
toobusy = require 'toobusy'

# MongoDB setup
Mongolian = require 'mongolian'
mongolian = new Mongolian
ObjectId = Mongolian.ObjectId
ObjectId.prototype.toJSON = ObjectId.prototype.toString
db = mongolian.db 'tickingtock'
images = db.collection 'images'

_check_if_busy = (req, res, next) ->
  if toobusy()
    res.send 503, "I'm busy right now, sorry."
  else next()

server = restify.createServer()
server.pre restify.pre.userAgentConnection()
server.use _check_if_busy
server.use restify.queryParser()
server.use restify.acceptParser server.acceptable # respond correctly to accept headers
server.use restify.bodyParser uploadDir: 'public/uploads', keepExtensions: true
server.use restify.fullResponse() # set CORS, eTag, other common headers

newImage = (req, res, next) ->
  uuid = req.params.uuid
  prompt = req.params.prompt
  path = req.files.image.path.split('/')[1...].join('/')
  date = new Date()

  console.log {uuid, prompt, path, date}

  images.insert {uuid, prompt, path, date}, (err, doc) ->
    res.send doc

getImage = (req, res, next) ->
  uuid = req.params.uuid
  console.log uuid
  images.find({uuid}).sort({date:-1}).toArray (err, body) ->
    res.send body

###
  API
###
server.post "/image", newImage
server.get "/image", getImage
server.get '.*', restify.serveStatic directory: './public', default: 'index.html'

server.listen process.env.PORT or 8081, ->
  console.log "[%s] #{server.name} listening at #{server.url}", process.pid