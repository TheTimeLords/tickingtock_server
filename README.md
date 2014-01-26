tickingtock_server
==================

`foreman start && open localhost:5100` to test the gui

GET /ids
  gets an array of uuids

GET /image?uuid=someId
  gets an array of image urls, sorted by date

POST /image?uuid=someId
BODY params:
   image = some image to upload
