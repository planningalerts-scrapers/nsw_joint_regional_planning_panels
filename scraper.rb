#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
Bundler.require

require "date"
require "mechanize"
require "scraperwiki"

# Scrapes planning applications currently under assessment from the NSW
# Planning Portal's planning panels register and yields one record per
# application.
class Scraper
  PAGE_URL = "https://www.planningportal.nsw.gov.au/planning-panel?field_status_value=2&page=%d"

  def self.run(&)
    new.run(&)
  end

  def run(&block)
    agent = Mechanize.new
    page_number = 0
    loop do
      puts "Getting page #{page_number}..."
      count = scrape_page(agent, page_number, &block)
      page_number += 1
      break unless count.positive?
    end
  end

  # Scrapes one page of applications of those currently under assessment
  # (page 0 is the first page) and returns the number of applications found.
  def scrape_page(agent, page_number)
    page = agent.get(format(PAGE_URL, page_number))
    block = page.at(".page__content .grid__row")
    return 0 if block.nil?

    urls = block.element_children.map do |application|
      (page.uri + application.at("a")["href"]).to_s
    end
    urls.each { |url| yield scrape_detail(agent, url) }
    urls.count
  end

  def scrape_detail(agent, url)
    page = agent.get(url)
    fields = project_details(page)

    {
      "council_reference" => fields["Planning panel reference number"],
      "address" => "#{fields['Project Address']}, NSW",
      "description" => squish(page.at(".field-field-project-description").inner_text),
      "info_url" => url,
      "date_scraped" => Date.today.to_s,
      "date_received" => convert_date(fields["Referral date"])
    }
  end

  def project_details(page)
    page.at(".project__details").search(".row").to_h do |row|
      [squish(row.at("b").inner_text), squish(row.at("div").inner_text)]
    end
  end

  def convert_date(value)
    Date.strptime(value, "%d/%m/%Y").to_s
  rescue ArgumentError, TypeError
    nil
  end

  # Equivalent of ActiveSupport's String#squish
  def squish(text)
    text.gsub(/[[:space:]]+/, " ").strip
  end
end

if __FILE__ == $PROGRAM_NAME
  count = 0
  Scraper.run do |record|
    puts "Saving #{record['council_reference']}..."
    ScraperWiki.save_sqlite(["council_reference"], record)
    count += 1
  end
  puts "Finished - added #{count} records."
end
