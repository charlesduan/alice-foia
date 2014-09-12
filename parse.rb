#!/usr/bin/env ruby

require 'nokogiri'

class Template
  TEMPLATES = {}

  def initialize(name, xpath, &transform)
    @name = name
    @xpath = xpath
    @transform = transform || proc { |x| x.empty? ? nil : x[0].text }

    TEMPLATES[name] = self
  end

  def apply(doc)
    @result = @transform.call(doc.xpath(@xpath))
  end

  attr_accessor :result

  def self.run(doc)
    TEMPLATES.each do |name, obj|
      obj.apply(doc)
    end
  end

  def self.report
    names = TEMPLATES.keys.sort
    names.each do |name|
      puts "#{name}\t#{TEMPLATES[name].result}"
    end
  end

end

Template.new(:title, "//xmlns:invention-title[@lang='en']")
Template.new(:abstract, "//xmlns:abstract[@lang='en']")
Template.new(:priority_count, "//xmlns:priority-claim") { |x| x.count }
Template.new(
  :classification,
  "//xmlns:patent-classification" +
  "[./xmlns:classification-scheme/@office='US']" +
  "/xmlns:classification-symbol"
)
Template.new(
  :priority_date,
  "//xmlns:priority-claim/xmlns:document-id/xmlns:date"
) { |x| x.map(&:text).min }
Template.new(
  :applicants,
  "//xmlns:applicant[@data-format='original']//xmlns:name"
) { |x| x.map(&:text) }
Template.new(
  :inventors,
  "//xmlns:inventor[@data-format='original']//xmlns:name"
) { |x| x.map(&:text) }
Template.new(:publication, "//xmlns:exchange-document/@doc-number")

doc = Nokogiri::XML(open(ARGV[0]))

Template.run(doc)

Template::TEMPLATES[:applicants].result = (
  Template::TEMPLATES[:applicants].result -
  Template::TEMPLATES[:inventors].result
).join("; ")
Template::TEMPLATES[:inventors].result =
  Template::TEMPLATES[:inventors].result.join("; ")

Template.report
