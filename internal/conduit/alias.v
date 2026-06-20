module conduit

import record

pub type APIKey = record.APIKey
pub type APIKeyRetrieveParams = record.APIKeyRetrieveParams
pub type APIKeyUpdateParams = record.APIKeyUpdateParams

pub type Category = record.Category
pub type CategoryUpdateParams = record.CategoryUpdateParams
pub type CategoryTranslationUpdateParams = record.CategoryTranslationUpdateParams
pub type CategoryTranslation = record.CategoryTranslation
pub type CategoryRetrieveParams = record.CategoryRetrieveParams
pub type CategorySEOCreateParams = record.CategorySEOCreateParams

pub type Country = record.Country
pub type CountryRetrieveParams = record.CountryRetrieveParams

pub type Currency = record.Currency
pub type CurrencyRetrieveParams = record.CurrencyRetrieveParams

pub type ImageTranslation = record.ImageTranslation
pub type ProductImage = record.ProductImage

pub type InventoryItem = record.InventoryItem
pub type InventoryLevel = record.InventoryLevel

pub type Locale = record.Locale
pub type LocaleRetrieveParams = record.LocaleRetrieveParams
pub type VariantMoneyAmount = record.VariantMoneyAmount
pub type PasswordDetails = record.PasswordDetails
pub type PasswordDetailsGetParams = record.PasswordDetailsGetParams
pub type ProductOptionValueTranslation = record.ProductOptionValueTranslation
pub type ProductOptionValue = record.ProductOptionValue
pub type ProductOptionTranslation = record.ProductOptionTranslation
pub type ProductOption = record.ProductOption
pub type Product = record.Product
pub type ProductTranslation = record.ProductTranslation
pub type ProductRetrieveParams = record.ProductRetrieveParams
pub type Region = record.Region
pub type RegionRetriveParams = record.RegionRetriveParams
pub type RegionCreateParams = record.RegionCreateParams
pub type RegionUpdateParams = record.RegionUpdateParams

pub type SalesChannel = record.SalesChannel
pub type SalesChannelRetrieveParams = record.SalesChannelRetrieveParams
pub type SEO = record.SEO
pub type SEOTranslation = record.SEOTranslation
pub type SEOTranslationCreateParams = record.SEOTranslationCreateParams
pub type SEOUpdateParams = record.SEOUpdateParams
pub type StockLocation = record.StockLocation
pub type Store = record.Store
pub type TaxRate = record.TaxRate

pub type User = record.User
pub type UserCreateParams = record.UserCreateParams
pub type UserUpdateParams = record.UserUpdateParams
pub type UserListParams = record.UserListParams
pub type Variant = record.Variant
