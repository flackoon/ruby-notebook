require 'cgi/escape'

# Single class approach
class HTMLTable
  def initialize(rows)
    @rows = rows
  end

  def to_s
    html = String.new
    html << '<table><tbody>'

    @rows.each do |row|
      html << '<tr>'
      row.each do |cell|
        html << "<td>#{CGI.escapeHTML(cell.to_s)}</td>"
      end
      html << '</tr>'
    end

    html << '</tbody></table>'
  end
end

# Element subclass approach
class HTMLTable
  class Element
    class << self
      def set_type(type)
        define_method(:type) {type}
      end
    end

    def initialize(data)
      @data = data
    end

    def to_s
      "<#{type}>#{@data}</#{type}>"
    end
  end

  %i[table tbody tr td].each do |type|
    klass = Class.new(Element)
    klass.set_type type
    const_set(type.capitalize, klass)
  end

  def initialize(rows)
    @rows = rows
  end

  def to_s
    Table.new(
      Tbody.new(
        @rows.map do |row|
          Tr.new(
            row.map do |cell|
              Td.new(CGI.escapeHTML(cell.to_s))
            end.join
          )
        end.join
      )
    ).to_s
  end
end


# Wrap method approach
class HTMLTable
  def wrap(html, type)
    html << '<' << type << '>'
    yield
    html << '</' << type << '>'
  end

  def to_s
    html = String.new
    wrap(html, 'table') do
      wrap(html, 'tbody') do
        @rows.each do |row|
          wrap(html, 'tr') do
            row.each do |cell|
              wrap(html, 'td') do
                html << CGI.escapeHTML(cell.to_s)
              end
            end
          end
        end
      end
    end
  end
end
