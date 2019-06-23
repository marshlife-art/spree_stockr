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
          flash[:success] = "Header row updated!"
        end

        @sheet.update_attributes(sheet_params)
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def delete
        @sheet_id = params[:id]
        sheet = Spree::Sheet.find_by_id(@sheet_id)
        sheet.destroy
      end

      def process_file
        @sheet = Spree::Sheet.find_by_id(params[:id])
        if(@sheet.active?)
          @sheet.processing!
          ImportProductsSheetJob.perform_later(@sheet.id)
        end
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def get_parsed_json_files
        sheet = Spree::Sheet.find_by_id(params[:id])
        @parsed_json_files = sheet.parsed_json_files.collect{|f| f.service_url}
        render json: @parsed_json_files
      end

      def update_header_map
        log("header_map params: #{params['header_map']}")
        @sheet = Spree::Sheet.find_by_id(params[:id])
        
        @sheet.data['header_map'] = params["header_map"]
        @sheet.save
        flash[:success] = "Updated header mapping!"
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def update_global_map
        log("header_map params: #{params}")
        @sheet = Spree::Sheet.find_by_id(params[:id])
        unless params[:global_map].blank?
          @sheet.data['global_map'] = params[:global_map]
          @sheet.save
        end
        flash[:success] = "Updated global mapping!"
        redirect_to admin_edit_sheet_path(@sheet.id)
      end
     
      private
      def sheet_params
        params.require(:spree_sheet).permit(:file, :name, :header_row)
      end

      def log(message=nil)
        return unless Rails.env.development? and message.present?
        @logger ||= Logger.new(File.join(Rails.root, 'log', 'debug.log'))
        @logger.debug(message) 
      end

    end
  end
end
