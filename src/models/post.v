module models

// vlib
import arrays
import db.mysql as v_mysql
// local
import data.mysql
import utils
// first party
import coachonko.luuid

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
	created_at   string    @[json: 'createdAt']
	created_by   User      @[json: 'createdBy']
	updated_at   string    @[json: 'updatedAt']
	updated_by   User      @[json: 'updatedBy']
	deleted_at   string    @[json: 'deletedAt'; omitempty]
	deleted_by   User      @[json: 'deletedBy'; omitempty]
	status       string
	post_type    string    @[json: 'postType'] // `type` is a reserved keyword in V and in MySQL
	published_at string    @[json: 'publishedAt'; omitempty]
	published_by User      @[json: 'publishedBy'; omitempty]
	visibility   string // TODO v3.7.0
	title        string
	subtitle     string
	content      string
	handle       string
	excerpt      string
	metadata     string    @[raw]
	authors      []User
	tags         []PostTag @[omitempty]
	// revisions    []Revision
	// products     []Product
	// images       []Image
}

pub struct PostWriteable {
pub mut:
	status     string
	visibility string // TODO v3.7.0
	title      string
	subtitle   string
	content    string
	handle     string
	excerpt    string
	metadata   string   @[raw]
	authors    []string
	tags       []string
}

pub fn (pw PostWriteable) create(mut mysql_conn v_mysql.DB, created_by_id string, id string, post_type string) ! {
	luuid.verify(created_by_id) or {
		return utils.new_peony_error(400, 'created_by_id is not a UUID')
	}
	luuid.verify(id) or { return utils.new_peony_error(400, 'id is not a UUID') }

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
		id,
		created_at,
		created_by,
		updated_at,
		updated_by,
		title,
		subtitle,
		content,
		excerpt,
		handle,
		metadata'
	mut values := 'UUID_TO_BIN(?), NOW(), UUID_TO_BIN(?), NOW(), UUID_TO_BIN(?), ?, ?, ?, ?, ?, ?'

	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, id, created_by_id, created_by_id, pw.title, pw.subtitle,
		pw.content, pw.excerpt, pw.handle, pw.metadata)

	if post_type in allowed_post_type {
		query_columns += ', type'
		values += ', ?'
		vars = arrays.concat(vars, post_type)
	}

	if pw.status != '' {
		query_columns += ', status'
		values += ', ?'
		vars = arrays.concat(vars, pw.status)
	}

	if pw.status == 'published' {
		query_columns += ', published_at, published_by'
		values += ', NOW(), UUID_TO_BIN(?)'
		vars = arrays.concat(vars, created_by_id)
	}

	if pw.visibility != '' {
		query_columns += ', visibility'
		values += ', ?'
		vars = arrays.concat(vars, pw.visibility)
	}

	mut query := 'INSERT INTO post (${query_columns}) VALUES (${values})'
	mysql.prep_n_exec(mut mysql_conn, query, ...vars)!

	authors_query := 'INSERT INTO post_authors (post_id, author_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

	vars = []mysql.Param{}
	vars = arrays.concat(vars, id)

	// TODO use same conditions as update for consistency.
	if pw.authors.len < 2 {
		// Add user as author automatically if no authors are provided
		if pw.authors.len == 0 {
			vars = arrays.concat(vars, created_by_id)
		}
		if pw.authors.len == 1 {
			vars = arrays.concat(vars, pw.authors[0])
		}
		mysql.prep_n_exec(mut mysql_conn, authors_query, ...vars)!
	} else {
		mut stmt := mysql.prepare(mut mysql_conn, authors_query)!
		for author in pw.authors {
			author_id := author
			vars = []mysql.Param{}
			vars = arrays.concat(vars, id, author_id)
			stmt.exec(...vars)!
		}
		stmt.deallocate()
	}

	// tags
	if pw.tags.len != 0 {
		tags_query := 'INSERT INTO post_tags (post_id, post_tag_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

		if pw.tags.len == 1 {
			vars = []mysql.Param{}
			vars = arrays.concat(vars, id, pw.tags[0])
			mysql.prep_n_exec(mut mysql_conn, tags_query, ...vars)!
		} else {
			mut stmt := mysql.prepare(mut mysql_conn, tags_query)!
			for tag_id in pw.tags {
				tag := tag_id
				vars = []mysql.Param{}
				vars = arrays.concat(vars, id, tag)
				stmt.exec(...vars)!
			}
			stmt.deallocate()
		}
	}
}

// PostListParams allows to shape the response
// `include_authors` When false only the primary author is returned.
// `include_tags` When false only the primary tag is returned.
// `filter_post_type` required (`allowed_post_type`)
// `filter_deleted` When false includes deleted posts in the response.
// `filter_visibility` defaults to 'public' (`allowed_visibility`). TODO v3.7.0
// `filter_title` not applied by default TODO
// `filter_handle` not applied by default. Accepts one or more handle.
// `filter_description` not applied by default TODO
// `filter_tag` not applied by default. Accepts one or more tag id.
// `filter_category` not applied by default
// `filter_created_at` TODO
// `filter_updated_at` TODO
// `filter_sales_channel` TODO v3.10.0
// `order` defaults to `created_at DESC`
// `limit` defaults to 0 (no limit)
// `offset` defaults to 0 (no offset)
pub struct PostListParams {
	include_authors   bool
	include_tags      bool
	filter_post_type  string
	filter_deleted    bool
	filter_visibility string
	filter_handle     []string
	filter_tag        []string
	order             string
	limit             int
	offset            int
}

// TODO performance optimization: use keyset pagination
pub fn post_list(mut mysql_conn v_mysql.DB, params PostListParams) ![]Post {
	if params.filter_tag.len > 0 {
		for i := 0; i < params.filter_tag.len; i++ {
			luuid.verify(params.filter_tag[0]) or {
				return utils.new_peony_error(400, 'tag id ${params.filter_tag[0]} is not a UUID')
			}
		}
	}

	if params.filter_post_type != '' {
		if params.filter_post_type !in allowed_post_type {
			return error("post_type must be either 'post' or 'page'")
		}
	}

	mut where := ''
	if params.filter_deleted {
		where += 'AND post.deleted_at IS NULL'
	}

	if params.filter_handle.len == 1 {
		where += ' AND post.handle = ?'
	}
	if params.filter_handle.len > 1 {
		where += ' AND post.handle = ?'
		for i := 0; i < params.filter_handle.len; i++ {
			where += ' OR post.handle = ?'
		}
	}

	if params.filter_tag.len == 1 {
		where += ' AND post_tags.post_tag_id = UUID_TO_BIN(?)'
	}
	if params.filter_tag.len > 1 {
		where += ' AND post_tags.post_tag_id = UUID_TO_BIN(?)'
		for i := 0; i < params.filter_tag.len; i++ {
			where += ' OR post_tags.post_tag_id = UUID_TO_BIN(?)'
		}
	}

	mut limit := ''
	if params.limit > 0 {
		limit = 'LIMIT ${params.limit}'
	}

	mut offset := ''
	if params.offset > 0 {
		limit = 'OFFSET ${params.offset}'
	}

	// TODO validate params.order
	mut order := 'created_at DESC'
	if params.order != '' {
		order = params.order
	}

	mut author_id := 'BIN_TO_UUID(post_authors.author_id)'
	mut post_authors := '(
		SELECT post_id, author_id
		FROM post_authors
		WHERE sort_order = 0)
		AS post_authors'
	if params.include_authors {
		author_id = 'GROUP_CONCAT(BIN_TO_UUID(post_authors.author_id) ORDER BY post_authors.sort_order)'
		post_authors = 'post_authors'
	}

	mut post_tag_id := 'BIN_TO_UUID(post_tags.post_tag_id)'
	mut post_tags := '(
		SELECT post_id, post_tag_id
		FROM post_tags
		WHERE sort_order = 0)
		AS post_tags'
	if params.include_tags {
		post_tag_id = 'GROUP_CONCAT(BIN_TO_UUID(post_tags.post_tag_id) ORDER BY post_tags.sort_order)'
		post_tags = 'post_tags'
	}

	mut group := ''
	if params.include_authors || params.include_tags {
		group = 'GROUP BY post.id'
	}

	query_string := '
		SELECT
			BIN_TO_UUID(post.id),
			post.created_at,
			BIN_TO_UUID(post.created_by),
			post.updated_at,
			BIN_TO_UUID(post.updated_by),
			post.deleted_at,
			BIN_TO_UUID(post.deleted_by),
			post.status,
			post."type",
			post.published_at,
			BIN_TO_UUID(post.published_by),
			post.visibility,
			post.title,
			post.subtitle,
			post.content,
			post.handle,
			post.excerpt,
			post.metadata,
			${author_id},
			${post_tag_id}
		FROM post
		LEFT JOIN ${post_authors} ON post.id = post_authors.post_id
		LEFT JOIN ${post_tags} ON post.id = post_tags.post_id
		WHERE post."type" = ? ${where}
		${group}
		ORDER BY ${order}
		${limit}
		${offset}'

	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, params.filter_post_type)

	if params.filter_handle.len == 1 {
		vars = arrays.concat(vars, params.filter_handle[0])
	}
	if params.filter_handle.len > 1 {
		for i := 0; i < params.filter_handle.len; i++ {
			vars = arrays.concat(vars, params.filter_handle[i])
		}
	}

	if params.filter_tag.len == 1 {
		vars = arrays.concat(vars, params.filter_tag[0])
	}
	if params.filter_tag.len > 1 {
		for i := 0; i < params.filter_tag.len; i++ {
			vars = arrays.concat(vars, params.filter_tag[i])
		}
	}

	res := mysql.prep_n_exec(mut mysql_conn, query_string, ...vars)!

	rows := res.rows()
	mut posts := []Post{}

	for row in rows {
		vals := row.vals

		mut created_by := User{}
		if vals[2] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[2])!
		}
		mut updated_by := User{}
		if vals[4] != '' {
			updated_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
		}
		mut deleted_by := User{}
		if vals[6] != '' {
			deleted_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
		}
		mut published_by := User{}
		if vals[10] != '' {
			published_by = user_retrieve_by_id(mut mysql_conn, vals[10])!
		}

		mut authors := []User{}
		if params.include_authors {
			author_ids := vals[18].split(',')
			for id in author_ids {
				author := user_retrieve_by_id(mut mysql_conn, id)!
				authors = arrays.concat(authors, author)
			}
		} else {
			primary_author := user_retrieve_by_id(mut mysql_conn, vals[18])!
			authors = arrays.concat(authors, primary_author)
		}

		mut tags := []PostTag{}
		if vals[19] != '' { // post may have no tags
			if params.include_tags {
				tag_ids := vals[19].split(',')
				for id in tag_ids {
					tag := post_tag_retrieve_by_id(mut mysql_conn, id)!
					tags = arrays.concat(tags, tag)
				}
			} else {
				primary_tag := post_tag_retrieve_by_id(mut mysql_conn, vals[19])!
				tags = arrays.concat(tags, primary_tag)
			}
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
			published_at: vals[9]
			published_by: published_by
			visibility: vals[11]
			title: vals[12]
			subtitle: vals[13]
			content: vals[14]
			handle: vals[15]
			excerpt: vals[16]
			metadata: vals[17]
			authors: authors
			tags: tags
		}
		posts = arrays.concat(posts, post)
	}

	return posts
}

// PostRetrieveParams allows to shape the response
// `deleted` defaults to false. When false returns an error if the post is deleted
// `visibility` defaults to 'public' (`allowed_visibility`). TODO v3.7.0
// `authors` defaults to false. When false only the primary author is returned.
// `tags` defaults to false When false only the primary tag is returned.
// `filter_post_type` required (`allowed_post_type`)
// TODO apply to post_retrieve functions and routes
pub struct PostRetrieveParams {
	deleted          bool
	visibility       string
	authors          bool
	tags             bool
	filter_post_type string
}

// TODO add post_type parameter
fn post_retrieve(mut mysql_conn v_mysql.DB, column string, var string) !Post {
	mut qm := '?'
	if column == 'id' {
		qm = 'UUID_TO_BIN(?)'
	}

	query := '
	SELECT
		BIN_TO_UUID(id),
		created_at,
		BIN_TO_UUID(created_by),
		updated_at,
		BIN_TO_UUID(updated_by),
		deleted_at,
		BIN_TO_UUID(deleted_by),
		status,
		"type",
		published_at,
		BIN_TO_UUID(published_by),
		visibility,
		title,
		subtitle,
		content,
		handle,
		excerpt,
		metadata
	FROM post
	WHERE ${column} = ${qm}'
	res := mysql.prep_n_exec(mut mysql_conn, query, var)!

	rows := res.rows()
	if rows.len == 0 {
		return utils.new_peony_error(404, 'No post exists with the given ${column}')
	}

	mut posts := []Post{}

	for row in rows {
		vals := row.vals

		mut created_by := User{}
		if vals[2] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[2])!
		}
		mut updated_by := User{}
		if vals[4] != '' {
			updated_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
		}
		mut deleted_by := User{}
		if vals[6] != '' {
			deleted_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
		}
		mut published_by := User{}
		if vals[10] != '' {
			published_by = user_retrieve_by_id(mut mysql_conn, vals[10])!
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
			published_at: vals[9]
			published_by: published_by
			visibility: vals[11]
			title: vals[12]
			subtitle: vals[13]
			content: vals[14]
			handle: vals[15]
			excerpt: vals[16]
			metadata: vals[17]
			authors: authors
			tags: tags
		}
		posts = arrays.concat(posts, post)
	}

	return posts[0]
}

// pub fn internal_post_retrieve_by_id(mut mysql_conn v_mysql.DB, id string) !Post {
// 	// Retrieve all post data
// 	params := &PostRetrieveParams{
// 		deleted: true
// 		visibility: 'paid'
// 		authors: true
// 		tags: true
// 	}
// 	return post_retrieve(mut mysql_conn, id, params)
// }

pub fn post_retrieve_by_id(mut mysql_conn v_mysql.DB, id string) !Post {
	luuid.verify(id) or { return utils.new_peony_error(400, 'id is not a UUID') }

	return post_retrieve(mut mysql_conn, 'id', id)
}

pub fn post_retrieve_by_handle(mut mysql_conn v_mysql.DB, handle string) !Post {
	return post_retrieve(mut mysql_conn, 'handle', handle)
}

pub fn (mut pw PostWriteable) update(mut mysql_conn v_mysql.DB, post_id string, user_id string) ! {
	luuid.verify(post_id) or { return utils.new_peony_error(400, 'post_id is not a UUID') }
	luuid.verify(user_id) or { return utils.new_peony_error(400, 'user_id is not a UUID') }

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
	status = ?,
	updated_at = NOW(),
	updated_by = UUID_TO_BIN(?),
	visibility = ?,
	title = ?,
	subtitle = ?,
	content = ?,
	handle = ?,
	excerpt = ?,
	metadata = ?'

	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, pw.status, user_id, pw.visibility, pw.title, pw.subtitle,
		pw.content, pw.handle, pw.excerpt, pw.metadata)

	// Only update published_at and published_by if post is being published for the first time
	// Note: concatenate string at the beginning because of MySQL non-standard behavior
	//  https://dev.mysql.com/doc/refman/8.0/en/ansi-diff-update.html
	if pw.status == 'published' {
		query_records =
			"
		published_at = CASE
			WHEN published_at IS NULL AND status != 'published'
			THEN NOW()
			ELSE published_at
		END,
		published_by = CASE
			WHEN published_by IS NULL AND status != 'published'
			THEN UUID_TO_BIN(?)
			ELSE published_by
		END, " +
			query_records
		mut new_params := []mysql.Param{}
		new_params = arrays.concat(new_params, user_id)
		vars = arrays.concat(new_params, ...vars)
	}

	vars = arrays.concat(vars, post_id)

	mut query := 'UPDATE post SET ${query_records} WHERE id = UUID_TO_BIN(?)'
	mysql.prep_n_exec(mut mysql_conn, query, ...vars)!

	// Cleanup post_authors and post_tags
	query = 'DELETE FROM post_authors WHERE post_id = UUID_TO_BIN(?)'
	mysql.prep_n_exec(mut mysql_conn, query, post_id)!
	query = 'DELETE FROM post_tags WHERE post_id = UUID_TO_BIN(?)'
	mysql.prep_n_exec(mut mysql_conn, query, post_id)!

	// Insert post_authors and post_tags
	if pw.authors.len < 2 {
		query = 'INSERT INTO post_authors (post_id, author_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'
		if pw.authors.len == 1 {
			mysql.prep_n_exec(mut mysql_conn, query, post_id, pw.authors[0])!
		} else {
			mysql.prep_n_exec(mut mysql_conn, query, post_id, user_id)!
		}
	} else {
		query = '
			INSERT INTO post_authors (
				post_id,
				author_id,
				sort_order
				)
			VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?), ?)'
		mut stmt := mysql.prepare(mut mysql_conn, query)!
		for i := 0; i < pw.authors.len; i++ {
			vars = []mysql.Param{}
			vars = arrays.concat(vars, post_id, pw.authors[i], i)
			stmt.exec(...vars)!
		}
		stmt.deallocate()
	}

	if pw.tags.len != 0 {
		if pw.tags.len == 1 {
			query = 'INSERT INTO post_tags (post_id, post_tag_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'
			mysql.prep_n_exec(mut mysql_conn, query, post_id, pw.tags[0])!
		} else if pw.tags.len > 1 {
			query = '
				INSERT INTO post_tags (
					post_id,
					post_tag_id
					sort_order
					)
				VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?), ?)'
			mut stmt := mysql.prepare(mut mysql_conn, query)!
			for i := 0; i < pw.tags.len; i++ {
				vars = []mysql.Param{}
				vars = arrays.concat(vars, post_id, pw.tags[i], i)
				stmt.exec(...vars)!
			}
			stmt.deallocate()
		}
	}
}

pub fn post_delete_by_id(mut mysql_conn v_mysql.DB, user_id string, id string) ! {
	luuid.verify(id) or { return utils.new_peony_error(400, 'id is not a UUID') }

	query := '
	UPDATE post SET 
		deleted_at = NOW(),
		deleted_by = UUID_TO_BIN(?)
	WHERE id = UUID_TO_BIN(?)'

	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, user_id, id)

	mysql.prep_n_exec(mut mysql_conn, query, ...vars)!
}
