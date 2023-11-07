module models

// vlib
import arrays
import db.mysql as v_mysql
// local
import data.mysql

// A post is a resource of content. A subset of posts is pages. pages are resources that are not meant
// to be listed together with posts.
//
// `status` can be either: 'published', 'draft', 'scheduled'.
// `post_type` can be either: 'post' or 'page'.
//
// peony does not perform any sanitization of post content: only allow trusted and informed users to
// publish posts.
pub struct Post {
pub mut:
	id           string
	created_at   string [json: 'createdAt']
	created_by   User   [json: 'createdBy']
	updated_at   string [json: 'updatedAt']
	updated_by   User   [json: 'updatedBy']
	deleted_at   string [json: 'deletedAt']
	deleted_by   User   [json: 'deletedBy']
	status       string
	post_type    string [json: 'postType'] // `type` is a reserved keyword in V
	featured     bool
	published_at string [json: 'publishedAt']
	published_by User   [json: 'publishedBy']
	visibility   string
	title        string
	subtitle     string
	content      string
	handle       string
	excerpt      string
	metadata     string [raw]
	authors      []User
	// tags         []Tag
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
	handle     string
	excerpt    string
	metadata   string [raw]
}

pub const allowed_status = ['published', 'draft', 'scheduled']

pub const allowed_visibility = ['public', 'paid']

// TODO add created_by to post_authors if authors is empty
pub fn (post Post) create(mut mysql_conn v_mysql.DB, created_by_id string) ! {
	mut query_columns := ['id', 'title', 'created_by', 'updated_by']
	mut qm := ['UUID_TO_BIN(?)', '?', 'UUID_TO_BIN(?)', 'UUID_TO_BIN(?)']
	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, mysql.Param(post.id), mysql.Param(post.title), mysql.Param(created_by_id),
		mysql.Param(created_by_id))

	if post.status != '' {
		match post.status {
			'published', 'draft', 'scheduled' {
				query_columns = arrays.concat(query_columns, 'status')
				vars = arrays.concat(vars, mysql.Param(post.status))
				qm = arrays.concat(qm, '?')
			}
			else {
				return error('status not allowed')
			}
		}
	}

	if post.post_type != '' {
		match post.post_type {
			'post', 'page' {
				query_columns = arrays.concat(query_columns, 'type')
				vars = arrays.concat(vars, mysql.Param(post.post_type))
				qm = arrays.concat(qm, '?')
			}
			else {
				return error('type not allowed')
			}
		}
	}

	if post.featured {
		query_columns = arrays.concat(query_columns, 'featured')
		vars = arrays.concat(vars, mysql.Param(post.featured))
		qm = arrays.concat(qm, '?')
	}

	if post.status == 'published' {
		query_columns = arrays.concat(query_columns, 'published_at', 'published_by')
		vars = arrays.concat(vars, mysql.Param('NOW()'), mysql.Param(created_by_id))
		qm = arrays.concat(qm, 'UUID_TO_BIN(?)', 'UUID_TO_BIN(?)')
	}

	if post.visibility != '' {
		match post.visibility {
			'public', 'paid' {
				query_columns = arrays.concat(query_columns, 'visibility')
				vars = arrays.concat(vars, mysql.Param(post.visibility))
				qm = arrays.concat(qm, '?')
			}
			else {
				return error('visibility not allowed')
			}
		}
	}

	if post.subtitle != '' {
		query_columns = arrays.concat(query_columns, 'subtitle')
		vars = arrays.concat(vars, mysql.Param(post.subtitle))
		qm = arrays.concat(qm, '?')
	}

	if post.content != '' {
		query_columns = arrays.concat(query_columns, 'content')
		vars = arrays.concat(vars, mysql.Param(post.content))
		qm = arrays.concat(qm, '?')
	}

	if post.handle != '' {
		query_columns = arrays.concat(query_columns, 'handle')
		vars = arrays.concat(vars, mysql.Param(post.handle))
		qm = arrays.concat(qm, '?')
	}

	if post.excerpt != '' {
		query_columns = arrays.concat(query_columns, 'excerpt')
		vars = arrays.concat(vars, mysql.Param(post.excerpt))
		qm = arrays.concat(qm, '?')
	}

	if post.metadata != '' {
		query_columns = arrays.concat(query_columns, 'metadata')
		vars = arrays.concat(vars, mysql.Param(post.metadata))
		qm = arrays.concat(qm, '?')
	}

	mut query := 'INSERT INTO "post" (${mysql.columns(query_columns)}) VALUES (${qm.join(', ')})'
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!

	// post_authors
	query = '
		INSERT INTO "post_authors" ("post_id", "author_id")
		VALUES	(UUID_TO_BIN(?), UUID_TO_BIN(?))'

	vars = [mysql.Param(post.id)]

	if post.authors.len < 2 {
		if post.authors.len == 0 {
			vars = arrays.concat(vars, mysql.Param(created_by_id))
		}
		if post.authors.len == 1 {
			vars = arrays.concat(vars, mysql.Param(post.authors[0].id))
		}
		mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
	} else {
		for author in post.authors {
			author_id := author.id
			vars = [mysql.Param(post.id), mysql.Param(author_id)]
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
			"post"."featured",
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
	query := 'SELECT BIN_TO_UUID("id"), "created_at", BIN_TO_UUID("created_by"), "updated_at", BIN_TO_UUID("updated_by"), "deleted_at", BIN_TO_UUID("deleted_by"), "status", "type", "featured", "published_at", BIN_TO_UUID("published_by"), "visibility", "title", "subtitle", "content", "handle", "metadata" FROM "post" WHERE "id" = UUID_TO_BIN(?)'
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
			metadata: vals[17]
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
	"featured",
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

	row := rows[0] // TODO what happens if no records?
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
		metadata: vals[17]
		// TODO authors
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
