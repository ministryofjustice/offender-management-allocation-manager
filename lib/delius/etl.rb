# frozen_string_literal: true

require 'open3'
require 'zip'

module Delius
  class ETL
    class DecryptionError < StandardError; end

    def process
      @working_folder = setup

      downloaded_zip = File.join(@working_folder, 'download.zip')
      fetch_attachment_to(downloaded_zip)

      encrypted_xlsx = File.join(@working_folder, 'encrypted.xlsx')
      unzip_attachment(downloaded_zip, encrypted_xlsx)

      xlsx_filename = File.join(@working_folder, 'delius-data.xlsx')
      decrypt_xlsx(encrypted_xlsx, xlsx_filename)

      import_data(xlsx_filename)
    ensure
      # Make sure we always clean up by deleting everything in the working
      # folder.
      FileUtils.rm_rf(@working_folder)
    end

  private

    def setup
      dir = '/tmp/delius_import'
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      dir
    end

    # Fetch the latest attachment and write it into the working folder with
    # the provided name.
    def fetch_attachment_to(output_filename)
      Rails.logger.info("Downloading attachment to #{output_filename}")

      Rake::Task['delius_email:fetch_latest'].invoke(output_filename)

      Rails.logger.info("Download of attachment to #{output_filename} complete")
    end

    # Unzip the previously downloaded attachment to a specific filename in the
    # working folder.
    def unzip_attachment(zip_filename, target_filename)
      Rails.logger.info("Decompressing #{zip_filename} to #{target_filename}")

      Zip::File.open(zip_filename) do |zip_file|
        zip_file.extract(zip_file.first, target_filename)
      end

      Rails.logger.info("Decompressing #{zip_filename} to #{target_filename} complete")
    end

    # Decrypt the downloaded and unzipped XLSX file. The password is taken from the
    # DELIUS_DATA_PASSWORD environment variable and the decrypted file is written to
    # the specific file.
    # For this to work you need to have the `msoffice-crypt` executable installed in
    # your path, which can be build separately and moved into your path with
    #
    #   mkdir ./build
    #   cd ./build
    #   git clone https://github.com/herumi/cybozulib
    #   git clone https://github.com/herumi/msoffice
    #   cd msoffice
    #   make -j RELEASE=1
    #   mv ./bin/msoffice-crypt.exe <SOMEWHERE_IN_PATH>/mssoffice-crypt
    #
    def decrypt_xlsx(encrypted_filename, decrypted_filename)
      Rails.logger.info("Decrypting #{encrypted_filename} to #{decrypted_filename}")

      stdout_and_stderr_str, status = Open3.capture2e("msoffice-crypt -d -p #{ENV['DELIUS_DATA_PASSWORD']} #{encrypted_filename} #{decrypted_filename}")
      raise DecryptionError.new(stdout_and_stderr_str) unless status.success?

      Rails.logger.info("Decrypting #{encrypted_filename} to #{decrypted_filename} complete")
    end

    # Import the data from the decrypted xlsx file into the delius_data table in the
    # database for further processing.
    def import_data(decrypted_xlsx_filename)
      Rails.logger.info("Importing #{decrypted_xlsx_filename} into DeliusData")
      Rake::Task['delius_import:load'].invoke(decrypted_xlsx_filename)
      Rails.logger.info("Import of #{decrypted_xlsx_filename} into DeliusData complete")
    end
  end
end
