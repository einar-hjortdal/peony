module models

// vlib
import arrays
import db.mysql as v_mysql
// local
import utils
import data.mysql as p_mysql

pub struct PostTag {
	id         string
	parent     ?&PostTag // TODO ensure no circular
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

pub fn (mut ptw PostTagWriteable) create(mut mysql_conn v_mysql.DB, created_by_id string, id string) ! {
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

	if ptw.excerpt != '' {
		columns += ', excerpt'
		vars << ptw.excerpt
		qm += ', ?'
	}

	query := '
	INSERT INTO post_tag (${columns})
	VALUES (${qm})'

	p_mysql.prep_n_exec(mut mysql_conn, query, ...vars)!
	// TODO insert post_tags values
}

// PostTagListParams allows to shape the response
// `deleted` when false excludes deleted posts in the response
pub struct PostTagListParams {
	deleted bool
}

pub fn post_tag_list(mut mysql_conn v_mysql.DB, params PostTagListParams) ![]PostTag {
	mut where_clauses := ''

	if params.deleted == false {
		where_clauses = 'AND post_tag.deleted_at IS NULL'
	}

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
		BIN_TO_UUID(post_tags.post_id)
	FROM post_tag
	LEFT JOIN post_tags ON post_tag.id = post_tags.post_tag_id
	${where_clauses}
	ORDER BY created_at DESC'

	res := p_mysql.prep_n_exec(mut mysql_conn, query)!

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
		if vals[4] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
		}

		mut updated_by := User{}
		if vals[6] != '' {
			updated_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
		}

		mut deleted_by := User{}
		if vals[8] != '' {
			deleted_by = user_retrieve_by_id(mut mysql_conn, vals[8])!
		}

		mut post_tag := PostTag{
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

pub fn post_tag_retrieve_by_id(mut mysql_conn v_mysql.DB, id string) !PostTag {
	return post_tag_retrieve(mut mysql_conn, 'id', id)!
}

pub fn post_tag_retrieve_by_handle(mut mysql_conn v_mysql.DB, handle string) !PostTag {
	return post_tag_retrieve(mut mysql_conn, 'handle', handle)!
}

fn post_tag_retrieve(mut mysql_conn v_mysql.DB, column string, var string) !PostTag {
	mut qm := '?'
	if column == 'id' {
		qm = 'UUID_TO_BIN(?)'
	}

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
		BIN_TO_UUID(post_tags.post_id)
	FROM post_tag
	LEFT JOIN post_tags ON post_tag.id = post_tags.post_tag_id
	WHERE ${column} = ${qm}
	ORDER BY created_at DESC'

	res := p_mysql.prep_n_exec(mut mysql_conn, query, var)!

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
		updated_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
	}

	mut deleted_by := User{}
	if vals[8] != '' {
		deleted_by = user_retrieve_by_id(mut mysql_conn, vals[8])!
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

pub fn (mut ptw PostTagWriteable) update(mut mysql_conn v_mysql.DB, post_tag_id string, user_id string) ! {
	ptw.validate()!
	mut query_records := '
	visibility = ?,
	updated_at = NOW(),
	updated_by = UUID_TO_BIN(?),
	title = ?,
	subtitle = ?,
	content = ?,
	handle = ?,
	excerpt = ?,
	metadata = ?'

	mut vars := []p_mysql.Param{}
	vars << ptw.visibility
	vars << user_id
	vars << ptw.title
	vars << ptw.subtitle
	vars << ptw.content
	vars << ptw.handle
	vars << ptw.excerpt
	vars << ptw.metadata

	if ptw.parent != '' {
		query_records += ', parent_id = UUID_TO_BIN(?)'
		vars << ptw.parent
	}

	vars << post_tag_id

	mut query := '
	UPDATE post_tag
	SET ${query_records}
	WHERE id = UUID_TO_BIN(?)'

	p_mysql.prep_n_exec(mut mysql_conn, query, ...vars)!

	// TODO the following could return errors if post_id does not exist
	if ptw.posts.len > 0 {
		post_tags_query := '
		INSERT IGNORE INTO post_tags (post_id, post_tag_id)
		VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

		if ptw.posts.len == 1 {
			mut post_tags_vars := []p_mysql.Param{}
			post_tags_vars << ptw.posts[0]
			post_tags_vars << post_tag_id
			p_mysql.prep_n_exec(mut mysql_conn, query, ...post_tags_vars)!
		} else {
			mut stmt := p_mysql.prepare(mut mysql_conn, post_tags_query)!
			for post_id in ptw.posts {
				id := post_id
				mut post_tags_vars := []p_mysql.Param{}
				post_tags_vars << id
				post_tags_vars << post_tag_id
				stmt.exec(...post_tags_vars)!
			}
			stmt.deallocate()
		}
	}
}

pub fn post_tag_retrieve_by_post_id(mut mysql_conn v_mysql.DB, post_id string) ![]PostTag {
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
		post_tag.metadata
	FROM post_tag
	INNER JOIN post_tags ON post_tag.id = post_tags.post_tag_id
	WHERE post_id = ?
	ORDER BY post_tags.sort_order'

	res := p_mysql.prep_n_exec(mut mysql_conn, query, post_id)!

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
			created_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
		}

		mut updated_by := User{}
		if vals[6] != '' {
			updated_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
		}

		mut deleted_by := User{}
		if vals[8] != '' {
			deleted_by = user_retrieve_by_id(mut mysql_conn, vals[8])!
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

pub fn post_tag_delete_by_id(mut mysql_conn v_mysql.DB, user_id string, id string) !PostTag {
	query := '
	UPDATE post_tag SET 
		deleted_at = NOW(),
		deleted_by = UUID_TO_BIN(?)
	WHERE id = UUID_TO_BIN(?)'

	mut vars := []p_mysql.Param{}
	vars << user_id
	vars << id

	p_mysql.prep_n_exec(mut mysql_conn, query, ...vars)!
	return post_tag_retrieve_by_id(mut mysql_conn, id)!
}
