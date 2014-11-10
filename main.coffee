express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
expressSession = require 'express-session'
# expressLogger = require 'express-logger'
passport = require 'passport'
localStrategy = require('passport-local').Strategy
mu = require './mysql-utils.coffee'

app = do express

templateid_to_str = (entity_templateid) ->
	switch
		when entity_templateid == 20 then 'Печать'
		when entity_templateid == 21 then 'Ламинация'
		else ''

param_by_variant = (params, param_variantid) ->
	for param in params
		if param.entity_param_variantid = param_variantid
			return param
	return

app.disable 'x-powered-by'
app.set 'view engine', 'jade'
app.use express.static __dirname + '/public'
app.use bodyParser.urlencoded
	extended: false
app.use do cookieParser
app.use expressSession
	secret: process.env.SESSION_SECRET || 'so secret'
	resave: false
	saveUninitialized: false
app.use do passport.initialize
app.use do passport.session
# app.use expressLogger
# 	path: 'log'

passport.serializeUser (user, done) ->
	console.log 'serialize'
	console.log user
	done null, user.id

passport.deserializeUser (id, done) ->
	console.log 'deser'
	mu.find_user_by_id id, (user) ->
		done null, user

ensureAuthenticated = (req, res, next) ->
	if do req.isAuthenticated
		do next
	else
		res.redirect '/login'

passport.use new localStrategy((username, password, done) ->
	console.log 'strategy'
	mu.find_user username, password, (user) ->
		done null, user
)

app.get '/', (req, res) ->
	mu.get_entities (entities) -> 
		for entity in entities
			entity.act_type = templateid_to_str entity.entity_templateid
		script = ['/js/utils.js']
		res.render 'main', 
			entities: entities
			script: script
			isAuthenticated: do req.isAuthenticated
			user: req.user

app.get '/login', (req, res) ->
	res.render 'login',
		isAuthenticated: do req.isAuthenticated
		user: req.user

app.post '/login',
	passport.authenticate 'local',
		failureRedirect: '/login'
	(req, res) ->
		res.redirect('/')
  
app.get '/logout', (req, res) ->
	do req.logout
	res.redirect '/'

app.get '/act/:id', ensureAuthenticated, (req, res) ->
	entityid = req.params.id
	mu.get_params entityid, (entity_params) ->
		orderid = if entity_params.length then entity_params[0].orderid else -1;
		innerid = if entity_params.length then entity_params[0].innerid else -1;
		entity_templateid = if entity_params.length then entity_params[0].entity_templateid else -1;
		act_type = templateid_to_str entity_templateid
		res.render 'edit-params', 
			isAuthenticated: do req.isAuthenticated
			user: req.user
			entity_params: entity_params
			act_type: act_type
			innerid: innerid
			orderid: orderid

app.get '/act/print/:id', ensureAuthenticated, (req, res) ->
	entityid = req.params.id
	mu.get_entity entityid, (entity) ->
		mu.get_params entityid, (entity_params) ->
			entity.act_type = templateid_to_str entity.entity_templateid
			res.render 'print',
				params:
					date: param_by_variant entity_params, 93
				entity: entity
				title: "Акт № #{entity.innerid}"	

app.get '/act/new/:type/:orderid', ensureAuthenticated, (req, res) ->
	orderid = req.params.orderid
	switch req.params.type
		when "1" then entity_templateid = 20 
		when "2" then entity_templateid = 21
		else entity_templateid = 0
	if entity_templateid > 0
		mu.new_entity entity_templateid, orderid, (new_entity_id) ->
			res.redirect "/act/#{new_entity_id}"

app.post '/param', ensureAuthenticated, (req, res) ->
	mu.update req.body
	res.redirect 'back'

server = app.listen 3000, ->
	console.log 'Listening on 3000'