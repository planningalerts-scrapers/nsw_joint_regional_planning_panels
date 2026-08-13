# NSW Joint Regional Planning Panels

This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

It scrapes planning applications currently under assessment from the
[NSW Planning Portal's planning panels register](https://www.planningportal.nsw.gov.au/planning-panel?field_status_value=2).

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

## To run the scraper

    bundle exec ruby scraper.rb

### Expected output

    Getting page 0...
    Saving PPSSTH-123...
    Saving PPSSCC-456...
    ...
    Getting page 3...
    Finished - added 42 records.

Execution time under a minute

## To run the tests

    bundle exec rspec

## To run style and coding checks

    bundle exec rubocop

## To check for security updates

    gem install bundler-audit
    bundle-audit
