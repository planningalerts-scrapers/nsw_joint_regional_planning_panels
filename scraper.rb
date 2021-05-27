require "mechanize"

url = "https://www.planningportal.nsw.gov.au/planning-panel"

agent = Mechanize.new
page = agent.get(url)
urls = page.at(".page__content .grid__row").element_children.map do |application|
  (page.uri + application.at('a')["href"]).to_s
end

p urls
