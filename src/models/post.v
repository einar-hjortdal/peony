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

// TODO add created_by to post_authors if authors is empty
pub fn (pw PostWriteable) create(mut mysql_conn v_mysql.DB, created_by_id string, id string, post_type string) ! {
	if post_type !in allowed_post_type {
		return utils.new_peony_error(500, 'post_type invalid')
	}

	if pw.status != '' {
		if pw.status !in allowed_post_status {
			return utils.new_peony_error(400, 'status invalid')
		}
	}

	if pw.visibility != '' {
		if pw.visibility !in allowed_visibility {
			return utils.new_peony_error(400, 'visibility invalid')
		}
	}

	if pw.title == '' {
		return utils.new_peony_error(400, 'title is required')
	}

	if pw.title.len > 63 {
		return utils.new_peony_error(400, 'title cannot be longer than 63 characters')
	}

	if pw.subtitle.len > 191 {
		return utils.new_peony_error(400, 'subtitle cannot be longer than 191 characters')
	}

	if pw.handle == '' {
		return utils.new_peony_error(400, 'handle is required')
	}

	if pw.handle.len > 63 {
		return utils.new_peony_error(400, 'handle cannot be longer than 63 characters')
	}

	mut query_columns := '
		"id",
		"created_at",
		"created_by",
		"updated_at",
		"updated_by",
		"featured",
		"title",
		"subtitle",
		"content",
		"excerpt",
		"handle",
		"metadata"'
	mut values := '
	UUID_TO_BIN(?),
	NOW(),
	UUID_TO_BIN(?),
	NOW(),
	UUID_TO_BIN(?),
	?,
	?,
	?,
	?,
	?,
	?,
	?'

	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, mysql.Param(id), mysql.Param(created_by_id), mysql.Param(created_by_id),
		mysql.Param(pw.featured), mysql.Param(pw.title), mysql.Param(pw.subtitle), mysql.Param(pw.content),
		mysql.Param(pw.excerpt), mysql.Param(pw.handle), mysql.Param(pw.metadata))

	if post_type in allowed_post_type {
		query_columns += ', "type"'
		values += ', ?'
		vars = arrays.concat(vars, mysql.Param(post_type))
	}

	if pw.status != '' {
		query_columns += ', "status"'
		values += ', ?'
		vars = arrays.concat(vars, mysql.Param(pw.status))
	}

	if pw.status == 'published' {
		query_columns += ', "published_at", "published_by"'
		values += ', UUID_TO_BIN(?), UUID_TO_BIN(?)'
		vars = arrays.concat(vars, mysql.Param('NOW()'), mysql.Param(created_by_id))
	}

	if pw.visibility != '' {
		query_columns += ', "visibility"'
		values += ', ?'
		vars = arrays.concat(vars, mysql.Param(pw.visibility))
	}

	mut query := 'INSERT INTO "post" (${query_columns}) VALUES (${values})'
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!

	query = 'INSERT INTO "post_authors" ("post_id", "author_id") VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

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

	// tags
	if pw.tags.len != 0 {
		query = 'INSERT INTO "post_tags" ("post_id", "post_tag_id") VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

		if pw.tags.len == 1 {
			vars = []mysql.Param{}
			vars = arrays.concat(vars, mysql.Param(id), mysql.Param(pw.tags[0]))
			mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
		} else {
			mysql.prep(mut mysql_conn, 'stmt', query)!
			for tag_id in pw.tags {
				tag := tag_id
				vars = []mysql.Param{}
				vars = arrays.concat(vars, mysql.Param(id), mysql.Param(tag))
				mysql.exec(mut mysql_conn, 'stmt', ...vars)!
			}
			mysql.deallocate(mut mysql_conn, 'stmt')
		}
	}
}

pub fn post_list(mut mysql_conn v_mysql.DB, post_type string) ![]Post {
	if post_type != '' {
		if post_type != 'page' && post_type != 'post' {
			return error("post_type must be either 'post' or 'page'")
		}
	}

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
			BIN_TO_UUID("post_tags"."post_tag_id")
		FROM "post"
		LEFT JOIN "post_authors" ON "post"."id" = "post_authors"."post_id"
		LEFT JOIN "post_tags" ON "post"."id" = "post_tags"."post_id"
		WHERE "post"."type" = ?
		ORDER BY "created_at" DESC'

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
		tags := post_tag_retrieve_by_post_id(mut mysql_conn, vals[0])!

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
			tags: tags
		}
		posts = arrays.concat(posts, post)
	}

	return posts
}

fn post_retrieve(mut mysql_conn v_mysql.DB, column string, var string) !Post {
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
	WHERE "${column}" = UUID_TO_BIN(?)'
	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query, var)!

	rows := res.rows()
	if rows.len == 0 {
		return utils.new_peony_error(404, 'No post exists with the given id/handle')
	}

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
		tags := post_tag_retrieve_by_post_id(mut mysql_conn, vals[0])!

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
			tags: tags
		}
		posts = arrays.concat(posts, post)
	}

	return posts[0]
}

pub fn post_retrieve_by_id(mut mysql_conn v_mysql.DB, id string) !Post {
	return post_retrieve(mut mysql_conn, 'id', id)
}

pub fn post_retrieve_by_handle(mut mysql_conn v_mysql.DB, handle string) !Post {
	return post_retrieve(mut mysql_conn, 'handle', handle)
}

pub fn (mut pw PostWriteable) update(mut mysql_conn v_mysql.DB, post_id string, user_id string) ! {
	if user_id == '' {
		return error('PostWriteable.update: parameter user_id invalid')
	}

	if pw.title == '' {
		return error('PostWriteable.update: post title is required')
	}

	if pw.status == '' {
		return error('PostWriteable.update: post status is required')
	}

	if pw.status !in allowed_post_status {
		return error('PostWriteable.update: post status invalid')
	}

	if pw.visibility == '' {
		return error('PostWriteable.update: post visibility is required')
	}

	if pw.visibility !in allowed_visibility {
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

	// Only update published_at and published_by if post is being published for the first time
	if pw.status == 'published' {
		query_records += ',
		"published_at" = CASE
			WHEN "published_at" IS NOT NULL AND status IS NOT \'published\'
			THEN NOW()
			ELSE "published_at"
		END,
		"published_by" = CASE
			WHEN "published_by" IS NOT NULL
			THEN UUID_TO_BIN(?)
			ELSE "published_by"
		END'
		vars = arrays.concat(vars, mysql.Param(user_id))
	}

	vars = arrays.concat(vars, mysql.Param(post_id))

	mut query := '
	UPDATE "post"
	SET ${query_records}
	WHERE "id" = UUID_TO_BIN(?)'
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars) or { // TODO
		println(err)
	}
}
