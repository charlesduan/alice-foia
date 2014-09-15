#!/usr/bin/env ruby

require 'nokogiri'
require 'csv'

class Template
  TEMPLATES = {}
  NAMES = []

  def initialize(name, xpath, &transform)
    @name = name
    @xpath = xpath
    @transform = transform || proc { |x| x.empty? ? nil : x[0].text }

    TEMPLATES[name] = self
    NAMES.push(name)
  end

  def apply(doc)
    res = doc.xpath(@xpath)
    if res.empty?
      @result = nil
    else
      @result = @transform.call(res)
    end
  end

  attr_accessor :result

  class << self
    def run(doc)
      TEMPLATES.each do |name, obj|
        obj.apply(doc)
      end
    end


    def report
      names = header_row
      names.each do |name|
        puts "#{name}\t#{TEMPLATES[name].result}"
      end
    end

    def csv_row
      header_row.map { |name| TEMPLATES[name].result.to_s }
    end

    def reset
      TEMPLATES.values.each do |template| template.result = nil end
    end

    def [](name)
      get(name).result
    end

    def []=(name, res)
      get(name).result = res
    end

    def get(name)
      TEMPLATES[name]
    end

    def header_row
      NAMES
    end
  end

end

Template.new(:title, "//xmlns:invention-title[@lang='en']")

Template.new(
  :application,
  "//xmlns:application-reference/" +
  "xmlns:document-id[@document-id-type='original']/xmlns:doc-number"
) do |x|
  x[0].text.sub(/^(..)(...)(...)$/, "\\1/\\2,\\3")
end

Template.new(
  :filing_date,
  "//xmlns:application-reference//xmlns:date"
) do |x|
  x[0].text.sub(/^(....)(..)(..)$/, "\\1-\\2-\\3")
end

Template.new(
  :priority_date,
  "//xmlns:priority-claim/xmlns:document-id/xmlns:date"
) { |x| x.map(&:text).min.sub(/^(....)(..)(..)$/, "\\1-\\2-\\3") }

Template.new(:priority_count, "//xmlns:priority-claim") { |x| x.count }
Template.new(
  :classification,
  "//xmlns:patent-classification" +
  "[./xmlns:classification-scheme/@office='US']" +
  "/xmlns:classification-symbol"
)
Template.new(
  :applicants,
  "//xmlns:applicant[@data-format='original']//xmlns:name"
) { |x| x.map(&:text) }
Template.new(
  :inventors,
  "//xmlns:inventor[@data-format='original']//xmlns:name"
) { |x| x.map(&:text) }
Template.new(:publication, "//xmlns:exchange-document/@doc-number") do |x|
  x[0].text.sub(/^(....)(......)$/, "\\1/0\\2")
end
Template.new(:abstract, "//xmlns:abstract[@lang='en']")

CSV.open("out.csv", "wb") do |csv|

  csv << Template.header_row

  ARGV.each do |filename|
    doc = Nokogiri::XML(open(filename))
    Template.run(doc)

    Template[:applicants] ||= []
    Template[:inventors] ||= []
    Template[:applicants] -= Template[:inventors]
    Template[:applicants] = Template[:applicants].join("; ")
    Template[:inventors] = Template[:inventors].join("; ")

    csv << Template.csv_row
    Template.reset

  end
end
