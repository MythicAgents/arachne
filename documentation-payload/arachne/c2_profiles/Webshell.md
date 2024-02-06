+++
title = "Webshell"
chapter = false
weight = 102
+++

## Summary
Basic profile to enable linked P2P agents to communicate with a Webshell agent. This also defines how the arachne agent's payload type container will reach out directly to a webshell agent if no other agent is linked to it.

When using P2P to remotely connect to a Webshell agent, the linking agent must drop responses from Mythic. For example:

* Operator issues task `ls`
* Linking agent gets `ls` task and forwards it along to webshell agent
* Webshell agent processes message and sends output
* Linking agent forwards output to Mythic
* Mythic processes output and responds with status message
* Linking agent should now drop this message and not forward it along to the webshell agent

The reason for this is that if the linking agent doesn't eventually filter what gets sent to the webshell agent, then you'll get into an infinite loop where:
* task result isn't a tasking, so webshell responds with an empty message
* linking agent forwards it along to Mythic
* Mythic gets error message output from agent, displays it to the user, and responds with another status message
* linking agent forwards it along to webshell
* webshell doesn't know what it is, so it responds with an empty message
* etc

### Profile Options

#### user_agent
The user agent to use when connecting to the webshell-based agent.

#### cookie_name
The name of the cookie to use when authenticating to the webshell (the value is the base64 UUID of the payload).

#### query_param
The name of the query parameter to use in GET requests where the agent message will go.

#### url
The address where the webshell agent lives (ex: https://evil.com/evil.aspx).