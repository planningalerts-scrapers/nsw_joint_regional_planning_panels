require "mechanize"
require "active_support/core_ext/string/filters"

def page(agent)
  url = "https://www.planningportal.nsw.gov.au/planning-panel"

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
      "date_received" => fields["Referral date"]
    )
  end
end

agent = Mechanize.new
page(agent) do |record|
  pp record
end
