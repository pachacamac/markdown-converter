#!/usr/bin/env ruby

require 'redcarpet'
require 'albino'
require 'nokogiri'
require 'pdfkit'

['pygmentize', 'wkhtmltopdf'].each do |e|
  abort "Please install package '#{e}'" if `command -v #{e} &>/dev/null`.empty?
end


def generate_html(markdown, options = {})
  options[:stylesheets] ||= ['default.css']
  options[:redcarpet_flags] ||= [:autolink, :no_intraemphasis, :fenced_code, :gh_blockcode]
  html = Redcarpet.new(markdown, *options[:redcarpet_flags]).to_html
  doc = Nokogiri::HTML(html)
  doc.search("//pre[@lang]").each do |pre|
    pre.replace Albino.colorize(pre.text.rstrip, pre[:lang].downcase.to_sym)
  end
  css = options[:stylesheets].collect{ |f| File.read(f) }.join("\n")
  body = doc.xpath('/html/body').first
  head = Nokogiri::XML::Node.new "head", doc
  style = Nokogiri::XML::Node.new "style", doc
  style['type'] = "text/css"
  style.content = css
  style.parent = head
  body.add_previous_sibling head
  doc.to_s
end

def generate_pdf(html, options = {})
  options[:page_size] ||= 'Letter'
  options[:stylesheets] ||= ['default.css']
  kit = PDFKit.new(html, :page_size => options[:page_size])
  options[:stylesheets].each do |f|
    kit.stylesheets << f
  end
  kit.to_pdf
end


markdown = File.read(ARGV[0])
name = File.basename(ARGV[0]).split('.')[0]
html = generate_html(markdown)
File.open("#{name}.html",'w'){ |f| f.write html }
puts 'HTML done'
pdf = generate_pdf(html)
File.open("#{name}.pdf",'w'){ |f| f.write pdf }
puts 'PDF done'
