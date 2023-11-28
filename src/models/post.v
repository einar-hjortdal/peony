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
	created_at   string    @[json: 'createdAt']
	created_by   User      @[json: 'createdBy']
	updated_at   string    @[json: 'updatedAt']
	updated_by   User      @[json: 'updatedBy']
	deleted_at   string    @[json: 'deletedAt']
	deleted_by   User      @[json: 'deletedBy']
	status       string
	post_type    string    @[json: 'postType'] // `type` is a reserved keyword in V and in MySQL
	featured     bool
	published_at string    @[json: 'publishedAt']
	published_by User      @[json: 'publishedBy']
	visibility   string // TODO v3.7.0
	title        string
	subtitle     string
	content      string
	handle       string
	excerpt      string
	metadata     string    @[raw]
	authors      []User
	tags         []PostTag
	// revisions    []Revision
	// products     []Product
	// images       []Image
}

// TODO handle authors, accept array of strings (expect user id)
pub struct PostWriteable {
pub mut:
	status     string
	featured   bool
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
		featured,
		title,
		subtitle,
		content,
		excerpt,
		handle,
		metadata'
	mut values := 'UUID_TO_BIN(?), NOW(), UUID_TO_BIN(?), NOW(), UUID_TO_BIN(?), ?, ?, ?, ?, ?, ?, ?'

	mut vars := []mysql.Param{}
	vars << id
	vars << created_by_id
	vars << created_by_id
	vars << pw.featured
	vars << pw.title
	vars << pw.subtitle
	vars << pw.content
	vars << pw.excerpt
	vars << pw.handle
	vars << pw.metadata

	if post_type in allowed_post_type {
		query_columns += ', type'
		values += ', ?'
		vars << post_type
	}

	if pw.status != '' {
		query_columns += ', status'
		values += ', ?'
		vars << pw.status
	}

	if pw.status == 'published' {
		query_columns += ', published_at, published_by'
		values += ', NOW(), UUID_TO_BIN(?)'
		vars << created_by_id
	}

	if pw.visibility != '' {
		query_columns += ', visibility'
		values += ', ?'
		vars << pw.visibility
	}

	mut query := 'INSERT INTO post (${query_columns}) VALUES (${values})'
	mysql.prepare_n_exec(mut mysql_conn, query, ...vars)!

	authors_query := 'INSERT INTO post_authors (post_id, author_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

	vars = []mysql.Param{}
	vars << id

	// TODO use same conditions as update for consistency.
	if pw.authors.len < 2 {
		// Add user as author automatically if no authors are provided
		if pw.authors.len == 0 {
			vars << created_by_id
		}
		if pw.authors.len == 1 {
			vars << pw.authors[0]
		}
		mysql.prepare_n_exec(mut mysql_conn, authors_query, ...vars)!
	} else {
		mysql.prep(mut mysql_conn, 'stmt', authors_query)!
		for author in pw.authors {
			author_id := author
			vars = []mysql.Param{}
			vars << id
			vars << author_id
			mysql.exec(mut mysql_conn, 'stmt', ...vars)!
		}
		mysql.deallocate(mut mysql_conn, 'stmt')
	}

	// tags
	if pw.tags.len != 0 {
		tags_query := 'INSERT INTO post_tags (post_id, post_tag_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'

		if pw.tags.len == 1 {
			vars = []mysql.Param{}
			vars << id
			vars << pw.tags[0]
			mysql.prepare_n_exec(mut mysql_conn, tags_query, ...vars)!
		} else {
			mysql.prep(mut mysql_conn, 'stmt', tags_query)!
			for tag_id in pw.tags {
				tag := tag_id
				vars = []mysql.Param{}
				vars << id
				vars << tag
				mysql.exec(mut mysql_conn, 'stmt', ...vars)!
			}
			mysql.deallocate(mut mysql_conn, 'stmt')
		}
	}
}

// PostListParams allows to shape the response
// `post_type` required (`allowed_post_type`)
// `deleted` defaults to false. When false excludes deleted posts in the response
// `visibility` defaults to 'public' (`allowed_visibility`). TODO v3.7.0
// `order` defaults to `created_at DESC`
// `limit` defaults to 10
// `offset` defaults to 0
// `authors` defaults to false. When false only the primary author is returned.
// `tags` defaults to false When false only the primary tag is returned.
pub struct PostListParams {
	post_type  string
	deleted    bool
	visibility string
	order      string
	limit      int
	offset     int
	authors    bool
	tags       bool
}

// TODO performance optimization: use keyset pagination
pub fn post_list(mut mysql_conn v_mysql.DB, params PostListParams) ![]Post {
	if params.post_type != '' {
		if params.post_type !in allowed_post_type {
			return error("post_type must be either 'post' or 'page'")
		}
	}

	mut where := ''
	if !params.deleted {
		where += 'AND post.deleted_at IS NULL'
	}

	mut limit := '10'
	if params.limit > 0 {
		limit = '${params.limit}'
	}

	mut offset := 0
	if params.offset > 0 {
		limit = '${params.offset}'
	}

	// TODO validate params.order
	mut order := 'created_at DESC'
	if params.order != '' {
		order = params.order
	}

	mut author_id := 'BIN_TO_UUID(post_authors.author_id)'
	mut post_authors := '
		(
			SELECT post_id, author_id
			FROM post_authors
			WHERE sort_order = 0
		) AS post_authors'
	if params.authors {
		author_id = 'GROUP_CONCAT(BIN_TO_UUID(post_authors.author_id) ORDER BY post_authors.sort_order)'
		post_authors = 'post_authors'
	}

	mut post_tag_id := 'BIN_TO_UUID(post_tags.post_tag_id)'
	mut post_tags := '
		(
			SELECT post_id, post_tag_id
			FROM post_tags
			WHERE sort_order = 0
		) AS post_tags'
	if params.tags {
		post_tag_id = 'GROUP_CONCAT(BIN_TO_UUID(post_tags.post_tag_id) ORDER BY post_tags.sort_order)'
		post_tags = 'post_tags'
	}

	mut group := ''
	if params.authors || params.tags {
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
			CASE WHEN post.featured = 0x01 THEN 1 ELSE 0 END,
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
		LIMIT ${limit}
		OFFSET ${offset}'

	res := mysql.prepare_n_exec(mut mysql_conn, query_string, params.post_type)!

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
		if vals[11] != '' {
			published_by = user_retrieve_by_id(mut mysql_conn, vals[11])!
		}

		mut authors := []User{}
		if params.authors {
			author_ids := vals[19].split(',')
			for id in author_ids {
				author := user_retrieve_by_id(mut mysql_conn, id)!
				authors << author
			}
		} else {
			primary_author := user_retrieve_by_id(mut mysql_conn, vals[19])!
			authors << primary_author
		}

		mut tags := []PostTag{}
		if vals[20] != '' { // post may have no tags
			if params.tags {
				tag_ids := vals[20].split(',')
				for id in tag_ids {
					tag := post_tag_retrieve_by_id(mut mysql_conn, id)!
					tags << tag
				}
			} else {
				primary_tag := post_tag_retrieve_by_id(mut mysql_conn, vals[20])!
				tags << primary_tag
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

// PostRetrieveParams allows to shape the response
// `deleted` defaults to false. When false returns an error if the post is deleted
// `visibility` defaults to 'public' (`allowed_visibility`). TODO v3.7.0
// `authors` defaults to false. When false only the primary author is returned.
// `tags` defaults to false When false only the primary tag is returned.
// TODO apply to post_retrieve functions and routes
pub struct PostRetrieveParams {
	deleted    bool
	visibility string
	authors    bool
	tags       bool
}

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
		type,
		CASE WHEN featured = 0x01 THEN 1 ELSE 0 END,
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
	res := mysql.prepare_n_exec(mut mysql_conn, query, var)!

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
		if vals[11] != '' {
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
	status = ?,
	featured = ?,
	updated_at = NOW(),
	updated_by = UUID_TO_BIN(?),
	visibility = ?,
	title = ?,
	subtitle = ?,
	content = ?,
	handle = ?,
	excerpt = ?,
	metadata = ?'

	// TODO use arrays.concat https://github.com/vlang/v/issues/19976
	mut vars := []mysql.Param{}
	vars << pw.status
	vars << pw.featured
	vars << user_id
	vars << pw.visibility
	vars << pw.title
	vars << pw.subtitle
	vars << pw.content
	vars << pw.handle
	vars << pw.excerpt
	vars << pw.metadata

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
		new_params << user_id
		vars = arrays.concat(new_params, ...vars)
	}

	vars << post_id

	mut query := 'UPDATE post SET ${query_records} WHERE id = UUID_TO_BIN(?)'
	println(query)
	println(vars)
	mysql.prepare_n_exec(mut mysql_conn, query, ...vars)!

	// Cleanup post_authors and post_tags
	query = 'DELETE FROM "post_authors" WHERE "post_id" = ?'
	mysql.prepare_n_exec(mut mysql_conn, query, post_id)!
	query = 'DELETE FROM "post_tags" WHERE "post_id" = ?'
	mysql.prepare_n_exec(mut mysql_conn, query, post_id)!

	// Insert post_authors and post_tags
	query = 'INSERT INTO post_authors (post_id, author_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'
	if pw.authors.len == 0 {
		mysql.prepare_n_exec(mut mysql_conn, query, post_id, user_id)!
	}
	if pw.authors.len == 1 {
		mysql.prepare_n_exec(mut mysql_conn, query, post_id, pw.authors[0])!
	}
	if pw.authors.len > 1 {
		mysql.prep(mut mysql_conn, 'stmt', query)!
		for author in pw.authors {
			vars = []mysql.Param{}
			vars = arrays.concat(vars, post_id, author)
			mysql.exec(mut mysql_conn, 'stmt', ...vars)!
		}
		mysql.deallocate(mut mysql_conn, 'stmt')
	}

	if pw.tags.len != 0 {
		query = 'INSERT INTO post_tags (post_id, post_tag_id) VALUES (UUID_TO_BIN(?), UUID_TO_BIN(?))'
		if pw.tags.len == 1 {
			mysql.prepare_n_exec(mut mysql_conn, query, post_id, pw.tags[0])!
		}
		if pw.tags.len > 1 {
			mysql.prep(mut mysql_conn, 'stmt', query)!
			for tag in pw.tags {
				vars = []mysql.Param{}
				vars = arrays.concat(vars, post_id, tag)
				mysql.exec(mut mysql_conn, 'stmt', ...vars)!
			}
			mysql.deallocate(mut mysql_conn, 'stmt')
		}
	}
}

pub fn post_delete_by_id(mut mysql_conn v_mysql.DB, user_id string, id string) ! {
	query := '
	UPDATE post SET 
		deleted_at = NOW(),
		deleted_by = ?
	WHERE id = UUID_TO_BIN(?)'

	mut vars := []mysql.Param{}
	vars << user_id
	vars << id

	mysql.prepare_n_exec(mut mysql_conn, query, ...vars)!
}
