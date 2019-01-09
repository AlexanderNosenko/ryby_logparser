require 'byebug'

class PageViewStats
  AVAILABLE_STATISTICS = ['total', 'total_unique']
  attr_reader :file_name, :strategy

  def initialize(file_name, strategy)
    @file_name = file_name

    if strategy.is_a? String
      @strategy = get_strategy_by_name(strategy)
    else
      @strategy = strategy
    end

    raise FileMissingError.new('No file provided') if file_name.nil?
    raise FileMissingError.new("No such file exists '#{file_name}' ") unless file_exists?
    raise InvalidStrategyError.new("Invalid strategy '#{strategy.class.name}'") unless valid_strategy?
  end

  def print
    data = calculate

    data.map { |line|
      formated = strategy.print_line(line)
      puts formated
      formated
    }
  end

  def calculate
    strategy.compile(data)
  end

  private
    def get_strategy_by_name(name)
      raise StatisticNotSupportedError.new("Statistic not supported '#{name}'") unless AVAILABLE_STATISTICS.include?(name)

      case name
      when 'total'
        TotalStatistic.new
      when 'total_unique'
        TotalUniqueStatistic.new
      end
    end

    def data
      @data ||= extract_data
    end

    def file_path
      if file_name[0] == '/'# || !file_name.include?('/')
        file_name
      else
        "#{__dir__}/#{file_name}"
      end
    end

    def file_exists?
      File.file?(file_path)
    end

    def valid_strategy?
      strategy.respond_to?(:compile)
    end

    def extract_data
      begin
        text = File.open(file_path).read
        text.gsub!(/\r\n?/, "\n")
        text.split("\n")
      rescue EOFError
        raise FileError.new("IO Error while reading '#{file_path}'")
      end
    end

  class FileError < StandardError;end
  class FileMissingError < StandardError;end
  class InvalidStrategyError < StandardError;end
  class StatisticNotSupportedError < StandardError;end

  class TotalStatistic
    def print_line(line)
      "#{line[:page_name]} #{line[:statistic]} visits"
    end

    def compile(data)
      groups = data
        .group_by { |a| a.split(/\s/).first }
        .map { |group_name, items|
          {
            page_name: group_name,
            statistic: items.size,
          }
        }
    end
  end

  class TotalUniqueStatistic
    attr_reader :max_line_length

    def print_line(line)
      count_line = "#{line[:statistic]} unique views"

      padding_size = max_line_length - raw_line_length(line) + 1

      padded_page_name = line[:page_name] + ("\s" * padding_size)

      "#{padded_page_name}#{count_line}"
    end

    def raw_line_length(line)
      line[:page_name].size + line[:statistic].size
    end

    def compile_line(group_name, items)
      {
        page_name: group_name,
        statistic: items.uniq { |item| item.split(/\s/)[1] }.size,
      }
    end

    def compile(data)
      data
        .group_by { |a| a.split(/\s/).first }
        .map { |group_name, items|
          line = compile_line(group_name, items)
          if raw_line_length(line) > @max_line_length.to_i
            @max_line_length = raw_line_length(line)
          end
          line
        }
    end
  end
end
