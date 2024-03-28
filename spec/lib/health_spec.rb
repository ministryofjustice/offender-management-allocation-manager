require "rails_helper"

describe Health do
  subject(:health) { described_class.new(timeout_in_seconds_per_check: 2, num_retries_per_check: 2) }

  before { health.reset_checks! }

  describe "status" do
    context "when all status checks return { 'status': 'UP' }" do
      it "is UP" do
        health.add_check(name: 'serviceA', get_response: -> { { "status" => "UP" } })
        health.add_check(name: 'serviceB', get_response: -> { { "status" => "UP" } })

        expect(health.status).to eq({
          status: "UP",
          components: {
            "serviceA" => { status: "UP" },
            "serviceB" => { status: "UP" },
          }
        })
      end
    end

    context "when any of the status checks return { 'status': 'DOWN' }" do
      it "is DOWN" do
        health.add_check(name: 'serviceA', get_response: -> { { "status" => "DOWN" } })
        health.add_check(name: 'serviceB', get_response: -> { { "status" => "UP" } })

        expect(health.status).to eq({
          status: "DOWN",
          components: {
            "serviceA" => { status: "DOWN" },
            "serviceB" => { status: "UP" },
          }
        })
      end
    end

    describe "checks can be configured to match a specific key and value" do
      context "when the response matches that value" do
        it "is UP" do
          health.add_check(
            name: 'serviceA',
            get_response: -> { { "custom" => "value" } },
            check_response: ->(response) { response["custom"] == "value" }
          )

          expect(health.status).to eq({
            status: "UP",
            components: {
              "serviceA" => { status: "UP" },
            }
          })
        end
      end

      context "when the response does not match that value" do
        it "is DOWN" do
          health.add_check(
            name: 'serviceA',
            get_response: -> { { "custom" => "not_value" } },
            check_response: { key: "custom", value: "value" }
          )

          expect(health.status).to eq({
            status: "DOWN",
            components: {
              "serviceA" => { status: "DOWN" },
            }
          })
        end
      end
    end

    describe "checks can be configured to match a specific value" do
      context "when the response matches that value" do
        it "is UP" do
          health.add_check(
            name: 'serviceA',
            get_response: -> { "pong" },
            check_response: ->(response) { response == "pong" }
          )

          expect(health.status).to eq({
            status: "UP",
            components: {
              "serviceA" => { status: "UP" },
            }
          })
        end
      end

      context "when the response does not match that value" do
        it "is UP" do
          health.add_check(
            name: 'serviceA',
            get_response: -> { "not_pong" },
            check_response: { value: "pong" }
          )

          expect(health.status).to eq({
            status: "DOWN",
            components: {
              "serviceA" => { status: "DOWN" },
            }
          })
        end
      end
    end

    describe "when any of the status checks fail" do
      it "is DOWN" do
        health.add_check(name: 'serviceA', get_response: -> { { "status" => "UP" } })
        health.add_check(name: 'serviceB', get_response: -> { raise "FAILED!" })

        expect(health.status).to eq({
          status: "DOWN",
          components: {
            "serviceA" => { status: "UP" },
            "serviceB" => { status: "DOWN" },
          }
        })
      end

      context "when the check passes after retrying once" do
        it "is UP" do
          momentarily_down = double('momentarily_down')
          allow(momentarily_down).to receive(:call).and_return({ "status" => "DOWN" }, { "status" => "UP" })

          health.add_check(name: 'serviceA', get_response: -> { { "status" => "UP" } })
          health.add_check(name: 'serviceB', get_response: momentarily_down)

          expect(health.status).to eq({
            status: "UP",
            components: {
              "serviceA" => { status: "UP" },
              "serviceB" => { status: "UP" },
            }
          })
        end
      end

      context "when the check times out" do
        it "is DOWN" do
          allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

          health.add_check(name: 'serviceA', get_response: -> { { "status" => "UP" } })

          expect(health.status).to eq({
            status: "DOWN",
            components: {
              "serviceA" => { status: "DOWN" },
            }
          })
        end
      end
    end
  end
end
