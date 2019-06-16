module Spree
  module Admin
    class SheetsController < Spree::Admin::ResourceController
      def index
        @sheets = Spree::Sheet.page params[:page]
      end

      def create
        sheet = Spree::Sheet.create!(sheet_params)
        sheet.active!
        redirect_to admin_sheets_url
      end

      def edit
        @sheet = Spree::Sheet.find_by_id(params[:id])
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

      def header_map
        @sheet = Spree::Sheet.find_by_id(params[:id])
        @sheet.data['header_map'] = params[:header_map]
        @sheet.save
        redirect_to admin_edit_sheet_path(@sheet.id)
      end

      def global_map
        @sheet = Spree::Sheet.find_by_id(params[:id])
        @sheet.data['global_map'] = params[:global_map]
        @sheet.save
        redirect_to admin_edit_sheet_path(@sheet.id)
      end
     
      private
      def sheet_params
        params.require(:spree_sheet).permit(:file, :name, :header_row)
      end

    end
  end
end
