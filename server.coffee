util = require 'util'
restify = require 'restify'
swagger = require 'swagger-doc'
toobusy = require 'toobusy'
fs = require 'fs'
async = require 'async'

# MongoDB setup
Mongolian = require 'mongolian'
mongolian = new Mongolian
ObjectId = Mongolian.ObjectId
ObjectId.prototype.toJSON = ObjectId.prototype.toString
db = mongolian.db 'tickingtock'

# Collections
images = db.collection 'images'

_check_if_busy = (req, res, next) ->
  if toobusy()
    res.send 503, "I'm busy right now, sorry."
  else next()

_exists = (item, cb) -> cb item?

server = restify.createServer()
server.pre restify.pre.userAgentConnection()
server.use _check_if_busy
server.use restify.queryParser()
server.use restify.acceptParser server.acceptable # respond correctly to accept headers
server.use restify.bodyParser uploadDir: 'public/uploads', keepExtensions: true
server.use restify.fullResponse() # set CORS, eTag, other common headers

newImage = (req, res, next) ->
  console.log util.inspect req
  uuid = req.params.uuid
  prompt = req.params.prompt
  path = req.files.image.path.split('/')[1...].join('/')
  image = req.headers.host + '/' + path
  date = new Date()

  console.log {uuid, prompt, image, date}

  images.insert {uuid, prompt, image, date}, (err, doc) ->
    console.log err if err
    console.log doc
    res.send doc

getImage = (req, res, next) ->
  console.log 'GET'
  uuid = req.query.uuid
  prompt = req.query.prompt
  async.filter {uuid, prompt}, _exists, (filtered) ->
    images.find(filtered).sort({date:1}).toArray (err, body) ->
      res.send body

###
  API
###
swagger.configure server
server.post "/image", newImage
server.get "/image", getImage

###
  Documentation
###
docs = swagger.createResource '/doc'
docs.get "/image", "Get images",
  nickname: "getImage"
  parameters: [
    { name: 'uuid', description: 'uuid for who', required: true, dataType: 'string', paramType: 'query' }
  ]
docs.post "/image", "Upload a new image",
  nickname: "newImage"
  parameters: [
    { name: 'uuid', description: 'uuid', required: true, dataType: 'string', paramType: 'body' }
    { name: 'prompt', description: 'what prompted this image?', required: true, dataType: 'string', paramType: 'body'}
    { name: 'image', description: 'the photo', required: true, dataType: 'file', paramType: 'body' }
  ]

server.get '.*', restify.serveStatic directory: './public', default: 'index.html'

server.listen process.env.PORT or 8081, ->
  console.log "[%s] #{server.name} listening at #{server.url}", process.pid