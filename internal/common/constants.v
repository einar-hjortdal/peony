module common

pub const min_fetch = i32(1)
pub const max_fetch = i32(250)
pub const offset_default = i32(0)
pub const order_asc = 'ASC'
pub const order_desc = 'DESC'
pub const order_default = order_asc

pub const role_admin = 'admin'
pub const role_member = 'member'
pub const role_developer = 'developer'
pub const role_author = 'author'
pub const role_contributor = 'contributor'

pub const product_status_draft = 'draft'
pub const product_status_proposed = 'proposed'
pub const product_status_published = 'published'
pub const product_status_rejected = 'rejected'

pub const variant_rank_default = i32(0)

pub const inventory_item_requires_shipping_default = true
pub const inventory_item_manage_inventory_default = true
pub const inventory_item_allow_backorder_default = false

pub const money_amount_default_is_original = false
