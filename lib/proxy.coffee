config = require('../config')
fs = require('fs')
connect = require('connect')
wildcard = require('wildcard')
handlebars = require('handlebars')
httpProxy = require('http-proxy')
routingProxy = new httpProxy.RoutingProxy()

rules = []
if not fs.existsSync(config.rulesFile)
  fs.writeFileSync(config.rulesFile, "{}")

reloadRules = ->
  console.log('Reloading rule configuration')
  try
    rules = JSON.parse(fs.readFileSync(config.rulesFile, 'utf-8'))
  catch e
    console.error("Unable to parse rules file (#{config.rulesFile})")
  # Parse targets into host + port
  for rule in rules
    # Just a port or host
    if rule.target.indexOf(':') is -1
      if isNan(parseInt(rule.target))
        rule.host = rule.target
        rule.port = 80
      else
        rule.host = 'localhost'
        rule.port = parseInt(rule.target)
    else
      [ rule.host, rule.port ] = rule.target.split(':')

reloadRules()
fs.watch(config.rulesFile, reloadRules)

proxy = (req, res, next) ->
  requestedHost = req.headers['host']

  # Match tld
  if requestedHost.match(///.#{tld}$///)

    # Find matching rule
    for rule in rules
      if wildcard(rule.pattern, requestedHost)
        return routingProxy.proxyRequest req, res,
          host: rule.host
          port: rule.port
          buffer: httpProxy.buffer(req)

    # Fallback to our help page
    next()

# A help page to indicate when a domain was not found in the marathon config file
notFoundTemplate = handlebars.compile(fs.readFileSync('lib/project-not-found.hbs', 'utf-8'))
domainNotFound = (req, res, next) ->
  res.end(notFoundTemplate({rules, req}))

# A simple connect server to handle our proxy and help page
connect()
.use(proxy)
.use(domainNotFound)
.listen(config.proxyPort)