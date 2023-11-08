module models

// vlib
import arrays
import db.mysql as v_mysql
// local
import utils
import data.mysql

struct PostTag {
	id string
	// parent     ?&PostTag
	visibility string
	created_at string [json: 'createdAt']
	created_by User   [json: 'createdBy']
	updated_at string [json: 'updatedAt']
	updated_by User   [json: 'updatedBy']
	deleted_at string [json: 'deletedAt']
	deleted_by User   [json: 'deletedBy']
	title      string
	subtitle   string
	content    string
	handle     string
	excerpt    string
	metadata   string [raw]
}

struct PostTagWriteable {
	parent     string
	visibility string
	title      string
	subtitle   string
	content    string
	handle     string
	excerpt    string
	metadata   string [raw]
}

// TODO validate first, add vals after
pub fn (mut ptw PostTagWriteable) create(mut mysql_conn v_mysql.DB, created_by_id string, id string) ! {
	mut query_columns := ['id', 'created_by', 'updated_by', 'title', 'handle']
	mut qm := ['UUID_TO_BIN(?)', 'UUID_TO_BIN(?)', 'UUID_TO_BIN(?)', '?', '?']
	mut vars := []mysql.Param{}
	vars = arrays.concat(vars, mysql.Param(id), mysql.Param(created_by_id), mysql.Param(created_by_id),
		mysql.Param(ptw.title), mysql.Param(ptw.handle))

	if ptw.parent != '' {
		query_columns = arrays.concat(query_columns, 'parent')
		vars = arrays.concat(vars, mysql.Param(ptw.parent))
		qm = arrays.concat(qm, '?')
	}

	if ptw.visibility != '' {
		match ptw.visibility {
			'public', 'paid' {
				query_columns = arrays.concat(query_columns, 'visibility')
				vars = arrays.concat(vars, mysql.Param(ptw.visibility))
				qm = arrays.concat(qm, '?')
			}
			else {
				return utils.new_peony_error(400, 'visibility not allowed')
			}
		}
	}

	if ptw.title == '' {
		return utils.new_peony_error(400, 'title is required')
	}

	if ptw.title.len > 63 {
		return utils.new_peony_error(400, 'title is longer than 63 characters')
	}

	if ptw.subtitle != '' {
		query_columns = arrays.concat(query_columns, 'subtitle')
		vars = arrays.concat(vars, mysql.Param(ptw.subtitle))
		qm = arrays.concat(qm, '?')
	}

	if ptw.subtitle.len > 191 {
		return utils.new_peony_error(400, 'subtitle is longer than 191 characters')
	}

	if ptw.content != '' {
		query_columns = arrays.concat(query_columns, 'content')
		vars = arrays.concat(vars, mysql.Param(ptw.content))
		qm = arrays.concat(qm, '?')
	}

	// TODO generate handle in route if missing
	if ptw.handle == '' {
		return utils.new_peony_error(400, 'handle is required')
	}

	if ptw.handle.len > 63 {
		return utils.new_peony_error(400, 'handle is longer than 63 characters')
	}
	// TODO check handle does not contain forbidden characters

	query := '
	INSERT INTO "post_tag" (${mysql.columns(query_columns)}) 
	VALUES (${qm.join(', ')})'

	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
}

pub fn post_tag_list(mut mysql_conn v_mysql.DB) ![]PostTag {
	// TODO left join with post
	// TODO get parent tag if not empty
	query := '
	SELECT 
		BIN_TO_UUID("id"),
		"visibility",
		"created_at",
		BIN_TO_UUID("created_by"),
		"updated_at",
		BIN_TO_UUID("updated_by"),
		"deleted_at",
		BIN_TO_UUID("deleted_by"),
		"title",
		"subtitle",
		"content",
		"handle",
		"excerpt",
		"metadata"
	FROM "post_tag"'

	res := mysql.prep_n_exec(mut mysql_conn, 'stmt', query)!

	rows := res.rows()
	mut post_tags := []PostTag{}

	for row in rows {
		vals := row.vals

		mut created_by := User{}
		if vals[4] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[4])!
		}

		mut updated_by := User{}
		if vals[6] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[6])!
		}

		mut deleted_by := User{}
		if vals[3] != '' {
			created_by = user_retrieve_by_id(mut mysql_conn, vals[8])!
		}

		mut post_tag := PostTag{
			id: vals[0]
			visibility: vals[1]
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
