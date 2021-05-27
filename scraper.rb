require "mechanize"
require "active_support/core_ext/string/filters"
require "scraperwiki"

# Gets one page of applications of those currently under assessment
# page 0 is the first page
def page(agent, page)
  url = "https://www.planningportal.nsw.gov.au/planning-panel?field_status_value=2&page=#{page}"

  page = agent.get(url)
  urls = page.at(".page__content .grid__row").element_children.map do |application|
    (page.uri + application.at('a')["href"]).to_s
  end

  urls.each do |url|
    page = agent.get(url)
    v = page.at(".project__details").search(".row").map do |row|
      label = row.at("b").inner_text.squish
      value = row.at("div").inner_text.squish
      [label, value]
    end
    fields = Hash[v]

    yield(
      "council_reference" => fields["DA number"],
      "address" => fields["Project Address"] + ", NSW",
      "description" => page.at(".field-field-project-description").inner_text.squish,
      "info_url" => url,
      "date_scraped" => Date.today.to_s,
      "date_received" => Date.strptime(fields["Referral date"], "%d/%m/%Y").to_s
    )
  end

  # Return number of applications found
  urls.count
end

agent = Mechanize.new

page = 0
loop do
  puts "Getting page #{page}..."
  count = page(agent, page) do |record|
    puts "Saving #{record['council_reference']}..."
    ScraperWiki.save_sqlite(["council_reference"], record)
  end
  page += 1
  break unless count > 0
end
