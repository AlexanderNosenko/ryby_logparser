require_relative "../ruby_app/page_view_stats"

RSpec.describe PageViewStats do
  def init
    @stats = PageViewStats.new(@file_name, @strategy)
  end

  def mock_input_file(output = nil)
    output ||= @file_content.join("\r\n")
    file_mock = double
    if output == 'error'
      allow(file_mock).to receive(:read).and_raise(EOFError)
    else
      allow(file_mock).to receive(:read).and_return(output)
    end
    allow(File).to receive(:open).and_return(file_mock)
    allow_any_instance_of(PageViewStats).to receive(:file_exists?).and_return(true)
  end

  before do
    @file_name = ''
    @strategy = PageViewStats::TotalStatistic.new

    @file_content = [
      "/help_page/1 126.318.035.038",
      "/contact 184.123.665.067",
      "/contact 184.123.665.067",
      "/contact 84.123.665.067",
      "/about/2 444.701.448.104",
      "/help_page/1 929.398.951.889",
      "/index 444.701.448.104",
      "/help_page/1 722.247.931.582",
      "/about 061.945.150.735",
      "/about 061.945.150.735",
      "/about 061.945.150.735",
      "/about 061.945.150.735",
      "/about 061.945.150.735",
    ]
  end

  describe '#print' do
    context "TotalStatistic strategy" do
      it "should retrun total views" do
        expected_output = [
          "/help_page/1 3 visits",
          "/contact 3 visits",
          "/about/2 1 visits",
          "/index 1 visits",
          "/about 5 visits",
        ]

        mock_input_file

        expect(init.print).to eq expected_output
      end
    end

    context "TotalUniqueStatistic strategy" do
      it "should retrun total views" do
        expected_output = [
          "/help_page/1 3 unique views",
          "/contact     2 unique views",
          "/about/2     1 unique views",
          "/index       1 unique views",
          "/about       1 unique views",
        ]

        mock_input_file
        @strategy = PageViewStats::TotalUniqueStatistic.new

        expect(init.print).to match_array expected_output
      end
    end

    it "should raise error if file is corrupted" do
      # TODO Partial double verification can be skipped as the api is stable.
      mock_input_file('error')

      expect { init.calculate }.to raise_error PageViewStats::FileError
    end
  end


  describe '#calculate' do
    context "TotalStatistic strategy" do
      it "should retrun total views" do
        @strategy = PageViewStats::TotalUniqueStatistic.new
        expected_output = [
          {
            page_name: '/help_page/1',
            statistic: 3,
          },
          {
            page_name: '/contact',
            statistic: 2,
          },
          {
            page_name: '/about/2',
            statistic: 1,
          },
          {
            page_name: '/index',
            statistic: 1,
          },
          {
            page_name: '/about',
            statistic: 1,
          },
        ]

        mock_input_file

        expect(init.calculate).to eq expected_output
      end
    end

    context "TotalStatistic strategy" do
      it "should retrun total views" do
        @strategy = PageViewStats::TotalStatistic.new
        expected_output = [
          {
            page_name: '/help_page/1',
            statistic: 3,
          },
          {
            page_name: '/contact',
            statistic: 3,
          },
          {
            page_name: '/about/2',
            statistic: 1,
          },
          {
            page_name: '/index',
            statistic: 1,
          },
          {
            page_name: '/about',
            statistic: 5,
          },
        ]

        mock_input_file

        expect(init.calculate).to eq expected_output
      end
    end

    it "should raise error if file is corrupted" do
      mock_input_file('error')

      expect { init.calculate }.to raise_error PageViewStats::FileError
    end
  end

  describe 'initialize' do
    it "should inilialize with propper param" do
      mock_input_file
      @strategy = 'total'
      init
    end

    it "should raise error if strategy is invalid" do
      mock_input_file
      @strategy = double

      expect { init }.to raise_error PageViewStats::InvalidStrategyError
    end

    it "should raise error if strategy is not supported" do
      mock_input_file
      @strategy = 'not_suported'

      expect { init }.to raise_error PageViewStats::StatisticNotSupportedError
    end

    it "should raise error if no file provided" do
      @file_name = nil

      expect { init }.to raise_error PageViewStats::FileMissingError
    end

    it "should raise error if file doesn\'t exist" do
      @file_name = 'nonexistent'

      expect { init }.to raise_error PageViewStats::FileMissingError
    end
  end
end
