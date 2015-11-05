require 'spec_helper'

describe PerfectRetry do
  describe "#with_retry" do
    it 'return block value' do
      ret = PerfectRetry.with_retry do
        42
      end
      expect(ret).to eq 42
    end

    describe "logger" do
      let(:pr) { PerfectRetry.new }
      let(:error_message) { "ERROR!!"}
      let(:error_type) { StandardError }

      before do
        pr.config.sleep = lambda{|n| 0}
      end

      subject {
        pr.with_retry do
          raise error_type.new(error_message)
        end
      }

      context "logging retry count" do
        before { pr.config.limit = limit }

        context "natural number" do
          let(:limit) { 5 }

          it do
            expect(pr.config.logger).to receive(:warn).with(%r!\[[0-9]+/#{pr.config.limit}\]!).exactly(pr.config.limit).times

            expect { subject }.to raise_error(PerfectRetry::TooManyRetry)
          end
        end

        context "infinity" do
          let(:limit) { nil }

          it do
            expect(pr.config.logger).to receive(:warn).with(%r!\[[0-9]+/Infinitiy\]!).at_least(1)

            expect {
              pr.with_retry do |times|
                raise "foo" if times < 10
                raise Exception, "stop"
              end
            }.to raise_error(Exception)
          end
        end
      end

      describe "log message content" do
        after { expect { subject }.to raise_error(PerfectRetry::TooManyRetry) }

        it "exception message" do
          expect(pr.config.logger).to receive(:warn).with(/#{error_message}/).exactly(pr.config.limit).times
        end

        it "exception type(class)" do
          expect(pr.config.logger).to receive(:warn).with(/#{error_type}/).exactly(pr.config.limit).times
        end

        it "'Retrying'" do
          expect(pr.config.logger).to receive(:warn).with(/Retrying/).exactly(pr.config.limit).times
        end
      end
    end
  end
end
