module models

// vlib
import arrays
import db.mysql as v_mysql
// local
import data.mysql
import utils

// A post is a resource of content. A subset of posts is pages. pages are resources that are not meant
// to be listed together with posts.
//
// `status` can be either: 'published', 'draft', 'scheduled'.
// `post_type` can be either: 'post' or 'page'.
//
// peony does not perform any sanitization of post content: only allow trusted and informed users to
// publish posts.
pub struct Post {
	id           string
	created_at   string    [json: 'createdAt']
	created_by   User      [json: 'createdBy']
	updated_at   string    [json: 'updatedAt']
	updated_by   User      [json: 'updatedBy']
	deleted_at   string    [json: 'deletedAt']
	deleted_by   User      [json: 'deletedBy']
	status       string
	post_type    string    [json: 'postType'] // `type` is a reserved keyword in V
	featured     bool
	published_at string    [json: 'publishedAt']
	published_by User      [json: 'publishedBy']
	visibility   string
	title        string
	subtitle     string
	content      string
	handle       string
	excerpt      string
	metadata     string    [raw]
	authors      []User
	tags         []PostTag
	// revisions    []Revision
	// products     []Product
	// images       []Image
}

// TODO only use this struct for create and update. Make Post immutable
// TODO handle authors, accept array of strings (expect user id)
pub struct PostWriteable {
pub mut:
	status     string
	featured   bool
	visibility string
	title      string
	subtitle   string
	content    string
	handle     string // TODO generate handle using title if not provided
	excerpt    string
	metadata   string   [raw]
	authors    []string
	tags       []string
}

pub const allowed_status = ['published', 'draft', 'scheduled']

pub const allowed_visibility = ['public', 'paid']

// TODO add created_by to post_authors if authors is empty
pub fn (pw PostWriteable) create(mut mysql_conn v_mysql.DB, created_by_id string, id string, post_type string) ! {
	mut query_columns := ['id', 'title', 'created_by', 'updated_by']
	mut qm := ['UUID_TO_BIN(?)', '?', 'UUID_TO_BIN(?)', 'UUID_TO_BIN(?)']
	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, mysql.Param(id), mysql.Param(pw.title), mysql.Param(created_by_id),
		mysql.Param(created_by_id))

	// TODO always enter, database defaults to draft
	if pw.status != '' {
		match pw.status {
			'published', 'draft', 'scheduled' {
				query_columns = arrays.concat(query_columns, 'status')
				vars = arrays.concat(vars, mysql.Param(pw.status))
				qm = arrays.concat(qm, '?')
			}
			else {
				return utils.new_peony_error(400, 'status not allowed')
			}
		}
	}

	// Always enter, defaults to post
	if post_type != '' {
		match post_type {
			'post', 'page' {
				query_columns = arrays.concat(query_columns, 'type')
				vars = arrays.concat(vars, mysql.Param(post_type))
				qm = arrays.concat(qm, '?')
			}
			else {
				return error('type not allowed')
			}
		}
	}

	// TODO always insert, defaults to false
	if pw.featured || !pw.featured {
		query_columns = arrays.concat(query_columns, 'featured')
		vars = arrays.concat(vars, mysql.Param(pw.featured))
		qm = arrays.concat(qm, '?')
	}

	if pw.status == 'published' {
		query_columns = arrays.concat(query_columns, 'published_at', 'published_by')
		vars = arrays.concat(vars, mysql.Param('NOW()'), mysql.Param(created_by_id))
		qm = arrays.concat(qm, 'UUID_TO_BIN(?)', 'UUID_TO_BIN(?)')
	}

	// TODO always insert: database defaults to public
	if pw.visibility != '' {
		match pw.visibility {
			'public', 'paid' {
				query_columns = arrays.concat(query_columns, 'visibility')
				vars = arrays.concat(vars, mysql.Param(pw.visibility))
				qm = arrays.concat(qm, '?')
			}
			else {
				return error('visibility not allowed')
			}
		}
	}

	// TODO always insert, could be empty on purpose
	if pw.subtitle != '' {
		query_columns = arrays.concat(query_columns, 'subtitle')
		vars = arrays.concat(vars, mysql.Param(pw.subtitle))
		qm = arrays.concat(qm, '?')
	}

	// TODO always insert, could be empty on purpose
	if pw.content != '' {
		query_columns = arrays.concat(query_columns, 'content')
		vars = arrays.concat(vars, mysql.Param(pw.content))
		qm = arrays.concat(qm, '?')
	}

	// TODO when empty, generate one
	if pw.handle != '' {
		query_columns = arrays.concat(query_columns, 'handle')
		vars = arrays.concat(vars, mysql.Param(pw.handle))
		qm = arrays.concat(qm, '?')
	}

	// TODO always insert excerpt: could be empty on purpose
	if pw.excerpt != '' {
		query_columns = arrays.concat(query_columns, 'excerpt')
		vars = arrays.concat(vars, mysql.Param(pw.excerpt))
		qm = arrays.concat(qm, '?')
	}

	// TODO always insert metadata: could be empty on purpose
	if pw.metadata != '' {
		query_columns = arrays.concat(query_columns, 'metadata')
		vars = arrays.concat(vars, mysql.Param(pw.metadata))
		qm = arrays.concat(qm, '?')
	}

	mut query := 'INSERT INTO "post" (${mysql.columns(query_columns)}) VALUES (${qm.join(', ')})'
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!

	// post_authors
	query = '
		INSERT INTO "post_authors" ("post_id", "author_id")
		VALUES	(UUID_TO_BIN(?), UUID_TO_BIN(?))'

	vars = [mysql.Param(id)]

	if pw.authors.len < 2 {
		if pw.authors.len == 0 {
			vars = arrays.concat(vars, mysql.Param(created_by_id))
		}
		if pw.authors.len == 1 {
			vars = arrays.concat(vars, mysql.Param(pw.authors[0]))
		}
		mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
	} else {
		for author in pw.authors {
			author_id := author
			vars = [mysql.Param(id), mysql.Param(author_id)]
			mysql.prep(mut mysql_conn, 'stmt', query)!
			mysql.exec(mut mysql_conn, 'stmt', ...vars)!
		}
		mysql.deallocate(mut mysql_conn, 'stmt')
	}
}

pub fn post_list(mut mysql_conn v_mysql.DB, post_type string) ![]Post {
	if post_type != '' {
		if post_type != 'page' && post_type != 'post' {
			return error("post_type must be either 'post' or 'page'")
		}
	}

	// TODO fetch , products, images, translations and tiers
	// (from tables post_products, post_images, post_translations, tiers)
	query_string := '
		SELECT DISTINCT
			BIN_TO_UUID("post"."id"),
			"post"."created_at",
			BIN_TO_UUID("post"."created_by"),
			"post"."updated_at",
			BIN_TO_UUID("post"."updated_by"),
			"post"."deleted_at",
			BIN_TO_UUID("post"."deleted_by"),
			"post"."status",
			"post"."type",
			CASE WHEN "post"."featured" = 0x01 THEN 1 ELSE 0 END,
			"post"."published_at",
			BIN_TO_UUID("post"."published_by"),
			"post"."visibility",
			"post"."title",
			"post"."subtitle",
			"post"."content",
			"post"."handle",
			"post"."excerpt",
			"post"."metadata",
			BIN_TO_UUID("post_authors"."author_id"),
			BIN_TO_UUID("post_tags"."tag_id")
		FROM "post"
		LEFT JOIN "post_authors" ON "post"."id" = "post_authors"."post_id"
		LEFT JOIN "post_tags" ON "post"."id" = "post_tags"."post_id"
		WHERE "post"."type" = ?'

	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query_string, post_type)!

	rows := res.rows()
	mut posts := []Post{}

	for row in rows {
		vals := row.vals

		mut created_by := User{}
		if vals[2] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[2])!
		}
		mut updated_by := User{}
		if vals[2] != '' {
			updated_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
		}
		mut deleted_by := User{}
		if vals[6] != '' {
			deleted_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
		}
		mut published_by := User{}
		if vals[6] != '' {
			published_by = user_retrieve_by_id(mut mysql_conn, vals[11])!
		}

		authors := authors_retrieve_by_post_id(mut mysql_conn, vals[0])!

		mut post := Post{
			id: vals[0]
			created_at: vals[1]
			created_by: created_by
			updated_at: vals[3]
			updated_by: updated_by
			deleted_at: vals[5]
			deleted_by: deleted_by
			status: vals[7]
			post_type: vals[8]
			featured: mysql.bit_to_bool(vals[9])
			published_at: vals[10]
			published_by: published_by
			visibility: vals[12]
			title: vals[13]
			subtitle: vals[14]
			content: vals[15]
			handle: vals[16]
			excerpt: vals[17]
			metadata: vals[18]
			authors: authors
		}
		posts = arrays.concat(posts, post)
	}

	return posts
}

pub fn post_retrieve_by_id(mut mysql_conn v_mysql.DB, id string) !Post {
	query := '
	SELECT
		BIN_TO_UUID("id"),
		"created_at",
		BIN_TO_UUID("created_by"),
		"updated_at",
		BIN_TO_UUID("updated_by"),
		"deleted_at",
		BIN_TO_UUID("deleted_by"),
		"status",
		"type",
		CASE WHEN "featured" = 0x01 THEN 1 ELSE 0 END,
		"published_at",
		BIN_TO_UUID("published_by"),
		"visibility",
		"title",
		"subtitle",
		"content",
		"handle",
		"excerpt",
		"metadata"
	FROM "post"
	WHERE "id" = UUID_TO_BIN(?)'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, id)!

	rows := res.rows()
	mut posts := []Post{}

	for row in rows {
		vals := row.vals

		mut created_by := User{}
		if vals[2] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[2])!
		}
		mut updated_by := User{}
		if vals[2] != '' {
			updated_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
		}
		mut deleted_by := User{}
		if vals[6] != '' {
			deleted_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
		}
		mut published_by := User{}
		if vals[6] != '' {
			published_by = user_retrieve_by_id(mut mysql_conn, vals[11])!
		}

		mut post := Post{
			id: vals[0]
			created_at: vals[1]
			created_by: created_by
			updated_at: vals[3]
			updated_by: updated_by
			deleted_at: vals[5]
			deleted_by: deleted_by
			status: vals[7]
			post_type: vals[8]
			featured: mysql.bit_to_bool(vals[9])
			published_at: vals[10]
			published_by: published_by
			visibility: vals[12]
			title: vals[13]
			subtitle: vals[14]
			content: vals[15]
			handle: vals[16]
			excerpt: vals[17]
			metadata: vals[18]
			// TODO authors
		}
		posts = arrays.concat(posts, post)
	}

	return posts[0]
}

pub fn post_retrieve_by_handle(mut mysql_conn v_mysql.DB, handle string) !Post {
	query := '
	SELECT
		BIN_TO_UUID("id"),
		"created_at",
		BIN_TO_UUID("created_by"),
		"updated_at",
		BIN_TO_UUID("updated_by"),
		"deleted_at",
		BIN_TO_UUID("deleted_by"),
		"status",
		"type",
		CASE WHEN "featured" = 0x01 THEN 1 ELSE 0 END,
		"published_at",
		BIN_TO_UUID("published_by"),
		"visibility",
		"title",
		"subtitle",
		"content",
		"handle",
		"excerpt",
		"metadata"
	FROM "post"
	WHERE "handle" = ?'

	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, handle)!

	rows := res.rows()

	if rows.len == 0 {
		return utils.new_peony_error(404, 'No post exists with the given handle')
	}

	row := rows[0]
	vals := row.vals

	mut created_by := User{}
	if vals[2] != '' {
		created_by = user_retrieve_by_id(mut mysql_conn, vals[2])!
	}
	mut updated_by := User{}
	if vals[2] != '' {
		updated_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
	}
	mut deleted_by := User{}
	if vals[6] != '' {
		deleted_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
	}
	mut published_by := User{}
	if vals[6] != '' {
		published_by = user_retrieve_by_id(mut mysql_conn, vals[11])!
	}

	mut post := Post{
		id: vals[0]
		created_at: vals[1]
		created_by: created_by
		updated_at: vals[3]
		updated_by: updated_by
		deleted_at: vals[5]
		deleted_by: deleted_by
		status: vals[7]
		post_type: vals[8]
		featured: mysql.bit_to_bool(vals[9])
		published_at: vals[10]
		published_by: published_by
		visibility: vals[12]
		title: vals[13]
		subtitle: vals[14]
		content: vals[15]
		handle: vals[16]
		excerpt: vals[17]
		metadata: vals[18]
		// TODO authors: join tables, combine rows that are equal except for authors column
	}

	return post
}

pub fn (mut pw PostWriteable) update(mut mysql_conn v_mysql.DB, post_id string, user_id string) ! {
	if user_id == '' {
		return error('PostWriteable.update: parameter user_id invalid')
	}

	if pw.title == '' {
		return error('PostWriteable.update: post title is required')
	}

	if pw.status !in models.allowed_status {
		return error('PostWriteable.update: post status invalid')
	}

	if pw.visibility !in models.allowed_visibility {
		return error('PostWriteable.update: post visibility invalid')
	}

	mut query_records := '
	"status" = ?,
	"featured" = ?,
	"updated_at" = NOW(),
	"updated_by" = UUID_TO_BIN(?), 
	"visibility" = ?,
	"title" = ?,
	"subtitle" = ?,
	"content" = ?,
	"handle" = ?,
	"excerpt" = ?,
	"metadata" = ?'

	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, mysql.Param(pw.status), mysql.Param(pw.featured), mysql.Param(user_id),
		mysql.Param(pw.visibility), mysql.Param(pw.title), mysql.Param(pw.subtitle), mysql.Param(pw.content),
		mysql.Param(pw.handle), mysql.Param(pw.excerpt), mysql.Param(pw.metadata))

	// TODO only update published_at if post not public already
	if pw.status == 'published' {
		query_records += ', "published_at" = NOW(), "published_by" = ?'
		vars = arrays.concat(vars, mysql.Param(user_id))
	}

	vars = arrays.concat(vars, mysql.Param(post_id))

	mut query := '
	UPDATE "post" 
	SET ${query_records}
	WHERE "id" = UUID_TO_BIN(?)'
	println(query)
	println(vars)
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars) or { println(err) }
}
