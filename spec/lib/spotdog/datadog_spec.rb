require "spec_helper"

module Spotdog
  describe Datadog do
    let(:api_key) do
      "apikey"
    end

    let(:prefix) do
      "spotinstance"
    end

    let(:datadog) do
      described_class.new(api_key, prefix)
    end

    describe ".send_price_history" do
      let(:spot_price_history) do
        []
      end

      before do
        allow_any_instance_of(described_class).to receive(:send_price_history).and_return([])
      end

      it "should create new #{described_class} isntance and call #send_price_history" do
        expect_any_instance_of(described_class).to receive(:send_price_history)
        described_class.send_price_history(api_key, spot_price_history)
      end
    end

    describe ".send_spot_instance_requests" do
      let(:spot_instance_requests) do
        []
      end

      before do
        allow_any_instance_of(described_class).to receive(:send_spot_instance_requests).and_return([])
      end

      it "should create new #{described_class} isntance and call #send_spot_instance_requests" do
        expect_any_instance_of(described_class).to receive(:send_spot_instance_requests)
        described_class.send_spot_instance_requests(api_key, spot_instance_requests)
      end
    end

    describe "#send_price_history" do
      let(:c4xlarge_linux_vpc_1b_1) do
        {
          instance_type: "c4.xlarge",
          product_description: "Linux/UNIX (Amazon VPC)",
          spot_price: "0.143600",
          timestamp: Time.parse("2015-10-06 05:39:52 UTC"),
          availability_zone: "ap-northeast-1b",
        }
      end

      let(:c4xlarge_linux_vpc_1b_2) do
        {
          instance_type: "c4.xlarge",
          product_description: "Linux/UNIX (Amazon VPC)",
          spot_price: "0.233600",
          timestamp: Time.parse("2015-10-06 05:29:52 UTC"),
          availability_zone: "ap-northeast-1b",
        }
      end

      let(:m4large_windows_classic_1c) do
        {
          instance_type: "m4.large",
          product_description: "Windows",
          spot_price: "1.143600",
          timestamp: Time.parse("2015-10-06 05:20:52 UTC"),
          availability_zone: "ap-northeast-1c",
        }
      end

      let(:r3xlarge_suse_vpc_1c) do
        {
          instance_type: "r3.xlarge",
          product_description: "SUSE Linux (Amazon VPC)",
          spot_price: "1.343600",
          timestamp: Time.parse("2015-10-06 05:10:52 UTC"),
          availability_zone: "ap-northeast-1c",
        }
      end

      let(:spot_price_history) do
        [
          c4xlarge_linux_vpc_1b_1,
          c4xlarge_linux_vpc_1b_2,
          m4large_windows_classic_1c,
          r3xlarge_suse_vpc_1c,
        ]
      end

      let(:c4xlarge_points) do
        [
          [Time.parse("2015-10-06 05:39:52 UTC"), 0.1436],
          [Time.parse("2015-10-06 05:29:52 UTC"), 0.2336],
        ]
      end

      let(:m4large_points) do
        [
          [Time.parse("2015-10-06 05:20:52 UTC"), 1.1436],
        ]
      end

      let(:r3xlarge_points) do
        [
          [Time.parse("2015-10-06 05:10:52 UTC"), 1.3436],
        ]
      end

      before do
        allow_any_instance_of(Dogapi::Client).to receive(:emit_point).and_return(nil)
      end

      it "should call emit_point" do
        expect_any_instance_of(Dogapi::Client).to receive(:emit_points).with(
          "spotinstance",
          c4xlarge_points,
          {
            instance_type: "c4_xlarge",
            machine_type: "linux_vpc",
            availability_zone: "ap_northeast_1b"
          }
        )
        expect_any_instance_of(Dogapi::Client).to receive(:emit_points).with(
          "spotinstance",
          m4large_points,
          {
            instance_type: "m4_large",
            machine_type: "windows_classic",
            availability_zone: "ap_northeast_1c"
          }
        )
        expect_any_instance_of(Dogapi::Client).to receive(:emit_points).with(
          "spotinstance",
          r3xlarge_points,
          {
            instance_type: "r3_xlarge",
            machine_type: "suse_vpc",
            availability_zone: "ap_northeast_1c"
          }
        )
        datadog.send_price_history(spot_price_history)
      end
    end

    describe "#send_spot_instance_requests" do
      let(:spot_instance_request) do
        {
          spot_instance_request_id: "sir-1234abcd",
          spot_price: "0.051120",
          type: "one-time",
          state: "active",
          status: {
            code: "fulfilled", update_time: Time.parse("2015-10-20 12:34:56 UTC"), message: "Your Spot request is fulfilled."
          },
          launch_specification: {
            image_id: "ami-1234abcd",
            key_name: "hoge",
            security_groups: [
              { group_name: "default", group_id: "sg-1234abcd" }
            ],
            instance_type: "c4.xlarge",
            placement: { availability_zone: "ap-northeast-1c" },
            block_device_mappings: [
              {
                device_name: "/dev/xvda", ebs: {
                  volume_size: 50, delete_on_termination: true, volume_type: "gp2"
                }
              },
              {
                device_name: "/dev/xvdb", no_device: ""
              }
            ],
            network_interfaces: [
              { device_index: 0, subnet_id: "subnet-1234abcd", associate_public_ip_address: true }
            ],
            ebs_optimized: true,
            monitoring: { enabled: false }
          },
          instance_id: "i-1234abcd",
          create_time: Time.parse("2015-10-20 12:34:56 UTC"),
          product_description: "Linux/UNIX",
          tags: [
            { key: "Name", value: "" }
          ],
          launched_availability_zone: "ap-northeast-1c"
        }
      end

      let(:spot_instance_requests) do
        [
          spot_instance_request
        ]
      end

      let(:current_time) do
        Time.parse("2015-10-20 12:34:56 UTC")
      end

      let(:active_points) do
        [
          [current_time, 1]
        ]
      end

      before do
        allow_any_instance_of(Dogapi::Client).to receive(:emit_point).and_return(nil)
      end

      it "should call emit_point" do
        Timecop.freeze(current_time) do
          expect_any_instance_of(Dogapi::Client).to receive(:emit_points).with(
            "spotinstance.status.active",
            active_points
          )
          datadog.send_spot_instance_requests(spot_instance_requests)
        end
      end
    end
  end
end
