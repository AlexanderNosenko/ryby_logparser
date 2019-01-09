require "#{__dir__}/page_view_stats"

stats = PageViewStats.new(ARGV[0], ARGV[1])
stats.print
