## RTMP nginx for multi-OBS streaming
This provides a docker configuration to run a local nginx rtmp service for using
multiple instances of OBS to split out components of the stream which should are
desired to be captured and recorded in isolation.

### Setup
The basic setup is to build the docker image (and optionally tag the resultant
image for easier future interaction):

```
docker build . -t rtmp-relay
```

Set up a profile and scene collection in OBS dedicated to streaming to the RTMP
relay for each source which should be isolated.  For example, in a case where
the desired result is an isolated stream for a camera, an HDMI feed, and a
layout combining these elements which will stream to Twitch, create the
following:

 1. Scene collection called "Camera capture" containing one scene (capturing the
    camera in question)
 2. Profile called "Camera RTMP feed" set up to stream to the RTMP service (here
    assumed to be accessible at localhost via a local docker instance):
    `rtmp://localhost/stream` with a stream key of `hdmi`
 3. Scene collection called "HDMI capture" containing one scene (capturing the
    HDMI source in question)
 4. Profile called "HDMI RTMP feed" set up to stream to the RTMP service:
    `rtmp://localhost/stream` with a stream key of `hdmi`
 5. Scene collection called "Stream Layout" containing any number of scenes.
 6. Profile called "Twitch Stream" set up to stream to Twitch

### Usage
To use the docker image in order to stream via multiple obs instances, first run
the docker container with ports forwarded for rtmp usage:

```
docker run -d -p 127.0.0.1:8080:8080 -p 127.0.0.1:1935:1935 rtmp-relay:latest
```

Once the RTMP server is up and running, run an instance of OBS in multi-mode for
each profile which will be used, e.g.:

```
obs -m --profile "Camera RTMP feed" --collection "Camera capture"
obs -m --profile "HDMI RTMP feed" --collection "HDMI capture"
obs -m --profile "Twitch Stream" --collection "Stream Layout"
```

In order to capture 
Upon beginning streaming with each instance of OBS configured to use RTMP,
media source elements can be used to capture the muxed output of their feeds by
appending the stream key as an element to the path.  So, to add the HDMI feed,
a Media Source could be added to stream from `rtmp://localhost/stream/hdmi`
(assuming the above configuration of using `rtmp://localhost/stream` with the
stream key being `hdmi`).

### Automating startup
For Linux users, a convenience script is provided at `gen-desktop.rb`, which
will generate a shell script appropriate for a given user's setup and a
`.desktop` file which can be used to avoid having to use the terminal to start
up the docker container and obs instances.
