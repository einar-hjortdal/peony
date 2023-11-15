module models

// vlib
import arrays
import db.mysql
// local
import utils
import data.mysql as p_mysql

pub struct PostTag {
	id         string
	parent     ?&PostTag
	visibility string
	created_at string    @[json: 'createdAt']
	created_by User      @[json: 'createdBy']
	updated_at string    @[json: 'updatedAt']
	updated_by User      @[json: 'updatedBy']
	deleted_at string    @[json: 'deletedAt']
	deleted_by User      @[json: 'deletedBy']
	title      string
	subtitle   string
	content    string
	handle     string
	excerpt    string
	metadata   string    @[raw]
	posts      []Post
}

pub struct PostTagWriteable {
pub mut:
	parent     string
	visibility string
	title      string
	subtitle   string
	content    string
	handle     string
	excerpt    string
	metadata   string   @[raw]
	posts      []string
}

pub fn (mut ptw PostTagWriteable) create(mut mysql_conn mysql.DB, created_by_id string, id string) ! {
	ptw.validate()!

	mut columns := '
	id,
	created_by,
	updated_by,
	title,
	handle'
	mut qm := 'UUID_TO_BIN(?), UUID_TO_BIN(?), UUID_TO_BIN(?), ?, ?'

	mut vars := []p_mysql.Param{}
	vars << id
	vars << created_by_id
	vars << created_by_id
	vars << ptw.title
	vars << ptw.handle

	if ptw.parent != '' {
		columns += ', parent'
		vars << ptw.parent
		qm += ', ?'
	}

	if ptw.visibility != '' {
		columns += ', visibility'
		vars << ptw.visibility
		qm += ', ?'
	}

	if ptw.subtitle != '' {
		columns += ', subtitle'
		vars << ptw.subtitle
		qm += ', ?'
	}

	if ptw.content != '' {
		columns += ', content'
		vars << ptw.content
		qm += ', ?'
	}

	query := '
	INSERT INTO "post_tag" (${columns})
	VALUES (${qm})'

	p_mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
}

pub fn post_tag_list(mut mysql_conn mysql.DB) ![]PostTag {
	// TODO left join with post
	// TODO get parent tag if not empty
	query := '
	SELECT 
		BIN_TO_UUID(post_tag.id),
		BIN_TO_UUID(post_tag.parent_id),
		post_tag.visibility,
		post_tag.created_at,
		BIN_TO_UUID(post_tag.created_by),
		post_tag.updated_at,
		BIN_TO_UUID(post_tag.updated_by),
		post_tag.deleted_at,
		BIN_TO_UUID(post_tag.deleted_by),
		post_tag.title,
		post_tag.subtitle,
		post_tag.content,
		post_tag.handle,
		post_tag.excerpt,
		post_tag.metadata,
		BIN_TO_UUID(post_id)
	FROM post_tag
	LEFT JOIN post_tags ON post_tag.id = post_tags.post_tag_id
	ORDER BY created_at DESC'

	res := p_mysql.prep_n_exec(mut mysql_conn, 'stmt', query)!

	rows := res.rows()
	if rows.len == 0 {
		return []PostTag{}
	}

	// TODO a single tag may be listed more than once if it is linked to more than one post.

	mut post_tags := []PostTag{}

	for row in rows {
		vals := row.vals

		// TODO parent id = vals[1]

		mut created_by := User{}
		if vals[5] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[5])!
		}

		mut updated_by := User{}
		if vals[7] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[7])!
		}

		mut deleted_by := User{}
		if vals[9] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[9])!
		}

		mut post_tag := PostTag{
			id: vals[0]
			visibility: vals[2]
			created_at: vals[4]
			created_by: created_by
			updated_at: vals[6]
			updated_by: updated_by
			deleted_at: vals[8]
			deleted_by: deleted_by
			title: vals[10]
			subtitle: vals[11]
			content: vals[12]
			handle: vals[13]
			excerpt: vals[14]
			metadata: vals[15]
		}

		// TODO fetch posts by id
		post_tags = arrays.concat(post_tags, post_tag)
	}
	return post_tags
}

fn (ptw PostTagWriteable) validate() ! {
	if ptw.visibility != '' {
		if ptw.visibility !in allowed_visibility {
			return utils.new_peony_error(400, 'visibility not allowed')
		}
	}

	if ptw.title == '' {
		return utils.new_peony_error(400, 'title is required')
	}

	if ptw.title.len > 63 {
		return utils.new_peony_error(400, 'title is longer than 63 characters')
	}

	if ptw.subtitle.len > 191 {
		return utils.new_peony_error(400, 'subtitle is longer than 191 characters')
	}

	if ptw.handle == '' {
		return utils.new_peony_error(400, 'handle is required')
	}

	if ptw.handle.len > 63 {
		return utils.new_peony_error(400, 'handle is longer than 63 characters')
	}

	// TODO UUID must be validated or risk mysql fail operations
}

pub fn post_tag_retrieve_by_id(mut mysql_conn mysql.DB, id string) !PostTag {
	return post_tag_retrieve(mut mysql_conn, 'id', id)!
}

pub fn post_tag_retrieve_by_handle(mut mysql_conn mysql.DB, handle string) !PostTag {
	return post_tag_retrieve(mut mysql_conn, 'handle', handle)!
}

fn post_tag_retrieve(mut mysql_conn mysql.DB, column string, var string) !PostTag {
	mut qm := '?'
	if column == 'id' {
		qm = 'UUID_TO_BIN(?)'
	}

	query := '
	SELECT 
		BIN_TO_UUID("post_tag"."id"),
		BIN_TO_UUID("post_tag"."parent_id"),
		"post_tag"."visibility",
		"post_tag"."created_at",
		BIN_TO_UUID("post_tag"."created_by"),
		"post_tag"."updated_at",
		BIN_TO_UUID("post_tag"."updated_by"),
		"post_tag"."deleted_at",
		BIN_TO_UUID("post_tag"."deleted_by"),
		"post_tag"."title",
		"post_tag"."subtitle",
		"post_tag"."content",
		"post_tag"."handle",
		"post_tag"."excerpt",
		"post_tag"."metadata",
		BIN_TO_UUID("post"."id")
	FROM "post_tag"
	LEFT JOIN "post_tags" ON "post_tag"."id" = "post_tags"."post_tag_id"
	WHERE "${column}" = ${qm}
	ORDER BY "created_at" DESC'

	res := p_mysql.prep_n_exec(mut mysql_conn, 'stmt', query, var)!

	rows := res.rows()
	if rows.len == 0 {
		return utils.new_peony_error(404, 'No post_tag exists with the given ${column}')
	}
	// TODO it will return more than one row if a tag is linked to more than one post.
	// TODO fetch posts by id
	row := rows[0]
	vals := row.vals

	// parent id = vals[1]

	mut created_by := User{}
	if vals[4] != '' {
		created_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
	}

	mut updated_by := User{}
	if vals[6] != '' {
		created_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
	}

	mut deleted_by := User{}
	if vals[8] != '' {
		created_by = user_retrieve_by_id(mut mysql_conn, vals[8])!
	}

	post_tag := PostTag{
		id: vals[0]
		visibility: vals[2]
		created_at: vals[3]
		created_by: created_by
		updated_at: vals[5]
		updated_by: updated_by
		deleted_at: vals[7]
		deleted_by: deleted_by
		title: vals[9]
		subtitle: vals[10]
		content: vals[11]
		handle: vals[12]
		excerpt: vals[13]
		metadata: vals[14]
	}

	return post_tag
}

pub fn (mut ptw PostTagWriteable) update(mut mysql_conn mysql.DB, post_tag_id string, user_id string) ! {
	ptw.validate()!
	mut query_records := '
	"parent" = UUID_TO_BIN(?),
	"visibility" = ?,
	"updated_at" = NOW(),
	"updated_by" = UUID_TO_BIN(?),
	"title" = ?,
	"subtitle" = ?,
	"content" = ?,
	"handle" = ?,
	"excerpt" = ?,
	"metadata" = ?
	'

	mut vars := []p_mysql.Param{}
	vars = arrays.concat(vars, p_mysql.Param(ptw.parent), p_mysql.Param(ptw.visibility),
		p_mysql.Param(user_id), p_mysql.Param(ptw.title), p_mysql.Param(ptw.subtitle),
		p_mysql.Param(ptw.content), p_mysql.Param(ptw.handle), p_mysql.Param(ptw.excerpt),
		p_mysql.Param(ptw.metadata))

	vars = arrays.concat(vars, p_mysql.Param(post_tag_id))

	mut query := '
	UPDATE "post_tag" 
	SET ${query_records}
	WHERE "id" = UUID_TO_BIN(?)'

	p_mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!

	// TODO the following could return errors if post_id does not exist
	if ptw.posts.len > 0 {
		post_tags_query := '
		INSERT IGNORE INTO "post_tags" ("post_id", "post_tag_id")
		VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

		if ptw.posts.len == 1 {
			mut post_tags_vars := []p_mysql.Param{}
			post_tags_vars = arrays.concat(vars, p_mysql.Param(ptw.posts[0]), p_mysql.Param(post_tag_id))
			p_mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...post_tags_vars)!
		} else {
			p_mysql.prep(mut mysql_conn, 'stmt', post_tags_query)!
			for post_id in ptw.posts {
				id := post_id
				mut post_tags_vars := []p_mysql.Param{}
				post_tags_vars = arrays.concat(vars, p_mysql.Param(id), p_mysql.Param(post_tag_id))
				p_mysql.exec(mut mysql_conn, 'stmt', ...post_tags_vars)!
			}
			p_mysql.deallocate(mut mysql_conn, 'stmt')
		}
	}
}

pub fn post_tag_retrieve_by_post_id(mut mysql_conn mysql.DB, post_id string) ![]PostTag {
	query := '
	SELECT 
		BIN_TO_UUID("post_tag"."id"),
		BIN_TO_UUID("post_tag"."parent_id"),
		"post_tag"."visibility",
		"post_tag"."created_at",
		BIN_TO_UUID("post_tag"."created_by"),
		"post_tag"."updated_at",
		BIN_TO_UUID("post_tag"."updated_by"),
		"post_tag"."deleted_at",
		BIN_TO_UUID("post_tag"."deleted_by"),
		"post_tag"."title",
		"post_tag"."subtitle",
		"post_tag"."content",
		"post_tag"."handle",
		"post_tag"."excerpt",
		"post_tag"."metadata"
	FROM "post_tag"
	INNER JOIN "post_tags" ON "post_tag"."id" = "post_tags"."post_tag_id"
	WHERE "post_id" = ?
	ORDER BY "post_tags"."sort_order"'

	res := p_mysql.prep_n_exec(mut mysql_conn, 'stmt', query, post_id)!

	rows := res.rows()
	if rows.len == 0 {
		return []PostTag{}
	}

	mut post_tags := []PostTag{}
	for row in rows {
		vals := row.vals

		// TODO parent vals[1]
		mut created_by := User{}
		if vals[4] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[5])!
		}

		mut updated_by := User{}
		if vals[6] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[7])!
		}

		mut deleted_by := User{}
		if vals[9] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[9])!
		}

		post_tag := PostTag{
			id: vals[0]
			// parent: parent
			visibility: vals[2]
			created_at: vals[3]
			created_by: created_by
			updated_at: vals[5]
			updated_by: updated_by
			deleted_at: vals[7]
			deleted_by: deleted_by
			title: vals[9]
			subtitle: vals[10]
			content: vals[11]
			handle: vals[12]
			excerpt: vals[13]
			metadata: vals[14]
		}

		post_tags = arrays.concat(post_tags, post_tag)
	}
	return post_tags
}
