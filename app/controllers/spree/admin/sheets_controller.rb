module Spree
  module Admin
    class SheetsController < Spree::Admin::ResourceController
      def index
        @sheets = Spree::Sheet.page params[:page]
      end

      def create
        @sheet = Spree::Sheet.create!(sheet_params)
        @sheet.active!
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def edit
        @sheet = Spree::Sheet.find_by_id(params[:id])
      end

      def update
        @sheet = Spree::Sheet.find_by_id(params[:id])

        if @sheet.header_row.to_s != sheet_params[:header_row]
          @sheet.update_header_row
        end

        @sheet.update_attributes(sheet_params)
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def delete
        @sheet_id = params[:id]
        sheet = Spree::Sheet.find_by_id(@sheet_id)
        flash[:success] = 'Sheet destroyed.'
        sheet.destroy
      end

      def process_file
        @sheet = Spree::Sheet.find_by_id(params[:id])
        if(!@sheet.processing?)
          @sheet.processing!
          ParseProductsSheetJob.perform_later(@sheet.id)
        end
        flash[:success] = 'Processing file...'
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def import_products
        @sheet = Spree::Sheet.find_by_id(params[:id])
        if(@sheet.active? or @sheet.ready? or @sheet.failed_processing?)
          @sheet.processing!
          ImportProductsSheetJob.perform_later(@sheet.id)
        end
        flash[:success] = 'Importing products...'
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def get_parsed_json_files
        sheet = Spree::Sheet.find_by_id(params[:id])
        @parsed_json_files = sheet.parsed_json_files.collect{|f| f.service_url}
        render json: @parsed_json_files
      end

      def update_header_map
        log("update_header_map params: #{params['header_map']}")
        @sheet = Spree::Sheet.find_by_id(params[:id])
        
        @sheet.data['header_map'] = params["header_map"]
        @sheet.save
      end

      def update_global_map
        log("update_global_map params: #{params}")
        @sheet = Spree::Sheet.find_by_id(params[:id])
        unless params[:global_map].blank?
          @sheet.data['global_map'] = params[:global_map]
          @sheet.save
        end
      end

      def sheet_status
        @sheet = Spree::Sheet.find_by_id(params[:id])
        render json: {status: @sheet.status}
      end
      
      private
      def sheet_params
        params.require(:spree_sheet).permit(:file, :name, :header_row, :group_column)
      end

      def log(message=nil)
        return unless Rails.env.development? and message.present?
        @logger ||= Logger.new(File.join(Rails.root, 'log', 'debug.log'))
        @logger.debug(message) 
      end

    end
  end
end
