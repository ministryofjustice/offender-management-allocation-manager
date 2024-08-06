# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.1'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.paths << Rails.root.join('node_modules/govuk-frontend')
Rails.application.config.assets.paths << Rails.root.join('node_modules/govuk-frontend/dist')
Rails.application.config.assets.paths << Rails.root.join('node_modules/govuk-frontend/dist/govuk/assets/images')
Rails.application.config.assets.paths << Rails.root.join('node_modules/govuk-frontend/dist/govuk/assets/fonts/')

Rails.application.config.assets.paths << Rails.root.join('node_modules/@ministryofjustice/frontend')
Rails.application.config.assets.paths << Rails.root.join('node_modules/@ministryofjustice/frontend/moj/assets/images')

# Precompiled assets
# Configure which assets get precompiled in the Sprockets manifest file:
# app/assets/config/manifest.js
