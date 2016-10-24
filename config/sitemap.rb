# frozen_string_literal: true

# To run task
# rails sitemap:refresh:no_ping
# Or production
# rails sitemap:refresh RAILS_ENV=production
# https://www.google.com/webmasters/tools/

require 'rubygems'
require 'sitemap_generator'

SitemapGenerator.verbose = false
SitemapGenerator::Sitemap.default_host = 'https://tryslice.io'
SitemapGenerator::Sitemap.sitemaps_host = ENV['website_url']
SitemapGenerator::Sitemap.public_path = 'carrierwave/sitemaps/'
SitemapGenerator::Sitemap.sitemaps_path = ''
SitemapGenerator::Sitemap.create do
  add '/landing', changefreq: 'weekly', priority: 0.5
  add '/about', changefreq: 'weekly', priority: 0.5
  add '/about/use', changefreq: 'weekly', priority: 0.5
  add '/contact', changefreq: 'monthly', priority: 0.3

  add '/docs', changefreq: 'weekly', priority: 0.5
  add '/docs/adverse-events', changefreq: 'weekly', priority: 0.5
  add '/docs/blinding', changefreq: 'weekly', priority: 0.5
  add '/docs/data-entry', changefreq: 'weekly', priority: 0.5
  add '/docs/data-entry/events', changefreq: 'weekly', priority: 0.5
  add '/docs/data-entry/locking', changefreq: 'weekly', priority: 0.5
  add '/docs/data-quality-checks', changefreq: 'weekly', priority: 0.5
  add '/docs/data-review-and-analysis', changefreq: 'weekly', priority: 0.5
  add '/docs/designs', changefreq: 'weekly', priority: 0.5
  add '/docs/domains', changefreq: 'weekly', priority: 0.5
  add '/docs/exports', changefreq: 'weekly', priority: 0.5
  add '/docs/filters', changefreq: 'weekly', priority: 0.5
  add '/docs/lingo', changefreq: 'weekly', priority: 0.5
  add '/docs/modules', changefreq: 'weekly', priority: 0.5
  add '/docs/notifications', changefreq: 'weekly', priority: 0.5
  add '/docs/project-roles', changefreq: 'weekly', priority: 0.5
  add '/docs/project-setup', changefreq: 'weekly', priority: 0.5
  add '/docs/randomization/stratification-factors', changefreq: 'weekly', priority: 0.5
  add '/docs/randomization/treatment-arms', changefreq: 'weekly', priority: 0.5
  add '/docs/randomization-schemes', changefreq: 'weekly', priority: 0.5
  add '/docs/randomization-schemes/minimization', changefreq: 'weekly', priority: 0.5
  add '/docs/randomization-schemes/permuted-block', changefreq: 'weekly', priority: 0.5
  add '/docs/reports', changefreq: 'weekly', priority: 0.5
  add '/docs/sections', changefreq: 'weekly', priority: 0.5
  add '/docs/sites', changefreq: 'weekly', priority: 0.5
  add '/docs/tablet-handoff', changefreq: 'weekly', priority: 0.5
  add '/docs/technical', changefreq: 'weekly', priority: 0.5
  add '/docs/theme', changefreq: 'weekly', priority: 0.5
  add '/docs/variables', changefreq: 'weekly', priority: 0.5
end
