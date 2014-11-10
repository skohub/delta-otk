mysql = require 'mysql'

pool = mysql.createPool
	poolnectionLimit: 10
	host:		process.env.DB_HOST
	user:		process.env.DB_USER
	password:	process.env.DB_SECRET
	database:	process.env.DB_NAME

exports.end = ->
	pool.end (err) -> 
		console.log 'Pool terminated'

# Users

exports.find_user = (username, password, cb) ->
	sql = 
		'select userid, get_user_name(userid) name from user where user=? and 
		password=?';
	pool.query sql, [username, password], (err, res) ->
		throw err if err
		if res.length > 0
			user = 
				id: res[0].userid
				name: res[0].name
			console.log user
		cb user

exports.find_user_by_id = (userid, cb) ->
	sql = 'select get_user_name(userid) name from user where userid=?'
	pool.query sql, [userid], (err, res) ->
		throw err if err
		if res.length > 0
			user = 
				id: res[0].userid
				name: res[0].name
			console.log user
		cb user

# Entities

exports.get_entities = (cb) ->
	sql = 
		'select entity.*, company.name from entity 
			left join `order` using(orderid)
			left join company on company.companyid=`order`.companyid
			join entity_template using(entity_templateid)
			where entity_type = \'act\'
			order by entityid desc limit 20'
	pool.query sql, (err, res) ->
		throw err if err
		cb (res)

exports.get_entity = (entityid, cb) ->
	sql = 
		'select entity.*, company.name from entity 
			left join `order` using(orderid)
			left join company on company.companyid=`order`.companyid
			join entity_template using(entity_templateid)
			where entityid = ?'
	pool.query sql, [entityid], (err, res) ->
		throw err if err
		if res then cb (res[0]) else do cb

exports.new_entity = (entity_templateid, orderid, cb) ->
	sql = 'insert into entity set entity_templateid = ?, orderid = ?';
	pool.query sql, [entity_templateid, orderid], (err, res) ->
		throw err if err
		entityid = res.insertId
		sql = 'call create_entity_template_params(?, ?, null)'
		pool.query sql, [entityid, entity_templateid], (err, res) ->
			throw err if err
			cb entityid

# Entity params

exports.get_params = (entityid, cb) ->
	sql = 
		'select * 
		from 
			entity_param 
		join 
			entity using(entityid)
		join
			entity_param_variant using(entity_param_variantid)
		where entityid=?
		order by sort_order'
	pool.query sql, [entityid], (err, res) -> 
			throw err if err
			cb res

exports.update = (req_body) ->
	sql = 'update entity_param set str_value = ? where entity_paramid = ?';
	for id, key in req_body.id
		pool.query sql, [req_body.str_value[key], id], (err, res) ->
			throw err if err